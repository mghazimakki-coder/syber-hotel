import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/manager_data_service.dart';

class RoomsApartmentsManagementScreen extends StatefulWidget {
  const RoomsApartmentsManagementScreen({super.key});

  @override
  State<RoomsApartmentsManagementScreen> createState() =>
      _RoomsApartmentsManagementScreenState();
}

class _RoomsApartmentsManagementScreenState
    extends State<RoomsApartmentsManagementScreen> {
  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> rooms = [];
  List<Map<String, dynamic>> apartments = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final results = await Future.wait([
        ManagerDataService.list('rooms'),
        ManagerDataService.list('apartments'),
      ]);
      if (!mounted) return;
      setState(() {
        rooms = results[0];
        apartments = results[1];
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        error = 'تعذر تحميل الغرف والشقق';
        isLoading = false;
      });
    }
  }

  Future<void> _showEditor({String? table, Map<String, dynamic>? item}) async {
    final selectedTable = table ?? 'rooms';
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _RoomEditorDialog(
        table: selectedTable,
        item: item,
        onSave: (table, values) async {
          if (item == null) {
            await ManagerDataService.insert(table, values);
          } else {
            await ManagerDataService.update(
              table,
              item['id'].toString(),
              values,
            );
          }
        },
        errorMessage: _errorMessage,
      ),
    );
    if (result == true && mounted) {
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(item == null ? 'تمت الإضافة بنجاح' : 'تم التحديث بنجاح')),
        );
      }
    }
  }

  String _errorMessage(Object error) {
    if (error is PostgrestException) return error.message;
    if (error is StateError) return error.message;
    return 'تعذر حفظ البيانات. حاول مرة أخرى';
  }

  void _viewItem(String table, Map<String, dynamic> item) {
    final title = table == 'rooms'
        ? item['room_number']?.toString() ?? 'بدون رقم'
        : item['name']?.toString() ?? 'بدون اسم';
    final status = item['status']?.toString() ?? 'غير محدد';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title),
          content: Text(
            'الوصف: ${item['description'] ?? ''}\n'
            'السعر: ${item['price'] ?? 0} جنيه سوداني\n'
            'الحالة: $status',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(String table, Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل تريد حذف هذا العنصر نهائياً؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await ManagerDataService.delete(table, item['id'].toString());
      if (mounted) {
        await _loadItems();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الحذف بنجاح')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage(error))),
        );
      }
    }
  }

  Widget _itemTile(String table, Map<String, dynamic> item) {
    final name = table == 'rooms'
        ? item['room_number']?.toString() ?? 'بدون رقم'
        : item['name']?.toString() ?? 'بدون اسم';
    final status = item['status']?.toString() ?? 'unknown';
    final statusLabel = switch (status) {
      'available' => 'متاحة',
      'occupied' => 'مشغولة',
      'maintenance' => 'صيانة',
      _ => 'غير محددة',
    };
    final statusColor = switch (status) {
      'available' => const Color(0xFF287A56),
      'occupied' => const Color(0xFFB4771D),
      'maintenance' => const Color(0xFFB53B3B),
      _ => const Color(0xFF7A8490),
    };
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => _viewItem(table, item),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF245A7A).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      table == 'rooms' ? Icons.hotel : Icons.apartment,
                      color: const Color(0xFF245A7A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          table == 'rooms' ? 'غرفة $name' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          table == 'rooms'
                              ? (item['room_type']?.toString() ?? 'غرفة فندقية')
                              : '${item['description'] ?? 'شقة فندقية'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7A8490),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showEditor(table: table, item: item),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'تعديل',
                  ),
                  IconButton(
                    onPressed: () => _delete(table, item),
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFB53B3B)),
                    tooltip: 'حذف',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${item['price'] ?? 0} جنيه سوداني',
                    style: const TextStyle(
                      color: Color(0xFF173B56),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة الغرف والشقق'),
          actions: [
            IconButton(onPressed: _loadItems, icon: const Icon(Icons.refresh)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showEditor(),
          icon: const Icon(Icons.add),
          label: const Text('إضافة'),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text(error!))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text('الغرف', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...rooms.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _itemTile('rooms', item),
                          )),
                      const SizedBox(height: 12),
                      const Text('الشقق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...apartments.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _itemTile('apartments', item),
                          )),
                    ],
                  ),
      ),
    );
  }
}

class _RoomEditorDialog extends StatefulWidget {
  const _RoomEditorDialog({
    required this.table,
    required this.item,
    required this.onSave,
    required this.errorMessage,
  });

  final String table;
  final Map<String, dynamic>? item;
  final Future<void> Function(String table, Map<String, dynamic> values) onSave;
  final String Function(Object error) errorMessage;

  @override
  State<_RoomEditorDialog> createState() => _RoomEditorDialogState();
}

class _RoomEditorDialogState extends State<_RoomEditorDialog> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController roomTypeController;
  late final TextEditingController priceController;
  late final TextEditingController imageUrlController;
  late String selectedType;
  late String selectedStatus;
  String? validationError;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item ?? <String, dynamic>{};
    selectedType = widget.table;
    selectedStatus = item['status']?.toString() ?? 'available';
    nameController = TextEditingController(
      text: selectedType == 'rooms'
          ? item['room_number']?.toString() ?? ''
          : item['name']?.toString() ?? '',
    );
    descriptionController = TextEditingController(
      text: item['description']?.toString() ?? '',
    );
    roomTypeController = TextEditingController(
      text: item['room_type']?.toString() ?? '',
    );
    priceController = TextEditingController(
      text: item['price']?.toString() ?? '',
    );
    imageUrlController = TextEditingController(
      text: item['image_url']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    roomTypeController.dispose();
    priceController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final price = double.tryParse(priceController.text.trim());
    if (name.isEmpty) {
      setState(() => validationError = 'يرجى إدخال الاسم أو رقم الغرفة');
      return;
    }
    if (description.isEmpty) {
      setState(() => validationError = 'يرجى إدخال الوصف');
      return;
    }
    if (price == null || price < 0) {
      setState(() => validationError = 'يرجى إدخال سعر صحيح');
      return;
    }
    if (selectedType == 'rooms' && roomTypeController.text.trim().isEmpty) {
      setState(() => validationError = 'يرجى إدخال نوع الغرفة');
      return;
    }

    setState(() {
      isSaving = true;
      validationError = null;
    });
    final values = selectedType == 'rooms'
        ? {
            'room_number': name,
            'room_type': roomTypeController.text.trim(),
            'description': description,
            'price': price,
            'image_url': imageUrlController.text.trim(),
            'status': selectedStatus,
          }
        : {
            'name': name,
            'description': description,
            'price': price,
            'image_url': imageUrlController.text.trim(),
            'status': selectedStatus,
          };
    try {
      await widget.onSave(selectedType, values);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
        validationError = widget.errorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statuses = <String>{'available', 'occupied', 'maintenance'};
    statuses.add(selectedStatus);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.item == null ? 'إضافة عنصر' : 'تعديل العنصر'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.item == null)
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'rooms', child: Text('غرفة')),
                    DropdownMenuItem(value: 'apartments', child: Text('شقة')),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => selectedType = value);
                          }
                        },
                  decoration: const InputDecoration(labelText: 'النوع'),
                ),
              TextField(
                controller: nameController,
                enabled: !isSaving,
                decoration: InputDecoration(
                  labelText: selectedType == 'rooms' ? 'رقم الغرفة' : 'اسم الشقة',
                ),
              ),
              if (selectedType == 'rooms')
                TextField(
                  controller: roomTypeController,
                  enabled: !isSaving,
                  decoration: const InputDecoration(labelText: 'نوع الغرفة'),
                ),
              TextField(
                controller: descriptionController,
                enabled: !isSaving,
                decoration: const InputDecoration(labelText: 'الوصف'),
              ),
              TextField(
                controller: priceController,
                enabled: !isSaving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'السعر'),
              ),
              TextField(
                controller: imageUrlController,
                enabled: !isSaving,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'رابط الصورة'),
              ),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                items: statuses
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(switch (status) {
                          'available' => 'متاحة',
                          'occupied' => 'مشغولة',
                          'maintenance' => 'صيانة',
                          _ => status,
                        }),
                      ),
                    )
                    .toList(),
                onChanged: isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => selectedStatus = value);
                        }
                      },
                decoration: const InputDecoration(labelText: 'الحالة'),
              ),
              if (validationError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    validationError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSaving ? null : () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: isSaving ? null : _save,
            child: Text(isSaving ? 'جار الحفظ...' : 'حفظ'),
          ),
        ],
      ),
    );
  }
}
