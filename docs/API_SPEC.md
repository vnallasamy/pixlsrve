# PixlSrve API Specification v1

## Base URL

- **LAN Mode**: `http://<host-ip>:8080`
- **VPN Mode**: `http://10.100.0.1:8080`

All API endpoints require authentication via Bearer token unless specified otherwise.

## Authentication

### Device Pairing

#### `POST /api/v1/auth/pair`

Initial device pairing - generates QR code data.

**Request:**
```json
{
  "device_name": "John's iPhone",
  "device_type": "ios",
  "public_key": "wireguard_public_key_base64"
}
```

**Response:**
```json
{
  "device_id": "uuid",
  "api_token": "jwt_token",
  "wireguard_config": {
    "private_key": "device_private_key",
    "server_public_key": "server_public_key",
    "server_endpoint": "192.168.1.100:51820",
    "allowed_ips": "10.100.0.0/24",
    "device_ip": "10.100.0.2/32",
    "dns": "10.100.0.1"
  },
  "host_id": "host_uuid",
  "host_name": "John's Mac"
}
```

#### `POST /api/v1/auth/token/refresh`

Refresh an expired token.

**Request:**
```json
{
  "device_id": "uuid",
  "refresh_token": "refresh_jwt"
}
```

**Response:**
```json
{
  "api_token": "new_jwt_token",
  "refresh_token": "new_refresh_token",
  "expires_in": 3600
}
```

#### `POST /api/v1/auth/revoke`

Revoke device access (requires admin token).

**Request:**
```json
{
  "device_id": "uuid"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Device access revoked"
}
```

## Discovery

### mDNS Service

**Service Type:** `_pixlsrve._tcp.local.`

**TXT Records:**
- `host_id=<uuid>`
- `version=1.0.0`
- `api_port=8080`
- `secure=true`
- `name=<host_name>`

### Manual Discovery

#### `GET /api/v1/discovery/info`

Get host information (no auth required for LAN).

**Response:**
```json
{
  "host_id": "uuid",
  "host_name": "John's Mac",
  "version": "1.0.0",
  "api_version": "v1",
  "capabilities": ["wireguard", "thumbnails", "search"],
  "photo_count": 12458,
  "album_count": 45
}
```

## Albums & Folders

### `GET /api/v1/albums`

List all albums/photo folders.

**Query Parameters:**
- `page` (int): Page number (default: 1)
- `limit` (int): Items per page (default: 50, max: 200)
- `sort` (string): Sort field (name, date, photo_count)
- `order` (string): asc or desc

**Response:**
```json
{
  "albums": [
    {
      "id": "uuid",
      "name": "Summer 2023",
      "path": "/Photos/Summer 2023",
      "photo_count": 234,
      "cover_photo_id": "photo_uuid",
      "cover_thumbnail_url": "/api/v1/photos/photo_uuid/thumbnail",
      "created_at": "2023-06-01T00:00:00Z",
      "updated_at": "2023-08-31T23:59:59Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 50,
    "total": 45,
    "total_pages": 1
  }
}
```

### `GET /api/v1/albums/:id`

Get album details.

**Response:**
```json
{
  "id": "uuid",
  "name": "Summer 2023",
  "path": "/Photos/Summer 2023",
  "photo_count": 234,
  "size_bytes": 2147483648,
  "cover_photo_id": "photo_uuid",
  "created_at": "2023-06-01T00:00:00Z",
  "updated_at": "2023-08-31T23:59:59Z",
  "sub_albums": []
}
```

### `GET /api/v1/albums/:id/photos`

List photos in an album.

**Query Parameters:**
- `page` (int): Page number
- `limit` (int): Items per page (default: 100, max: 500)
- `sort` (string): date, name, size
- `order` (string): asc or desc

**Response:**
```json
{
  "photos": [
    {
      "id": "uuid",
      "filename": "IMG_1234.jpg",
      "album_id": "album_uuid",
      "size_bytes": 4194304,
      "width": 4032,
      "height": 3024,
      "format": "jpeg",
      "taken_at": "2023-07-15T14:30:00Z",
      "created_at": "2023-07-15T14:30:00Z",
      "modified_at": "2023-07-15T14:30:00Z",
      "thumbnail_url": "/api/v1/photos/uuid/thumbnail",
      "metadata": {
        "camera": "iPhone 14 Pro",
        "location": {
          "latitude": 37.7749,
          "longitude": -122.4194
        }
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 100,
    "total": 234,
    "total_pages": 3
  }
}
```

## Photos

### `GET /api/v1/photos/:id`

Get photo metadata.

**Response:**
```json
{
  "id": "uuid",
  "filename": "IMG_1234.jpg",
  "album_id": "album_uuid",
  "path": "/Photos/Summer 2023/IMG_1234.jpg",
  "size_bytes": 4194304,
  "width": 4032,
  "height": 3024,
  "format": "jpeg",
  "taken_at": "2023-07-15T14:30:00Z",
  "created_at": "2023-07-15T14:30:00Z",
  "modified_at": "2023-07-15T14:30:00Z",
  "thumbnail_url": "/api/v1/photos/uuid/thumbnail",
  "full_url": "/api/v1/photos/uuid/full",
  "metadata": {
    "camera": "iPhone 14 Pro",
    "lens": "iPhone 14 Pro back triple camera 6.86mm f/1.78",
    "iso": 64,
    "exposure": "1/120",
    "aperture": "f/1.78",
    "location": {
      "latitude": 37.7749,
      "longitude": -122.4194,
      "altitude": 15.2
    }
  }
}
```

### `GET /api/v1/photos/:id/thumbnail`

Get photo thumbnail (JPEG, 400x400 max).

**Query Parameters:**
- `size` (string): small (200x200), medium (400x400), large (800x800)

**Response:**
- Content-Type: `image/jpeg`
- Binary image data
- Headers: `Cache-Control: public, max-age=31536000`

### `GET /api/v1/photos/:id/full`

Get full-resolution photo.

**Query Parameters:**
- `download` (bool): If true, set Content-Disposition to attachment

**Response:**
- Content-Type: `image/jpeg`, `image/png`, `image/heic`, etc.
- Binary image data
- Headers: `Accept-Ranges: bytes` (supports range requests)

### `GET /api/v1/photos/search`

Search photos by filename, date, or metadata.

**Query Parameters:**
- `q` (string): Search query
- `date_from` (string): ISO date (optional)
- `date_to` (string): ISO date (optional)
- `album_id` (string): Filter by album (optional)
- `page` (int): Page number
- `limit` (int): Items per page

**Response:**
```json
{
  "photos": [...],
  "pagination": {...},
  "query": "sunset",
  "results_count": 42
}
```

## VPN Management

### `GET /api/v1/vpn/config`

Get WireGuard configuration for authenticated device.

**Response:**
```json
{
  "device_id": "uuid",
  "private_key": "device_private_key",
  "server_public_key": "server_public_key",
  "server_endpoint": "192.168.1.100:51820",
  "allowed_ips": "10.100.0.0/24",
  "device_ip": "10.100.0.2/32",
  "dns": "10.100.0.1",
  "keepalive": 25
}
```

### `POST /api/v1/vpn/status`

Report VPN connection status (for monitoring).

**Request:**
```json
{
  "device_id": "uuid",
  "status": "connected",
  "last_handshake": "2023-12-27T04:00:00Z",
  "rx_bytes": 1048576,
  "tx_bytes": 524288
}
```

**Response:**
```json
{
  "acknowledged": true
}
```

### `POST /api/v1/vpn/revoke`

Revoke VPN access for device (requires admin token).

**Request:**
```json
{
  "device_id": "uuid",
  "reason": "Device lost"
}
```

**Response:**
```json
{
  "success": true,
  "message": "VPN access revoked"
}
```

## Host Management

### `GET /api/v1/host/status`

Get host system status.

**Response:**
```json
{
  "host_id": "uuid",
  "host_name": "John's Mac",
  "version": "1.0.0",
  "uptime_seconds": 3600,
  "photo_roots": [
    {
      "path": "/Users/john/Pictures",
      "total_photos": 5000,
      "size_bytes": 10737418240,
      "last_scan": "2023-12-27T03:00:00Z"
    }
  ],
  "indexing_status": {
    "in_progress": false,
    "last_completed": "2023-12-27T03:00:00Z",
    "photos_indexed": 12458
  },
  "wireguard_status": {
    "enabled": true,
    "listening_port": 51820,
    "connected_peers": 2
  }
}
```

### `POST /api/v1/host/scan`

Trigger a manual photo index scan.

**Request:**
```json
{
  "full_scan": false
}
```

**Response:**
```json
{
  "scan_id": "uuid",
  "status": "started",
  "estimated_duration_seconds": 120
}
```

## Error Responses

All errors follow this format:

```json
{
  "error": {
    "code": "INVALID_TOKEN",
    "message": "Authentication token is invalid or expired",
    "details": {}
  }
}
```

### Error Codes

- `INVALID_TOKEN`: Authentication failed
- `UNAUTHORIZED`: Insufficient permissions
- `NOT_FOUND`: Resource not found
- `RATE_LIMITED`: Too many requests
- `INVALID_REQUEST`: Malformed request
- `INTERNAL_ERROR`: Server error
- `PATH_TRAVERSAL`: Invalid file path
- `DEVICE_REVOKED`: Device access has been revoked

## Rate Limiting

- **Authentication endpoints**: 10 requests per minute per IP
- **Photo fetch endpoints**: 100 requests per minute per device
- **Search endpoints**: 20 requests per minute per device
- **Other endpoints**: 60 requests per minute per device

Rate limit headers:
```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1703649600
```

## Versioning

API version is included in the URL path. Current version: `v1`

Breaking changes will increment the version number.
