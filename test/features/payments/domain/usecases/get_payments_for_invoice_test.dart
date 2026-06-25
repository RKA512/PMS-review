import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/enums/payment_method.dart';
import 'package:property_management_system/core/common/enums/payment_type.dart';
import 'package:property_management_system/core/common/models/money.dart';
import 'package:property_management_system/features/payments/domain/entities/payment.dart';
import 'package:property_management_system/features/payments/domain/repositories/payment_repository.dart';
import 'package:property_management_system/features/payments/domain/usecases/get_payments_for_invoice.dart';

class FakePaymentRepository implements PaymentRepository {
  final List<Payment> _payments = [];

  void addPayment(Payment payment) => _payments.add(payment);

  @override
  Future<int> recordPayment(Payment payment) async => 1;

  @override
  Future<List<Payment>> getPaymentsForInvoice(int invoiceId) async {
    return _payments.where((p) => p.invoiceId == invoiceId).toList();
  }

  @override
  Future<List<Payment>> getPaymentsForBooking(int bookingId) async {
    return _payments.where((p) => p.bookingId == bookingId).toList();
  }

  @override
  Future<void> voidPayment(int paymentId, int userId) async {}
}

void main() {
  late FakePaymentRepository repository;
  late GetPaymentsForInvoice useCase;

  setUp(() {
    repository = FakePaymentRepository();
    useCase = GetPaymentsForInvoice(repository);
  });

  test('should return empty list when no payments exist for invoice', () async {
    final result = await useCase(1);
    expect(result, isEmpty);
  });

  test('should return payments for the given invoice', () async {
    repository.addPayment(Payment(
      id: 1, uuid: '', propertyId: 1, bookingId: 10, invoiceId: 100,
      amount: const Money(1000), paymentMethod: PaymentMethod.cash,
      paymentType: PaymentType.incoming, createdBy: 1, createdAt: DateTime.now(),
    ));
    repository.addPayment(Payment(
      id: 2, uuid: '', propertyId: 1, bookingId: 10, invoiceId: 100,
      amount: const Money(500), paymentMethod: PaymentMethod.card,
      paymentType: PaymentType.incoming, createdBy: 1, createdAt: DateTime.now(),
    ));

    final result = await useCase(100);
    expect(result.length, 2);
    expect(result[0].amount, const Money(1000));
    expect(result[1].amount, const Money(500));
  });

  test('should not return payments for other invoices', () async {
    repository.addPayment(Payment(
      id: 1, uuid: '', propertyId: 1, bookingId: 10, invoiceId: 200,
      amount: const Money(1000), paymentMethod: PaymentMethod.cash,
      paymentType: PaymentType.incoming, createdBy: 1, createdAt: DateTime.now(),
    ));

    final result = await useCase(100);
    expect(result, isEmpty);
  });
}
