library;

import '../../../../../core/database/database_helper.dart';
import 'unit_local_datasource.dart';

class UnitLocalDataSourceImpl implements UnitLocalDataSource {
  final DatabaseHelper _dbHelper;

  UnitLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<Map<String, dynamic>>> getUnits(int propertyId, bool includeArchived) async {
    final db = await _dbHelper.executor;
    if (includeArchived) {
      return await db.query('units', where: 'property_id = ?', whereArgs: [propertyId], orderBy: 'unit_number ASC');
    }
    return await db.query('units', where: 'property_id = ? AND deleted_at IS NULL', whereArgs: [propertyId], orderBy: 'unit_number ASC');
  }

  @override
  Future<Map<String, dynamic>?> getUnitById(int id) async {
    final db = await _dbHelper.executor;
    final maps = await db.query('units', where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  @override
  Future<Map<String, dynamic>?> getUnitByUuid(String uuid) async {
    final db = await _dbHelper.executor;
    final maps = await db.query('units', where: 'uuid = ?', whereArgs: [uuid], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  @override
  Future<int> createUnit(Map<String, dynamic> map) async {
    final db = await _dbHelper.executor;
    return await db.insert('units', map);
  }

  @override
  Future<void> updateUnit(Map<String, dynamic> map, int id) async {
    final db = await _dbHelper.executor;
    await db.update('units', map, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> archiveUnit(int id, String now) async {
    final db = await _dbHelper.executor;
    await db.update('units', {'deleted_at': now, 'updated_at': now}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> unarchiveUnit(int id, String now) async {
    final db = await _dbHelper.executor;
    await db.update('units', {'deleted_at': null, 'updated_at': now}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> updateUnitStatus(int unitId, String status) async {
    final db = await _dbHelper.executor;
    await db.update('units', {'status': status}, where: 'id = ?', whereArgs: [unitId]);
  }

  @override
  Future<List<Map<String, dynamic>>> getUnitTypes() async {
    final db = await _dbHelper.executor;
    return await db.query('unit_types', orderBy: 'name ASC');
  }
}
