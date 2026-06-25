library;

import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpenses {
  final ExpenseRepository _repository;

  GetExpenses(this._repository);

  Future<List<Expense>> call(int propertyId, {bool includeArchived = false}) =>
      _repository.getExpensesForProperty(propertyId, includeArchived: includeArchived);
}
