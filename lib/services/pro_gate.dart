import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/subscription/paywall_screen.dart';
import '../state/providers.dart';

/// Checks if the user is pro. If not, shows the paywall.
/// Returns true if the user is pro (or just purchased).
Future<bool> requirePro(BuildContext context, WidgetRef ref,
    {String feature = ''}) async {
  final isPro = ref.read(isProProvider);
  if (isPro) return true;

  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => PaywallScreen(featureName: feature)),
  );
  return result ?? false;
}
