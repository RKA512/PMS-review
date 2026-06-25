library;

enum PropertyStatus {
  active,
  archived,
  maintenance;

  String toJson() => name;

  static PropertyStatus fromJson(String value) {
    return PropertyStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PropertyStatus.active,
    );
  }

  String get displayName {
    switch (this) {
      case PropertyStatus.active:
        return 'نشط (Active)';
      case PropertyStatus.archived:
        return 'مؤرشف (Archived)';
      case PropertyStatus.maintenance:
        return 'صيانة (Maintenance)';
    }
  }
}
