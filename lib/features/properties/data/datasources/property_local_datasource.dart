library;

abstract class PropertyLocalDataSource {
  Future<List<Map<String, dynamic>>> getProperties(bool includeArchived);
  Future<Map<String, dynamic>?> getPropertyById(int id);
  Future<Map<String, dynamic>?> getPropertyByUuid(String uuid);
  Future<int> createProperty(Map<String, dynamic> map);
  Future<void> updateProperty(Map<String, dynamic> map, int id);
  Future<void> archiveProperty(int id, Map<String, dynamic> values);
  Future<void> unarchiveProperty(int id, Map<String, dynamic> values);
  Future<List<Map<String, dynamic>>> getPropertyTypes();
  Future<List<Map<String, dynamic>>> getPropertySettings(int propertyId);
  Future<List<Map<String, dynamic>>> getPropertySettingByKey(int propertyId, String key);
  Future<void> insertPropertySetting(Map<String, dynamic> map);
  Future<void> updatePropertySetting(String value, String now, int propertyId, String key);
}
