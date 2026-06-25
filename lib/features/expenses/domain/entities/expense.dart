library;

import '../../../../core/common/models/money.dart';

class Expense {
  final int? id;
  final String uuid;
  final int propertyId;
  final int expenseCategoryId;
  final Money amount;
  final String? description;
  final DateTime expenseDate;
  final int createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Expense({
    this.id,
    required this.uuid,
    required this.propertyId,
    required this.expenseCategoryId,
    required this.amount,
    this.description,
    required this.expenseDate,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Expense copyWith({
    int? id,
    String? uuid,
    int? propertyId,
    int? expenseCategoryId,
    Money? amount,
    String? description,
    DateTime? expenseDate,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      propertyId: propertyId ?? this.propertyId,
      expenseCategoryId: expenseCategoryId ?? this.expenseCategoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      expenseDate: expenseDate ?? this.expenseDate,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
