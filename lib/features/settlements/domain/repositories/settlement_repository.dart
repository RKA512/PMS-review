library;

import '../entities/settlement.dart';
import '../entities/settlement_correction.dart';

abstract class SettlementRepository {
  Future<int> createSettlement(Settlement settlement);
  Future<List<Settlement>> getSettlementsForBooking(int bookingId);
  Future<void> completeSettlement(int settlementId, int userId);
  Future<void> cancelSettlement(int settlementId, int userId);
  Future<int> addCorrection(SettlementCorrection correction);
  Future<List<SettlementCorrection>> getCorrections(int settlementId);
}
