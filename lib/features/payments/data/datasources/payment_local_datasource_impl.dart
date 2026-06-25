library;

import '../../../../../core/database/database_helper.dart';
import 'payment_local_datasource.dart';

class PaymentLocalDataSourceImpl implements PaymentLocalDataSource {
  final DatabaseHelper _dbHelper;

  PaymentLocalDataSourceImpl(this._dbHelper);

  @override
  Future<int> insertPayment(Map<String, dynamic> map) async {
    final db = await _dbHelper.database;
    return await db.insert('payments', map);
  }

  @override
  Future<List<Map<String, dynamic>>> getPaymentsByInvoice(int invoiceId) async {
    final db = await _dbHelper.database;
    return await db.query('payments', where: 'invoice_id = ?', whereArgs: [invoiceId], orderBy: 'created_at DESC');
  }

  @override
  Future<List<Map<String, dynamic>>> getPaymentsByBooking(int bookingId) async {
    final db = await _dbHelper.database;
    return await db.query('payments', where: 'booking_id = ?', whereArgs: [bookingId], orderBy: 'created_at DESC');
  }

  @override
  Future<void> updatePayment(int id, Map<String, dynamic> values) async {
    final db = await _dbHelper.database;
    await db.update('payments', values, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Map<String, dynamic>?> getPaymentById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('payments', where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }
}
