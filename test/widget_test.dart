import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:volunteer_connect/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test - verifies VolunteerConnect loads navigation and home', (WidgetTester tester) async {
    await tester.pumpWidget(const VolunteerConnectApp());
    // Allow asynchronous profile loading to finish
    await tester.pumpAndSettle();

    // Verify key UI elements render
    expect(find.text('VolunteerConnect'), findsOneWidget);
    expect(find.text('Discover'), findsWidgets);
    expect(find.text('For You'), findsWidgets);
    expect(find.text('Activities'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });
}
