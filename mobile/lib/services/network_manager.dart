import 'package:flutter/foundation.dart';

enum NetworkType {
  none,
  wifi,
  cellular,
  ethernet,
}

class NetworkManager extends ChangeNotifier {
  NetworkType _networkType = NetworkType.none;
  String? _wifiSSID;
  bool _isHostReachableOnLAN = false;
  String? _hostLANAddress;

  NetworkType get networkType => _networkType;
  String? get wifiSSID => _wifiSSID;
  bool get isHostReachableOnLAN => _isHostReachableOnLAN;
  String? get hostLANAddress => _hostLANAddress;
  bool get isOnWiFi => _networkType == NetworkType.wifi;
  bool get isOnCellular => _networkType == NetworkType.cellular;
  bool get hasNetwork => _networkType != NetworkType.none;

  Future<void> initialize() async {
    // TODO: Set up network change listeners
    await checkNetwork();
  }

  Future<void> checkNetwork() async {
    // TODO: Implement actual network checking
    // For now, simulate network detection
    _networkType = NetworkType.wifi;
    _wifiSSID = 'Home WiFi';
    notifyListeners();

    await checkHostReachability();
  }

  Future<void> checkHostReachability() async {
    // TODO: Implement mDNS discovery
    // TODO: Try direct HTTP connection to host
    
    // Simulate host discovery
    await Future.delayed(const Duration(seconds: 1));
    _isHostReachableOnLAN = false; // Change based on actual discovery
    _hostLANAddress = null;
    
    notifyListeners();
  }

  Future<List<HostInfo>> discoverHosts({Duration timeout = const Duration(seconds: 5)}) async {
    // TODO: Implement mDNS discovery
    // Search for _pixlsrve._tcp.local. services
    
    await Future.delayed(timeout);
    return [];
  }

  void onNetworkChanged(NetworkType type, {String? ssid}) {
    _networkType = type;
    _wifiSSID = ssid;
    notifyListeners();

    // Trigger reachability check
    checkHostReachability();
  }

  void dispose() {
    // TODO: Clean up network listeners
    super.dispose();
  }
}

class HostInfo {
  final String hostId;
  final String name;
  final String ipAddress;
  final int port;
  final int photoCount;
  final int albumCount;

  HostInfo({
    required this.hostId,
    required this.name,
    required this.ipAddress,
    required this.port,
    required this.photoCount,
    required this.albumCount,
  });

  factory HostInfo.fromJson(Map<String, dynamic> json) {
    return HostInfo(
      hostId: json['host_id'] as String,
      name: json['host_name'] as String,
      ipAddress: '', // From mDNS
      port: json['api_port'] as int? ?? 8080,
      photoCount: json['photo_count'] as int? ?? 0,
      albumCount: json['album_count'] as int? ?? 0,
    );
  }
}
