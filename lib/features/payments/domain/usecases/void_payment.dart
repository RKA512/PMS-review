library;

import '../../../../core/common/enums/user_role.dart';
import '../../../../core/common/utils/permissions.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../repositories/payment_repository.dart';

class VoidPayment {
  final PaymentRepository _repository;
  final AuditLogger _auditService;

  VoidPayment(this._repository, this._auditService);

  Future<void> call(int paymentId, int userId, {UserRole? role}) async {
    final perm = checkPermission(role ?? UserRole.receptionist, PermissionAction.voidPayment);
    if (perm != null) throw perm;
    await _repository.voidPayment(paymentId, userId);
    await _auditService.log(
      userId: userId,
      entityType: 'payment',
      entityId: paymentId,
      action: 'void',
      description: 'إلغاء دفعة رقم $paymentId',
    );
  }
}
