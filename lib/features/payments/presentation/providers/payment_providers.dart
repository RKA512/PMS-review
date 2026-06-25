library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/services/audit_service.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../data/datasources/payment_local_datasource_impl.dart';
import '../../domain/usecases/record_payment.dart';
import '../../domain/usecases/get_payments_for_invoice.dart';
import '../../domain/usecases/void_payment.dart';

final paymentLocalDataSourceProvider = Provider((ref) {
  return PaymentLocalDataSourceImpl(DatabaseHelper.instance);
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.watch(paymentLocalDataSourceProvider));
});

final recordPaymentUseCaseProvider = Provider<RecordPayment>((ref) {
  return RecordPayment(ref.watch(paymentRepositoryProvider), ref.watch(auditServiceProvider));
});

final getPaymentsForInvoiceUseCaseProvider = Provider<GetPaymentsForInvoice>((ref) {
  return GetPaymentsForInvoice(ref.watch(paymentRepositoryProvider));
});

final voidPaymentUseCaseProvider = Provider<VoidPayment>((ref) {
  return VoidPayment(ref.watch(paymentRepositoryProvider), ref.watch(auditServiceProvider));
});
