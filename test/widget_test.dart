import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:login_screen/main.dart';
import 'package:login_screen/database_helper.dart';
import 'package:login_screen/api_screen.dart';

// Mock Database Helper
class MockDatabaseHelper extends DatabaseHelper {
  final Map<String, String> _users = {};

  @override
  Future<bool> registerUser(String email, String password) async {
    final emailLower = email.trim().toLowerCase();
    if (_users.containsKey(emailLower)) {
      return false;
    }
    _users[emailLower] = password;
    return true;
  }

  @override
  Future<bool> verifyUser(String email, String password) async {
    final emailLower = email.trim().toLowerCase();
    return _users.containsKey(emailLower) && _users[emailLower] == password;
  }

  @override
  Future<bool> userExists(String email) async {
    return _users.containsKey(email.trim().toLowerCase());
  }
}

void main() {
  setUp(() {
    // Setup Mock Database
    DatabaseHelper.instance = MockDatabaseHelper();
  });

  testWidgets('Full Auth flow, DB verification, registration, warning popups, and API products display', (WidgetTester tester) async {
    // Use runWithClient to mock http requests cleanly inside tests
    await http.runWithClient(() async {
      // Build app
      await tester.pumpWidget(const MyApp());

      // 1. Initial State: Should show Sign-In
      expect(find.text('Sign-In'), findsNWidgets(2)); // Heading & Button
      expect(find.text('Confirm Password'), findsNothing);

      // 2. Toggle to Sign-Up
      await tester.ensureVisible(find.text('Sign-Up'));
      await tester.tap(find.text('Sign-Up'));
      await tester.pumpAndSettle();
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // 3. Register user - Valid registration
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      
      await tester.ensureVisible(find.text('Sign-Up').last);
      await tester.tap(find.text('Sign-Up').last);
      await tester.pumpAndSettle();

      // Verify Success dialog
      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Account registered successfully! You can now sign in.'), findsOneWidget);
      
      // Tap Go to Sign-In
      await tester.tap(find.text('Go to Sign-In'));
      await tester.pumpAndSettle();

      // Now we are back in Sign-In state
      expect(find.text('Create Account'), findsNothing);

      // 4. Test Verification Failure (wrong credentials)
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');
      
      await tester.ensureVisible(find.text('Sign-In').last);
      await tester.tap(find.text('Sign-In').last);
      await tester.pumpAndSettle();

      // Warning Dialog should appear
      expect(find.text('Verification Failed'), findsOneWidget);
      expect(find.textContaining('Invalid Credentials'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // 5. Test Successful Authentication and API Fetch
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      
      await tester.ensureVisible(find.text('Sign-In').last);
      await tester.tap(find.text('Sign-In').last);
      
      // Finish loading and network call transition
      await tester.pumpAndSettle();

      // 6. Should navigate to ProductListScreen
      expect(find.byType(ApiScreen), findsOneWidget);
      expect(find.text('Welcome, test@example.com'), findsOneWidget);
      expect(find.text('Mock Product A'), findsOneWidget);
      expect(find.text('Mock Product B'), findsOneWidget);

      // 7. Test Search bar filter
      await tester.enterText(find.byType(TextField).at(0), 'Product A');
      await tester.pumpAndSettle();
      expect(find.text('Mock Product A'), findsOneWidget);
      expect(find.text('Mock Product B'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(find.text('Mock Product B'), findsOneWidget);

      // 8. Test Log Out
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Should be back on the Login screen
      expect(find.byType(ApiScreen), findsNothing);
      expect(find.text('Sign-In'), findsNWidgets(2));
    }, () => MockClient((request) async {
      return http.Response(
        json.encode({
          'products': [
            {'productId': 1, 'productName': 'Mock Product A', 'available': 'Yes'},
            {'productId': 2, 'productName': 'Mock Product B', 'available': 'No'},
          ]
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }));
  });
}
