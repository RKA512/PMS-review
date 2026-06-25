library;

abstract class GuestLocalDataSource {
  Future<List<Map<String, dynamic>>> getGuests(int accountId, bool includeArchived);
  Future<Map<String, dynamic>?> getGuestById(int id);
  Future<Map<String, dynamic>?> getGuestByDocument(int accountId, String documentType, String documentNumber);
  Future<List<Map<String, dynamic>>> searchGuests(int accountId, String query, bool includeArchived);
  Future<int> insertGuest(Map<String, dynamic> map);
  Future<void> updateGuest(Map<String, dynamic> map, int id);
  Future<void> archiveGuest(int id, String now);
  Future<void> unarchiveGuest(int id, String now);
  Future<List<Map<String, dynamic>>> getGuestContacts(int guestId);
  Future<void> insertGuestContact(Map<String, dynamic> map);
  Future<void> updateGuestContact(Map<String, dynamic> map, int id);
  Future<void> deleteGuestContact(int contactId);
  Future<void> deleteGuestContactsByGuestId(int guestId);
  Future<int> createGuestWithContacts(Map<String, dynamic> guestMap, List<Map<String, dynamic>> contactMaps);
  Future<void> updateGuestWithContacts(Map<String, dynamic> guestMap, List<Map<String, dynamic>> contactMaps, int guestId);
}
