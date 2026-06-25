library;

import '../entities/expense.dart';
import '../entities/expense_category.dart';

abstract class ExpenseRepository {
  Future<int> createExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<List<Expense>> getExpensesForProperty(int propertyId, {bool includeArchived = false});
  Future<List<ExpenseCategory>> getExpenseCategories();
  Future<void> deleteExpense(int expenseId, int userId);
}
