library;

import '../../../../core/common/enums/user_role.dart';
import '../../../../core/common/utils/permissions.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../repositories/settlement_repository.dart';

class CompleteSettlement {
  final SettlementRepository _repository;
  final AuditLogger _auditService;

  CompleteSettlement(this._repository, this._auditService);

  Future<void> call(int settlementId, int userId, {UserRole? role}) async {
    final perm = checkPermission(role ?? UserRole.receptionist, PermissionAction.completeSettlement);
    if (perm != null) throw perm;
    await _repository.completeSettlement(settlementId, userId);
    await _auditService.log(
      userId: userId,
      entityType: 'settlement',
      entityId: settlementId,
      action: 'complete',
      description: 'إكمال تسوية رقم $settlementId',
    );
  }
}
