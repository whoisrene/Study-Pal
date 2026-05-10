import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:study_pal/data/prefs_study_pal_store.dart';
import 'package:study_pal/data/session_vault.dart';
import 'package:study_pal/screens/auth/auth_screen.dart';
import 'package:study_pal/services/auth_service.dart';
import 'package:study_pal/study_pal_scope.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  testWidgets('Auth gate renders after store opens', (WidgetTester tester) async {
    final store = await PrefsStudyPalStore.open(SessionVault());
    AuthService.configure(store: store);

    await tester.pumpWidget(
      StudyPalScope(
        store: store,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: AuthScreen(store: store),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Study Pal'), findsWidgets);
    expect(find.text('Sign In'), findsWidgets);
  });
}
