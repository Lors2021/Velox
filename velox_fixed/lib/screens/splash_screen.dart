import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
            parent: _ctrl, curve: Curves.easeOut));
    _scale =
        Tween<double>(begin: 0.85, end: 1).animate(CurvedAnimation(
            parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();

    // Wait for auth state, then navigate
    Future.delayed(const Duration(milliseconds: 1800), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.directions_bike_rounded,
                      color: Colors.black, size: 52),
                ),
                const SizedBox(height: 28),
                const Text(
                  'VELOX',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 10,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'CYCLE FURTHER',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    letterSpacing: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
