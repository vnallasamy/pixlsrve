# PixlSrve - Personal Photo Host

A production-grade cross-platform photo hosting system with secure LAN and internet access via WireGuard.

## Overview

PixlSrve allows users to: 
- Host photos from their Windows/macOS computer
- Access photos via native iOS/Android mobile apps
- Automatic LAN detection (direct connection when on same network)
- Secure remote access via WireGuard VPN when away from home
- Zero-cost infrastructure with optional LAN-only mode

## Key Features

### Mobile App
- **Smart Connection Mode**: Automatically switches between LAN and VPN
- **VPN Lifecycle Management**: Connects VPN when needed, tears down when backgrounded
- **Fast Photo Gallery**: Responsive thumbnail browsing
- **Full-Resolution Viewing**: Interactive photo viewer with zoom
- **Settings**: Manual overrides for "Always VPN", "Never VPN on Wi-Fi", "LAN Only"

### Host App
- **Photo Indexing**: Automatic scanning and indexing of photo directories
- **File Watching**: Real-time detection of new photos
- **REST API**: JSON API for mobile clients
- **mDNS Discovery**: Zero-config LAN discovery
- **WireGuard Server**: Secure remote access
- **SQLite Database**: Fast metadata storage

## Architecture

- **Host App**: Go-based server with SQLite database
- **Mobile App**: Flutter UI with native VPN integration
- **VPN**: WireGuard with per-device keys
- **Control Plane**: Optional Go service for multi-device management

## Repository Structure

```
pixlsrve/
├── host/              # Go-based host application
├── mobile/            # Flutter mobile app
├── control-plane/     # Optional control plane service
├── docs/              # Architecture and API documentation
├── scripts/           # Development helper scripts
└── .github/           # CI/CD workflows
```

## Quick Start

### Prerequisites

- **Host**: Go 1.21+, GCC (for SQLite)
- **Mobile**: Flutter 3.0+
- **VPN**: WireGuard tools (optional)

### 1. Build and Run Host

```bash
# Build
cd host
go build -o pixlsrve ./cmd/pixlsrve

# Or use dev script
./scripts/dev.sh build-host

# Run
./host/pixlsrve
```

On first run, the host creates `~/.pixlsrve/config.json`. Edit this file to add your photo directories:

```json
{
  "photo_roots": [
    "/Users/username/Pictures",
    "/Users/username/Photos"
  ],
  "initial_scan": true
}
```

Restart the host to scan your photos.

### 2. Access from Mobile

**Option A: Use Pre-built APK/IPA** (coming soon)

**Option B: Build from source**

```bash
cd mobile
flutter pub get
flutter run
```

### 3. Pair Device

1. Open mobile app
2. Tap "Scan QR Code"
3. On host, navigate to admin UI (http://localhost:8080)
4. Generate pairing QR code
5. Scan with mobile app

## Documentation

- [Architecture Overview](docs/ARCHITECTURE.md) - System design and components
- [API Specification](docs/API_SPEC.md) - REST API endpoints and data formats
- [VPN Lifecycle](docs/VPN_LIFECYCLE.md) - VPN state machine and mode switching
- [Threat Model](docs/THREAT_MODEL.md) - Security analysis and mitigations
- [Test Plan](docs/TEST_PLAN.md) - End-to-end testing scenarios

## Development

### Host Application

See [host/README.md](host/README.md) for:
- Build instructions
- Configuration
- API endpoints
- Cross-platform builds

### Mobile Application

See [mobile/README.md](mobile/README.md) for:
- Setup
- Running on iOS/Android
- VPN integration
- Testing

### Development Scripts

```bash
# Build host
./scripts/dev.sh build-host

# Run host
./scripts/dev.sh run-host

# Clean build artifacts
./scripts/dev.sh clean
```

## CI/CD

GitHub Actions workflows automatically build the host and mobile apps on every push:

- **Host**: Builds on Linux, macOS, Windows
- **Mobile**: Builds Android APK and iOS (no codesign)

See `.github/workflows/` for configuration.

## Network Modes

### LAN Mode (Direct Connection)
```
[Mobile App] --WiFi--> [Host App]
```
- mDNS discovery locates host
- Direct HTTP/JSON API connection
- No VPN overhead
- Fastest performance

### VPN Mode (Remote Access)
```
[Mobile App] --Internet--> [WireGuard Tunnel] ---> [Host App]
```
- WireGuard tunnel established
- Encrypted connection over internet
- Automatic host reachability check
- Seamless fallback when LAN unavailable

### Mode Switching Logic
1. App launch: Check host reachability on LAN
2. If reachable → LAN Mode
3. If not reachable → VPN Mode
4. Network change detected → Re-evaluate mode
5. App background/close → Tear down VPN

## Security

- **Authentication**: Token-based API auth per device
- **Transport**: TLS for LAN, WireGuard for remote
- **Authorization**: Per-device keys, revocable access
- **Path Protection**: Prevent directory traversal attacks
- **Rate Limiting**: Protect against brute force

See [docs/THREAT_MODEL.md](docs/THREAT_MODEL.md) for complete security analysis.

## Roadmap

### Current Status (v1.0)
- ✅ Host photo indexing
- ✅ REST API server
- ✅ mDNS discovery
- ✅ Mobile VPN state machine
- ✅ Photo gallery UI
- ✅ CI/CD pipelines

### Planned Features
- [ ] Thumbnail generation (currently stub)
- [ ] WireGuard server (currently stub)
- [ ] QR code pairing
- [ ] Device management UI
- [ ] Photo search
- [ ] EXIF metadata extraction
- [ ] Windows/macOS installers
- [ ] Optional control plane

## Contributing

This is a personal project demonstration. For production use, additional work is needed:

1. Complete VPN implementation
2. Add comprehensive tests
3. Security audit
4. Performance optimization
5. UI/UX improvements

## Tech Stack

### Backend
- **Language**: Go 1.21
- **Database**: SQLite with WAL mode
- **VPN**: WireGuard
- **Discovery**: mDNS/Bonjour

### Mobile
- **Framework**: Flutter 3.0+
- **State Management**: Provider
- **Networking**: dio, http
- **VPN**: NetworkExtension (iOS), VpnService (Android)

### Infrastructure
- **CI/CD**: GitHub Actions
- **Deployment**: Single binary, systemd/launchd service
- **Hosting**: Self-hosted (no cloud required)

## License

TBD

## Acknowledgments

Built following the requirements for a production-grade personal photo hosting system with:
- Automatic LAN/VPN mode switching
- Mobile-first design
- Zero-cost infrastructure
- Security best practices
- Comprehensive documentation