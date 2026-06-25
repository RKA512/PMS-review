library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/audit_service.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../../data/repositories/settlement_repository_impl.dart';
import '../../data/datasources/settlement_local_datasource_impl.dart';
import '../../domain/usecases/cancel_settlement.dart';
import '../../domain/usecases/complete_settlement.dart';
import '../../domain/usecases/create_settlement.dart';
import '../../domain/usecases/get_settlements_for_booking.dart';

final settlementLocalDataSourceProvider = Provider((ref) {
  return SettlementLocalDataSourceImpl(DatabaseHelper.instance);
});

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  return SettlementRepositoryImpl(ref.watch(settlementLocalDataSourceProvider));
});

final createSettlementUseCaseProvider = Provider<CreateSettlement>((ref) {
  return CreateSettlement(ref.watch(settlementRepositoryProvider), ref.watch(auditServiceProvider));
});

final completeSettlementUseCaseProvider = Provider<CompleteSettlement>((ref) {
  return CompleteSettlement(ref.watch(settlementRepositoryProvider), ref.watch(auditServiceProvider));
});

final cancelSettlementUseCaseProvider = Provider<CancelSettlement>((ref) {
  return CancelSettlement(ref.watch(settlementRepositoryProvider), ref.watch(auditServiceProvider));
});

final getSettlementsForBookingUseCaseProvider = Provider<GetSettlementsForBooking>((ref) {
  return GetSettlementsForBooking(ref.watch(settlementRepositoryProvider));
});
