library;

import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class GetPaymentsForInvoice {
  final PaymentRepository _repository;

  GetPaymentsForInvoice(this._repository);

  Future<List<Payment>> call(int invoiceId) => _repository.getPaymentsForInvoice(invoiceId);
}
