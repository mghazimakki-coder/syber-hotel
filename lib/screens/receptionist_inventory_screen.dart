import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/booking_inventory_policy.dart';
import '../services/manager_data_service.dart';

class ReceptionistInventoryScreen extends StatefulWidget {
  const ReceptionistInventoryScreen({super.key, required this.showApartments});

  final bool showApartments;

  @override
  State<ReceptionistInventoryScreen> createState() =>
      _ReceptionistInventoryScreenState();
}

class _ReceptionistInventoryScreenState
    extends State<ReceptionistInventoryScreen> {
  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final loaded = widget.showApartments
          ? await ManagerDataService.listApartmentsForReceptionist()
          : await ManagerDataService.listRoomsForReceptionist();
      if (!mounted) return;
      setState(() {
        items = loaded;
        isLoading = false;
      });
    } catch (loadError) {
      if (!mounted) return;
      setState(() {
        error = loadError is PostgrestException
            ? bookingDatabaseErrorMessage(
                code: loadError.code,
                message: loadError.message,
              )
            : loadError.toString();
        isLoading = false;
      });
    }
  }

  String _statusLabel(String status) => switch (status) {
    'available' => 'متاحة',
    'occupied' => 'مشغولة',
    'maintenance' => 'صيانة',
    _ => 'غير محددة',
  };

  Color _statusColor(String status) => switch (status) {
    'available' => const Color(0xFF287A56),
    'occupied' => const Color(0xFFB4771D),
    'maintenance' => const Color(0xFFB53B3B),
    _ => const Color(0xFF7A8490),
  };

  Widget _itemTile(Map<String, dynamic> item) {
    final isApartment = widget.showApartments;
    final status = item['status']?.toString() ?? '';
    final title = isApartment
        ? item['name']?.toString() ?? 'شقة'
        : 'غرفة ${item['room_number'] ?? '—'}';
    final subtitle = isApartment
        ? item['description']?.toString() ?? 'لا يوجد وصف'
        : item['room_type']?.toString() ?? 'غرفة فندقية';
    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF245A7A).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isApartment ? Icons.apartment : Icons.bed_outlined,
              color: const Color(0xFF245A7A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: isApartment ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF7A8490)),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item['price'] ?? 0} جنيه سوداني',
                  style: const TextStyle(
                    color: Color(0xFF173B56),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.showApartments ? 'الشقق' : 'الغرف';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              onPressed: _loadItems,
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadItems,
          child: isLoading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(
                      height: 360,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                )
              : error != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    SizedBox(
                      height: 300,
                      child: Center(
                        child: Text(error!, textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                )
              : items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 360,
                      child: Center(child: Text('لا توجد $title مسجلة')),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _itemTile(items[index]),
                ),
        ),
      ),
    );
  }
}
