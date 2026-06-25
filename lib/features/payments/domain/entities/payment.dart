library;

import '../../../../core/common/enums/payment_method.dart';
import '../../../../core/common/enums/payment_type.dart';
import '../../../../core/common/models/money.dart';

class Payment {
  final int? id;
  final String uuid;
  final int propertyId;
  final int bookingId;
  final int invoiceId;
  final Money amount;
  final PaymentMethod paymentMethod;
  final PaymentType paymentType;
  final String? referenceNumber;
  final String? notes;
  final int createdBy;
  final DateTime createdAt;

  const Payment({
    this.id,
    required this.uuid,
    required this.propertyId,
    required this.bookingId,
    required this.invoiceId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentType,
    this.referenceNumber,
    this.notes,
    required this.createdBy,
    required this.createdAt,
  });

  Payment copyWith({
    int? id,
    String? uuid,
    int? propertyId,
    int? bookingId,
    int? invoiceId,
    Money? amount,
    PaymentMethod? paymentMethod,
    PaymentType? paymentType,
    String? referenceNumber,
    String? notes,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      propertyId: propertyId ?? this.propertyId,
      bookingId: bookingId ?? this.bookingId,
      invoiceId: invoiceId ?? this.invoiceId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentType: paymentType ?? this.paymentType,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
