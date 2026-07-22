import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: const Text(
          'Sceneo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 56,
            fontWeight: FontWeight.w200, // Very thin for elegance
            letterSpacing: 4,
          ),
        )
        .animate()
        .fade(duration: 1.5.seconds, curve: Curves.easeIn)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.05, 1.05),
          duration: 2.seconds,
          curve: Curves.easeOutQuart,
        )
        .shimmer(
          duration: 2.seconds,
          color: AppColors.accent.withOpacity(0.3),
        ),
      ),
    );
  }
}
