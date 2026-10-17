import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/manager_data_service.dart';

enum _ReportPeriod { today, thisWeek, thisMonth, all }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool isLoading = true;
  String? error;
  ManagerReportData? reportData;
  _ReportPeriod selectedPeriod = _ReportPeriod.thisMonth;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await ManagerDataService.loadManagerReportData();
      if (!mounted) return;
      setState(() {
        reportData = data;
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

  List<Map<String, dynamic>> _bookingsForPeriod(
    List<Map<String, dynamic>> bookings,
  ) {
    if (selectedPeriod == _ReportPeriod.all) return bookings;
    final now = DateTime.now();
    final start = switch (selectedPeriod) {
      _ReportPeriod.today => DateTime(now.year, now.month, now.day),
      _ReportPeriod.thisWeek => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1)),
      _ReportPeriod.thisMonth => DateTime(now.year, now.month),
      _ReportPeriod.all => DateTime(1),
    };
    final end = switch (selectedPeriod) {
      _ReportPeriod.today => start.add(const Duration(days: 1)),
      _ReportPeriod.thisWeek => start.add(const Duration(days: 7)),
      _ReportPeriod.thisMonth => DateTime(now.year, now.month + 1),
      _ReportPeriod.all => DateTime(9999),
    };
    return bookings.where((booking) {
      final createdAt = DateTime.tryParse(
        booking['created_at']?.toString() ?? '',
      )?.toLocal();
      return createdAt != null &&
          !createdAt.isBefore(start) &&
          createdAt.isBefore(end);
    }).toList();
  }

  int _count(List<Map<String, dynamic>> bookings, String status) => bookings
      .where((booking) => booking['status']?.toString() == status)
      .length;

  int _guestCount(List<Map<String, dynamic>> bookings, {String? status}) =>
      bookings.fold<int>(0, (total, booking) {
        final bookingStatus = booking['status']?.toString() ?? '';
        if (bookingStatus == 'cancelled' ||
            (status != null && bookingStatus != status)) {
          return total;
        }
        final value = booking['guests'];
        final guests = value is num
            ? value.toInt()
            : int.tryParse(value?.toString() ?? '') ?? 0;
        return total + (guests > 0 ? guests : 0);
      });

  List<_PopularUnit> _popularUnits(List<Map<String, dynamic>> bookings) {
    final counts = <String, int>{};
    final labels = <String, String>{};
    final roomIds = <String>{};
    for (final booking in bookings) {
      if (booking['status']?.toString() == 'cancelled') continue;
      final roomId = booking['room_id']?.toString().trim();
      final apartmentId = booking['apartment_id']?.toString().trim();
      final isRoom = roomId != null && roomId.isNotEmpty;
      final unitId = isRoom ? roomId : apartmentId;
      if (unitId == null || unitId.isEmpty) continue;

      final key = '${isRoom ? 'room' : 'apartment'}:$unitId';
      counts.update(key, (count) => count + 1, ifAbsent: () => 1);
      if (isRoom) {
        roomIds.add(key);
        labels[key] =
            'غرفة ${booking['room_number'] ?? ''} ${booking['room_type'] ?? ''}'
                .trim();
      } else {
        labels[key] = booking['apartment_name']?.toString() ?? 'شقة';
      }
    }

    final units =
        counts.entries
            .map(
              (entry) => _PopularUnit(
                label: labels[entry.key] ?? 'وحدة إقامة',
                bookings: entry.value,
                isRoom: roomIds.contains(entry.key),
              ),
            )
            .toList()
          ..sort((first, second) {
            final countOrder = second.bookings.compareTo(first.bookings);
            return countOrder != 0
                ? countOrder
                : first.label.compareTo(second.label);
          });
    return units.take(5).toList();
  }

  double _revenue(
    List<Map<String, dynamic>> bookings,
    bool Function(String status) include,
  ) {
    return bookings.fold<double>(0, (total, booking) {
      final status = booking['status']?.toString() ?? '';
      final price = (booking['total_price'] as num?)?.toDouble() ?? 0;
      return include(status) && price.isFinite ? total + price : total;
    });
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF245A7A), size: 21),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF173B56),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricGrid(List<_ReportMetric> metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 2 ? 1.12 : 1.45,
          ),
          itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
        );
      },
    );
  }

  Widget _bookingTile(Map<String, dynamic> booking) {
    final status = booking['status']?.toString() ?? 'pending';
    final stayName = booking['room_id'] != null
        ? 'غرفة ${booking['room_number'] ?? ''} ${booking['room_type'] ?? ''}'
        : booking['apartment_name']?.toString() ?? 'وحدة إقامة';
    final guestName = booking['customer_name']?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  guestName == null || guestName.isEmpty
                      ? 'عميل غير معروف'
                      : guestName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF17202A),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusLabel(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stayName.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF245A7A)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              _BookingDetail(
                icon: Icons.login,
                text: _dateLabel(booking['check_in']),
              ),
              _BookingDetail(
                icon: Icons.logout,
                text: _dateLabel(booking['check_out']),
              ),
              _BookingDetail(
                icon: Icons.people_outline,
                text: '${booking['guests'] ?? 0} ضيوف',
              ),
              _BookingDetail(
                icon: Icons.payments_outlined,
                text: _money(booking['total_price']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _dateLabel(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '—';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _money(dynamic value) {
    final amount = (value as num?)?.toDouble() ?? 0;
    final decimals = amount == amount.roundToDouble() ? 0 : 2;
    return '${amount.toStringAsFixed(decimals)} جنيه سوداني';
  }

  Widget _buildReport(ManagerReportData data) {
    final bookings = _bookingsForPeriod(data.bookings);
    bool isNotCancelled(String status) => status != 'cancelled';
    final bookingMetrics = <_ReportMetric>[
      _ReportMetric(
        'إجمالي الحجوزات',
        '${bookings.length}',
        Icons.receipt_long,
      ),
      _ReportMetric('معلقة', '${_count(bookings, 'pending')}', Icons.schedule),
      _ReportMetric(
        'مؤكدة',
        '${_count(bookings, 'confirmed')}',
        Icons.check_circle_outline,
      ),
      _ReportMetric(
        'حجوزات تم تسجيل وصولها',
        '${_count(bookings, 'checked_in')}',
        Icons.login,
      ),
      _ReportMetric(
        'تم تسجيل المغادرة',
        '${_count(bookings, 'checked_out')}',
        Icons.logout,
      ),
      _ReportMetric('ملغاة', '${_count(bookings, 'cancelled')}', Icons.cancel),
      _ReportMetric(
        'إجمالي الضيوف غير الملغاة',
        '${_guestCount(bookings)}',
        Icons.people_alt_outlined,
      ),
      _ReportMetric(
        'نزلاء تم تسجيل وصولهم',
        '${_guestCount(bookings, status: 'checked_in')}',
        Icons.person_pin_circle_outlined,
      ),
    ];
    final statusCounts = <_ReportStatusCount>[
      _ReportStatusCount(
        'معلقة',
        _count(bookings, 'pending'),
        const Color(0xFFB4771D),
      ),
      _ReportStatusCount(
        'مؤكدة',
        _count(bookings, 'confirmed'),
        const Color(0xFF287A56),
      ),
      _ReportStatusCount(
        'تم الوصول',
        _count(bookings, 'checked_in'),
        const Color(0xFF245A7A),
      ),
      _ReportStatusCount(
        'تمت المغادرة',
        _count(bookings, 'checked_out'),
        const Color(0xFF173B56),
      ),
      _ReportStatusCount(
        'ملغاة',
        _count(bookings, 'cancelled'),
        const Color(0xFFB53B3B),
      ),
    ];
    final popularUnits = _popularUnits(bookings);
    final roomMetrics = _inventoryMetrics(data.rooms, 'الغرف');
    final apartmentMetrics = _inventoryMetrics(data.apartments, 'الشقق');
    final revenueMetrics = <_ReportMetric>[
      _ReportMetric(
        'إجمالي قيمة الحجوزات',
        _money(_revenue(bookings, isNotCancelled)),
        Icons.payments_outlined,
      ),
      _ReportMetric(
        'قيمة الحجوزات المؤكدة',
        _money(_revenue(bookings, (status) => status == 'confirmed')),
        Icons.verified_outlined,
      ),
      _ReportMetric(
        'قيمة الحجوزات المكتملة',
        _money(_revenue(bookings, (status) => status == 'checked_out')),
        Icons.task_alt,
      ),
    ];

    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_ReportPeriod>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _ReportPeriod.today, label: Text('اليوم')),
                ButtonSegment(
                  value: _ReportPeriod.thisWeek,
                  label: Text('هذا الأسبوع'),
                ),
                ButtonSegment(
                  value: _ReportPeriod.thisMonth,
                  label: Text('هذا الشهر'),
                ),
                ButtonSegment(value: _ReportPeriod.all, label: Text('الكل')),
              ],
              selected: {selectedPeriod},
              onSelectionChanged: (selection) {
                setState(() => selectedPeriod = selection.first);
              },
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle('الحجوزات', Icons.event_note),
          _metricGrid(bookingMetrics),
          const SizedBox(height: 22),
          _sectionTitle('توزيع الحجوزات حسب الحالة', Icons.bar_chart),
          _StatusBreakdownChart(items: statusCounts),
          const SizedBox(height: 22),
          _sectionTitle('الغرف', Icons.hotel_outlined),
          _metricGrid(roomMetrics),
          const SizedBox(height: 22),
          _sectionTitle('الشقق', Icons.apartment_outlined),
          _metricGrid(apartmentMetrics),
          const SizedBox(height: 22),
          _sectionTitle('الإيرادات', Icons.account_balance_wallet_outlined),
          _metricGrid(revenueMetrics),
          const SizedBox(height: 22),
          _sectionTitle('أحدث الحجوزات', Icons.history),
          if (bookings.isEmpty)
            const _EmptyBookings()
          else
            ...bookings.take(10).map(_bookingTile),
          const SizedBox(height: 12),
          _sectionTitle('الوحدات الأكثر حجزاً', Icons.leaderboard_outlined),
          if (popularUnits.isEmpty)
            const _NoPopularUnits()
          else
            ...popularUnits.map(_PopularUnitTile.new),
        ],
      ),
    );
  }

  List<_ReportMetric> _inventoryMetrics(
    List<Map<String, dynamic>> inventory,
    String type,
  ) {
    int count(String status) =>
        inventory.where((item) => item['status']?.toString() == status).length;
    return [
      _ReportMetric('إجمالي $type', '${inventory.length}', Icons.inventory_2),
      _ReportMetric(
        'متاحة',
        '${count('available')}',
        Icons.check_circle_outline,
      ),
      _ReportMetric('مشغولة', '${count('occupied')}', Icons.bed),
      _ReportMetric('تحت الصيانة', '${count('maintenance')}', Icons.build),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التقارير'),
          actions: [
            IconButton(
              onPressed: _loadReportData,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 42),
                      const SizedBox(height: 12),
                      Text(error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _loadReportData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              )
            : reportData == null
            ? const _EmptyBookings()
            : _buildReport(reportData!),
      ),
    );
  }
}

class _ReportMetric {
  const _ReportMetric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _ReportStatusCount {
  const _ReportStatusCount(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;
}

class _PopularUnit {
  const _PopularUnit({
    required this.label,
    required this.bookings,
    required this.isRoom,
  });

  final String label;
  final int bookings;
  final bool isRoom;
}

class _StatusBreakdownChart extends StatelessWidget {
  const _StatusBreakdownChart({required this.items});

  final List<_ReportStatusCount> items;

  @override
  Widget build(BuildContext context) {
    final maximum = items.fold<int>(
      0,
      (highest, item) => item.count > highest ? item.count : highest,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.map((item) {
          final fraction = maximum == 0 ? 0.0 : item.count / maximum;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                SizedBox(width: 82, child: Text(item.label)),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: SizedBox(
                      height: 10,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: Color(0xFFF0F2F3)),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              widthFactor: fraction,
                              child: ColoredBox(color: item.color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${item.count}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PopularUnitTile extends StatelessWidget {
  const _PopularUnitTile(this.unit);

  final _PopularUnit unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            unit.isRoom ? Icons.hotel_outlined : Icons.apartment_outlined,
            color: const Color(0xFF245A7A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              unit.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${unit.bookings} حجز',
            style: const TextStyle(
              color: Color(0xFF173B56),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPopularUnits extends StatelessWidget {
  const _NoPopularUnits();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: Text('لا توجد بيانات كافية لترتيب الوحدات'),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _ReportMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(metric.icon, color: const Color(0xFF245A7A), size: 19),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF59636D),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              metric.value,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF173B56),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingDetail extends StatelessWidget {
  const _BookingDetail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF7A8490)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'confirmed' => ('مؤكد', const Color(0xFF287A56)),
      'checked_in' => ('تم الوصول', const Color(0xFFB4771D)),
      'checked_out' => ('مكتمل', const Color(0xFF245A7A)),
      'cancelled' => ('ملغى', const Color(0xFFB53B3B)),
      _ => ('معلق', const Color(0xFF7A8490)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 42, color: Color(0xFF7A8490)),
          SizedBox(height: 10),
          Text('لا توجد حجوزات في الفترة المحددة'),
        ],
      ),
    );
  }
}
