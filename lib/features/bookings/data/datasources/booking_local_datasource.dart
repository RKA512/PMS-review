library;

abstract class BookingLocalDataSource {
  Future<int> insertBookingRow(Map<String, dynamic> map);
  Future<void> insertBookingUnit(Map<String, dynamic> map);
  Future<void> insertBookingGuest(Map<String, dynamic> map);
  Future<void> updateBooking(Map<String, dynamic> values, int id);
  Future<Map<String, dynamic>?> getBookingById(int id);
  Future<Map<String, dynamic>?> getBookingByNumber(String bookingNumber);
  Future<List<Map<String, dynamic>>> getBookingsForProperty(int propertyId);
  Future<bool> isUnitAvailable(int unitId, String startStr, String endStr, int? excludeBookingId);
  Future<void> updateBookingStatus(int bookingId, String status);
  Future<List<int>> getUnitIdsForBooking(int bookingId);
  Future<List<int>> getGuestIdsForBooking(int bookingId);
}
