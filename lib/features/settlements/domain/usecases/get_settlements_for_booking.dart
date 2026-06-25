library;

import '../entities/settlement.dart';
import '../repositories/settlement_repository.dart';

class GetSettlementsForBooking {
  final SettlementRepository _repository;

  GetSettlementsForBooking(this._repository);

  Future<List<Settlement>> call(int bookingId) async {
    return await _repository.getSettlementsForBooking(bookingId);
  }
}
