import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/enums/user_role.dart';
import 'package:property_management_system/core/errors/failure.dart';
import 'package:property_management_system/core/contracts/audit_logger.dart';
import 'package:property_management_system/features/payments/domain/entities/payment.dart';
import 'package:property_management_system/features/payments/domain/repositories/payment_repository.dart';
import 'package:property_management_system/features/payments/domain/usecases/void_payment.dart';

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
  bool voidCalled = false;
  int? voidedPaymentId;
  int? voidedByUserId;

  @override
  Future<int> recordPayment(Payment payment) async => 1;

  @override
  Future<List<Payment>> getPaymentsForInvoice(int invoiceId) async => [];

  @override
  Future<List<Payment>> getPaymentsForBooking(int bookingId) async => [];

  @override
  Future<void> voidPayment(int paymentId, int userId) async {
    voidCalled = true;
    voidedPaymentId = paymentId;
    voidedByUserId = userId;
  }
}

void main() {
  late FakePaymentRepository repository;
  late FakeAuditLogger auditLogger;
  late VoidPayment useCase;

  setUp(() {
    repository = FakePaymentRepository();
    auditLogger = FakeAuditLogger();
    useCase = VoidPayment(repository, auditLogger);
  });

  test('should throw AuthorizationFailure if role lacks permission', () async {
    expect(
      () => useCase(1, 1, role: UserRole.receptionist),
      throwsA(isA<AuthorizationFailure>().having((f) => f.code, 'code', 'PERMISSION_DENIED')),
    );
  });

  test('should successfully void payment and log audit event', () async {
    await useCase(3, 42, role: UserRole.accountant);

    expect(repository.voidCalled, isTrue);
    expect(repository.voidedPaymentId, 3);
    expect(repository.voidedByUserId, 42);
    expect(auditLogger.logCount, 1);
    expect(auditLogger.loggedEvents.first['action'], 'void');
    expect(auditLogger.loggedEvents.first['entityId'], 3);
  });
}
