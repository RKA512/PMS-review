library;

import '../../../../core/common/enums/user_role.dart';
import '../../../../core/common/utils/permissions.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../entities/settlement.dart';
import '../repositories/settlement_repository.dart';

class CreateSettlement {
  final SettlementRepository _repository;
  final AuditLogger _auditService;

  CreateSettlement(this._repository, this._auditService);

  Future<int> call(Settlement settlement, int userId, {UserRole? role}) async {
    final perm = checkPermission(role ?? UserRole.receptionist, PermissionAction.createSettlement);
    if (perm != null) throw perm;
    final id = await _repository.createSettlement(settlement);
    await _auditService.log(
      propertyId: settlement.propertyId,
      userId: userId,
      entityType: 'settlement',
      entityId: id,
      action: 'create',
      description: 'إنشاء تسوية ${settlement.settlementType.name} بقيمة ${settlement.differenceAmount}',
    );
    return id;
  }
}
