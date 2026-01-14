import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      isForegroundMode: true,
      autoStart: false,
      foregroundServiceNotificationId: 888,
      initialNotificationTitle: 'Bus Tracking Active',
      initialNotificationContent: 'Sharing live bus location',
    ),
    iosConfiguration: IosConfiguration(
      onForeground: _onStart,
      onBackground: _onIosBackground,
      autoStart: false,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  await Firebase.initializeApp();
  return true;
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  await Firebase.initializeApp();
  final database = FirebaseDatabase.instance;

  String? busId;
  String? tripId;
  String? routeId;
  bool isActive = false;
  StreamSubscription<Position>? positionSub;
  DateTime lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  void updateNotification() {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: isActive ? 'Trip in progress' : 'Trip stopped',
        content: busId != null
            ? 'Bus $busId sending location'
            : 'Waiting for trip start',
      );
    }
  }

  Future<void> stopTracking() async {
    await positionSub?.cancel();
    positionSub = null;
    isActive = false;
    if (busId != null) {
      await database.ref('buses/$busId/live').update({
        'isActive': false,
        'updatedAt': ServerValue.timestamp,
      });
    }
    updateNotification();
  }

  Future<void> startTracking(Map<String, dynamic> data) async {
    busId = data['busId'] as String?;
    routeId = data['routeId'] as String?;
    tripId = data['tripId'] as String? ?? _uuid.v4();
    isActive = true;
    lastSent = DateTime.fromMillisecondsSinceEpoch(0);

    final metaRef = database.ref('trips/$tripId/meta');
    await metaRef.set({
      'busId': busId,
      'routeId': routeId,
      'startAt': ServerValue.timestamp,
      'endAt': null,
    });

    final settings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      intervalDuration: const Duration(seconds: 5),
      distanceFilter: 10,
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Bus Tracking Active',
        notificationText: 'Sharing live bus location',
      ),
    );

    positionSub = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((position) async {
      final now = DateTime.now();
      final isStationary = position.speed <= 1.0;
      final throttleSeconds = isStationary ? 30 : 8;

      if (now.difference(lastSent).inSeconds < throttleSeconds) {
        return;
      }
      lastSent = now;

      final payload = {
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'updatedAt': ServerValue.timestamp,
        'tripId': tripId,
        'routeId': routeId,
        'isActive': true,
      };

      if (busId != null) {
        await database.ref('buses/$busId/live').set(payload);
      }
      if (tripId != null) {
        await database.ref('trips/$tripId/points').push().set({
          'lat': position.latitude,
          'lng': position.longitude,
          'speed': position.speed,
          'heading': position.heading,
          'timestamp': ServerValue.timestamp,
        });
      }
    });

    updateNotification();
  }

  service.on('startTrip').listen((event) {
    if (event == null) return;
    startTracking(Map<String, dynamic>.from(event));
  });

  service.on('stopTrip').listen((event) async {
    await stopTracking();
  });

  service.on('endTrip').listen((event) async {
    await stopTracking();
    if (tripId != null) {
      await database.ref('trips/$tripId/meta').update({
        'endAt': ServerValue.timestamp,
      });
    }
  });

  updateNotification();
}
