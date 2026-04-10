import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat API keys — replace with real keys before production
const _revenueCatApiKeyApple = 'appl_YOUR_KEY_HERE';
const _revenueCatApiKeyGoogle = 'goog_YOUR_KEY_HERE';

/// Entitlement ID in RevenueCat dashboard
const kProEntitlement = 'pro';

/// Product IDs
const kMonthlyProductId = 'our_bible_pro_monthly'; // $4.99/mo
const kYearlyProductId = 'our_bible_pro_yearly'; // $39.99/yr

class SubscriptionService {
  static Future<void> init() async {
    // Configure based on platform
    final config = PurchasesConfiguration(_revenueCatApiKeyApple);
    await Purchases.configure(config);
  }

  static Future<bool> isProUser() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[kProEntitlement]?.isActive ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Package>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return offerings.current!.availablePackages;
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all[kProEntitlement]?.isActive ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[kProEntitlement]?.isActive ?? false;
    } catch (_) {
      return false;
    }
  }
}
