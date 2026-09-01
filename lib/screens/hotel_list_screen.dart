import 'package:flutter/material.dart';

import '../models/hotel.dart';
import '../widgets/hotel_card.dart';
import '../widgets/hotel_filter.dart';

class HotelListScreen extends StatefulWidget {
  const HotelListScreen({
    super.key,
  });

  @override
  State<HotelListScreen> createState() {
    return _HotelListScreenState();
  }
}

class _HotelListScreenState
    extends State<HotelListScreen> {

  // ==========================
  // الفنادق
  // ==========================

  final List<Hotel> hotels = const [
    Hotel(
      name: 'Grand Hotel',
      location: 'Khartoum',
      price: 150.0,
      rating: 4.5,
      image: 'https://picsum.photos/300',
    ),

    Hotel(
      name: 'Royal Hotel',
      location: 'Omdurman',
      price: 200.0,
      rating: 4.0,
      image: 'https://picsum.photos/301',
    ),

    Hotel(
      name: 'Nile Hotel',
      location: 'Khartoum',
      price: 300.0,
      rating: 4.8,
      image: 'https://picsum.photos/302',
    ),

    Hotel(
      name: 'Blue Hotel',
      location: 'Bahri',
      price: 100.0,
      rating: 3.5,
      image: 'https://picsum.photos/303',
    ),

    Hotel(
      name: 'Capital Hotel',
      location: 'Khartoum',
      price: 250.0,
      rating: 4.2,
      image: 'https://picsum.photos/304',
    ),
  ];

  // ==========================
  // إعدادات الفلتر
  // ==========================

  double minPrice = 100.0;
  double maxPrice = 300.0;
  double selectedRating = 0.0;

  // ==========================
  // الفنادق بعد الفلترة
  // ==========================

  List<Hotel> get filteredHotels {
    return hotels.where((hotel) {
      final bool priceIsValid =
          hotel.price >= minPrice &&
          hotel.price <= maxPrice;

      final bool ratingIsValid =
          hotel.rating >= selectedRating;

      return priceIsValid && ratingIsValid;
    }).toList();
  }

  // ==========================
  // فتح الفلتر
  // ==========================

  void showFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return HotelFilter(
          minPrice: 100.0,
          maxPrice: 300.0,
          selectedRating: selectedRating,

          onApply: (
            double min,
            double max,
            double rating,
          ) {
            setState(() {
              minPrice = min;
              maxPrice = max;
              selectedRating = rating;
            });
          },
        );
      },
    );
  }

  // ==========================
  // إعادة الفلتر
  // ==========================

  void resetFilter() {
    setState(() {
      minPrice = 100.0;
      maxPrice = 300.0;
      selectedRating = 0.0;
    });
  }

  // ==========================
  // الواجهة
  // ==========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الفنادق',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,

        actions: [
          IconButton(
            onPressed: showFilter,
            icon: const Icon(
              Icons.filter_list,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ======================
          // عدد الفنادق + إعادة
          // ======================

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),

            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                Text(
                  '${filteredHotels.length} فندق',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: resetFilter,
                  child: const Text(
                    'إعادة الفلتر',
                  ),
                ),
              ],
            ),
          ),

          // ======================
          // قائمة الفنادق
          // ======================

          Expanded(
            child: filteredHotels.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد فنادق مطابقة للفلتر',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.all(16),

                    itemCount:
                        filteredHotels.length,

                    itemBuilder:
                        (context, index) {
                      final Hotel hotel =
                          filteredHotels[index];

                      return Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 15,
                        ),

                        child: HotelCard(
                          hotel: hotel,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
