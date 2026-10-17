import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:student_app/utils/apartment_image_assets.dart';
import 'package:student_app/widgets/stay_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('maps all 19 hotel and apartment names to unique local assets', (
    tester,
  ) async {
    const expected = {
      'Syber Hotel': {
        'شقة اقتصادية': 'assets/images/apartments/apartment_01.jpg',
        'شقة عائلية': 'assets/images/apartments/apartment_02.jpg',
        'شقة فاخرة': 'assets/images/apartments/apartment_03.jpg',
        'اليمن': 'assets/images/apartments/apartment_04.jpg',
      },
      'Acropole Hotel': {
        'شقة ستاندرد': 'assets/images/apartments/apartment_05.jpg',
        'شقة عائلية': 'assets/images/apartments/apartment_06.jpg',
        'شقة فاخرة': 'assets/images/apartments/apartment_07.jpg',
      },
      'Corinthia Hotel Khartoum': {
        'شقة ستاندرد': 'assets/images/apartments/apartment_08.jpg',
        'شقة عائلية': 'assets/images/apartments/apartment_09.jpg',
        'شقة فاخرة': 'assets/images/apartments/apartment_10.jpg',
      },
      'Al Salam Hotel Khartoum': {
        'شقة ستاندرد': 'assets/images/apartments/apartment_11.jpg',
        'شقة عائلية': 'assets/images/apartments/apartment_12.jpg',
        'شقة فاخرة': 'assets/images/apartments/apartment_13.jpg',
      },
      'Grand Holiday Villa Hotel': {
        'شقة ستاندرد': 'assets/images/apartments/apartment_14.jpg',
        'شقة عائلية': 'assets/images/apartments/apartment_15.jpg',
        'شقة فاخرة': 'assets/images/apartments/apartment_16.jpg',
      },
      'EWA Khartoum Hotel & Apartments': {
        'شقة ستاندرد': 'assets/images/apartments/apartment_17.jpg',
        'شقة عائلية': 'assets/images/apartments/apartment_18.jpg',
        'شقة فاخرة': 'assets/images/apartments/apartment_19.jpg',
      },
    };

    final allMappedAssets = <String>[];
    for (final hotelEntry in expected.entries) {
      for (final apartmentEntry in hotelEntry.value.entries) {
        final asset = ApartmentImageMapper.assetFor(
          hotelName: hotelEntry.key,
          apartmentName: apartmentEntry.key,
        );
        expect(asset, apartmentEntry.value);
        allMappedAssets.add(asset!);
        await rootBundle.load(asset);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StayImage(
                imageUrl: '',
                fallbackIcon: Icons.apartment,
                apartmentHotelName: hotelEntry.key,
                apartmentName: apartmentEntry.key,
              ),
            ),
          ),
        );
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.image, AssetImage(apartmentEntry.value));
      }
    }

    expect(allMappedAssets, hasLength(19));
    expect(allMappedAssets.toSet(), hasLength(19));
  });

  test('returns no asset when the hotel and apartment pair is unknown', () {
    expect(
      ApartmentImageMapper.assetFor(
        hotelName: 'Unknown Hotel',
        apartmentName: 'شقة فاخرة',
      ),
      isNull,
    );
  });

  test('trims whitespace around Supabase names before resolving assets', () {
    expect(
      ApartmentImageMapper.assetFor(
        hotelName: ' Syber Hotel ',
        apartmentName: ' شقة اقتصادية ',
      ),
      'assets/images/apartments/apartment_01.jpg',
    );
  });
}
