import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/enums/payment_method.dart';
import 'package:property_management_system/core/common/enums/payment_type.dart';
import 'package:property_management_system/core/common/enums/user_role.dart';
import 'package:property_management_system/core/common/models/money.dart';
import 'package:property_management_system/core/errors/failure.dart';
import 'package:property_management_system/core/contracts/audit_logger.dart';
import 'package:property_management_system/features/payments/domain/entities/payment.dart';
import 'package:property_management_system/features/payments/domain/repositories/payment_repository.dart';
import 'package:property_management_system/features/payments/domain/usecases/record_payment.dart';

class FakeAuditLogger implements AuditLogger {
  int logCount = 0;
  List<Map<String, dynamic>> loggedEvents = [];

  @override
  Future<int> log({
    int? propertyId,
    required int userId,
    required String entityType,
    required int entityId,
    required String action,
    required String description,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  }) async {
    logCount++;
    loggedEvents.add({
      'propertyId': propertyId,
      'userId': userId,
      'entityType': entityType,
      'entityId': entityId,
      'action': action,
      'description': description,
      'oldValues': oldValues,
      'newValues': newValues,
    });
    return logCount;
  }
}

class FakePaymentRepository implements PaymentRepository {
  final Map<int, Payment> payments = {};
  int _idCounter = 1;

  @override
  Future<int> recordPayment(Payment payment) async {
    final id = _idCounter++;
    payments[id] = payment.copyWith(id: id);
    return id;
  }

  @override
  Future<List<Payment>> getPaymentsForInvoice(int invoiceId) async {
    return payments.values.where((p) => p.invoiceId == invoiceId).toList();
  }

  @override
  Future<List<Payment>> getPaymentsForBooking(int bookingId) async {
    return payments.values.where((p) => p.bookingId == bookingId).toList();
  }

  @override
  Future<void> voidPayment(int paymentId, int userId) async {}
}

void main() {
  late FakePaymentRepository repository;
  late FakeAuditLogger auditLogger;
  late RecordPayment useCase;

  setUp(() {
    repository = FakePaymentRepository();
    auditLogger = FakeAuditLogger();
    useCase = RecordPayment(repository, auditLogger);
  });

  Payment createTemplatePayment() {
    return Payment(
      id: null,
      uuid: '',
      propertyId: 1,
      bookingId: 10,
      invoiceId: 100,
      amount: const Money(1500),
      paymentMethod: PaymentMethod.cash,
      paymentType: PaymentType.incoming,
      referenceNumber: 'REF-001',
      createdBy: 1,
      createdAt: DateTime.now(),
    );
  }

  test('should throw AuthorizationFailure if role lacks permission', () async {
    final payment = createTemplatePayment();
    expect(
      () => useCase(payment, 1, role: UserRole.receptionist),
      throwsA(isA<AuthorizationFailure>().having((f) => f.code, 'code', 'PERMISSION_DENIED')),
    );
  });

  test('should successfully record payment and log audit event', () async {
    final payment = createTemplatePayment();
    final id = await useCase(payment, 42, role: UserRole.accountant);

    expect(id, 1);
    expect(repository.payments[1], isNotNull);
    expect(repository.payments[1]!.amount, const Money(1500));
    expect(repository.payments[1]!.paymentMethod, PaymentMethod.cash);
    expect(repository.payments[1]!.invoiceId, 100);
    expect(auditLogger.logCount, 1);
    expect(auditLogger.loggedEvents.first['action'], 'record');
    expect(auditLogger.loggedEvents.first['entityId'], 1);
    expect(auditLogger.loggedEvents.first['newValues'], isNotNull);
  });
}
