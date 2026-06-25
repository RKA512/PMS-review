library;

import '../../../../core/common/enums/settlement_status.dart';
import '../../../../core/common/enums/settlement_type.dart';
import '../../../../core/common/models/money.dart';
import '../../domain/entities/settlement.dart';

class SettlementModel {
  static Map<String, dynamic> toMap(Settlement settlement) {
    return {
      if (settlement.id != null) 'id': settlement.id,
      'uuid': settlement.uuid,
      'property_id': settlement.propertyId,
      'booking_id': settlement.bookingId,
      'settlement_type': settlement.settlementType.toJson(),
      'status': settlement.status.toJson(),
      'difference_amount': settlement.differenceAmount.minorUnits,
      'reason': settlement.reason,
      'created_by': settlement.createdBy,
      'created_at': settlement.createdAt.toIso8601String(),
      'completed_at': settlement.completedAt?.toIso8601String(),
    };
  }

  static Settlement fromMap(Map<String, dynamic> map) {
    return Settlement(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      propertyId: map['property_id'] as int,
      bookingId: map['booking_id'] as int,
      settlementType: SettlementType.fromJson(map['settlement_type'] as String),
      status: SettlementStatus.fromJson(map['status'] as String),
      differenceAmount: Money(map['difference_amount'] as int),
      reason: map['reason'] as String?,
      createdBy: map['created_by'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
    );
  }
}
