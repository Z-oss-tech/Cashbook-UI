import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import '../../providers/record_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/theme/premium_themes.dart';
import 'package:provider/provider.dart';

import '../dashboard/dashboard_screen.dart';
import '../voice/voice_entry_screen.dart';
import '../records/cashbook_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/profile_screen.dart';
import 'app_drawer.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;

  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _translateAnimation;

  final List<Widget> screens = [
    const DashboardScreen(),
    const VoiceEntryScreen(),
    const ReportsScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _translateAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecordProvider>(context, listen: false).fetchData();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showCreateCashbookDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(0),
                child: GlassCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 16,
                  backgroundColor: Theme.of(context).cardColor,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 12,
                          top: 12,
                          bottom: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Create New Cashbook",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF191C1E),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(dialogContext),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF191C1E),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF191C1E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark
                            ? Colors.white24
                            : const Color(0xFFE0E0E0),
                      ),
                      // Body
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            TextField(
                              controller: nameController,
                              style: GoogleFonts.inter(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Cashbook name',
                                labelStyle: GoogleFonts.inter(
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF4143D5),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: isCreating
                                      ? null
                                      : () async {
                                          final cashbookName =
                                              nameController.text.trim().isEmpty
                                              ? "New Cashbook"
                                              : nameController.text.trim();

                                          setState(() => isCreating = true);
                                          await Provider.of<RecordProvider>(
                                            context,
                                            listen: false,
                                          ).addCashbook(cashbookName);
                                          setState(() => isCreating = false);

                                          if (context.mounted) {
                                            Navigator.pop(
                                              dialogContext,
                                            ); // Close dialog
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => CashbookScreen(
                                                  cashbookName: cashbookName,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4143D5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                    ),
                                    elevation: 2,
                                  ),
                                  child: isCreating
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          "CREATE",
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawer: const AppDrawer(),
      body: screens[currentIndex],
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: SafeArea(bottom: true, child: _buildFloatingNavBar(context)),
      ),
    );
  }

  Widget _buildFloatingNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.7)
                  : Theme.of(context).cardColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 50,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: "Home",
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.mic_rounded,
                  label: "Voice",
                  index: 1,
                ),
                _buildFab(context),
                _buildNavItem(
                  icon: Icons.analytics_rounded,
                  label: "Reports",
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.person_rounded,
                  label: "Profile",
                  index: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isSelected = currentIndex == index;
    
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final premiumTheme = PremiumThemes.getTheme(settings.appTheme);
    final isDefault = settings.appTheme == 'Default';

    final isDark = isDefault
        ? Theme.of(context).brightness == Brightness.dark
        : premiumTheme.themeData.brightness == Brightness.dark;



    final activeColor = const Color(0xFFFFFFFF);

    final activeBg = isDefault
        ? const Color(0xFF7459F7)
        : premiumTheme.primaryColor;

    final inactiveColor = isDark ? Colors.white70 : const Color(0xFF464555);

    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final premiumTheme = PremiumThemes.getTheme(settings.appTheme);
    final isDefault = settings.appTheme == 'Default';

    final gradient = isDefault
        ? const LinearGradient(
            colors: [Color(0xFF4143D5), Color(0xFF7459F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : premiumTheme.gradient;

    final shadowColor = isDefault
        ? const Color(0xFF4143D5).withValues(alpha: 0.4)
        : premiumTheme.primaryColor.withValues(alpha: 0.4);

    final iconColor =
        (isDefault || premiumTheme.themeData.brightness == Brightness.dark)
        ? Colors.white
        : const Color(0xFF191C1E);

    return GestureDetector(
      onTap: () => _showCreateCashbookDialog(context),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _translateAnimation.value),
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.add_rounded, color: iconColor, size: 32),
        ),
      ),
    );
  }
}
