import 'package:flutter/material.dart';

/// A widget that animates its child with a staggered fade-in and slide-up effect.
/// Use this in ListView/GridView builders for smooth list item animations.
class StaggeredFadeAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final double slideOffset;

  const StaggeredFadeAnimation({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 300),
    this.slideOffset = 20,
  });

  @override
  State<StaggeredFadeAnimation> createState() => _StaggeredFadeAnimationState();
}

class _StaggeredFadeAnimationState extends State<StaggeredFadeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Calculate delay based on index (cap at 10 to avoid long waits)
    final effectiveIndex = widget.index.clamp(0, 10);
    final totalDelay = widget.delay * effectiveIndex;

    Future.delayed(totalDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// A simpler version that only fades in without slide
class StaggeredFadeIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;

  const StaggeredFadeIn({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Calculate delay based on index (cap at 10 to avoid long waits)
    final effectiveIndex = widget.index.clamp(0, 10);
    final totalDelay = widget.delay * effectiveIndex;

    Future.delayed(totalDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
      child: widget.child,
    );
  }
}
