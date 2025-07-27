// lib/map_screen.dart

import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// The new MapScreen, redesigned to look like the Uber map.
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
    // Using a Stack to layer the map, info panel, and buttons.
    return Material(
      color: const Color(0xFF0A0A12),
      child: Stack(
        children: [
          // The programmatically drawn map fills the whole screen.
          _buildVectorMap(),

          // The top app bar area.
          _buildTopBar(),

          // The bottom info panel slides up from the bottom.
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildVectorMap() {
    return CustomPaint(
      size: Size.infinite,
      painter: UberStyleMapPainter(),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTopButton(Icons.arrow_back),
              Text(
                'LIVE LOCATION',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
              _buildTopButton(Icons.my_location),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTopButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70),
        onPressed: () {
          if (icon == Icons.arrow_back) {
            // This allows the back button to work.
            if(Navigator.canPop(context)) Navigator.pop(context);
          }
        },
      ),
    );
  }

  // This builds the floating panel at the bottom of the screen.
  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 90, // Raised to avoid the navigation bar
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E).withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.cyan,
                      child: Icon(Icons.person, color: Colors.black, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KAVYA',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Status: In Transit',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 32),
                _buildInfoRow(
                  Icons.access_time_filled,
                  'Last Ping',
                  'Just now',
                  Colors.greenAccent,
                ),
                const SizedBox(height: 12),
                 _buildInfoRow(
                  Icons.location_on,
                  'Location',
                  'Vidhana Soudha, Bengaluru',
                  Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String title, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// This CustomPainter draws the abstract map background in the Uber style.
class UberStyleMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dark background
    final backgroundPaint = Paint()..color = const Color(0xFF1A1D24);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Thinner, lighter roads
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Darker, subtle blocks
    final blockPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;
      
    // Bright yellow highlight lines
    final highlightPaint = Paint()
      ..color = const Color(0xFFFFC107).withOpacity(0.6)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final random = Random(42); // Use a fixed seed for a consistent map layout

    // Draw grid-like blocks
    for (double i = -100; i < size.width + 100; i += 80) {
      for (double j = -100; j < size.height + 100; j += 80) {
         if (random.nextDouble() > 0.4) {
           canvas.drawRect(
             Rect.fromLTWH(
               i + random.nextDouble() * 20,
               j + random.nextDouble() * 20,
               random.nextDouble() * 40 + 30,
               random.nextDouble() * 40 + 30,
             ),
             blockPaint,
           );
         }
      }
    }
    
    // Draw grid-like roads
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), roadPaint);
    }
     for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), roadPaint);
    }

    // Draw the main highlighted route path
    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.3, size.height * 0.6,
      size.width * 0.5, size.height * 0.5,
    );
     path.quadraticBezierTo(
      size.width * 0.7, size.height * 0.4,
      size.width * 0.9, size.height * 0.2,
    );
    canvas.drawPath(path, highlightPaint);
    
    // Draw a marker on the path
     final markerPaint = Paint()..color = Colors.cyan;
     canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 8, markerPaint);
     final markerBorderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
     canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 8, markerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}