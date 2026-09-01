import 'package:flutter/material.dart';

class HotelFilter extends StatefulWidget {
  final double minPrice;
  final double maxPrice;
  final double selectedRating;
  final Function(double min, double max, double rating) onApply;

  const HotelFilter({
    super.key,
    required this.minPrice,
    required this.maxPrice,
    required this.selectedRating,
    required this.onApply,
  });

  @override
  State<HotelFilter> createState() => _HotelFilterState();
}

class _HotelFilterState extends State<HotelFilter> {
  late RangeValues priceRange;
  late double rating;

  @override
  void initState() {
    super.initState();

    priceRange = RangeValues(
      widget.minPrice,
      widget.maxPrice,
    );

    rating = widget.selectedRating;
  }

  void resetFilter() {
    setState(() {
      priceRange = RangeValues(
        widget.minPrice,
        widget.maxPrice,
      );

      rating = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ==============================
              // Header
              // ==============================

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'فلترة الفنادق',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 26,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const Divider(),

              const SizedBox(height: 15),

              // ==============================
              // Price
              // ==============================

              const Text(
                'السعر',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '${priceRange.start.round()} - ${priceRange.end.round()} جنيه',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 5),

              RangeSlider(
                values: priceRange,
                min: widget.minPrice,
                max: widget.maxPrice,
                divisions: 20,
                labels: RangeLabels(
                  '${priceRange.start.round()}',
                  '${priceRange.end.round()}',
                ),
                onChanged: (values) {
                  setState(() {
                    priceRange = values;
                  });
                },
              ),

              const SizedBox(height: 20),

              // ==============================
              // Rating
              // ==============================

              const Text(
                'التقييم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ratingButton(
                    title: 'الكل',
                    value: 0,
                  ),

                  _ratingButton(
                    title: '⭐ 3+',
                    value: 3,
                  ),

                  _ratingButton(
                    title: '⭐ 4+',
                    value: 4,
                  ),

                  _ratingButton(
                    title: '⭐ 4.5+',
                    value: 4.5,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ==============================
              // Buttons
              // ==============================

              Row(
                children: [

                  // Reset
                  Expanded(
                    child: OutlinedButton(
                      onPressed: resetFilter,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          52,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'مسح',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Apply
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(
                          priceRange.start,
                          priceRange.end,
                          rating,
                        );

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          52,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'تطبيق الفلتر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================
  // Rating Button
  // ==============================

  Widget _ratingButton({
    required String title,
    required double value,
  }) {
    final bool isSelected = rating == value;

    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          rating = value;
        });
      },
    );
  }
}