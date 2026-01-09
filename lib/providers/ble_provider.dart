// lib/providers/ble_provider.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleProvider with ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _monitorCharacteristic; // For Ring/Loop Security
  BluetoothCharacteristic? _vitalsCharacteristic;  // For IR, BPM, Avg

  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _securitySubscription;
  StreamSubscription<List<int>>? _vitalsSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  // --- VITAL SIGNS DATA ---
  int _irValue = 0;
  int _bpm = 0;
  int _avgBpm = 0;

  int get irValue => _irValue;
  int get bpm => _bpm;
  int get avgBpm => _avgBpm;

  bool get isSkinContact => _irValue > 50000;

  // --- UUID DEFINITIONS ---
  final String SERVICE_UUID = "19B10000-E8F2-537E-4F6C-D104768A1214";
  final String RING_CHAR_UUID = "19B10001-E8F2-537E-4F6C-D104768A1214";
  final String VITALS_CHAR_UUID = "19B10002-E8F2-537E-4F6C-D104768A1214";

  final _alertController = StreamController<bool>.broadcast();
  Stream<bool> get alertStream => _alertController.stream;

  Future<void> startScanAndConnect() async {
    if (_isConnected) return;
    
    _isScanning = true;
    notifyListeners(); 

    print("Starting Scan...");
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    try {
      // Start scan with timeout
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: true,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult result in results) {
          if (result.device.platformName == "ProjectKavach") {
            print("Found Kavach Device! Connecting...");
            
            // 1. Stop scanning first
            await FlutterBluePlus.stopScan();
            await _scanSubscription?.cancel();
            _scanSubscription = null;

            // 2. Small delay to let BLE stack settle (CRITICAL FIX)
            await Future.delayed(const Duration(milliseconds: 200));

            // 3. Connect
            await _connectToDevice(result.device);
            
            _isScanning = false;
            notifyListeners();
            return;
          }
        }
      });

      // Timeout fallback
      await Future.delayed(const Duration(seconds: 5));
      if (!_isConnected && _isScanning) {
        print("Scan timeout. No device found.");
        if (FlutterBluePlus.isScanningNow) {
          await FlutterBluePlus.stopScan();
        }
        _isScanning = false;
        notifyListeners();
      }
    } catch (e) {
      print("Scan Error: $e");
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      // autoConnect: false forces an immediate connection attempt
      await device.connect(autoConnect: false, mtu: null); 
      
      _connectedDevice = device;
      _isConnected = true;
      notifyListeners();

      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _cleanup();
          notifyListeners();
        }
      });

      // Android specific delay before discovering services (CRITICAL FIX)
      if (Platform.isAndroid) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Explicitly request MTU (Optional, improves throughput for strings)
      if (Platform.isAndroid) {
        try {
          await device.requestMtu(512);
        } catch (e) {
          print("MTU Request failed (not fatal): $e");
        }
      }

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase() == SERVICE_UUID) {
          for (BluetoothCharacteristic c in service.characteristics) {
            String uuid = c.uuid.toString().toUpperCase();

            // 1. RING/SECURITY
            if (uuid == RING_CHAR_UUID) {
              _monitorCharacteristic = c;
              await c.setNotifyValue(true);
              _securitySubscription = c.lastValueStream.listen((value) {
                if (value.isNotEmpty && value[0] == 1) {
                  _alertController.add(true);
                }
              });
            }

            // 2. VITALS (String)
            if (uuid == VITALS_CHAR_UUID) {
              _vitalsCharacteristic = c;
              await c.setNotifyValue(true);
              _vitalsSubscription = c.lastValueStream.listen((value) {
                try {
                  String data = utf8.decode(value);
                  List<String> parts = data.split(',');
                  if (parts.length >= 3) {
                    _irValue = int.tryParse(parts[0]) ?? 0;
                    _bpm = int.tryParse(parts[1]) ?? 0;
                    _avgBpm = int.tryParse(parts[2]) ?? 0;
                    notifyListeners(); 
                  }
                } catch (e) {
                  print("Vitals Parse Error: $e");
                }
              });
            }
          }
        }
      }
    } catch (e) {
      print("Connection Error: $e");
      // If we failed, try to disconnect cleanly so we can try again
      try { await device.disconnect(); } catch (_) {}
      _cleanup();
    }
  }

  void _cleanup() {
    _isConnected = false;
    _isScanning = false;
    _irValue = 0;
    _bpm = 0;
    _avgBpm = 0;

    _securitySubscription?.cancel();
    _vitalsSubscription?.cancel();
    _connectionSubscription?.cancel();
    _scanSubscription?.cancel();
    
    _securitySubscription = null;
    _vitalsSubscription = null;
    _connectionSubscription = null;
    _scanSubscription = null;
    _connectedDevice = null;

    notifyListeners();
  }

  @override
  void dispose() {
    _cleanup();
    _alertController.close();
    super.dispose();
  }
}