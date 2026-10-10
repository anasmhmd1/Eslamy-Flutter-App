import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

class PrayerService {
  // Offline Calculation using 'adhan' package

  Future<Map<String, dynamic>> getPrayerTimes(double lat, double long) async {
    final myCoordinates = Coordinates(lat, long);
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;

    final now = DateTime.now();
    final date = DateComponents(now.year, now.month, now.day);

    final prayerTimes = PrayerTimes(myCoordinates, date, params);

    // Format for the app (matching the previous structure roughly or adapting UI)
    // The previous app used "transliterated" names in the map from API.
    // We will return a map that the UI expects.
    // UI expects: Map with 'timings' key -> Map of "Fajr": "HH:mm"

    return {
      'date': {
        'gregorian': {'date': DateFormat('dd-MM-yyyy').format(now)},
      },
      'timings': {
        'Fajr': DateFormat('HH:mm').format(prayerTimes.fajr),
        'Sunrise': DateFormat('HH:mm').format(prayerTimes.sunrise),
        'Dhuhr': DateFormat('HH:mm').format(prayerTimes.dhuhr),
        'Asr': DateFormat('HH:mm').format(prayerTimes.asr),
        'Maghrib': DateFormat('HH:mm').format(prayerTimes.maghrib),
        'Isha': DateFormat('HH:mm').format(prayerTimes.isha),
      },
      'meta': {'method': 'Egyptian General Authority of Survey (Offline)'},
    };
  }

  // Get next 7 days data for Notification scheduling
  Future<List<Map<String, dynamic>>> getNext7DaysPrayerTimes(
    double lat,
    double long,
  ) async {
    final myCoordinates = Coordinates(lat, long);
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;

    List<Map<String, dynamic>> days = [];
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final components = DateComponents(date.year, date.month, date.day);
      final prayerTimes = PrayerTimes(myCoordinates, components, params);

      days.add({
        'date': {
          'gregorian': {'date': DateFormat('dd-MM-yyyy').format(date)},
        },
        'timings': {
          'Fajr': DateFormat('HH:mm').format(prayerTimes.fajr),
          'Dhuhr': DateFormat('HH:mm').format(prayerTimes.dhuhr),
          'Asr': DateFormat('HH:mm').format(prayerTimes.asr),
          'Maghrib': DateFormat('HH:mm').format(prayerTimes.maghrib),
          'Isha': DateFormat('HH:mm').format(prayerTimes.isha),
        },
      });
    }
    return days;
  }

  Future<Map<String, dynamic>> getQiblaDirection(
    double lat,
    double long,
  ) async {
    // Qibla calc is also in Adhan package!
    final qibla = Qibla(Coordinates(lat, long));
    return {'direction': qibla.direction};
  }

  // Legacy method signature to avoid breaking callers, but now we don't cache month data the same way.
  // Or current callers might call getCachedMonthData.
  Future<List<dynamic>> getCachedMonthData() async {
    return []; // No longer needed for logic, returning empty.
  }
}
