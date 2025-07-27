// lib/main.dart

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:project_kavach_app/live_screen.dart';
import 'package:project_kavach_app/ble_scan_screen.dart';
import 'package:project_kavach_app/map_screen.dart';
// Make sure you have this file in your lib folder
import 'package:project_kavach_app/student_dashboard_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Kavach',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A12),
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  bool _isDemoModeOn = false;
  int _selectedIndex = 2;

  // We build the list of pages here so it can access the state
  List<Widget> _getPages() {
    return <Widget>[
      LiveScreen(
        isDemoModeOn: _isDemoModeOn,
        onDemoModeChanged: (value) {
          setState(() {
            _isDemoModeOn = value;
          });
        },
      ),
      const MapScreen(),
      HomeScreen(isDemoModeOn: _isDemoModeOn),
      const Center(
          child: Text('History Page', style: TextStyle(color: Colors.white))),
      const Center(
          child: Text('More Page', style: TextStyle(color: Colors.white))),
    ];
  }

  final List<IconData> _icons = [
    Icons.show_chart,
    Icons.map_outlined,
    Icons.home_filled,
    Icons.history,
    Icons.menu,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _getPages(), // Use the method to get the pages
      ),
      bottomNavigationBar: AnimatedBottomNavBar(
        selectedIndex: _selectedIndex,
        icons: _icons,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CUSTOM ANIMATED NAVIGATION BAR WIDGET (No Changes Here)
// -----------------------------------------------------------------------------
class AnimatedBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final List<IconData> icons;
  final ValueChanged<int> onItemTapped;

  const AnimatedBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.icons,
    required this.onItemTapped,
  });

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Tween<double> _tween;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    final initialPosition = widget.selectedIndex.toDouble();
    _tween = Tween<double>(begin: initialPosition, end: initialPosition);
    _animation = _tween
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _tween.begin = oldWidget.selectedIndex.toDouble();
      _tween.end = widget.selectedIndex.toDouble();
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const navBarHeight = 70.0;
    return Container(
      height: navBarHeight,
      color: Colors.transparent,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(size.width, navBarHeight),
                painter: NavBarPainter(
                  position: _animation.value,
                  itemCount: widget.icons.length,
                  color: const Color(0xFF1F1F1F),
                ),
              );
            },
          ),
          Center(
            heightFactor: 1.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(widget.icons.length, (index) {
                return _buildNavItem(
                  icon: widget.icons[index],
                  isSelected: index == widget.selectedIndex,
                  onTap: () => widget.onItemTapped(index),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      {required IconData icon,
      required bool isSelected,
      required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.translationValues(0, isSelected ? -18 : 0, 0),
          child: Icon(
            icon,
            size: 26,
            color: isSelected ? const Color(0xFFE53935) : Colors.white60,
          ),
        ),
      ),
    );
  }
}

class NavBarPainter extends CustomPainter {
  final double position;
  final int itemCount;
  final Color color;
  NavBarPainter(
      {required this.position, required this.itemCount, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final itemWidth = size.width / itemCount;
    final notchCenter = (position * itemWidth) + (itemWidth / 2);
    const notchRadius = 30.0;
    const cornerRadius = 20.0;
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    path.lineTo(notchCenter - notchRadius, 0);
    path.arcToPoint(
      Offset(notchCenter + notchRadius, 0),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// -----------------------------------------------------------------------------
// HOME SCREEN CODE
// -----------------------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  final bool isDemoModeOn;
  const HomeScreen({super.key, required this.isDemoModeOn});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildFrostedTile(context),
                    Row(
                      children: [
                        Expanded(flex: 5, child: _buildVitalsContent()),
                        Expanded(flex: 4, child: _buildModel()),
                      ],
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

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.bluetooth_audio,
                color: Colors.white70, size: 28),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => BleScanScreen(
                  isDemoModeOn: isDemoModeOn,
                ),
              ));
            },
          ),
          Text(
            'PROJECT KAVACH',
            style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.5),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline,
                color: Colors.white70, size: 28),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedTile(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            width: size.width * 0.9,
            height: size.height * 0.6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30.0),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVitalsContent() {
    return Padding(
      padding: const EdgeInsets.only(left: 40.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Your Unseen Guardian',
            style: GoogleFonts.ebGaramond(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w600,
              fontSize: 36,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 40),
          _buildVitalsDisplay('Heart Rate', '72', 'BPM', Icons.favorite,
              const Color(0xFFE53935)),
          const SizedBox(height: 32),
          _buildVitalsDisplay(
              'SpO2', '98', '%', Icons.bubble_chart, const Color(0xFF00BCD4)),
          const SizedBox(height: 32),
          _buildVitalsDisplay('Mood', 'Anxiety', '',
              Icons.sentiment_very_dissatisfied, const Color(0xFFFFC107)),
        ],
      ),
    );
  }

  Widget _buildModel() {
    return Transform.translate(
      offset: const Offset(-40, 0),
      child: const ModelViewer(
        src: 'assets/uniform.glb',
        alt: "Uniform 3D Model",
        autoRotate: true,
        cameraControls: true,
        disableZoom: true,
        cameraOrbit: '0deg 90deg 4.8m',
        minCameraOrbit: 'auto 90deg 4.8m',
        maxCameraOrbit: 'auto 90deg 4.8m',
        fieldOfView: '22deg',
        backgroundColor: Colors.transparent,
      ),
    );
  }

  Widget _buildVitalsDisplay(
      String label, String value, String unit, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.1)),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (unit.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        unit,
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
