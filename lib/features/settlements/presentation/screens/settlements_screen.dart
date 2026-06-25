library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/enums/settlement_status.dart';
import '../../../../core/common/enums/settlement_type.dart';
import '../../../../core/common/models/money.dart';
import '../../../../core/providers/permission_providers.dart';
import '../../../../core/providers/session_providers.dart';
import '../../domain/entities/settlement.dart';
import '../providers/settlement_providers.dart';

class SettlementsScreen extends ConsumerStatefulWidget {
  const SettlementsScreen({super.key});

  @override
  ConsumerState<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends ConsumerState<SettlementsScreen> {
  final _bookingIdController = TextEditingController();
  bool _hasSearched = false;
  AsyncValue<List<Settlement>> _settlementsAsync = const AsyncValue.data([]);

  @override
  void dispose() {
    _bookingIdController.dispose();
    super.dispose();
  }

  Future<void> _searchSettlements() async {
    final bookingId = int.tryParse(_bookingIdController.text);
    if (bookingId == null) return;
    setState(() {
      _hasSearched = true;
      _settlementsAsync = const AsyncValue.loading();
    });
    try {
      final list = await ref.read(getSettlementsForBookingUseCaseProvider).call(bookingId);
      if (!mounted) return;
      setState(() => _settlementsAsync = AsyncValue.data(list));
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _settlementsAsync = AsyncValue.error(e, st));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAccount = ref.watch(activeAccountIdProvider);
    final authenticatedUserId = ref.watch(authenticatedUserIdProvider);

    if (activeAccount == null || authenticatedUserId == null) {
      return const Center(child: Text('الرجاء تسجيل الدخول أولاً'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('التسويات المالية', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('إدارة فروقات الدفع والتسويات', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _openCreateSettlementDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إنشاء تسوية'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bookingIdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'رقم الحجز',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _searchSettlements,
                      ),
                    ),
                    onSubmitted: (_) => _searchSettlements(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('أدخل رقم الحجز للبحث عن التسويات', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          ],
        ),
      );
    }

    return _settlementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text('حدث خطأ أثناء تحميل التسويات', style: TextStyle(color: Colors.red[600], fontSize: 15)),
            const SizedBox(height: 4),
            Text('$e', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('لا توجد تسويات لهذا الحجز', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _buildSettlementCard(list[i]),
        );
      },
    );
  }

  Widget _buildSettlementCard(Settlement s) {
    final statusColor = switch (s.status) {
      SettlementStatus.pending => Colors.orange,
      SettlementStatus.completed => Colors.green,
      SettlementStatus.cancelled => Colors.red,
    };
    final typeColor = switch (s.settlementType) {
      SettlementType.overpayment => Colors.blue,
      SettlementType.underpayment => Colors.orange,
    };
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.differenceAmount.format('SAR'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Chip(
                  label: Text(s.settlementType.displayName, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: typeColor,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(s.status.displayName, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: statusColor,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Text(_formatDate(s.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            if (s.reason != null && s.reason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(s.reason!, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            ],
            const SizedBox(height: 4),
            Text('رقم الحجز: ${s.bookingId}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _openCreateSettlementDialog(BuildContext context) {
    final userId = ref.read(authenticatedUserIdProvider)!;
    showDialog(
      context: context,
      builder: (ctx) {
        final bookingIdCtrl = TextEditingController();
        final amountCtrl = TextEditingController();
        final reasonCtrl = TextEditingController();
        SettlementType selectedType = SettlementType.overpayment;

        return AlertDialog(
          title: const Text('إنشاء تسوية جديدة', textDirection: TextDirection.rtl),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bookingIdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رقم الحجز', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ (بأقل وحدة نقدية)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SettlementType>(
                  initialValue: selectedType,
                  items: SettlementType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                  onChanged: (v) => selectedType = v ?? SettlementType.overpayment,
                  decoration: const InputDecoration(labelText: 'نوع التسوية', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'السبب', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final bookingId = int.tryParse(bookingIdCtrl.text);
                final amount = int.tryParse(amountCtrl.text);
                if (bookingId == null || amount == null) return;
                final userRole = await ref.read(currentUserRoleProvider.future);
                try {
                  await ref.read(createSettlementUseCaseProvider).call(
                    Settlement(
                      uuid: '',
                      propertyId: 1,
                      bookingId: bookingId,
                      settlementType: selectedType,
                      status: SettlementStatus.pending,
                      differenceAmount: Money(amount),
                      reason: reasonCtrl.text.isNotEmpty ? reasonCtrl.text : null,
                      createdBy: userId,
                      createdAt: DateTime.now(),
                    ),
                    userId,
                    role: userRole,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء التسوية')));
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }
}
