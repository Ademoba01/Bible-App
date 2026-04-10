import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/kids/kids_home_screen.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/reading/screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/subscription_service.dart';
import 'state/providers.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // RevenueCat and local notifications are not supported on web
  if (!kIsWeb) {
    try {
      await SubscriptionService.init();
    } catch (_) {}
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
      home = const WelcomeScreen();
    } else if (settings.kidsMode) {
      home = const KidsHomeScreen();
    } else {
      home = const HomeScreen();
    }

    return MaterialApp(
      title: 'Our Bible',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: home,
      ),
    );
  }
}
