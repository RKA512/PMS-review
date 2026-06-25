library;

import '../../../../core/errors/failure.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource _dataSource;

  ExpenseRepositoryImpl(this._dataSource);

  @override
  Future<int> createExpense(Expense expense) async {
    try {
      final map = ExpenseModel.toMap(expense);
      return await _dataSource.insertExpense(map);
    } catch (e) {
      throw const DatabaseFailure(
        code: 'CREATE_EXPENSE_FAILED',
        message: 'فشل إنشاء المصروف في قاعدة البيانات.',
      );
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) {
      throw const DatabaseFailure(
        code: 'UPDATE_EXPENSE_MISSING_ID',
        message: 'معرّف المصروف مفقود.',
      );
    }
    try {
      final map = ExpenseModel.toMap(expense);
      await _dataSource.updateExpense(map, expense.id!);
    } catch (e) {
      throw const DatabaseFailure(
        code: 'UPDATE_EXPENSE_FAILED',
        message: 'فشل تحديث المصروف.',
      );
    }
  }

  @override
  Future<List<Expense>> getExpensesForProperty(int propertyId, {bool includeArchived = false}) async {
    try {
      final maps = await _dataSource.getExpensesByProperty(propertyId, includeArchived);
      return maps.map((m) => ExpenseModel.fromMap(m)).toList();
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_EXPENSES_FAILED',
        message: 'حدث خطأ أثناء جلب المصروفات.',
      );
    }
  }

  @override
  Future<List<ExpenseCategory>> getExpenseCategories() async {
    try {
      final maps = await _dataSource.getExpenseCategories();
      return maps.map((map) {
        return ExpenseCategory(
          id: map['id'] as int?,
          uuid: map['uuid'] as String,
          name: map['name'] as String,
          description: map['description'] as String?,
          createdAt: DateTime.parse(map['created_at'] as String),
          updatedAt: DateTime.parse(map['updated_at'] as String),
        );
      }).toList();
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_EXPENSE_CATEGORIES_FAILED',
        message: 'حدث خطأ أثناء جلب فئات المصروفات.',
      );
    }
  }

  @override
  Future<void> deleteExpense(int expenseId, int userId) async {
    try {
      final existing = await _dataSource.getExpenseById(expenseId);
      if (existing == null) {
        throw const ValidationFailure(
          code: 'EXPENSE_NOT_FOUND',
          message: 'المصروف غير موجود.',
        );
      }
      final now = DateTime.now().toIso8601String();
      await _dataSource.updateExpense({'deleted_at': now, 'updated_at': now}, expenseId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'DELETE_EXPENSE_FAILED',
        message: 'فشل حذف المصروف.',
      );
    }
  }
}
