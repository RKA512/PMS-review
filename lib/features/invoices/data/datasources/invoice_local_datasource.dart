library;

abstract class InvoiceLocalDataSource {
  Future<Map<String, dynamic>?> getInvoiceById(int id);
  Future<Map<String, dynamic>?> getInvoiceByBookingId(int bookingId);
  Future<int> addInvoice(Map<String, dynamic> map);
  Future<void> updateInvoice(Map<String, dynamic> map, int id);
  Future<List<Map<String, dynamic>>> getLinesByInvoiceId(int invoiceId);
  Future<List<Map<String, dynamic>>> getAdjustmentsByInvoiceId(int invoiceId);
  Future<void> insertLine(Map<String, dynamic> map);
  Future<void> insertAdjustment(Map<String, dynamic> map);
  Future<Map<String, dynamic>?> getLineById(int lineId);
  Future<void> deleteLine(int lineId);
  Future<void> deleteLinesByInvoiceId(int invoiceId);
  Future<void> deleteAdjustmentsByInvoiceId(int invoiceId);
  Future<int> updateInvoiceStatus(int invoiceId, Map<String, dynamic> values);
  Future<List<Map<String, dynamic>>> getInvoicesByAccount(int accountId);
  Future<List<Map<String, dynamic>>> getBatchLines(List<int> invoiceIds);
  Future<List<Map<String, dynamic>>> getBatchAdjustments(List<int> invoiceIds);
  Future<List<Map<String, dynamic>>> getUninvoicedBookings();
  Future<int> createInvoiceWithDetails(Map<String, dynamic> invoiceMap, List<Map<String, dynamic>> lines, List<Map<String, dynamic>> adjustments);
}
