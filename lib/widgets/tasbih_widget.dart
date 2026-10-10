import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class TasbihWidget extends StatefulWidget {
  const TasbihWidget({super.key});

  @override
  State<TasbihWidget> createState() => _TasbihWidgetState();
}

class _TasbihWidgetState extends State<TasbihWidget> {
  int _count = 0;
  int _round = 0;

  void _increment() {
    setState(() {
      _count++;
      if (_count > 33) {
        _count = 1;
        _round++;
      }
    });
  }

  void _reset() {
    setState(() {
      _count = 0;
      _round = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Counter Display
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: CircularProgressIndicator(
                value: _count / 33,
                strokeWidth: 10,
                backgroundColor: Colors.white10,
                color: AppTheme.accentGold,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_count',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                    fontFamily: 'Amiri',
                  ),
                ),
                Text(
                  'الدورة: $_round',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontFamily: 'Amiri',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),

        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.2),
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
              child: const Text('إعادة', style: TextStyle(fontFamily: 'Amiri')),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: _increment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'تسبيح',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
