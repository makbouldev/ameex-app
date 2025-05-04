import 'package:flutter/material.dart';
import '../theme/ameex_theme.dart';

/// Premium confirmation dialog with colored header icon,
/// supports destructive (red) or neutral (blue) tone.
class AmeexDialog {
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    IconData icon = Icons.help_outline_rounded,
    bool destructive = false,
  }) {
    final accent = destructive ? AmeexColors.dangerRed : AmeexColors.primaryBlue;
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AmeexTheme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AmeexColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: const TextStyle(
                  fontFamily: AmeexTheme.fontFamily,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AmeexColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AmeexColors.surfaceAlt,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          cancelLabel,
                          style: const TextStyle(
                            fontFamily: AmeexTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AmeexColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontFamily: AmeexTheme.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Branded empty state — icon badge + title + hint, optional action.
class AmeexEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AmeexEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AmeexColors.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 30, color: AmeexColors.textFaint),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AmeexTheme.fontFamily,
                color: AmeexColors.textDark,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AmeexTheme.fontFamily,
                  color: AmeexColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AmeexColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontFamily: AmeexTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton block — rectangular placeholder that pulses
/// to signal "loading real data from the server".
class AmeexSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry margin;

  const AmeexSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.margin = EdgeInsets.zero,
  });

  @override
  State<AmeexSkeleton> createState() => _AmeexSkeletonState();
}

class _AmeexSkeletonState extends State<AmeexSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.margin,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(-1 + 2 * t, 0),
                end: Alignment(1 + 2 * t, 0),
                colors: const [
                  Color(0xFFEDEEF2),
                  Color(0xFFF6F7F9),
                  Color(0xFFEDEEF2),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Wraps content with a 2-second Ameex splash loading animation
/// whenever switching tabs or loading pages.
class AmeexInitialLoad extends StatefulWidget {
  final Widget? skeleton;
  final Widget child;
  final Duration minDuration;
  final String? message;

  const AmeexInitialLoad({
    super.key,
    this.skeleton,
    required this.child,
    this.minDuration = const Duration(seconds: 2),
    this.message,
  });

  @override
  State<AmeexInitialLoad> createState() => _AmeexInitialLoadState();
}

class _AmeexInitialLoadState extends State<AmeexInitialLoad> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.minDuration, () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      child: _ready
          ? KeyedSubtree(key: const ValueKey('ready'), child: widget.child)
          : KeyedSubtree(
              key: const ValueKey('loading'),
              child: AmeexSplashView(message: widget.message ?? 'Chargement…'),
            ),
    );
  }
}

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

/// Chart style variants for AmeexSparkline.
enum AmeexSparklineStyle { area, bars, line }

/// Mini analytics chart — smooth area, soft bars, or clean line.
/// Shows a subtle baseline, the max point highlight, and an end dot.
class AmeexSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final double height;
  final AmeexSparklineStyle style;

  const AmeexSparkline({
    super.key,
    required this.values,
    this.color = AmeexColors.primaryBlue,
    this.strokeWidth = 1.8,
    this.height = 32,
    this.style = AmeexSparklineStyle.area,
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
          style: style,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double strokeWidth;
  final AmeexSparklineStyle style;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final range = (maxV - minV) == 0 ? 1.0 : (maxV - minV);
    final padding = 5.0;
    final chartHeight = size.height - padding * 2;

    // Subtle baseline (dotted)
    final baselinePaint = Paint()
      ..color = const Color(0xFFEDEEF2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final baselineY = size.height - 1;
    _drawDottedLine(canvas, Offset(0, baselineY),
        Offset(size.width, baselineY), baselinePaint);

    if (style == AmeexSparklineStyle.bars) {
      _drawBars(canvas, size, minV, range, padding, chartHeight);
    } else {
      _drawLine(canvas, size, minV, range, padding, chartHeight);
    }
  }

  void _drawBars(Canvas canvas, Size size, double minV, double range,
      double padding, double chartHeight) {
    final count = values.length;
    final gap = 2.0;
    final barW = ((size.width - gap * (count - 1)) / count).clamp(2.0, 8.0);
    int maxIdx = 0;
    for (int i = 1; i < count; i++) {
      if (values[i] > values[maxIdx]) maxIdx = i;
    }

    for (int i = 0; i < count; i++) {
      final x = i * (barW + gap);
      final norm = (values[i] - minV) / range;
      final h = (norm * chartHeight).clamp(2.0, chartHeight);
      final y = padding + chartHeight - h;
      final isMax = i == maxIdx;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: isMax ? 0.95 : 0.65),
            color.withValues(alpha: isMax ? 0.6 : 0.25),
          ],
        ).createShader(Rect.fromLTWH(x, y, barW, h));
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barW, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  void _drawLine(Canvas canvas, Size size, double minV, double range,
      double padding, double chartHeight) {
    final path = Path();
    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final norm = (values[i] - minV) / range;
      final y = padding + chartHeight - (norm * chartHeight);
      points.add(Offset(x, y));
    }

    // Catmull-Rom smooth
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i == 0 ? points[i] : points[i - 1];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = (i + 2 < points.length) ? points[i + 2] : p2;
      final c1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final c2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    // Area fill
    if (style == AmeexSparklineStyle.area) {
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.02),
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

    // Max point highlight
    int maxIdx = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > values[maxIdx]) maxIdx = i;
    }
    if (maxIdx != values.length - 1) {
      final maxPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[maxIdx], 2.6, maxPaint);
    }

    // End dot (halo + fill)
    final haloPaint = Paint()..color = color.withValues(alpha: 0.18);
    canvas.drawCircle(points.last, 5.4, haloPaint);
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(points.last, 2.8, dotPaint);
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(points.last, 1.0, innerPaint);
  }

  void _drawDottedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dashW = 2.0;
    const gap = 3.0;
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final len = (dx * dx + dy * dy);
    if (len == 0) return;
    final total = (len).sqrt();
    final ux = dx / total;
    final uy = dy / total;
    double traveled = 0;
    while (traveled < total) {
      final start = Offset(a.dx + ux * traveled, a.dy + uy * traveled);
      final next = traveled + dashW;
      final end = Offset(
        a.dx + ux * next.clamp(0, total),
        a.dy + uy * next.clamp(0, total),
      );
      canvas.drawLine(start, end, paint);
      traveled = next + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.style != style;
}

// Tiny extension for sqrt on double (avoid dart:math import here)
extension _NumSqrt on double {
  double sqrt() {
    double v = this;
    if (v <= 0) return 0;
    double x = v;
    for (int i = 0; i < 20; i++) {
      x = 0.5 * (x + v / x);
    }
    return x;
  }
}

/// Branded Ameex splash / loading view with animated expanding rings
/// and the glowing Ameex orb.
class AmeexSplashView extends StatefulWidget {
  final String message;
  const AmeexSplashView({super.key, this.message = 'Chargement…'});

  @override
  State<AmeexSplashView> createState() => _AmeexSplashViewState();
}

class _AmeexSplashViewState extends State<AmeexSplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AmeexColors.background,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Expanding ring 1
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
                          color: AmeexColors.primaryBlue.withValues(alpha: opacity),
                          width: 1.5,
                        ),
                      ),
                    );
                  },
                ),
                // Expanding ring 2 (offset phase)
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (context, _) {
                    final t = (_ctrl.value + 0.5) % 1.0;
                    final size = 44 + (72 * t);
                    final opacity = (1 - t).clamp(0.0, 1.0) * 0.35;
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AmeexColors.primaryBlue.withValues(alpha: opacity),
                          width: 1.2,
                        ),
                      ),
                    );
                  },
                ),
                // Core Ameex orb with glow
                Container(
                  width: 46,
                  height: 46,
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
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.message,
            style: const TextStyle(
              fontFamily: AmeexTheme.fontFamily,
              color: AmeexColors.textMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen branded splash / loading screen with the Ameex orb
/// surrounded by expanding rings. Used during auth/profile loading.
class AmeexSplash extends StatelessWidget {
  final String? message;
  const AmeexSplash({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmeexColors.background,
      body: AmeexSplashView(message: message ?? 'Chargement…'),
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
