# PixlSrve - Personal Photo Host

A production-grade cross-platform photo hosting system with secure LAN and internet access via WireGuard.

## Overview

PixlSrve allows users to: 
- Host photos from their Windows/macOS computer
- Access photos via native iOS/Android mobile apps
- Automatic LAN detection (direct connection when on same network)
- Secure remote access via WireGuard VPN when away from home
- Zero-cost infrastructure with optional LAN-only mode

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
└── docs/              # Architecture and API documentation
```

## Getting Started

*Coming soon - project structure in development*

## Tech Stack

- **Backend**: Go, SQLite, WireGuard
- **Mobile**: Flutter, NetworkExtension (iOS), VpnService (Android)
- **VPN**: WireGuard with automatic LAN/VPN switching

## License

TBD