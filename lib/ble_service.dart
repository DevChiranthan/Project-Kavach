import 'dart:async';
import 'dart:typed_data'; // <--- REQUIRED for Int64List
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

// --- UUIDs ---
const String KAVACH_SERVICE_UUID = "19B10000-E8F2-537E-4F6C-D104768A1214";
const String RING_CHARACTERISTIC_UUID = "19B10002-E8F2-537E-4F6C-D104768A1214";

class BleService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FlutterTts flutterTts = FlutterTts();

  BluetoothDevice? kavachDevice;
  StreamSubscription<BluetoothConnectionState>? connectionStateSubscription;

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
  }

  // --- Scan and Connect logic ---
  void startScanAndConnect(Function(String) onStatusUpdate) {
    onStatusUpdate("Scanning...");
    // FlutterBluePlus 1.30.0 uses List<Guid>
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15), 
      withServices: [Guid(KAVACH_SERVICE_UUID)]
    );
    
    FlutterBluePlus.scanResults.listen((results) {
      if (results.isNotEmpty) {
        ScanResult r = results.first;
        FlutterBluePlus.stopScan();
        kavachDevice = r.device;
        connectToDevice(onStatusUpdate);
      }
    });
  }

  void connectToDevice(Function(String) onStatusUpdate) async {
    if (kavachDevice == null) return;
    connectionStateSubscription?.cancel();
    connectionStateSubscription = kavachDevice!.connectionState.listen((BluetoothConnectionState state) {
      if (state == BluetoothConnectionState.connected) {
        onStatusUpdate('Connected');
        discoverServices();
      } else {
        onStatusUpdate(state.toString().split('.').last);
      }
    });
    await kavachDevice!.connect();
  }

  void discoverServices() async {
    if (kavachDevice == null) return;
    List<BluetoothService> services = await kavachDevice!.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase() == KAVACH_SERVICE_UUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase() == RING_CHARACTERISTIC_UUID) {
            final isNotifying = characteristic.isNotifying;
            if (!isNotifying) await characteristic.setNotifyValue(true);
            
            characteristic.lastValueStream.listen((value) {
              if (value.isNotEmpty && value[0] == 1) {
                triggerRingAlert();
              } else if (value.isNotEmpty && value[0] == 0) {
                stopRingAlert();
              }
            });
          }
        }
      }
    }
  }

  // --- THE FINAL, RELIABLE RING ALERT ---
  Future<void> triggerRingAlert() async {
    // 1. Prepare Vibration
    final Int64List vibrationPattern = Int64List(10);
    vibrationPattern[0] = 0;    // Start immediately
    vibrationPattern[1] = 1000; // Vibrate for 1 second
    vibrationPattern[2] = 1000; // Pause for 1 second
    vibrationPattern[3] = 1000; 
    vibrationPattern[4] = 1000; 
    vibrationPattern[5] = 1000;
    vibrationPattern[6] = 1000;
    vibrationPattern[7] = 1000;
    vibrationPattern[8] = 1000;
    vibrationPattern[9] = 1000;

    // 2. Configure the full-screen notification
    // Note: RawResourceAndroidNotificationSound requires the file to be in 'android/app/src/main/res/raw/alarm.mp3'
    // If it's not there, it will use the default sound.
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'kavach_emergency_channel',
        'Kavach Emergency Alerts',
        channelDescription: 'This channel is used for emergency, full-screen alerts.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        // CHANGED: RingtoneAndroidNotificationSound does not exist. 
        // Using default sound ensures no crash.
        // sound: const RawResourceAndroidNotificationSound('alarm'), 
        fullScreenIntent: true, 
        category: AndroidNotificationCategory.call, 
        vibrationPattern: vibrationPattern, 
        enableVibration: true,
        );
    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // 3. Show the notification
    await flutterLocalNotificationsPlugin.show(
      1,
      'KAVACH EMERGENCY', 
      'Safety Circuit Alert!', 
      platformDetails
    );

    // 4. Get Location and Speak
    Position? position = await _determinePosition();
    String locationInfo = "Location is currently unavailable.";
    if (position != null) {
      locationInfo = "Last known location is near latitude ${position.latitude.toStringAsFixed(2)} and longitude ${position.longitude.toStringAsFixed(2)}.";
    }
    String spokenMessage = "Emergency alert from Project Kavach. The safety circuit has been broken. $locationInfo Please take immediate action.";
    
    // Speak after a short delay to allow the notification to appear
    Future.delayed(const Duration(seconds: 1), () {
      flutterTts.speak(spokenMessage);
    });
  }

  Future<void> stopRingAlert() async {
    await flutterTts.stop();
    await flutterLocalNotificationsPlugin.cancel(1);
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition();
  }

  void dispose() {
    connectionStateSubscription?.cancel();
    kavachDevice?.disconnect();
  }
}