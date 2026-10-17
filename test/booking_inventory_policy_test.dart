import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/services/booking_inventory_policy.dart';

void main() {
  group('booking inventory status policy', () {
    test('pending and confirmed do not occupy inventory', () {
      for (final status in ['pending', 'confirmed']) {
        expect(
          bookingInventoryStatusAfterTransition(
            nextBookingStatus: status,
            currentInventoryStatus: 'available',
            anotherCheckedInBooking: false,
          ),
          isNull,
        );
      }
    });

    test('check-in marks a room or apartment occupied', () {
      expect(
        bookingInventoryStatusAfterTransition(
          nextBookingStatus: 'checked_in',
          currentInventoryStatus: 'available',
          anotherCheckedInBooking: false,
        ),
        'occupied',
      );
    });

    test('check-out frees inventory when no other guest is checked in', () {
      expect(
        bookingInventoryStatusAfterTransition(
          nextBookingStatus: 'checked_out',
          currentInventoryStatus: 'occupied',
          anotherCheckedInBooking: false,
        ),
        'available',
      );
    });

    test('cancellation frees inventory when no other guest is checked in', () {
      expect(
        bookingInventoryStatusAfterTransition(
          nextBookingStatus: 'cancelled',
          currentInventoryStatus: 'occupied',
          anotherCheckedInBooking: false,
        ),
        'available',
      );
    });

    test('cancellation preserves occupancy for another checked-in booking', () {
      expect(
        bookingInventoryStatusAfterTransition(
          nextBookingStatus: 'cancelled',
          currentInventoryStatus: 'occupied',
          anotherCheckedInBooking: true,
        ),
        'occupied',
      );
    });

    test('booking updates never release inventory under maintenance', () {
      for (final status in ['checked_in', 'checked_out', 'cancelled']) {
        expect(
          bookingInventoryStatusAfterTransition(
            nextBookingStatus: status,
            currentInventoryStatus: 'maintenance',
            anotherCheckedInBooking: false,
          ),
          isNull,
        );
      }
    });

    test(
      'pending to confirmed to check-in to check-out follows the lifecycle',
      () {
        var inventoryStatus = 'available';
        for (final bookingStatus in ['pending', 'confirmed']) {
          inventoryStatus =
              bookingInventoryStatusAfterTransition(
                nextBookingStatus: bookingStatus,
                currentInventoryStatus: inventoryStatus,
                anotherCheckedInBooking: false,
              ) ??
              inventoryStatus;
        }
        expect(inventoryStatus, 'available');

        inventoryStatus = bookingInventoryStatusAfterTransition(
          nextBookingStatus: 'checked_in',
          currentInventoryStatus: inventoryStatus,
          anotherCheckedInBooking: false,
        )!;
        expect(inventoryStatus, 'occupied');

        inventoryStatus = bookingInventoryStatusAfterTransition(
          nextBookingStatus: 'checked_out',
          currentInventoryStatus: inventoryStatus,
          anotherCheckedInBooking: false,
        )!;
        expect(inventoryStatus, 'available');
      },
    );
  });

  group('booking lifecycle rules', () {
    test(
      'new booking payload starts pending for exactly one inventory item',
      () {
        final roomBooking = buildPendingBookingPayload(
          userId: 'customer-1',
          hotelId: 'hotel-1',
          roomId: 'room-1',
          apartmentId: null,
          checkIn: '2026-10-12',
          checkOut: '2026-10-14',
          guests: 2,
          totalPrice: 1200,
          notes: '',
        );
        expect(roomBooking['status'], 'pending');
        expect(roomBooking['room_id'], 'room-1');
        expect(roomBooking['apartment_id'], isNull);
        expect(roomBooking['user_id'], 'customer-1');
        expect(roomBooking['hotel_id'], 'hotel-1');

        final apartmentBooking = buildPendingBookingPayload(
          userId: 'customer-1',
          hotelId: 'hotel-1',
          roomId: null,
          apartmentId: 'apartment-1',
          checkIn: '2026-10-12',
          checkOut: '2026-10-14',
          guests: 3,
          totalPrice: 2400,
          notes: 'late arrival',
        );
        expect(apartmentBooking['status'], 'pending');
        expect(apartmentBooking['room_id'], isNull);
        expect(apartmentBooking['apartment_id'], 'apartment-1');
      },
    );

    test('allows the normal lifecycle and cancellation paths', () {
      expect(canTransitionBookingStatus('pending', 'confirmed'), isTrue);
      expect(canTransitionBookingStatus('confirmed', 'checked_in'), isTrue);
      expect(canTransitionBookingStatus('checked_in', 'checked_out'), isTrue);
      expect(canTransitionBookingStatus('pending', 'cancelled'), isTrue);
      expect(canTransitionBookingStatus('confirmed', 'cancelled'), isTrue);
    });

    test('rejects check-in from pending or terminal states', () {
      expect(canTransitionBookingStatus('pending', 'checked_in'), isFalse);
      expect(canTransitionBookingStatus('checked_out', 'checked_in'), isFalse);
      expect(canTransitionBookingStatus('cancelled', 'checked_in'), isFalse);
    });

    test('rejects cancellation after check-in or check-out', () {
      expect(canTransitionBookingStatus('checked_in', 'cancelled'), isFalse);
      expect(canTransitionBookingStatus('checked_out', 'cancelled'), isFalse);
    });

    test('allows cancellation before check-in only', () {
      expect(canTransitionBookingStatus('pending', 'cancelled'), isTrue);
      expect(canTransitionBookingStatus('confirmed', 'cancelled'), isTrue);
    });

    test('treats checkout and check-in boundaries as non-overlapping', () {
      final dayOne = DateTime(2026, 10, 12);
      final dayTwo = DateTime(2026, 10, 13);
      final dayThree = DateTime(2026, 10, 14);
      expect(
        bookingPeriodsOverlap(
          firstCheckIn: dayOne,
          firstCheckOut: dayTwo,
          secondCheckIn: dayTwo,
          secondCheckOut: dayThree,
        ),
        isFalse,
      );
      expect(
        bookingPeriodsOverlap(
          firstCheckIn: dayOne,
          firstCheckOut: dayThree,
          secondCheckIn: dayTwo,
          secondCheckOut: dayThree,
        ),
        isTrue,
      );
    });

    test('pending confirmed and checked-in bookings block overlaps only', () {
      expect(bookingActiveStatuses, {'pending', 'confirmed', 'checked_in'});
      expect(bookingActiveStatuses.contains('checked_out'), isFalse);
      expect(bookingActiveStatuses.contains('cancelled'), isFalse);
    });

    test(
      'requested date boundaries and booking statuses follow availability rules',
      () {
        final existingCheckIn = DateTime(2026, 10, 13);
        final existingCheckOut = DateTime(2026, 10, 21);
        bool blocks({
          required String status,
          required DateTime checkIn,
          required DateTime checkOut,
        }) => bookingBlocksRequestedPeriod(
          status: status,
          existingCheckIn: existingCheckIn,
          existingCheckOut: existingCheckOut,
          requestedCheckIn: checkIn,
          requestedCheckOut: checkOut,
        );

        expect(
          blocks(
            status: 'confirmed',
            checkIn: existingCheckIn,
            checkOut: existingCheckOut,
          ),
          isTrue,
        );
        expect(
          blocks(
            status: 'pending',
            checkIn: DateTime(2026, 10, 15),
            checkOut: DateTime(2026, 10, 18),
          ),
          isTrue,
        );
        expect(
          blocks(
            status: 'checked_in',
            checkIn: DateTime(2026, 10, 21),
            checkOut: DateTime(2026, 10, 25),
          ),
          isFalse,
        );
        expect(
          blocks(
            status: 'confirmed',
            checkIn: DateTime(2026, 10, 21),
            checkOut: DateTime(2026, 10, 25),
          ),
          isFalse,
        );
        expect(
          blocks(
            status: 'confirmed',
            checkIn: DateTime(2026, 10, 10),
            checkOut: DateTime(2026, 10, 13),
          ),
          isFalse,
        );
        expect(
          blocks(
            status: 'checked_out',
            checkIn: DateTime(2026, 10, 15),
            checkOut: DateTime(2026, 10, 18),
          ),
          isFalse,
        );
        expect(
          blocks(
            status: 'cancelled',
            checkIn: DateTime(2026, 10, 15),
            checkOut: DateTime(2026, 10, 18),
          ),
          isFalse,
        );
      },
    );

    test('maps overlap and permission failures to Arabic messages', () {
      expect(
        bookingDatabaseErrorMessage(
          code: '23P01',
          message: 'booking_period_overlaps_existing_booking',
        ),
        'هذه الوحدة محجوزة بالفعل خلال الفترة المحددة.',
      );
      expect(
        bookingDatabaseErrorMessage(code: '42501', message: 'denied'),
        contains('صلاحية'),
      );
    });

    test('maps booking transition RPC errors to clear Arabic messages', () {
      expect(
        bookingDatabaseErrorMessage(
          code: 'P0001',
          message: 'booking_not_found',
        ),
        'تعذر العثور على الحجز أو لا تملك صلاحية الوصول إليه',
      );
      expect(
        bookingDatabaseErrorMessage(
          code: 'P0001',
          message: 'booking_status_changed',
        ),
        'تغيرت حالة الحجز، حدّث القائمة ثم حاول مرة أخرى',
      );
    });
  });

  group('booking visibility scopes', () {
    test('customer scope is limited to the authenticated user', () {
      final scope = BookingVisibilityScope.forRole(
        role: 'customer',
        userId: 'customer-1',
        assignedHotelId: 'hotel-1',
      );
      expect(scope.column, 'user_id');
      expect(scope.value, 'customer-1');
    });

    test('manager and receptionist scopes use the assigned hotel', () {
      for (final role in ['manager', 'receptionist']) {
        final scope = BookingVisibilityScope.forRole(
          role: role,
          userId: 'staff-1',
          assignedHotelId: 'assigned-hotel',
        );
        expect(scope.column, 'hotel_id');
        expect(scope.value, 'assigned-hotel');
      }
    });

    test('missing assignments and unrecognized roles are rejected', () {
      expect(
        () => BookingVisibilityScope.forRole(role: 'manager'),
        throwsStateError,
      );
      expect(
        () => BookingVisibilityScope.forRole(role: 'customer', userId: '  '),
        throwsStateError,
      );
      expect(
        () => BookingVisibilityScope.forRole(role: 'unknown'),
        throwsStateError,
      );
    });
  });
}
