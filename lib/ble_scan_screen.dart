// lib/ble_scan_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:project_kavach_app/student_dashboard_screen.dart';

class BleScanScreen extends StatefulWidget {
  final bool isDemoModeOn;
  const BleScanScreen({super.key, required this.isDemoModeOn});

  @override
  State<BleScanScreen> createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  String _statusText = "Tap the icon to scan for Kavach Device";

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startScan() {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _statusText = "Scanning... Hold near uniform wristband";
      _animationController.duration = const Duration(milliseconds: 700);
      _animationController.repeat();
    });

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return; // Check if the widget is still in the tree

      if (widget.isDemoModeOn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => const StudentDashboardScreen()),
        );
      } else {
        setState(() {
          _isScanning = false;
          _statusText =
              "Device Not Found\nEnable 'Demo Mode' on the Live screen and try again.";
          // --- THIS IS THE CORRECTED LINE ---
          _animationController.duration = const Duration(seconds: 2);
          _animationController.repeat();
        });
      }
    });
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPulsingScanner(),
                    const SizedBox(height: 32),
                    Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        color: _isScanning ? Colors.white : Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingScanner() {
    return GestureDetector(
      onTap: _startScan,
      child: CustomPaint(
        painter: PulsePainter(_animationController),
        child: SizedBox(
          width: 200,
          height: 200,
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Center(
                child: Icon(
                  _isScanning ? Icons.bluetooth_searching : Icons.tap_and_play,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
            'BLE Scan',
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
}

class PulsePainter extends CustomPainter {
  final Animation<double> _animation;
  PulsePainter(this._animation) : super(repaint: _animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    for (int i = 3; i >= 1; i--) {
      final double radius = size.width / 2 * _animation.value;
      final double opacity =
          (1.0 - (_animation.value * i / 3.5)).clamp(0.0, 1.0);
      final color = Color.fromRGBO(68, 138, 255, opacity); // BlueAccent
      final paint = Paint()..color = color;
      canvas.drawCircle(rect.center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(PulsePainter oldDelegate) {
    return false;
  }
}
