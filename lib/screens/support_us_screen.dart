import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/constants/selectors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportUsScreen extends StatefulWidget {
  static const kRouteName = '/support-us';
  const SupportUsScreen({super.key});

  @override
  State<SupportUsScreen> createState() => _SupportUsScreenState();
}

class _SupportUsScreenState extends State<SupportUsScreen> {
  final List<Widget> _supportTiles = [];
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>(); // Use SliverAnimatedListState
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _addSupportTiles();
      _initialized = true;
    }
  }

  void _addSupportTiles() {
    final widgets = [
      _buildSectionHeader(context, "Direct Support"),
      _buildSupportTile(
        context: context,
        icon: Icons.coffee_rounded,
        iconColor: Colors.brown.shade400,
        title: 'Support on Ko-fi',
        subtitle: 'The most reliable way to contribute.',
        onTap: () => _launchUrl('https://ko-fi.com/theprantadutta'),
      ),
      _buildSupportTile(
        context: context,
        icon: Icons.free_breakfast_rounded,
        iconColor: Colors.orange.shade400,
        title: 'Buy Me a Coffee',
        subtitle: 'Another great platform to show support.',
        onTap: () => _launchUrl('https://www.buymeacoffee.com/theprantadutta'),
      ),
      _buildSupportTile(
        context: context,
        icon: Icons.payment_rounded,
        iconColor: Colors.deepPurple.shade400,
        title: 'Donate with Stripe',
        subtitle: 'Contribute directly via Stripe.',
        onTap: () => _launchUrl('https://buy.stripe.com/your-payment-link'),
      ),
      const SizedBox(height: 20),
      _buildSectionHeader(context, "Other Ways to Help"),
      _buildSupportTile(
        context: context,
        icon: Icons.share_rounded,
        iconColor: Theme.of(context).colorScheme.primary,
        title: 'Share the App',
        subtitle: 'Help the community grow by sharing.',
        onTap: () => _shareApp(context),
      ),
    ];

    Future.delayed(Duration.zero, () {
      for (int i = 0; i < widgets.length; i++) {
        Timer(Duration(milliseconds: 100 * (i + 1)), () {
          if (mounted && _listKey.currentState != null) {
            _supportTiles.add(widgets[i]);
            _listKey.currentState!
                .insertItem(i, duration: const Duration(milliseconds: 400));
          }
        });
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the page.')),
        );
      }
    }
  }

  void _shareApp(BuildContext context) {
    const String appShareLink =
        'https://play.google.com/store/apps/details?id=com.pranta.quotely_flutter_app';
    const String shareMessage =
        'Check out Quotely! A beautiful app for daily quotes and inspiration:';
    Share.share('$shareMessage $appShareLink',
        subject: 'Check out the Quotely App!');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Us'),
        centerTitle: true,
        backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: kGetDefaultGradient(context),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: const Icon(
                        Icons.volunteer_activism,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Support Our Journey',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
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
            SliverAnimatedList(
              key: _listKey,
              initialItemCount: 0,
              itemBuilder: (context, index, animation) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 6.0),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOut)),
                    child: FadeTransition(
                      opacity: animation,
                      child: _supportTiles[index],
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            letterSpacing: 1.2,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: iconColor.withOpacity(0.1),
        highlightColor: iconColor.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
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
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }
}
