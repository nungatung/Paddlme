// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wave_share/main.dart';
import 'package:wave_share/services/notification_service.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Create a mock notification service or skip it
    final notificationService = NotificationService();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(WaveShareApp(notificationService: notificationService));

    // Just verify the app builds
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
