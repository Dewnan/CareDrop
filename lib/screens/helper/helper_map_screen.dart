import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HelperMapScreen extends StatelessWidget {
  const HelperMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Map Canvas Simulation
            Positioned.fill(
              child: Container(
                color: const Color(0xFFE6F4F1),
                child: CustomPaint(
                  painter: _RouteMapPainter(),
                ),
              ),
            ),

            // Top Status Bar Banner Overlay
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Heading to',
                          style: TextStyle(
                            fontSize: 12,
                            color: CareDropTheme.textMuted,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'PPUM Block B',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CareDropTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text(
                          '0.6 km',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CareDropTheme.royalBlue,
                          ),
                        ),
                        Text(
                          '~4 min',
                          style: TextStyle(
                            fontSize: 12,
                            color: CareDropTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Turn-by-Turn Instruction Banner + Action Buttons
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CareDropTheme.royalBlue.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: CareDropTheme.royalBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.turn_right_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Turn right onto Jalan Universiti',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: CareDropTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'In 200 m',
                                style: TextStyle(
                                  color: CareDropTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: CareDropTheme.cardBorderColor),
                              foregroundColor: CareDropTheme.textPrimary,
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'End Nav',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CareDropTheme.royalBlue,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Opening Google Maps...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text(
                              'Open in Maps',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFD1FAE5).withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    // Grid lines
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Dashed Route curve
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.8)
      ..cubicTo(
        size.width * 0.45,
        size.height * 0.5,
        size.width * 0.55,
        size.height * 0.35,
        size.width * 0.4,
        size.height * 0.2,
      );

    final routePaint = Paint()
      ..color = CareDropTheme.royalBlue
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, routePaint);

    // Destination Pin (Hospital) at top
    final destPinPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.2), 16, destPinPaint);

    final TextPainter textPainter = TextPainter(
      text: const TextSpan(
        text: '📍',
        style: TextStyle(fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(size.width * 0.4 - 8, size.height * 0.2 - 10));

    // Helper Position Marker in middle
    final helperPinPaint = Paint()..color = CareDropTheme.royalBlue;
    canvas.drawCircle(Offset(size.width * 0.49, size.height * 0.48), 20, helperPinPaint);

    final TextPainter arrowPainter = TextPainter(
      text: const TextSpan(
        text: '▲',
        style: TextStyle(fontSize: 16, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    arrowPainter.paint(canvas, Offset(size.width * 0.49 - 7, size.height * 0.48 - 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
