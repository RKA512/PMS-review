library;

import '../../../../core/contracts/transaction_runner.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/common/enums/booking_status.dart';
import '../../../../core/contracts/audit_logger.dart';
import '../entities/booking.dart';
import '../repositories/booking_repository.dart';
import '../services/booking_domain_service.dart';

class NoShowBookingUseCase {
  final BookingRepository _repository;
  final BookingDomainService _bookingDomainService;
  final AuditLogger _auditService;
  final TransactionRunner _transactionRunner;

  NoShowBookingUseCase(
    this._repository,
    this._bookingDomainService,
    this._auditService,
    this._transactionRunner,
  );

  Future<void> execute({
    required Booking booking,
    required int updatedByUserId,
  }) async {
    if (booking.status == BookingStatus.noShow) {
      throw const BusinessRuleFailure(
        code: 'ALREADY_NO_SHOW',
        message: 'تم تسجيل عدم حضور النزيل مسبقاً (Guest already marked as no show).',
      );
    }

    if (booking.status == BookingStatus.checkedOut) {
      throw const BusinessRuleFailure(
        code: 'ALREADY_CHECKED_OUT',
        message: 'لا يمكن تسجيل عدم حضور لحجز منتهي (Cannot mark as no show for a checked out booking).',
      );
    }

    await _transactionRunner.run<void>(() async {
      await _repository.updateBookingStatus(
        bookingId: booking.id!,
        status: BookingStatus.noShow.toJson(),
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
      action: 'No Show',
      description: 'تسجيل عدم حضور النزيل للحجز رقم ${booking.bookingNumber}.',
    );
  }
}
