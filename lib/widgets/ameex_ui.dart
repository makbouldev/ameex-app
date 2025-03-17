import 'package:flutter/material.dart';
import '../theme/ameex_theme.dart';

/// Animated number counter — eases from 0 to target.
/// Gives the "real app" feel, especially on KPIs and balances.
class AmeexAnimatedNumber extends StatefulWidget {
  final double value;
  final Duration duration;
  final TextStyle? style;
  final String Function(double) format;
  final String suffix;
  final TextStyle? suffixStyle;

  AmeexAnimatedNumber({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 650),
    this.style,
    String Function(double)? format,
    this.suffix = '',
    this.suffixStyle,
  }) : format = format ?? ((v) => v.toStringAsFixed(0));

  @override
  State<AmeexAnimatedNumber> createState() => _AmeexAnimatedNumberState();
}

class _AmeexAnimatedNumberState extends State<AmeexAnimatedNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _displayValue = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _displayValue = widget.value;
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AmeexAnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-animate on meaningful changes (not every stream tick).
    // Avoids CPU churn when StreamBuilder rebuilds with same value.
    if ((oldWidget.value - widget.value).abs() > 0.01) {
      _anim = Tween<double>(begin: _displayValue, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _displayValue = widget.value;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final value = widget.format(_anim.value);
        if (widget.suffix.isEmpty) {
          return Text(value, style: widget.style);
        }
        return RichText(
          text: TextSpan(
            style: widget.style,
            children: [
              TextSpan(text: value),
              TextSpan(text: widget.suffix, style: widget.suffixStyle),
            ],
          ),
        );
      },
    );
  }
}

/// Soft sparkline (mini trend line) — the biggest "not AI-generated"
/// signal: real apps show trends, not just numbers.
class AmeexSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final double height;
  final bool fill;

  const AmeexSparkline({
    super.key,
    required this.values,
    this.color = AmeexColors.primaryBlue,
    this.strokeWidth = 1.6,
    this.height = 28,
    this.fill = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          color: color,
          strokeWidth: strokeWidth,
          fill: fill,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool fill;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final padding = 4.0;
    final chartHeight = size.height - padding * 2;

    final path = Path();
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final norm = (values[i] - minV) / range;
      final y = padding + chartHeight - (norm * chartHeight);
      points.add(Offset(x, y));
    }

    // Smooth curve using quadratic beziers
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midX = (prev.dx + curr.dx) / 2;
      path.quadraticBezierTo(prev.dx, prev.dy, midX, (prev.dy + curr.dy) / 2);
      if (i == points.length - 1) {
        path.lineTo(curr.dx, curr.dy);
      }
    }

    // Fill below the curve
    if (fill) {
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // End dot
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(points.last, strokeWidth + 1.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

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
      duration: const Duration(milliseconds: 1800),
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
            SizedBox(
              width: 120, height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Single expanding ring (half the CPU of two)
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, _) {
                      final t = _ctrl.value;
                      final size = 44 + (72 * t);
                      final opacity = (1 - t).clamp(0.0, 1.0) * 0.45;
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
                  // Static core (no scale animation)
                  Container(
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
