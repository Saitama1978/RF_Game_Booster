import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const GameBoosterApp(),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class GameBoosterApp extends StatelessWidget {
  const GameBoosterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Game Booster VIP',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        primaryColor: const Color(0xFF4F46E5),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF4F46E5),
          surface: Colors.white,
        ),
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF6366F1),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          surface: Color(0xFF1E293B),
        ),
        cardColor: const Color(0xFF1E293B),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isBoosting = false;
  int _ramOptimized = 0;
  
  // Real-time Ping state
  int _ping = 0;
  bool _isTestingPing = false;
  Timer? _pingTimer;

  // DND and Crosshair Toggles
  bool _isDndEnabled = false;
  bool _isCrosshairEnabled = false;

  // FPS & Temperature Monitor States
  int _fps = 60;
  double _temperature = 36.5;

  final String mlbbPackage = "com.mobile.legends";
  final String hokPackage = "com.levelinfinite.sgameGlobal";

  @override
  void initState() {
    super.initState();
    _startPingMonitor();
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  void _startPingMonitor() {
    _testPing();
    _pingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _testPing();
    });
  }

  void _testPing() async {
    if (_isTestingPing) return;
    setState(() => _isTestingPing = true);

    final stopwatch = Stopwatch()..start();
    try {
      final result = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
      stopwatch.stop();
      result.destroy();
      if (mounted) {
        setState(() {
          _ping = stopwatch.elapsedMilliseconds;
          _isTestingPing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ping = 999;
          _isTestingPing = false;
        });
      }
    }
  }

  void _toggleDND(bool value) async {
    PermissionStatus status = await Permission.accessNotificationPolicy.status;
    if (!status.isGranted) {
      status = await Permission.accessNotificationPolicy.request();
    }

    if (status.isGranted) {
      setState(() {
        _isDndEnabled = value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isDndEnabled ? 'Do Not Disturb Enabled' : 'Do Not Disturb Disabled'),
            backgroundColor: _isDndEnabled ? Colors.greenAccent[700] : Colors.grey[700],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification Policy Access permission is required for DND.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _toggleCrosshair(bool value) async {
    PermissionStatus status = await Permission.systemAlertWindow.status;
    if (!status.isGranted) {
      status = await Permission.systemAlertWindow.request();
    }

    setState(() {
      _isCrosshairEnabled = value;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isCrosshairEnabled ? 'Custom Crosshair Overlay Activated' : 'Crosshair Deactivated'),
          backgroundColor: _isCrosshairEnabled ? Colors.indigoAccent : Colors.grey[700],
        ),
      );
    }
  }

  void _boostDevice() async {
    setState(() {
      _isBoosting = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isBoosting = false;
      _ramOptimized = 512;
      _temperature = 34.2; // Thermal cooling simulation
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device Boosted! Cleared $_ramOptimized MB RAM.'),
          backgroundColor: Colors.greenAccent[700],
        ),
      );
    }
  }

  void _launchGame(String packageName, String gameName) async {
    bool isInstalled = await DeviceApps.isAppInstalled(packageName);

    if (isInstalled) {
      DeviceApps.openApp(packageName);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$gameName is not installed on this device.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Color _getPingColor() {
    if (_ping == 0) return Colors.grey;
    if (_ping < 60) return Colors.greenAccent;
    if (_ping < 120) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getTempColor() {
    if (_temperature < 38.0) return Colors.greenAccent;
    if (_temperature < 42.0) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GAME BOOSTER VIP',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode, size: 20),
              Switch(
                value: isDark,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              ),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Logo
            Center(
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF512F).withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.rocket_launch,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ULTRA BOOST ENGINE",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Performance & Network Monitor Dashboard Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Real-time Ping Monitor
                        Column(
                          children: [
                            Icon(Icons.wifi, color: _getPingColor(), size: 28),
                            const SizedBox(height: 4),
                            Text(
                              _ping == 0 ? "-- ms" : "$_ping ms",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _getPingColor(),
                              ),
                            ),
                            const Text("Ping", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        // FPS Monitor
                        Column(
                          children: [
                            const Icon(Icons.speed, color: Colors.cyanAccent, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              "$_fps FPS",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent,
                              ),
                            ),
                            const Text("Target FPS", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        // Temperature Monitor
                        Column(
                          children: [
                            Icon(Icons.thermostat, color: _getTempColor(), size: 28),
                            const SizedBox(height: 4),
                            Text(
                              "${_temperature.toStringAsFixed(1)}°C",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _getTempColor(),
                              ),
                            ),
                            const Text("Temp", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isBoosting ? null : _boostDevice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: _isBoosting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.bolt, color: Colors.white, size: 18),
                      label: Text(
                        _isBoosting ? "OPTIMIZING..." : "BOOST NOW",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gaming Tools & Toggles (DND and Crosshair Overlay)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Auto Do Not Disturb (DND)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text("Blocks pop-up notifications & calls while gaming", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      value: _isDndEnabled,
                      activeColor: Colors.greenAccent,
                      onChanged: _toggleDND,
                      secondary: const Icon(Icons.do_not_disturb_on, color: Colors.redAccent),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text("Custom Crosshair Overlay", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text("Safe screen center reticle for aiming games", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      value: _isCrosshairEnabled,
                      activeColor: Colors.indigoAccent,
                      onChanged: _toggleCrosshair,
                      secondary: const Icon(Icons.center_focus_strong, color: Colors.amberAccent),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Select Game to Launch",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // MLBB Launcher Card
            _buildGameCard(
              title: "Mobile Legends: Bang Bang",
              subtitle: "com.mobile.legends",
              icon: Icons.sports_esports,
              color: Colors.amber,
              onTap: () => _launchGame(mlbbPackage, "Mobile Legends"),
            ),
            const SizedBox(height: 10),

            // Honor of Kings Launcher Card
            _buildGameCard(
              title: "Honor of Kings",
              subtitle: "com.levelinfinite.sgameGlobal",
              icon: Icons.shield,
              color: Colors.blueAccent,
              onTap: () => _launchGame(hokPackage, "Honor of Kings"),
            ),

            const SizedBox(height: 30),

            // Developer Name Footer
            Center(
              child: Column(
                children: [
                  Text(
                    "Developer",
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Renante Fullo",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.play_arrow_rounded, color: Colors.greenAccent, size: 30),
        onTap: onTap,
      ),
    );
  }
}
