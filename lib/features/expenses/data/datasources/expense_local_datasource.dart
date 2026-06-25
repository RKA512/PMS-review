library;

abstract class ExpenseLocalDataSource {
  Future<int> insertExpense(Map<String, dynamic> map);
  Future<void> updateExpense(Map<String, dynamic> map, int id);
  Future<List<Map<String, dynamic>>> getExpensesByProperty(int propertyId, bool includeArchived);
  Future<Map<String, dynamic>?> getExpenseById(int id);
  Future<List<Map<String, dynamic>>> getExpenseCategories();
  Future<Map<String, dynamic>?> getExpenseCategoryById(int id);
}
