import 'package:flutter/material.dart';

class ApartmentFilter extends StatefulWidget {
  final double minPrice;
  final double maxPrice;
  final RangeValues priceRange;
  final double selectedRating;
  final int selectedRooms;
  final int selectedBeds;
  final String? selectedType;
  final bool? availability;
  final void Function(
    double min,
    double max,
    double rating,
    int rooms,
    int beds,
    String? type,
    bool? available,
  )
  onApply;

  const ApartmentFilter({
    super.key,
    required this.minPrice,
    required this.maxPrice,
    required this.priceRange,
    required this.selectedRating,
    required this.selectedRooms,
    required this.selectedBeds,
    required this.selectedType,
    required this.availability,
    required this.onApply,
  });

  @override
  State<ApartmentFilter> createState() => _ApartmentFilterState();
}

class _ApartmentFilterState extends State<ApartmentFilter> {
  late RangeValues priceRange;
  late double rating;
  late int rooms;
  late int beds;
  late String? type;
  late bool? availability;

  @override
  void initState() {
    super.initState();
    priceRange = widget.priceRange;
    rating = widget.selectedRating;
    rooms = widget.selectedRooms;
    beds = widget.selectedBeds;
    type = widget.selectedType;
    availability = widget.availability;
  }

  void resetFilter() {
    setState(() {
      priceRange = RangeValues(widget.minPrice, widget.maxPrice);
      rating = 0;
      rooms = 0;
      beds = 0;
      type = null;
      availability = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'فلترة الشقق',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'السعر',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${priceRange.start.round()} - ${priceRange.end.round()} جنيه سوداني',
                style: const TextStyle(color: Colors.grey),
              ),
              RangeSlider(
                values: priceRange,
                min: widget.minPrice,
                max: widget.maxPrice,
                divisions: 20,
                labels: RangeLabels(
                  '${priceRange.start.round()}',
                  '${priceRange.end.round()}',
                ),
                onChanged: (value) => setState(() => priceRange = value),
              ),
              const SizedBox(height: 12),
              const Text(
                'التقييم',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _choice(
                    'الكل',
                    rating == 0,
                    () => setState(() => rating = 0),
                  ),
                  _choice(
                    '⭐ 3+',
                    rating == 3,
                    () => setState(() => rating = 3),
                  ),
                  _choice(
                    '⭐ 4+',
                    rating == 4,
                    () => setState(() => rating = 4),
                  ),
                  _choice(
                    '⭐ 4.5+',
                    rating == 4.5,
                    () => setState(() => rating = 4.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'عدد الغرف',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _choice('الكل', rooms == 0, () => setState(() => rooms = 0)),
                  _choice(
                    'غرفة واحدة',
                    rooms == 1,
                    () => setState(() => rooms = 1),
                  ),
                  _choice(
                    'غرفتان فأكثر',
                    rooms == 2,
                    () => setState(() => rooms = 2),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'عدد الأسرّة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _choice('الكل', beds == 0, () => setState(() => beds = 0)),
                  _choice(
                    'سرير واحد',
                    beds == 1,
                    () => setState(() => beds = 1),
                  ),
                  _choice(
                    'سريران فأكثر',
                    beds == 2,
                    () => setState(() => beds = 2),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'نوع الشقة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _choice(
                    'الكل',
                    type == null,
                    () => setState(() => type = null),
                  ),
                  _choice(
                    'استوديو',
                    type == 'استوديو',
                    () => setState(() => type = 'استوديو'),
                  ),
                  _choice(
                    'عائلية',
                    type == 'عائلية',
                    () => setState(() => type = 'عائلية'),
                  ),
                  _choice(
                    'فاخرة',
                    type == 'فاخرة',
                    () => setState(() => type = 'فاخرة'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'التوفر',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _choice(
                    'الكل',
                    availability == null,
                    () => setState(() => availability = null),
                  ),
                  _choice(
                    'متاحة',
                    availability == true,
                    () => setState(() => availability = true),
                  ),
                  _choice(
                    'غير متاحة',
                    availability == false,
                    () => setState(() => availability = false),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: resetFilter,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: const Text('مسح'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(
                          priceRange.start,
                          priceRange.end,
                          rating,
                          rooms,
                          beds,
                          type,
                          availability,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: const Text('تطبيق الفلتر'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
