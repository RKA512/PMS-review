library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/common/models/money.dart';
import '../../../properties/presentation/providers/property_providers.dart';

final _financialSummaryProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, propertyId) async {
  return DatabaseHelper.instance.getFinancialSummary(propertyId);
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProperty = ref.watch(selectedPropertyProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('التقارير المتقدمة', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text('تحليلات مالية وتشغيلية شاملة', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 24),
            if (activeProperty == null)
              const Expanded(child: Center(child: Text('الرجاء تحديد منشأة من القائمة الجانبية')))
            else
              Expanded(child: _ReportsContent(propertyId: activeProperty.id!)),
          ],
        ),
      ),
    );
  }
}

class _ReportsContent extends ConsumerWidget {
  final int propertyId;
  const _ReportsContent({required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(_financialSummaryProvider(propertyId));
    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e', style: const TextStyle(color: Colors.red))),
      data: (data) {
        final revenue = data['revenue'] as int;
        final expenses = data['expenses'] as int;
        final refunds = data['refunds'] as int;
        final netProfit = revenue - expenses - refunds;
        final bookingCount = data['bookingCount'] as int;
        final occupiedUnits = data['occupiedUnits'] as int;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryCard(title: 'إجمالي الإيرادات', value: Money(revenue).format('ر.س'), color: const Color(0xFF10B981), icon: Icons.trending_up),
              const SizedBox(height: 12),
              _SummaryCard(title: 'إجمالي المصروفات', value: Money(expenses).format('ر.س'), color: const Color(0xFFEF4444), icon: Icons.shopping_cart),
              const SizedBox(height: 12),
              _SummaryCard(title: 'المردودات', value: Money(refunds).format('ر.س'), color: const Color(0xFFF59E0B), icon: Icons.replay),
              const SizedBox(height: 12),
              _SummaryCard(title: 'صافي الربح', value: Money(netProfit).format('ر.س'), color: netProfit >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444), icon: Icons.account_balance),
              const SizedBox(height: 12),
              _SummaryCard(title: 'إجمالي الحجوزات', value: bookingCount.toString(), color: const Color(0xFF3B82F6), icon: Icons.book_online),
              const SizedBox(height: 12),
              _SummaryCard(title: 'الوحدات المشغولة حالياً', value: occupiedUnits.toString(), color: const Color(0xFF8B5CF6), icon: Icons.meeting_room),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ملخص الأداء', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _StatRow(label: 'الإيرادات', value: Money(revenue).format('ر.س'), color: Colors.green),
                      _StatRow(label: 'المصروفات', value: Money(expenses).format('ر.س'), color: Colors.red),
                      _StatRow(label: 'المردودات', value: Money(refunds).format('ر.س'), color: Colors.orange),
                      const Divider(height: 24),
                      _StatRow(label: 'صافي الربح', value: Money(netProfit).format('ر.س'), color: netProfit >= 0 ? Colors.green : Colors.red),
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryCard({required this.title, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
