import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../core/theme/premium_themes.dart';
import '../../models/transaction_model.dart';

class CherryReportsComponents {
  // 1. Savings Goal Card
  static Widget buildSavingsCard(
    BuildContext context,
    double balance,
    ThemeInfo premiumTheme,
  ) {
    // Dynamic goal: next multiple of 10,000 above current balance (minimum 10,000)
    final target =
        ((balance > 0 ? balance + 1 : 1000) / 10000).ceil() * 10000.0;
    double progress = balance / target;
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;
    final progressPercent = (progress * 100).toInt();

    final isDark = premiumTheme.themeData.brightness == Brightness.dark;

    // Using HTML colors approx
    final bgColor = isDark ? const Color(0xFFffb2b7) : const Color(0xFFffdadb);
    final onBgColor = isDark
        ? const Color(0xFF92002a)
        : const Color(0xFF40000d);
    final onBgVariant = isDark
        ? const Color(0xFF544244)
        : const Color(0xFF92002a);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.savings_rounded,
                  color: premiumTheme.primaryColor,
                ),
              ),
              Text(
                '$progressPercent% Complete',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onBgVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Next Milestone',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: onBgColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Goal: ₹${NumberFormat("#,##0.00").format(target)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: onBgVariant,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: onBgColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: premiumTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            progress >= 1
                ? 'Milestone achieved!'
                : 'Almost there, keep blooming...',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: onBgColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Spending Insights
  static Widget buildInsightsCard(
    BuildContext context,
    List<double> weeklyData,
    ThemeInfo premiumTheme,
  ) {
    final isDark = premiumTheme.themeData.brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF0f0069);

    // Find max for scaling
    final maxVal = weeklyData.isEmpty ? 0.0 : weeklyData.reduce(max);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: premiumTheme.primaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Insights',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: premiumTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'This Week',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: premiumTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final val = weeklyData[index];
                final pct = maxVal > 0 ? val / maxVal : 0.0;
                // Add a small base height for visibility
                final heightPct = pct * 0.9 + 0.1;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text(
                            days[index],
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: premiumTheme.primaryColor.withValues(alpha: 0.7),
                            ),
                          ),
                        const SizedBox(height: 4),
                        FractionallySizedBox(
                          widthFactor: 1.0,
                          child: Container(
                            height: 150 * heightPct,
                            decoration: BoxDecoration(
                              color: premiumTheme.primaryColor.withValues(alpha: 0.2),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: 0.5,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: premiumTheme.primaryColor
                                        .withValues(alpha: 0.4),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Weekly spending distribution.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: isDark ? Colors.white70 : const Color(0xFF5b4041),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Top Categories
  static Widget buildTopCategories(
    BuildContext context,
    List<RecordModel> records,
    ThemeInfo premiumTheme,
  ) {
    final isDark = premiumTheme.themeData.brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF0f0069);

    // Group expenses by category/note
    Map<String, double> catSpending = {};
    for (var r in records) {
      if (r.isGiven) {
        String cat = (r.category != null && r.category!.isNotEmpty)
            ? r.category!
            : r.note;
        if (cat.isEmpty) cat = 'General';
        catSpending[cat] = (catSpending[cat] ?? 0) + r.amount;
      }
    }

    var sortedCats = catSpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top3 = sortedCats.take(3).toList();
    final totalExpense = records
        .where((r) => r.isGiven)
        .fold(0.0, (s, r) => s + r.amount);

    // Fallback if no expenses
    if (top3.isEmpty) {
      top3.add(const MapEntry('No expenses yet', 0.0));
    }

    final colors = [
      const Color(0xFFf7dcde), // tertiary-fixed
      const Color(0xFFffdadb), // primary-fixed
      const Color(0xFFffdadc), // secondary-fixed
    ];
    final iconColors = [
      const Color(0xFF544244), // on-tertiary-fixed-variant
      const Color(0xFFb90538), // primary
      const Color(0xFFa93349), // secondary
    ];
    final icons = [
      Icons.restaurant_rounded,
      Icons.shopping_bag_rounded,
      Icons.commute_rounded,
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: premiumTheme.primaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Categories',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(top3.length, (index) {
            final entry = top3[index];
            final pct = totalExpense > 0 ? entry.value / totalExpense : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icons[index % icons.length],
                      color: iconColors[index % iconColors.length],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '₹${NumberFormat("#,##0.00").format(entry.value)}',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFf5f2ff),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: pct,
                            child: Container(
                              decoration: BoxDecoration(
                                color: iconColors[index % iconColors.length],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 4. Recent Books
  static Widget buildRecentBloom(
    BuildContext context,
    List<RecordModel> recentEvents,
    ThemeInfo premiumTheme,
  ) {
    final isDark = premiumTheme.themeData.brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF0f0069);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF5b4041);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Books',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: premiumTheme.primaryColor.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: recentEvents.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "No records yet",
                        style: TextStyle(color: subtitleColor),
                      ),
                    ),
                  ]
                : recentEvents.map((r) {
                    final isExpense = r.isGiven;
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: premiumTheme.primaryColor.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isExpense
                                  ? premiumTheme.primaryColor.withValues(alpha: 0.1)
                                  : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              isExpense
                                  ? Icons.local_florist_rounded
                                  : Icons.payments_rounded,
                              color: isExpense
                                  ? premiumTheme.primaryColor
                                  : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateFormat('MMM dd').format(r.date)} • ${r.cashbookName ?? ""}',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: subtitleColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isExpense ? '-' : '+'}\$${NumberFormat("#,##0.00").format(r.amount)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isExpense
                                  ? premiumTheme.primaryColor
                                  : Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
          ),
        ),
      ],
    );
  }
}

class FloatingPetalsBackground extends StatefulWidget {
  final Widget child;
  const FloatingPetalsBackground({super.key, required this.child});

  @override
  State<FloatingPetalsBackground> createState() =>
      _FloatingPetalsBackgroundState();
}

class _FloatingPetalsBackgroundState extends State<FloatingPetalsBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Petal> _petals = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initial petals
    for (int i = 0; i < 15; i++) {
      _petals.add(_createPetal(true));
    }

    _controller.addListener(() {
      setState(() {
        for (var petal in _petals) {
          petal.y += petal.speed;
          petal.rotation += petal.rotationSpeed;
          petal.x += sin(petal.y * 0.01) * 0.5; // Sway

          // Reset when out of bounds
          if (petal.y > MediaQuery.of(context).size.height + 50) {
            _resetPetal(petal);
          }
        }
      });
    });
  }

  Petal _createPetal(bool randomY) {
    return Petal(
      x:
          _random.nextDouble() *
          500, // Will be constrained by screen width later
      y: randomY ? _random.nextDouble() * 800 : -50,
      size: _random.nextDouble() * 20 + 10,
      speed: _random.nextDouble() * 2 + 1,
      rotation: _random.nextDouble() * 360,
      rotationSpeed: (_random.nextDouble() - 0.5) * 2,
    );
  }

  void _resetPetal(Petal petal) {
    petal.y = -50;
    // We don't have direct access to screen width here easily in init,
    // so we approximate or use a large value
    petal.x = _random.nextDouble() * 1000;
    petal.speed = _random.nextDouble() * 2 + 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Petals layer
        IgnorePointer(
          child: CustomPaint(
            painter: PetalsPainter(_petals),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }
}

class Petal {
  double x;
  double y;
  double size;
  double speed;
  double rotation;
  double rotationSpeed;

  Petal({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class PetalsPainter extends CustomPainter {
  final List<Petal> petals;

  PetalsPainter(this.petals);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF43F5E)
          .withValues(alpha: 0.2) // Pink/Cherry color
      ..style = PaintingStyle.fill;

    for (var petal in petals) {
      canvas.save();
      // Ensure X is within screen
      double x = petal.x % size.width;
      canvas.translate(x, petal.y);
      canvas.rotate(petal.rotation * pi / 180);

      // Draw a simple petal shape
      final path = Path();
      path.moveTo(0, 0);
      path.quadraticBezierTo(petal.size / 2, -petal.size, petal.size, 0);
      path.quadraticBezierTo(petal.size / 2, petal.size, 0, 0);

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
