import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/enums/user_role.dart';
import 'package:property_management_system/core/common/models/money.dart';
import 'package:property_management_system/core/errors/failure.dart';
import 'package:property_management_system/core/contracts/audit_logger.dart';
import 'package:property_management_system/features/expenses/domain/entities/expense.dart';
import 'package:property_management_system/features/expenses/domain/entities/expense_category.dart';
import 'package:property_management_system/features/expenses/domain/repositories/expense_repository.dart';
import 'package:property_management_system/features/expenses/domain/usecases/create_expense.dart';

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
  final Map<int, Expense> expenses = {};
  int _idCounter = 1;

  @override
  Future<int> createExpense(Expense expense) async {
    final id = _idCounter++;
    expenses[id] = expense.copyWith(id: id);
    return id;
  }

  @override
  Future<void> updateExpense(Expense expense) async {}

  @override
  Future<List<Expense>> getExpensesForProperty(int propertyId, {bool includeArchived = false}) async {
    return [];
  }

  @override
  Future<List<ExpenseCategory>> getExpenseCategories() async {
    return [];
  }

  @override
  Future<void> deleteExpense(int expenseId, int userId) async {}
}

void main() {
  late FakeExpenseRepository repository;
  late FakeAuditLogger auditLogger;
  late CreateExpense useCase;

  setUp(() {
    repository = FakeExpenseRepository();
    auditLogger = FakeAuditLogger();
    useCase = CreateExpense(repository, auditLogger);
  });

  Expense createTemplateExpense() {
    return Expense(
      id: null,
      uuid: '',
      propertyId: 1,
      expenseCategoryId: 1,
      amount: const Money(500),
      description: 'مصروف اختبار',
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

  test('should successfully create expense and log audit event', () async {
    final expense = createTemplateExpense();
    final id = await useCase(expense, 42, role: UserRole.accountant);

    expect(id, 1);
    expect(repository.expenses[1], isNotNull);
    expect(repository.expenses[1]!.amount, const Money(500));
    expect(repository.expenses[1]!.description, 'مصروف اختبار');
    expect(auditLogger.logCount, 1);
    expect(auditLogger.loggedEvents.first['userId'], 42);
    expect(auditLogger.loggedEvents.first['entityType'], 'expense');
    expect(auditLogger.loggedEvents.first['entityId'], 1);
    expect(auditLogger.loggedEvents.first['action'], 'create');
  });
}
