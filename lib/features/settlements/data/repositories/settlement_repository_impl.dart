library;

import '../../../../core/errors/failure.dart';
import '../../../../core/common/enums/settlement_status.dart';
import '../../domain/entities/settlement.dart';
import '../../domain/entities/settlement_correction.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../datasources/settlement_local_datasource.dart';
import '../models/settlement_model.dart';
import '../models/settlement_correction_model.dart';

class SettlementRepositoryImpl implements SettlementRepository {
  final SettlementLocalDataSource _dataSource;

  SettlementRepositoryImpl(this._dataSource);

  @override
  Future<int> createSettlement(Settlement settlement) async {
    try {
      final map = SettlementModel.toMap(settlement);
      return await _dataSource.insertSettlement(map);
    } catch (e) {
      throw const DatabaseFailure(
        code: 'CREATE_SETTLEMENT_FAILED',
        message: 'فشل إنشاء التسوية في قاعدة البيانات.',
      );
    }
  }

  @override
  Future<List<Settlement>> getSettlementsForBooking(int bookingId) async {
    try {
      final maps = await _dataSource.getSettlementsByBooking(bookingId);
      return maps.map((m) => SettlementModel.fromMap(m)).toList();
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_SETTLEMENTS_FAILED',
        message: 'حدث خطأ أثناء جلب التسويات.',
      );
    }
  }

  @override
  Future<void> completeSettlement(int settlementId, int userId) async {
    try {
      final existing = await _dataSource.getSettlementById(settlementId);
      if (existing == null) {
        throw const ValidationFailure(
          code: 'SETTLEMENT_NOT_FOUND',
          message: 'التسوية غير موجودة.',
        );
      }
      final now = DateTime.now().toIso8601String();
      await _dataSource.updateSettlement(settlementId, {
        'status': SettlementStatus.completed.name,
        'completed_at': now,
      });
    } on Failure {
      rethrow;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'COMPLETE_SETTLEMENT_FAILED',
        message: 'فشل إكمال التسوية.',
      );
    }
  }

  @override
  Future<void> cancelSettlement(int settlementId, int userId) async {
    try {
      final existing = await _dataSource.getSettlementById(settlementId);
      if (existing == null) {
        throw const ValidationFailure(
          code: 'SETTLEMENT_NOT_FOUND',
          message: 'التسوية غير موجودة.',
        );
      }
      await _dataSource.updateSettlement(settlementId, {
        'status': SettlementStatus.cancelled.name,
      });
    } on Failure {
      rethrow;
    } catch (e) {
      throw const DatabaseFailure(
        code: 'CANCEL_SETTLEMENT_FAILED',
        message: 'فشل إلغاء التسوية.',
      );
    }
  }

  @override
  Future<int> addCorrection(SettlementCorrection correction) async {
    try {
      final map = SettlementCorrectionModel.toMap(correction);
      return await _dataSource.insertCorrection(map);
    } catch (e) {
      throw const DatabaseFailure(
        code: 'ADD_CORRECTION_FAILED',
        message: 'فشل إضافة تصحيح للتسوية.',
      );
    }
  }

  @override
  Future<List<SettlementCorrection>> getCorrections(int settlementId) async {
    try {
      final maps = await _dataSource.getCorrectionsBySettlement(settlementId);
      return maps.map((m) => SettlementCorrectionModel.fromMap(m)).toList();
    } catch (e) {
      throw const DatabaseFailure(
        code: 'GET_CORRECTIONS_FAILED',
        message: 'حدث خطأ أثناء جلب تصحيحات التسوية.',
      );
    }
  }
}
