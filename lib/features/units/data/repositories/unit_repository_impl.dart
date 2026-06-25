/// Why this file exists:
/// Implementation of UnitRepository contract.
/// Delegates SQL to UnitLocalDataSource; focuses on domain mapping.
/// Follows [Architecture Rule AR-302] and logs Unit audit updates.
library;

import '../../domain/entities/unit.dart';
import '../../domain/entities/unit_type.dart';
import '../../domain/repositories/unit_repository.dart';
import '../datasources/unit_local_datasource.dart';
import '../models/unit_model.dart';

class UnitRepositoryImpl implements UnitRepository {
  final UnitLocalDataSource _dataSource;

  UnitRepositoryImpl(this._dataSource);

  @override
  Future<List<Unit>> getUnits({required int propertyId, bool includeArchived = false}) async {
    final maps = await _dataSource.getUnits(propertyId, includeArchived);
    return maps.map((map) => UnitModel.fromMap(map)).toList();
  }

  @override
  Future<Unit?> getUnitById(int id) async {
    final map = await _dataSource.getUnitById(id);
    if (map == null) return null;
    return UnitModel.fromMap(map);
  }

  @override
  Future<Unit?> getUnitByUuid(String uuid) async {
    final map = await _dataSource.getUnitByUuid(uuid);
    if (map == null) return null;
    return UnitModel.fromMap(map);
  }

  @override
  Future<int> createUnit(Unit unit) async {
    final id = await _dataSource.createUnit(UnitModel.toMap(unit));
    return id;
  }

  @override
  Future<void> updateUnit(Unit unit) async {
    if (unit.id == null) return;
    await _dataSource.updateUnit(UnitModel.toMap(unit), unit.id!);
  }

  @override
  Future<void> archiveUnit(int id) async {
    final nowString = DateTime.now().toIso8601String();
    await _dataSource.archiveUnit(id, nowString);
  }

  @override
  Future<void> unarchiveUnit(int id) async {
    final nowString = DateTime.now().toIso8601String();
    await _dataSource.unarchiveUnit(id, nowString);
  }

  @override
  Future<void> updateUnitStatus({required int unitId, required String status}) async {
    await _dataSource.updateUnitStatus(unitId, status);
  }

  @override
  Future<List<UnitType>> getUnitTypes() async {
    final maps = await _dataSource.getUnitTypes();
    return maps.map((map) {
      return UnitType(
        id: map['id'] as int,
        name: map['name'] as String,
        description: map['description'] as String?,
      );
    }).toList();
  }
}
