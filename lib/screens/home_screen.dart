import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/prayer_service.dart';
import '../services/hadith_service.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';
import 'prayer_times_screen.dart';
import '../widgets/glass_container.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late Future<void> _initDataFuture;
  Map<String, dynamic>? _prayerTimes;
  late AnimationController _controller;
  late Animation<double> _animation;

  String? _errorMessage;
  Map<String, dynamic>? _randomHadith;

  @override
  void initState() {
    super.initState();
    _initDataFuture = _fetchData();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  Timer? _timer;
  String? _nextPrayerName;
  Duration? _timeRemaining;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _calculateNextPrayer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _calculateNextPrayer();
      }
    });
  }

  void _calculateNextPrayer() {
    if (_prayerTimes == null) return;

    final timings = _prayerTimes!['timings'];
    final now = DateTime.now();

    final prayers = {
      'Fajr': 'الفجر',
      'Dhuhr': 'الظهر',
      'Asr': 'العصر',
      'Maghrib': 'المغرب',
      'Isha': 'العشاء',
    };

    DateTime? nextPrayerTime;
    String? nextName;

    // Find first prayer after now
    for (var entry in prayers.entries) {
      final timeStr = timings[entry.key]; // "05:30 (EET)"
      if (timeStr == null) continue;

      final timeParts = timeStr.split(' ')[0].split(':');
      final h = int.parse(timeParts[0]);
      final m = int.parse(timeParts[1]);

      final prayerDate = DateTime(now.year, now.month, now.day, h, m);

      if (prayerDate.isAfter(now)) {
        nextPrayerTime = prayerDate;
        nextName = entry.value;
        break;
      }
    }

    // If no prayer found today (after Isha), next is Fajr tomorrow
    if (nextPrayerTime == null) {
      final timeStr = timings['Fajr'];
      final timeParts = timeStr.split(' ')[0].split(':');
      final h = int.parse(timeParts[0]);
      final m = int.parse(timeParts[1]);
      // Add 1 day
      nextPrayerTime = DateTime(
        now.year,
        now.month,
        now.day,
        h,
        m,
      ).add(const Duration(days: 1));
      nextName = 'الفجر';
    }

    setState(() {
      _nextPrayerName = nextName;
      _timeRemaining = nextPrayerTime!.difference(now);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _fetchData() async {
    try {
      final prayerService = Provider.of<PrayerService>(context, listen: false);
      final hadithService = Provider.of<HadithService>(context, listen: false);

      // 1. Get Location
      Position position = await _determinePosition();

      // 2. Fetch Prayer Times
      final prayerData = await prayerService.getPrayerTimes(
        position.latitude,
        position.longitude,
      );

      // 3. Schedule Notifications (Offline Support)
      // Calculate next 7 days locally using Adhan package
      final next7Days = await prayerService.getNext7DaysPrayerTimes(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        final notificationService = Provider.of<NotificationService>(
          context,
          listen: false,
        );
        // Verify permissions and prompt if needed
        await _checkNotificationPermissions(notificationService);

        notificationService.schedulePrayerTimes(next7Days);
      }

      // 3. Fetch Random Hadith
      final hadith = await hadithService.getRandomHadith();

      if (mounted) {
        setState(() {
          _prayerTimes = prayerData;
          _randomHadith = hadith;
          _startTimer();
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _errorMessage = 'تعذر تحديد الموقع. تأكد من تفعيل خدمة الموقع.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Simplify error message for user if possible
          if (e.toString().contains('Network Error') ||
              e.toString().contains('SocketException')) {
            _errorMessage = 'خطأ في الاتصال بالانترنت';
          } else {
            _errorMessage = e.toString();
          }
        });
      }
    }
  }

  Future<void> _checkNotificationPermissions(
    NotificationService notificationService,
  ) async {
    final hasPermission = await notificationService
        .checkNotificationPermission();
    if (!hasPermission && mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'تنبيهات الاذان',
            style: TextStyle(
              color: AppTheme.accentGold,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'قم بتفعيل الاشعارات حتي تتمكن من الاستماع للاذان في مواعيد الصلاة',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'حسناً',
                style: TextStyle(color: AppTheme.accentGold),
              ),
            ),
          ],
        ),
      );
      await notificationService.requestPermissions();
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        // Fallback or throw informative error
        // throwing error to be caught by _fetchData and show retry
        throw TimeoutException('Location request timed out');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Current Gregorian Date
    final String currentDate = DateFormat(
      'EEEE, d MMMM yyyy',
      'ar',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('نور'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.redAccent),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  '❤️ صدقة جارية',
                  style: TextStyle(
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                content: const Text(
                  'هذا التطبيق صدقة جارية على روح جدي\n\nمحمد\n\nرحمه الله وأسكنه فسيح جناته 🤲',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'الفاتحة',
                      style: TextStyle(color: AppTheme.accentGold),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initDataFuture = _fetchData();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: _initDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _prayerTimes == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_errorMessage != null && _prayerTimes == null) {
            return Center(
              child: Text(
                'خطأ: $_errorMessage',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: FadeTransition(
              opacity: _animation,
              child: ScaleTransition(
                scale: _animation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Date
                    Text(
                      currentDate,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    if (_prayerTimes?['date']?['hijri'] != null)
                      Text(
                        '${_prayerTimes!['date']['hijri']['day']} ${_prayerTimes!['date']['hijri']['month']['ar']} ${_prayerTimes!['date']['hijri']['year']}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 20),

                    // Prayer Times Card
                    if (_nextPrayerName != null && _timeRemaining != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppTheme.accentGold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'الصلاة القادمة: $_nextPrayerName',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _formatDuration(_timeRemaining!),
                              style: const TextStyle(
                                color: AppTheme.accentGold,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ],
                        ),
                      ),

                    _buildPrayerTimesCard(context),
                    const SizedBox(height: 20),

                    // Hadith Widget
                    if (_randomHadith != null) _buildHadithCard(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrayerTimesCard(BuildContext context) {
    if (_prayerTimes == null) return const SizedBox();

    final timings = _prayerTimes!['timings'];
    return GlassContainer(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrayerTimesScreen(prayerData: _prayerTimes!),
          ),
        );
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('prayer_times'),
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: AppTheme.accentGold),
              ),
              const Icon(Icons.access_time_filled, color: AppTheme.accentGold),
            ],
          ),
          const Divider(color: Colors.white24),
          _buildPrayerRow(
            context,
            AppLocalizations.of(context).translate('fajr'),
            timings['Fajr'],
          ),
          _buildPrayerRow(
            context,
            AppLocalizations.of(context).translate('dhuhr'),
            timings['Dhuhr'],
          ),
          _buildPrayerRow(
            context,
            AppLocalizations.of(context).translate('asr'),
            timings['Asr'],
          ),
          _buildPrayerRow(
            context,
            AppLocalizations.of(context).translate('maghrib'),
            timings['Maghrib'],
          ),
          _buildPrayerRow(
            context,
            AppLocalizations.of(context).translate('isha'),
            timings['Isha'],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              AppLocalizations.of(context).translate('tap_for_details'),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerRow(BuildContext context, String name, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            time.replaceAll(RegExp(r'[^0-9:]'), '').trim(),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHadithCard(BuildContext context) {
    // "Remove white box" -> make color transparent?
    return GlassContainer(
      color: Colors.transparent, // Trying to remove the white box effect
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('hadith_of_day'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.accentGold),
          ),
          const SizedBox(height: 10),
          Text(
            _randomHadith!['text'].toString(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '- ${(_randomHadith!['reference'] is Map) ? _randomHadith!['reference']['book'] : _randomHadith!['reference']}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
