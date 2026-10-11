import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_connect/main.dart';
import 'package:volunteer_connect/screens/provider/provider_dashboard_shell.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test - verifies VolunteerConnect loads WelcomeScreen with dual roles', (WidgetTester tester) async {
    await tester.pumpWidget(const VolunteerConnectApp());
    await tester.pumpAndSettle();

    // Verify WelcomeScreen renders dual options
    expect(find.text('VolunteerConnect'), findsOneWidget);
    expect(find.text('Continue as Volunteer'), findsOneWidget);
    expect(find.text('Continue as Opportunity Provider'), findsOneWidget);
  });

  testWidgets('Volunteer dashboard smoke test - verifies navigation items render', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainNavigationShell(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('VolunteerConnect'), findsOneWidget);
    expect(find.text('Discover'), findsWidgets);
    expect(find.text('For You'), findsWidgets);
    expect(find.text('Activities'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('Provider dashboard smoke test - verifies provider navigation items render', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProviderDashboardShell(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsWidgets);
    expect(find.text('My Events'), findsWidgets);
    expect(find.text('Participants'), findsWidgets);
    expect(find.text('Org Profile'), findsWidgets);
  });
}
