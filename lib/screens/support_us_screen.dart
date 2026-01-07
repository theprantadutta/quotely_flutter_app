import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
// ignore: deprecated_member_use
import 'package:share_plus/share_plus.dart';

import '../theme/colors/app_colors.dart';
import '../theme/gradients/app_gradients.dart';

class SupportUsScreen extends StatefulWidget {
  static const kRouteName = '/support-us';
  const SupportUsScreen({super.key});

  @override
  State<SupportUsScreen> createState() => _SupportUsScreenState();
}

class _SupportUsScreenState extends State<SupportUsScreen> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  final Set<String> _productIds = {'support_the_dev_1', 'buy_me_a_coffee_1'};

  List<ProductDetails> _products = [];
  bool _loading = true;
  String _statusMessage = 'Loading support options...';

  @override
  void initState() {
    super.initState();
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
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
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(_productIds);
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase failed. Please try again.')),
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _handleSuccessfulPurchase(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your generous support!')),
    );
  }

  void _buyProduct(ProductDetails productDetails) {
    HapticFeedback.mediumImpact();
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _shareApp() {
    HapticFeedback.lightImpact();
    const String appShareLink =
        'https://play.google.com/store/apps/details?id=com.pranta.quotely_flutter_app';
    const String shareMessage =
        'Check out Quotely! A beautiful app for daily quotes and inspiration:';
    // ignore: deprecated_member_use
    Share.share(
      '$shareMessage $appShareLink',
      subject: 'Check out the Quotely App!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;

    final ProductDetails? supportProduct = _products
        .cast<ProductDetails?>()
        .firstWhere((p) => p?.id == 'support_the_dev_1', orElse: () => null);
    final ProductDetails? coffeeProduct = _products
        .cast<ProductDetails?>()
        .firstWhere((p) => p?.id == 'buy_me_a_coffee_1', orElse: () => null);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.scaffoldBackground(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, colors, isDark),

              // Content
              Expanded(
                child: _loading
                    ? _buildLoadingState(colors)
                    : CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),

                                  // Hero section
                                  _buildHeroSection(colors, isDark),

                                  const SizedBox(height: 32),

                                  // Support options
                                  _buildSectionHeader('Show Your Support', colors),
                                  const SizedBox(height: 12),

                                  if (supportProduct != null)
                                    _NeumorphicSupportCard(
                                      icon: Icons.favorite_rounded,
                                      iconColor: Colors.pink.shade400,
                                      title: supportProduct.title,
                                      subtitle: supportProduct.description,
                                      price: supportProduct.price,
                                      colors: colors,
                                      isDark: isDark,
                                      onTap: () => _buyProduct(supportProduct),
                                    ),

                                  if (coffeeProduct != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: _NeumorphicSupportCard(
                                        icon: Icons.coffee_rounded,
                                        iconColor: Colors.brown.shade400,
                                        title: coffeeProduct.title,
                                        subtitle: coffeeProduct.description,
                                        price: coffeeProduct.price,
                                        colors: colors,
                                        isDark: isDark,
                                        onTap: () => _buyProduct(coffeeProduct),
                                      ),
                                    ),

                                  const SizedBox(height: 24),

                                  // Other ways
                                  _buildSectionHeader('Other Ways to Help', colors),
                                  const SizedBox(height: 12),

                                  _NeumorphicSupportCard(
                                    icon: Icons.share_rounded,
                                    iconColor: colors.primary,
                                    title: 'Share the App',
                                    subtitle: 'Help the community grow by sharing Quotely',
                                    colors: colors,
                                    isDark: isDark,
                                    onTap: _shareApp,
                                  ),

                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorScheme colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 20, 16),
      child: Row(
        children: [
          _NeumorphicBackButton(
            colors: colors,
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.warmPrimary(context),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.volunteer_activism_rounded,
                color: colors.onPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support Us',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  'Help us grow',
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(colors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            _statusMessage,
            style: GoogleFonts.lora(
              fontSize: 14,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(AppColorScheme colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.shadowDark.withValues(alpha: isDark ? 0.5 : 0.25),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          BoxShadow(
            color: colors.shadowLight.withValues(alpha: isDark ? 0.08 : 0.7),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.primaryDark],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.volunteer_activism_rounded,
              size: 36,
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Support Our Journey',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Quotely is a passion project. Your support helps us dedicate more time to new features and keep the app free for everyone.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              fontSize: 14,
              height: 1.6,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColorScheme colors) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.lora(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: colors.textMuted,
        ),
      ),
    );
  }
}

class _NeumorphicBackButton extends StatefulWidget {
  final AppColorScheme colors;
  final bool isDark;
  final VoidCallback onTap;

  const _NeumorphicBackButton({
    required this.colors,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NeumorphicBackButton> createState() => _NeumorphicBackButtonState();
}

class _NeumorphicBackButtonState extends State<_NeumorphicBackButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: widget.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.colors.shadowDark
                        .withValues(alpha: widget.isDark ? 0.5 : 0.25),
                    offset: const Offset(3, 3),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: widget.colors.shadowLight
                        .withValues(alpha: widget.isDark ? 0.08 : 0.7),
                    offset: const Offset(-3, -3),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: widget.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _NeumorphicSupportCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? price;
  final AppColorScheme colors;
  final bool isDark;
  final VoidCallback onTap;

  const _NeumorphicSupportCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.price,
    required this.colors,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NeumorphicSupportCard> createState() => _NeumorphicSupportCardState();
}

class _NeumorphicSupportCardState extends State<_NeumorphicSupportCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.colors.shadowDark
                        .withValues(alpha: widget.isDark ? 0.4 : 0.2),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: widget.colors.shadowLight
                        .withValues(alpha: widget.isDark ? 0.06 : 0.6),
                    offset: const Offset(-4, -4),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: widget.iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                color: widget.iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: widget.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: GoogleFonts.lora(
                      fontSize: 12,
                      color: widget.colors.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (widget.price != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.colors.primary, widget.colors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.price!,
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.colors.onPrimary,
                  ),
                ),
              ),
            ] else
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: widget.colors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
