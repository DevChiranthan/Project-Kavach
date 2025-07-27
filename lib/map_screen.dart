import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// The new MapScreen designed to match your app's dark theme.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12), // Matching the main theme
      appBar: AppBar(
        title: Text(
          'LOCATION TRACKER',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // The programmatically drawn map area
          Expanded(
            flex: 5,
            child: _buildVectorMap(),
          ),
          // The data log area below the map
          Expanded(
            flex: 4,
            child: _buildLocationData(),
          ),
        ],
      ),
    );
  }

  // This widget builds the custom-painted map and the animations on top.
  Widget _buildVectorMap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The CustomPainter draws the vector map background.
            CustomPaint(
              size: Size.infinite,
              painter: FakeMapPainter(),
            ),
            // Pulsing circles for the animation.
            _buildPulsingCircle(delay: 0.0),
            _buildPulsingCircle(delay: 0.5),
            // The central marker for "Kavya".
            _buildLocationMarker(),
          ],
        ),
      ),
    );
  }

  // The glowing, pulsing circles.
  Widget _buildPulsingCircle({required double delay}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final animationValue = (_pulseController.value + delay) % 1.0;
        final scale = 1.5 * animationValue;
        final opacity = 1.0 - animationValue;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.cyanAccent.withOpacity(opacity),
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  // The marker with a glowing effect.
  Widget _buildLocationMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.cyan,
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.black, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          'KAVYA',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            shadows: [
              const Shadow(blurRadius: 10, color: Colors.black),
            ],
          ),
        ),
      ],
    );
  }

  // The data log section below the map.
  Widget _buildLocationData() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIGNAL LOG',
            style: GoogleFonts.roboto(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const Divider(color: Colors.white24, height: 24),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildInfoTile(
                  icon: Icons.access_time_filled,
                  title: 'Last Ping Received',
                  subtitle: 'Just now',
                  color: Colors.greenAccent.withOpacity(0.8),
                ),
                _buildInfoTile(
                  icon: Icons.my_location,
                  title: 'Coordinates',
                  subtitle: '12.9716° N, 77.5946° E',
                  color: Colors.cyanAccent.withOpacity(0.8),
                ),
                _buildInfoTile(
                  icon: Icons.signal_cellular_alt,
                  title: 'Signal Strength',
                  subtitle: 'Strong (-65 dBm)',
                  color: Colors.amberAccent.withOpacity(0.8),
                ),
                _buildInfoTile(
                  icon: Icons.security,
                  title: 'Status',
                  subtitle: 'Secure Zone | School Campus',
                  color: Colors.redAccent.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Reusable widget for each line of data.
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.robotoMono(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// This CustomPainter draws the abstract map background.
class FakeMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background color
    final backgroundPaint = Paint()..color = const Color(0xFF1A1D24);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Paint for the roads
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Paint for the blocks
     final blockPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    // Draw a grid of blocks and roads
    final random = Random(10); // Use a fixed seed for consistency
    for (int i = 0; i < 15; i++) {
      // Draw random blocks
      canvas.drawRect(
        Rect.fromLTWH(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
          random.nextDouble() * 80 + 20,
          random.nextDouble() * 80 + 20,
        ),
        blockPaint,
      );
      // Draw random road lines
      canvas.drawLine(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        roadPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}