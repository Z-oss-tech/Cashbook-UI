import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/settings_provider.dart';
import '../constants/app_colors.dart';

class LockScreenWrapper extends StatefulWidget {
  final Widget child;

  const LockScreenWrapper({
    super.key,
    required this.child,
  });

  @override
  State<LockScreenWrapper> createState() => _LockScreenWrapperState();
}

class _LockScreenWrapperState extends State<LockScreenWrapper> with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isAuthenticating = false;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check initially when wrapper is created, if the app just started
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialLockState();
    });
  }

  void _checkInitialLockState() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.biometricLock) {
      setState(() {
        _isLocked = true;
      });
      _authenticate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (!_isAuthenticating) {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        if (settings.biometricLock) {
          setState(() {
            _isLocked = true;
          });
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_isLocked && !_isAuthenticating) {
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    bool authenticated = false;
    try {
      authenticated = await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock SmartKhata',
        biometricOnly: true,
      );
    } catch (e) {
      debugPrint("Auth error: $e");
    }

    if (!mounted) return;

    if (authenticated) {
      setState(() {
        _isLocked = false;
      });
    }
    
    setState(() {
      _isAuthenticating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (_isLocked)
          Positioned.fill(
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'App Locked',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unlock with biometrics to continue',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 48),
                      ElevatedButton.icon(
                        onPressed: _isAuthenticating ? null : _authenticate,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: Text(
                          'Unlock App',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
