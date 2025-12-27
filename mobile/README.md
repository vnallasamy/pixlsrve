# Mobile Application

Flutter-based iOS and Android app for accessing your photos with automatic LAN/VPN mode switching.

## Features

- Automatic LAN/VPN mode switching
- Fast photo gallery with thumbnails
- Full-resolution photo viewing
- Native VPN integration (NetworkExtension/VpnService)
- mDNS discovery for LAN hosts
- Background/foreground lifecycle management
- Manual VPN override settings

## Requirements

- Flutter 3.0 or later
- iOS 14+ or Android 10+
- For VPN functionality:
  - iOS: NetworkExtension entitlements
  - Android: VpnService permissions

## Development

### Setup

```bash
cd mobile
flutter pub get
```

### Run on iOS Simulator

```bash
flutter run -d "iPhone 15 Pro"
```

### Run on Android Emulator

```bash
flutter run -d emulator-5554
```

### Run on Physical Device

```bash
# iOS
flutter run -d <device-id>

# Android
flutter run -d <device-id>
```

## Project Structure

```
mobile/
├── lib/
│   ├── main.dart              # App entry point
│   ├── models/                # Data models
│   ├── screens/               # UI screens
│   │   ├── home_screen.dart
│   │   ├── albums_screen.dart
│   │   ├── album_photos_screen.dart
│   │   ├── pairing_screen.dart
│   │   └── settings_screen.dart
│   ├── services/              # Business logic
│   │   ├── api_client.dart
│   │   ├── vpn_manager.dart
│   │   └── network_manager.dart
│   ├── widgets/               # Reusable widgets
│   └── utils/                 # Utilities
├── android/                   # Android-specific code
├── ios/                       # iOS-specific code
└── pubspec.yaml              # Dependencies
```

## Key Components

### VPN Manager

Implements the VPN lifecycle state machine:
- `IDLE`: No VPN active
- `DETERMINING`: Checking network conditions
- `LAN_MODE`: Direct connection on local network
- `VPN_REQUIRED`: Remote access needed
- `CONNECTING`: Establishing VPN tunnel
- `VPN_ACTIVE`: VPN connected
- `VPN_ERROR`: Connection failed
- `TEARING_DOWN`: Shutting down VPN

### Network Manager

Handles network detection and host discovery:
- Monitors network changes (Wi-Fi ↔ cellular)
- mDNS service discovery
- Host reachability checks
- Network type detection

### API Client

Manages all API communication:
- Automatic LAN/VPN mode switching
- Authentication with Bearer tokens
- Photo and album endpoints
- Image caching

## VPN Configuration

### iOS (NetworkExtension)

Add to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>network-authentication</string>
</array>
```

Add Network Extension entitlement.

### Android (VpnService)

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

## Building for Release

### iOS

```bash
flutter build ios --release
```

Then open in Xcode to archive and submit to App Store.

### Android

```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

## Testing

```bash
# Run tests
flutter test

# Run integration tests
flutter test integration_test/

# Generate coverage
flutter test --coverage
```

## VPN Lifecycle Testing

Key scenarios to test:

1. **LAN to VPN transition**: Start on Wi-Fi, switch to cellular
2. **VPN to LAN transition**: Start on cellular, connect to home Wi-Fi
3. **Background/foreground**: VPN should teardown when backgrounded
4. **Network loss**: Handle gracefully when network disconnects
5. **User overrides**: Test "Always VPN", "Never VPN on Wi-Fi", "LAN Only" modes

See [../docs/TEST_PLAN.md](../docs/TEST_PLAN.md) for complete test scenarios.

## Troubleshooting

### VPN not connecting

- Check internet connectivity
- Verify host is reachable
- Ensure WireGuard configuration is valid
- Check firewall allows WireGuard port (51820)

### mDNS discovery not working

- Ensure devices on same Wi-Fi network
- Check router allows mDNS/Bonjour
- Try manual pairing with IP address

### App crashes on launch

- Run `flutter clean && flutter pub get`
- Check for missing permissions in manifests
- Review logs: `flutter logs`

## Platform-Specific Notes

### iOS

- VPN requires NetworkExtension entitlements
- App must be code signed for VPN to work
- Cannot test VPN in simulator (needs real device)

### Android

- VPN requires VpnService
- User must grant VPN permission on first use
- VPN icon appears in status bar when active

## License

TBD