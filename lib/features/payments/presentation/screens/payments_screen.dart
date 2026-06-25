library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/common/enums/payment_method.dart';
import '../../../../core/common/enums/payment_type.dart';
import '../../../../core/common/models/money.dart';
import '../../../../core/providers/permission_providers.dart';
import '../../../../core/providers/session_providers.dart';
import '../../domain/entities/payment.dart';
import '../providers/payment_providers.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  final _invoiceIdCtrl = TextEditingController();
  List<Payment>? _payments;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _invoiceIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPayments(int invoiceId) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _payments = null;
    });
    try {
      final payments = await ref.read(getPaymentsForInvoiceUseCaseProvider).call(invoiceId);
      if (mounted) setState(() { _payments = payments; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red[600])),
            const SizedBox(height: 8),
            TextButton(onPressed: () => _loadPayments(int.parse(_invoiceIdCtrl.text)), child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    if (_payments == null) {
      return Center(child: Text('أدخل رقم الفاتورة ثم اضغط "عرض"', style: TextStyle(color: Colors.grey[500])));
    }
    if (_payments!.isEmpty) {
      return Center(child: Text('لا توجد مدفوعات لهذه الفاتورة', style: TextStyle(color: Colors.grey[500])));
    }
    return ListView.separated(
      itemCount: _payments!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = _payments![index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${p.amount.toString()} ر.س', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.paymentType == PaymentType.incoming ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(p.paymentType.displayName, style: TextStyle(fontSize: 12, color: p.paymentType == PaymentType.incoming ? Colors.green[700] : Colors.red[700])),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _infoRow('طريقة الدفع', p.paymentMethod.displayName),
                if (p.referenceNumber != null) _infoRow('رقم المرجع', p.referenceNumber!),
                _infoRow('التاريخ', DateFormat('yyyy/MM/dd HH:mm').format(p.createdAt)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
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
                    const Text('المدفوعات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('تسجيل وإدارة الدفعات الواردة والمرتجعة', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _openRecordPaymentDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('تسجيل دفعة جديدة'),
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
                    controller: _invoiceIdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'رقم الفاتورة',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final id = int.tryParse(_invoiceIdCtrl.text);
                    if (id != null) _loadPayments(id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('عرض'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  void _openRecordPaymentDialog(BuildContext context) {
    final userId = ref.read(authenticatedUserIdProvider)!;
    showDialog(
      context: context,
      builder: (ctx) {
        final invoiceIdCtrl = TextEditingController();
        final amountCtrl = TextEditingController();
        final refCtrl = TextEditingController();
        PaymentMethod selectedMethod = PaymentMethod.cash;
        PaymentType selectedType = PaymentType.incoming;

        return AlertDialog(
          title: const Text('تسجيل دفعة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: invoiceIdCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رقم الفاتورة', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ (بأقل وحدة نقدية)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PaymentMethod>(
                  initialValue: selectedMethod,
                  items: PaymentMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(m.displayName))).toList(),
                  onChanged: (v) => selectedMethod = v ?? PaymentMethod.cash,
                  decoration: const InputDecoration(labelText: 'طريقة الدفع', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PaymentType>(
                  initialValue: selectedType,
                  items: PaymentType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                  onChanged: (v) => selectedType = v ?? PaymentType.incoming,
                  decoration: const InputDecoration(labelText: 'نوع الدفعة', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refCtrl,
                  decoration: const InputDecoration(labelText: 'رقم المرجع (اختياري)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final invoiceId = int.tryParse(invoiceIdCtrl.text);
                final amount = int.tryParse(amountCtrl.text);
                if (invoiceId == null || amount == null) return;
                final userRole = await ref.read(currentUserRoleProvider.future);
                try {
                  await ref.read(recordPaymentUseCaseProvider).call(
                    Payment(
                      uuid: '',
                      propertyId: 1,
                      bookingId: 1,
                      invoiceId: invoiceId,
                      amount: Money(amount),
                      paymentMethod: selectedMethod,
                      paymentType: selectedType,
                      referenceNumber: refCtrl.text.isNotEmpty ? refCtrl.text : null,
                      createdBy: userId,
                      createdAt: DateTime.now(),
                    ),
                    userId,
                    role: userRole,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل الدفعة')));
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
