import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secure_comm_monitor/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SecureCommMonitorApp());
    await tester.pumpAndSettle();
    
    // Verify the app loads
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
