// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:permission_handler/permission_handler.dart';

// --- IMPORTS ---
// Ensure these file paths exactly match your project structure
import 'package:project_kavach_app/live_screen.dart'; 
import 'package:project_kavach_app/ble_scan_screen.dart';
import 'package:project_kavach_app/map_screen.dart';
import 'package:project_kavach_app/providers/ble_provider.dart';
import 'package:project_kavach_app/screens/incoming_call_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Project Kavach',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0A12),
          textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
        ),
        home: const MainScreen(),
      ),
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
  int _selectedIndex = 2; // Default to Home

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _setupGlobalAlertListener();
  }

  // 1. Request Permissions
  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.notification,
    ].request();
  }

  // 2. Global Listener for the Call Alert (Loop Break)
  void _setupGlobalAlertListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bleProvider = Provider.of<BleProvider>(context, listen: false);
      bleProvider.alertStream.listen((isAlert) {
        if (isAlert) {
          // Trigger the Call Screen immediately on Loop Break
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const IncomingCallScreen()),
          );
        }
      });
    });
  }

  // 3. Page Navigation Configuration
  List<Widget> _getPages() {
    return <Widget>[
      // Index 0: Charts/Live Data
      LiveScreen(
        isDemoModeOn: _isDemoModeOn,
        onDemoModeChanged: (value) {
          setState(() {
            _isDemoModeOn = value;
          });
        },
      ),
      // Index 1: Map
      const MapScreen(),
      // Index 2: Home Dashboard
      HomeScreen(isDemoModeOn: _isDemoModeOn),
      // Index 3: History
      const Center(
          child: Text('History Page', style: TextStyle(color: Colors.white))),
      // Index 4: More/Menu
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
        children: _getPages(),
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
// HOME SCREEN (Dashboard with 3D Model & Real Data)
// -----------------------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  final bool isDemoModeOn;
  const HomeScreen({super.key, required this.isDemoModeOn});

  @override
  Widget build(BuildContext context) {
    // Access BLE Provider to listen for changes
    final ble = Provider.of<BleProvider>(context);

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
              _buildCustomAppBar(context, ble),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildFrostedTile(context),
                    Row(
                      children: [
                        // Left Side: Vitals
                        Expanded(flex: 5, child: _buildVitalsContent(ble)),
                        // Right Side: 3D Model
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

  // --- NEW DYNAMIC APP BAR ---
  Widget _buildCustomAppBar(BuildContext context, BleProvider ble) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Fallback Scan Screen Button (Optional)
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
          
          // Center: Title
          Text(
            'PROJECT KAVACH',
            style: GoogleFonts.roboto(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.5),
          ),

          // Right: THE NEW DYNAMIC CONNECT BUTTON
          GestureDetector(
            onTap: () {
              // Prevent double-clicking while scanning
              if (ble.isScanning) return;

              if (ble.isConnected) {
                ble.disconnect();
              } else {
                ble.startScanAndConnect();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                // Color Logic: Green (Connected) / Amber (Scanning) / Grey (Idle)
                color: ble.isConnected
                    ? Colors.green.withOpacity(0.2)
                    : ble.isScanning
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: ble.isConnected
                      ? Colors.greenAccent
                      : ble.isScanning
                          ? Colors.amberAccent
                          : Colors.white24,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Logic: Spinner or Static Icon
                  if (ble.isScanning)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.amberAccent,
                      ),
                    )
                  else
                    Icon(
                      ble.isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                      color: ble.isConnected ? Colors.greenAccent : Colors.white70,
                      size: 18,
                    ),
                  const SizedBox(width: 8),
                  
                  // Text Logic
                  Text(
                    ble.isConnected
                        ? "CONNECTED"
                        : ble.isScanning
                            ? "SCANNING..."
                            : "PAIR",
                    style: TextStyle(
                      color: ble.isConnected
                          ? Colors.greenAccent
                          : ble.isScanning
                              ? Colors.amberAccent
                              : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
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

  // --- CONNECTED TO REAL DATA ---
  Widget _buildVitalsContent(BleProvider ble) {
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
          
          // 1. Heart Rate (Real Data)
          _buildVitalsDisplay(
              'Heart Rate',
              ble.isConnected && ble.bpm > 0 ? '${ble.bpm}' : '--', 
              'BPM',
              Icons.favorite,
              const Color(0xFFE53935)),
              
          const SizedBox(height: 32),
          
          // 2. SpO2 (Static for now, or derive from code if available)
          _buildVitalsDisplay(
              'SpO2', 
              ble.isConnected ? '98' : '--', 
              '%', 
              Icons.bubble_chart, 
              const Color(0xFF00BCD4)),
              
          const SizedBox(height: 32),
          
          // 3. System Status (Based on connection)
          _buildVitalsDisplay(
              'Status',
              ble.isConnected ? 'Active' : 'Offline',
              '',
              ble.isConnected ? Icons.check_circle : Icons.error_outline,
              ble.isConnected ? Colors.greenAccent : Colors.grey),
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

// -----------------------------------------------------------------------------
// NAVIGATION BAR WIDGET (Preserved)
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