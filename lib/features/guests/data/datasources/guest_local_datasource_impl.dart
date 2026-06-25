library;

import 'package:sqflite/sqflite.dart';
import '../../../../../core/database/database_helper.dart';
import 'guest_local_datasource.dart';

class GuestLocalDataSourceImpl implements GuestLocalDataSource {
  final DatabaseHelper _dbHelper;

  GuestLocalDataSourceImpl(this._dbHelper);

  Database? _cachedDb;

  Future<Database> _getDb() async {
    _cachedDb ??= await _dbHelper.database;
    return _cachedDb!;
  }

  @override
  Future<List<Map<String, dynamic>>> getGuests(int accountId, bool includeArchived) async {
    final db = await _getDb();
    if (includeArchived) {
      return await db.query('guests', where: 'account_id = ?', whereArgs: [accountId], orderBy: 'full_name ASC');
    }
    return await db.query('guests', where: 'account_id = ? AND deleted_at IS NULL', whereArgs: [accountId], orderBy: 'full_name ASC');
  }

  @override
  Future<Map<String, dynamic>?> getGuestById(int id) async {
    final db = await _getDb();
    final maps = await db.query('guests', where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  @override
  Future<Map<String, dynamic>?> getGuestByDocument(int accountId, String documentType, String documentNumber) async {
    final db = await _getDb();
    final maps = await db.query('guests', where: 'account_id = ? AND document_type = ? AND document_number = ? AND deleted_at IS NULL', whereArgs: [accountId, documentType, documentNumber], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> searchGuests(int accountId, String query, bool includeArchived) async {
    final db = await _getDb();
    final wildcard = '%$query%';
    String whereString = 'account_id = ? AND (full_name LIKE ? OR phone LIKE ? OR email LIKE ? OR document_number LIKE ?)';
    final whereArgs = [accountId, wildcard, wildcard, wildcard, wildcard];
    if (!includeArchived) {
      whereString += ' AND deleted_at IS NULL';
    }
    return await db.query('guests', where: whereString, whereArgs: whereArgs, orderBy: 'full_name ASC');
  }

  @override
  Future<int> insertGuest(Map<String, dynamic> map) async {
    final db = await _getDb();
    return await db.insert('guests', map);
  }

  @override
  Future<void> updateGuest(Map<String, dynamic> map, int id) async {
    final db = await _getDb();
    await db.update('guests', map, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> archiveGuest(int id, String now) async {
    final db = await _getDb();
    await db.update('guests', {'deleted_at': now, 'updated_at': now}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> unarchiveGuest(int id, String now) async {
    final db = await _getDb();
    await db.update('guests', {'deleted_at': null, 'updated_at': now}, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Map<String, dynamic>>> getGuestContacts(int guestId) async {
    final db = await _getDb();
    return await db.query('guest_contacts', where: 'guest_id = ?', whereArgs: [guestId]);
  }

  @override
  Future<void> insertGuestContact(Map<String, dynamic> map) async {
    final db = await _getDb();
    await db.insert('guest_contacts', map);
  }

  @override
  Future<void> updateGuestContact(Map<String, dynamic> map, int id) async {
    final db = await _getDb();
    await db.update('guest_contacts', map, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteGuestContact(int contactId) async {
    final db = await _getDb();
    await db.delete('guest_contacts', where: 'id = ?', whereArgs: [contactId]);
  }

  @override
  Future<void> deleteGuestContactsByGuestId(int guestId) async {
    final db = await _getDb();
    await db.delete('guest_contacts', where: 'guest_id = ?', whereArgs: [guestId]);
  }

  @override
  Future<int> createGuestWithContacts(Map<String, dynamic> guestMap, List<Map<String, dynamic>> contactMaps) async {
    final db = await _getDb();
    return await db.transaction((txn) async {
      final id = await txn.insert('guests', guestMap);
      for (final contact in contactMaps) {
        contact['guest_id'] = id;
        await txn.insert('guest_contacts', contact);
      }
      return id;
    });
  }

  @override
  Future<void> updateGuestWithContacts(Map<String, dynamic> guestMap, List<Map<String, dynamic>> contactMaps, int guestId) async {
    final db = await _getDb();
    await db.transaction((txn) async {
      await txn.update('guests', guestMap, where: 'id = ?', whereArgs: [guestId]);
      await txn.delete('guest_contacts', where: 'guest_id = ?', whereArgs: [guestId]);
      for (final contact in contactMaps) {
        await txn.insert('guest_contacts', contact);
      }
    });
  }
}
