import 'dart:math';

import 'package:akillisletme/product/service/service_locator.dart';
import 'package:flutter/material.dart';

/// Ambient "matrix code rain" backdrop — faint neon glyph columns falling
/// behind the whole app, giving the scanner a terminal / hacker feel.
class HomeBackground extends StatefulWidget {
  const HomeBackground({super.key});

  static final enabledNotifier = ValueNotifier<bool>(
    locator.sharedCache.isBackgroundAnimationEnabled,
  );

  /// Neon accent reused by the home console UI so it matches the rain.
  static const neon = Color(0xFF00FF9C);

  @override
  State<HomeBackground> createState() => _HomeBackgroundState();
}

class _HomeBackgroundState extends State<HomeBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    if (HomeBackground.enabledNotifier.value) _controller.repeat();
    HomeBackground.enabledNotifier.addListener(_onToggle);
  }

  void _onToggle() {
    if (HomeBackground.enabledNotifier.value) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
    setState(() {});
  }

  @override
  void dispose() {
    HomeBackground.enabledNotifier.removeListener(_onToggle);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!HomeBackground.enabledNotifier.value) return const SizedBox.shrink();

    final size = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: size,
          painter: _MatrixRainPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _MatrixRainPainter extends CustomPainter {
  _MatrixRainPainter({required this.progress});

  final double progress;

  static const _glyphs = r'ｱｲｳｴｵ01ﾊﾋﾌ#@%&$=+<>/0123456789ABCDEF';
  static const double _cell = 22; // glyph cell height/width
  static const int _trail = 14; // glyphs lit above each column head
  static const Color _neon = HomeBackground.neon;

  // Stable per-column randomness (so glyphs don't flicker every frame).
  static final Random _rng = Random(7);
  static List<double> _speeds = const [];
  static List<double> _offsets = const [];
  static List<List<String>> _columns = const [];
  static int _cols = 0;
  static int _rows = 0;

  void _ensureGrid(Size size) {
    final cols = (size.width / _cell).ceil();
    final rows = (size.height / _cell).ceil() + _trail;
    if (cols == _cols && rows == _rows && _columns.isNotEmpty) return;
    _cols = cols;
    _rows = rows;
    _speeds = List.generate(cols, (_) => 0.4 + _rng.nextDouble() * 1.1);
    _offsets = List.generate(cols, (_) => _rng.nextDouble());
    _columns = List.generate(
      cols,
      (_) => List.generate(
        rows,
        (_) => _glyphs[_rng.nextInt(_glyphs.length)],
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _ensureGrid(size);

    for (var c = 0; c < _cols; c++) {
      final x = c * _cell;
      // Head row scrolls down continuously, wrapping around.
      final headF = ((progress * _speeds[c] + _offsets[c]) % 1.0) * _rows;
      final head = headF.floor();

      for (var t = 0; t < _trail; t++) {
        final row = head - t;
        if (row < 0 || row >= _rows) continue;
        final y = row * _cell;
        // Brightest at the head, fading up the trail.
        final fade = 1 - t / _trail;
        final alpha = t == 0 ? 0.32 : 0.16 * fade;
        if (alpha <= 0.01) continue;

        TextPainter(
          text: TextSpan(
            text: _columns[c][row],
            style: TextStyle(
              color: (t == 0 ? Colors.white : _neon).withValues(alpha: alpha),
              fontSize: 15,
              fontFamily: 'monospace',
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )
          ..layout()
          ..paint(canvas, Offset(x, y));
      }
    }
  }

  @override
  bool shouldRepaint(_MatrixRainPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
