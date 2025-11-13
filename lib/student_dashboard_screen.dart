// lib/student_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:permission_handler/permission_handler.dart'; // Import for permissions
import 'ble_service.dart'; // Import the new Bluetooth logic file

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final BleService _bleService = BleService();
  String _connectionStatus = "Disconnected";
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _bleService.initialize();
  }

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  // This new function requests permissions BEFORE trying to scan.
  Future<void> _requestPermissionsAndConnect() async {
    if (_isConnecting) return;

    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted &&
        statuses[Permission.location]!.isGranted) {
      // If permissions are granted, start the scan.
      setState(() {
        _isConnecting = true;
      });
      _bleService.startScanAndConnect((status) {
        if (mounted) {
          setState(() {
            _connectionStatus = status;
            // Stop showing "Connecting..." once a final state is reached.
            if (status.toLowerCase() != 'scanning...' &&
                status.toLowerCase() != 'connecting') {
              _isConnecting = false;
            }
          });
        }
      });
    } else {
      // If permissions are denied, show an error.
      setState(() {
        _connectionStatus = "Permissions Denied";
      });
      print("Permissions were not granted. Cannot scan.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            colors: [Color(0xFF2A2A3A), Color(0xFF0A0A12)],
            radius: 1.0,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  children: [
                    const SizedBox(height: 10),
                    _buildUserInfoCard(),
                    const SizedBox(height: 24),
                    _buildConnectivitySection(), // New section added here
                    const SizedBox(height: 24),
                    _buildDashboardGrid(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // This new widget displays the connection button and status.
  Widget _buildConnectivitySection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Uniform Status: ",
                    style:
                        GoogleFonts.roboto(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    _connectionStatus,
                    style: GoogleFonts.roboto(
                      color: _connectionStatus.toLowerCase() == 'connected'
                          ? Colors.greenAccent
                          : _connectionStatus == "Permissions Denied"
                              ? Colors.redAccent
                              : Colors.amberAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _requestPermissionsAndConnect,
                  icon: const Icon(Icons.bluetooth, color: Colors.white),
                  label: Text(
                    _isConnecting ? 'Scanning...' : 'Connect to Uniform',
                    style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isConnecting
                        ? Colors.grey.shade600
                        : Colors.indigoAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- All of your original UI-building methods are preserved below ---

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          Text(
            'Student Dashboard',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Juno Pradhan',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Class VII B  |  Roll No: 14',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.verified_user,
                  color: Colors.greenAccent, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildGridItem(
            Icons.event_available, 'Attendance', '95%', Colors.greenAccent),
        _buildGridItem(
            Icons.contacts, 'Contact Info', 'View', Colors.orangeAccent),
        _buildGridItem(
            Icons.schedule, 'Time Table', 'Check', Colors.purpleAccent),
        _buildGridItem(
            Icons.assignment, 'Assignments', 'Post New', Colors.blueAccent),
      ],
    );
  }

  Widget _buildGridItem(
      IconData icon, String title, String subtitle, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: GoogleFonts.roboto(
                      color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.sms, color: Colors.white),
            label: Text('Send Complaint to Parent',
                style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
            ),
          ),
        ),
      ],
    );
  }
}
