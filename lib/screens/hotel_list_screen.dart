import 'package:flutter/material.dart';
import '../models/hotel.dart';
import '../services/auth_service.dart';
import '../services/hotel_service.dart';
import 'apartment_list_screen.dart';
import 'login_screen.dart';
import 'my_bookings_screen.dart';
import '../widgets/hotel_card.dart';

class HotelListScreen extends StatefulWidget {
  const HotelListScreen({super.key});

  @override
  State<HotelListScreen> createState() {
    return _HotelListScreenState();
  }
}

class _HotelListScreenState extends State<HotelListScreen> {
  List<Hotel> hotels = [];
  bool isLoading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final loadedHotels = await HotelService.getCustomerHotels();
      if (!mounted) return;
      setState(() {
        hotels = loadedHotels;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loadError = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ==========================================
  // الواجهة
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F5F0),

          // ====================================
          // AppBar
          // ====================================
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F5F0),
            elevation: 0,

            centerTitle: false,

            title: const Text(
              'Syber Hotel',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF173B56),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MyBookingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined),
                tooltip: 'حجوزاتي',
              ),
              IconButton(
                onPressed: _loadHotels,
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث الفندق',
              ),
              IconButton(
                onPressed: logout,
                icon: const Icon(Icons.logout),
                tooltip: 'تسجيل الخروج',
              ),
            ],
            bottom: const TabBar(
              labelColor: Color(0xFF173B56),
              unselectedLabelColor: Color(0xFF7A8490),
              indicatorColor: Color(0xFFD4A72C),
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'الفنادق', icon: Icon(Icons.hotel_outlined)),
                Tab(text: 'الشقق', icon: Icon(Icons.apartment_outlined)),
              ],
            ),
          ),

          // ====================================
          // محتوى الصفحة
          // ====================================
          body: TabBarView(
            children: [
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : loadError != null
                  ? _HotelLoadError(message: loadError!, onRetry: _loadHotels)
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 25),
                      children: hotels
                          .map((hotel) => HotelCard(hotel: hotel))
                          .toList(),
                    ),
              ApartmentListScreen(showAppBar: false),
            ],
          ),
        ),
      ),
    );
  }
}

class _HotelLoadError extends StatelessWidget {
  const _HotelLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تعذر تحميل الفندق: $message', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
