/// Why the file exists:
/// Implements [InvoiceRepository] using sqflite, managing transactions,
/// ensuring safe updates, freezing totals, dynamic outstanding calculations, and audit logging.
/// Delegates raw SQL to InvoiceLocalDataSource.
library;

import '../../../../core/errors/failure.dart';
import '../../../../core/common/enums/invoice_status.dart';
import '../../../../core/common/models/money.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_adjustment.dart';
import '../../domain/entities/invoice_line.dart';
import '../datasources/invoice_local_datasource.dart';
import '../models/invoice_model.dart';
import '../models/invoice_line_model.dart';
import '../models/invoice_adjustment_model.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceLocalDataSource _dataSource;

  InvoiceRepositoryImpl(this._dataSource);

  @override
  Future<Invoice?> getInvoiceById(int id) async {
    try {
      final invoiceMap = await _dataSource.getInvoiceById(id);
      if (invoiceMap == null) return null;

      final lineMaps = await _dataSource.getLinesByInvoiceId(id);
      final adjustmentMaps = await _dataSource.getAdjustmentsByInvoiceId(id);

      final lines = lineMaps.map((m) => InvoiceLineModel.fromMap(m)).toList();
      final adjustments = adjustmentMaps.map((m) => InvoiceAdjustmentModel.fromMap(m)).toList();

      return InvoiceModel.fromMap(invoiceMap, lines: lines, adjustments: adjustments);
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_INVOICE_BY_ID_FAILED',
        message: 'حدث خطأ أثناء جلب الفاتورة من قاعدة البيانات.',
      );
    }
  }

  @override
  Future<Invoice?> getInvoiceByBookingId(int bookingId) async {
    try {
      final invoiceMap = await _dataSource.getInvoiceByBookingId(bookingId);
      if (invoiceMap == null) return null;

      final id = invoiceMap['id'] as int;
      final lineMaps = await _dataSource.getLinesByInvoiceId(id);
      final adjustmentMaps = await _dataSource.getAdjustmentsByInvoiceId(id);

      final lines = lineMaps.map((m) => InvoiceLineModel.fromMap(m)).toList();
      final adjustments = adjustmentMaps.map((m) => InvoiceAdjustmentModel.fromMap(m)).toList();

      return InvoiceModel.fromMap(invoiceMap, lines: lines, adjustments: adjustments);
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_INVOICE_BY_BOOKING_FAILED',
        message: 'حدث خطأ أثناء جلب فاتورة الحجز.',
      );
    }
  }

  @override
  Future<List<Invoice>> getInvoices(int accountId) async {
    try {
      final maps = await _dataSource.getInvoicesByAccount(accountId);
      if (maps.isEmpty) return const [];

      final invoiceIds = maps.map((row) => row['id'] as int).toList();
      final lineMaps = await _dataSource.getBatchLines(invoiceIds);
      final adjustmentMaps = await _dataSource.getBatchAdjustments(invoiceIds);

      final Map<int, List<InvoiceLine>> linesByInvoiceId = {};
      for (final map in lineMaps) {
        final invoiceId = map['invoice_id'] as int;
        final line = InvoiceLineModel.fromMap(map);
        linesByInvoiceId.putIfAbsent(invoiceId, () => []).add(line);
      }

      final Map<int, List<InvoiceAdjustment>> adjustmentsByInvoiceId = {};
      for (final map in adjustmentMaps) {
        final invoiceId = map['invoice_id'] as int;
        final adj = InvoiceAdjustmentModel.fromMap(map);
        adjustmentsByInvoiceId.putIfAbsent(invoiceId, () => []).add(adj);
      }

      final List<Invoice> results = [];
      for (final map in maps) {
        final id = map['id'] as int;
        final lines = linesByInvoiceId[id] ?? [];
        final adjustments = adjustmentsByInvoiceId[id] ?? [];
        results.add(InvoiceModel.fromMap(map, lines: lines, adjustments: adjustments));
      }
      return results;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_INVOICES_FAILED',
        message: 'حدث خطأ أثناء جلب الفواتير للحساب من قاعدة البيانات.',
      );
    }
  }

  @override
  Future<int> createInvoice(Invoice invoice, int userId) async {
    try {
      final invoiceMap = InvoiceModel.toMap(invoice);
      final lineMaps = invoice.lines.map((l) => InvoiceLineModel.toMap(l)).toList();
      final adjustmentMaps = invoice.adjustments.map((a) => InvoiceAdjustmentModel.toMap(a)).toList();
      return await _dataSource.createInvoiceWithDetails(invoiceMap, lineMaps, adjustmentMaps);
    } on Failure {
      rethrow;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'CREATE_INVOICE_FAILED',
        message: 'فشل إنشاء الفاتورة في قاعدة البيانات.',
      );
    }
  }

  @override
  Future<void> updateInvoice(Invoice invoice, int userId) async {
    if (invoice.id == null) {
      throw const ValidationFailure(
        code: 'INVOICE_ID_MISSING',
        message: 'تعذر التحديث: معرف الفاتورة مفقود.',
      );
    }
    try {
      final invoiceMap = InvoiceModel.toMap(invoice);
      final lineMaps = invoice.lines.map((l) => InvoiceLineModel.toMap(l.copyWith(invoiceId: invoice.id))).toList();
      final adjustmentMaps = invoice.adjustments.map((a) => InvoiceAdjustmentModel.toMap(a.copyWith(invoiceId: invoice.id))).toList();

      final existing = await _dataSource.getInvoiceById(invoice.id!);
      if (existing == null) {
        throw const ValidationFailure(
          code: 'INVOICE_NOT_FOUND',
          message: 'الفاتورة غير موجودة لتحديثها في النظام.',
        );
      }

      await _dataSource.deleteLinesByInvoiceId(invoice.id!);
      for (final line in lineMaps) {
        line['invoice_id'] = invoice.id!;
        await _dataSource.insertLine(line);
      }

      await _dataSource.deleteAdjustmentsByInvoiceId(invoice.id!);
      for (final adj in adjustmentMaps) {
        adj['invoice_id'] = invoice.id!;
        await _dataSource.insertAdjustment(adj);
      }

      await _dataSource.updateInvoice(invoiceMap, invoice.id!);
    } on Failure {
      rethrow;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'UPDATE_INVOICE_FAILED',
        message: 'فشل تحديث الفاتورة والتزامن.',
      );
    }
  }

  @override
  Future<void> addInvoiceLine(InvoiceLine line, int userId) async {
    if (line.invoiceId == null) {
      throw const ValidationFailure(
        code: 'LINE_INVOICE_ID_MISSING',
        message: 'معرف الفاتورة مفقود لخطوط الفاتورة.',
      );
    }
    try {
      await _dataSource.insertLine(InvoiceLineModel.toMap(line));
    } on Failure {
      rethrow;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'ADD_INVOICE_LINE_FAILED',
        message: 'فشل إضافة بند الفاتورة.',
      );
    }
  }

  @override
  Future<void> removeInvoiceLine(int lineId, int userId) async {
    try {
      final lineMap = await _dataSource.getLineById(lineId);
      if (lineMap == null) {
        throw const ValidationFailure(
          code: 'LINE_NOT_FOUND',
          message: 'بند الفاتورة المطلوب غير موجود في النظام.',
        );
      }
      await _dataSource.deleteLine(lineId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'REMOVE_INVOICE_LINE_FAILED',
        message: 'فشل حذف بند الفاتورة.',
      );
    }
  }

  @override
  Future<void> addInvoiceAdjustment(InvoiceAdjustment adjustment, int userId) async {
    if (adjustment.invoiceId == null) {
      throw const ValidationFailure(
        code: 'ADJUSTMENT_INVOICE_ID_MISSING',
        message: 'معرف الفاتورة مفقود في التعديل.',
      );
    }
    try {
      await _dataSource.insertAdjustment(InvoiceAdjustmentModel.toMap(adjustment));
    } on Failure {
      rethrow;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'ADD_ADJUSTMENT_FAILED',
        message: 'فشل إضافة تعديل الفاتورة الحسابي.',
      );
    }
  }

  @override
  Future<void> issueInvoice(int invoiceId, Money frozenTotal, int userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final updatedRows = await _dataSource.updateInvoiceStatus(invoiceId, {
        'status': InvoiceStatus.issued.name,
        'total_amount': frozenTotal.minorUnits,
        'issued_at': now,
        'updated_at': now,
      });
      if (updatedRows == 0) {
        throw const ValidationFailure(
          code: 'INVOICE_NOT_FOUND',
          message: 'الفاتورة غير موجودة في قاعدة البيانات.',
        );
      }
    } on Failure {
      rethrow;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'ISSUE_INVOICE_FAILED',
        message: 'فشل إصدار الفاتورة في النظام المالي.',
      );
    }
  }

  @override
  Future<void> cancelInvoice(int invoiceId, int userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final updatedRows = await _dataSource.updateInvoiceStatus(invoiceId, {
        'status': InvoiceStatus.cancelled.name,
        'updated_at': now,
      });
      if (updatedRows == 0) {
        throw const ValidationFailure(
          code: 'INVOICE_NOT_FOUND',
          message: 'الفاتورة غير موجودة لتحديث حالتها إلى ملغاة.',
        );
      }
    } on Failure {
      rethrow;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'CANCEL_INVOICE_FAILED',
        message: 'فشل إلغاء الفاتورة.',
      );
    }
  }

  @override
  Future<int?> getInvoiceIdByLineId(int lineId) async {
    try {
      final map = await _dataSource.getLineById(lineId);
      return map?['invoice_id'] as int?;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_INVOICE_ID_BY_LINE_FAILED',
        message: 'حدث خطأ أثناء جلب معرّف الفاتورة للبند.',
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUninvoicedBookings() async {
    try {
      return await _dataSource.getUninvoicedBookings();
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_UNINVOICED_BOOKINGS_FAILED',
        message: 'حدث خطأ أثناء جلب الحجوزات غير المفوترة.',
      );
    }
  }
}
