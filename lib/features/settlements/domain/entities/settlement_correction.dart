library;

import '../../../../core/common/models/money.dart';

class SettlementCorrection {
  final int? id;
  final String uuid;
  final int settlementId;
  final Money correctionAmount;
  final String reason;
  final int createdBy;
  final DateTime createdAt;

  const SettlementCorrection({
    this.id,
    required this.uuid,
    required this.settlementId,
    required this.correctionAmount,
    required this.reason,
    required this.createdBy,
    required this.createdAt,
  });
}
