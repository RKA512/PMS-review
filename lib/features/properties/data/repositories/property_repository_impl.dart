/// Why this file exists:
/// Implementation of PropertyRepository contract.
/// Delegates SQL to PropertyLocalDataSource; focuses on domain mapping.
/// Triggers AP-1000 Property Audit Rules on changes.
library;

import '../../../../core/common/enums/property_status.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_type.dart';
import '../../domain/entities/property_settings.dart';
import '../../domain/repositories/property_repository.dart';
import '../datasources/property_local_datasource.dart';
import '../models/property_model.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyLocalDataSource _dataSource;

  PropertyRepositoryImpl(this._dataSource);

  @override
  Future<List<Property>> getProperties({bool includeArchived = false}) async {
    final maps = await _dataSource.getProperties(includeArchived);
    return maps.map((map) => PropertyModel.fromMap(map)).toList();
  }

  @override
  Future<Property?> getPropertyById(int id) async {
    final map = await _dataSource.getPropertyById(id);
    if (map == null) return null;
    return PropertyModel.fromMap(map);
  }

  @override
  Future<Property?> getPropertyByUuid(String uuid) async {
    final map = await _dataSource.getPropertyByUuid(uuid);
    if (map == null) return null;
    return PropertyModel.fromMap(map);
  }

  @override
  Future<int> createProperty(Property property) async {
    final id = await _dataSource.createProperty(PropertyModel.toMap(property));
    return id;
  }

  @override
  Future<void> updateProperty(Property property) async {
    if (property.id == null) return;
    await _dataSource.updateProperty(PropertyModel.toMap(property), property.id!);
  }

  @override
  Future<void> archiveProperty(int id) async {
    final nowString = DateTime.now().toIso8601String();
    await _dataSource.archiveProperty(id, {
      'deleted_at': nowString,
      'status': PropertyStatus.archived.toJson(),
      'updated_at': nowString,
    });
  }

  @override
  Future<void> unarchiveProperty(int id) async {
    final nowString = DateTime.now().toIso8601String();
    await _dataSource.unarchiveProperty(id, {
      'deleted_at': null,
      'status': PropertyStatus.active.toJson(),
      'updated_at': nowString,
    });
  }

  @override
  Future<List<PropertyType>> getPropertyTypes() async {
    final maps = await _dataSource.getPropertyTypes();
    return maps.map((map) {
      return PropertyType(
        id: map['id'] as int,
        name: map['name'] as String,
        description: map['description'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<PropertySettings>> getPropertySettings(int propertyId) async {
    final maps = await _dataSource.getPropertySettings(propertyId);
    return maps.map((map) {
      return PropertySettings(
        id: map['id'] as int?,
        propertyId: map['property_id'] as int,
        settingKey: map['setting_key'] as String,
        settingValue: map['setting_value'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
    }).toList();
  }

  @override
  Future<void> savePropertySetting(int propertyId, String key, String value) async {
    final nowString = DateTime.now().toIso8601String();
    final existing = await _dataSource.getPropertySettingByKey(propertyId, key);
    if (existing.isEmpty) {
      await _dataSource.insertPropertySetting({
        'property_id': propertyId,
        'setting_key': key,
        'setting_value': value,
        'created_at': nowString,
        'updated_at': nowString,
      });
    } else {
      await _dataSource.updatePropertySetting(value, nowString, propertyId, key);
    }
  }

  @override
  Future<String?> getPropertySettingValue(int propertyId, String key) async {
    final result = await _dataSource.getPropertySettingByKey(propertyId, key);
    if (result.isEmpty) return null;
    return result.first['setting_value'] as String?;
  }
}
