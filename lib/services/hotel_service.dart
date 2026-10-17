import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/hotel.dart';

class HotelService {
  HotelService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<List<Hotel>> getCustomerHotels() async {
    const pageSize = 500;
    final rows = <Map<String, dynamic>>[];
    for (var offset = 0; ; offset += pageSize) {
      final page = List<Map<String, dynamic>>.from(
        await _client
            .from('hotels')
            .select('*')
            .order('name')
            .order('id')
            .range(offset, offset + pageSize - 1),
      );
      rows.addAll(page);
      if (page.length < pageSize) break;
    }
    if (rows.isEmpty) {
      throw StateError('لا يوجد فندق متاح حالياً');
    }

    final hotelIds = rows
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    final inventoryResults = await Future.wait(
      [
        for (var offset = 0; offset < hotelIds.length; offset += 100)
          hotelIds.sublist(
            offset,
            offset + 100 < hotelIds.length ? offset + 100 : hotelIds.length,
          ),
      ].map(
        (ids) => Future.wait([
          _client
              .from('rooms')
              .select('hotel_id, price')
              .inFilter('hotel_id', ids),
          _client
              .from('apartments')
              .select('hotel_id, price')
              .inFilter('hotel_id', ids),
        ]),
      ),
    );
    final pricesByHotel = <String, List<double>>{};
    for (final batch in inventoryResults) {
      for (final row in [...batch[0] as List, ...batch[1] as List]) {
        final hotelId = row['hotel_id']?.toString();
        final price = (row['price'] as num?)?.toDouble();
        if (hotelId != null && price != null) {
          pricesByHotel.putIfAbsent(hotelId, () => []).add(price);
        }
      }
    }

    return rows.map((row) {
      final hotelId = row['id']?.toString() ?? '';
      final prices = pricesByHotel[hotelId] ?? const <double>[];
      final startingPrice = prices.isEmpty
          ? 0.0
          : prices.reduce((first, second) => first < second ? first : second);
      return Hotel.fromMap(row, price: startingPrice);
    }).toList();
  }
}
