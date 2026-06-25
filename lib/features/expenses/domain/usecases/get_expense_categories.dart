library;

import '../entities/expense_category.dart';
import '../repositories/expense_repository.dart';

class GetExpenseCategories {
  final ExpenseRepository _repository;

  GetExpenseCategories(this._repository);

  Future<List<ExpenseCategory>> call() => _repository.getExpenseCategories();
}
