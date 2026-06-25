import 'package:flutter_test/flutter_test.dart';
import 'package:property_management_system/core/common/enums/settlement_status.dart';
import 'package:property_management_system/core/common/enums/settlement_type.dart';
import 'package:property_management_system/core/common/models/money.dart';
import 'package:property_management_system/features/settlements/domain/entities/settlement.dart';
import 'package:property_management_system/features/settlements/domain/entities/settlement_correction.dart';
import 'package:property_management_system/features/settlements/domain/repositories/settlement_repository.dart';
import 'package:property_management_system/features/settlements/domain/usecases/get_settlements_for_booking.dart';

class FakeSettlementRepository implements SettlementRepository {
  final List<Settlement> _settlements = [];

  void addSettlement(Settlement settlement) => _settlements.add(settlement);

  @override
  Future<int> createSettlement(Settlement settlement) async => 1;

  @override
  Future<List<Settlement>> getSettlementsForBooking(int bookingId) async {
    return _settlements.where((s) => s.bookingId == bookingId).toList();
  }

  @override
  Future<void> completeSettlement(int settlementId, int userId) async {}

  @override
  Future<void> cancelSettlement(int settlementId, int userId) async {}

  @override
  Future<int> addCorrection(SettlementCorrection correction) async => 1;

  @override
  Future<List<SettlementCorrection>> getCorrections(int settlementId) async => [];
}

void main() {
  late FakeSettlementRepository repository;
  late GetSettlementsForBooking useCase;

  setUp(() {
    repository = FakeSettlementRepository();
    useCase = GetSettlementsForBooking(repository);
  });

  test('should return empty list when no settlements exist for booking', () async {
    final result = await useCase(1);
    expect(result, isEmpty);
  });

  test('should return settlements for the given booking', () async {
    repository.addSettlement(Settlement(
      id: 1, uuid: '', propertyId: 1, bookingId: 10,
      settlementType: SettlementType.overpayment,
      status: SettlementStatus.pending,
      differenceAmount: const Money(200), reason: 'دفع زائد',
      createdBy: 1, createdAt: DateTime.now(),
    ));
    repository.addSettlement(Settlement(
      id: 2, uuid: '', propertyId: 1, bookingId: 10,
      settlementType: SettlementType.underpayment,
      status: SettlementStatus.completed,
      differenceAmount: const Money(150), reason: 'دفع ناقص',
      createdBy: 1, createdAt: DateTime.now(), completedAt: DateTime.now(),
    ));

    final result = await useCase(10);
    expect(result.length, 2);
    expect(result[0].settlementType, SettlementType.overpayment);
    expect(result[1].settlementType, SettlementType.underpayment);
  });

  test('should not return settlements for other bookings', () async {
    repository.addSettlement(Settlement(
      id: 1, uuid: '', propertyId: 1, bookingId: 20,
      settlementType: SettlementType.overpayment,
      status: SettlementStatus.pending,
      differenceAmount: const Money(200), reason: 'لحجز آخر',
      createdBy: 1, createdAt: DateTime.now(),
    ));

    final result = await useCase(10);
    expect(result, isEmpty);
  });
}
