import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../bottom_nav/main_navigation_screen.dart';
import '../../core/utils/toast_helper.dart';
import 'complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isFirstTime = false;
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRunBefore = prefs.getBool('hasRunBefore') ?? false;
    
    if (mounted) {
      setState(() {
        _isFirstTime = !hasRunBefore;
      });
    }

    if (!hasRunBefore) {
      await prefs.setBool('hasRunBefore', true);
    }
  }

  void _handleAuth() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      ToastHelper.showToast(context, 'Please enter username and password', isError: true);
      return;
    }

    if (password.length < 6) {
      ToastHelper.showToast(context, 'Password must be at least 6 characters', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    Map<String, dynamic>? res;
    if (_isLogin) {
      res = await authProvider.login(username, password);
    } else {
      res = await authProvider.register(username, password);
    }

    if (res != null && mounted) {
      final isNewUser = res['isNewUser'] == true;
      
      if (isNewUser) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
        );
      } else {
        if (res['name'] != null) {
          Provider.of<SettingsProvider>(context, listen: false).setUserName(res['name']);
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } else if (mounted) {
      final errorMsg = authProvider.error ?? 'Authentication failed';
      ToastHelper.showToast(context, errorMsg, isError: true);
      
      if (_isLogin && errorMsg.toLowerCase().contains('user not found')) {
        setState(() {
          _isLogin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

                        // Top Text
                        Text(
                          _isFirstTime ? "Welcome 👋" : "Welcome Back 👋",
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "Manage your business smartly with AI",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 50),

                        // Illustration
                        Center(
                          child: Container(
                            height: 220,
                            width: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 25,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 90,
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),

                        // Username Field
                        Text(
                          "Username",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter username",
                              hintStyle: GoogleFonts.poppins(),
                              icon: const Icon(Icons.person),
                              counterText: "",
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Password Field
                        Text(
                          "Password",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter password",
                              hintStyle: GoogleFonts.poppins(),
                              icon: const Icon(Icons.lock_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Continue Button
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: authProvider.isLoading ? null : _handleAuth,
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _isLogin ? "Login" : "Register",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(
                              _isLogin ? "Don't have an account? Register" : "Already have an account? Login",
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                "OR",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Google Button
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return GestureDetector(
                              onTap: authProvider.isLoading
                                  ? null
                                  : () async {
                                      final res = await authProvider.googleLogin();
                                      if (res != null && mounted) {
                                        final isNewUser = res['isNewUser'] == true;
                                        if (isNewUser) {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
                                          );
                                        } else {
                                          if (res['name'] != null) {
                                            Provider.of<SettingsProvider>(context, listen: false).setUserName(res['name']);
                                          }
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                                          );
                                        }
                                      } else if (mounted && authProvider.error != null) {
                                        ToastHelper.showToast(context, authProvider.error!, isError: true);
                                      }
                                    },
                              child: Container(
                                height: 58,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                                      height: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Continue with Google",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Offline Guest Button
                        
                        Center(
                          child: TextButton(
                            onPressed: () async {
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              await authProvider.loginOffline();
                              if (mounted) {
                                Provider.of<SettingsProvider>(context, listen: false).setUserName("Offline Guest");
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MainNavigationScreen(),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              "Continue Offline (Guest)",
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bottom Text
                        Center(
                          child: Text(
                            "SmartKhata © 2026",
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}