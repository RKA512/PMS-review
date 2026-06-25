library;

import '../../../../core/common/enums/payment_method.dart';
import '../../../../core/common/enums/payment_type.dart';
import '../../../../core/common/models/money.dart';
import '../../domain/entities/payment.dart';

class PaymentModel {
  static Map<String, dynamic> toMap(Payment payment) {
    return {
      if (payment.id != null) 'id': payment.id,
      'uuid': payment.uuid,
      'property_id': payment.propertyId,
      'booking_id': payment.bookingId,
      'invoice_id': payment.invoiceId,
      'amount': payment.amount.minorUnits,
      'payment_method': payment.paymentMethod.toJson(),
      'payment_type': payment.paymentType.toJson(),
      'reference_number': payment.referenceNumber,
      'notes': payment.notes,
      'created_by': payment.createdBy,
      'created_at': payment.createdAt.toIso8601String(),
    };
  }

  static Payment fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      propertyId: map['property_id'] as int,
      bookingId: map['booking_id'] as int,
      invoiceId: map['invoice_id'] as int,
      amount: Money(map['amount'] as int),
      paymentMethod: PaymentMethod.fromJson(map['payment_method'] as String),
      paymentType: PaymentType.fromJson(map['payment_type'] as String),
      referenceNumber: map['reference_number'] as String?,
      notes: map['notes'] as String?,
      createdBy: map['created_by'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
