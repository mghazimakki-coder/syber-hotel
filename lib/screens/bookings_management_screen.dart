import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/booking_inventory_policy.dart';
import '../services/manager_data_service.dart';
import 'receptionist_booking_details_screen.dart';

class BookingsManagementScreen extends StatefulWidget {
  const BookingsManagementScreen({
    super.key,
    this.isReceptionist = false,
    this.initialStatus = 'all',
    this.screenTitle = 'إدارة الحجوزات',
    this.showStatusFilters = true,
  });

  final bool isReceptionist;
  final String initialStatus;
  final String screenTitle;
  final bool showStatusFilters;

  @override
  State<BookingsManagementScreen> createState() =>
      _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends State<BookingsManagementScreen> {
  bool isLoading = true;
  String? error;
  late String selectedStatus;
  List<Map<String, dynamic>> bookings = [];

  static const _bookingStatuses = <String, String>{
    'all': 'الكل',
    'pending': 'معلقة',
    'confirmed': 'مؤكدة',
    'checked_in': 'تم الوصول',
    'checked_out': 'تمت المغادرة',
    'cancelled': 'ملغاة',
  };

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialStatus;
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final rows = widget.isReceptionist
          ? await ManagerDataService.listBookingsForReceptionist()
          : await ManagerDataService.listBookingsForManager();
      if (!mounted) return;
      setState(() {
        bookings = rows;
        isLoading = false;
      });
    } catch (loadError) {
      if (!mounted) return;
      setState(() {
        error = loadError is PostgrestException
            ? 'تعذر تحميل الحجوزات: ${bookingDatabaseErrorMessage(code: loadError.code, message: loadError.message)}'
            : 'تعذر تحميل الحجوزات: $loadError';
        isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(
    Map<String, dynamic> booking,
    String status,
  ) async {
    if (status == 'checked_out' || status == 'cancelled') {
      final checked = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              status == 'checked_out' ? 'تسجيل المغادرة' : 'إلغاء الحجز',
            ),
            content: Text(
              status == 'checked_out'
                  ? 'هل أنت متأكد من تسجيل مغادرة النزيل؟'
                  : 'هل أنت متأكد من إلغاء هذا الحجز؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('رجوع'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  status == 'checked_out' ? 'تأكيد المغادرة' : 'تأكيد الإلغاء',
                ),
              ),
            ],
          ),
        ),
      );
      if (checked != true || !mounted) return;
    }

    try {
      await ManagerDataService.updateBookingStatus(
        booking['id'].toString(),
        status,
      );
      if (mounted) {
        await _loadBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث حالة الحجز بنجاح')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is PostgrestException
                  ? bookingDatabaseErrorMessage(
                      code: error.code,
                      message: error.message,
                    )
                  : error.toString(),
            ),
          ),
        );
      }
    }
  }

  void _viewBooking(Map<String, dynamic> booking) {
    final details = [
      'العميل: ${booking['customer_name'] ?? booking['user_id'] ?? 'غير معروف'}',
      if (booking['customer_email'] != null)
        'البريد الإلكتروني: ${booking['customer_email']}',
      'الفندق: ${booking['hotel_name'] ?? booking['hotel_id'] ?? 'غير معروف'}',
      'الغرفة: ${booking['room_number'] ?? 'غير محددة'}',
      'نوع الغرفة: ${booking['room_type'] ?? 'غير محدد'}',
      'الشقة: ${booking['apartment_name'] ?? 'غير محددة'}',
      'تاريخ الوصول: ${booking['check_in'] ?? 'غير محدد'}',
      'تاريخ المغادرة: ${booking['check_out'] ?? 'غير محدد'}',
      'عدد الضيوف: ${booking['guests'] ?? 'غير محدد'}',
      'السعر الإجمالي: ${booking['total_price'] ?? 'غير محدد'}',
      'الحالة: ${booking['status'] ?? 'pending'}',
      'تاريخ إنشاء الحجز: ${_formatDate(booking['created_at'])}',
      'ملاحظات: ${booking['notes'] ?? 'لا توجد'}',
    ].join('\n');
    showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تفاصيل الحجز'),
          content: SingleChildScrollView(child: Text(details)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'غير محدد';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return '${date.day}/${date.month}/${date.year}';
  }

  String _statusActionLabel(String status) => switch (status) {
    'confirmed' => 'تأكيد الحجز',
    'checked_in' => 'تسجيل الوصول',
    'checked_out' => 'تسجيل المغادرة',
    'cancelled' => 'إلغاء الحجز',
    _ => 'قيد الانتظار',
  };

  Widget _bookingTile(Map<String, dynamic> booking) {
    final status = booking['status']?.toString() ?? 'pending';
    final statusLabel = switch (status) {
      'confirmed' => 'مؤكد',
      'cancelled' => 'ملغي',
      'checked_in' => 'تم تسجيل الوصول',
      'checked_out' => 'تم تسجيل المغادرة',
      _ => 'قيد الانتظار',
    };
    final statusColor = switch (status) {
      'confirmed' || 'checked_in' => const Color(0xFF287A56),
      'cancelled' => const Color(0xFFB53B3B),
      'checked_out' => const Color(0xFF245A7A),
      _ => const Color(0xFFB4771D),
    };
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: const Icon(Icons.event_note, color: Color(0xFF245A7A)),
      title: Text(
        booking['customer_name']?.toString() ?? 'حجز ${booking['id'] ?? ''}',
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking['customer_email']?.toString() ??
                booking['user_id']?.toString() ??
                'بيانات العميل غير متاحة',
          ),
          if (widget.isReceptionist && booking['customer_phone'] != null)
            Text('الهاتف: ${booking['customer_phone']}'),
          if (widget.isReceptionist && booking['hotel_name'] != null)
            Text('الفندق: ${booking['hotel_name']}'),
          Text(
            booking['room_number'] != null
                ? 'غرفة ${booking['room_number']} · ${booking['room_type'] ?? ''}'
                : booking['apartment_name']?.toString() ?? 'وحدة غير محددة',
          ),
          Text(
            '${booking['check_in'] ?? '—'} إلى ${booking['check_out'] ?? '—'} · '
            '${booking['guests'] ?? '—'} ضيف · ${booking['total_price'] ?? '—'} جنيه سوداني',
          ),
          Text('تاريخ الإنشاء: ${_formatDate(booking['created_at'])}'),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      onTap: () => widget.isReceptionist
          ? _openReceptionistBooking(booking)
          : _viewBooking(booking),
      trailing: widget.isReceptionist
          ? const Icon(Icons.chevron_left)
          : availableBookingTransitions(status).isEmpty
          ? null
          : PopupMenuButton<String>(
              onSelected: (value) => _updateStatus(booking, value),
              itemBuilder: (_) => availableBookingTransitions(status)
                  .map(
                    (nextStatus) => PopupMenuItem(
                      value: nextStatus,
                      child: Text(_statusActionLabel(nextStatus)),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Future<void> _openReceptionistBooking(Map<String, dynamic> booking) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ReceptionistBookingDetailsScreen(booking: booking),
      ),
    );
    if (updated == true && mounted) {
      await _loadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث حالة الحجز بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.screenTitle),
          actions: [
            IconButton(
              onPressed: _loadBookings,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            if (widget.isReceptionist && widget.showStatusFilters)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: _bookingStatuses.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: selectedStatus == entry.key,
                        onSelected: (_) =>
                            setState(() => selectedStatus = entry.key),
                      ),
                    );
                  }).toList(),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadBookings,
                child: Builder(
                  builder: (context) {
                    final visibleBookings = selectedStatus == 'all'
                        ? bookings
                        : bookings
                              .where(
                                (booking) =>
                                    booking['status'] == selectedStatus,
                              )
                              .toList();
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: isLoading
                          ? 1
                          : error != null || visibleBookings.isEmpty
                          ? 1
                          : visibleBookings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (isLoading) {
                          return const SizedBox(
                            height: 240,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (error != null) {
                          return SizedBox(
                            height: 240,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  error!,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          );
                        }
                        if (visibleBookings.isEmpty) {
                          return SizedBox(
                            height: 240,
                            child: Center(
                              child: Text(
                                selectedStatus == 'all'
                                    ? 'لا توجد حجوزات لهذا الفندق'
                                    : 'لا توجد حجوزات بهذه الحالة',
                              ),
                            ),
                          );
                        }
                        return _bookingTile(visibleBookings[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
