import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/supporter_thanks.dart';
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

  /// When they first supported, for "Supporter since ...". Null if unknown.
  DateTime? _supporterSince;

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
    final since = DateTime.tryParse(prefs.getString(kSupporterSinceKey) ?? '');
    if (mounted && cached) {
      setState(() {
        _isSupporter = true;
        _supporterSince = since;
      });
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
      final owned = purchases
          .where((p) => _productIds.contains(p.productId))
          .toList();
      if (owned.isNotEmpty) await _markSupporter(_purchaseTime(owned.first));
    } catch (_) {
      // Non-fatal: the cached flag still applies.
    }
  }

  /// The store's transaction time, when it reports a plausible one.
  DateTime? _purchaseTime(Purchase purchase) {
    final ms = purchase.transactionDate.toInt();
    return ms > 0 ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  /// Records supporter status, and the date they first supported unless one
  /// is already stored ([at] when the store knows it, otherwise now).
  Future<void> _markSupporter([DateTime? at]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kIsSupporterKey, true);
    var since = DateTime.tryParse(prefs.getString(kSupporterSinceKey) ?? '');
    if (since == null) {
      since = at ?? DateTime.now();
      await prefs.setString(kSupporterSinceKey, since.toIso8601String());
    }
    if (mounted) {
      setState(() {
        _isSupporter = true;
        _supporterSince = since;
      });
    }
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

    final wasSupporter = _isSupporter;
    await _markSupporter(_purchaseTime(purchase));

    // Must be finalized or Google auto-refunds after 3 days and iOS replays the
    // transaction on every launch. isConsumable: false acknowledges without
    // consuming, which is what keeps these one-per-user.
    try {
      await _iap.finishTransaction(purchase: purchase, isConsumable: false);
    } catch (_) {
      // Already finished, or the store will replay it; the flag is set anyway.
    }

    // The store can replay a finished purchase (e.g. on launch); thank them
    // properly once, not every time it echoes.
    if (!mounted || wasSupporter) return;
    await showThankYouMoment(context);
  }

  void _onPurchaseError(PurchaseError error) {
    if (!mounted) return;

    // Backing out of the sheet is not a failure; saying nothing is correct.
    if (error.code == ErrorCode.UserCancelled) return;

    // Expected on a second attempt, since these are non-consumable. Treat it as
    // confirmation they already supported us rather than as an error.
    if (error.code == ErrorCode.AlreadyOwned) {
      final wasSupporter = _isSupporter;
      _markSupporter().then((_) {
        if (mounted && !wasSupporter) {
          showThankYouMoment(context, restored: true);
        }
      });
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
      final wasSupporter = _isSupporter;
      await _iap.restorePurchases();
      await _syncSupporterFromStore();
      if (!mounted) return;
      if (_isSupporter && !wasSupporter) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await showThankYouMoment(context, restored: true);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSupporter
                ? 'You are already a supporter. Thank you!'
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
      title: _isSupporter ? null : 'Support Quotely',
      bottom: selected == null
          ? null
          : PrimaryButton(
              label:
                  '${_cleanTitle(selected.title)} · ${selected.displayPrice}',
              onPressed: () => _buyProduct(selected),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (_isSupporter)
            SupporterLetter(since: _supporterSince)
          else ...[
            const _Invitation(),
            const SizedBox(height: 22),
            if (_loading)
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
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'One-time. No subscription. Thanked properly.',
                  style: context.qt.label.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
          const SizedBox(height: 28),
          Text(
            _isSupporter ? 'Another way to help' : 'Other ways to help',
            style: context.qt.overline,
          ),
          const SizedBox(height: 10),
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

/// The top of the page for someone who hasn't supported yet: a big serif
/// line and the maker's own note, never a sales pitch.
class _Invitation extends StatelessWidget {
  const _Invitation();

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final qt = context.qt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Entrance(
          child: Text(
            'Made by one person, free for everyone.',
            style: qt.quoteSpotlight.copyWith(color: t.ink),
          ),
        ),
        const SizedBox(height: 22),
        const Entrance(index: 1, child: _MakerMessage()),
      ],
    );
  }
}

class _MakerMessage extends StatelessWidget {
  const _MakerMessage();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Hey! I build Quotely on my own. No ads, no tracking, no '
                  'paywall, and it will stay that way. If it has given you a '
                  'good moment, you can give one back. Every supporter gets '
                  'a proper thank-you.',
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
            color: selected ? t.ink.withValues(alpha: 0.06) : null,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? t.ink : t.line,
              width: selected ? 1.4 : 1,
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
                          fontWeight: FontWeight.w600,
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
