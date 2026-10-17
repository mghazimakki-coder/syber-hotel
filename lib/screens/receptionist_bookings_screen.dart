import 'package:flutter/material.dart';

import 'bookings_management_screen.dart';

class ReceptionistBookingsScreen extends StatelessWidget {
  const ReceptionistBookingsScreen({
    super.key,
    this.title = 'إدارة الحجوزات',
    this.status = 'all',
    this.showStatusFilters = true,
  });

  final String title;
  final String status;
  final bool showStatusFilters;

  @override
  Widget build(BuildContext context) {
    return BookingsManagementScreen(
      isReceptionist: true,
      initialStatus: status,
      screenTitle: title,
      showStatusFilters: showStatusFilters,
    );
  }
}
