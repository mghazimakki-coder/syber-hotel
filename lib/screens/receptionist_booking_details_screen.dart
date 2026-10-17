import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/booking_inventory_policy.dart';
import '../services/manager_data_service.dart';

class ReceptionistBookingDetailsScreen extends StatefulWidget {
  const ReceptionistBookingDetailsScreen({super.key, required this.booking});

  final Map<String, dynamic> booking;

  @override
  State<ReceptionistBookingDetailsScreen> createState() =>
      _ReceptionistBookingDetailsScreenState();
}

class _ReceptionistBookingDetailsScreenState
    extends State<ReceptionistBookingDetailsScreen> {
  bool isSaving = false;
  String? error;

  String get status => widget.booking['status']?.toString() ?? 'pending';

  String _formatDate(dynamic value) {
    if (value == null) return 'غير محدد';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _performAction(String nextStatus, String label) async {
    if (nextStatus == 'cancelled' || nextStatus == 'checked_out') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(nextStatus == 'checked_out' ? 'تسجيل المغادرة' : 'إلغاء الحجز'),
            content: Text(
              nextStatus == 'checked_out'
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
                style: FilledButton.styleFrom(
                  backgroundColor: nextStatus == 'checked_out'
                      ? const Color(0xFF173B56)
                      : const Color(0xFFB53B3B),
                ),
                child: Text(
                  nextStatus == 'checked_out' ? 'تأكيد المغادرة' : 'تأكيد الإلغاء',
                ),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true) return;
      if (!mounted) return;
    }

    setState(() {
      isSaving = true;
      error = null;
    });
    try {
      await ManagerDataService.updateReceptionistBookingStatus(
        widget.booking['id'].toString(),
        nextStatus,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (actionError) {
      if (!mounted) return;
      setState(() {
        error = actionError is PostgrestException
            ? bookingDatabaseErrorMessage(
                code: actionError.code,
                message: actionError.message,
              )
            : actionError.toString();
        isSaving = false;
      });
    }
  }

  List<Widget> _actions() {
    final actions = availableBookingTransitions(status).map((nextStatus) {
      final (label, icon) = switch (nextStatus) {
        'confirmed' => ('تأكيد الحجز', Icons.check_circle_outline),
        'checked_in' => ('تسجيل الوصول', Icons.login),
        'checked_out' => ('تسجيل المغادرة', Icons.logout),
        'cancelled' => ('إلغاء الحجز', Icons.cancel_outlined),
        _ => ('قيد الانتظار', Icons.schedule),
      };
      return (nextStatus, label, icon);
    }).toList();
    return actions
        .map(
          (action) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: action.$1 == 'cancelled'
                  ? OutlinedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () => _performAction(action.$1, action.$2),
                      icon: Icon(action.$3, color: const Color(0xFFB53B3B)),
                      label: Text(
                        action.$2,
                        style: const TextStyle(color: Color(0xFFB53B3B)),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: isSaving
                          ? null
                          : () => _performAction(action.$1, action.$2),
                      icon: Icon(action.$3),
                      label: Text(action.$2),
                    ),
            ),
          ),
        )
        .toList();
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(label, style: const TextStyle(color: Color(0xFF7A8490))),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final statusLabel = switch (status) {
      'confirmed' => 'مؤكد',
      'checked_in' => 'تم تسجيل الوصول',
      'checked_out' => 'تم تسجيل المغادرة',
      'cancelled' => 'ملغي',
      _ => 'قيد الانتظار',
    };
    final itemName = booking['room_number'] != null
        ? 'غرفة ${booking['room_number']} · ${booking['room_type'] ?? ''}'
        : booking['apartment_name']?.toString() ?? 'وحدة غير محددة';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الحجز')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking['customer_name']?.toString() ??
                        'بيانات العميل غير متاحة',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Divider(height: 24),
                  _detail('رقم الحجز', booking['id']?.toString() ?? '—'),
                  _detail(
                    'هاتف العميل',
                    booking['customer_phone']?.toString() ?? 'غير متاح',
                  ),
                  _detail('الفندق', booking['hotel_name']?.toString() ?? '—'),
                  _detail('الغرفة / الشقة', itemName),
                  _detail('تاريخ الوصول', _formatDate(booking['check_in'])),
                  _detail('تاريخ المغادرة', _formatDate(booking['check_out'])),
                  _detail('عدد الضيوف', booking['guests']?.toString() ?? '—'),
                  _detail(
                    'السعر الإجمالي',
                    '${booking['total_price'] ?? '—'} جنيه سوداني',
                  ),
                  _detail('الحالة', statusLabel),
                  _detail('تاريخ الإنشاء', _formatDate(booking['created_at'])),
                  if ((booking['notes']?.toString() ?? '').isNotEmpty)
                    _detail('ملاحظات', booking['notes'].toString()),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isSaving) const LinearProgressIndicator(),
            if (error != null) ...[
              Text(error!, style: const TextStyle(color: Color(0xFFB53B3B))),
              const SizedBox(height: 12),
            ],
            ..._actions(),
            if (_actions().isEmpty)
              const Center(child: Text('لا توجد إجراءات متاحة لهذه الحالة')),
          ],
        ),
      ),
    );
  }
}
