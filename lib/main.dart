import 'package:flutter/material.dart';

import 'data/session_vault.dart';
import 'data/store_factory.dart';
import 'services/auth_service.dart';
import 'splash_gate.dart';
import 'study_pal_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final vault = SessionVault();
  final store = await createStudyPalStore(vault);

  AuthService.configure(store: store);

  runApp(StudyPalScope(store: store, child: const StudyPalApp()));
}

class StudyPalApp extends StatelessWidget {
  const StudyPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StudyPalScope.of(context);

    return MaterialApp(
      title: 'Study Pal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD4A574)),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashGate(store: store),
    );
  }
}
