library;

import '../../../../core/common/enums/user_role.dart';
import '../../../../core/common/utils/permissions.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../repositories/settlement_repository.dart';

class CancelSettlement {
  final SettlementRepository _repository;
  final AuditLogger _auditService;

  CancelSettlement(this._repository, this._auditService);

  Future<void> call(int settlementId, int userId, {UserRole? role}) async {
    final perm = checkPermission(role ?? UserRole.receptionist, PermissionAction.cancelSettlement);
    if (perm != null) throw perm;
    await _repository.cancelSettlement(settlementId, userId);
    await _auditService.log(
      userId: userId,
      entityType: 'settlement',
      entityId: settlementId,
      action: 'cancel',
      description: 'إلغاء تسوية رقم $settlementId',
    );
  }
}
