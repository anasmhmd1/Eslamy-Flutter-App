import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/adhkar.dart';
import '../core/theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../services/adhkar_service.dart';

class AdhkarScreen extends StatefulWidget {
  final String title;
  final List<Adhkar> adhkarList;
  final bool isMorning;

  const AdhkarScreen({
    super.key,
    required this.title,
    required this.adhkarList,
    required this.isMorning,
  });

  @override
  State<AdhkarScreen> createState() => _AdhkarScreenState();
}

class _AdhkarScreenState extends State<AdhkarScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final savedProgress = await AdhkarService.loadProgress(
      isMorning: widget.isMorning,
    );

    if (savedProgress != null &&
        savedProgress.length == widget.adhkarList.length) {
      for (int i = 0; i < widget.adhkarList.length; i++) {
        widget.adhkarList[i].currentCount = savedProgress[i];
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProgress() async {
    final progress = widget.adhkarList.map((d) => d.currentCount).toList();
    await AdhkarService.saveProgress(
      isMorning: widget.isMorning,
      progress: progress,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: widget.adhkarList.length,
          itemBuilder: (context, index) {
            final dhikr = widget.adhkarList[index];
            final isCompleted = dhikr.currentCount >= dhikr.targetCount;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () async {
                  if (!isCompleted) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      dhikr.currentCount++;
                    });
                    await _saveProgress();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          dhikr.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Amiri',
                            color: isCompleted
                                ? Colors.greenAccent
                                : Colors.white,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Large Counter Circle
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.3),
                                border: Border.all(
                                  color: isCompleted
                                      ? Colors.greenAccent
                                      : AppTheme.accentGold,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${dhikr.currentCount}',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: isCompleted
                                            ? Colors.greenAccent
                                            : AppTheme.accentGold,
                                      ),
                                    ),
                                    Container(
                                      width: 30,
                                      height: 1,
                                      color: isCompleted
                                          ? Colors.greenAccent
                                          : AppTheme.accentGold,
                                    ),
                                    Text(
                                      '${dhikr.targetCount}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: isCompleted
                                            ? Colors.greenAccent.withValues(
                                                alpha: 0.7,
                                              )
                                            : Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
