import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'features/kids/kids_home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/reading/screens/home_screen.dart';
import 'services/notification_service.dart';
import 'state/providers.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase. Web has explicit options. iOS/macOS expect a
  // GoogleService-Info.plist in the Runner bundle which we ship — but if
  // it's missing (fresh checkouts before adding the file), fall back to
  // explicit options so the app still boots. Android uses google-services
  // .json which the Gradle plugin reads automatically when present.
  try {
    await Firebase.initializeApp(
      options: kIsWeb
          ? const FirebaseOptions(
              apiKey: 'AIzaSyCnKmWA-OOhlbHDwpXXdZrIsrJvMWljMDU',
              appId: '1:351142574491:web:d680e02d89756051d6493e',
              messagingSenderId: '351142574491',
              projectId: 'rhema-study-bible',
              authDomain: 'rhema-study-bible.firebaseapp.com',
              storageBucket: 'rhema-study-bible.firebasestorage.app',
            )
          : (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS)
              ? const FirebaseOptions(
                  apiKey: 'AIzaSyCnKmWA-OOhlbHDwpXXdZrIsrJvMWljMDU',
                  appId: '1:351142574491:ios:d680e02d89756051d6493e',
                  messagingSenderId: '351142574491',
                  projectId: 'rhema-study-bible',
                  storageBucket:
                      'rhema-study-bible.firebasestorage.app',
                  iosBundleId: 'com.ademoba.bible_app',
                )
              : null, // Android: Gradle plugin reads google-services.json
    );
  } catch (e) {
    // Non-fatal. Firebase-dependent features (auth, prayer-feed cloud
    // sync) will gracefully degrade; everything else (reading, listen,
    // codex, cross-references, AI, maps, kids) is local-first and works
    // without Firebase.
    debugPrint('Firebase init error (continuing without): $e');
  }

  // Local notifications are not supported on web
  if (!kIsWeb) {
    try {
      await NotificationService.init();
    } catch (_) {}
  }

  runApp(const ProviderScope(child: BibleApp()));
}

class BibleApp extends ConsumerWidget {
  const BibleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final brightness = settings.darkMode ? Brightness.dark : Brightness.light;
    final theme = settings.kidsMode
        ? buildKidsTheme(brightness: brightness)
        : buildAdultTheme(brightness: brightness);

    final Widget home;
    if (!settings.onboarded) {
      home = const OnboardingScreen();
    } else if (settings.kidsMode) {
      home = const KidsHomeScreen();
    } else {
      home = const HomeScreen();
    }

    return MaterialApp(
      title: 'Rhema Study Bible',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: home,
      ),
    );
  }
}
