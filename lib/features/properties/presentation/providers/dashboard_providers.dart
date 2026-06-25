library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import 'property_providers.dart';

final activeUnitsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final property = ref.watch(selectedPropertyProvider);
  if (property == null) return 0;
  return DatabaseHelper.instance.getActiveUnitsCount(property.id!);
});

final activeBookingsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final property = ref.watch(selectedPropertyProvider);
  if (property == null) return 0;
  return DatabaseHelper.instance.getActiveBookingsCount(property.id!);
});

final auditLogsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final property = ref.watch(selectedPropertyProvider);
  if (property == null) return 0;
  return DatabaseHelper.instance.getAuditLogsCount(property.id!);
});
