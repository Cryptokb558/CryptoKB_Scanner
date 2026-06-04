import 'package:flutter/material.dart';

/// Real-time latency line chart. Drops (null = timeout) are drawn as vertical
/// red markers.
class LatencyChart extends StatelessWidget {
  const LatencyChart({
    required this.history,
    super.key,
    this.height = 150,
    this.lineColor = const Color(0xFF00E5A8),
    this.dropColor = const Color(0xFFFF3B30),
  });

  final List<int?> history;
  final double height;
  final Color lineColor;
  final Color dropColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _ChartPainter(
          history: history,
          lineColor: lineColor,
          dropColor: dropColor,
          gridColor: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.history,
    required this.lineColor,
    required this.dropColor,
    required this.gridColor,
  });

  final List<int?> history;
  final Color lineColor;
  final Color dropColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;
    final width = size.width;
    final height = size.height;

    var maxVal = 150;
    for (final v in history) {
      if (v != null && v > maxVal) maxVal = v;
    }
    maxVal = ((maxVal + 49) ~/ 50) * 50;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i <= 3; i++) {
      final y = height - (i * (height / 3));
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
      final label = (maxVal * i / 3).round();
      textPainter
        ..text = TextSpan(
          text: '${label}ms',
          style: TextStyle(
            color: gridColor,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        )
        ..layout()
        ..paint(
          canvas,
          Offset(width - textPainter.width - 2, y - textPainter.height - 2),
        );
    }

    final stepX = width / (history.length - 1);
    final points = <Offset>[];
    for (var i = 0; i < history.length; i++) {
      final v = history[i];
      final x = i * stepX;
      if (v != null) {
        final y = height - ((v / maxVal) * height);
        points.add(Offset(x, y.clamp(2.0, height - 2.0)));
      } else {
        _drawDrop(canvas, x, height);
      }
    }
    if (points.isEmpty) return;

    final areaPath = Path()..moveTo(points.first.dx, height);
    for (final p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath
      ..lineTo(points.last.dx, height)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.18),
            lineColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, width, height)),
    );

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas
      ..drawPath(
        linePath,
        Paint()
          ..color = lineColor.withValues(alpha: 0.4)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawPath(
        linePath,
        Paint()
          ..color = lineColor
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(
        points.last,
        4,
        Paint()..color = lineColor,
      )
      ..drawCircle(
        points.last,
        8,
        Paint()
          ..color = lineColor.withValues(alpha: 0.3)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
  }

  void _drawDrop(Canvas canvas, double x, double height) {
    canvas
      ..drawLine(
        Offset(x, 0),
        Offset(x, height),
        Paint()
          ..color = dropColor.withValues(alpha: 0.15)
          ..strokeWidth = 2,
      )
      ..drawCircle(
        Offset(x, height - 6),
        3,
        Paint()..color = dropColor,
      );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.history != history;
}
