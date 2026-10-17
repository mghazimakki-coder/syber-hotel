import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bookable_stay.dart';
import '../models/apartment.dart';
import '../services/booking_service.dart';
import '../widgets/stay_image.dart';
import 'my_bookings_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final BookableStay stay;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guests;
  final double totalPrice;
  final String notes;

  const BookingConfirmationScreen({
    super.key,
    required this.stay,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guests,
    required this.totalPrice,
    this.notes = '',
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool isSubmitting = false;
  String? submissionError;

  BookableStay get stay => widget.stay;
  DateTime get checkInDate => widget.checkInDate;
  DateTime get checkOutDate => widget.checkOutDate;
  int get guests => widget.guests;
  double get totalPrice => widget.totalPrice;
  String get notes => widget.notes;

  // =========================
  // عدد الليالي
  // =========================
  int get numberOfNights {
    return checkOutDate.difference(checkInDate).inDays;
  }

  // =========================
  // تنسيق التاريخ
  // =========================
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // =========================
  // رقم حجز بسيط
  // =========================
  String get bookingNumber {
    return 'BK${checkInDate.millisecondsSinceEpoch.toString().substring(5)}';
  }

  Future<void> _confirmBooking() async {
    setState(() {
      isSubmitting = true;
      submissionError = null;
    });
    try {
      await BookingService.createBooking(
        stay: stay,
        checkIn: checkInDate,
        checkOut: checkOutDate,
        guests: guests,
        totalPrice: totalPrice,
        notes: notes,
      );
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.popUntil((route) => route.isFirst);
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const MyBookingsScreen(successMessage: 'تم إنشاء الحجز بنجاح'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is BookingConflictException
          ? error.toString()
          : error is BookingRequestException
          ? error.message
          : error is PostgrestException
          ? _databaseErrorMessage(error)
          : 'حدث خطأ أثناء إنشاء الحجز: $error';
      setState(() {
        isSubmitting = false;
        submissionError = message;
      });
    }
  }

  String _databaseErrorMessage(PostgrestException error) {
    final details = <String>[
      error.message,
      if (error.code != null) 'code: ${error.code}',
      if (error.details != null) 'details: ${error.details}',
      if (error.hint != null) 'hint: ${error.hint}',
    ];
    return 'خطأ قاعدة البيانات: ${details.join('\n')}';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F0),

        // =========================
        // App Bar
        // =========================
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F5F0),
          elevation: 0,
          centerTitle: true,

          title: Text(
            'تأكيد حجز ${stay.typeLabel}',
            style: TextStyle(
              color: Color(0xFF17202A),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF173B56),
            ),
          ),
        ),

        // =========================
        // Body
        // =========================
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // =========================
              // Success Icon
              // =========================
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF287A56).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF287A56),
                  size: 65,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'مراجعة الحجز',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'تأكد من بيانات الحجز قبل التأكيد',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 30),

              // =========================
              // Hotel Card
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: StayImage(
                          imageUrl: stay.imageUrl,
                          fallbackIcon: stay.typeLabel == 'شقة'
                              ? Icons.apartment
                              : Icons.hotel,
                          aspectRatio: 1,
                          hotelName: stay.typeLabel == 'فندق'
                              ? stay.name
                              : null,
                          apartmentHotelName: switch (stay) {
                            Apartment(:final hotelName) => hotelName,
                            _ => null,
                          },
                          apartmentName: switch (stay) {
                            Apartment(:final name) => name,
                            _ => null,
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stay.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            stay.typeLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF245A7A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF7A8490),
                                size: 18,
                              ),

                              const SizedBox(width: 4),

                              Expanded(
                                child: Text(
                                  stay.location,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // Booking Number
              // =========================
              _InfoCard(
                icon: Icons.confirmation_number_outlined,
                title: 'رقم الحجز',
                value: bookingNumber,
              ),

              const SizedBox(height: 12),

              // =========================
              // Check In
              // =========================
              _InfoCard(
                icon: Icons.login,
                title: 'تاريخ الوصول',
                value: formatDate(checkInDate),
              ),

              const SizedBox(height: 12),

              // =========================
              // Check Out
              // =========================
              _InfoCard(
                icon: Icons.logout,
                title: 'تاريخ المغادرة',
                value: formatDate(checkOutDate),
              ),

              const SizedBox(height: 12),

              // =========================
              // Nights
              // =========================
              _InfoCard(
                icon: Icons.nights_stay,
                title: 'عدد الليالي',
                value: '$numberOfNights ليلة',
              ),

              const SizedBox(height: 12),

              // =========================
              // Guests
              // =========================
              _InfoCard(
                icon: Icons.people,
                title: 'عدد الأشخاص',
                value: '$guests أشخاص',
              ),

              const SizedBox(height: 20),

              // =========================
              // Total Price
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      color: Color(0xFF245A7A),
                      size: 32,
                    ),

                    const SizedBox(width: 12),

                    const Text(
                      'السعر الإجمالي',
                      style: TextStyle(fontSize: 17, color: Colors.black54),
                    ),

                    const Spacer(),

                    Text(
                      '${totalPrice.toStringAsFixed(0)} جنيه سوداني',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF173B56),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // =========================
              // Final Confirm Button
              // =========================
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _confirmBooking,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF173B56),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  child: Text(
                    isSubmitting ? 'جار إنشاء الحجز...' : 'تأكيد الحجز النهائي',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              if (submissionError != null) ...[
                const SizedBox(height: 12),
                Text(
                  submissionError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB53B3B)),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// Info Card
// =====================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),

      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,

            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: Colors.blue),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
