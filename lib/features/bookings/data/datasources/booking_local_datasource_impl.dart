library;

import '../../../../../core/database/database_helper.dart';
import 'booking_local_datasource.dart';

class BookingLocalDataSourceImpl implements BookingLocalDataSource {
  final DatabaseHelper _dbHelper;

  BookingLocalDataSourceImpl(this._dbHelper);

  @override
  Future<int> insertBookingRow(Map<String, dynamic> map) async {
    final db = await _dbHelper.executor;
    return await db.insert('bookings', map);
  }

  @override
  Future<void> insertBookingUnit(Map<String, dynamic> map) async {
    final db = await _dbHelper.executor;
    await db.insert('booking_units', map);
  }

  @override
  Future<void> insertBookingGuest(Map<String, dynamic> map) async {
    final db = await _dbHelper.executor;
    await db.insert('booking_guests', map);
  }

  @override
  Future<void> updateBooking(Map<String, dynamic> values, int id) async {
    final db = await _dbHelper.executor;
    await db.update('bookings', values, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Map<String, dynamic>?> getBookingById(int id) async {
    final db = await _dbHelper.executor;
    final results = await db.query('bookings', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  @override
  Future<Map<String, dynamic>?> getBookingByNumber(String bookingNumber) async {
    final db = await _dbHelper.executor;
    final results = await db.query('bookings', where: 'booking_number = ?', whereArgs: [bookingNumber]);
    return results.isNotEmpty ? results.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getBookingsForProperty(int propertyId) async {
    final db = await _dbHelper.executor;
    return await db.query('bookings', where: 'property_id = ?', whereArgs: [propertyId], orderBy: 'check_in_date DESC');
  }

  @override
  Future<bool> isUnitAvailable(int unitId, String startStr, String endStr, int? excludeBookingId) async {
    final db = await _dbHelper.executor;
    final List<Object?> whereArgs = [unitId];
    String excludeClause = '';
    if (excludeBookingId != null) {
      excludeClause = 'AND b.id != ?';
      whereArgs.add(excludeBookingId);
    }
    whereArgs.addAll([startStr, endStr]);

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM booking_units bu
      JOIN bookings b ON bu.booking_id = b.id
      WHERE bu.unit_id = ? 
        AND b.status NOT IN ('cancelled', 'checkedOut')
        $excludeClause
        AND (bu.start_date < ? AND bu.end_date > ?)
    ''', whereArgs);
    final count = result.first['count'] as int? ?? 0;
    return count == 0;
  }

  @override
  Future<void> updateBookingStatus(int bookingId, String status) async {
    final db = await _dbHelper.executor;
    await db.update('bookings', {
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [bookingId]);
  }

  @override
  Future<List<int>> getUnitIdsForBooking(int bookingId) async {
    final db = await _dbHelper.executor;
    final results = await db.query('booking_units', columns: ['unit_id'], where: 'booking_id = ?', whereArgs: [bookingId]);
    return results.map((row) => row['unit_id'] as int).toList();
  }

  @override
  Future<List<int>> getGuestIdsForBooking(int bookingId) async {
    final db = await _dbHelper.executor;
    final results = await db.query('booking_guests', columns: ['guest_id'], where: 'booking_id = ?', whereArgs: [bookingId]);
    return results.map((row) => row['guest_id'] as int).toList();
  }
}
