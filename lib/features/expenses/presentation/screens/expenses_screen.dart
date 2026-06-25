library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../core/common/models/money.dart';
import '../../../../core/providers/permission_providers.dart';
import '../../../../core/providers/session_providers.dart';
import '../../../properties/presentation/providers/property_providers.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_category.dart';
import '../providers/expense_providers.dart';

final _expensesProvider = FutureProvider.autoDispose<List<Expense>>((ref) async {
  final property = ref.watch(selectedPropertyProvider);
  if (property?.id == null) return [];
  return ref.watch(getExpensesUseCaseProvider).call(property!.id!);
});

final _categoriesProvider = FutureProvider.autoDispose<List<ExpenseCategory>>((ref) async {
  return ref.watch(getExpenseCategoriesUseCaseProvider).call();
});

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  @override
  Widget build(BuildContext context) {
    final activeAccount = ref.watch(activeAccountIdProvider);
    final authenticatedUserId = ref.watch(authenticatedUserIdProvider);
    final activeProperty = ref.watch(selectedPropertyProvider);

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
                    const Text('المصروفات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text('تسجيل وإدارة مصروفات المنشأة', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: activeProperty != null ? () => _openCreateExpenseDialog(context) : null,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('تسجيل مصروف'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (activeProperty == null)
              const Expanded(child: Center(child: Text('الرجاء تحديد منشأة من القائمة الجانبية')))
            else
              const Expanded(child: _ExpensesList()),
          ],
        ),
      ),
    );
  }

  void _openCreateExpenseDialog(BuildContext context) {
    final userId = ref.read(authenticatedUserIdProvider)!;
    final propertyId = ref.read(selectedPropertyProvider)!.id!;
    showDialog(
      context: context,
      builder: (ctx) {
        final amountCtrl = TextEditingController();
        final descCtrl = TextEditingController();
        int selectedCategoryId = 1;

        return AlertDialog(
          title: const Text('تسجيل مصروف جديد', textDirection: TextDirection.rtl),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ (بأقل وحدة نقدية)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final amount = int.tryParse(amountCtrl.text);
                if (amount == null) return;
                final userRole = await ref.read(currentUserRoleProvider.future);
                try {
                  await ref.read(createExpenseUseCaseProvider).call(
                    Expense(
                      uuid: '',
                      propertyId: propertyId,
                      expenseCategoryId: selectedCategoryId,
                      amount: Money(amount),
                      description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
                      expenseDate: DateTime.now(),
                      createdBy: userId,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                    userId,
                    role: userRole,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ref.invalidate(_expensesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل المصروف')));
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

class _ExpensesList extends ConsumerWidget {
  const _ExpensesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(_expensesProvider);
    final categoriesAsync = ref.watch(_categoriesProvider);
    final categoryMap = categoriesAsync.asData != null
        ? {for (final c in categoriesAsync.asData!.value) if (c.id != null) c.id!: c.name}
        : <int, String>{};

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                'خطأ أثناء جلب المصروفات: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      data: (expenses) {
        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'لا توجد مصروفات مسجلة بعد.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('الوصف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                    Expanded(flex: 2, child: Text('المبلغ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                    Expanded(flex: 2, child: Text('التصنيف', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                    Expanded(flex: 2, child: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)))),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: ListView.separated(
                  itemCount: expenses.length,
                  separatorBuilder: (context, idx) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, idx) {
                    final expense = expenses[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              expense.description ?? 'بدون وصف',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              expense.amount.format(''),
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              categoryMap[expense.expenseCategoryId] ?? 'تصنيف ${expense.expenseCategoryId}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              intl.DateFormat('yyyy/MM/dd').format(expense.expenseDate),
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
