library;

import '../../../../core/common/enums/user_role.dart';
import '../../../../core/common/utils/permissions.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class RecordPayment {
  final PaymentRepository _repository;
  final AuditLogger _auditService;

  RecordPayment(this._repository, this._auditService);

  Future<int> call(Payment payment, int userId, {UserRole? role}) async {
    final perm = checkPermission(role ?? UserRole.receptionist, PermissionAction.recordPayment);
    if (perm != null) throw perm;
    final id = await _repository.recordPayment(payment);
    await _auditService.log(
      propertyId: payment.propertyId,
      userId: userId,
      entityType: 'payment',
      entityId: id,
      action: 'record',
      description: 'تسجيل دفعة بقيمة ${payment.amount} للحجز رقم ${payment.bookingId}',
      newValues: {'amount': payment.amount.minorUnits, 'method': payment.paymentMethod.name},
    );
    return id;
  }
}
