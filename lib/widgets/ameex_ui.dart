import 'package:flutter/material.dart';
import '../theme/ameex_theme.dart';

/// Branded full-screen splash — elegant pulsing brand-blue core
/// surrounded by expanding rings. Used during auth/profile loading
/// and other blocking transitions.
class AmeexSplash extends StatefulWidget {
  final String? message;
  const AmeexSplash({super.key, this.message});

  @override
  State<AmeexSplash> createState() => _AmeexSplashState();
}

class _AmeexSplashState extends State<AmeexSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmeexColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing brand mark — rings + core
            SizedBox(
              width: 120, height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Two expanding rings offset in phase
                  for (int i = 0; i < 2; i++)
                    AnimatedBuilder(
                      animation: _ctrl,
                      builder: (context, _) {
                        final phase = (_ctrl.value + i * 0.5) % 1.0;
                        final size = 44 + (72 * phase);
                        final opacity = (1 - phase).clamp(0.0, 1.0) * 0.45;
                        return Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AmeexColors.primaryBlue
                                  .withValues(alpha: opacity),
                              width: 1.4,
                            ),
                          ),
                        );
                      },
                    ),
                  // Inner core with subtle breathing scale
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, child) {
                      final s = 0.92 + 0.08 *
                          ((_ctrl.value * 2 * 3.14159).remainder(6.28318) < 3.14159
                              ? 1 - (_ctrl.value - 0.25).abs() * 2
                              : (_ctrl.value - 0.75).abs() * 2);
                      return Transform.scale(scale: s.clamp(0.9, 1.0), child: child);
                    },
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1E3A8A),
                            AmeexColors.primaryBlue,
                            AmeexColors.darkNavy,
                          ],
                        ),
                        boxShadow: AmeexDesign.shadowHero,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              widget.message ?? 'Chargement…',
              style: const TextStyle(
                fontFamily: AmeexTheme.fontFamily,
                color: AmeexColors.textMuted,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline, compact brand spinner (dots that fade in sequence).
class AmeexLoading extends StatefulWidget {
  final double size;
  final Color? color;

  const AmeexLoading({super.key, this.size = 44, this.color});

  @override
  State<AmeexLoading> createState() => _AmeexLoadingState();
}

class _AmeexLoadingState extends State<AmeexLoading>
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
    final c = widget.color ?? AmeexColors.primaryBlue;
    final dotSize = widget.size * 0.16;
    final spacing = widget.size * 0.10;

    return SizedBox(
      width: widget.size,
      height: widget.size * 0.4,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(3, (i) {
              final phase = (_ctrl.value + i * 0.2) % 1.0;
              final t = (phase < 0.5
                      ? phase * 2
                      : (1 - phase) * 2)
                  .clamp(0.0, 1.0);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.3 + 0.7 * t),
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

/// Clean white card with a very soft, single-direction shadow.
/// The standard container for grouped content (inDrive/Yango style).
class AmeexCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? color;

  const AmeexCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = AmeexDesign.radiusLg,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AmeexColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AmeexDesign.shadowCard,
      ),
      child: child,
    );

    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: box,
      ),
    );
  }
}

/// Primary filled button — brand blue, full width by default, 52dp tall.
class AmeexPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? trailingIcon;
  final double height;

  const AmeexPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.trailingIcon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: (onPressed == null || isLoading) ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Secondary (outlined/neutral) button.
class AmeexSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;

  const AmeexSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AmeexColors.textDark),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Compact statistic tile — clean monospace-free numbers, muted label,
/// no exaggerated icon badges.
class AmeexStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const AmeexStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AmeexColors.primaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return AmeexCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AmeexTheme.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AmeexColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontFamily: AmeexTheme.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AmeexColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading — restrained, no bars or gradients.
class AmeexSectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const AmeexSectionTitle({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: AmeexTheme.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AmeexColors.textDark,
              ),
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

/// Small pill status badge — neutral background, brand-tinted text.
class AmeexStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const AmeexStatusPill({
    super.key,
    required this.label,
    this.color = AmeexColors.primaryBlue,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AmeexDesign.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AmeexTheme.fontFamily,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
