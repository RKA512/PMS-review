library;

import '../../../../core/common/enums/user_role.dart';
import '../../../../core/common/utils/permissions.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class CreateExpense {
  final ExpenseRepository _repository;
  final AuditLogger _auditService;

  CreateExpense(this._repository, this._auditService);

  Future<int> call(Expense expense, int userId, {UserRole? role}) async {
    final perm = checkPermission(role ?? UserRole.receptionist, PermissionAction.createExpense);
    if (perm != null) throw perm;
    final id = await _repository.createExpense(expense);
    await _auditService.log(
      propertyId: expense.propertyId,
      userId: userId,
      entityType: 'expense',
      entityId: id,
      action: 'create',
      description: 'تسجيل مصروف بقيمة ${expense.amount}',
    );
    return id;
  }
}
