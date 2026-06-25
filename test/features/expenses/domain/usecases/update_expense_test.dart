import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/enums/user_role.dart';
import 'package:property_management_system/core/common/models/money.dart';
import 'package:property_management_system/core/errors/failure.dart';
import 'package:property_management_system/core/contracts/audit_logger.dart';
import 'package:property_management_system/features/expenses/domain/entities/expense.dart';
import 'package:property_management_system/features/expenses/domain/entities/expense_category.dart';
import 'package:property_management_system/features/expenses/domain/repositories/expense_repository.dart';
import 'package:property_management_system/features/expenses/domain/usecases/update_expense.dart';

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

class FakeExpenseRepository implements ExpenseRepository {
  bool updateCalled = false;
  Expense? updatedExpense;

  @override
  Future<int> createExpense(Expense expense) async => 1;

  @override
  Future<void> updateExpense(Expense expense) async {
    updateCalled = true;
    updatedExpense = expense;
  }

  @override
  Future<List<Expense>> getExpensesForProperty(int propertyId, {bool includeArchived = false}) async => [];

  @override
  Future<List<ExpenseCategory>> getExpenseCategories() async => [];

  @override
  Future<void> deleteExpense(int expenseId, int userId) async {}
}

void main() {
  late FakeExpenseRepository repository;
  late FakeAuditLogger auditLogger;
  late UpdateExpense useCase;

  setUp(() {
    repository = FakeExpenseRepository();
    auditLogger = FakeAuditLogger();
    useCase = UpdateExpense(repository, auditLogger);
  });

  Expense createTemplateExpense({int id = 1}) {
    return Expense(
      id: id,
      uuid: 'uuid-123',
      propertyId: 1,
      expenseCategoryId: 1,
      amount: const Money(750),
      description: 'مصروف محدّث',
      expenseDate: DateTime.now(),
      createdBy: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  test('should throw AuthorizationFailure if role lacks permission', () async {
    final expense = createTemplateExpense();
    expect(
      () => useCase(expense, 1, role: UserRole.receptionist),
      throwsA(isA<AuthorizationFailure>().having((f) => f.code, 'code', 'PERMISSION_DENIED')),
    );
  });

  test('should successfully update expense and log audit event', () async {
    final expense = createTemplateExpense();
    await useCase(expense, 42, role: UserRole.accountant);

    expect(repository.updateCalled, isTrue);
    expect(repository.updatedExpense!.id, 1);
    expect(repository.updatedExpense!.description, 'مصروف محدّث');
    expect(auditLogger.logCount, 1);
    expect(auditLogger.loggedEvents.first['action'], 'update');
    expect(auditLogger.loggedEvents.first['entityId'], 1);
  });
}
