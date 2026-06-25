library;

import '../../../../core/common/enums/settlement_status.dart';
import '../../../../core/common/enums/settlement_type.dart';
import '../../../../core/common/models/money.dart';

class Settlement {
  final int? id;
  final String uuid;
  final int propertyId;
  final int bookingId;
  final SettlementType settlementType;
  final SettlementStatus status;
  final Money differenceAmount;
  final String? reason;
  final int createdBy;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Settlement({
    this.id,
    required this.uuid,
    required this.propertyId,
    required this.bookingId,
    required this.settlementType,
    required this.status,
    required this.differenceAmount,
    this.reason,
    required this.createdBy,
    required this.createdAt,
    this.completedAt,
  });

  Settlement copyWith({
    int? id,
    String? uuid,
    int? propertyId,
    int? bookingId,
    SettlementType? settlementType,
    SettlementStatus? status,
    Money? differenceAmount,
    String? reason,
    int? createdBy,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Settlement(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      propertyId: propertyId ?? this.propertyId,
      bookingId: bookingId ?? this.bookingId,
      settlementType: settlementType ?? this.settlementType,
      status: status ?? this.status,
      differenceAmount: differenceAmount ?? this.differenceAmount,
      reason: reason ?? this.reason,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
