import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:quotely_flutter_app/constants/selectors.dart';
import 'package:share_plus/share_plus.dart';

import '../components/layouts/main_layout.dart';
import '../components/shared/dark_gradient_background.dart';

class SupportUsScreen extends StatefulWidget {
  static const kRouteName = '/support-us';
  const SupportUsScreen({super.key});

  @override
  State<SupportUsScreen> createState() => _SupportUsScreenState();
}

class _SupportUsScreenState extends State<SupportUsScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  // The IDs for our in-app products, matching the Play Console
  final Set<String> _productIds = {'support_the_dev_1', 'buy_me_a_coffee_1'};

  List<ProductDetails> _products = [];
  bool _loading = true;
  String _statusMessage = 'Loading support options...';

  @override
  void initState() {
    super.initState();
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    // Listen to the stream for purchase updates
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        setState(() {
          _statusMessage = 'An error occurred: $error';
          _loading = false;
        });
      },
    );

    _initializeIAP();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _initializeIAP() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _statusMessage = 'In-app purchases are not available on this device.';
        _loading = false;
      });
      return;
    }
    // Load the product details from the store
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final ProductDetailsResponse response = await _inAppPurchase
        .queryProductDetails(_productIds);
    if (response.notFoundIDs.isNotEmpty) {
      _statusMessage = 'Products not found. Check your Play Console setup.';
    }
    setState(() {
      _products = response.productDetails;
      _loading = false;
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI if needed
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Handle error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase failed. Please try again.')),
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Handle successful purchase
          _handleSuccessfulPurchase(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) {
    // Here you can save a flag to SharedPreferences that the user is a supporter
    // e.g., `prefs.setBool('is_supporter', true);`
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your generous support!')),
    );
  }

  void _buyProduct(ProductDetails productDetails) {
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );
    // This will open the Google Play purchase sheet
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _shareApp(BuildContext context) {
    const String appShareLink =
        'https://play.google.com/store/apps/details?id=com.pranta.quotely_flutter_app';
    const String shareMessage =
        'Check out Quotely! A beautiful app for daily quotes and inspiration:';
    Share.share(
      '$shareMessage $appShareLink',
      subject: 'Check out the Quotely App!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Find our specific products from the loaded list
    final ProductDetails? supportProduct = _products
        .cast<ProductDetails?>()
        .firstWhere((p) => p?.id == 'support_the_dev_1', orElse: () => null);
    final ProductDetails? coffeeProduct = _products
        .cast<ProductDetails?>()
        .firstWhere((p) => p?.id == 'buy_me_a_coffee_1', orElse: () => null);
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
          DarkGradientBackground(),
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
              : CustomScrollView(
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
                          _buildSectionHeader(context, "Show Your Support"),
                          if (supportProduct != null)
                            _buildSupportTile(
                              context: context,
                              icon: Icons.favorite_rounded,
                              iconColor: Colors.pink.shade400,
                              title: supportProduct.title,
                              subtitle:
                                  '${supportProduct.description} (${supportProduct.price})',
                              onTap: () => _buyProduct(supportProduct),
                            ),
                          if (coffeeProduct != null)
                            _buildSupportTile(
                              context: context,
                              icon: Icons.coffee_rounded,
                              iconColor: Colors.brown.shade400,
                              title: coffeeProduct.title,
                              subtitle:
                                  '${coffeeProduct.description} (${coffeeProduct.price})',
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
                        ]),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
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
