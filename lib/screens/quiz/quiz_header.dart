import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../widgets/bottom_nav.dart';
import 'quiz_lang.dart';

class QuizHeader extends StatelessWidget {
  final String title;
  final bool showExit;

  const QuizHeader({
    super.key,
    this.title = 'Bollywood Quiz',
    this.showExit = true,
  });

  void _exitToMain(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const BottomNav()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return RepaintBoundary(
      child: CustomPaint(
        painter: const QuizInvertedCurvePainter(),
        isComplex: true,
        willChange: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, topPad + 10, 8, 64),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    height: 36,
                    width: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff111111),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: showExit
                      ? IconButton(
                          onPressed: () => _exitToMain(context),
                           tooltip: QuizLang.t('exit'),
                          padding: EdgeInsets.zero,
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedLogout02,
                            size: 22.0,
                            color: Colors.redAccent,
                            strokeWidth: 1.5,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuizInvertedCurvePainter extends CustomPainter {
  const QuizInvertedCurvePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const curveDepth = 56.0;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height - curveDepth)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + 18,
        size.width,
        size.height - curveDepth,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.28), 10, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
