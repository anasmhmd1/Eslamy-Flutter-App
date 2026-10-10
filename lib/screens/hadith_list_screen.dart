import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/hadith_service.dart';
import '../core/theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../core/utils/text_utils.dart';
import '../core/localization/app_localizations.dart';

class HadithListScreen extends StatefulWidget {
  final String bookId;
  final String bookName;

  const HadithListScreen({
    super.key,
    required this.bookId,
    required this.bookName,
  });

  @override
  State<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends State<HadithListScreen> {
  late Future<Map<String, dynamic>> _hadithFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _hadithFuture = Provider.of<HadithService>(
      context,
      listen: false,
    ).getHadiths(widget.bookId);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.bookName),
          centerTitle: true,
          backgroundColor: Colors.transparent,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _hadithFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${AppLocalizations.of(context).translate('error')}: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            final data = snapshot.data!;
            var hadiths = data['hadiths'] as List<dynamic>;

            // Filter broken/empty hadiths
            hadiths = hadiths.where((h) {
              return h['text'] != null &&
                  h['text'].toString().trim().isNotEmpty;
            }).toList();

            if (_searchQuery.isNotEmpty) {
              final normalizedQuery = TextUtils.removeDiacritics(_searchQuery);
              hadiths = hadiths.where((hadith) {
                final text = TextUtils.removeDiacritics(
                  hadith['text'].toString(),
                );
                final number = hadith['hadithnumber'].toString();
                return text.contains(normalizedQuery) ||
                    number.contains(normalizedQuery);
              }).toList();
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'بحث...',
                      hintStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: hadiths.length,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemBuilder: (context, index) {
                      final hadith = hadiths[index];
                      final grade =
                          (hadith['grade'] != null &&
                              hadith['grade'].isNotEmpty)
                          ? hadith['grade'][0]['grade']
                          : 'Unknown';
                      final localizedGrade = _localizeGrade(context, grade);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${AppLocalizations.of(context).translate('hadith_number')} ${hadith['hadithnumber']}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppTheme.accentGold,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  if (localizedGrade.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        localizedGrade,
                                        style: const TextStyle(
                                          color: Colors.lightGreenAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 10),
                              Text(
                                hadith['text'],
                                textAlign: TextAlign.justify,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 18,
                                  height: 1.8,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _localizeGrade(BuildContext context, String? grade) {
    if (grade == null) return '';
    final lowerGrade = grade.toLowerCase();
    if (lowerGrade.contains('sahih')) {
      return AppLocalizations.of(context).translate('grade_sahih');
    }
    if (lowerGrade.contains('hasan')) {
      return AppLocalizations.of(context).translate('grade_hasan');
    }
    if (lowerGrade.contains('daif') || lowerGrade.contains('weak')) {
      return AppLocalizations.of(context).translate('grade_daif');
    }
    if (lowerGrade.contains('unknown')) {
      return ''; // Look! Returning empty string for unknown
    }
    return grade; // Fallback to original if not matched or localized
  }
}
