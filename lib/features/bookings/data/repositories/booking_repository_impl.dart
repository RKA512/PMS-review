/// Why the file exists:
/// SQLite implementation of the BookingRepository interface.
/// Implements [AR-302 (Repository Implementation inside data/repositories)] and database actions in [Flow 04].
/// Delegates raw SQL to BookingLocalDataSource; focuses on domain mapping.
library;

import 'dart:async';
import '../../../../core/common/enums/booking_status.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_local_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingLocalDataSource _dataSource;

  BookingRepositoryImpl(this._dataSource);

  @override
  Future<int> insertBookingRow(Booking booking) async {
    return await _dataSource.insertBookingRow({
      'uuid': booking.uuid,
      'property_id': booking.propertyId,
      'primary_guest_id': booking.primaryGuestId,
      'booking_number': booking.bookingNumber,
      'status': booking.status.toJson(),
      'check_in_date': booking.checkInDate.toIso8601String(),
      'check_out_date': booking.checkOutDate.toIso8601String(),
      'source': booking.source,
      'notes': booking.notes,
      'created_by': booking.createdBy,
      'created_at': booking.createdAt.toIso8601String(),
      'updated_at': booking.updatedAt.toIso8601String(),
    });
  }

  @override
  Future<void> insertBookingUnit({
    required int bookingId,
    required int unitId,
    required DateTime startDate,
    required DateTime endDate,
    required String uuid,
  }) async {
    await _dataSource.insertBookingUnit({
      'uuid': uuid,
      'booking_id': bookingId,
      'unit_id': unitId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'nightly_rate': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> insertBookingGuest({
    required int bookingId,
    required int guestId,
  }) async {
    await _dataSource.insertBookingGuest({
      'booking_id': bookingId,
      'guest_id': guestId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateBooking(Booking booking) async {
    await _dataSource.updateBooking({
      'notes': booking.notes,
      'source': booking.source,
      'check_in_date': booking.checkInDate.toIso8601String(),
      'check_out_date': booking.checkOutDate.toIso8601String(),
      'updated_at': booking.updatedAt.toIso8601String(),
    }, booking.id!);
  }

  @override
  Future<Booking?> getBookingById(int id) async {
    final row = await _dataSource.getBookingById(id);
    if (row == null) return null;
    return _mapToBooking(row);
  }

  @override
  Future<Booking?> getBookingByNumber(String bookingNumber) async {
    final row = await _dataSource.getBookingByNumber(bookingNumber);
    if (row == null) return null;
    return _mapToBooking(row);
  }

  @override
  Future<List<Booking>> getBookingsForProperty(int propertyId) async {
    final rows = await _dataSource.getBookingsForProperty(propertyId);
    return rows.map(_mapToBooking).toList();
  }

  @override
  Future<bool> isUnitAvailable({
    required int unitId,
    required DateTime start,
    required DateTime end,
    int? excludeBookingId,
  }) async {
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();
    return await _dataSource.isUnitAvailable(unitId, startStr, endStr, excludeBookingId);
  }

  @override
  Future<void> updateBookingStatus({
    required int bookingId,
    required String status,
    required int updatedByUserId,
  }) async {
    await _dataSource.updateBookingStatus(bookingId, status);
  }

  @override
  Future<List<int>> getUnitIdsForBooking(int bookingId) async {
    return await _dataSource.getUnitIdsForBooking(bookingId);
  }

  @override
  Future<List<int>> getGuestIdsForBooking(int bookingId) async {
    return await _dataSource.getGuestIdsForBooking(bookingId);
  }

  Booking _mapToBooking(Map<String, dynamic> row) {
    return Booking(
      id: row['id'] as int?,
      uuid: row['uuid'] as String,
      propertyId: row['property_id'] as int,
      primaryGuestId: row['primary_guest_id'] as int,
      bookingNumber: row['booking_number'] as String,
      status: BookingStatus.fromJson(row['status'] as String),
      checkInDate: DateTime.parse(row['check_in_date'] as String),
      checkOutDate: DateTime.parse(row['check_out_date'] as String),
      actualCheckIn: row['actual_check_in'] != null ? DateTime.parse(row['actual_check_in'] as String) : null,
      actualCheckOut: row['actual_check_out'] != null ? DateTime.parse(row['actual_check_out'] as String) : null,
      source: row['source'] as String?,
      notes: row['notes'] as String?,
      createdBy: row['created_by'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
