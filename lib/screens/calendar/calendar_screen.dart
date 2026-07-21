import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart';
import '../../providers/record_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/premium_themes.dart';
import '../../core/widgets/theme_background_wrapper.dart';
import '../../screens/records/add_record_screen.dart';
import 'widgets/calendar_day_widget.dart';
import 'widgets/month_header.dart';
import 'widgets/transaction_bottom_sheet.dart';

class CalendarScreen extends StatefulWidget {
  final String? cashbookName;
  const CalendarScreen({super.key, this.cashbookName});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late DateTime _currentMonth;
  late DateTime _selectedDate;
  late AnimationController _gridFadeController;
  late Animation<double> _gridFadeAnim;

  // The pivot: page 500 = "today's month" so we can scroll infinitely
  static const int _initialPage = 500;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);

    _pageController = PageController(initialPage: _initialPage);

    _gridFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _gridFadeAnim = CurvedAnimation(
      parent: _gridFadeController,
      curve: Curves.easeOut,
    );
    _gridFadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _gridFadeController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) {
    final diff = page - _initialPage;
    final baseMonth = DateTime(DateTime.now().year, DateTime.now().month);
    return DateTime(baseMonth.year, baseMonth.month + diff);
  }

  void _goToPrev() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToNext() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToToday() {
    final now = DateTime.now();
    final diffMonths = (now.year - _currentMonth.year) * 12 +
        (now.month - _currentMonth.month);
    _pageController.animateToPage(
      _pageController.page!.round() + diffMonths,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  void _onDayTap(DateTime date, List<RecordModel> records) {
    setState(() => _selectedDate = date);
    final settings =
        Provider.of<SettingsProvider>(context, listen: false);
    final primaryColor = settings.appTheme == 'Default'
        ? const Color(0xFF4143D5)
        : PremiumThemes.getTheme(settings.appTheme).primaryColor;

    showTransactionBottomSheet(
      context: context,
      date: date,
      records: records,
      primaryColor: primaryColor,
      onAddRecord: () => _navigateToAddRecord(date),
    );
  }

  void _onDayLongPress(DateTime date) {
    HapticFeedback.heavyImpact();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final primaryColor = settings.appTheme == 'Default'
        ? const Color(0xFF4143D5)
        : PremiumThemes.getTheme(settings.appTheme).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickActionsSheet(
        date: date,
        primaryColor: primaryColor,
        isDark: isDark,
        onAddIncome: () {
          Navigator.pop(context);
          _navigateToAddRecord(date, forceIncome: true);
        },
        onAddExpense: () {
          Navigator.pop(context);
          _navigateToAddRecord(date, forceExpense: true);
        },
        onViewDetails: () {
          Navigator.pop(context);
          final records = _getRecordsForDate(
            Provider.of<RecordProvider>(context, listen: false).records,
            date,
          );
          _onDayTap(date, records);
        },
      ),
    );
  }

  void _navigateToAddRecord(DateTime date,
      {bool forceIncome = false, bool forceExpense = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddRecordScreen(),
      ),
    );
  }

  List<RecordModel> _getRecordsForDate(
      List<RecordModel> allRecords, DateTime date) {
    return allRecords.where((r) {
      return r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day;
    }).toList();
  }

  Color _getPrimaryColor(SettingsProvider settings) {
    return settings.appTheme == 'Default'
        ? const Color(0xFF4143D5)
        : PremiumThemes.getTheme(settings.appTheme).primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<RecordProvider, SettingsProvider>(
      builder: (context, recordProvider, settings, _) {
        final primaryColor = _getPrimaryColor(settings);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        var allRecords = recordProvider.records;
        if (widget.cashbookName != null) {
          allRecords = allRecords
              .where((r) => r.cashbookName == widget.cashbookName)
              .toList();
        }

        return ThemeBackgroundWrapper(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                children: [
                  // ── App Bar ────────────────────────────────────────────
                  _buildAppBar(context, isDark, primaryColor),

                  // ── Weekday Labels ──────────────────────────────────────
                  _buildWeekdayRow(isDark),

                  // ── Stats Strip ─────────────────────────────────────────
                  _buildMonthStatsStrip(allRecords, primaryColor, isDark),

                  // ── Calendar PageView ───────────────────────────────────
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (page) {
                        _gridFadeController.reset();
                        _gridFadeController.forward();
                        setState(() {
                          _currentMonth = _monthForPage(page);
                        });
                      },
                      itemBuilder: (context, page) {
                        final month = _monthForPage(page);
                        return FadeTransition(
                          opacity: _gridFadeAnim,
                          child: _buildCalendarGrid(
                            month,
                            allRecords,
                            primaryColor,
                            isDark,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── App Bar with MonthHeader ─────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, bool isDark, Color primaryColor) {
    return Column(
      children: [
        // Title row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '📅',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
              Text(
                widget.cashbookName != null
                    ? '${widget.cashbookName} Calendar'
                    : 'Calendar',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              // Today button
              GestureDetector(
                onTap: _goToToday,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.75),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'Today',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        MonthHeader(
          displayedMonth: _currentMonth,
          primaryColor: primaryColor,
          onPrevious: _goToPrev,
          onNext: _goToNext,
        ),
      ],
    );
  }

  // ── Weekday Labels ──────────────────────────────────────────────────────

  Widget _buildWeekdayRow(bool isDark) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: days
            .map(
              (d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: d == 'Sun'
                          ? Colors.red.withValues(alpha: 0.7)
                          : (isDark
                              ? Colors.white38
                              : Colors.grey.shade500),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Month Stats Strip ───────────────────────────────────────────────────

  Widget _buildMonthStatsStrip(
    List<RecordModel> allRecords,
    Color primaryColor,
    bool isDark,
  ) {
    final monthRecords = allRecords.where((r) {
      return r.date.year == _currentMonth.year &&
          r.date.month == _currentMonth.month;
    }).toList();

    final income =
        monthRecords.where((r) => r.type == 'income').fold(0.0, (a, r) => a + r.amount);
    final expense =
        monthRecords.where((r) => r.type == 'expense').fold(0.0, (a, r) => a + r.amount);
    final net = income - expense;
    final activeDays = monthRecords.map((r) => r.date.day).toSet().length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatPill('📈', _short(income), 'In', const Color(0xFF00C853)),
          _vDivider(isDark),
          _StatPill('📉', _short(expense), 'Out', const Color(0xFFE53935)),
          _vDivider(isDark),
          _StatPill(
            net >= 0 ? '✅' : '⚠️',
            _short(net.abs()),
            net >= 0 ? 'Saved' : 'Deficit',
            net >= 0 ? const Color(0xFF00C853) : const Color(0xFFE53935),
          ),
          _vDivider(isDark),
          _StatPill(
            '📅',
            '$activeDays',
            'Active Days',
            primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _vDivider(bool isDark) => Container(
        height: 28,
        width: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.2),
      );

  Widget _StatPill(String emoji, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // ── Calendar Grid ──────────────────────────────────────────────────────

  Widget _buildCalendarGrid(
    DateTime month,
    List<RecordModel> allRecords,
    Color primaryColor,
    bool isDark,
  ) {
    // Build list of all dates to display (including prev/next month overflow)
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    // weekday: Mon=1, ..., Sun=7
    int startWeekday = firstDayOfMonth.weekday; // 1–7
    final daysInMonth =
        DateTime(month.year, month.month + 1, 0).day;

    // Cells before the first of month (prev month overflow)
    final prevMonthDays = startWeekday - 1;
    final prevMonth = DateTime(month.year, month.month - 1);
    final daysInPrevMonth = DateTime(month.year, month.month, 0).day;

    // Total cells: fill to multiple of 7
    final totalCells = ((prevMonthDays + daysInMonth) / 7).ceil() * 7;

    final cells = <DateTime>[];
    // Prev month overflow
    for (int i = prevMonthDays; i > 0; i--) {
      cells.add(DateTime(prevMonth.year, prevMonth.month, daysInPrevMonth - i + 1));
    }
    // Current month
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(month.year, month.month, d));
    }
    // Next month overflow
    final nextMonth = DateTime(month.year, month.month + 1);
    int nextDay = 1;
    while (cells.length < totalCells) {
      cells.add(DateTime(nextMonth.year, nextMonth.month, nextDay++));
    }

    final today = DateTime.now();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 80),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.62,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: cells.length,
      itemBuilder: (context, index) {
        final date = cells[index];
        final isCurrentMonth = date.month == month.month;
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;

        final dayRecords = allRecords.where((r) {
          return r.date.year == date.year &&
              r.date.month == date.month &&
              r.date.day == date.day;
        }).toList();

        return CalendarDayWidget(
          date: date,
          records: dayRecords,
          isCurrentMonth: isCurrentMonth,
          isToday: isToday,
          isSelected: isSelected,
          primaryColor: primaryColor,
          onTap: () => _onDayTap(date, dayRecords),
          onLongPress: () => _onDayLongPress(date),
        );
      },
    );
  }

  String _short(double v) {
    final abs = v.abs();
    if (abs >= 100000) return '₹${(abs / 100000).toStringAsFixed(1)}L';
    if (abs >= 1000) return '₹${(abs / 1000).toStringAsFixed(1)}K';
    return '₹${abs.toStringAsFixed(0)}';
  }
}

// ─── Quick Actions Sheet ─────────────────────────────────────────────────────

class _QuickActionsSheet extends StatelessWidget {
  final DateTime date;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onViewDetails;

  const _QuickActionsSheet({
    required this.date,
    required this.primaryColor,
    required this.isDark,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final sheetBg = isDark ? const Color(0xFF1C1C2E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('EEE, MMM d').format(date),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  emoji: '💰',
                  label: 'Add Income',
                  color: const Color(0xFF00C853),
                  isDark: isDark,
                  onTap: onAddIncome,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  emoji: '💸',
                  label: 'Add Expense',
                  color: const Color(0xFFE53935),
                  isDark: isDark,
                  onTap: onAddExpense,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  emoji: '📋',
                  label: 'View Details',
                  color: primaryColor,
                  isDark: isDark,
                  onTap: onViewDetails,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionTile({
    required this.emoji,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
