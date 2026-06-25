library;

import '../../../../../core/database/database_helper.dart';
import 'property_local_datasource.dart';

class PropertyLocalDataSourceImpl implements PropertyLocalDataSource {
  final DatabaseHelper _dbHelper;

  PropertyLocalDataSourceImpl(this._dbHelper);

  @override
  Future<List<Map<String, dynamic>>> getProperties(bool includeArchived) async {
    final db = await _dbHelper.database;
    if (includeArchived) {
      return await db.query('properties', orderBy: 'name ASC');
    }
    return await db.query('properties', where: 'deleted_at IS NULL', orderBy: 'name ASC');
  }

  @override
  Future<Map<String, dynamic>?> getPropertyById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('properties', where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  @override
  Future<Map<String, dynamic>?> getPropertyByUuid(String uuid) async {
    final db = await _dbHelper.database;
    final maps = await db.query('properties', where: 'uuid = ?', whereArgs: [uuid], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  @override
  Future<int> createProperty(Map<String, dynamic> map) async {
    final db = await _dbHelper.database;
    return await db.insert('properties', map);
  }

  @override
  Future<void> updateProperty(Map<String, dynamic> map, int id) async {
    final db = await _dbHelper.database;
    await db.update('properties', map, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> archiveProperty(int id, Map<String, dynamic> values) async {
    final db = await _dbHelper.database;
    await db.update('properties', values, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> unarchiveProperty(int id, Map<String, dynamic> values) async {
    final db = await _dbHelper.database;
    await db.update('properties', values, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Map<String, dynamic>>> getPropertyTypes() async {
    final db = await _dbHelper.database;
    return await db.query('property_types', orderBy: 'name ASC');
  }

  @override
  Future<List<Map<String, dynamic>>> getPropertySettings(int propertyId) async {
    final db = await _dbHelper.database;
    return await db.query('property_settings', where: 'property_id = ?', whereArgs: [propertyId]);
  }

  @override
  Future<List<Map<String, dynamic>>> getPropertySettingByKey(int propertyId, String key) async {
    final db = await _dbHelper.database;
    return await db.query('property_settings', where: 'property_id = ? AND setting_key = ?', whereArgs: [propertyId, key], limit: 1);
  }

  @override
  Future<void> insertPropertySetting(Map<String, dynamic> map) async {
    final db = await _dbHelper.database;
    await db.insert('property_settings', map);
  }

  @override
  Future<void> updatePropertySetting(String value, String now, int propertyId, String key) async {
    final db = await _dbHelper.database;
    await db.update('property_settings', {'setting_value': value, 'updated_at': now},
        where: 'property_id = ? AND setting_key = ?', whereArgs: [propertyId, key]);
  }
}
