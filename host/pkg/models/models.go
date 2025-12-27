package models

import (
	"time"
)

// Photo represents a photo file in the database
type Photo struct {
	ID         string    `json:"id" db:"id"`
	Filename   string    `json:"filename" db:"filename"`
	AlbumID    string    `json:"album_id" db:"album_id"`
	Path       string    `json:"path" db:"path"`
	SizeBytes  int64     `json:"size_bytes" db:"size_bytes"`
	Width      int       `json:"width" db:"width"`
	Height     int       `json:"height" db:"height"`
	Format     string    `json:"format" db:"format"`
	TakenAt    time.Time `json:"taken_at" db:"taken_at"`
	CreatedAt  time.Time `json:"created_at" db:"created_at"`
	ModifiedAt time.Time `json:"modified_at" db:"modified_at"`
	IndexedAt  time.Time `json:"indexed_at" db:"indexed_at"`
	Hash       string    `json:"hash" db:"hash"`
}

// Album represents a photo album/folder
type Album struct {
	ID             string    `json:"id" db:"id"`
	Name           string    `json:"name" db:"name"`
	Path           string    `json:"path" db:"path"`
	PhotoCount     int       `json:"photo_count" db:"photo_count"`
	SizeBytes      int64     `json:"size_bytes" db:"size_bytes"`
	CoverPhotoID   *string   `json:"cover_photo_id" db:"cover_photo_id"`
	CreatedAt      time.Time `json:"created_at" db:"created_at"`
	UpdatedAt      time.Time `json:"updated_at" db:"updated_at"`
}

// Device represents a paired mobile device
type Device struct {
	ID                string    `json:"id" db:"id"`
	Name              string    `json:"name" db:"name"`
	DeviceType        string    `json:"device_type" db:"device_type"` // ios, android
	APIToken          string    `json:"api_token" db:"api_token"`
	RefreshToken      string    `json:"refresh_token" db:"refresh_token"`
	WireGuardPublicKey string   `json:"wireguard_public_key" db:"wireguard_public_key"`
	WireGuardIP       string    `json:"wireguard_ip" db:"wireguard_ip"`
	PairedAt          time.Time `json:"paired_at" db:"paired_at"`
	LastSeenAt        time.Time `json:"last_seen_at" db:"last_seen_at"`
	Revoked           bool      `json:"revoked" db:"revoked"`
	RevokedAt         *time.Time `json:"revoked_at,omitempty" db:"revoked_at"`
}

// PhotoMetadata stores EXIF and other metadata
type PhotoMetadata struct {
	PhotoID   string  `json:"photo_id" db:"photo_id"`
	Camera    *string `json:"camera,omitempty" db:"camera"`
	Lens      *string `json:"lens,omitempty" db:"lens"`
	ISO       *int    `json:"iso,omitempty" db:"iso"`
	Exposure  *string `json:"exposure,omitempty" db:"exposure"`
	Aperture  *string `json:"aperture,omitempty" db:"aperture"`
	Latitude  *float64 `json:"latitude,omitempty" db:"latitude"`
	Longitude *float64 `json:"longitude,omitempty" db:"longitude"`
	Altitude  *float64 `json:"altitude,omitempty" db:"altitude"`
}

// ScanJob represents an indexing scan job
type ScanJob struct {
	ID           string    `json:"id" db:"id"`
	Status       string    `json:"status" db:"status"` // pending, running, completed, failed
	PhotosFound  int       `json:"photos_found" db:"photos_found"`
	PhotosAdded  int       `json:"photos_added" db:"photos_added"`
	PhotosUpdated int      `json:"photos_updated" db:"photos_updated"`
	StartedAt    time.Time `json:"started_at" db:"started_at"`
	CompletedAt  *time.Time `json:"completed_at,omitempty" db:"completed_at"`
	ErrorMessage *string   `json:"error_message,omitempty" db:"error_message"`
}

// VPNConnection tracks VPN connection status
type VPNConnection struct {
	DeviceID      string    `json:"device_id" db:"device_id"`
	Status        string    `json:"status" db:"status"` // connected, disconnected
	LastHandshake time.Time `json:"last_handshake" db:"last_handshake"`
	RxBytes       int64     `json:"rx_bytes" db:"rx_bytes"`
	TxBytes       int64     `json:"tx_bytes" db:"tx_bytes"`
	ConnectedAt   time.Time `json:"connected_at" db:"connected_at"`
	DisconnectedAt *time.Time `json:"disconnected_at,omitempty" db:"disconnected_at"`
}
