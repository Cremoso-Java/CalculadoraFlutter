import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:math_expressions/math_expressions.dart';

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculator',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  bool darkMode = true;
  String input = '';
  String result = '';
  bool justCalculated = false;

  String? lastOperator;
  double? lastNumber;

  static const buttons = [
    'C', '+/-', '%', '÷',
    '7', '8', '9', 'x',
    '4', '5', '6', '-',
    '1', '2', '3', '+',
    '.', '0', 'DEL', '=',
  ];

  void changeTheme() {
    setState(() => darkMode = !darkMode);
    SystemChrome.setSystemUIOverlayStyle(
      darkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }

  void press(String value) {
    if (value == 'C') {
      clear();
      return;
    }

    if (value == 'DEL') {
      delete();
      return;
    }

    if (value == '+/-') {
      changeSign();
      return;
    }

    if (value == '=') {
      calculate();
      return;
    }

    setState(() {
      if (justCalculated) {
        if (_isOperator(value)) {
          input = result.replaceAll(',', '');
        } else {
          input = '';
        }
        result = '';
        justCalculated = false;
        lastOperator = null;
        lastNumber = null;
      }

      if (value == '.') {
        final currentNumber = input.split(RegExp(r'[+\-x÷%]')).last;
        if (currentNumber.contains('.')) return;
      }

      if (_isOperator(value) && input.isNotEmpty) {
        if (_isOperator(input[input.length - 1])) {
          input = input.substring(0, input.length - 1) + value;
          return;
        }
      }

      input += value;
    });
  }

  void clear() {
    setState(() {
      input = '';
      result = '';
      justCalculated = false;
      lastOperator = null;
      lastNumber = null;
    });
  }

  void delete() {
    if (input.isEmpty) return;

    setState(() {
      input = input.substring(0, input.length - 1);
      result = '';
      justCalculated = false;
    });
  }

  void changeSign() {
    if (input.isEmpty) return;

    final number = double.tryParse(input.replaceAll(',', ''));
    if (number == null) return;

    setState(() {
      input = number < 0
          ? _cleanNumber(number.abs())
          : '-${_cleanNumber(number)}';
      result = '';
      justCalculated = false;
    });
  }

  void calculate() {
    // Pressionar '=' novamente repete a última operação.
    // Ex.: 2 + 2 = 4, depois = -> 6, depois = -> 8.
    if (justCalculated && lastOperator != null && lastNumber != null) {
      final current = double.tryParse(result.replaceAll(',', ''));
      if (current != null) {
        final value = applyOperation(current, lastNumber!, lastOperator!);
        setState(() {
          result = formatResult(value);
          input = result.replaceAll(',', '');
        });
      }
      return;
    }

    if (input.isEmpty) return;

    try {
      final expression = input;
      var mathExpression = expression
          .replaceAll('x', '*')
          .replaceAll('÷', '/')
          .replaceAll('%', '/100');

      if (_isOperator(expression[expression.length - 1])) {
        mathExpression = mathExpression.substring(0, mathExpression.length - 1);
      }

      final parser = Parser();
      final parsed = parser.parse(mathExpression);
      final value = parsed.evaluate(EvaluationType.REAL, ContextModel());

      saveLastOperation(expression);

      setState(() {
        result = formatResult(value);
        justCalculated = true;
      });
    } catch (_) {
      setState(() {
        result = 'Erro';
        justCalculated = true;
        lastOperator = null;
        lastNumber = null;
      });
    }
  }

  void saveLastOperation(String expression) {
    final match = RegExp(r'([+\-x÷])(-?\d+(?:\.\d+)?)$').firstMatch(expression);

    if (match != null) {
      lastOperator = match.group(1);
      lastNumber = double.tryParse(match.group(2)!);
    } else {
      lastOperator = null;
      lastNumber = null;
    }
  }

  double applyOperation(double first, double second, String operator) {
    switch (operator) {
      case '+':
        return first + second;
      case '-':
        return first - second;
      case 'x':
        return first * second;
      case '÷':
        return second == 0 ? double.nan : first / second;
      default:
        return first;
    }
  }

  bool _isOperator(String value) {
    return value == '+' ||
        value == '-' ||
        value == 'x' ||
        value == '÷' ||
        value == '%';
  }

  String formatResult(double value) {
    if (value.isNaN || value.isInfinite) return 'Erro';

    if (value == value.roundToDouble()) {
      return formatThousands(value.toInt().toString());
    }

    var text = value.toStringAsFixed(8);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');

    final parts = text.split('.');
    return '${formatThousands(parts[0])}.${parts[1]}';
  }

  String formatThousands(String value) {
    final negative = value.startsWith('-');
    final digits = negative ? value.substring(1) : value;

    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

    return negative ? '-$formatted' : formatted;
  }

  String _cleanNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final background = darkMode
        ? const Color(0xFF111116)
        : const Color(0xFFF2F7F8);
    final keypadBackground = darkMode
        ? const Color(0xFF1B1B21)
        : const Color(0xFFE8EDEE);
    final numberButton = darkMode
        ? const Color(0xFF303037)
        : Colors.white;
    final functionButton = darkMode
        ? const Color(0xFF4A4A54)
        : const Color(0xFFD5D9DC);
    const operatorBlue = Color(0xFF4B5BFF);

    final primaryText = darkMode ? Colors.white : Colors.black;
    final secondaryText = darkMode
        ? const Color(0xFF74747C)
        : const Color(0xFF8A8A8F);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    buildThemeSwitch(),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        input,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 25,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          result.isEmpty ? '0' : result,
                          maxLines: 1,
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 58,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
                decoration: BoxDecoration(
                  color: keypadBackground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: buttons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 7,
                  ),
                  itemBuilder: (context, index) {
                    final label = buttons[index];
                    final isOperator = {'÷', 'x', '-', '+', '='}.contains(label);
                    final isFunction = {'C', '+/-', '%', 'DEL'}.contains(label);

                    return buildButton(
                      label,
                      isOperator ? operatorBlue : isFunction ? functionButton : numberButton,
                      isOperator
                          ? Colors.white
                          : isFunction
                              ? (darkMode ? Colors.white : const Color(0xFF202124))
                              : primaryText,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildThemeSwitch() {
    return GestureDetector(
      onTap: changeTheme,
      child: Container(
        width: 58,
        height: 31,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: darkMode ? const Color(0xFF303039) : const Color(0xFFD1D7DA),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: darkMode ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: darkMode ? const Color(0xFF50515A) : const Color(0xFFF9FAFA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              darkMode ? Icons.nightlight_round : Icons.wb_sunny_outlined,
              size: 15,
              color: const Color(0xFF6575FF),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildButton(String label, Color background, Color textColor) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () => press(label),
        borderRadius: BorderRadius.circular(15),
        child: Center(
          child: label == 'DEL'
              ? Icon(Icons.backspace_outlined, color: textColor, size: 19)
              : Text(
                  label == 'x' ? '×' : label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: label == '+/-' ? 18 : label == '÷' ? 26 : 25,
                    fontWeight: FontWeight.w400,
                  ),
                ),
        ),
      ),
    );
  }
}
