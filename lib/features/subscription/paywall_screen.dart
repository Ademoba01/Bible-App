import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../services/subscription_service.dart';
import '../../state/providers.dart';
import '../../theme.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  final String featureName; // "Bible Maps", "AI Verse Scanner", etc.
  const PaywallScreen({super.key, this.featureName = ''});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<Package> _packages = [];
  bool _loading = true;
  bool _purchasing = false;
  int _selectedIndex = 1; // default to yearly (best value)

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final packages = await SubscriptionService.getOfferings();
    if (mounted) {
      setState(() {
        _packages = packages;
        _loading = false;
      });
    }
  }

  Future<void> _purchase(Package package) async {
    setState(() => _purchasing = true);
    final success = await SubscriptionService.purchasePackage(package);
    if (mounted) {
      setState(() => _purchasing = false);
      if (success) {
        ref.read(isProProvider.notifier).state = true;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to Our Bible Pro!',
                style: GoogleFonts.lora()),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    final success = await SubscriptionService.restorePurchases();
    if (mounted) {
      setState(() => _purchasing = false);
      if (success) {
        ref.read(isProProvider.notifier).state = true;
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No previous purchases found.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // Pro badge
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [BrandColors.gold, Color(0xFFE6BE5A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: BrandColors.gold.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.workspace_premium,
                      size: 48, color: Colors.white),
                ),
                const SizedBox(height: 20),

                Text(
                  'Our Bible Pro',
                  style: GoogleFonts.lora(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.featureName.isNotEmpty)
                  Text(
                    'Unlock ${widget.featureName} and more',
                    style: GoogleFonts.lora(
                      fontSize: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 28),

                // Features list
                const _FeatureItem(
                    icon: Icons.sync,
                    title: 'Cloud Sync',
                    subtitle:
                        'Bookmarks, highlights & notes across all devices'),
                const _FeatureItem(
                    icon: Icons.auto_awesome,
                    title: 'AI Verse Scanner',
                    subtitle:
                        'Auto-discover related verses as you write notes'),
                const _FeatureItem(
                    icon: Icons.map,
                    title: 'Bible Maps',
                    subtitle: 'Interactive maps with journey tracing'),
                const _FeatureItem(
                    icon: Icons.quiz,
                    title: 'Unlimited Quizzes',
                    subtitle:
                        'Dynamic chapter quizzes with progress tracking'),
                const _FeatureItem(
                    icon: Icons.library_books,
                    title: 'Premium Devotionals',
                    subtitle:
                        'Open Heavens, Search the Scriptures & more'),
                const _FeatureItem(
                    icon: Icons.block,
                    title: 'Ad-Free',
                    subtitle: 'Pure, distraction-free Bible study'),

                const SizedBox(height: 28),

                // Pricing cards
                if (_loading)
                  const CircularProgressIndicator()
                else if (_packages.isEmpty)
                  // Fallback when RevenueCat isn't configured yet
                  Column(
                    children: [
                      _PricingCard(
                        title: 'Monthly',
                        price: '\$4.99/mo',
                        subtitle: 'Cancel anytime',
                        selected: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                      const SizedBox(height: 12),
                      _PricingCard(
                        title: 'Yearly',
                        price: '\$39.99/yr',
                        subtitle: 'Save 33% — best value',
                        selected: _selectedIndex == 1,
                        onTap: () => setState(() => _selectedIndex = 1),
                        badge: 'BEST VALUE',
                      ),
                    ],
                  )
                else
                  ...List.generate(_packages.length, (i) {
                    final pkg = _packages[i];
                    final isYearly = pkg.packageType == PackageType.annual;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PricingCard(
                        title: isYearly ? 'Yearly' : 'Monthly',
                        price: pkg.storeProduct.priceString,
                        subtitle: isYearly
                            ? 'Save 33% — best value'
                            : 'Cancel anytime',
                        selected: _selectedIndex == i,
                        onTap: () => setState(() => _selectedIndex = i),
                        badge: isYearly ? 'BEST VALUE' : null,
                      ),
                    );
                  }),

                const SizedBox(height: 20),

                // Purchase button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandColors.gold,
                      foregroundColor: BrandColors.dark,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _purchasing
                        ? null
                        : () {
                            if (_packages.isNotEmpty) {
                              _purchase(_packages[_selectedIndex]);
                            } else {
                              // Demo mode — just unlock
                              ref.read(isProProvider.notifier).state = true;
                              Navigator.pop(context, true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Pro unlocked (demo mode)',
                                      style: GoogleFonts.lora()),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                    child: _purchasing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('Start Free Trial',
                            style: GoogleFonts.lora(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 12),

                // Restore purchases
                TextButton(
                  onPressed: _purchasing ? null : _restore,
                  child: Text('Restore purchases',
                      style: GoogleFonts.lora(fontSize: 13)),
                ),

                const SizedBox(height: 8),
                Text(
                  'Cancel anytime. No commitment.',
                  style: GoogleFonts.lora(
                      fontSize: 12, color: theme.colorScheme.outline),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureItem(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BrandColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: BrandColors.gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.lora(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface)),
                Text(subtitle,
                    style: GoogleFonts.lora(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: BrandColors.gold, size: 20),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title, price, subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  const _PricingCard(
      {required this.title,
      required this.price,
      required this.subtitle,
      required this.selected,
      required this.onTap,
      this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? BrandColors.gold
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: selected ? 2.5 : 1.5,
          ),
          color: selected ? BrandColors.gold.withValues(alpha: 0.08) : null,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? BrandColors.gold : theme.colorScheme.outline,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: GoogleFonts.lora(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: BrandColors.gold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(badge!,
                              style: GoogleFonts.lora(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle,
                      style: GoogleFonts.lora(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Text(price,
                style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}
