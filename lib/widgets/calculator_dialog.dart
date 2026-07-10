import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_colors.dart';

class CalculatorDialog extends StatefulWidget {
  final Function(String) onResult;

  const CalculatorDialog({super.key, required this.onResult});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _display = '';
  double _result = 0.0;
  String _operator = '';
  String _firstOperand = '';

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        _display = '';
        _firstOperand = '';
        _operator = '';
        _result = 0.0;
      } else if (buttonText == '+' ||
          buttonText == '-' ||
          buttonText == '*' ||
          buttonText == '/') {
        if (_display.isNotEmpty) {
          _firstOperand = _display;
          _operator = buttonText;
          _display = '';
        }
      } else if (buttonText == '=') {
        if (_firstOperand.isNotEmpty &&
            _display.isNotEmpty &&
            _operator.isNotEmpty) {
          double num1 = double.tryParse(_firstOperand) ?? 0.0;
          double num2 = double.tryParse(_display) ?? 0.0;
          switch (_operator) {
            case '+':
              _result = num1 + num2;
              break;
            case '-':
              _result = num1 - num2;
              break;
            case '*':
              _result = num1 * num2;
              break;
            case '/':
              _result = num2 != 0 ? num1 / num2 : 0.0;
              break;
          }
          // Remove decimal if integer
          _display = _result.toStringAsFixed(
            _result.truncateToDouble() == _result ? 0 : 2,
          );
          _firstOperand = '';
          _operator = '';
        }
      } else if (buttonText == 'Apply') {
        widget.onResult(_display);
        Navigator.pop(context);
      } else if (buttonText == '⌫') {
        if (_display.isNotEmpty) {
          _display = _display.substring(0, _display.length - 1);
        }
      } else {
        _display += buttonText;
      }
    });
  }

  Widget _buildButton(
    String text, {
    Color? color,
    Color? textColor,
    double width = 60,
    double height = 60,
    double fontSize = 24,
  }) {
    return GestureDetector(
      onTap: () => _onButtonPressed(text),
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Text(
                _display.isEmpty ? '0' : _display,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton('C', textColor: Colors.red),
                _buildButton('⌫', textColor: Colors.orange),
                _buildButton('/', textColor: Theme.of(context).primaryColor),
                _buildButton('*', textColor: Theme.of(context).primaryColor),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton('7'),
                _buildButton('8'),
                _buildButton('9'),
                _buildButton('-', textColor: Theme.of(context).primaryColor),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton('4'),
                _buildButton('5'),
                _buildButton('6'),
                _buildButton('+', textColor: Theme.of(context).primaryColor),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton('1'),
                _buildButton('2'),
                _buildButton('3'),
                _buildButton(
                  '=',
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton('0', width: 130),
                _buildButton('.'),
                _buildButton(
                  'Apply',
                  color: AppColors.success,
                  textColor: Colors.white,
                  fontSize: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
