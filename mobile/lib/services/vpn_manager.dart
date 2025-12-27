import 'package:flutter/foundation.dart';

enum VPNState {
  idle,
  determining,
  lanMode,
  vpnRequired,
  connecting,
  vpnActive,
  vpnError,
  tearingDown,
}

enum ConnectionPhase {
  checkingNetwork,
  startingVPN,
  handshake,
  verifyingHost,
  loadingLibrary,
}

class VPNManager extends ChangeNotifier {
  VPNState _state = VPNState.idle;
  ConnectionPhase? _phase;
  String? _errorMessage;
  DateTime? _lastHandshake;
  int _retryCount = 0;

  VPNState get state => _state;
  ConnectionPhase? get phase => _phase;
  String? get errorMessage => _errorMessage;
  DateTime? get lastHandshake => _lastHandshake;
  bool get isConnected => _state == VPNState.vpnActive;

  // Configuration
  bool _alwaysUseVPN = false;
  bool _neverUseVPNOnWiFi = false;
  bool _lanOnly = false;
  List<String> _trustedNetworks = [];

  bool get alwaysUseVPN => _alwaysUseVPN;
  bool get neverUseVPNOnWiFi => _neverUseVPNOnWiFi;
  bool get lanOnly => _lanOnly;
  List<String> get trustedNetworks => _trustedNetworks;

  void setAlwaysUseVPN(bool value) {
    _alwaysUseVPN = value;
    notifyListeners();
  }

  void setNeverUseVPNOnWiFi(bool value) {
    _neverUseVPNOnWiFi = value;
    notifyListeners();
  }

  void setLanOnly(bool value) {
    _lanOnly = value;
    notifyListeners();
  }

  void addTrustedNetwork(String ssid) {
    if (!_trustedNetworks.contains(ssid)) {
      _trustedNetworks.add(ssid);
      notifyListeners();
    }
  }

  void removeTrustedNetwork(String ssid) {
    _trustedNetworks.remove(ssid);
    notifyListeners();
  }

  Future<void> determineConnectionMode({
    required bool isHostReachableOnLAN,
    required bool isOnWiFi,
    String? currentSSID,
  }) async {
    _setState(VPNState.determining);

    // Check user overrides
    if (_lanOnly) {
      if (isHostReachableOnLAN) {
        _setState(VPNState.lanMode);
      } else {
        _setError('LAN Only mode enabled. Cannot reach host on LAN.');
      }
      return;
    }

    if (_alwaysUseVPN) {
      await _startVPNConnection();
      return;
    }

    if (_neverUseVPNOnWiFi && isOnWiFi) {
      if (isHostReachableOnLAN) {
        _setState(VPNState.lanMode);
      } else {
        _setError('Never Use VPN on Wi-Fi enabled. Host not reachable.');
      }
      return;
    }

    // Auto mode
    if (isHostReachableOnLAN) {
      _setState(VPNState.lanMode);
    } else {
      await _startVPNConnection();
    }
  }

  Future<void> _startVPNConnection() async {
    _setState(VPNState.connecting);
    _retryCount++;

    try {
      // Phase 1: Checking network
      _setPhase(ConnectionPhase.checkingNetwork);
      await Future.delayed(const Duration(milliseconds: 500));

      // Phase 2: Starting VPN
      _setPhase(ConnectionPhase.startingVPN);
      await Future.delayed(const Duration(seconds: 1));
      // TODO: Actually start VPN

      // Phase 3: Handshake
      _setPhase(ConnectionPhase.handshake);
      await Future.delayed(const Duration(seconds: 2));
      // TODO: Perform WireGuard handshake
      _lastHandshake = DateTime.now();

      // Phase 4: Verifying host
      _setPhase(ConnectionPhase.verifyingHost);
      await Future.delayed(const Duration(seconds: 1));
      // TODO: Verify host API is reachable

      // Phase 5: Loading library
      _setPhase(ConnectionPhase.loadingLibrary);
      await Future.delayed(const Duration(milliseconds: 500));

      // Success
      _setState(VPNState.vpnActive);
      _phase = null;
      _retryCount = 0;
    } catch (e) {
      _setError('VPN connection failed: $e');
      
      if (_retryCount < 3) {
        // Retry with exponential backoff
        final delay = Duration(seconds: _retryCount * 5);
        await Future.delayed(delay);
        await _startVPNConnection();
      }
    }
  }

  Future<void> tearDown() async {
    if (_state == VPNState.idle || _state == VPNState.lanMode) {
      return;
    }

    _setState(VPNState.tearingDown);

    try {
      // TODO: Actually tear down VPN
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('Error tearing down VPN: $e');
    }

    _setState(VPNState.idle);
  }

  Future<void> reconnect() async {
    await tearDown();
    _retryCount = 0;
    _errorMessage = null;
    // Will be triggered by network manager
  }

  void _setState(VPNState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setPhase(ConnectionPhase newPhase) {
    _phase = newPhase;
    notifyListeners();
  }

  void _setError(String message) {
    _state = VPNState.vpnError;
    _errorMessage = message;
    _phase = null;
    notifyListeners();
  }

  // App lifecycle handlers
  void onAppResumed() {
    if (_state == VPNState.idle) {
      // Trigger connection check
    }
  }

  void onAppPaused() {
    if (_state == VPNState.vpnActive || _state == VPNState.connecting) {
      tearDown();
    }
  }
}
