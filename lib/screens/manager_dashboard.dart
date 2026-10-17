import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'bookings_management_screen.dart';
import 'hotel_management_screen.dart';
import 'login_screen.dart';
import 'reports_screen.dart';
import 'rooms_apartments_management_screen.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة المدير'),
          backgroundColor: const Color(0xFFF7F5F0),
          actions: [
            IconButton(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              tooltip: 'تسجيل الخروج',
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
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF173B56).withValues(alpha: 0.16),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.apartment, color: Color(0xFFD4A72C), size: 28),
                  SizedBox(height: 22),
                  Text(
                    'إدارة الفندق\nمن مكان واحد',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'تابع التشغيل والحجوزات والإيرادات',
                    style: TextStyle(color: Color(0xFFD7E2E9), fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'أقسام الإدارة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            _ManagerSection(
              icon: Icons.hotel,
              title: 'إدارة معلومات الفندق',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HotelManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ManagerSection(
              icon: Icons.apartment,
              title: 'إدارة الغرف والشقق',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RoomsApartmentsManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ManagerSection(
              icon: Icons.event_note,
              title: 'إدارة الحجوزات',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BookingsManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ManagerSection(
              icon: Icons.bar_chart,
              title: 'التقارير والإحصائيات',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagerSection extends StatelessWidget {
  const _ManagerSection({required this.icon, required this.title, this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF245A7A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF245A7A)),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_left, size: 21),
          ),
        ),
      ),
    );
  }
}
