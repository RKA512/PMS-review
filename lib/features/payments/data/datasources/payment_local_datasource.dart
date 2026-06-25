library;

abstract class PaymentLocalDataSource {
  Future<int> insertPayment(Map<String, dynamic> map);
  Future<List<Map<String, dynamic>>> getPaymentsByInvoice(int invoiceId);
  Future<List<Map<String, dynamic>>> getPaymentsByBooking(int bookingId);
  Future<void> updatePayment(int id, Map<String, dynamic> values);
  Future<Map<String, dynamic>?> getPaymentById(int id);
}
