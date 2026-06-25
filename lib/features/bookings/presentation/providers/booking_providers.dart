/// Why this file exists:
/// Riverpod state providers for Bookings, including Use Cases, domain services, and repository wiring.
/// Satisfies [Architecture Rule AR-011 (Riverpod management)].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/services/audit_service.dart';
import '../../../units/presentation/providers/unit_providers.dart';
import '../../../properties/presentation/providers/property_providers.dart';
import '../../../guests/presentation/providers/guest_providers.dart';
import '../../../../core/providers/session_providers.dart';
import '../../../guests/domain/entities/guest.dart';
import '../../../units/domain/entities/unit.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/services/booking_domain_service.dart';
import '../../domain/usecases/create_booking.dart';
import '../../domain/usecases/edit_booking.dart';
import '../../domain/usecases/cancel_booking.dart';
import '../../domain/usecases/check_in_booking.dart';
import '../../domain/usecases/check_out_booking.dart';
import '../../domain/usecases/noshow_booking.dart';
import '../../../properties/domain/entities/property.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../invoices/presentation/providers/invoice_providers.dart';
import '../../domain/entities/booking.dart';

// Repository Provider
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl(DatabaseHelper.instance);
});

// Domain Service Provider
final bookingDomainServiceProvider = Provider<BookingDomainService>((ref) {
  return BookingDomainService(
    bookingRepository: ref.watch(bookingRepositoryProvider),
    unitRepository: ref.watch(unitRepositoryProvider),
    transactionRunner: ref.watch(transactionRunnerProvider),
  );
});

// Use Case Providers
final createBookingUseCaseProvider = Provider<CreateBookingUseCase>((ref) {
  return CreateBookingUseCase(
    ref.watch(bookingRepositoryProvider),
    ref.watch(bookingDomainServiceProvider),
    ref.watch(auditServiceProvider),
    ref.watch(propertyRepositoryProvider),
    ref.watch(unitRepositoryProvider),
    ref.watch(guestRepositoryProvider),
  );
});

final editBookingUseCaseProvider = Provider<EditBookingUseCase>((ref) {
  return EditBookingUseCase(
    ref.watch(bookingRepositoryProvider),
    ref.watch(auditServiceProvider),
    ref.watch(propertyRepositoryProvider),
    ref.watch(unitRepositoryProvider),
    ref.watch(guestRepositoryProvider),
  );
});

final cancelBookingUseCaseProvider = Provider<CancelBookingUseCase>((ref) {
  return CancelBookingUseCase(
    ref.watch(bookingRepositoryProvider),
    ref.watch(bookingDomainServiceProvider),
    ref.watch(auditServiceProvider),
    ref.watch(transactionRunnerProvider),
  );
});

final checkInBookingUseCaseProvider = Provider<CheckInBookingUseCase>((ref) {
  return CheckInBookingUseCase(
    ref.watch(bookingRepositoryProvider),
    ref.watch(bookingDomainServiceProvider),
    ref.watch(auditServiceProvider),
    ref.watch(transactionRunnerProvider),
  );
});

final checkOutBookingUseCaseProvider = Provider<CheckOutBookingUseCase>((ref) {
  return CheckOutBookingUseCase(
    ref.watch(bookingRepositoryProvider),
    ref.watch(bookingDomainServiceProvider),
    ref.watch(auditServiceProvider),
    ref.watch(transactionRunnerProvider),
  );
});

final noShowBookingUseCaseProvider = Provider<NoShowBookingUseCase>((ref) {
  return NoShowBookingUseCase(
    ref.watch(bookingRepositoryProvider),
    ref.watch(bookingDomainServiceProvider),
    ref.watch(auditServiceProvider),
    ref.watch(transactionRunnerProvider),
  );
});

// Reactive Bookings List StateNotifier and Provider
class BookingsListNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  final BookingRepository _repository;
  final int? _propertyId;

  BookingsListNotifier(this._repository, this._propertyId) : super(const AsyncValue.loading()) {
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    if (_propertyId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getBookingsForProperty(_propertyId!);
      state = AsyncValue.data(list);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

final bookingsListProvider = StateNotifierProvider.family<BookingsListNotifier, AsyncValue<List<Booking>>, int?>((ref, propertyId) {
  return BookingsListNotifier(ref.watch(bookingRepositoryProvider), propertyId);
});

final bookingUnitIdsProvider = FutureProvider.family<List<int>, int>((ref, bookingId) async {
  return await ref.watch(bookingRepositoryProvider).getUnitIdsForBooking(bookingId);
});

final bookingGuestIdsProvider = FutureProvider.family<List<int>, int>((ref, bookingId) async {
  return await ref.watch(bookingRepositoryProvider).getGuestIdsForBooking(bookingId);
});

// Fetch ONLY active (unarchived) guests for selection in Booking Dialog
final activeGuestsForBookingProvider = FutureProvider<List<Guest>>((ref) async {
  final accountId = ref.watch(activeAccountIdProvider);
  if (accountId == null) return [];
  final getGuests = ref.watch(getGuestsUseCaseProvider);
  return await getGuests(accountId, includeArchived: false);
});

// Fetch ONLY active (unarchived) units for selection in Booking Dialog
final activeUnitsForBookingProvider = FutureProvider.family<List<Unit>, int>((ref, propertyId) async {
  final getUnits = ref.watch(getUnitsUseCaseProvider);
  return await getUnits(propertyId: propertyId, includeArchived: false);
});

// ──────────────────────────────────────────────
// Cross-Feature Provider Wrappers (CA-003)
// These isolate bookings presentation from direct coupling
// to other features' presentation providers.
// ──────────────────────────────────────────────

final bookingSelectedPropertyProvider = Provider<Property?>((ref) {
  return ref.watch(selectedPropertyProvider);
});

final bookingSelectPropertyActionProvider = Provider<void Function(Property?)>((ref) {
  return (prop) => ref.read(selectedPropertyProvider.notifier).state = prop;
});

final bookingPropertiesListAsyncProvider = Provider<AsyncValue<List<Property>>>((ref) {
  return ref.watch(propertiesListProvider);
});

final bookingFetchPropertiesActionProvider = Provider<void Function({bool includeArchived})>((ref) {
  return ({bool includeArchived = false}) =>
      ref.read(propertiesListProvider.notifier).fetchProperties(includeArchived: includeArchived);
});

final bookingGuestsListAsyncProvider = Provider<AsyncValue<List<Guest>>>((ref) {
  return ref.watch(guestsListProvider);
});

final bookingUnitsListAsyncProvider = Provider.family<AsyncValue<List<Unit>>, int>((ref, propertyId) {
  return ref.watch(unitsListProvider(propertyId));
});

final bookingRefreshUnitsActionProvider = Provider.family<void Function(), int>((ref, propertyId) {
  return () => ref.read(unitsListProvider(propertyId).notifier).fetchUnits();
});

final bookingInvoiceForBookingProvider = FutureProvider.family<Invoice?, int>((ref, bookingId) async {
  return await ref.read(invoiceRepositoryProvider).getInvoiceByBookingId(bookingId);
});

final bookingInvoiceByBookingIdActionProvider = Provider.family<Future<Invoice?> Function(), int>((ref, bookingId) {
  return () => ref.read(invoiceRepositoryProvider).getInvoiceByBookingId(bookingId);
});

