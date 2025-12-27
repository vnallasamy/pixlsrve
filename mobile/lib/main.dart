import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/vpn_manager.dart';
import 'services/network_manager.dart';
import 'services/api_client.dart';
import 'screens/home_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const PixlSrveApp());
}

class PixlSrveApp extends StatelessWidget {
  const PixlSrveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NetworkManager()),
        ChangeNotifierProvider(create: (_) => VPNManager()),
        ChangeNotifierProvider(create: (_) => APIClient()),
      ],
      child: MaterialApp(
        title: 'PixlSrve',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const AppRoot(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/pairing': (context) => const PairingScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _isConfigured = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  Future<void> _checkConfiguration() async {
    // TODO: Check if app is configured (device paired)
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isConfigured = false; // TODO: Load from storage
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isConfigured) {
      return const PairingScreen();
    }

    return const HomeScreen();
  }
}
