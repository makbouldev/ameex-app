import 'package:flutter/material.dart';

/// 1. SILKY SMOOTH GLOBAL PAGE TRANSITIONS
class AmeexPageTransitionsBuilder extends PageTransitionsBuilder {
  const AmeexPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Subtle scale & fade for previous page when a new one opens on top
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0.0), // subtle right-to-left glide
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1.0, end: 0.85).animate(secondaryCurved),
          child: child,
        ),
      ),
    );
  }
}

/// Helper to push screens with a premium Ameex page animation.
/// Includes a brief brand loading overlay that fades out as the new
/// page fades in — gives a polished "loading between pages" feel.
class AmeexPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AmeexPageRoute({required this.page, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Page itself fades/slides in during the second half
            final pageCurve = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
              reverseCurve: Curves.easeInCubic,
            );
            // Loading overlay is opaque at start, fades out as page comes in
            final overlayCurve = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
            );

            return Stack(
              children: [
                FadeTransition(
                  opacity: pageCurve,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.025),
                      end: Offset.zero,
                    ).animate(pageCurve),
                    child: child,
                  ),
                ),
                IgnorePointer(
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 1.0, end: 0.0).animate(overlayCurve),
                    child: Container(
                      color: const Color(0xFFF7F8FA),
                      alignment: Alignment.center,
                      child: const _TransitionLoader(),
                    ),
                  ),
                ),
              ],
            );
          },
        );
}

/// Private 3-dot brand loader used inside the page transition overlay.
/// (Kept here to avoid a circular import with ameex_ui.dart.)
class _TransitionLoader extends StatefulWidget {
  const _TransitionLoader();

  @override
  State<_TransitionLoader> createState() => _TransitionLoaderState();
}

class _TransitionLoaderState extends State<_TransitionLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF14307A);
    return SizedBox(
      width: 60,
      height: 24,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(3, (i) {
              final phase = (_ctrl.value + i * 0.2) % 1.0;
              final t = (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: brand.withValues(alpha: 0.3 + 0.7 * t),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// 2. ANIMATED INDEXED STACK (Preserves OSM map state while animating tab switches)
class AnimatedIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 280),
  });

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != _currentIndex) {
      _controller.reset();
      setState(() {
        _currentIndex = widget.index;
      });
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.015), // smooth micro-glide upward
          end: Offset.zero,
        ).animate(_animation),
        child: IndexedStack(
          index: _currentIndex,
          children: widget.children,
        ),
      ),
    );
  }
}

/// 3. SMOOTH ENTRANCE FADE & SLIDE (For Cards, Lists, Headers)
class AmeexFadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  const AmeexFadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 320),
    this.beginOffset = const Offset(0.0, 0.04),
  });

  @override
  State<AmeexFadeSlideIn> createState() => _AmeexFadeSlideInState();
}

class _AmeexFadeSlideInState extends State<AmeexFadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero).animate(curved);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 4. TACTILE PRESSABLE BOUNCE (Native feeling on card or button click)
class AmeexPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const AmeexPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.975,
  });

  @override
  State<AmeexPressable> createState() => _AmeexPressableState();
}

class _AmeexPressableState extends State<AmeexPressable>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 5. PULSING RADAR BEACON (For Live GPS and "En Ligne" status indicator)
class AmeexPulseBadge extends StatefulWidget {
  final Color color;
  final double size;
  final Widget? child;

  const AmeexPulseBadge({
    super.key,
    this.color = const Color(0xFF10B981),
    this.size = 10,
    this.child,
  });

  @override
  State<AmeexPulseBadge> createState() => _AmeexPulseBadgeState();
}

class _AmeexPulseBadgeState extends State<AmeexPulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2.2,
      height: widget.size * 2.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, _) {
              final scale = 1.0 + (_pulseAnimation.value * 1.2);
              final opacity = (1.0 - _pulseAnimation.value).clamp(0.0, 1.0);
              return Container(
                width: widget.size * scale,
                height: widget.size * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: opacity * 0.45),
                ),
              );
            },
          ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
              ],
            ),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
