/// Why the file exists:
/// Use Case for cancelling an active booking.
/// Implements [Application Flows Flow 09] and state controls in [Business Rules BR-307].
/// Uses TransactionRunner for atomic operations across booking status update and unit release.
library;

import '../../../../core/contracts/transaction_runner.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/common/enums/booking_status.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';
import '../services/booking_domain_service.dart';

class CancelBookingUseCase {
  final BookingRepository _repository;
  final BookingDomainService _bookingDomainService;
  final AuditLogger _auditService;
  final TransactionRunner _transactionRunner;

  CancelBookingUseCase(
    this._repository,
    this._bookingDomainService,
    this._auditService,
    this._transactionRunner,
  );

  Future<void> execute({
    required Booking booking,
    required int updatedByUserId,
  }) async {
    // Cannot cancel if checked out or already cancelled
    if (booking.status == BookingStatus.checkedOut) {
      throw const BusinessRuleFailure(
        code: 'CANCEL_FORBIDDEN',
        message: 'الحجز منتهي بالفعل وتم خروج النزيل، لا يمكن إلغاؤه (Cannot cancel a booking that is already checked out).',
      );
    }
    
    if (booking.status == BookingStatus.cancelled) {
      throw const BusinessRuleFailure(
        code: 'ALREADY_CANCELLED',
        message: 'الحجز ملغي بالفعل مسبقاً (This booking is already cancelled).',
      );
    }

    await _transactionRunner.run<void>(() async {
      await _repository.updateBookingStatus(
        bookingId: booking.id!,
        status: BookingStatus.cancelled.toJson(),
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
      action: 'Cancel Booking',
      description: 'إلغاء الحجز رقم ${booking.bookingNumber} بنجاح.',
    );
  }
}
