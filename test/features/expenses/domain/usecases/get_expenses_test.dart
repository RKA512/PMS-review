import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/models/money.dart';
import 'package:property_management_system/features/expenses/domain/entities/expense.dart';
import 'package:property_management_system/features/expenses/domain/entities/expense_category.dart';
import 'package:property_management_system/features/expenses/domain/repositories/expense_repository.dart';
import 'package:property_management_system/features/expenses/domain/usecases/get_expenses.dart';

class FakeExpenseRepository implements ExpenseRepository {
  final List<Expense> _expenses = [];

  void addExpense(Expense expense) => _expenses.add(expense);

  @override
  Future<int> createExpense(Expense expense) async => 1;

  @override
  Future<void> updateExpense(Expense expense) async {}

  @override
  Future<List<Expense>> getExpensesForProperty(int propertyId, {bool includeArchived = false}) async {
    return _expenses.where((e) => e.propertyId == propertyId).toList();
  }

  @override
  Future<List<ExpenseCategory>> getExpenseCategories() async => [];

  @override
  Future<void> deleteExpense(int expenseId, int userId) async {}
}

void main() {
  late FakeExpenseRepository repository;
  late GetExpenses useCase;

  setUp(() {
    repository = FakeExpenseRepository();
    useCase = GetExpenses(repository);
  });

  test('should return empty list when no expenses exist for property', () async {
    final result = await useCase(1);
    expect(result, isEmpty);
  });

  test('should return expenses for the given property', () async {
    repository.addExpense(Expense(
      id: 1, uuid: '', propertyId: 1, expenseCategoryId: 1,
      amount: const Money(200), description: 'مصروف أ', expenseDate: DateTime.now(),
      createdBy: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(),
    ));
    repository.addExpense(Expense(
      id: 2, uuid: '', propertyId: 1, expenseCategoryId: 1,
      amount: const Money(300), description: 'مصروف ب', expenseDate: DateTime.now(),
      createdBy: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(),
    ));

    final result = await useCase(1);
    expect(result.length, 2);
    expect(result[0].description, 'مصروف أ');
    expect(result[1].description, 'مصروف ب');
  });

  test('should not return expenses for other properties', () async {
    repository.addExpense(Expense(
      id: 1, uuid: '', propertyId: 2, expenseCategoryId: 1,
      amount: const Money(100), description: 'لمنشأة أخرى', expenseDate: DateTime.now(),
      createdBy: 1, createdAt: DateTime.now(), updatedAt: DateTime.now(),
    ));

    final result = await useCase(1);
    expect(result, isEmpty);
  });
}
