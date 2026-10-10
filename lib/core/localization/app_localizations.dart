import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';

class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations(
      Provider.of<LocaleProvider>(context, listen: false).locale,
    );
  }

  final Locale locale;

  AppLocalizations(this.locale);

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Noor',
      'home': 'Home',
      'quran': 'Quran',
      'hadith': 'Hadith',
      'tools': 'Tools',
      'prayer_times': 'Prayer Times',
      'hadith_of_day': 'Hadith of the Day',
      'tap_for_details': 'Tap for details',
      'fajr': 'Fajr',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
      'qibla': 'Qibla',
      'tasbih': 'Tasbih',
      'align_arrow': 'Align arrow with the marker',
      'round': 'Round',
      'reset': 'Reset',
      'count': 'Count',
      'hadith_books': 'Hadith Books',
      'error': 'Error',
      'verses': 'Verses',
      'hadith_number': 'Hadith #',
      'grade_sahih': 'Sahih',
      'grade_hasan': 'Hasan',
      'grade_daif': 'Daif',
      'grade_unknown': 'Unknown',
    },
    'ar': {
      'app_title': 'نور',
      'home': 'الرئيسية',
      'quran': 'القرآن',
      'hadith': 'الحديث',
      'tools': 'الأدوات',
      'prayer_times': 'مواقيت الصلاة',
      'hadith_of_day': 'حديث اليوم',
      'tap_for_details': 'اضغط للمزيد من التفاصيل',
      'fajr': 'الفجر',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
      'qibla': 'القبلة',
      'tasbih': 'المسبحة',
      'align_arrow': 'حاذي السهم مع العلامة',
      'round': 'الدورة',
      'reset': 'إعادة',
      'count': 'تسبيح',
      'hadith_books': 'كتب الحديث',
      'error': 'خطأ',
      'verses': 'آية',
      'hadith_number': 'حديث رقم',
      'grade_sahih': 'صحيح',
      'grade_hasan': 'حسن',
      'grade_daif': 'ضعيف',
      'grade_unknown': 'غير معروف',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]![key] ?? key;
  }

  bool get isArabic => locale.languageCode == 'ar';
}
