import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/network_manager.dart';
import '../services/vpn_manager.dart';
import '../services/api_client.dart';
import 'albums_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeConnection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final vpnManager = context.read<VPNManager>();
    
    if (state == AppLifecycleState.resumed) {
      vpnManager.onAppResumed();
      _checkConnection();
    } else if (state == AppLifecycleState.paused) {
      vpnManager.onAppPaused();
    }
  }

  Future<void> _initializeConnection() async {
    final networkManager = context.read<NetworkManager>();
    final vpnManager = context.read<VPNManager>();

    await networkManager.initialize();
    await _checkConnection();
  }

  Future<void> _checkConnection() async {
    final networkManager = context.read<NetworkManager>();
    final vpnManager = context.read<VPNManager>();

    await networkManager.checkHostReachability();

    await vpnManager.determineConnectionMode(
      isHostReachableOnLAN: networkManager.isHostReachableOnLAN,
      isOnWiFi: networkManager.isOnWiFi,
      currentSSID: networkManager.wifiSSID,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PixlSrve'),
        actions: [
          Consumer<VPNManager>(
            builder: (context, vpnManager, child) {
              return _buildConnectionIndicator(vpnManager.state);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Consumer<VPNManager>(
        builder: (context, vpnManager, child) {
          if (vpnManager.state == VPNState.connecting) {
            return _buildConnectingUI(vpnManager);
          } else if (vpnManager.state == VPNState.vpnError) {
            return _buildErrorUI(vpnManager);
          } else if (vpnManager.state == VPNState.lanMode ||
                     vpnManager.state == VPNState.vpnActive) {
            return const AlbumsScreen();
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Widget _buildConnectionIndicator(VPNState state) {
    IconData icon;
    Color color;
    String tooltip;

    switch (state) {
      case VPNState.lanMode:
        icon = Icons.wifi;
        color = Colors.green;
        tooltip = 'Connected via LAN';
        break;
      case VPNState.vpnActive:
        icon = Icons.vpn_lock;
        color = Colors.blue;
        tooltip = 'Connected via VPN';
        break;
      case VPNState.connecting:
        icon = Icons.sync;
        color = Colors.orange;
        tooltip = 'Connecting...';
        break;
      case VPNState.vpnError:
        icon = Icons.error;
        color = Colors.red;
        tooltip = 'Connection Error';
        break;
      default:
        icon = Icons.cloud_off;
        color = Colors.grey;
        tooltip = 'Not Connected';
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Tooltip(
        message: tooltip,
        child: Icon(icon, color: color),
      ),
    );
  }

  Widget _buildConnectingUI(VPNManager vpnManager) {
    final phaseNames = {
      ConnectionPhase.checkingNetwork: 'Checking network',
      ConnectionPhase.startingVPN: 'Starting VPN',
      ConnectionPhase.handshake: 'Handshake',
      ConnectionPhase.verifyingHost: 'Verifying host',
      ConnectionPhase.loadingLibrary: 'Loading library',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Connecting to Photo Library',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ...ConnectionPhase.values.map((phase) {
              final isActive = vpnManager.phase == phase;
              final isDone = vpnManager.phase != null &&
                             phase.index < vpnManager.phase!.index;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      isDone ? Icons.check_circle : 
                      isActive ? Icons.circle : Icons.circle_outlined,
                      color: isDone ? Colors.green :
                             isActive ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      phaseNames[phase]!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () {
                context.read<VPNManager>().tearDown();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorUI(VPNManager vpnManager) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Connection Failed',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              vpnManager.errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Text(
              'Troubleshooting:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Check internet connection'),
            const Text('• Verify host is online'),
            const Text('• Try LAN connection'),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context.read<VPNManager>().reconnect();
                    _checkConnection();
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () {
                    // Try LAN mode
                    context.read<VPNManager>().setLanOnly(true);
                    _checkConnection();
                  },
                  child: const Text('Use LAN'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
