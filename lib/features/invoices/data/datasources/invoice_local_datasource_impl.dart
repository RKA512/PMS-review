library;

import 'package:sqflite/sqflite.dart';
import '../../../../../core/database/database_helper.dart';
import 'invoice_local_datasource.dart';

class InvoiceLocalDataSourceImpl implements InvoiceLocalDataSource {
  final DatabaseHelper _dbHelper;

  InvoiceLocalDataSourceImpl(this._dbHelper);

  Database? _cachedDb;

  Future<Database> _getDb() async {
    _cachedDb ??= await _dbHelper.database;
    return _cachedDb!;
  }

  @override
  Future<Map<String, dynamic>?> getInvoiceById(int id) async {
    final db = await _getDb();
    final maps = await db.query('invoices', where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  @override
  Future<Map<String, dynamic>?> getInvoiceByBookingId(int bookingId) async {
    final db = await _getDb();
    final maps = await db.query('invoices', where: 'booking_id = ?', whereArgs: [bookingId], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  @override
  Future<int> addInvoice(Map<String, dynamic> map) async {
    final db = await _getDb();
    return await db.insert('invoices', map);
  }

  @override
  Future<void> updateInvoice(Map<String, dynamic> map, int id) async {
    final db = await _getDb();
    await db.update('invoices', map, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Map<String, dynamic>>> getLinesByInvoiceId(int invoiceId) async {
    final db = await _getDb();
    return await db.query('invoice_lines', where: 'invoice_id = ?', whereArgs: [invoiceId]);
  }

  @override
  Future<List<Map<String, dynamic>>> getAdjustmentsByInvoiceId(int invoiceId) async {
    final db = await _getDb();
    return await db.query('invoice_adjustments', where: 'invoice_id = ?', whereArgs: [invoiceId]);
  }

  @override
  Future<void> insertLine(Map<String, dynamic> map) async {
    final db = await _getDb();
    await db.insert('invoice_lines', map);
  }

  @override
  Future<void> insertAdjustment(Map<String, dynamic> map) async {
    final db = await _getDb();
    await db.insert('invoice_adjustments', map);
  }

  @override
  Future<Map<String, dynamic>?> getLineById(int lineId) async {
    final db = await _getDb();
    final maps = await db.query('invoice_lines', where: 'id = ?', whereArgs: [lineId], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  @override
  Future<void> deleteLine(int lineId) async {
    final db = await _getDb();
    await db.delete('invoice_lines', where: 'id = ?', whereArgs: [lineId]);
  }

  @override
  Future<void> deleteLinesByInvoiceId(int invoiceId) async {
    final db = await _getDb();
    await db.delete('invoice_lines', where: 'invoice_id = ?', whereArgs: [invoiceId]);
  }

  @override
  Future<void> deleteAdjustmentsByInvoiceId(int invoiceId) async {
    final db = await _getDb();
    await db.delete('invoice_adjustments', where: 'invoice_id = ?', whereArgs: [invoiceId]);
  }

  @override
  Future<int> updateInvoiceStatus(int invoiceId, Map<String, dynamic> values) async {
    final db = await _getDb();
    return await db.update('invoices', values, where: 'id = ?', whereArgs: [invoiceId]);
  }

  @override
  Future<List<Map<String, dynamic>>> getInvoicesByAccount(int accountId) async {
    final db = await _getDb();
    return await db.rawQuery('''
      SELECT i.* FROM invoices i
      JOIN bookings b ON i.booking_id = b.id
      JOIN properties p ON b.property_id = p.id
      WHERE p.account_id = ?
      ORDER BY i.created_at DESC
    ''', [accountId]);
  }

  @override
  Future<List<Map<String, dynamic>>> getBatchLines(List<int> invoiceIds) async {
    final db = await _getDb();
    final placeholders = List.filled(invoiceIds.length, '?').join(', ');
    return await db.rawQuery('SELECT * FROM invoice_lines WHERE invoice_id IN ($placeholders)', invoiceIds);
  }

  @override
  Future<List<Map<String, dynamic>>> getBatchAdjustments(List<int> invoiceIds) async {
    final db = await _getDb();
    final placeholders = List.filled(invoiceIds.length, '?').join(', ');
    return await db.rawQuery('SELECT * FROM invoice_adjustments WHERE invoice_id IN ($placeholders)', invoiceIds);
  }

  @override
  Future<List<Map<String, dynamic>>> getUninvoicedBookings() async {
    final db = await _getDb();
    return await db.rawQuery('''
      SELECT b.id, b.booking_number, g.full_name as guest_name 
      FROM bookings b 
      JOIN guests g ON b.primary_guest_id = g.id 
      WHERE b.id NOT IN (SELECT booking_id FROM invoices)
    ''');
  }

  @override
  Future<int> createInvoiceWithDetails(Map<String, dynamic> invoiceMap, List<Map<String, dynamic>> lines, List<Map<String, dynamic>> adjustments) async {
    final db = await _getDb();
    return await db.transaction((txn) async {
      final id = await txn.insert('invoices', invoiceMap);
      for (final line in lines) {
        line['invoice_id'] = id;
        await txn.insert('invoice_lines', line);
      }
      for (final adj in adjustments) {
        adj['invoice_id'] = id;
        await txn.insert('invoice_adjustments', adj);
      }
      return id;
    });
  }
}
