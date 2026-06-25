library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/enums/user_role.dart';
import '../database/database_helper.dart';
import 'session_providers.dart';

final currentUserRoleProvider = FutureProvider<UserRole>((ref) async {
  final userId = ref.watch(authenticatedUserIdProvider);
  if (userId == null) return UserRole.receptionist;

  final db = await DatabaseHelper.instance.database;
  final maps = await db.query('users', columns: ['role_id'], where: 'id = ?', whereArgs: [userId], limit: 1);
  if (maps.isEmpty) return UserRole.receptionist;

  final roleId = maps.first['role_id'] as int;
  return UserRole.values[(roleId - 1).clamp(0, UserRole.values.length - 1)];
});
