import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts flutterTts = FlutterTts();
  late AnimationController _controller;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    
    // Setup Ringing Animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.8,
      upperBound: 1.0,
    )..repeat(reverse: true);

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
    _controller.stop();

    setState(() {
      _isAnswered = true;
    });

    // Speak AI Warning
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak("Emergency Alert! Uniform Tampering Detected. GPS Location Sent to Police Control Room.");
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    flutterTts.stop();
    Vibration.cancel();
    _controller.dispose();
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
              padding: const EdgeInsets.only(top: 60.0),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _controller,
                    child: Container(
                      padding: const EdgeInsets.all(4), // Red Border
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage('assets/icon.png'), // Your App Icon
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "PROJECT KAVACH HQ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isAnswered ? "00:12" : "HIGH PRIORITY ALERT...",
                    style: TextStyle(
                      color: _isAnswered ? Colors.greenAccent : Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            // MIDDLE: VISUALIZER (Only if answered)
            if (_isAnswered)
               const Expanded(
                 child: Center(
                   child: Icon(Icons.graphic_eq, color: Colors.greenAccent, size: 100),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // MESSAGE BUTTON
        Column(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context), 
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.message, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Message", style: TextStyle(color: Colors.white70)),
          ],
        ),

        // ANSWER BUTTON (ANIMATED)
        Column(
          children: [
            GestureDetector(
              onTap: _answerCall,
              child: ScaleTransition(
                scale: _controller,
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
            const Text("Accept", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        
         // DECLINE BUTTON
        Column(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.call_end, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 10),
            const Text("Decline", style: TextStyle(color: Colors.white70)),
          ],
        ),
      ],
    );
  }
}