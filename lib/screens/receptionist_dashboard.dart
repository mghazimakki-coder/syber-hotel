import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/manager_data_service.dart';
import 'login_screen.dart';
import 'receptionist_bookings_screen.dart';
import 'receptionist_inventory_screen.dart';

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({super.key});

  @override
  State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard> {
  bool isLoading = true;
  String? error;
  Map<String, int> summary = {};

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final result = await ManagerDataService.receptionistDashboardSummary();
      if (!mounted) return;
      setState(() {
        summary = result;
        isLoading = false;
      });
    } catch (loadError) {
      if (!mounted) return;
      setState(() {
        error = loadError is PostgrestException
            ? loadError.message
            : loadError.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) await _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة موظف الاستقبال'),
          actions: [
            IconButton(
              onPressed: _loadSummary,
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              onPressed: () => _logout(context),
              tooltip: 'تسجيل الخروج',
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF173B56),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.support_agent, color: Color(0xFFD4A72C), size: 28),
                  SizedBox(height: 22),
                  Text(
                    'واجهة الاستقبال',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'إدارة يوم الضيوف والحجوزات',
                    style: TextStyle(color: Color(0xFFD7E2E9), fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ملخص اليوم',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('تعذر تحميل الملخص: $error')),
                    IconButton(
                      onPressed: _loadSummary,
                      tooltip: 'إعادة المحاولة',
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 700 ? 4 : 2;
                  final spacing = 10.0;
                  final width =
                      (constraints.maxWidth - spacing * (columns - 1)) /
                      columns;
                  const metrics = <(String, String, IconData, Color)>[
                    (
                      'total_bookings',
                      'إجمالي الحجوزات',
                      Icons.event_note,
                      Color(0xFF245A7A),
                    ),
                    (
                      'pending_bookings',
                      'الحجوزات المعلقة',
                      Icons.hourglass_top,
                      Color(0xFFB4771D),
                    ),
                    (
                      'confirmed_bookings',
                      'الحجوزات المؤكدة',
                      Icons.check_circle_outline,
                      Color(0xFF287A56),
                    ),
                    (
                      'check_ins_today',
                      'وصول اليوم',
                      Icons.login,
                      Color(0xFF245A7A),
                    ),
                    (
                      'check_outs_today',
                      'مغادرة اليوم',
                      Icons.logout,
                      Color(0xFF245A7A),
                    ),
                    (
                      'available_rooms',
                      'الغرف المتاحة',
                      Icons.bed_outlined,
                      Color(0xFF287A56),
                    ),
                    (
                      'occupied_rooms',
                      'الغرف المشغولة',
                      Icons.bed,
                      Color(0xFFB4771D),
                    ),
                  ];
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: metrics.map((metric) {
                      return SizedBox(
                        width: width,
                        child: _SummaryMetric(
                          value: summary[metric.$1] ?? 0,
                          label: metric.$2,
                          icon: metric.$3,
                          color: metric.$4,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 26),
            const Text(
              'إدارة الفندق',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _NavigationTile(
              icon: Icons.event_note,
              title: 'إدارة الحجوزات',
              subtitle: 'عرض الحجوزات وتحديث حالتها',
              onTap: () => _open(const ReceptionistBookingsScreen()),
            ),
            const SizedBox(height: 10),
            _NavigationTile(
              icon: Icons.login,
              title: 'تسجيل الوصول',
              subtitle: 'الحجوزات المؤكدة الجاهزة للوصول',
              onTap: () => _open(
                const ReceptionistBookingsScreen(
                  title: 'تسجيل الوصول',
                  status: 'confirmed',
                  showStatusFilters: false,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _NavigationTile(
              icon: Icons.logout,
              title: 'تسجيل المغادرة',
              subtitle: 'النزلاء المسجل وصولهم حالياً',
              onTap: () => _open(
                const ReceptionistBookingsScreen(
                  title: 'تسجيل المغادرة',
                  status: 'checked_in',
                  showStatusFilters: false,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _NavigationTile(
              icon: Icons.update,
              title: 'تحديث حالة الحجز',
              subtitle: 'إدارة حالات الحجوزات',
              onTap: () => _open(
                const ReceptionistBookingsScreen(title: 'تحديث حالة الحجز'),
              ),
            ),
            const SizedBox(height: 10),
            _NavigationTile(
              icon: Icons.bed_outlined,
              title: 'الغرف',
              subtitle: 'حالة الغرف والأسعار',
              onTap: () => _open(
                const ReceptionistInventoryScreen(showApartments: false),
              ),
            ),
            const SizedBox(height: 10),
            _NavigationTile(
              icon: Icons.apartment,
              title: 'الشقق',
              subtitle: 'الوحدات والأسعار والحالة',
              onTap: () => _open(
                const ReceptionistInventoryScreen(showApartments: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Text(
            '$value',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7A8490)),
          ),
        ],
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF245A7A)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }
}
