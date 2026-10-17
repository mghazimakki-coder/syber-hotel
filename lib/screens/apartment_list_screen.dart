import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/apartment.dart';
import '../services/booking_service.dart';
import '../widgets/apartment_card.dart';
import '../widgets/apartment_filter.dart';

class ApartmentListScreen extends StatefulWidget {
  final bool showAppBar;
  final String? hotelId;

  const ApartmentListScreen({super.key, this.showAppBar = true, this.hotelId});

  @override
  State<ApartmentListScreen> createState() => _ApartmentListScreenState();
}

class _ApartmentListScreenState extends State<ApartmentListScreen> {
  List<Apartment> apartments = [];
  bool isLoading = true;
  String? loadError;

  double minPrice = 0;
  double maxPrice = 1;
  double priceFloor = 0;
  double priceCeiling = 1;
  double selectedRating = 0;
  int selectedRooms = 0;
  int selectedBeds = 0;
  String? selectedType;
  bool? selectedAvailability;
  late DateTime checkInDate;
  late DateTime checkOutDate;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    checkInDate = DateTime(today.year, today.month, today.day);
    checkOutDate = checkInDate.add(const Duration(days: 1));
    _loadApartments();
  }

  Future<void> _selectDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final firstDate = isCheckIn
        ? DateTime(now.year, now.month, now.day)
        : checkInDate.add(const Duration(days: 1));
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? checkInDate : checkOutDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selectedDate == null || !mounted) return;
    setState(() {
      if (isCheckIn) {
        checkInDate = selectedDate;
        if (!checkOutDate.isAfter(checkInDate)) {
          checkOutDate = checkInDate.add(const Duration(days: 1));
        }
      } else {
        checkOutDate = selectedDate;
      }
    });
    await _loadApartments();
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Future<void> _loadApartments() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final client = Supabase.instance.client;
      var apartmentQuery = client.from('apartments').select('*');
      var hotelQuery = client.from('hotels').select('id, name, location');
      final requestedHotelId = widget.hotelId;
      if (requestedHotelId != null && requestedHotelId.isNotEmpty) {
        apartmentQuery = apartmentQuery.eq('hotel_id', requestedHotelId);
        hotelQuery = hotelQuery.eq('id', requestedHotelId);
      }
      final results = await Future.wait<dynamic>([apartmentQuery, hotelQuery]);
      final apartmentRows = List<Map<String, dynamic>>.from(results[0] as List);
      final hotelsById = {
        for (final hotel in List<Map<String, dynamic>>.from(results[1] as List))
          hotel['id'].toString(): hotel,
      };
      final hotelIds = apartmentRows
          .map((row) => row['hotel_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      final availabilityResults = await Future.wait(
        hotelIds.map(
          (id) => BookingService.listInventoryAvailability(
            hotelId: id,
            checkIn: checkInDate,
            checkOut: checkOutDate,
          ),
        ),
      );
      final availability = <String, bool>{
        for (final result in availabilityResults) ...result,
      };
      final loaded = apartmentRows.map((row) {
        final amenities = row['amenities'];
        final apartmentId = row['id']?.toString() ?? '';
        final hotel = hotelsById[row['hotel_id']?.toString()];
        final hotelName = hotel?['name']?.toString() ?? '';
        final hotelLocation = hotel?['location']?.toString() ?? '';
        return Apartment(
          id: apartmentId,
          hotelId: row['hotel_id']?.toString() ?? '',
          hotelName: hotelName,
          name: row['name']?.toString() ?? 'شقة',
          location: [
            if (hotelName.isNotEmpty) hotelName,
            if (hotelLocation.isNotEmpty) hotelLocation,
          ].join(' · '),
          description: row['description']?.toString() ?? '',
          imageUrl: row['image_url']?.toString() ?? '',
          price: (row['price'] as num?)?.toDouble() ?? 0,
          rating: (row['rating'] as num?)?.toDouble() ?? 0,
          numberOfRooms: (row['number_of_rooms'] as num?)?.toInt() ?? 0,
          numberOfBeds: (row['number_of_beds'] as num?)?.toInt() ?? 0,
          numberOfBathrooms: (row['number_of_bathrooms'] as num?)?.toInt() ?? 0,
          apartmentType: row['apartment_type']?.toString() ?? 'شقة',
          available: availability['apartment:$apartmentId'] ?? false,
          amenities: amenities is List
              ? amenities.map((value) => value.toString()).toList()
              : const [],
          availabilityCheckIn: checkInDate,
          availabilityCheckOut: checkOutDate,
        );
      }).toList();
      final prices = loaded.map((apartment) => apartment.price).toList();
      final low = prices.isEmpty ? 0.0 : prices.reduce((a, b) => a < b ? a : b);
      final high = prices.isEmpty
          ? 1.0
          : prices.reduce((a, b) => a > b ? a : b);
      if (!mounted) return;
      setState(() {
        apartments = loaded;
        priceFloor = low;
        priceCeiling = high > low ? high : low + 1;
        minPrice = priceFloor;
        maxPrice = priceCeiling;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loadError = error is PostgrestException
            ? error.message
            : error.toString();
        isLoading = false;
      });
    }
  }

  List<Apartment> get filteredApartments {
    return apartments.where((apartment) {
      final priceMatches =
          apartment.price >= minPrice && apartment.price <= maxPrice;
      final ratingMatches = apartment.rating >= selectedRating;
      final roomsMatch =
          selectedRooms == 0 ||
          (selectedRooms == 1
              ? apartment.numberOfRooms == 1
              : apartment.numberOfRooms >= selectedRooms);
      final bedsMatch =
          selectedBeds == 0 ||
          (selectedBeds == 1
              ? apartment.numberOfBeds == 1
              : apartment.numberOfBeds >= selectedBeds);
      final typeMatches =
          selectedType == null || apartment.apartmentType == selectedType;
      final availabilityMatches =
          selectedAvailability == null ||
          apartment.available == selectedAvailability;
      return priceMatches &&
          ratingMatches &&
          roomsMatch &&
          bedsMatch &&
          typeMatches &&
          availabilityMatches;
    }).toList();
  }

  void showFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ApartmentFilter(
        minPrice: priceFloor,
        maxPrice: priceCeiling,
        priceRange: RangeValues(minPrice, maxPrice),
        selectedRating: selectedRating,
        selectedRooms: selectedRooms,
        selectedBeds: selectedBeds,
        selectedType: selectedType,
        availability: selectedAvailability,
        onApply: (min, max, rating, rooms, beds, type, available) {
          setState(() {
            minPrice = min;
            maxPrice = max;
            selectedRating = rating;
            selectedRooms = rooms;
            selectedBeds = beds;
            selectedType = type;
            selectedAvailability = available;
          });
        },
      ),
    );
  }

  void resetFilter() {
    setState(() {
      minPrice = priceFloor;
      maxPrice = priceCeiling;
      selectedRating = 0;
      selectedRooms = 0;
      selectedBeds = 0;
      selectedType = null;
      selectedAvailability = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6DF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'الشقق والأسعار المعروضة تجريبية لاختبار التطبيق، ولا تمثل وحدات أو توافراً مؤكداً لدى الفنادق.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF785A17), height: 1.4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => _selectDate(isCheckIn: true),
                  icon: const Icon(Icons.login),
                  label: Text('الوصول ${_formatDate(checkInDate)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () => _selectDate(isCheckIn: false),
                  icon: const Icon(Icons.logout),
                  label: Text('المغادرة ${_formatDate(checkOutDate)}'),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: showFilter,
                icon: const Icon(Icons.filter_list, color: Color(0xFF3F444B)),
                tooltip: 'فلترة الشقق',
              ),
              IconButton(
                onPressed: isLoading ? null : _loadApartments,
                icon: const Icon(Icons.refresh, color: Color(0xFF3F444B)),
                tooltip: 'تحديث التوفر',
              ),
              const Spacer(),
              TextButton(
                onPressed: resetFilter,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'إعادة الفلتر',
                  style: TextStyle(color: Color(0xFF315B7D)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${filteredApartments.length} شقة',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('تعذر تحميل الشقق: $loadError'),
                  ),
                )
              : filteredApartments.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد شقق مطابقة للفلتر',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 25),
                  itemCount: filteredApartments.length,
                  itemBuilder: (_, index) => ApartmentCard(
                    apartment: filteredApartments[index],
                    onReturn: _loadApartments,
                  ),
                ),
        ),
      ],
    );

    if (!widget.showAppBar) {
      return Directionality(textDirection: TextDirection.rtl, child: content);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F5F0),
          elevation: 0,
          centerTitle: true,
          title: Text(
            widget.hotelId == null ? 'شقق الفنادق' : 'شقق الفندق',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color(0xFF173B56),
            ),
          ),
        ),
        body: content,
      ),
    );
  }
}
