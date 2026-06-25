import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/features/expenses/domain/entities/expense.dart';
import 'package:property_management_system/features/expenses/domain/entities/expense_category.dart';
import 'package:property_management_system/features/expenses/domain/repositories/expense_repository.dart';
import 'package:property_management_system/features/expenses/domain/usecases/get_expense_categories.dart';

class FakeExpenseRepository implements ExpenseRepository {
  final List<ExpenseCategory> _categories = [];

  void addCategory(ExpenseCategory category) => _categories.add(category);

  @override
  Future<int> createExpense(Expense expense) async => 1;

  @override
  Future<void> updateExpense(Expense expense) async {}

  @override
  Future<List<Expense>> getExpensesForProperty(int propertyId, {bool includeArchived = false}) async => [];

  @override
  Future<List<ExpenseCategory>> getExpenseCategories() async => _categories;

  @override
  Future<void> deleteExpense(int expenseId, int userId) async {}
}

void main() {
  late FakeExpenseRepository repository;
  late GetExpenseCategories useCase;

  setUp(() {
    repository = FakeExpenseRepository();
    useCase = GetExpenseCategories(repository);
  });

  test('should return empty list when no categories exist', () async {
    final result = await useCase();
    expect(result, isEmpty);
  });

  test('should return all categories', () async {
    repository.addCategory(ExpenseCategory(
      id: 1, uuid: '', name: 'نظافة', createdAt: DateTime.now(), updatedAt: DateTime.now(),
    ));
    repository.addCategory(ExpenseCategory(
      id: 2, uuid: '', name: 'صيانة', createdAt: DateTime.now(), updatedAt: DateTime.now(),
    ));

    final result = await useCase();
    expect(result.length, 2);
    expect(result[0].name, 'نظافة');
    expect(result[1].name, 'صيانة');
  });
}
