import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color _background = Color(0xFFF4F5F7);
  static const String _splashAsset =
      'assets/animations/invoice_ai_logo_motion.gif';
  static const Duration _splashDuration = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(const AssetImage(_splashAsset), context);
    });
    _start();
  }

  Future<void> _start() async {
    await Future<void>.delayed(_splashDuration);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => widget.nextScreen,
        transitionDuration: const Duration(milliseconds: 360),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoWidth = (screenWidth * 0.72).clamp(230.0, 420.0);

    return Scaffold(
      backgroundColor: _background,
      body: Center(
        child: Image.asset(
          _splashAsset,
          width: logoWidth,
          gaplessPlayback: true,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
