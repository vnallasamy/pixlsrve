# PixlSrve System Architecture

## Overview

PixlSrve is a client-server photo hosting system designed for personal use with intelligent network mode switching.

## System Components

### 1. Host Application (Go)
- **Photo Indexer**: Scans and indexes photo directories
- **Thumbnail Generator**: Creates optimized previews
- **API Server**: REST/JSON API for mobile clients
- **WireGuard Server**: Manages VPN connections for remote access
- **mDNS Service**: Enables LAN discovery
- **Database**: SQLite for metadata and cache

### 2. Mobile Application (Flutter)
- **Network Manager**: Detects LAN vs remote connectivity
- **VPN Controller**: Manages WireGuard connections
- **Photo Gallery UI**: Fast, responsive photo browsing
- **Sync Manager**: Handles offline/online transitions

### 3. Control Plane (Optional)
- **Device Registry**: Tracks all paired devices
- **Key Management**: Handles WireGuard key distribution
- **User Authentication**: Email-based auth for multi-device

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

## Data Flow

### Photo Indexing
```
File System → File Watcher → Indexer → SQLite → Thumbnail Generator
```

### Mobile Gallery Request
```
Mobile → API Auth → Query Handler → SQLite → Response (metadata + thumbnails)
```

### Full Photo Fetch
```
Mobile → API Auth → File Retriever → Stream File → Mobile Display
```

## Security Model

- **Authentication**: Token-based API auth per device
- **Transport**: TLS for LAN, WireGuard for remote
- **Authorization**: Per-device keys, revocable access
- **Path Protection**: Prevent directory traversal attacks
- **Rate Limiting**: Protect against brute force

## VPN Lifecycle State Machine

```
┌─────────┐
│  IDLE   │ (App not running or LAN mode active)
└────┬────┘
     │ App needs remote access
     ▼
┌─────────┐
│CONNECTING│ (Starting VPN, handshake)
└────┬────┘
     │ Success
     ▼
┌─────────┐
│ ACTIVE  │ (VPN tunnel up, host reachable)
└────┬────┘
     │ LAN detected OR App backgrounded
     ▼
┌─────────┐
│TEARING  │ (Shutting down tunnel)
│  DOWN   │
└────┬────┘
     │
     ▼
┌─────────┐
│  IDLE   │
└─────────┘
```

## API Contract (Draft)

### Authentication
- `POST /api/v1/auth/pair` - Initial device pairing
- `POST /api/v1/auth/token` - Get access token

### Discovery
- mDNS service name: `_pixlsrve._tcp.local.`

### Photos
- `GET /api/v1/albums` - List all albums/folders
- `GET /api/v1/albums/:id/photos` - List photos in album
- `GET /api/v1/photos/:id/thumbnail` - Get thumbnail
- `GET /api/v1/photos/:id/full` - Get full resolution
- `GET /api/v1/photos/search?q=query` - Search photos

### VPN Management
- `GET /api/v1/vpn/config` - Get WireGuard config for device
- `POST /api/v1/vpn/revoke` - Revoke device access

## Development Roadmap

1. **Phase 1**: Host basic API + photo indexing
2. **Phase 2**: Mobile LAN mode + gallery UI
3. **Phase 3**: WireGuard integration + VPN mode
4. **Phase 4**: Automatic mode switching
5. **Phase 5**: Control plane + multi-device
6. **Phase 6**: Installers + CI/CD

## Technology Decisions

### Why Go for Host?
- Single binary deployment
- Excellent performance
- Strong stdlib (HTTP, file I/O)
- Easy cross-compilation

### Why Flutter for Mobile?
- Single codebase for iOS/Android
- Native performance
- Rich UI components

### Why WireGuard?
- Modern, secure protocol
- Low overhead
- Good mobile battery life
- Platform libraries available

### Why SQLite?
- Zero-configuration
- Embedded database
- Perfect for single-host use
- Fast for our use case