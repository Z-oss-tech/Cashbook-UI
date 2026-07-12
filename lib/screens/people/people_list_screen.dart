import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/record_provider.dart';
import '../records/cashbook_screen.dart';
import '../../core/utils/date_helper.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/widgets/theme_background_wrapper.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/premium_themes.dart';

class PeopleListScreen extends StatefulWidget {
  const PeopleListScreen({super.key});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  String searchQuery = "";
  String filterType = "All"; // All, Positive, Negative, Recent
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Helper to format currency
  String formatCurrencyNoDecimal(double amount) {
    final double absoluteAmount = amount.abs();
    String beforeDecimal = absoluteAmount.toStringAsFixed(0);

    if (beforeDecimal.length > 3) {
      String formatted = beforeDecimal.substring(beforeDecimal.length - 3);
      beforeDecimal = beforeDecimal.substring(0, beforeDecimal.length - 3);
      while (beforeDecimal.length > 2) {
        formatted =
            '${beforeDecimal.substring(beforeDecimal.length - 2)},$formatted';
        beforeDecimal = beforeDecimal.substring(0, beforeDecimal.length - 2);
      }
      formatted = '$beforeDecimal,$formatted';
      beforeDecimal = formatted;
    }
    return '₹ $beforeDecimal';
  }

  @override
  Widget build(BuildContext context) {
    final recordProvider = Provider.of<RecordProvider>(context);
    var cashbookList = recordProvider.cashbooks.where((book) {
      return book.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    // Apply Filters
    if (filterType == "Positive") {
      cashbookList = cashbookList.where((book) {
        final records = recordProvider.records.where(
          (r) => r.cashbookName == book.name,
        );
        final received = records
            .where((r) => !r.isGiven)
            .fold(0.0, (s, r) => s + r.amount);
        final given = records
            .where((r) => r.isGiven)
            .fold(0.0, (s, r) => s + r.amount);
        return (received - given) > 0;
      }).toList();
    } else if (filterType == "Negative") {
      cashbookList = cashbookList.where((book) {
        final records = recordProvider.records.where(
          (r) => r.cashbookName == book.name,
        );
        final received = records
            .where((r) => !r.isGiven)
            .fold(0.0, (s, r) => s + r.amount);
        final given = records
            .where((r) => r.isGiven)
            .fold(0.0, (s, r) => s + r.amount);
        return (received - given) < 0;
      }).toList();
    } else if (filterType == "Recent") {
      cashbookList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final isDark = _getIsDark(context);
    final _settings = Provider.of<SettingsProvider>(context, listen: false);
    final activePrimary = _settings.appTheme == 'Default' ? const Color(0xFF4143D5) : PremiumThemes.getTheme(_settings.appTheme).primaryColor;

    return ThemeBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        title: Text(
          "All Books",
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: RefreshIndicator(
        color: activePrimary,
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF464555)
                        : const Color(0xFFE6E8EA),
                  ),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search books...",
                    hintStyle: GoogleFonts.poppins(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    icon: Icon(
                      Icons.search,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ["All", "Positive", "Negative", "Recent"].map((
                    filter,
                  ) {
                    final isSelected = filterType == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          filter,
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: activePrimary,
                        backgroundColor: isDark
                            ? const Color(0xFF2D3133)
                            : const Color(0xFFF2F4F6),
                        onSelected: (selected) {
                          if (selected) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              filterType = filter;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic Cashbook Cards
              Expanded(
                child: cashbookList.isEmpty
                    ? FadeIn(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 80,
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No cashbooks found.",
                                style: GoogleFonts.inter(
                                  color: Theme.of(context).dividerColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: cashbookList.length,
                        itemBuilder: (context, index) {
                          final cashbook = cashbookList[index];
                          final name = cashbook.name;
                          final date = DateHelper.formatDateTime(
                            cashbook.createdAt,
                          );

                          // Calculate Balance
                          final records = recordProvider.records
                              .where((r) => r.cashbookName == name)
                              .toList();
                          final double received = records
                              .where((r) => !r.isGiven)
                              .fold(0, (s, r) => s + r.amount);
                          final double given = records
                              .where((r) => r.isGiven)
                              .fold(0, (s, r) => s + r.amount);
                          final double balance = received - given;
                          final bool isPositive = balance >= 0;

                          final int transactionCount = records.length;
                          String lastActivity = date;
                          if (records.isNotEmpty) {
                            // Sort by date just to be sure
                            records.sort((a, b) => a.date.compareTo(b.date));
                            final lastRecord = records.last;
                            lastActivity = DateHelper.formatDateTime(
                              lastRecord.date,
                            );
                          }

                          final String amountText =
                              "${isPositive ? '+' : '-'} ${formatCurrencyNoDecimal(balance)}";

                          return FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            delay: Duration(milliseconds: index * 50),
                            child: _buildBookCard(
                              id: cashbook.id,
                              name: name,
                              date: date,
                              lastActivity: lastActivity,
                              transactionCount: transactionCount,
                              amount: amountText,
                              isPositive: isPositive,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildBookCard({
    required String id,
    required String name,
    required String date,
    required String lastActivity,
    required int transactionCount,
    required String amount,
    required bool isPositive,
  }) {
    final isDark = _getIsDark(context);
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark
        ? const Color(0xFF464555)
        : const Color(0xFFE6E8EA);
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : const Color(0xFF0B1C30));
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF464555);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CashbookScreen(cashbookName: name),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEEF0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF5B5FEF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: subTextColor,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditDialog(id, name);
                              } else if (value == 'delete') {
                                _showDeleteDialog(id, name);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_rounded,
                                      size: 18,
                                      color: textColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Edit Name",
                                      style: TextStyle(color: textColor),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_rounded,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 14,
                            color: subTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$transactionCount Txns",
                            style: GoogleFonts.inter(
                              color: subTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: subTextColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "Activity: $lastActivity",
                              style: GoogleFonts.inter(
                                color: subTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE6E8EA), height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Net Balance",
                      style: GoogleFonts.inter(
                        color: subTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      amount,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isPositive
                            ? const Color(0xFF008339)
                            : const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF191C1E)
                        : const Color(0xFFF2F4F6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Details",
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: textColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String id, String currentName) {
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );
    showDialog(
      context: context,
      builder: (context) {
        final isDark = _getIsDark(context);
    final _settings = Provider.of<SettingsProvider>(context, listen: false);
    final activePrimary = _settings.appTheme == 'Default' ? const Color(0xFF4143D5) : PremiumThemes.getTheme(_settings.appTheme).primaryColor;
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Edit Cashbook",
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: "Cashbook Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: activePrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  Provider.of<RecordProvider>(
                    context,
                    listen: false,
                  ).updateCashbook(id, newName);
                }
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(String id, String name) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = _getIsDark(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Delete Cashbook",
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to delete '$name'? This action can be undone via Recovery Bin within 30 days.",
            style: GoogleFonts.inter(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Provider.of<RecordProvider>(
                  context,
                  listen: false,
                ).deleteCashbook(id);
                Navigator.pop(context);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _getIsDark(BuildContext context) {
    final appTheme = Provider.of<SettingsProvider>(context, listen: false).appTheme;
    if (appTheme == 'Default') {
      return Theme.of(context).brightness == Brightness.dark;
    }
    return PremiumThemes.getTheme(appTheme).themeData.brightness == Brightness.dark;
  }
}
