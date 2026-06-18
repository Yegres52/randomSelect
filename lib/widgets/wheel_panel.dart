import 'dart:math';

import 'package:flutter/material.dart';

class WheelPanel extends StatelessWidget {
  const WheelPanel({
    super.key,
    required this.animation,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final Animation<double> animation;
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight =
            constraints.maxHeight.isFinite ? constraints.maxHeight : 620.0;
        final wheelSize = min(430.0, max(150.0, availableHeight - 190.0));

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: availableHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Random Select',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox.square(
                  dimension: wheelSize,
                  child: AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: animation.value * pi * 2,
                        child: child,
                      );
                    },
                    child: const CustomPaint(painter: _WheelPainter()),
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    label,
                    key: ValueKey(label),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: onPressed,
                  icon: isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.casino_outlined),
                  label: Text(isLoading ? 'Выбираем' : 'Старт'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter();

  static const _colors = [
    Color(0xffd24040),
    Color(0xff316edb),
    Color(0xff34a853),
    Color(0xfffbbc04),
    Color(0xff9b59b6),
    Color(0xffff7a45),
    Color(0xff00acc1),
    Color(0xffef476f),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final segmentAngle = pi * 2 / _colors.length;

    for (var i = 0; i < _colors.length; i++) {
      final paint = Paint()..color = _colors[i];
      canvas.drawArc(rect, i * segmentAngle, segmentAngle, true, paint);
    }

    canvas.drawCircle(
      center,
      radius * 0.97,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = Colors.white,
    );
    canvas.drawCircle(center, radius * 0.16, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius * 0.08, Paint()..color = Colors.black);

    final marker = Path()
      ..moveTo(center.dx, center.dy - radius - 6)
      ..lineTo(center.dx - 18, center.dy - radius + 34)
      ..lineTo(center.dx + 18, center.dy - radius + 34)
      ..close();
    canvas.drawPath(marker, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
