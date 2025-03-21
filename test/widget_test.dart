// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_great_ape_escape/main.dart';
import 'package:the_great_ape_escape/host_join_screen.dart';
import 'package:nakama/nakama.dart';

void main() {
  testWidgets('HostJoinScreen smoke test', (WidgetTester tester) async {
    // Create a mock NakamaClient and Session
    final mockClient = getNakamaClient(
      host: 'localhost',
      ssl: false,
      serverKey: 'defaultkey',
      grpcPort: 7349,
      httpPort: 7350,
    );
    final mockSession = Session(
      token: 'mock-token',
      refreshToken: 'mock-refresh-token',
      userId: 'mock-user-id',
      created: true,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      vars: {},
      refreshExpiresAt: DateTime.now().add(const Duration(hours: 2)),
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: HostJoinScreen(nakamaClient: mockClient, session: mockSession),
      ),
    );

    // Verify that the screen is rendered
    expect(find.byType(HostJoinScreen), findsOneWidget);
  });
}
