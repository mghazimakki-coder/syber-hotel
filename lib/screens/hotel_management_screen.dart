import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/profile_service.dart';
import '../widgets/stay_image.dart';

class HotelManagementScreen extends StatefulWidget {
  const HotelManagementScreen({super.key});

  @override
  State<HotelManagementScreen> createState() => _HotelManagementScreenState();
}

class _HotelManagementScreenState extends State<HotelManagementScreen> {
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final descriptionController = TextEditingController();
  final phoneController = TextEditingController();
  final imageController = TextEditingController();

  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;
  String? hotelId;
  String? loadError;
  Map<String, String> originalValues = {};

  @override
  void initState() {
    super.initState();
    _loadHotel();
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    phoneController.dispose();
    imageController.dispose();
    super.dispose();
  }

  Future<void> _loadHotel() async {
    try {
      final profile = await ProfileService.getCurrentProfile();
      final assignedHotelId = profile?.hotelId;
      if (assignedHotelId == null || assignedHotelId.isEmpty) {
        throw StateError('لا يوجد فندق مرتبط بهذا الحساب');
      }

      final hotel = await Supabase.instance.client
          .from('hotels')
          .select('id, name, location, description, phone, image_url')
          .eq('id', assignedHotelId)
          .maybeSingle();

      if (hotel == null) {
        throw StateError('لم يتم العثور على بيانات الفندق');
      }

      hotelId = assignedHotelId;
      nameController.text = hotel['name'] as String? ?? '';
      locationController.text = hotel['location'] as String? ?? '';
      descriptionController.text = hotel['description'] as String? ?? '';
      phoneController.text = hotel['phone'] as String? ?? '';
      imageController.text = hotel['image_url'] as String? ?? '';
      originalValues = {
        'name': nameController.text,
        'location': locationController.text,
        'description': descriptionController.text,
        'phone': phoneController.text,
        'image': imageController.text,
      };
    } catch (error) {
      loadError = error is StateError
          ? error.message
          : 'تعذر تحميل معلومات الفندق';
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveHotel() async {
    final currentHotelId = hotelId;
    if (currentHotelId == null) return;

    setState(() => isSaving = true);
    try {
      await Supabase.instance.client.from('hotels').update({
        'name': nameController.text.trim(),
        'location': locationController.text.trim(),
        'description': descriptionController.text.trim(),
        'phone': phoneController.text.trim(),
        'image_url': imageController.text.trim(),
      }).eq('id', currentHotelId);

      if (!mounted) return;
      setState(() => isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ معلومات الفندق بنجاح')),
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ المعلومات: ${error.message}')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _cancelEditing() {
    nameController.text = originalValues['name'] ?? nameController.text;
    locationController.text =
        originalValues['location'] ?? locationController.text;
    descriptionController.text =
        originalValues['description'] ?? descriptionController.text;
    phoneController.text = originalValues['phone'] ?? phoneController.text;
    imageController.text = originalValues['image'] ?? imageController.text;
    setState(() => isEditing = false);
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        enabled: isEditing,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة معلومات الفندق')),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : loadError != null
                ? Center(child: Text(loadError!))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'بيانات الفندق',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF173B56),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: StayImage(
                          imageUrl: imageController.text,
                          fallbackIcon: Icons.hotel,
                          hotelName: nameController.text,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _field(label: 'اسم الفندق', controller: nameController),
                      _field(label: 'الموقع', controller: locationController),
                      _field(
                        label: 'الوصف',
                        controller: descriptionController,
                        maxLines: 4,
                      ),
                      _field(
                        label: 'رقم الهاتف',
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      _field(
                        label: 'رابط صورة الفندق',
                        controller: imageController,
                        keyboardType: TextInputType.url,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isEditing
                                  ? (isSaving ? null : _saveHotel)
                                  : () => setState(() => isEditing = true),
                              child: Text(
                                isEditing
                                    ? (isSaving ? 'جار الحفظ...' : 'حفظ')
                                    : 'تعديل',
                              ),
                            ),
                          ),
                          if (isEditing) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : _cancelEditing,
                                child: const Text('إلغاء'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}