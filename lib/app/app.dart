/// Why the file exists:
/// Sets up general MaterialApp configs including localization flags and theme connections.
/// Implements [Official Product Name: Property Management System (PMS)] consistently as requested.
/// Configures complete interactive PMS Navigation linking to Phase 1 Features.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import '../features/properties/presentation/screens/properties_screen.dart';
import '../features/units/presentation/screens/units_screen.dart';
import '../features/guests/presentation/screens/guests_screen.dart';
import '../features/invoices/presentation/screens/invoices_screen.dart';
import '../features/bookings/presentation/screens/bookings_screen.dart';
import '../features/payments/presentation/screens/payments_screen.dart';
import '../features/settlements/presentation/screens/settlements_screen.dart';
import '../features/expenses/presentation/screens/expenses_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/backup/presentation/screens/backup_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/properties/presentation/providers/property_providers.dart';
import '../features/properties/presentation/providers/dashboard_providers.dart';
import '../features/properties/domain/entities/property.dart';

class PropertyManagementSystemApp extends StatelessWidget {
  const PropertyManagementSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Property Management System (PMS)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar', 'SA'), // Defaulting to Arabic locale as requested
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
        Locale('fr', 'FR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const PMSDashboardHomeScreen(),
    );
  }
}

/// Dynamic State-aware dashboard managing Phase 1 layouts and active views.
/// Built with strict [UX_Guidelines.md] Sidebar layouts.
class PMSDashboardHomeScreen extends ConsumerStatefulWidget {
  const PMSDashboardHomeScreen({super.key});

  @override
  ConsumerState<PMSDashboardHomeScreen> createState() => _PMSDashboardHomeScreenState();
}

class _PMSDashboardHomeScreenState extends ConsumerState<PMSDashboardHomeScreen> {
  int _selectedIndex = 0; // 0 = Dashboard, 1 = Properties, 2 = Units, 3+ = Placeholders

  Widget _buildBody(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return _buildMainDashboardView(context);
      case 1:
        return const PropertiesScreen();
      case 2:
        return const UnitsScreen();
      case 3:
        return const BookingsScreen();
      case 4:
        return const GuestsScreen();
      case 5:
        return const InvoicesScreen();
      case 6:
        return const PaymentsScreen();
      case 7:
        return const ReportsScreen();
      case 8:
        return const BackupScreen();
      case 9:
        return const ExpensesScreen();
      case 10:
        return const SettlementsScreen();
      case 11:
        return const SettingsScreen();
      default:
        return _buildPhasePlaceholderView(context);
    }
  }

  Widget _buildMainDashboardView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activeProperty = ref.watch(selectedPropertyProvider);

    return Container(
      padding: const EdgeInsets.all(32),
      color: const Color(0xFFF1F5F9),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نظام إدارة الفنادق والعقارات الشامل',
              style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'أهلاً بك في لوحة تحكّم النظام الشامل لإشراك وإدارة الشقق الفندقية والعقارات والنزلاء والمجرى المالي للعمل والمصارف بدقة متناهية.',
              style: textTheme.bodyLarge?.copyWith(color: const Color(0xFF475569)),
            ),
            const SizedBox(height: 24),
            
            // Phase 1 Selected Property Banner
            Card(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF3B82F6), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF3B82F6),
                      child: Icon(Icons.business_outlined, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeProperty == null 
                                ? 'لم يتم تحديد منشأة نشطة حالياً' 
                                : 'المنشأة النشطة حالياً: ${activeProperty.name}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeProperty == null 
                                ? 'يرجى تحديد أو إنشاء منشأة سياحية للتمكن من إدارة الغرف بكافة وظائفها.' 
                                : 'موقع المنشأة: ${activeProperty.address ?? ""}, العملة الأساسية: ${activeProperty.currencyCode}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 1; // Transition to Properties screen
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(activeProperty == null ? 'إنشاء وتفعيل منشأة' : 'تغيير المنشأة'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Bento configuration widgets
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _MetricCard(
                  title: 'إجمالي الغرف والوحدات المتاحة',
                  provider: activeUnitsCountProvider,
                  color: Color(0xFF10B981),
                  icon: Icons.meeting_room,
                ),
                _MetricCard(
                  title: 'الحجوزات النشطة (Active Bookings)',
                  provider: activeBookingsCountProvider,
                  color: Color(0xFF3B82F6),
                  icon: Icons.book_online,
                ),
                _MetricCard(
                  title: 'العمليات والتدقيقات المحفوظة',
                  provider: auditLogsCountProvider,
                  color: Color(0xFFF59E0B),
                  icon: Icons.security,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhasePlaceholderView(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded, size: 60, color: Color(0xFF64748B)),
                const SizedBox(height: 16),
                const Text(
                  'المرحلة قيد التطوير والمراجعة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'وفقاً لخطط التنزيل الصارمة والمعتمدة، تخضع هذه العمليات حالياً لتدقيق قواعد البيانات.\nيرجى استكمال وإجراء الفحص التشغيلي الشامل للمرحلة الأولى أولاً (Properties, Settings, Unit Types, Units).',
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.5, color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                  child: const Text('العودة للوحة تحكم الغرف والعقارات'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Property>>>(propertiesListProvider, (previous, next) {
      next.whenData((props) {
        final currentActive = ref.read(selectedPropertyProvider);
        if (currentActive != null) {
          final activeId = currentActive.id;
          final exists = props.any((p) => p.id == activeId);
          if (!exists) {
            if (props.isNotEmpty) {
              ref.read(selectedPropertyProvider.notifier).state = props.first;
            } else {
              ref.read(selectedPropertyProvider.notifier).state = null;
            }
          }
        } else if (props.isNotEmpty) {
          ref.read(selectedPropertyProvider.notifier).state = props.first;
        }
      });
    });

    final textTheme = Theme.of(context).textTheme;
    final propertiesAsync = ref.watch(propertiesListProvider);
    final activeProperty = ref.watch(selectedPropertyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام إدارة العقارات | Property Management System (PMS)'),
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Sidebar Panel - Implements [UX-200]
          SizedBox(
            width: 260,
            child: Container(
              color: const Color(0xFF0F172A),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Text(
                      'PMS CONTROL PANEL',
                      style: textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontFamily: 'Space Grotesk',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                
                // Dynamic active property dropdown directly inside Sidebar!
                propertiesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, s) => Container(),
                  data: (props) {
                    if (props.isEmpty) return Container();
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: activeProperty != null && props.any((p) => p.id == activeProperty.id)
                              ? activeProperty.id
                              : null,
                          hint: const Text('اختر منشأة نشطة', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          dropdownColor: const Color(0xFF0F172A),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                          items: props.map((p) {
                            return DropdownMenuItem<int?>(
                              value: p.id,
                              child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) {
                              final p = props.firstWhere((p) => p.id == id);
                              ref.read(selectedPropertyProvider.notifier).state = p;
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
                
                Expanded(
                  child: ListView(
                    children: [
                      const Divider(color: Colors.white12, height: 16),
                      _SidebarItem(
                        icon: Icons.dashboard, 
                        title: 'الرئيسية (Dashboard)', 
                        isActive: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                      _SidebarItem(
                        icon: Icons.business, 
                        title: 'العقارات والمنشآت (Properties)', 
                        isActive: _selectedIndex == 1,
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                      _SidebarItem(
                        icon: Icons.meeting_room, 
                        title: 'الوحدات السكنية (Units)', 
                        isActive: _selectedIndex == 2,
                        onTap: () => setState(() => _selectedIndex = 2),
                      ),
                      _SidebarItem(
                        icon: Icons.book_online, 
                        title: 'إدارة الحجوزات (Bookings)', 
                        isActive: _selectedIndex == 3,
                        onTap: () => setState(() => _selectedIndex = 3),
                      ),
                      _SidebarItem(
                        icon: Icons.people, 
                        title: 'دليل النزلاء (Guests)', 
                        isActive: _selectedIndex == 4,
                        onTap: () => setState(() => _selectedIndex = 4),
                      ),
                      _SidebarItem(
                        icon: Icons.receipt_long, 
                        title: 'الفواتير (Invoices)', 
                        isActive: _selectedIndex == 5,
                        onTap: () => setState(() => _selectedIndex = 5),
                      ),
                      _SidebarItem(
                        icon: Icons.account_balance_wallet, 
                        title: 'المدفوعات والتسوية (Payments)', 
                        isActive: _selectedIndex == 6,
                        onTap: () => setState(() => _selectedIndex = 6),
                      ),
                      _SidebarItem(
                        icon: Icons.monetization_on, 
                        title: 'المصروفات (Expenses)', 
                        isActive: _selectedIndex == 9,
                        onTap: () => setState(() => _selectedIndex = 9),
                      ),
                      _SidebarItem(
                        icon: Icons.balance, 
                        title: 'التسويات (Settlements)', 
                        isActive: _selectedIndex == 10,
                        onTap: () => setState(() => _selectedIndex = 10),
                      ),
                      _SidebarItem(
                        icon: Icons.analytics, 
                        title: 'التقارير المتقدمة (Reports)', 
                        isActive: _selectedIndex == 7,
                        onTap: () => setState(() => _selectedIndex = 7),
                      ),
                      _SidebarItem(
                        icon: Icons.backup, 
                        title: 'النسخ الاحتياطي (Backup)', 
                        isActive: _selectedIndex == 8,
                        onTap: () => setState(() => _selectedIndex = 8),
                      ),
                      _SidebarItem(
                        icon: Icons.settings, 
                        title: 'الإعدادات (Settings)', 
                        isActive: _selectedIndex == 11,
                        onTap: () => setState(() => _selectedIndex = 11),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
          
          // Dynamic Central Body Area
          Expanded(key: ValueKey('body-panel-$_selectedIndex'), child: _buildBody(context))
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          tileColor: isActive ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 20),
          title: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          dense: true,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _MetricCard extends ConsumerWidget {
  final String title;
  final AutoDisposeFutureProvider<int> provider;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.provider,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(provider);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            countAsync.when(
              data: (count) => Text(
                count.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              loading: () => const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => Text(
                '---',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
