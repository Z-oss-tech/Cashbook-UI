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
  State<VoiceEntryScreen> createState() =>
      _VoiceEntryScreenState();
}

class _VoiceEntryScreenState
    extends State<VoiceEntryScreen>
    with SingleTickerProviderStateMixin {

  bool isListening = false;
  late AnimationController _controller;
  String recognizedText = "Tap the mic and start speaking...";
  
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  String? parsedCashbook;
  double? parsedAmount;
  bool parsedIsGiven = true;

  @override
  void initState() {
    super.initState();
    _initSpeech();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.8,
      upperBound: 1.1,
    )..repeat(reverse: true);
  }

  void _initSpeech() async {
    await _speechToText.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
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
        if (recognizedText.isEmpty || recognizedText == "Listening...") {
          recognizedText = "Tap the mic and start speaking...";
        }
      });
    } else {
      setState(() {
        isListening = true;
        recognizedText = "Listening...";
        parsedCashbook = null;
        parsedAmount = null;
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
    if (text.contains('receive') || text.contains('got') || text.contains('liye')) {
      parsedIsGiven = false;
    } else if (text.contains('give') || text.contains('gave') || text.contains('diye') || text.contains('paid')) {
      parsedIsGiven = true;
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
      final stopWords = ['i', 'we', 'he', 'she', 'they', 'received', 'got', 'gave', 'paid', 'diye', 'liye', 'ko', 'se', 'me', 'in', 'for', 'to', 'from'];
      for (var w in words) {
        if (!stopWords.contains(w) && double.tryParse(w) == null && w.length > 1) {
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

    // If cashbook doesn't exist, create it
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
      title: 'Voice Entry',
      amount: parsedAmount!,
      type: parsedIsGiven ? 'expense' : 'income',
      note: "Added via Voice",
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
      recognizedText = "Tap the mic and start speaking...";
      parsedAmount = null;
      parsedCashbook = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)], // Deep premium dark theme
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header
                          Text(
                            "Smart Voice Entry",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Speak naturally and let AI handle the records.",
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const Spacer(),
                          
                          // Animated Mic Area
                          SizedBox(
                            height: 240,
                            child: Center(
                              child: AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (isListening) ...[
                                        _buildRipple(240, _controller.value * 1.5, 0.1),
                                        _buildRipple(200, _controller.value * 1.2, 0.2),
                                      ],
                                      GestureDetector(
                                        onTap: toggleListening,
                                        child: Container(
                                          height: 120,
                                          width: 120,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: isListening
                                                  ? [Colors.redAccent, Colors.red]
                                                  : [AppColors.primary, AppColors.secondary],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (isListening ? Colors.red : AppColors.primary).withValues(alpha: 0.6),
                                                blurRadius: 30,
                                                spreadRadius: isListening ? 15 : 5,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            isListening ? Icons.mic : Icons.mic_none_rounded,
                                            size: 50,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Listening Text
                          Text(
                            isListening ? "Listening..." : "Tap to Speak",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Try: “TestBook me 500 diye”",
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Glassmorphic Preview
                          if (recognizedText != "Tap the mic and start speaking...")
                            _buildGlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "AI Detected",
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    recognizedText,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      height: 1.5,
                                      fontStyle: isListening ? FontStyle.italic : FontStyle.normal,
                                    ),
                                  ),
                                  if (parsedCashbook != null || parsedAmount != null) ...[
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      child: Divider(color: Colors.white24, height: 1),
                                    ),
                                    _buildInfoRow("Cashbook", parsedCashbook ?? "Searching..."),
                                    const SizedBox(height: 12),
                                    _buildInfoRow("Amount", parsedAmount != null ? "₹${parsedAmount!.toStringAsFixed(0)}" : "Searching..."),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      "Type", 
                                      parsedIsGiven ? "Given (-)" : "Received (+)",
                                      color: parsedIsGiven ? Colors.redAccent : Colors.greenAccent,
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          
                          const Spacer(),
                          
                          // Save Button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: (parsedCashbook != null && parsedAmount != null)
                                    ? [const Color(0xFF10B981), const Color(0xFF059669)] // Vibrant Green
                                    : [Colors.grey.shade800, Colors.grey.shade900], // Disabled state
                              ),
                              boxShadow: (parsedCashbook != null && parsedAmount != null)
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      )
                                    ]
                                  : null,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: (parsedCashbook != null && parsedAmount != null) ? _saveRecord : null,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    (parsedCashbook != null && parsedAmount != null) ? Icons.check_circle_outline : Icons.mic_off,
                                    color: (parsedCashbook != null && parsedAmount != null) ? Colors.white : Colors.white54,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Save Record",
                                    style: GoogleFonts.outfit(
                                      color: (parsedCashbook != null && parsedAmount != null) ? Colors.white : Colors.white54,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRipple(double size, double scale, double opacity) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.redAccent.withValues(alpha: opacity),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white60,
            fontSize: 15,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}