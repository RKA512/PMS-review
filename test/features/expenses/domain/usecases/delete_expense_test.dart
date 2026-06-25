import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/enums/user_role.dart';
import 'package:property_management_system/core/errors/failure.dart';
import 'package:property_management_system/core/contracts/audit_logger.dart';
import 'package:property_management_system/features/expenses/domain/entities/expense.dart';
import 'package:property_management_system/features/expenses/domain/entities/expense_category.dart';
import 'package:property_management_system/features/expenses/domain/repositories/expense_repository.dart';
import 'package:property_management_system/features/expenses/domain/usecases/delete_expense.dart';

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
  bool deleteCalled = false;
  int? deletedExpenseId;
  int? deletedByUserId;

  @override
  Future<int> createExpense(Expense expense) async => 1;

  @override
  Future<void> updateExpense(Expense expense) async {}

  @override
  Future<List<Expense>> getExpensesForProperty(int propertyId, {bool includeArchived = false}) async => [];

  @override
  Future<List<ExpenseCategory>> getExpenseCategories() async => [];

  @override
  Future<void> deleteExpense(int expenseId, int userId) async {
    deleteCalled = true;
    deletedExpenseId = expenseId;
    deletedByUserId = userId;
  }
}

void main() {
  late FakeExpenseRepository repository;
  late FakeAuditLogger auditLogger;
  late DeleteExpense useCase;

  setUp(() {
    repository = FakeExpenseRepository();
    auditLogger = FakeAuditLogger();
    useCase = DeleteExpense(repository, auditLogger);
  });

  test('should throw AuthorizationFailure if role lacks permission', () async {
    expect(
      () => useCase(1, 1, role: UserRole.receptionist),
      throwsA(isA<AuthorizationFailure>().having((f) => f.code, 'code', 'PERMISSION_DENIED')),
    );
  });

  test('should successfully delete expense and log audit event', () async {
    await useCase(5, 42, role: UserRole.accountant);

    expect(repository.deleteCalled, isTrue);
    expect(repository.deletedExpenseId, 5);
    expect(repository.deletedByUserId, 42);
    expect(auditLogger.logCount, 1);
    expect(auditLogger.loggedEvents.first['action'], 'delete');
    expect(auditLogger.loggedEvents.first['entityId'], 5);
  });
}
