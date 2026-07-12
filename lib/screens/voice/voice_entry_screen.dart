// import 'dart:ui'; removed
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';

import '../../providers/record_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/animation_helper.dart';
import '../../core/utils/toast_helper.dart';
import '../../core/widgets/theme_background_wrapper.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/theme/premium_themes.dart';

class VoiceEntryScreen extends StatefulWidget {
  const VoiceEntryScreen({super.key});

  @override
  State<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends State<VoiceEntryScreen>
    with TickerProviderStateMixin {
  bool isListening = false;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  String recognizedText = "";

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  String? parsedCashbook;
  double? parsedAmount;
  bool parsedIsGiven = true;
  String? parsedCategory;
  String? parsedTitle;

  @override
  void initState() {
    super.initState();
    _initSpeech();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: false);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  void _initSpeech() async {
    await _speechToText.initialize();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _speechToText.cancel();
    super.dispose();
  }

  void toggleListening() async {
    if (!_speechToText.isAvailable) {
      await _speechToText.initialize();
    }

    if (isListening) {
      _speechToText.stop();
      setState(() {
        isListening = false;
        if (recognizedText.isEmpty) {
          recognizedText = "";
        }
      });
    } else {
      setState(() {
        isListening = true;
        recognizedText = "";
        parsedCashbook = null;
        parsedAmount = null;
        parsedCategory = null;
        parsedTitle = null;
      });
      _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            final cashbooks = Provider.of<RecordProvider>(
              context,
              listen: false,
            ).cashbooks;
            setState(() {
              recognizedText = result.recognizedWords;
              _parseSpeechText(recognizedText, cashbooks);
            });
          }
        },
      );
    }
  }

  void _parseSpeechText(String text, List<CashbookModel> existingCashbooks) {
    // Normalize text: remove punctuation and extra spaces
    final normalizedText = text.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
    final words = normalizedText.split(RegExp(r'\s+'));

    // 1. AMOUNT
    final amountMatch = RegExp(r'\d+([.,]\d+)?').firstMatch(text);
    if (amountMatch != null) {
      parsedAmount = double.tryParse(amountMatch.group(0)!.replaceAll(',', ''));
    }

    // 2. EXPENSE/INCOME
    final incomeWords = [
      'receive', 'received', 'got', 'liye', 'mila', 'aaye', 'income',
      'credit', 'deposit', 'earn', 'earned', 'aaya', 'mile', 'liya',
      'add', 'added', 'jama', 'in', 'daale'
    ];
    final expenseWords = [
      'give', 'gave', 'paid', 'diye', 'diya', 'gaye', 'kharch',
      'expense', 'debit', 'spend', 'spent', 'sent', 'bheje', 'de',
      'kharcha', 'kharacha', 'nikale', 'pay', 'cut', 'minus', 'out', 'nikala'
    ];

    int incomeScore = 0;
    int expenseScore = 0;
    for (var w in words) {
      if (incomeWords.contains(w)) incomeScore++;
      if (expenseWords.contains(w)) expenseScore++;
    }

    if (incomeScore > expenseScore) {
      parsedIsGiven = false;
    } else if (expenseScore > incomeScore) {
      parsedIsGiven = true;
    } else {
      parsedIsGiven = true; // Default to expense
    }

    // 3. CASHBOOK
    parsedCashbook = null;
    final textNoSpaces = normalizedText.replaceAll(' ', '');

    // Look for exact cashbook name first or without spaces
    for (var cb in existingCashbooks) {
      final cbNameLower = cb.name.toLowerCase();
      if (normalizedText.contains(cbNameLower)) {
        parsedCashbook = cb.name;
        break;
      }
      final cbNameNoSpaces = cbNameLower.replaceAll(' ', '');
      if (textNoSpaces.contains(cbNameNoSpaces)) {
        parsedCashbook = cb.name;
        break;
      }
    }
    
    // If not found, check if they said "cashbook", "khata", "book", "account", use the word before it.
    if (parsedCashbook == null) {
      final bookKeywords = ['cashbook', 'khata', 'book', 'account'];
      int keywordIndex = -1;
      for (var i = 0; i < words.length; i++) {
        if (bookKeywords.contains(words[i])) {
          keywordIndex = i;
          break;
        }
      }

      if (keywordIndex > 0) {
        parsedCashbook = _capitalize(words[keywordIndex - 1]);
      } else if (keywordIndex == 0 && words.length > 1) {
        parsedCashbook = _capitalize(words[1]);
      }
    }

    // 4. CATEGORY AND TITLE
    parsedCategory = null;
    parsedTitle = null;

    final categoryMap = {
      "Food & Dining": [
        'food', 'dinner', 'lunch', 'restaurant', 'khana', 'pizza',
        'burger', 'chai', 'coffee', 'nashta', 'snack'
      ],
      "Housing": [
        'rent', 'house', 'kiraya', 'room', 'flat', 'electricity',
        'bijli', 'water', 'pani'
      ],
      "Income": ['salary', 'tankha', 'kamai', 'profit', 'bonus'],
      "Investment": ['stock', 'investment', 'share', 'mutual', 'crypto', 'fd'],
      "Transport": [
        'travel', 'bus', 'train', 'flight', 'auto', 'cab', 'uber',
        'ola', 'petrol', 'diesel', 'fuel'
      ],
      "Shopping": [
        'shop', 'shopping', 'kapde', 'clothes', 'buy', 'bought',
        'kharida', 'shoes'
      ],
    };

    for (var cat in categoryMap.keys) {
      if (categoryMap[cat]!.any((w) => words.contains(w))) {
        parsedCategory = cat;
        break;
      }
    }

    // Identify the TITLE
    final stopWords = [
      'i', 'we', 'he', 'she', 'they', 'ko', 'se', 'me', 'in', 'for', 'to',
      'from', 'a', 'the', 'my', 'and', 'of', 'on', 'rupees', 'rs', 'bucks',
      'cashbook', 'khata', 'book', 'account', 'ke', 'ka', 'ki', 'mein'
    ];
    List<String> leftoverWords = [];

    for (var w in words) {
      if (w.isEmpty) continue;
      if (RegExp(r'\d+').hasMatch(w)) continue; // skip numbers
      if (incomeWords.contains(w) || expenseWords.contains(w) || stopWords.contains(w)) continue;
      
      if (parsedCashbook != null) {
        if (w == parsedCashbook!.toLowerCase() || parsedCashbook!.toLowerCase().split(' ').contains(w)) {
           continue;
        }
      }

      bool isCatWord = false;
      if (parsedCategory != null && categoryMap[parsedCategory]!.contains(w)) {
        isCatWord = true;
      }
      if (isCatWord) continue;

      leftoverWords.add(_capitalize(w));
    }

    if (leftoverWords.isNotEmpty) {
      parsedTitle = leftoverWords.join(' ');
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _saveRecord() async {
    if (parsedCashbook == null || parsedAmount == null) {
      ToastHelper.showToast(
        context,
        "Couldn't detect cashbook or amount correctly.",
        isError: true,
      );
      return;
    }

    final recordProvider = Provider.of<RecordProvider>(context, listen: false);

    if (!recordProvider.cashbooks.any(
      (c) => c.name.toLowerCase() == parsedCashbook!.toLowerCase(),
    )) {
      recordProvider.addCashbook(parsedCashbook!);
    }

    final cashbook = recordProvider.cashbooks.firstWhere(
      (c) => c.name.toLowerCase() == parsedCashbook!.toLowerCase(),
      orElse: () => recordProvider.cashbooks.isNotEmpty
          ? recordProvider.cashbooks.first
          : CashbookModel(
              id: '',
              name: parsedCashbook!,
              createdAt: DateTime.now(),
            ),
    );

    final record = RecordModel(
      id: '',
      cashbookId: cashbook.id,
      title: parsedTitle ?? parsedCategory ?? 'Voice Entry',
      amount: parsedAmount!,
      type: parsedIsGiven ? 'expense' : 'income',
      note: "Added via AI Voice",
      date: DateTime.now(),
      cashbookName: parsedCashbook!,
    );

    await recordProvider.addRecord(record);

    if (!mounted) return;

    if (recordProvider.error != null) {
      ToastHelper.showToast(context, recordProvider.error!, isError: true);
      return;
    }

    ToastHelper.showToast(context, "Record saved successfully!");
    AnimationHelper.showEmojiAnimation(
      context,
      isIncome: !parsedIsGiven,
      amount: parsedAmount!,
    );

    setState(() {
      recognizedText = "";
      parsedAmount = null;
      parsedCashbook = null;
      parsedCategory = null;
      parsedTitle = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final premiumTheme = PremiumThemes.getTheme(settings.appTheme);
    final isDefault = settings.appTheme == 'Default';

    final primaryColor = isDefault
        ? const Color(0xFF6D5BFF)
        : premiumTheme.primaryColor;
    final secondaryColor = isDefault
        ? const Color(0xFF3CD7FF)
        : premiumTheme.gradient.colors.last;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF191C1E);
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;

    final isReadyToSave = parsedCashbook != null && parsedAmount != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: ThemeBackgroundWrapper(
        child: SafeArea(
          child: Column(
            children: [
              // Top App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: textColor,
                            ),
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Smart Voice Assistant",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Finances at the speed of thought",
                                  style: GoogleFonts.manrope(
                                    color: subtitleColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.04),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "AI POWERED",
                            style: GoogleFonts.plusJakartaSans(
                              color: secondaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Speak naturally and let AI organize your finances automatically",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: subtitleColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 3D Mic Asset / Orb
                      SizedBox(
                        height: 280,
                        width: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse Rings
                            if (isListening)
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      _buildPulseRing(
                                        280,
                                        _pulseController.value,
                                        0.2,
                                        primaryColor,
                                      ),
                                      _buildPulseRing(
                                        220,
                                        (_pulseController.value + 0.5) % 1.0,
                                        0.4,
                                        primaryColor,
                                      ),
                                    ],
                                  );
                                },
                              ),

                            // The Orb
                            GestureDetector(
                              onTap: toggleListening,
                              child: AnimatedBuilder(
                                animation: _floatController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(
                                      0,
                                      isListening
                                          ? 0
                                          : -10 * _floatController.value,
                                    ),
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            primaryColor,
                                            secondaryColor,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: isListening ? 40 : 20,
                                            spreadRadius: isListening ? 10 : 0,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isListening
                                            ? Icons.mic
                                            : Icons.mic_none_rounded,
                                        color: Colors.white,
                                        size: 56,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Listening Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mic, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isListening ? "Listening..." : "Tap to speak",
                            style: GoogleFonts.plusJakartaSans(
                              color: primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // Transcript Card
                      if (recognizedText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: AnimatedBuilder(
                            animation: _floatController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, -5 * _floatController.value),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: Text(
                                      recognizedText,
                                      style: GoogleFonts.inter(
                                        color: textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 40),

                      // AI Understanding Grid
                      if (isReadyToSave ||
                          parsedCashbook != null ||
                          parsedAmount != null)
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 2.2,
                          children: [
                            _buildGridItem(
                              icon: Icons.person,
                              iconColor: primaryColor,
                              title: "CASHBOOK NAME",
                              value: parsedCashbook ?? "Searching...",
                              isDark: isDark,
                            ),
                            _buildGridItem(
                              icon: Icons.payments,
                              iconColor: secondaryColor,
                              title: "AMOUNT",
                              value: parsedAmount != null
                                  ? "₹${parsedAmount!.toStringAsFixed(2)}"
                                  : "Searching...",
                              isDark: isDark,
                            ),
                            _buildGridItem(
                              icon: Icons.restaurant,
                              iconColor: primaryColor,
                              title: "CATEGORY",
                              value: parsedCategory ?? "Uncategorized",
                              isDark: isDark,
                            ),
                            _buildGridItem(
                              icon: Icons.account_balance_wallet,
                              iconColor: secondaryColor,
                              title: "TYPE",
                              value: parsedIsGiven ? "Expense" : "Income",
                              isDark: isDark,
                            ),
                          ],
                        ),

                      const SizedBox(height: 40),

                      // Voice Suggestions
                      if (recognizedText.isEmpty && !isListening)
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildSuggestionChip(
                                'Try: "Received salary 50000 in General book"',
                                isDark,
                              ),
                              _buildSuggestionChip(
                                'Try: "Paid 15000 for rent from personal account"',
                                isDark,
                              ),
                              _buildSuggestionChip(
                                'Try: "Bought pizza for 500 in food khata"',
                                isDark,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Save Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: InkWell(
                  onTap: isReadyToSave ? _saveRecord : null,
                  borderRadius: BorderRadius.circular(30),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: isReadyToSave
                          ? LinearGradient(
                              colors: [primaryColor, secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05),
                                Theme.of(
                                  context,
                                ).cardColor.withValues(alpha: 0.5),
                              ],
                            ),
                      boxShadow: isReadyToSave
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 0),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: isReadyToSave
                              ? Colors.white
                              : (isDark ? Colors.white54 : Colors.black38),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Save Transaction",
                          style: GoogleFonts.plusJakartaSans(
                            color: isReadyToSave
                                ? Colors.white
                                : (isDark ? Colors.white54 : Colors.black38),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseRing(
    double maxSize,
    double progress,
    double startOpacity,
    Color primaryColor,
  ) {
    return Transform.scale(
      scale: progress * 1.5,
      child: Container(
        width: maxSize,
        height: maxSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: primaryColor.withValues(
              alpha: startOpacity * (1 - progress),
            ),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 20,
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
