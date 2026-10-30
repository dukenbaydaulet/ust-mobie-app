import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/colors.dart';
import '../../core/config.dart';

/// Splash экраны көрініп болды ма (кемінде 3 секунд).
final splashDoneProvider = NotifierProvider<SplashDone, bool>(SplashDone.new);

class SplashDone extends Notifier<bool> {
  @override
  bool build() => false;

  void finish() => state = true;
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Уақытты бірінші кадр экранға шыққаннан бастап санаймыз
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (mounted) ref.read(splashDoneProvider.notifier).finish();
      });
    });
  }

  // Логотип жүйелік splash-тағы суретпен (assets/splash_logo.png) бірдей және
  // дәл сол орында тұрады. Сондықтан ол қозғалмайды, қалғаны біртіндеп шығады.
  static const _logoSize = 96.0;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.splashMiddle, // жүйелік splash түсі
        body: Stack(
          children: [
            const Positioned.fill(
              child: _FadeIn(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.splashTop,
                        AppColors.splashMiddle,
                        AppColors.splashBottom,
                      ],
                      stops: [0, 0.5, 1],
                    ),
                  ),
                ),
              ),
            ),
            const Center(child: _Logo(size: _logoSize)),
            Positioned(
              top: height / 2 + _logoSize / 2 + 24,
              left: 16,
              right: 16,
              child: _FadeIn(slide: true, child: _titleBlock()),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 24,
              child: _FadeIn(
                child: Column(
                  children: [_loader(), const SizedBox(height: 16), _footer()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titleBlock() {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/images/wordmark.svg',
          width: 150,
          height: 20,
          semanticsLabel: 'USTAZ TILEGI',
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0x26FFFFFF)),
              ),
              child: const Text(
                'ust.kz',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xE5DBEAFE),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 19.5 / 13,
                  letterSpacing: 0.32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Республикалық\nғылыми – әдістемелік орталығы',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xCCDBEAFE),
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _loader() {
    return const Column(
      children: [
        _Spinner(size: 32),
        SizedBox(height: 10),
        Text(
          'Жүктелуде...',
          style: TextStyle(
            color: Color(0xB2BFDBFE),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 16 / 12,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    return Column(
      children: [
        // Толық енге созылған бір жол; тар экранда сыю үшін кішірейеді
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Қазақстан ұстаздарының қауымдастығы'.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0x80FFFFFF),
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 16.5 / 11,
                letterSpacing: 0.55,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Нұсқа ${AppConfig.version}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0x59FFFFFF),
            fontSize: 10,
            fontWeight: FontWeight.w400,
            height: 15 / 10,
          ),
        ),
      ],
    );
  }
}

/// Ақ шаршыдағы логотип, айналасында жұмсақ ақ жарқырау.
/// assets/splash_logo.png суретімен бірдей болуы керек.
class _Logo extends StatelessWidget {
  const _Logo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x33FFFFFF), blurRadius: 32)],
      ),
      child: SvgPicture.asset('assets/images/logo.svg'),
    );
  }
}

/// Айналып тұратын шеңбер: жоғарғы жағы ақ, төменге қарай мөлдірленеді.
class _Spinner extends StatefulWidget {
  const _Spinner({required this.size});
  final double size;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _RingPainter(),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.0;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = const SweepGradient(
        colors: [Color(0x33FFFFFF), Colors.white, Color(0x33FFFFFF)],
        stops: [0, 0.75, 1],
      ).createShader(rect);
    canvas.drawCircle(rect.center, (size.width - stroke) / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Мазмұнды 0.4 секундта біртіндеп көрсетеді.
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child, this.slide = false});
  final Widget child;
  final bool slide;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: slide
            ? Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child)
            : child,
      ),
      child: child,
    );
  }
}
