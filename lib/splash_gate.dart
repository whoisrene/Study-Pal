import 'package:flutter/material.dart';

import 'data/models.dart';
import 'data/study_pal_store.dart';
import 'data/study_pal_store_topics.dart';
import 'screens/auth/auth_screen.dart';
import 'widgets/main_layout.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.store});

  final StudyPalStore store;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  late final Future<UserProfile?> _bootstrap;

  @override
  void initState() {
    super.initState();
    _bootstrap = _restoreSession(widget.store);
  }

  Future<UserProfile?> _restoreSession(StudyPalStore store) async {
    final cached = await store.bootstrapSession();
    if (cached == null) return null;

    await store.applyLegacySharedPreferences(cached);
    return store.ensureTopicDefaults(cached);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF5E6D3),
                    Color(0xFFE8D4C4),
                  ],
                ),
              ),
              child: Center(
                child: SizedBox.square(
                  dimension: 36,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFFD4A574)),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Could not restore your session: ${snapshot.error}'),
              ),
            ),
          );
        }

        final profile = snapshot.data;
        final store = widget.store;

        if (profile != null) {
          return MainLayout(store: store, profile: profile);
        }

        return AuthScreen(store: store);
      },
    );
  }
}
