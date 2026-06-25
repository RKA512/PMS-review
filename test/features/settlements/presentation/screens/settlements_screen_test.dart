library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:property_management_system/core/providers/session_providers.dart';
import 'package:property_management_system/features/settlements/presentation/screens/settlements_screen.dart';

void main() {
  testWidgets('SettlementsScreen shows login required when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authenticatedUserIdProvider.overrideWith((ref) => null),
          activeAccountIdProvider.overrideWith((ref) => null),
        ],
        child: const MaterialApp(home: Scaffold(body: SettlementsScreen())),
      ),
    );

    expect(find.text('الرجاء تسجيل الدخول أولاً'), findsOneWidget);
  });
}
