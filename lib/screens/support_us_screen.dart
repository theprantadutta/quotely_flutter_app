import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:quotely_flutter_app/constants/selectors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/layouts/main_layout.dart';
import '../components/shared/dark_gradient_background.dart';
import '../constants/responsive.dart';
import '../constants/shared_preference_keys.dart';

/// Numeric Apple App Store ID for Quotely, from App Store Connect. Used to
/// build the "Share the App" link on iOS. The URL is deliberately built without
/// a locale segment so it redirects to each recipient's own storefront.
const String kAppStoreId = '6778280010';

class SupportUsScreen extends StatefulWidget {
  static const kRouteName = '/support-us';
  const SupportUsScreen({super.key});

  @override
  State<SupportUsScreen> createState() => _SupportUsScreenState();
}

class _SupportUsScreenState extends State<SupportUsScreen> {
  final FlutterInappPurchase _iap = FlutterInappPurchase.instance;
  StreamSubscription<Purchase>? _purchaseUpdated;
  StreamSubscription<PurchaseError>? _purchaseError;

  // The IDs for our in-app products. These must match exactly the product IDs
  // configured in both App Store Connect (iOS) and the Play Console (Android).
  static const String _supportSku = 'support_the_dev_1';
  static const String _coffeeSku = 'buy_me_a_coffee_1';
  static const List<String> _productIds = [_supportSku, _coffeeSku];

  List<Product> _products = [];
  bool _loading = true;

  /// These products are non-consumable: one donation per user, ever. Once this
  /// is true the donation tiles are hidden so we stop asking.
  bool _isSupporter = false;

  String _statusMessage = 'Loading support options...';

  @override
  void initState() {
    super.initState();
    _startIap();
  }

  @override
  void dispose() {
    _purchaseUpdated?.cancel();
    _purchaseError?.cancel();
    // Releases the billing connection. Failures on teardown are not actionable.
    _iap.endConnection().catchError((_) => false);
    super.dispose();
  }

  Future<void> _startIap() async {
    // Listeners must be attached before any purchase call: requestPurchase is
    // event-based and its return value is NOT the outcome.
    _purchaseUpdated = _iap.purchaseUpdatedListener.listen(_onPurchase);
    _purchaseError = _iap.purchaseErrorListener.listen(_onPurchaseError);

    // Show the supporter state we already know about before the store answers.
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool(kIsSupporterKey) ?? false;
    if (mounted && cached) {
      setState(() => _isSupporter = true);
    }

    try {
      await _iap.initConnection();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'In-app purchases are not available on this device.';
        _loading = false;
      });
      return;
    }

    await _loadProducts();
    await _syncSupporterFromStore();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _iap.fetchProducts<Product>(
        skus: _productIds,
        type: ProductQueryType.InApp,
      );
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
        if (products.isEmpty) {
          _statusMessage = 'Products not found. Check your store setup.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Could not load support options: $e';
        _loading = false;
      });
    }
  }

  /// Non-consumables stay owned, so the store still reports them as available
  /// purchases. This is what restores supporter state after a reinstall.
  Future<void> _syncSupporterFromStore() async {
    try {
      final purchases = await _iap.getAvailablePurchases();
      final owned = purchases.any((p) => _productIds.contains(p.productId));
      if (owned) await _markSupporter();
    } catch (_) {
      // Non-fatal: the cached flag still applies.
    }
  }

  Future<void> _markSupporter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kIsSupporterKey, true);
    if (mounted) setState(() => _isSupporter = true);
  }

  Future<void> _onPurchase(Purchase purchase) async {
    // A pending purchase (slow card, parental approval) is NOT a completed one
    // and must grant nothing until it comes back as Purchased.
    if (purchase.purchaseState == PurchaseState.Pending) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your payment is still processing.')),
      );
      return;
    }
    if (purchase.purchaseState != PurchaseState.Purchased) return;

    await _markSupporter();

    // Must be finalized or Google auto-refunds after 3 days and iOS replays the
    // transaction on every launch. isConsumable: false acknowledges without
    // consuming, which is what keeps these one-per-user.
    try {
      await _iap.finishTransaction(purchase: purchase, isConsumable: false);
    } catch (_) {
      // Already finished, or the store will replay it; the flag is set anyway.
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your generous support!')),
    );
  }

  void _onPurchaseError(PurchaseError error) {
    if (!mounted) return;

    // Backing out of the sheet is not a failure; saying nothing is correct.
    if (error.code == ErrorCode.UserCancelled) return;

    // Expected on a second attempt, since these are non-consumable. Treat it as
    // confirmation they already supported us rather than as an error.
    if (error.code == ErrorCode.AlreadyOwned) {
      _markSupporter();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already supported us. Thank you!'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(getUserFriendlyErrorMessage(error))));
  }

  Future<void> _buyProduct(Product product) async {
    try {
      // Outcome arrives on the listeners above, not from this call.
      await _iap.requestPurchase(
        RequestPurchaseProps.inApp((
          apple: RequestPurchaseIosProps(sku: product.id),
          google: RequestPurchaseAndroidProps(skus: [product.id]),
        )),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start the purchase: $e')),
      );
    }
  }

  /// Apple requires a visible "Restore Purchases" action for any app selling
  /// non-consumables (App Store Review Guideline 3.1.1), so this must stay.
  Future<void> _restorePurchases() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restoring your purchases...')),
    );
    try {
      await _iap.restorePurchases();
      await _syncSupporterFromStore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSupporter
                ? 'Your support has been restored. Thank you!'
                : 'No previous support found on this account.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not restore purchases: $e')),
      );
    }
  }

  void _shareApp(BuildContext context) {
    // Point users to the correct store listing for their platform.
    final String appShareLink = Platform.isIOS
        ? 'https://apps.apple.com/app/id$kAppStoreId'
        : 'https://play.google.com/store/apps/details?id=com.pranta.quotely';
    const String shareMessage =
        'Check out Quotely! A beautiful app for daily quotes and inspiration:';
    SharePlus.instance.share(
      ShareParams(
        text: '$shareMessage $appShareLink',
        subject: 'Check out the Quotely App!',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Find our specific products from the loaded list. Hidden entirely once the
    // user has donated - these are non-consumable, so there is nothing left to
    // buy and asking again would only produce an "already owned" error.
    final Product? supportProduct = _isSupporter
        ? null
        : _products.cast<Product?>().firstWhere(
            (p) => p?.id == _supportSku,
            orElse: () => null,
          );
    final Product? coffeeProduct = _isSupporter
        ? null
        : _products.cast<Product?>().firstWhere(
            (p) => p?.id == _coffeeSku,
            orElse: () => null,
          );
    final kPrimaryColor = Theme.of(context).primaryColor;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor.withValues(
          alpha: isDarkTheme ? 0.6 : 0.9,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: MainLayoutAppBar(title: 'Support Us'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, weight: 20),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: DarkGradientBackground()),
          _loading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_statusMessage),
                    ],
                  ),
                )
              // Gradient stays full-bleed; content is capped and centered on
              // tablets like every other pushed screen.
              : ResponsiveCenter(
                  child: CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                                child: const Icon(
                                  Icons.volunteer_activism,
                                  size: 80,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Support Our Journey',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Quotely is a passion project. Your support helps us dedicate more time to new features and keep the app free for everyone.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildSectionHeader(
                              context,
                              _isSupporter
                                  ? "You Are a Supporter"
                                  : "Show Your Support",
                            ),
                            if (_isSupporter)
                              _buildSupportTile(
                                context: context,
                                icon: Icons.verified_rounded,
                                iconColor: Colors.green.shade400,
                                title: "Purchase verified",
                                subtitle:
                                    "Thank you! Your support keeps Quotely free for everyone.",
                                onTap: () {},
                              ),
                            if (supportProduct != null)
                              _buildSupportTile(
                                context: context,
                                icon: Icons.favorite_rounded,
                                iconColor: Colors.pink.shade400,
                                title: supportProduct.title,
                                subtitle:
                                    '${supportProduct.description} (${supportProduct.displayPrice})',
                                onTap: () => _buyProduct(supportProduct),
                              ),
                            if (coffeeProduct != null)
                              _buildSupportTile(
                                context: context,
                                icon: Icons.coffee_rounded,
                                iconColor: Colors.brown.shade400,
                                title: coffeeProduct.title,
                                subtitle:
                                    '${coffeeProduct.description} (${coffeeProduct.displayPrice})',
                                onTap: () => _buyProduct(coffeeProduct),
                              ),
                            const SizedBox(height: 20),
                            _buildSectionHeader(context, "Other Ways to Help"),
                            _buildSupportTile(
                              context: context,
                              icon: Icons.share_rounded,
                              iconColor: theme.colorScheme.primary,
                              title: 'Share the App',
                              subtitle: 'Help the community grow by sharing.',
                              onTap: () => _shareApp(context),
                            ),
                            // Hidden once we already know they support us -
                            // there is nothing left to restore, and the tile
                            // would just repeat what the verified tile above
                            // already says. Still shown to everyone else, which
                            // is who Apple Guideline 3.1.1 requires it for.
                            if (!_isSupporter)
                              _buildSupportTile(
                                context: context,
                                icon: Icons.restore_rounded,
                                iconColor: theme.colorScheme.secondary,
                                title: 'Restore Purchases',
                                subtitle:
                                    'Already supported us? Restore it here.',
                                onTap: _restorePurchases,
                              ),
                          ]),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSupportTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          // color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          gradient: kGetDefaultGradient(context),
        ),
        child: InkResponse(
          // Using InkResponse for splash and highlight effects
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: iconColor.withValues(alpha: 0.1),
          highlightColor: iconColor.withValues(alpha: 0.1),
          // The child of InkResponse should be the actual content
          child: Padding(
            // Moved padding inside InkResponse's child
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 30),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
