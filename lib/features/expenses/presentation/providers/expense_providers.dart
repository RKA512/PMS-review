library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/audit_service.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/datasources/expense_local_datasource_impl.dart';
import '../../domain/usecases/create_expense.dart';
import '../../domain/usecases/update_expense.dart';
import '../../domain/usecases/get_expenses.dart';
import '../../domain/usecases/get_expense_categories.dart';
import '../../domain/usecases/delete_expense.dart';

final expenseLocalDataSourceProvider = Provider((ref) {
  return ExpenseLocalDataSourceImpl(DatabaseHelper.instance);
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(ref.watch(expenseLocalDataSourceProvider));
});

final createExpenseUseCaseProvider = Provider<CreateExpense>((ref) {
  return CreateExpense(ref.watch(expenseRepositoryProvider), ref.watch(auditServiceProvider));
});

final updateExpenseUseCaseProvider = Provider<UpdateExpense>((ref) {
  return UpdateExpense(ref.watch(expenseRepositoryProvider), ref.watch(auditServiceProvider));
});

final getExpensesUseCaseProvider = Provider<GetExpenses>((ref) {
  return GetExpenses(ref.watch(expenseRepositoryProvider));
});

final getExpenseCategoriesUseCaseProvider = Provider<GetExpenseCategories>((ref) {
  return GetExpenseCategories(ref.watch(expenseRepositoryProvider));
});

final deleteExpenseUseCaseProvider = Provider<DeleteExpense>((ref) {
  return DeleteExpense(ref.watch(expenseRepositoryProvider), ref.watch(auditServiceProvider));
});
