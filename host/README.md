# Host Application

Go-based photo hosting server for Windows and macOS.

## Features

- Photo directory indexing and monitoring
- Thumbnail generation and caching
- REST API for mobile clients
- WireGuard VPN server
- mDNS/Bonjour for LAN discovery
- SQLite database for metadata

## Requirements

- Go 1.21 or later
- GCC (for CGO/SQLite)
- WireGuard tools (optional, for VPN functionality)

## Development

### Build

```bash
cd host
go mod download
go build -o pixlsrve ./cmd/pixlsrve
```

### Run

```bash
./pixlsrve
```

The application will:
1. Create a configuration file at `~/.pixlsrve/config.json` on first run
2. Initialize the SQLite database at `~/.pixlsrve/pixlsrve.db`
3. Start the API server on port 8080
4. Start the mDNS discovery service

### Configuration

Edit `~/.pixlsrve/config.json` to configure:

```json
{
  "host_id": "host-xxxxx",
  "host_name": "My Photo Host",
  "database_path": "/path/to/.pixlsrve/pixlsrve.db",
  "photo_roots": [
    "/Users/username/Pictures",
    "/Users/username/Photos"
  ],
  "initial_scan": true,
  "api": {
    "port": 8080,
    "host": "0.0.0.0"
  },
  "vpn": {
    "enabled": false,
    "port": 51820
  },
  "discovery": {
    "enabled": true
  }
}
```

### Adding Photo Directories

1. Stop the application
2. Edit `~/.pixlsrve/config.json` and add paths to `photo_roots`
3. Set `initial_scan` to `true`
4. Restart the application

## API Endpoints

See [../docs/API_SPEC.md](../docs/API_SPEC.md) for full API documentation.

Quick test:

```bash
# Get host information
curl http://localhost:8080/api/v1/discovery/info

# List albums (requires authentication)
curl -H "Authorization: Bearer <token>" http://localhost:8080/api/v1/albums
```

## Cross-Platform Build

### Windows

```bash
GOOS=windows GOARCH=amd64 go build -o pixlsrve.exe ./cmd/pixlsrve
```

### macOS

```bash
GOOS=darwin GOARCH=amd64 go build -o pixlsrve-mac ./cmd/pixlsrve
```

### Linux

```bash
GOOS=linux GOARCH=amd64 go build -o pixlsrve-linux ./cmd/pixlsrve
```

## Development Scripts

### Run with sample photos

```bash
# Create test photo directory
mkdir -p /tmp/test-photos
# Add some test images...

# Update config to use test directory
# Start application
./pixlsrve
```

## Testing

```bash
# Run tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run tests with race detection
go test -race ./...
```

## Troubleshooting

### Database locked error

If you see "database is locked" errors:
- Ensure only one instance is running
- Check file permissions on the database file
- The database uses WAL mode for better concurrency

### mDNS not working

On some networks, mDNS/Bonjour may be blocked:
- Check firewall settings
- Ensure port 5353 (UDP) is allowed
- Try connecting manually using the host's IP address

### VPN not starting

WireGuard VPN requires:
- WireGuard tools installed
- Administrator/root privileges
- Valid network configuration

## Production Deployment

For production use:

1. **Enable TLS** for the API server
2. **Configure WireGuard** with proper keys and networking
3. **Set up systemd service** (Linux) or **launchd** (macOS) or **Windows Service**
4. **Configure firewall** to allow API port and WireGuard port
5. **Regular backups** of the SQLite database

## License

TBD