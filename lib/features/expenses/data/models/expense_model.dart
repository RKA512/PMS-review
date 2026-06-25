library;

import '../../../../core/common/models/money.dart';
import '../../domain/entities/expense.dart';

class ExpenseModel {
  static Map<String, dynamic> toMap(Expense expense) {
    return {
      if (expense.id != null) 'id': expense.id,
      'uuid': expense.uuid,
      'property_id': expense.propertyId,
      'expense_category_id': expense.expenseCategoryId,
      'amount': expense.amount.minorUnits,
      'description': expense.description,
      'expense_date': expense.expenseDate.toIso8601String(),
      'created_by': expense.createdBy,
      'created_at': expense.createdAt.toIso8601String(),
      'updated_at': expense.updatedAt.toIso8601String(),
      'deleted_at': expense.deletedAt?.toIso8601String(),
    };
  }

  static Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      propertyId: map['property_id'] as int,
      expenseCategoryId: map['expense_category_id'] as int,
      amount: Money(map['amount'] as int),
      description: map['description'] as String?,
      expenseDate: DateTime.parse(map['expense_date'] as String),
      createdBy: map['created_by'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
    );
  }
}
