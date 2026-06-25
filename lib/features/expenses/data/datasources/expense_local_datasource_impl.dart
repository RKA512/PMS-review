library;

import '../../../../../core/database/database_helper.dart';
import 'expense_local_datasource.dart';

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  final DatabaseHelper _dbHelper;

  ExpenseLocalDataSourceImpl(this._dbHelper);

  @override
  Future<int> insertExpense(Map<String, dynamic> map) async {
    final db = await _dbHelper.database;
    return await db.insert('expenses', map);
  }

  @override
  Future<void> updateExpense(Map<String, dynamic> map, int id) async {
    final db = await _dbHelper.database;
    await db.update('expenses', map, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Map<String, dynamic>>> getExpensesByProperty(int propertyId, bool includeArchived) async {
    final db = await _dbHelper.database;
    if (includeArchived) {
      return await db.query('expenses', where: 'property_id = ?', whereArgs: [propertyId], orderBy: 'expense_date DESC');
    }
    return await db.query('expenses', where: 'property_id = ? AND deleted_at IS NULL', whereArgs: [propertyId], orderBy: 'expense_date DESC');
  }

  @override
  Future<Map<String, dynamic>?> getExpenseById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('expenses', where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }

  @override
  Future<List<Map<String, dynamic>>> getExpenseCategories() async {
    final db = await _dbHelper.database;
    return await db.query('expense_categories', orderBy: 'name ASC');
  }

  @override
  Future<Map<String, dynamic>?> getExpenseCategoryById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('expense_categories', where: 'id = ?', whereArgs: [id], limit: 1);
    return maps.isNotEmpty ? maps.first : null;
  }
}
