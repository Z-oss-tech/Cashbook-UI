import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/record_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/animation_helper.dart';
import '../../core/utils/toast_helper.dart';

class VoiceEntryScreen extends StatefulWidget {
  const VoiceEntryScreen({super.key});

  @override
  State<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends State<VoiceEntryScreen> with TickerProviderStateMixin {
  bool isListening = false;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  String recognizedText = "";
  
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  String? parsedCashbook;
  double? parsedAmount;
  bool parsedIsGiven = true;
  String? parsedCategory;

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
      });
      _speechToText.listen(
        onResult: (result) {
          setState(() {
            recognizedText = result.recognizedWords;
            _parseSpeechText(recognizedText);
          });
        },
      );
    }
  }

  void _parseSpeechText(String text) {
    text = text.toLowerCase();
    
    // Find numbers for amount
    final amountMatch = RegExp(r'\d+').firstMatch(text);
    if (amountMatch != null) {
      parsedAmount = double.tryParse(amountMatch.group(0)!);
    }
    
    // Find transaction type
    if (text.contains('receive') || text.contains('got') || text.contains('liye') || text.contains('salary')) {
      parsedIsGiven = false;
    } else if (text.contains('give') || text.contains('gave') || text.contains('diye') || text.contains('paid')) {
      parsedIsGiven = true;
    }
    
    // Simple category inference
    if (text.contains('food') || text.contains('dinner') || text.contains('lunch') || text.contains('restaurant')) {
      parsedCategory = "Food & Dining";
    } else if (text.contains('rent') || text.contains('house')) {
      parsedCategory = "Housing";
    } else if (text.contains('salary')) {
      parsedCategory = "Income";
    } else if (text.contains('stock') || text.contains('investment')) {
      parsedCategory = "Investment";
    }

    // Basic cashbook extraction
    final words = text.split(' ');
    bool foundCashbook = false;
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      if (w == 'me' || w == 'in') {
        if (i > 0) {
          parsedCashbook = _capitalize(words[i-1]);
          foundCashbook = true;
          break;
        }
      }
    }
    
    if (!foundCashbook && words.isNotEmpty) {
      final stopWords = ['i', 'we', 'he', 'she', 'they', 'received', 'got', 'gave', 'paid', 'diye', 'liye', 'ko', 'se', 'me', 'in', 'for', 'to', 'from', 'a', 'the', 'my'];
      for (var w in words) {
        if (!stopWords.contains(w) && double.tryParse(w) == null && w.length > 2) {
          parsedCashbook = _capitalize(w);
          break;
        }
      }
    }
  }
  
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _saveRecord() async {
    if (parsedCashbook == null || parsedAmount == null) {
      ToastHelper.showToast(context, "Couldn't detect cashbook or amount correctly.", isError: true);
      return;
    }
    
    final recordProvider = Provider.of<RecordProvider>(context, listen: false);

    if (!recordProvider.cashbooks.any((c) => c.name.toLowerCase() == parsedCashbook!.toLowerCase())) {
      recordProvider.addCashbook(parsedCashbook!);
    }

    final cashbook = recordProvider.cashbooks.firstWhere(
      (c) => c.name.toLowerCase() == parsedCashbook!.toLowerCase(),
      orElse: () => recordProvider.cashbooks.isNotEmpty 
          ? recordProvider.cashbooks.first 
          : CashbookModel(id: '', name: parsedCashbook!, createdAt: DateTime.now())
    );

    final record = RecordModel(
      id: '',
      cashbookId: cashbook.id,
      title: parsedCategory ?? 'Voice Entry',
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
    AnimationHelper.showEmojiAnimation(context, isIncome: !parsedIsGiven, amount: parsedAmount!);

    setState(() {
      recognizedText = "";
      parsedAmount = null;
      parsedCashbook = null;
      parsedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isReadyToSave = parsedCashbook != null && parsedAmount != null;

    return Scaffold(
      backgroundColor: const Color(0xFF081028),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Atmospheric Mesh Gradient Background
          Positioned(
            top: -size.height * 0.2,
            left: -size.width * 0.3,
            child: Container(
              width: size.width * 1.5,
              height: size.height * 1.5,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6D5BFF).withValues(alpha: 0.15),
                    const Color(0xFF3CD7FF).withValues(alpha: 0.05),
                    const Color(0xFF081028).withValues(alpha: 0.0),
                  ],
                  radius: 0.8,
                  center: Alignment.center,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Smart Voice Assistant",
                                    style: GoogleFonts.geist(
                                      color: const Color(0xFFC6C0FF),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Finances at the speed of thought",
                                    style: GoogleFonts.inter(
                                      color: Colors.white54,
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3CD7FF),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "AI POWERED",
                              style: GoogleFonts.geist(
                                color: const Color(0xFF3CD7FF),
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
                            color: const Color(0xFFC8C4D8).withValues(alpha: 0.8),
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
                                        _buildPulseRing(280, _pulseController.value, 0.2),
                                        _buildPulseRing(220, (_pulseController.value + 0.5) % 1.0, 0.4),
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
                                      offset: Offset(0, isListening ? 0 : -10 * _floatController.value),
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF6D5BFF), Color(0xFF3CD7FF)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF6D5BFF).withValues(alpha: 0.4),
                                              blurRadius: isListening ? 40 : 20,
                                              spreadRadius: isListening ? 10 : 0,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          isListening ? Icons.mic : Icons.mic_none_rounded,
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
                            Icon(Icons.mic, color: const Color(0xFF3CD7FF), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              isListening ? "Listening..." : "Tap to speak",
                              style: GoogleFonts.geist(
                                color: const Color(0xFF3CD7FF),
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
                                  child: _buildGlassContainer(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: Text(
                                        recognizedText,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            ),
                          ),

                        const SizedBox(height: 40),

                        // AI Understanding Grid
                        if (isReadyToSave || parsedCashbook != null || parsedAmount != null)
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
                                iconColor: const Color(0xFFC6C0FF),
                                title: "CASHBOOK NAME",
                                value: parsedCashbook ?? "Searching...",
                              ),
                              _buildGridItem(
                                icon: Icons.payments,
                                iconColor: const Color(0xFF3CD7FF),
                                title: "AMOUNT",
                                value: parsedAmount != null ? "₹${parsedAmount!.toStringAsFixed(2)}" : "Searching...",
                              ),
                              _buildGridItem(
                                icon: Icons.restaurant,
                                iconColor: const Color(0xFFD0BCFF),
                                title: "CATEGORY",
                                value: parsedCategory ?? "Uncategorized",
                              ),
                              _buildGridItem(
                                icon: Icons.account_balance_wallet,
                                iconColor: const Color(0xFF3CD7FF),
                                title: "TYPE",
                                value: parsedIsGiven ? "Expense" : "Income",
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
                                _buildSuggestionChip('Try: "Received salary 50000"'),
                                _buildSuggestionChip('Try: "Paid Rent 15000"'),
                                _buildSuggestionChip('Try: "Stock investment 2000"'),
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
                            ? const LinearGradient(
                                colors: [Color(0xFF6D5BFF), Color(0xFF3CD7FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
                              ),
                        boxShadow: isReadyToSave
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6D5BFF).withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 0),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: isReadyToSave ? Colors.white : Colors.white54,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Save Transaction",
                            style: GoogleFonts.geist(
                              color: isReadyToSave ? Colors.white : Colors.white54,
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
        ],
      ),
    );
  }

  Widget _buildPulseRing(double maxSize, double progress, double startOpacity) {
    return Transform.scale(
      scale: progress * 1.5,
      child: Container(
        width: maxSize,
        height: maxSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF6D5BFF).withValues(alpha: startOpacity * (1 - progress)),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return _buildGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
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
                  style: GoogleFonts.geist(
                    color: const Color(0xFFC8C4D8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.geist(
                    color: Colors.white,
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

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _buildGlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.geist(
              color: const Color(0xFFC8C4D8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}