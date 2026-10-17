const bookingActiveStatuses = <String>{'pending', 'confirmed', 'checked_in'};

const bookingStatusTransitions = <String, Set<String>>{
  'pending': {'confirmed', 'cancelled'},
  'confirmed': {'checked_in', 'cancelled'},
  'checked_in': {'checked_out'},
  'checked_out': {},
  'cancelled': {},
};

Map<String, dynamic> buildPendingBookingPayload({
  required String userId,
  required String hotelId,
  required String? roomId,
  required String? apartmentId,
  required String checkIn,
  required String checkOut,
  required int guests,
  required double totalPrice,
  required String notes,
}) => {
  'user_id': userId,
  'hotel_id': hotelId,
  'room_id': roomId,
  'apartment_id': apartmentId,
  'check_in': checkIn,
  'check_out': checkOut,
  'guests': guests,
  'total_price': totalPrice,
  'status': 'pending',
  'notes': notes,
};

bool canTransitionBookingStatus(String currentStatus, String nextStatus) =>
    bookingStatusTransitions[currentStatus]?.contains(nextStatus) ?? false;

Set<String> availableBookingTransitions(String currentStatus) =>
    bookingStatusTransitions[currentStatus] ?? const {};

bool bookingPeriodsOverlap({
  required DateTime firstCheckIn,
  required DateTime firstCheckOut,
  required DateTime secondCheckIn,
  required DateTime secondCheckOut,
}) =>
    firstCheckIn.isBefore(secondCheckOut) &&
    firstCheckOut.isAfter(secondCheckIn);

bool bookingBlocksRequestedPeriod({
  required String status,
  required DateTime existingCheckIn,
  required DateTime existingCheckOut,
  required DateTime requestedCheckIn,
  required DateTime requestedCheckOut,
}) =>
    bookingActiveStatuses.contains(status) &&
    bookingPeriodsOverlap(
      firstCheckIn: requestedCheckIn,
      firstCheckOut: requestedCheckOut,
      secondCheckIn: existingCheckIn,
      secondCheckOut: existingCheckOut,
    );

String bookingDatabaseErrorMessage({
  required String? code,
  required String message,
}) {
  if (code == '23P01' || message.contains('booking_period_overlaps')) {
    return 'هذه الوحدة محجوزة بالفعل خلال الفترة المحددة.';
  }
  if (message.contains('invalid_booking_transition')) {
    return 'لا يمكن تنفيذ هذا الانتقال من حالة الحجز الحالية';
  }
  if (message.contains('booking_inventory_under_maintenance')) {
    return 'لا يمكن إتمام الحجز لأن الوحدة تحت الصيانة';
  }
  if (message.contains('booking_inventory_item_not_found') || code == '23503') {
    return 'تعذر العثور على الغرفة أو الشقة المرتبطة بالحجز';
  }
  if (message.contains('booking_identity_and_dates_are_immutable')) {
    return 'لا يمكن تغيير بيانات الحجز الأساسية بعد إنشائه';
  }
  if (message.contains('booking_not_found')) {
    return 'تعذر العثور على الحجز أو لا تملك صلاحية الوصول إليه';
  }
  if (message.contains('booking_status_changed')) {
    return 'تغيرت حالة الحجز، حدّث القائمة ثم حاول مرة أخرى';
  }
  if (code == '42501') return 'ليس لديك صلاحية لتنفيذ هذا الإجراء';
  if (code == '23514') return 'بيانات الحجز أو تواريخه غير صحيحة';
  return 'حدث خطأ في قاعدة البيانات: $message';
}

class BookingWorkflowException implements Exception {
  const BookingWorkflowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BookingVisibilityScope {
  const BookingVisibilityScope._(this.column, this.value);

  final String column;
  final String value;

  factory BookingVisibilityScope.forRole({
    required String role,
    String? userId,
    String? assignedHotelId,
  }) {
    switch (role) {
      case 'customer':
        final normalizedUserId = userId?.trim();
        if (normalizedUserId == null || normalizedUserId.isEmpty) {
          throw StateError('انتهت جلسة تسجيل الدخول');
        }
        return BookingVisibilityScope._('user_id', normalizedUserId);
      case 'manager':
      case 'receptionist':
        final normalizedHotelId = assignedHotelId?.trim();
        if (normalizedHotelId == null || normalizedHotelId.isEmpty) {
          throw StateError('لا يوجد فندق مرتبط بهذا الحساب');
        }
        return BookingVisibilityScope._('hotel_id', normalizedHotelId);
      default:
        throw StateError('ليس لديك صلاحية الوصول إلى الحجوزات');
    }
  }
}

String? bookingInventoryStatusAfterTransition({
  required String nextBookingStatus,
  required String currentInventoryStatus,
  required bool anotherCheckedInBooking,
}) {
  if (currentInventoryStatus == 'maintenance') return null;

  return switch (nextBookingStatus) {
    'pending' || 'confirmed' => null,
    'checked_in' => 'occupied',
    'checked_out' ||
    'cancelled' => anotherCheckedInBooking ? 'occupied' : 'available',
    _ => null,
  };
}
