library;

abstract class SettlementLocalDataSource {
  Future<int> insertSettlement(Map<String, dynamic> map);
  Future<List<Map<String, dynamic>>> getSettlementsByBooking(int bookingId);
  Future<Map<String, dynamic>?> getSettlementById(int id);
  Future<void> updateSettlement(int id, Map<String, dynamic> values);
  Future<int> insertCorrection(Map<String, dynamic> map);
  Future<List<Map<String, dynamic>>> getCorrectionsBySettlement(int settlementId);
}
