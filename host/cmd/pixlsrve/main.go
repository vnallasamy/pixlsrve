package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/vnallasamy/pixlsrve/host/internal/api"
	"github.com/vnallasamy/pixlsrve/host/internal/config"
	"github.com/vnallasamy/pixlsrve/host/internal/db"
	"github.com/vnallasamy/pixlsrve/host/internal/discovery"
	"github.com/vnallasamy/pixlsrve/host/internal/indexer"
	"github.com/vnallasamy/pixlsrve/host/internal/vpn"
	"github.com/vnallasamy/pixlsrve/host/internal/watcher"
)

const (
	appName    = "PixlSrve"
	appVersion = "1.0.0"
)

func main() {
	fmt.Printf("%s v%s - Personal Photo Host\n", appName, appVersion)
	fmt.Println("======================================")

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize database
	database, err := db.Initialize(cfg.DatabasePath)
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer database.Close()

	fmt.Println("✓ Database initialized")

	// Initialize indexer
	idx := indexer.New(database, cfg)
	fmt.Println("✓ Photo indexer ready")

	// Initialize file watcher
	watch := watcher.New(idx, cfg.PhotoRoots)
	if err := watch.Start(); err != nil {
		log.Fatalf("Failed to start file watcher: %v", err)
	}
	defer watch.Stop()
	fmt.Println("✓ File watcher started")

	// Perform initial scan if needed
	if cfg.InitialScan {
		fmt.Println("Performing initial photo scan...")
		if err := idx.ScanAll(context.Background()); err != nil {
			log.Printf("Warning: Initial scan failed: %v", err)
		} else {
			fmt.Println("✓ Initial scan complete")
		}
	}

	// Initialize VPN server
	vpnServer, err := vpn.NewServer(cfg, database)
	if err != nil {
		log.Fatalf("Failed to initialize VPN server: %v", err)
	}
	if cfg.VPN.Enabled {
		if err := vpnServer.Start(); err != nil {
			log.Fatalf("Failed to start VPN server: %v", err)
		}
		defer vpnServer.Stop()
		fmt.Printf("✓ WireGuard VPN server started on port %d\n", cfg.VPN.Port)
	}

	// Initialize mDNS discovery service
	if cfg.Discovery.Enabled {
		disc, err := discovery.New(cfg)
		if err != nil {
			log.Fatalf("Failed to initialize mDNS service: %v", err)
		}
		if err := disc.Start(); err != nil {
			log.Fatalf("Failed to start mDNS service: %v", err)
		}
		defer disc.Stop()
		fmt.Println("✓ mDNS discovery service started")
	}

	// Initialize and start API server
	server := api.NewServer(cfg, database, idx, vpnServer)
	
	// Start API server in goroutine
	serverErrors := make(chan error, 1)
	go func() {
		fmt.Printf("✓ API server starting on port %d\n", cfg.API.Port)
		serverErrors <- server.Start()
	}()

	fmt.Println("\n" + appName + " is running!")
	fmt.Printf("Photo roots: %v\n", cfg.PhotoRoots)
	fmt.Printf("API: http://localhost:%d\n", cfg.API.Port)
	fmt.Println("\nPress Ctrl+C to stop...")

	// Wait for interrupt signal or server error
	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt, syscall.SIGTERM)

	select {
	case err := <-serverErrors:
		log.Fatalf("Server error: %v", err)
	case <-interrupt:
		fmt.Println("\nShutting down gracefully...")
	}

	// Graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Printf("Server shutdown error: %v", err)
	}

	fmt.Println("Goodbye!")
}
