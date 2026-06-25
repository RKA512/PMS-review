library;

import '../../../../core/contracts/transaction_runner.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/common/enums/booking_status.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';
import '../services/booking_domain_service.dart';

class CheckOutBookingUseCase {
  final BookingRepository _repository;
  final BookingDomainService _bookingDomainService;
  final AuditLogger _auditService;
  final TransactionRunner _transactionRunner;

  CheckOutBookingUseCase(
    this._repository,
    this._bookingDomainService,
    this._auditService,
    this._transactionRunner,
  );

  Future<void> execute({
    required Booking booking,
    required int updatedByUserId,
  }) async {
    if (booking.status == BookingStatus.checkedOut) {
      throw const BusinessRuleFailure(
        code: 'ALREADY_CHECKED_OUT',
        message: 'تم تسجيل خروج النزيل مسبقاً (Guest already checked out).',
      );
    }

    if (booking.status != BookingStatus.checkedIn) {
      throw const BusinessRuleFailure(
        code: 'NOT_CHECKED_IN',
        message: 'يجب تسجيل دخول النزيل أولاً قبل تسجيل الخروج (Must check in before check out).',
      );
    }

    await _transactionRunner.run<void>(() async {
      await _repository.updateBookingStatus(
        bookingId: booking.id!,
        status: BookingStatus.checkedOut.toJson(),
        updatedByUserId: updatedByUserId,
      );

      await _bookingDomainService.releaseBookingUnits(
        bookingId: booking.id!,
        updatedByUserId: updatedByUserId,
      );
    });

    await _auditService.log(
      propertyId: booking.propertyId,
      userId: updatedByUserId,
      entityType: 'booking',
      entityId: booking.id!,
      action: 'Check Out',
      description: 'تسجيل خروج النزيل للحجز رقم ${booking.bookingNumber}.',
    );
  }
}
