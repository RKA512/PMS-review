library;

import '../enums/user_role.dart';
import '../../errors/failure.dart';

enum PermissionAction {
  createBooking,
  editBooking,
  cancelBooking,
  checkInBooking,
  checkOutBooking,
  noShowBooking,
  createGuest,
  editGuest,
  archiveGuest,
  createInvoice,
  editInvoice,
  issueInvoice,
  cancelInvoice,
  recordPayment,
  voidPayment,
  createSettlement,
  completeSettlement,
  cancelSettlement,
  createExpense,
  editExpense,
  deleteExpense,
  manageProperty,
  manageUnit,
  viewReports,
}

bool canPerform(UserRole role, PermissionAction action) {
  switch (role) {
    case UserRole.owner:
      return true;

    case UserRole.manager:
      switch (action) {
        case PermissionAction.voidPayment:
        case PermissionAction.cancelSettlement:
        case PermissionAction.manageProperty:
        case PermissionAction.manageUnit:
          return false;
        default:
          return true;
      }

    case UserRole.receptionist:
      switch (action) {
        case PermissionAction.createBooking:
        case PermissionAction.editBooking:
        case PermissionAction.cancelBooking:
        case PermissionAction.checkInBooking:
        case PermissionAction.checkOutBooking:
        case PermissionAction.noShowBooking:
        case PermissionAction.createGuest:
        case PermissionAction.editGuest:
        case PermissionAction.archiveGuest:
          return true;
        default:
          return false;
      }

    case UserRole.accountant:
      switch (action) {
        case PermissionAction.createInvoice:
        case PermissionAction.editInvoice:
        case PermissionAction.issueInvoice:
        case PermissionAction.cancelInvoice:
        case PermissionAction.recordPayment:
        case PermissionAction.voidPayment:
        case PermissionAction.createSettlement:
        case PermissionAction.completeSettlement:
        case PermissionAction.cancelSettlement:
        case PermissionAction.createExpense:
        case PermissionAction.editExpense:
        case PermissionAction.deleteExpense:
        case PermissionAction.viewReports:
          return true;
        default:
          return false;
      }

    case UserRole.housekeeping:
      return false;
  }
}

Failure? checkPermission(UserRole role, PermissionAction action) {
  if (!canPerform(role, action)) {
    return const AuthorizationFailure(
      code: 'PERMISSION_DENIED',
      message: 'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
    );
  }
  return null;
}
