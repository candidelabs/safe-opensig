import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HoldToConfirmButton extends StatefulWidget {
  final String label;
  final VoidCallback onConfirmed;
  final Duration duration;

  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        widget.onConfirmed();
        _controller.reset();
        setState(() => _holding = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    setState(() => _holding = true);
    HapticFeedback.lightImpact();
    _controller.forward(from: _controller.value);
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_holding) {
      setState(() => _holding = false);
      _controller.animateBack(0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut);
    }
  }

  void _onLongPressCancel() {
    if (_holding) {
      setState(() => _holding = false);
      _controller.animateBack(0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonTheme = theme.elevatedButtonTheme.style;
    final accentColor =
        buttonTheme?.backgroundColor?.resolve({}) ?? theme.colorScheme.primary;
    final fgColor = theme.colorScheme.onSurface;

    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onLongPressCancel: _onLongPressCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _BorderProgressPainter(
              progress: _controller.value,
              color: accentColor,
              borderRadius: 16,
              strokeWidth: 3.0,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _holding
                    ? accentColor.withValues(alpha: 0.15)
                    : Colors.transparent,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: fgColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (!_holding)
                      Text(
                        'press and hold',
                        style: TextStyle(
                          color: fgColor.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BorderProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double borderRadius;
  final double strokeWidth;

  _BorderProgressPainter({
    required this.progress,
    required this.color,
    required this.borderRadius,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Idle border — faint outline
    final idlePaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(rrect, idlePaint);

    if (progress <= 0) return;

    // Progress border — bright, traces the perimeter
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    final extractPath = metrics.extractPath(0, metrics.length * progress);

    canvas.drawPath(extractPath, progressPaint);
  }

  @override
  bool shouldRepaint(_BorderProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
