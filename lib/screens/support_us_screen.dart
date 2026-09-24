import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/thread/thread.dart';
import '../constants/shared_preference_keys.dart';
import '../navigation/routes.dart';

/// Numeric Apple App Store ID for Quotely, from App Store Connect. Used to
/// build the "Share the App" link on iOS. The URL is deliberately built without
/// a locale segment so it redirects to each recipient's own storefront.
const String kAppStoreId = '6778280010';

class SupportUsScreen extends StatefulWidget {
  static const kRouteName = Routes.support;
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

  /// The tier the sticky button will buy.
  String? _selectedSku;

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

  /// Opens the store listing on its review page.
  Future<void> _rateApp() async {
    final uri = Platform.isIOS
        ? Uri.parse(
            'https://apps.apple.com/app/id$kAppStoreId?action=write-review',
          )
        : Uri.parse('market://details?id=com.pranta.quotely');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && !Platform.isIOS) {
      await launchUrl(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.pranta.quotely',
        ),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  /// Store titles on Android carry the app name ("Buy me a coffee (Quotely)").
  String _cleanTitle(String title) =>
      title.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();

  @override
  Widget build(BuildContext context) {
    // Donations are non-consumable: once supported, nothing is left to buy.
    final products = _isSupporter
        ? const <Product>[]
        : [
            for (final sku in [_coffeeSku, _supportSku])
              ?_products.cast<Product?>().firstWhere(
                (p) => p?.id == sku,
                orElse: () => null,
              ),
          ];
    final selected = products.cast<Product?>().firstWhere(
      (p) => p?.id == _selectedSku,
      orElse: () => products.isEmpty ? null : products.first,
    );

    return ThreadPage(
      title: 'Support Quotely',
      bottom: selected == null
          ? null
          : PrimaryButton(
              label:
                  '${_cleanTitle(selected.title)} · ${selected.displayPrice}',
              onPressed: () => _buyProduct(selected),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _MakerMessage(),
          const SizedBox(height: 16),
          if (_isSupporter)
            const SystemPill(
              'You’re a supporter. Thank you!',
              icon: Icons.verified_rounded,
            )
          else if (_loading)
            const ThreadSkeleton(count: 1)
          else if (products.isEmpty)
            ErrorBubble(message: _statusMessage)
          else ...[
            for (final p in products) ...[
              _TierCard(
                title: _cleanTitle(p.title),
                tagline: p.description,
                price: p.displayPrice,
                selected: p.id == selected?.id,
                onTap: () => setState(() => _selectedSku = p.id),
              ),
              const SizedBox(height: 10),
            ],
            Center(
              child: Text(
                'One-time payment. No subscription.',
                style: context.qt.label.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Rate the app',
                  icon: Icons.star_rounded,
                  filled: true,
                  onPressed: _rateApp,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SecondaryButton(
                  label: 'Tell a friend',
                  icon: kShareIcon,
                  filled: true,
                  onPressed: () => _shareApp(context),
                ),
              ),
            ],
          ),
          // Apple Guideline 3.1.1 requires a visible restore action for
          // non-consumables; pointless once we know they're a supporter.
          if (!_isSupporter) ...[
            const SizedBox(height: 8),
            Center(
              child: QTextButton(
                label: 'Restore purchases',
                onPressed: _restorePurchases,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MakerMessage extends StatelessWidget {
  const _MakerMessage();

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const QAvatar(name: 'Pranta Dutta', size: 34),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  'Pranta · maker of Quotely',
                  style: context.qt.label,
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: t.surf,
                  borderRadius: bubbleRadius(22),
                ),
                child: Text(
                  'Hey! I build Quotely on my own. No ads, no tracking. If it '
                  'made your day a bit better, a coffee keeps it going.',
                  style: context.qt.quoteBody,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  final String title;
  final String tagline;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  const _TierCard({
    required this.title,
    required this.tagline,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: '$title, $price. $tagline',
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.surf,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? t.acc : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.qt.rowTitle),
                    if (tagline.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        tagline,
                        style: context.qt.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(price, style: context.qt.rowTitle.copyWith(fontSize: 17)),
            ],
          ),
        ),
      ),
    );
  }
}
