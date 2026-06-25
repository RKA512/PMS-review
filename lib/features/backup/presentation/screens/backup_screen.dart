library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/services/restore_service.dart';
import '../../../../core/providers/session_providers.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authenticatedUserIdProvider) ?? 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('النسخ الاحتياطي واستعادة البيانات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text('إنشاء واستعادة النسخ الاحتياطي لقاعدة البيانات', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 24, backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1), child: const Icon(Icons.backup, color: Color(0xFF3B82F6), size: 28)),
                        const SizedBox(width: 16),
                        const Expanded(child: Text('إنشاء نسخة احتياطية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('سيتم إنشاء نسخة من قاعدة البيانات الحالية وحفظها في مجلد التطبيق.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final dir = await getApplicationDocumentsDirectory();
                            final file = await BackupService.instance.createBackup(dir.path, userId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('تم إنشاء النسخة الاحتياطية: ${file.path.split('\\').last}'),
                                backgroundColor: Colors.green,
                              ));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                            }
                          }
                        },
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('إنشاء نسخة احتياطية جديدة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
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
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 24, backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.1), child: const Icon(Icons.restore, color: Color(0xFFF59E0B), size: 28)),
                        const SizedBox(width: 16),
                        const Expanded(child: Text('استعادة نسخة احتياطية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('اختر ملف قاعدة البيانات (.db) لاستعادة البيانات. سيتم استبدال البيانات الحالية.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final result = await FilePicker.platform.pickFiles(type: FileType.any);
                            if (result == null || result.files.single.path == null) return;
                            final success = await RestoreService.instance.restoreDatabase(result.files.single.path!, userId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(success ? 'تمت استعادة البيانات بنجاح' : 'فشلت عملية الاستعادة'),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                            }
                          }
                        },
                        icon: const Icon(Icons.folder_open),
                        label: const Text('اختيار ملف واستعادة'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                        ),
                      ),
                    ),
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
                    Row(
                      children: [
                        CircleAvatar(radius: 24, backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1), child: const Icon(Icons.share, color: Color(0xFF10B981), size: 28)),
                        const SizedBox(width: 16),
                        const Expanded(child: Text('مشاركة النسخة الاحتياطية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('مشاركة أحدث نسخة احتياطية مع جهة خارجية.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final dir = await getApplicationDocumentsDirectory();
                            final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.db')).toList();
                            if (files.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد نسخ احتياطية للمشاركة'), backgroundColor: Colors.orange));
                              }
                              return;
                            }
                            files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
                            await Share.shareXFiles([XFile(files.first.path)], text: 'PMS Backup - ${DateTime.now()}');
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
                            }
                          }
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('مشاركة آخر نسخة'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: const BorderSide(color: Color(0xFF10B981)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
