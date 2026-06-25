library;

import '../../../../core/common/models/money.dart';
import '../../domain/entities/settlement_correction.dart';

class SettlementCorrectionModel {
  static Map<String, dynamic> toMap(SettlementCorrection correction) {
    return {
      if (correction.id != null) 'id': correction.id,
      'uuid': correction.uuid,
      'settlement_id': correction.settlementId,
      'correction_amount': correction.correctionAmount.minorUnits,
      'reason': correction.reason,
      'created_by': correction.createdBy,
      'created_at': correction.createdAt.toIso8601String(),
    };
  }

  static SettlementCorrection fromMap(Map<String, dynamic> map) {
    return SettlementCorrection(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      settlementId: map['settlement_id'] as int,
      correctionAmount: Money(map['correction_amount'] as int),
      reason: map['reason'] as String,
      createdBy: map['created_by'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
