// lib/screens/incoming_call_screen.dart

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:google_fonts/google_fonts.dart';

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts flutterTts = FlutterTts();
  late AnimationController _rippleController;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    
    // Setup Ripple Animation
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _startAlarm();
  }

  void _startAlarm() async {
    // 1. Play Alarm/Ringtone
    await _audioPlayer.setSource(AssetSource('alarm.mp3'));
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.resume();

    // 2. Vibrate
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 0);
    }
  }

  void _answerCall() async {
    await _audioPlayer.stop();
    Vibration.cancel();
    _rippleController.stop();

    setState(() {
      _isAnswered = true;
    });

    // Speak AI Warning with Indian Accent
    await flutterTts.setLanguage("en-IN"); // Set to Indian English
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.4); // Slightly slower for clarity
    
    // Detailed AI Message
    await flutterTts.speak(
      "Alert! This is Project Kavach AI. We have detected a breach in the uniform security loop. "
      "GPS coordinates have been locked. Emergency services and parents are being notified immediately. "
      "Please remain calm and stay at your current location."
    );
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    flutterTts.stop();
    Vibration.cancel();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Navy Blue
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // TOP: HEADER
            Padding(
              padding: const EdgeInsets.only(top: 80.0),
              child: Column(
                children: [
                  _buildAnimatedAvatar(),
                  const SizedBox(height: 30),
                  Text(
                    "KAVACH HQ AI",
                    style: GoogleFonts.oxanium(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isAnswered ? "Security Protocol Active" : "HIGH PRIORITY ALERT...",
                    style: GoogleFonts.roboto(
                      color: _isAnswered ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // MIDDLE: VISUALIZER (Only if answered)
            if (_isAnswered)
               Expanded(
                 child: Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.graphic_eq, color: Colors.greenAccent, size: 120),
                       const SizedBox(height: 20),
                       Text("Transmitting Location...", style: GoogleFonts.sourceCodePro(color: Colors.white54))
                     ],
                   ),
                 ),
               ),

            // BOTTOM: BUTTONS
            Padding(
              padding: const EdgeInsets.only(bottom: 80.0, left: 40, right: 40),
              child: _isAnswered 
              ? _buildEndCallButton() 
              : _buildSlideToAnswer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple Effect
        if (!_isAnswered)
          FadeTransition(
            opacity: _rippleController.drive(Tween(begin: 1.0, end: 0.0)),
            child: ScaleTransition(
              scale: _rippleController.drive(Tween(begin: 1.0, end: 1.5)),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 4),
                ),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(6), 
          decoration: BoxDecoration(
            color: _isAnswered ? Colors.greenAccent : Colors.redAccent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _isAnswered ? Colors.greenAccent.withOpacity(0.4) : Colors.redAccent.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5
              )
            ]
          ),
          child: const CircleAvatar(
            radius: 60,
            backgroundColor: Color(0xFF0F172A),
            backgroundImage: AssetImage('assets/icon.png'),
          ),
        ),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.call_end, color: Colors.white, size: 35),
      ),
    );
  }

  Widget _buildSlideToAnswer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // DECLINE BUTTON
        Column(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent),
                ),
                child: const Icon(Icons.call_end, color: Colors.redAccent, size: 30),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Dismiss", style: TextStyle(color: Colors.white70)),
          ],
        ),

        // ANSWER BUTTON (PULSING)
        Column(
          children: [
            GestureDetector(
              onTap: _answerCall,
              child: ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.1).animate(
                  CurvedAnimation(parent: _rippleController, curve: Curves.easeInOut)
                ),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 20)],
                  ),
                  child: const Icon(Icons.call, color: Colors.white, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text("CONNECT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
      ],
    );
  }
}