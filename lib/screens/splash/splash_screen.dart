import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../bottom_nav/main_navigation_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../services/api_service.dart';
import '../../core/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _animationController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _appVersion = "1.0.0";

  @override
  void initState() {
    super.initState();
    _initAppVersion();
    _checkForUpdates();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _animationController.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = await authProvider.checkAuth();
      
      if (mounted) {
        if (isLoggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    });
  }

  Future<void> _initAppVersion() async {
    try {
      setState(() {
        _appVersion = "1.0.0";
      });
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final res = await ApiService().getLatestAppUpdate();
      if (res['updateAvailable'] == true && res['update'] != null) {
        final update = res['update'];
        final newVersion = update['version'] ?? '0.0.0';
        
        if (_isVersionGreater(_appVersion, newVersion)) {
          await NotificationService().showUpdateNotification(version: newVersion);
        }
      }
    } catch (e) {
      debugPrint('Startup update check failed: $e');
    }
  }

  bool _isVersionGreater(String currentVersion, String newVersion) {
    try {
      List<int> currentParts = currentVersion.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      List<int> newParts = newVersion.split('+').first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      
      for (int i = 0; i < 3; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        int newPart = i < newParts.length ? newParts[i] : 0;
        if (newPart > currentPart) return true;
        if (newPart < currentPart) return false;
      }
    } catch (_) {}
    return false;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,

      body: Stack(
        children: [

          // Background Glow
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.25),
              ),
            ),
          ),

          Positioned(
            bottom: -120,
            left: -70,
            child: Container(
              height: 300,
              width: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.18),
              ),
            ),
          ),

          // Main Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // Logo Container
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        height: 120,
                        width: 120,

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),

                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color:
                            AppColors.primary.withOpacity(0.4),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),

                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // App Name
                    Text(
                      "SmartKhata",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tagline
                    Text(
                      "Smart Business Ledger",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Loader
                    SizedBox(
                      width: 40,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: const LinearProgressIndicator(
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                          minHeight: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Bottom Text
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "100% Safe & Secure",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Version $_appVersion",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white24,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}