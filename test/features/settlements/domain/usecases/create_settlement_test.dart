import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/enums/settlement_status.dart';
import 'package:property_management_system/core/common/enums/settlement_type.dart';
import 'package:property_management_system/core/common/enums/user_role.dart';
import 'package:property_management_system/core/common/models/money.dart';
import 'package:property_management_system/core/errors/failure.dart';
import 'package:property_management_system/core/contracts/audit_logger.dart';
import 'package:property_management_system/features/settlements/domain/entities/settlement.dart';
import 'package:property_management_system/features/settlements/domain/entities/settlement_correction.dart';
import 'package:property_management_system/features/settlements/domain/repositories/settlement_repository.dart';
import 'package:property_management_system/features/settlements/domain/usecases/create_settlement.dart';

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
  final Map<int, Settlement> settlements = {};
  int _idCounter = 1;

  @override
  Future<int> createSettlement(Settlement settlement) async {
    final id = _idCounter++;
    settlements[id] = settlement.copyWith(id: id);
    return id;
  }

  @override
  Future<List<Settlement>> getSettlementsForBooking(int bookingId) async {
    return settlements.values.where((s) => s.bookingId == bookingId).toList();
  }

  @override
  Future<void> completeSettlement(int settlementId, int userId) async {}

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
  late CreateSettlement useCase;

  setUp(() {
    repository = FakeSettlementRepository();
    auditLogger = FakeAuditLogger();
    useCase = CreateSettlement(repository, auditLogger);
  });

  Settlement createTemplateSettlement() {
    return Settlement(
      id: null,
      uuid: '',
      propertyId: 1,
      bookingId: 10,
      settlementType: SettlementType.underpayment,
      status: SettlementStatus.pending,
      differenceAmount: const Money(500),
      reason: 'تسوية اختبار',
      createdBy: 1,
      createdAt: DateTime.now(),
    );
  }

  test('should throw AuthorizationFailure if role lacks permission', () async {
    final settlement = createTemplateSettlement();
    expect(
      () => useCase(settlement, 1, role: UserRole.receptionist),
      throwsA(isA<AuthorizationFailure>().having((f) => f.code, 'code', 'PERMISSION_DENIED')),
    );
  });

  test('should successfully create settlement and log audit event', () async {
    final settlement = createTemplateSettlement();
    final id = await useCase(settlement, 42, role: UserRole.accountant);

    expect(id, 1);
    expect(repository.settlements[1], isNotNull);
    expect(repository.settlements[1]!.settlementType, SettlementType.underpayment);
    expect(repository.settlements[1]!.differenceAmount, const Money(500));
    expect(repository.settlements[1]!.status, SettlementStatus.pending);
    expect(auditLogger.logCount, 1);
    expect(auditLogger.loggedEvents.first['action'], 'create');
    expect(auditLogger.loggedEvents.first['entityId'], 1);
  });
}
