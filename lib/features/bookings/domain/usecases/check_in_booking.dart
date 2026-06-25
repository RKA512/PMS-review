library;

import '../../../../core/contracts/transaction_runner.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/common/enums/booking_status.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';
import '../services/booking_domain_service.dart';

class CheckInBookingUseCase {
  final BookingRepository _repository;
  final BookingDomainService _bookingDomainService;
  final AuditLogger _auditService;
  final TransactionRunner _transactionRunner;

  CheckInBookingUseCase(
    this._repository,
    this._bookingDomainService,
    this._auditService,
    this._transactionRunner,
  );

  Future<void> execute({
    required Booking booking,
    required int updatedByUserId,
  }) async {
    if (booking.status == BookingStatus.checkedIn) {
      throw const BusinessRuleFailure(
        code: 'ALREADY_CHECKED_IN',
        message: 'تم تسجيل دخول النزيل مسبقاً (Guest already checked in).',
      );
    }

    if (booking.status == BookingStatus.cancelled) {
      throw const BusinessRuleFailure(
        code: 'CANCELLED_BOOKING',
        message: 'لا يمكن تسجيل دخول حجز ملغي (Cannot check in a cancelled booking).',
      );
    }

    if (booking.status == BookingStatus.checkedOut) {
      throw const BusinessRuleFailure(
        code: 'ALREADY_CHECKED_OUT',
        message: 'الحجز منتهي بالفعل وتم خروج النزيل (Booking already checked out).',
      );
    }

    if (booking.status == BookingStatus.noShow) {
      throw const BusinessRuleFailure(
        code: 'NO_SHOW_BOOKING',
        message: 'لا يمكن تسجيل دخول حجز تم تسجيل عدم حضوره (Cannot check in a no-show booking).',
      );
    }

    await _transactionRunner.run<void>(() async {
      await _repository.updateBookingStatus(
        bookingId: booking.id!,
        status: BookingStatus.checkedIn.toJson(),
        updatedByUserId: updatedByUserId,
      );

      await _bookingDomainService.occupyBookingUnits(
        bookingId: booking.id!,
        updatedByUserId: updatedByUserId,
      );
    });

    await _auditService.log(
      propertyId: booking.propertyId,
      userId: updatedByUserId,
      entityType: 'booking',
      entityId: booking.id!,
      action: 'Check In',
      description: 'تسجيل دخول النزيل للحجز رقم ${booking.bookingNumber}.',
    );
  }
}
