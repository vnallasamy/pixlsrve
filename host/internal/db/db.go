package db

import (
	"database/sql"
	"fmt"

	_ "github.com/mattn/go-sqlite3"
)

// Database wraps the SQL database
type Database struct {
	*sql.DB
}

// Initialize creates and initializes the database
func Initialize(dbPath string) (*Database, error) {
	db, err := sql.Open("sqlite3", dbPath+"?_journal_mode=WAL&_busy_timeout=5000")
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Set connection pool settings
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)

	// Create tables
	if err := createTables(db); err != nil {
		db.Close()
		return nil, fmt.Errorf("failed to create tables: %w", err)
	}

	return &Database{db}, nil
}

// createTables creates all necessary database tables
func createTables(db *sql.DB) error {
	schema := `
	-- Albums table
	CREATE TABLE IF NOT EXISTS albums (
		id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		path TEXT NOT NULL UNIQUE,
		photo_count INTEGER DEFAULT 0,
		size_bytes INTEGER DEFAULT 0,
		cover_photo_id TEXT,
		created_at DATETIME NOT NULL,
		updated_at DATETIME NOT NULL
	);

	CREATE INDEX IF NOT EXISTS idx_albums_path ON albums(path);
	CREATE INDEX IF NOT EXISTS idx_albums_updated ON albums(updated_at DESC);

	-- Photos table
	CREATE TABLE IF NOT EXISTS photos (
		id TEXT PRIMARY KEY,
		filename TEXT NOT NULL,
		album_id TEXT NOT NULL,
		path TEXT NOT NULL UNIQUE,
		size_bytes INTEGER NOT NULL,
		width INTEGER DEFAULT 0,
		height INTEGER DEFAULT 0,
		format TEXT NOT NULL,
		taken_at DATETIME,
		created_at DATETIME NOT NULL,
		modified_at DATETIME NOT NULL,
		indexed_at DATETIME NOT NULL,
		hash TEXT NOT NULL,
		FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE
	);

	CREATE INDEX IF NOT EXISTS idx_photos_album ON photos(album_id);
	CREATE INDEX IF NOT EXISTS idx_photos_taken_at ON photos(taken_at DESC);
	CREATE INDEX IF NOT EXISTS idx_photos_filename ON photos(filename);
	CREATE INDEX IF NOT EXISTS idx_photos_hash ON photos(hash);

	-- Photo metadata table
	CREATE TABLE IF NOT EXISTS photo_metadata (
		photo_id TEXT PRIMARY KEY,
		camera TEXT,
		lens TEXT,
		iso INTEGER,
		exposure TEXT,
		aperture TEXT,
		latitude REAL,
		longitude REAL,
		altitude REAL,
		FOREIGN KEY (photo_id) REFERENCES photos(id) ON DELETE CASCADE
	);

	-- Devices table
	CREATE TABLE IF NOT EXISTS devices (
		id TEXT PRIMARY KEY,
		name TEXT NOT NULL,
		device_type TEXT NOT NULL,
		api_token TEXT NOT NULL UNIQUE,
		refresh_token TEXT NOT NULL,
		wireguard_public_key TEXT NOT NULL,
		wireguard_ip TEXT NOT NULL UNIQUE,
		paired_at DATETIME NOT NULL,
		last_seen_at DATETIME NOT NULL,
		revoked BOOLEAN DEFAULT 0,
		revoked_at DATETIME
	);

	CREATE INDEX IF NOT EXISTS idx_devices_token ON devices(api_token);
	CREATE INDEX IF NOT EXISTS idx_devices_revoked ON devices(revoked);

	-- Scan jobs table
	CREATE TABLE IF NOT EXISTS scan_jobs (
		id TEXT PRIMARY KEY,
		status TEXT NOT NULL,
		photos_found INTEGER DEFAULT 0,
		photos_added INTEGER DEFAULT 0,
		photos_updated INTEGER DEFAULT 0,
		started_at DATETIME NOT NULL,
		completed_at DATETIME,
		error_message TEXT
	);

	CREATE INDEX IF NOT EXISTS idx_scan_jobs_status ON scan_jobs(status);
	CREATE INDEX IF NOT EXISTS idx_scan_jobs_started ON scan_jobs(started_at DESC);

	-- VPN connections table
	CREATE TABLE IF NOT EXISTS vpn_connections (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		device_id TEXT NOT NULL,
		status TEXT NOT NULL,
		last_handshake DATETIME NOT NULL,
		rx_bytes INTEGER DEFAULT 0,
		tx_bytes INTEGER DEFAULT 0,
		connected_at DATETIME NOT NULL,
		disconnected_at DATETIME,
		FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE
	);

	CREATE INDEX IF NOT EXISTS idx_vpn_device ON vpn_connections(device_id);
	CREATE INDEX IF NOT EXISTS idx_vpn_status ON vpn_connections(status);

	-- Access logs table
	CREATE TABLE IF NOT EXISTS access_logs (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		device_id TEXT,
		endpoint TEXT NOT NULL,
		method TEXT NOT NULL,
		status_code INTEGER NOT NULL,
		ip_address TEXT NOT NULL,
		user_agent TEXT,
		timestamp DATETIME NOT NULL
	);

	CREATE INDEX IF NOT EXISTS idx_access_logs_device ON access_logs(device_id);
	CREATE INDEX IF NOT EXISTS idx_access_logs_timestamp ON access_logs(timestamp DESC);
	`

	_, err := db.Exec(schema)
	return err
}

// Close closes the database connection
func (db *Database) Close() error {
	return db.DB.Close()
}
