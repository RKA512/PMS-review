library;

import '../../../../core/common/enums/user_role.dart';
import '../../../../core/common/utils/permissions.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../repositories/expense_repository.dart';

class DeleteExpense {
  final ExpenseRepository _repository;
  final AuditLogger _auditService;

  DeleteExpense(this._repository, this._auditService);

  Future<void> call(int expenseId, int userId, {UserRole? role}) async {
    final perm = checkPermission(role ?? UserRole.receptionist, PermissionAction.deleteExpense);
    if (perm != null) throw perm;
    await _repository.deleteExpense(expenseId, userId);
    await _auditService.log(
      userId: userId,
      entityType: 'expense',
      entityId: expenseId,
      action: 'delete',
      description: 'حذف مصروف رقم $expenseId',
    );
  }
}
