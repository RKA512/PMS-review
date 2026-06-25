library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/providers/session_providers.dart';
import '../../../../core/common/enums/user_role.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الإعدادات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text('إدارة المستخدمين، كلمة المرور، اللغة والعملة', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 20),
            Row(
              children: [
                _TabButton(label: 'المستخدمين', index: 0, selected: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0)),
                const SizedBox(width: 8),
                _TabButton(label: 'كلمة المرور', index: 1, selected: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1)),
                const SizedBox(width: 8),
                _TabButton(label: 'اللغة والعملة', index: 2, selected: _tabIndex == 2, onTap: () => setState(() => _tabIndex = 2)),
                const SizedBox(width: 8),
                _TabButton(label: 'إعادة ضبط', index: 3, selected: _tabIndex == 3, onTap: () => setState(() => _tabIndex = 3)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 0: return _UsersTab();
      case 1: return _PasswordTab();
      case 2: return _LanguageCurrencyTab();
      case 3: return _ResetTab();
      default: return const SizedBox.shrink();
    }
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton({required this.label, required this.index, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1)),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : const Color(0xFF475569))),
      ),
    );
  }
}

// ============================================================
// TAB 1: Users Management
// ============================================================
class _UsersTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  int _version = 0;

  void _refresh() => setState(() => _version++);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('users-$_version'),
      future: DatabaseHelper.instance.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        final users = snapshot.data ?? [];
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showUserDialog(context, ref, null),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('إضافة مستخدم'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: users.isEmpty
                  ? const Center(child: Text('لا يوجد مستخدمون'))
                  : ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final u = users[i];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              child: Text(u['name']?.toString().substring(0, 1).toUpperCase() ?? '?', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                            ),
                            title: Text('${u['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${u['email']}  ·  ${u['role_name'] ?? '—'}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showUserDialog(context, ref, u)),
                                IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _deleteUser(context, ref, u['id'] as int, u['name'] as String)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showUserDialog(BuildContext context, WidgetRef ref, Map<String, dynamic>? existing) {
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] as String? ?? '');
    final passwordCtrl = TextEditingController();
    int roleIndex = existing != null ? ((existing['role_id'] as int?) ?? 2) - 1 : 2;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'إضافة مستخدم جديد' : 'تعديل المستخدم'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'الاسم', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder())),
                    if (existing == null) ...[
                      const SizedBox(height: 12),
                      TextField(controller: passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: roleIndex + 1,
                      items: UserRole.values.asMap().entries.map((e) {
                        return DropdownMenuItem(value: e.key + 1, child: Text(e.value.displayName));
                      }).toList(),
                      onChanged: (v) => setDialogState(() => roleIndex = (v ?? 2) - 1),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () async {
                    final now = DateTime.now().toIso8601String();
                    if (existing == null) {
                      await DatabaseHelper.instance.createUser({
                        'uuid': 'usr-${DateTime.now().millisecondsSinceEpoch}',
                        'account_id': 1,
                        'role_id': roleIndex + 1,
                        'name': nameCtrl.text,
                        'email': emailCtrl.text,
                        'password_hash': passwordCtrl.text.isEmpty ? 'default123' : passwordCtrl.text,
                        'status': 'Active',
                        'created_at': now,
                        'updated_at': now,
                      });
                    } else {
                      final updates = <String, dynamic>{
                        'name': nameCtrl.text,
                        'email': emailCtrl.text,
                        'role_id': roleIndex + 1,
                        'updated_at': now,
                      };
                      await DatabaseHelper.instance.updateUser(existing['id'] as int, updates);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(existing == null ? 'تمت إضافة المستخدم' : 'تم تحديث المستخدم')));
                    _refresh();
                    },
                  child: Text(existing == null ? 'إضافة' : 'حفظ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteUser(BuildContext context, WidgetRef ref, int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المستخدم "$name"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteUser(id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المستخدم')));
              (context as Element).markNeedsBuild();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 2: Change Password
// ============================================================
class _PasswordTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PasswordTab> createState() => _PasswordTabState();
}

class _PasswordTabState extends ConsumerState<_PasswordTab> {
  final _currentPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentPw.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authenticatedUserIdProvider) ?? 1;
    return Center(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_outline, color: Color(0xFF3B82F6)),
                    SizedBox(width: 8),
                    Text('تغيير كلمة المرور', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(controller: _currentPw, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الحالية', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _newPw, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _confirmPw, obscureText: true, decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور الجديدة', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () async {
                      if (_newPw.text != _confirmPw.text) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمتا المرور غير متطابقتين'), backgroundColor: Colors.red));
                        return;
                      }
                      if (_newPw.text.length < 4) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور يجب أن تكون 4 أحرف على الأقل'), backgroundColor: Colors.red));
                        return;
                      }
                      setState(() => _loading = true);
                      final valid = await DatabaseHelper.instance.verifyPassword(userId, _currentPw.text);
                      if (!valid) {
                        setState(() => _loading = false);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور الحالية غير صحيحة'), backgroundColor: Colors.red));
                        return;
                      }
                      await DatabaseHelper.instance.updatePassword(userId, _newPw.text);
                      setState(() => _loading = false);
                      _currentPw.clear();
                      _newPw.clear();
                      _confirmPw.clear();
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح'), backgroundColor: Colors.green));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('تغيير كلمة المرور'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TAB 3: Language & Currency
// ============================================================
class _LanguageCurrencyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.database.then((db) => db.query('currencies')),
      builder: (context, snapshot) {
        final currencies = snapshot.data ?? [];
        return SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.language, color: Color(0xFF3B82F6)),
                          SizedBox(width: 8),
                          Text('اللغة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('النظام يدعم العربية والإنجليزية والفرنسية. سيتم إضافة تبديل اللغة في تحديث لاحق.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.attach_money, color: Color(0xFFF59E0B)),
                          SizedBox(width: 8),
                          Text('العملات المدعومة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...currencies.map((c) => ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: (c['is_default'] == 1 || c['is_default'] == true) ? const Color(0xFFF59E0B).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                          child: Text(c['symbol'] as String? ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: (c['is_default'] == 1 || c['is_default'] == true) ? const Color(0xFFF59E0B) : Colors.grey)),
                        ),
                        title: Text('${c['name']} (${c['code']})'),
                        trailing: (c['is_default'] == 1 || c['is_default'] == true)
                            ? const Chip(label: Text('الافتراضية', style: TextStyle(fontSize: 11)), backgroundColor: Color(0xFFF59E0B), labelStyle: TextStyle(color: Colors.white, fontSize: 11))
                            : null,
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// TAB 4: Factory Reset
// ============================================================
class _ResetTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(radius: 32, backgroundColor: Color(0xFFEF4444), child: Icon(Icons.warning_amber_rounded, size: 32, color: Color(0xFFEF4444))),
                const SizedBox(height: 16),
                const Text('إعادة ضبط النظام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                const SizedBox(height: 8),
                const Text('سيؤدي هذا الإجراء إلى حذف جميع البيانات وإعادة تهيئة النظام بالبيانات الافتراضية.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                const Text('لا يمكن التراجع عن هذا الإجراء!', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('تأكيد إعادة الضبط'),
                          content: const Text('هل أنت متأكد؟ سيتم حذف جميع البيانات المخزنة!'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                            ElevatedButton(
                              onPressed: () async {
                                await DatabaseHelper.instance.factoryReset();
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إعادة ضبط النظام بنجاح'), backgroundColor: Colors.green));
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              child: const Text('تأكيد إعادة الضبط'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة ضبط النظام بالكامل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
