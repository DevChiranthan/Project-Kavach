// lib/live_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:project_kavach_app/providers/ble_provider.dart';

class LiveScreen extends StatefulWidget {
  final bool isDemoModeOn;
  final ValueChanged<bool> onDemoModeChanged;

  const LiveScreen({
    super.key,
    required this.isDemoModeOn,
    required this.onDemoModeChanged,
  });

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  // Data buffers for the scrolling graphs
  final List<double> _irDataBuffer = List.filled(100, 0.0, growable: true);
  final List<double> _bpmDataBuffer = List.filled(50, 0.0, growable: true);
  
  // NEW: Variable to store the last non-zero BPM
  double _lastKnownBpm = 0.0;

  @override
  Widget build(BuildContext context) {
    // Access the BLE Provider for real-time data
    final ble = Provider.of<BleProvider>(context);

    // Update the graph buffers with new data
    _updateBuffers(ble);

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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 20),
                      
                      // 1. SKIN CONTACT STATUS (Prox Sensor Logic)
                      _buildSkinContactStatus(ble),
                      const SizedBox(height: 24),
                      
                      // 2. IR SENSOR GRAPH (Raw Data)
                      _buildGraphCard(
                        title: "IR SENSOR RAW",
                        value: "${ble.irValue}",
                        unit: "lux",
                        color: Colors.cyanAccent,
                        data: _irDataBuffer,
                        min: 0, 
                        max: 150000, 
                        isConnected: ble.isConnected,
                      ),
                      
                      const SizedBox(height: 20),

                      // 3. HEART RATE GRAPH (BPM)
                      _buildGraphCard(
                        title: "HEART RATE",
                        // LOGIC FIX: Use last known BPM if current is 0
                        value: (ble.isConnected && _lastKnownBpm > 0) 
                            ? "${_lastKnownBpm.toInt()}" 
                            : "--", 
                        unit: "BPM",
                        subValue: "AVG: ${ble.avgBpm}",
                        color: Colors.redAccent,
                        data: _bpmDataBuffer,
                        min: 40,
                        max: 150,
                        isConnected: ble.isConnected,
                      ),
                      
                      const SizedBox(height: 20),
                      _buildConnectionStatus(ble),
                      const SizedBox(height: 80), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateBuffers(BleProvider ble) {
    // Logic to save the last valid BPM
    if (ble.isConnected && ble.bpm > 0) {
      _lastKnownBpm = ble.bpm.toDouble();
    }

    // If connected, add the real values. If not, add 0 for a flatline.
    if (ble.isConnected) {
      _irDataBuffer.add(ble.irValue.toDouble());
      _bpmDataBuffer.add(ble.bpm.toDouble());
    } else {
      _irDataBuffer.add(0);
      _bpmDataBuffer.add(0);
    }

    // Maintain fixed buffer size to create scrolling effect
    if (_irDataBuffer.length > 100) _irDataBuffer.removeAt(0);
    if (_bpmDataBuffer.length > 50) _bpmDataBuffer.removeAt(0);
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Live Vitals',
            style: GoogleFonts.oxanium(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.2),
          ),
          Row(
            children: [
              Text("DEMO", style: TextStyle(color: widget.isDemoModeOn ? Colors.green : Colors.grey, fontSize: 12)),
              Switch(
                value: widget.isDemoModeOn,
                activeColor: Colors.green,
                onChanged: widget.onDemoModeChanged,
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSkinContactStatus(BleProvider ble) {
    bool hasContact = ble.isConnected && ble.isSkinContact;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: hasContact 
            ? Colors.greenAccent.withOpacity(0.1) 
            : Colors.orangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasContact ? Colors.greenAccent.withOpacity(0.5) : Colors.orangeAccent.withOpacity(0.5)
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasContact ? Icons.fingerprint : Icons.back_hand,
            color: hasContact ? Colors.greenAccent : Colors.orangeAccent,
            size: 28,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SENSOR STATUS",
                style: GoogleFonts.roboto(
                  color: Colors.white54, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold
                ),
              ),
              Text(
                !ble.isConnected 
                    ? "UNIFORM OFFLINE" 
                    : (hasContact ? "SKIN DETECTED" : "NO CONTACT"),
                style: GoogleFonts.oxanium(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGraphCard({
    required String title,
    required String value,
    required String unit,
    String? subValue,
    required Color color,
    required List<double> data,
    required double min,
    required double max,
    required bool isConnected,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          // ERROR FIX: Increased height from 240 to 265 to prevent overflow
          height: 265, 
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.show_chart, color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (subValue != null)
                    Text(subValue, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              
              // Big Value Display
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value, // Now uses the passed value which handles the logic
                    style: GoogleFonts.oxanium(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              ),
              
              const Spacer(),
              
              // THE REAL-TIME GRAPH
              SizedBox(
                height: 100,
                width: double.infinity,
                child: CustomPaint(
                  painter: LineChartPainter(
                    data: data,
                    color: color,
                    min: min,
                    max: max,
                    isSleep: !isConnected, 
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(BleProvider ble) {
    return Center(
      child: Text(
        ble.isConnected ? "Receiving Real-Time Telemetry..." : "Waiting for Uniform Connection...",
        style: const TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
      ),
    );
  }
}

// --- CUSTOM PAINTER (Draws the graph line) ---
class LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double min;
  final double max;
  final bool isSleep;

  LineChartPainter({
    required this.data,
    required this.color,
    required this.min,
    required this.max,
    required this.isSleep,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isSleep ? Colors.grey.withOpacity(0.3) : color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double stepX = size.width / (data.length - 1);

    if (isSleep || data.isEmpty) {
      // Draw flatline in middle
      path.moveTo(0, size.height / 2);
      path.lineTo(size.width, size.height / 2);
    } else {
      for (int i = 0; i < data.length; i++) {
        // Normalize value to height (0.0 to 1.0)
        double normalized = (data[i] - min) / (max - min);
        normalized = normalized.clamp(0.0, 1.0);
        
        double x = i * stepX;
        // Invert Y because canvas 0 is at top
        double y = size.height - (normalized * size.height);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
    }

    // Draw Shadow/Glow
    if (!isSleep) {
       canvas.drawShadow(path, color, 3.0, true);
    }
    
    canvas.drawPath(path, paint);

    // Draw pulsing dot at the end
    if (!isSleep) {
       final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
       
       double lastNormalized = 0.0;
       if(data.isNotEmpty) {
         lastNormalized = (data.last - min) / (max - min);
         lastNormalized = lastNormalized.clamp(0.0, 1.0);
       }
       
       double lastY = size.height - (lastNormalized * size.height);
       canvas.drawCircle(Offset(size.width, lastY), 4.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}