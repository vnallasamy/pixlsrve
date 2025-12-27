package config

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
)

// Config holds all application configuration
type Config struct {
	HostID       string        `json:"host_id"`
	HostName     string        `json:"host_name"`
	DatabasePath string        `json:"database_path"`
	PhotoRoots   []string      `json:"photo_roots"`
	InitialScan  bool          `json:"initial_scan"`
	API          APIConfig     `json:"api"`
	VPN          VPNConfig     `json:"vpn"`
	Discovery    DiscoveryConfig `json:"discovery"`
	Thumbnail    ThumbnailConfig `json:"thumbnail"`
}

// APIConfig holds API server configuration
type APIConfig struct {
	Port            int    `json:"port"`
	Host            string `json:"host"`
	TLSEnabled      bool   `json:"tls_enabled"`
	CertFile        string `json:"cert_file"`
	KeyFile         string `json:"key_file"`
	TokenExpiry     int    `json:"token_expiry_seconds"`
	RateLimitPerMin int    `json:"rate_limit_per_minute"`
}

// VPNConfig holds WireGuard VPN configuration
type VPNConfig struct {
	Enabled       bool   `json:"enabled"`
	Port          int    `json:"port"`
	Interface     string `json:"interface"`
	PrivateKey    string `json:"private_key"`
	PublicKey     string `json:"public_key"`
	Network       string `json:"network"`
	DNS           string `json:"dns"`
	Keepalive     int    `json:"keepalive"`
}

// DiscoveryConfig holds mDNS discovery configuration
type DiscoveryConfig struct {
	Enabled     bool   `json:"enabled"`
	ServiceName string `json:"service_name"`
	Domain      string `json:"domain"`
}

// ThumbnailConfig holds thumbnail generation configuration
type ThumbnailConfig struct {
	CachePath   string `json:"cache_path"`
	SmallSize   int    `json:"small_size"`
	MediumSize  int    `json:"medium_size"`
	LargeSize   int    `json:"large_size"`
	Quality     int    `json:"quality"`
	MaxWorkers  int    `json:"max_workers"`
}

// Default returns a configuration with sensible defaults
func Default() *Config {
	hostname, _ := os.Hostname()
	if hostname == "" {
		hostname = "PixlSrve Host"
	}

	homeDir, _ := os.UserHomeDir()
	configDir := filepath.Join(homeDir, ".pixlsrve")

	return &Config{
		HostID:       generateHostID(),
		HostName:     hostname,
		DatabasePath: filepath.Join(configDir, "pixlsrve.db"),
		PhotoRoots:   []string{},
		InitialScan:  false,
		API: APIConfig{
			Port:            8080,
			Host:            "0.0.0.0",
			TLSEnabled:      false,
			TokenExpiry:     3600,
			RateLimitPerMin: 60,
		},
		VPN: VPNConfig{
			Enabled:    false,
			Port:       51820,
			Interface:  "wg0",
			Network:    "10.100.0.0/24",
			DNS:        "10.100.0.1",
			Keepalive:  25,
		},
		Discovery: DiscoveryConfig{
			Enabled:     true,
			ServiceName: "_pixlsrve._tcp",
			Domain:      "local.",
		},
		Thumbnail: ThumbnailConfig{
			CachePath:  filepath.Join(configDir, "thumbnails"),
			SmallSize:  200,
			MediumSize: 400,
			LargeSize:  800,
			Quality:    85,
			MaxWorkers: runtime.NumCPU(),
		},
	}
}

// Load loads configuration from file or creates default
func Load() (*Config, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("failed to get home directory: %w", err)
	}

	configDir := filepath.Join(homeDir, ".pixlsrve")
	configPath := filepath.Join(configDir, "config.json")

	// Create config directory if it doesn't exist
	if err := os.MkdirAll(configDir, 0700); err != nil {
		return nil, fmt.Errorf("failed to create config directory: %w", err)
	}

	// Check if config file exists
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		// Create default config
		cfg := Default()
		if err := cfg.Save(configPath); err != nil {
			return nil, fmt.Errorf("failed to save default config: %w", err)
		}
		fmt.Println("Created default configuration at:", configPath)
		return cfg, nil
	}

	// Load existing config
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	cfg := Default() // Start with defaults
	if err := json.Unmarshal(data, cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	// Create necessary directories
	dirs := []string{
		filepath.Dir(cfg.DatabasePath),
		cfg.Thumbnail.CachePath,
	}
	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return nil, fmt.Errorf("failed to create directory %s: %w", dir, err)
		}
	}

	return cfg, nil
}

// Save saves configuration to file
func (c *Config) Save(path string) error {
	data, err := json.MarshalIndent(c, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	if err := os.WriteFile(path, data, 0600); err != nil {
		return fmt.Errorf("failed to write config file: %w", err)
	}

	return nil
}

// generateHostID generates a unique host ID
func generateHostID() string {
	return uuid.New().String()
}
