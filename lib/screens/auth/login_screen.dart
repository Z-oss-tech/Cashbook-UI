import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../bottom_nav/main_navigation_screen.dart';
import '../../core/utils/toast_helper.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  void _handleLogin() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ToastHelper.showToast(context, 'Please enter a phone number', isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final devOtp = await authProvider.sendOtp(phone);

    if (devOtp != null && mounted) {
      // Show the OTP in a SnackBar since we aren't sending real SMS yet
      ToastHelper.showToast(context, 'TESTING: Your OTP is $devOtp');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(phone: phone),
        ),
      );
    } else if (mounted) {
      ToastHelper.showToast(context, authProvider.error ?? 'Failed to send OTP', isError: true);
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
                          "Welcome Back 👋",
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

                        // Phone Field
                        Text(
                          "Phone Number",
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
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Enter phone number",
                              hintStyle: GoogleFonts.poppins(),
                              icon: const Icon(Icons.phone),
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
                                onPressed: authProvider.isLoading ? null : _handleLogin,
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
                                        "Continue",
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

                        const SizedBox(height: 30),

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
                                      // Try real Google Login first
                                      var res = await authProvider.googleLogin();
                                      
                                      // If it fails (due to missing SHA-1 configuration on this APK), fall back to the Demo Bypass so the app works flawlessly!
                                      if (res == null && mounted) {
                                        final errorMsg = authProvider.error ?? 'Unknown error';
                                        ToastHelper.showToast(context, 'Real Google Login failed ($errorMsg). Using demo bypass...');
                                        res = await authProvider.bypassGoogleLoginForDemo();
                                      }
                                      
                                      if (res != null && mounted) {
                                        final user = res;
                                        if (user['name'] != null) {
                                          Provider.of<SettingsProvider>(context, listen: false).setUserName(user['name']);
                                        }
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const MainNavigationScreen(),
                                          ),
                                        );
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
                                    const Icon(Icons.g_mobiledata, size: 34),
                                    const SizedBox(width: 8),
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