import 'package:flutter/material.dart';

import '../models/bookable_stay.dart';
import '../models/apartment.dart';
import '../services/booking_service.dart';
import '../widgets/stay_image.dart';
import 'booking_confirmation_screen.dart';

class BookingScreen extends StatefulWidget {
  final BookableStay stay;

  const BookingScreen({super.key, required this.stay});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? checkInDate;
  DateTime? checkOutDate;
  bool isCheckingAvailability = false;
  bool? isAvailable;
  String? availabilityError;
  int _availabilityRequest = 0;

  int guests = 2;
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkInDate = widget.stay.availabilityCheckIn;
    checkOutDate = widget.stay.availabilityCheckOut;
    if (checkInDate != null && checkOutDate != null) {
      _refreshAvailability();
    }
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  // =========================
  // اختيار التاريخ
  // =========================
  Future<void> selectDate({required bool isCheckIn}) async {
    final DateTime now = DateTime.now();

    final DateTime firstDate = isCheckIn
        ? now
        : (checkInDate?.add(const Duration(days: 1)) ?? now);

    final DateTime initialDate = isCheckIn
        ? (checkInDate ?? now)
        : (checkOutDate ??
              checkInDate?.add(const Duration(days: 1)) ??
              now.add(const Duration(days: 1)));

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      if (isCheckIn) {
        checkInDate = selectedDate;

        if (checkOutDate != null && !checkOutDate!.isAfter(selectedDate)) {
          checkOutDate = null;
        }
      } else {
        checkOutDate = selectedDate;
      }
    });
    await _refreshAvailability();
  }

  Future<void> _refreshAvailability() async {
    final checkIn = checkInDate;
    final checkOut = checkOutDate;
    final request = ++_availabilityRequest;
    if (checkIn == null || checkOut == null || !checkOut.isAfter(checkIn)) {
      setState(() {
        isCheckingAvailability = false;
        isAvailable = null;
        availabilityError = null;
      });
      return;
    }

    setState(() {
      isCheckingAvailability = true;
      isAvailable = null;
      availabilityError = null;
    });
    try {
      final available = await BookingService.isStayAvailable(
        stay: widget.stay,
        checkIn: checkIn,
        checkOut: checkOut,
      );
      if (!mounted || request != _availabilityRequest) return;
      setState(() {
        isAvailable = available;
        isCheckingAvailability = false;
      });
    } catch (error) {
      if (!mounted || request != _availabilityRequest) return;
      setState(() {
        isCheckingAvailability = false;
        isAvailable = false;
        availabilityError = error is BookingRequestException
            ? error.message
            : 'تعذر التحقق من التوفر: $error';
      });
    }
  }

  // =========================
  // عدد الليالي
  // =========================
  int get numberOfNights {
    if (checkInDate == null || checkOutDate == null) {
      return 0;
    }

    return checkOutDate!.difference(checkInDate!).inDays;
  }

  // =========================
  // السعر الإجمالي
  // =========================
  double get totalPrice {
    return widget.stay.price * numberOfNights;
  }

  // =========================
  // تنسيق التاريخ
  // =========================
  String formatDate(DateTime? date) {
    if (date == null) {
      return 'اختر التاريخ';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // =========================
  // الانتقال إلى تأكيد الحجز
  // =========================
  void goToConfirmation() {
    if (checkInDate == null || checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار تاريخ الوصول والمغادرة')),
      );

      return;
    }

    if (numberOfNights <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تاريخ المغادرة يجب أن يكون بعد تاريخ الوصول'),
        ),
      );

      return;
    }

    if (isAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            availabilityError ??
                'هذه الوحدة محجوزة بالفعل خلال الفترة المحددة.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return BookingConfirmationScreen(
            stay: widget.stay,
            checkInDate: checkInDate!,
            checkOutDate: checkOutDate!,
            guests: guests,
            totalPrice: totalPrice,
            notes: notesController.text.trim(),
          );
        },
      ),
    );
  }

  Widget _availabilityStatus() {
    final Color color;
    final IconData icon;
    final String message;
    if (isCheckingAvailability) {
      color = const Color(0xFF7A8490);
      icon = Icons.hourglass_top;
      message = 'جارٍ التحقق من التوفر';
    } else if (availabilityError != null) {
      color = const Color(0xFFB53B3B);
      icon = Icons.error_outline;
      message = availabilityError!;
    } else if (isAvailable == true) {
      color = const Color(0xFF287A56);
      icon = Icons.check_circle_outline;
      message = 'متاحة للفترة المحددة';
    } else if (isAvailable == false) {
      color = const Color(0xFFB53B3B);
      icon = Icons.block;
      message = 'غير متاحة للفترة المحددة';
    } else {
      color = const Color(0xFF7A8490);
      icon = Icons.date_range;
      message = 'اختر تواريخ الإقامة للتحقق من التوفر';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          if (isCheckingAvailability)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
        ],
      ),
    );
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
            'حجز ${widget.stay.typeLabel}',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================
              // Hotel Card
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),

                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: StayImage(
                          imageUrl: widget.stay.imageUrl,
                          fallbackIcon: widget.stay.typeLabel == 'شقة'
                              ? Icons.apartment
                              : Icons.hotel,
                          aspectRatio: 1,
                          hotelName: widget.stay.typeLabel == 'فندق'
                              ? widget.stay.name
                              : null,
                          apartmentHotelName: switch (widget.stay) {
                            Apartment(:final hotelName) => hotelName,
                            _ => null,
                          },
                          apartmentName: switch (widget.stay) {
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
                            widget.stay.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            widget.stay.typeLabel,
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
                                  widget.stay.location,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Text(
                            '${widget.stay.price} جنيه سوداني / ليلة',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF173B56),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات إضافية (اختياري)',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 30),

              // =========================
              // Booking Information
              // =========================
              const Text(
                'بيانات الحجز',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              // =========================
              // Check In
              // =========================
              _BookingInfoItem(
                icon: Icons.calendar_today,
                title: 'تاريخ الوصول',
                value: formatDate(checkInDate),

                onTap: () {
                  selectDate(isCheckIn: true);
                },
              ),

              const SizedBox(height: 12),
              _availabilityStatus(),
              const SizedBox(height: 12),

              // =========================
              // Check Out
              // =========================
              _BookingInfoItem(
                icon: Icons.calendar_month,
                title: 'تاريخ المغادرة',
                value: formatDate(checkOutDate),

                onTap: () {
                  if (checkInDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('اختر تاريخ الوصول أولاً')),
                    );

                    return;
                  }

                  selectDate(isCheckIn: false);
                },
              ),

              const SizedBox(height: 12),

              // =========================
              // Guests
              // =========================
              Container(
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
                        color: const Color(0xFF245A7A).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: const Icon(Icons.people, color: Color(0xFF245A7A)),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Text(
                        'عدد الأشخاص',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        if (guests > 1) {
                          setState(() {
                            guests--;
                          });
                        }
                      },

                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Color(0xFF245A7A),
                      ),
                    ),

                    Text(
                      '$guests',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        if (guests < 10) {
                          setState(() {
                            guests++;
                          });
                        }
                      },

                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF245A7A),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // =========================
              // Number of Nights
              // =========================
              if (numberOfNights > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: const Color(0xFF245A7A).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: Row(
                    children: [
                      const Icon(
                        Icons.nights_stay,
                        color: Color(0xFF245A7A),
                        size: 28,
                      ),

                      const SizedBox(width: 12),

                      const Text('عدد الليالي', style: TextStyle(fontSize: 16)),

                      const Spacer(),

                      Text(
                        '$numberOfNights ليلة',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF245A7A),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 15),

              // =========================
              // Total Price
              // =========================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      color: Color(0xFF245A7A),
                      size: 30,
                    ),

                    const SizedBox(width: 12),

                    const Text(
                      'السعر الإجمالي',
                      style: TextStyle(fontSize: 17, color: Colors.black54),
                    ),

                    const Spacer(),

                    Text(
                      numberOfNights > 0
                          ? '${totalPrice.toStringAsFixed(0)} جنيه سوداني'
                          : '0 جنيه سوداني',

                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF173B56),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // =========================
              // Confirm Button
              // =========================
              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed: isAvailable == true && !isCheckingAvailability
                      ? goToConfirmation
                      : null,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF173B56),
                    foregroundColor: Colors.white,
                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  child: const Text(
                    'متابعة لتأكيد الحجز',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// Booking Information Item
// =====================================================

class _BookingInfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _BookingInfoItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      borderRadius: BorderRadius.circular(15),

      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),

        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,

              decoration: BoxDecoration(
                color: const Color(0xFF245A7A).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),

              child: Icon(icon, color: const Color(0xFF245A7A)),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
