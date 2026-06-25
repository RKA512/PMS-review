library;

import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<int> recordPayment(Payment payment);
  Future<List<Payment>> getPaymentsForInvoice(int invoiceId);
  Future<List<Payment>> getPaymentsForBooking(int bookingId);
  Future<void> voidPayment(int paymentId, int userId);
}
