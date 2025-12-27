package discovery

import (
	"fmt"
	"log"
	"net"

	"github.com/hashicorp/mdns"
	"github.com/vnallasamy/pixlsrve/host/internal/config"
)

// Discovery handles mDNS service discovery
type Discovery struct {
	config *config.Config
	server *mdns.Server
}

// New creates a new discovery service
func New(cfg *config.Config) (*Discovery, error) {
	return &Discovery{
		config: cfg,
	}, nil
}

// Start starts the mDNS service
func (d *Discovery) Start() error {
	// Get local IP address
	ips, err := getLocalIPs()
	if err != nil {
		return fmt.Errorf("failed to get local IPs: %w", err)
	}

	// Setup mDNS service
	service, err := mdns.NewMDNSService(
		d.config.HostID,
		d.config.Discovery.ServiceName,
		d.config.Discovery.Domain,
		"",
		d.config.API.Port,
		ips,
		[]string{
			fmt.Sprintf("host_id=%s", d.config.HostID),
			fmt.Sprintf("version=1.0.0"),
			fmt.Sprintf("api_port=%d", d.config.API.Port),
			"secure=false",
			fmt.Sprintf("name=%s", d.config.HostName),
		},
	)
	if err != nil {
		return fmt.Errorf("failed to create mDNS service: %w", err)
	}

	// Create mDNS server
	server, err := mdns.NewServer(&mdns.Config{Zone: service})
	if err != nil {
		return fmt.Errorf("failed to create mDNS server: %w", err)
	}

	d.server = server
	log.Printf("mDNS service started: %s.%s", d.config.Discovery.ServiceName, d.config.Discovery.Domain)
	return nil
}

// Stop stops the mDNS service
func (d *Discovery) Stop() {
	if d.server != nil {
		d.server.Shutdown()
	}
}

// getLocalIPs returns all local non-loopback IP addresses
func getLocalIPs() ([]net.IP, error) {
	var ips []net.IP

	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return nil, err
	}

	for _, addr := range addrs {
		if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				ips = append(ips, ipnet.IP)
			}
		}
	}

	return ips, nil
}
