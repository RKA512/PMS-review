library;

import '../../../../core/common/enums/user_role.dart';
import '../../../../core/common/utils/permissions.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class UpdateExpense {
  final ExpenseRepository _repository;
  final AuditLogger _auditService;

  UpdateExpense(this._repository, this._auditService);

  Future<void> call(Expense expense, int userId, {UserRole? role}) async {
    final perm = checkPermission(role ?? UserRole.receptionist, PermissionAction.editExpense);
    if (perm != null) throw perm;
    await _repository.updateExpense(expense);
    await _auditService.log(
      propertyId: expense.propertyId,
      userId: userId,
      entityType: 'expense',
      entityId: expense.id!,
      action: 'update',
      description: 'تحديث مصروف رقم ${expense.id}',
    );
  }
}
