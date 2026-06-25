library;

import '../../../../../core/database/database_helper.dart';
import 'settlement_local_datasource.dart';

class SettlementLocalDataSourceImpl implements SettlementLocalDataSource {
  final DatabaseHelper _dbHelper;

  SettlementLocalDataSourceImpl(this._dbHelper);

  @override
  Future<int> insertSettlement(Map<String, dynamic> map) async {
    final db = await _dbHelper.database;
    return await db.insert('settlements', map);
  }

  @override
  Future<List<Map<String, dynamic>>> getSettlementsByBooking(int bookingId) async {
    final db = await _dbHelper.database;
    return await db.query('settlements', where: 'booking_id = ?', whereArgs: [bookingId], orderBy: 'created_at DESC');
  }

  @override
  Future<Map<String, dynamic>?> getSettlementById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('settlements', where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  @override
  Future<void> updateSettlement(int id, Map<String, dynamic> values) async {
    final db = await _dbHelper.database;
    await db.update('settlements', values, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> insertCorrection(Map<String, dynamic> map) async {
    final db = await _dbHelper.database;
    return await db.insert('settlement_corrections', map);
  }

  @override
  Future<List<Map<String, dynamic>>> getCorrectionsBySettlement(int settlementId) async {
    final db = await _dbHelper.database;
    return await db.query('settlement_corrections', where: 'settlement_id = ?', whereArgs: [settlementId]);
  }
}
