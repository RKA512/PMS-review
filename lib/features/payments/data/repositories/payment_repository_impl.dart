library;

import '../../../../core/common/enums/payment_type.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_local_datasource.dart';
import '../models/payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentLocalDataSource _dataSource;

  PaymentRepositoryImpl(this._dataSource);

  @override
  Future<int> recordPayment(Payment payment) async {
    try {
      final map = PaymentModel.toMap(payment);
      return await _dataSource.insertPayment(map);
    } catch (e) {
      throw const DatabaseFailure(
        code: 'RECORD_PAYMENT_FAILED',
        message: 'فشل تسجيل الدفعة في قاعدة البيانات.',
      );
    }
  }

  @override
  Future<List<Payment>> getPaymentsForInvoice(int invoiceId) async {
    try {
      final maps = await _dataSource.getPaymentsByInvoice(invoiceId);
      return maps.map((m) => PaymentModel.fromMap(m)).toList();
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_PAYMENTS_INVOICE_FAILED',
        message: 'حدث خطأ أثناء جلب مدفوعات الفاتورة.',
      );
    }
  }

  @override
  Future<List<Payment>> getPaymentsForBooking(int bookingId) async {
    try {
      final maps = await _dataSource.getPaymentsByBooking(bookingId);
      return maps.map((m) => PaymentModel.fromMap(m)).toList();
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_PAYMENTS_BOOKING_FAILED',
        message: 'حدث خطأ أثناء جلب مدفوعات الحجز.',
      );
    }
  }

  @override
  Future<void> voidPayment(int paymentId, int userId) async {
    try {
      final existing = await _dataSource.getPaymentById(paymentId);
      if (existing == null) {
        throw const ValidationFailure(
          code: 'PAYMENT_NOT_FOUND',
          message: 'الدفعة غير موجودة.',
        );
      }
      final now = DateTime.now().toIso8601String();
      await _dataSource.updatePayment(paymentId, {
        'payment_type': PaymentType.refund.toJson(),
        'notes': 'Voided by user $userId at $now',
      });
    } on Failure {
      rethrow;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'VOID_PAYMENT_FAILED',
        message: 'فشل إلغاء الدفعة.',
      );
    }
  }
}
