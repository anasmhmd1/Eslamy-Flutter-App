import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/app_theme.dart';
import 'triangle_painter.dart';

class QiblaCompassWidget extends StatefulWidget {
  const QiblaCompassWidget({super.key});

  @override
  State<QiblaCompassWidget> createState() => _QiblaCompassWidgetState();
}

class _QiblaCompassWidgetState extends State<QiblaCompassWidget> {
  double? _direction;
  double _qiblaBearing = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initQibla();
  }

  Future<void> _initQibla() async {
    try {
      // 1. Check Service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _error = "الموقع غير مفعل");
        return;
      }

      // 2. Check Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          // Show explanation dialog
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                'تحديد القبلة',
                style: TextStyle(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: const Text(
                'قم بتفعيل الموقع لتحديد اتجاه القبلة بدقة',
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

          // Request Permission
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            setState(() => _error = "تم رفض صلاحية الموقع");
            return;
          }
        }
      }

      // 3. Get Location
      Position position = await Geolocator.getCurrentPosition();

      // 4. Calculate Qibla Bearing
      // Kaaba Coordinates: 21.4225° N, 39.8262° E
      double lat = position.latitude;
      double lng = position.longitude;
      _qiblaBearing = _calculateBearing(lat, lng, 21.4225, 39.8262);

      // 5. Listen to Compass
      FlutterCompass.events?.listen((CompassEvent event) {
        if (mounted) {
          setState(() {
            _direction = event.heading;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error: $e";
        });
      }
    }
  }

  // Formula to calculate bearing from A to B
  double _calculateBearing(
    double startLat,
    double startLng,
    double destLat,
    double destLng,
  ) {
    var startLatRad = startLat * (math.pi / 180.0);
    var startLngRad = startLng * (math.pi / 180.0);
    var destLatRad = destLat * (math.pi / 180.0);
    var destLngRad = destLng * (math.pi / 180.0);

    var y = math.sin(destLngRad - startLngRad) * math.cos(destLatRad);
    var x =
        math.cos(startLatRad) * math.sin(destLatRad) -
        math.sin(startLatRad) *
            math.cos(destLatRad) *
            math.cos(destLngRad - startLngRad);

    var bearingRad = math.atan2(y, x);
    var bearingDegrees = bearingRad * (180.0 / math.pi);

    // Normalize to 0-360
    return (bearingDegrees + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_direction == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Compass graphic rotation
    // We want the compass to rotate so North points to actual North.
    // AND we want an arrow pointing to Qibla.

    // Actually, simpler UI: Rotate the WHOLE compass so 0 is up (North)? No, phone rotates.
    // Usual implementation:
    // Background Image: Compass Rose (Fixed to phone? No, rotates with North).
    // Needle: Points to Qibla?

    // Let's rotate the compass ROSE based on -heading (so valid North is up).
    // Then place Qibla marker at `_qiblaBearing`.

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "${_direction!.toStringAsFixed(0)}°",
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text("القبلة: ${_qiblaBearing.toStringAsFixed(0)}°"),
        const SizedBox(height: 30),
        SizedBox(
          height: 300,
          width: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Fixed Ring with Cardinal Directions (Rotates with phone so North is correct? No, simple Qibla pointer usually rotates the arrow)
              // Wait, if I want to point to Qibla:
              // Arrow Angle = Qibla Bearing - Phone Heading.
              // If I face Qibla, Arrow Angle = 0 (Up).
              // Let's visualize:
              // Heading = 0 (North). Qibla = 135. Arrow should point 135 (Right-Down).
              // Heading = 135 (Facing Qibla). Arrow should point 0 (Up).
              // So Angle = Qibla - Heading.

              // Background Ring
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white10, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),

              // Decorative ticks
              for (int i = 0; i < 12; i++)
                Transform.rotate(
                  angle: (i * 30) * (math.pi / 180),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: i % 3 == 0 ? 15 : 8,
                      width: i % 3 == 0 ? 4 : 2,
                      color: i % 3 == 0 ? AppTheme.accentGold : Colors.white24,
                      margin: const EdgeInsets.only(top: 10),
                    ),
                  ),
                ),

              // 3. Rotating Kaaba Indicator
              // This rotates so it points to Qibla relative to phone heading.
              Transform.rotate(
                angle: ((_qiblaBearing - (_direction ?? 0)) * (math.pi / 180)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The Kaaba Widget
                    Container(
                      width: 40,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white24, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Gold Band
                          Positioned(
                            top: 12,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 8,
                              color: AppTheme.accentGold,
                            ),
                          ),
                          // Door (Optional detail)
                          Positioned(
                            bottom: 8,
                            right: 6,
                            child: Container(
                              width: 10,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppTheme.accentGold,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(2),
                                  topRight: Radius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Small Arrow pointing up from Kaaba to indicate alignment direction
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: CustomPaint(
                        size: const Size(12, 6),
                        painter: TrianglePainter(color: AppTheme.accentGold),
                      ),
                    ),

                    const SizedBox(
                      height: 200,
                    ), // Spacing to push Kaaba to the rim
                  ],
                ),
              ),

              // 4. Fixed Alignment Triangle (The Target)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 5), // Overlap/near ring
                  child: Icon(
                    Icons
                        .arrow_drop_down, // Upside down triangle pointing to center
                    size: 40,
                    color: Colors.white,
                    shadows: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),

              // Center Dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.accentGold,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text("حاذي الكعبة مع المثلث"),
      ],
    );
  }
}
