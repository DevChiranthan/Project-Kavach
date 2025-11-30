import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleProvider with ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _monitorCharacteristic;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _valueSubscription;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // UUIDs matching your Arduino Code
  final String SERVICE_UUID = "19B10000-E8F2-537E-4F6C-D104768A1214";
  final String CHAR_UUID = "19B10002-E8F2-537E-4F6C-D104768A1214";

  // Stream controller to trigger UI events without context
  final _alertController = StreamController<bool>.broadcast();
  Stream<bool> get alertStream => _alertController.stream;

  void startScanAndConnect() async {
    print("Starting Scan...");
    // Start scanning for devices named "ProjectKavach"
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult result in results) {
        if (result.device.platformName == "ProjectKavach") {
          print("Found Kavach Device! Connecting...");
          await FlutterBluePlus.stopScan();
          await _connectToDevice(result.device);
        }
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
      _connectedDevice = device;
      _isConnected = true;
      notifyListeners();

      // Listen for disconnection
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _isConnected = false;
          _cleanup();
          notifyListeners();
        }
      });

      // Discover Services
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase() == SERVICE_UUID) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString().toUpperCase() == CHAR_UUID) {
              _monitorCharacteristic = c;
              
              // Enable Notifications
              await c.setNotifyValue(true);
              
              // Listen for Data Changes (1 = BROKEN, 0 = SAFE)
              _valueSubscription = c.lastValueStream.listen((value) {
                if (value.isNotEmpty && value[0] == 1) {
                  // Push ALERT to the stream!
                  _alertController.add(true); 
                }
              });
              print("Monitoring Characteristic Found!");
            }
          }
        }
      }
    } catch (e) {
      print("Connection Error: $e");
    }
  }

  void _cleanup() {
    _valueSubscription?.cancel();
    _connectionSubscription?.cancel();
    _connectedDevice = null;
    _monitorCharacteristic = null;
  }

  @override
  void dispose() {
    _cleanup();
    _alertController.close();
    super.dispose();
  }
}