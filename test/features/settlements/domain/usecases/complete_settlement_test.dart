import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/enums/user_role.dart';
import 'package:property_management_system/core/errors/failure.dart';
import 'package:property_management_system/core/contracts/audit_logger.dart';
import 'package:property_management_system/features/settlements/domain/entities/settlement.dart';
import 'package:property_management_system/features/settlements/domain/entities/settlement_correction.dart';
import 'package:property_management_system/features/settlements/domain/repositories/settlement_repository.dart';
import 'package:property_management_system/features/settlements/domain/usecases/complete_settlement.dart';

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

class FakeSettlementRepository implements SettlementRepository {
  bool completeCalled = false;
  int? completedSettlementId;
  int? completedByUserId;

  @override
  Future<int> createSettlement(Settlement settlement) async => 1;

  @override
  Future<List<Settlement>> getSettlementsForBooking(int bookingId) async => [];

  @override
  Future<void> completeSettlement(int settlementId, int userId) async {
    completeCalled = true;
    completedSettlementId = settlementId;
    completedByUserId = userId;
  }

  @override
  Future<void> cancelSettlement(int settlementId, int userId) async {}

  @override
  Future<int> addCorrection(SettlementCorrection correction) async => 1;

  @override
  Future<List<SettlementCorrection>> getCorrections(int settlementId) async => [];
}

void main() {
  late FakeSettlementRepository repository;
  late FakeAuditLogger auditLogger;
  late CompleteSettlement useCase;

  setUp(() {
    repository = FakeSettlementRepository();
    auditLogger = FakeAuditLogger();
    useCase = CompleteSettlement(repository, auditLogger);
  });

  test('should throw AuthorizationFailure if role lacks permission', () async {
    expect(
      () => useCase(1, 1, role: UserRole.receptionist),
      throwsA(isA<AuthorizationFailure>().having((f) => f.code, 'code', 'PERMISSION_DENIED')),
    );
  });

  test('should successfully complete settlement and log audit event', () async {
    await useCase(2, 42, role: UserRole.accountant);

    expect(repository.completeCalled, isTrue);
    expect(repository.completedSettlementId, 2);
    expect(repository.completedByUserId, 42);
    expect(auditLogger.logCount, 1);
    expect(auditLogger.loggedEvents.first['action'], 'complete');
    expect(auditLogger.loggedEvents.first['entityId'], 2);
  });
}
