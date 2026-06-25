library;

abstract class UnitLocalDataSource {
  Future<List<Map<String, dynamic>>> getUnits(int propertyId, bool includeArchived);
  Future<Map<String, dynamic>?> getUnitById(int id);
  Future<Map<String, dynamic>?> getUnitByUuid(String uuid);
  Future<int> createUnit(Map<String, dynamic> map);
  Future<void> updateUnit(Map<String, dynamic> map, int id);
  Future<void> archiveUnit(int id, String now);
  Future<void> unarchiveUnit(int id, String now);
  Future<void> updateUnitStatus(int unitId, String status);
  Future<List<Map<String, dynamic>>> getUnitTypes();
}
