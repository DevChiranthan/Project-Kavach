import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
// Ensure this import path matches your project name in pubspec.yaml
import 'package:project_kavach_app/providers/ble_provider.dart';
import 'package:project_kavach_app/screens/incoming_call_screen.dart';

class DemoDashboard extends StatefulWidget {
  const DemoDashboard({super.key});

  @override
  State<DemoDashboard> createState() => _DemoDashboardState();
}

class _DemoDashboardState extends State<DemoDashboard> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();

    // LISTEN FOR ALERTS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bleProvider = Provider.of<BleProvider>(context, listen: false);
      bleProvider.alertStream.listen((isAlert) {
        if (isAlert) {
          // Trigger the Fake Call if not already shown
          if (ModalRoute.of(context)?.isCurrent ?? true) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const IncomingCallScreen()),
            );
          }
        }
      });
    });
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    final ble = Provider.of<BleProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Kavach Monitor", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false, // Title on Left
        actions: [
          // BLUETOOTH STATUS ICON (TOP RIGHT)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ble.isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ble.isConnected ? Colors.green : Colors.red),
            ),
            child: Row(
              children: [
                Icon(
                  ble.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, 
                  color: ble.isConnected ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  ble.isConnected ? "ONLINE" : "OFFLINE",
                  style: TextStyle(
                    color: ble.isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // MAIN CONTROLS ROW
            Expanded(
              child: Row(
                children: [
                  // LEFT: NFC SCAN
                  Expanded(
                    child: _buildCard(
                      title: "NFC Scan",
                      subtitle: "Tap Student ID",
                      icon: Icons.nfc,
                      color: Colors.blueAccent,
                      onTap: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text("Reading NFC Tag... Verified: Student #1024")),
                         );
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  
                  // RIGHT: BLE CONNECT
                  Expanded(
                    child: _buildCard(
                      title: ble.isConnected ? "Armed" : "Connect",
                      subtitle: ble.isConnected ? "Monitoring Active" : "Pair Uniform",
                      icon: ble.isConnected ? Icons.shield : Icons.link,
                      color: ble.isConnected ? Colors.green : Colors.grey.shade800,
                      isPrimary: ble.isConnected,
                      onTap: () {
                        if (!ble.isConnected) ble.startScanAndConnect();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // BOTTOM INFO CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("System Logs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  _buildLogItem("System Initialized", "10:00 AM"),
                  if (ble.isConnected) _buildLogItem("Uniform Connected (UID: 8X-22)", "10:02 AM"),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: isPrimary ? Colors.white : color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isPrimary ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(String text, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: const TextStyle(color: Colors.black87)),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}