package api

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
	"github.com/vnallasamy/pixlsrve/host/internal/config"
	"github.com/vnallasamy/pixlsrve/host/internal/db"
	"github.com/vnallasamy/pixlsrve/host/internal/indexer"
	"github.com/vnallasamy/pixlsrve/host/internal/vpn"
)

// Server represents the API server
type Server struct {
	config    *config.Config
	db        *db.Database
	indexer   *indexer.Indexer
	vpnServer *vpn.Server
	router    *mux.Router
	server    *http.Server
}

// NewServer creates a new API server
func NewServer(cfg *config.Config, database *db.Database, idx *indexer.Indexer, vpn *vpn.Server) *Server {
	s := &Server{
		config:    cfg,
		db:        database,
		indexer:   idx,
		vpnServer: vpn,
		router:    mux.NewRouter(),
	}

	s.setupRoutes()
	return s
}

// setupRoutes configures all API routes
func (s *Server) setupRoutes() {
	api := s.router.PathPrefix("/api/v1").Subrouter()

	// Public endpoints (no auth required on LAN)
	api.HandleFunc("/discovery/info", s.handleDiscoveryInfo).Methods("GET")

	// Authentication endpoints
	api.HandleFunc("/auth/pair", s.handlePair).Methods("POST")
	api.HandleFunc("/auth/token/refresh", s.handleTokenRefresh).Methods("POST")
	
	// Protected endpoints (require auth)
	protected := api.PathPrefix("").Subrouter()
	protected.Use(s.authMiddleware)
	
	// Albums
	protected.HandleFunc("/albums", s.handleListAlbums).Methods("GET")
	protected.HandleFunc("/albums/{id}", s.handleGetAlbum).Methods("GET")
	protected.HandleFunc("/albums/{id}/photos", s.handleListAlbumPhotos).Methods("GET")
	
	// Photos
	protected.HandleFunc("/photos/{id}", s.handleGetPhoto).Methods("GET")
	protected.HandleFunc("/photos/{id}/thumbnail", s.handleGetThumbnail).Methods("GET")
	protected.HandleFunc("/photos/{id}/full", s.handleGetFullPhoto).Methods("GET")
	protected.HandleFunc("/photos/search", s.handleSearchPhotos).Methods("GET")
	
	// VPN Management
	protected.HandleFunc("/vpn/config", s.handleGetVPNConfig).Methods("GET")
	protected.HandleFunc("/vpn/status", s.handleVPNStatus).Methods("POST")
	
	// Host Management
	protected.HandleFunc("/host/status", s.handleHostStatus).Methods("GET")
	protected.HandleFunc("/host/scan", s.handleTriggerScan).Methods("POST")

	// Add CORS middleware
	s.router.Use(corsMiddleware)
	
	// Add logging middleware
	s.router.Use(loggingMiddleware)
}

// Start starts the API server
func (s *Server) Start() error {
	addr := fmt.Sprintf("%s:%d", s.config.API.Host, s.config.API.Port)
	
	s.server = &http.Server{
		Addr:         addr,
		Handler:      s.router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	log.Printf("API server listening on %s", addr)
	return s.server.ListenAndServe()
}

// Shutdown gracefully shuts down the server
func (s *Server) Shutdown(ctx context.Context) error {
	if s.server != nil {
		return s.server.Shutdown(ctx)
	}
	return nil
}

// authMiddleware validates API tokens
func (s *Server) authMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := r.Header.Get("Authorization")
		if token == "" {
			s.errorResponse(w, "Missing authorization header", http.StatusUnauthorized)
			return
		}

		// Remove "Bearer " prefix if present
		if len(token) > 7 && token[:7] == "Bearer " {
			token = token[7:]
		}

		// Validate token
		var deviceID string
		var revoked bool
		err := s.db.QueryRow(`
			SELECT id, revoked FROM devices WHERE api_token = ?
		`, token).Scan(&deviceID, &revoked)

		if err != nil {
			s.errorResponse(w, "Invalid token", http.StatusUnauthorized)
			return
		}

		if revoked {
			s.errorResponse(w, "Device has been revoked", http.StatusForbidden)
			return
		}

		// Update last seen
		s.db.Exec("UPDATE devices SET last_seen_at = ? WHERE id = ?", time.Now(), deviceID)

		// Add device ID to context
		ctx := context.WithValue(r.Context(), "device_id", deviceID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// corsMiddleware adds CORS headers
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// loggingMiddleware logs all requests
func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %v", r.Method, r.URL.Path, time.Since(start))
	})
}

// jsonResponse sends a JSON response
func (s *Server) jsonResponse(w http.ResponseWriter, data interface{}, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

// errorResponse sends an error response
func (s *Server) errorResponse(w http.ResponseWriter, message string, status int) {
	s.jsonResponse(w, map[string]interface{}{
		"error": map[string]interface{}{
			"message": message,
			"code":    http.StatusText(status),
		},
	}, status)
}

// Handler implementations (stubs for now)

func (s *Server) handleDiscoveryInfo(w http.ResponseWriter, r *http.Request) {
	var photoCount int
	var albumCount int
	
	s.db.QueryRow("SELECT COUNT(*) FROM photos").Scan(&photoCount)
	s.db.QueryRow("SELECT COUNT(*) FROM albums").Scan(&albumCount)

	s.jsonResponse(w, map[string]interface{}{
		"host_id":     s.config.HostID,
		"host_name":   s.config.HostName,
		"version":     "1.0.0",
		"api_version": "v1",
		"capabilities": []string{"wireguard", "thumbnails", "search"},
		"photo_count": photoCount,
		"album_count": albumCount,
	}, http.StatusOK)
}

func (s *Server) handlePair(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement device pairing
	s.errorResponse(w, "Not implemented", http.StatusNotImplemented)
}

func (s *Server) handleTokenRefresh(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement token refresh
	s.errorResponse(w, "Not implemented", http.StatusNotImplemented)
}

func (s *Server) handleListAlbums(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement album listing
	rows, err := s.db.Query(`
		SELECT id, name, path, photo_count, size_bytes, cover_photo_id, created_at, updated_at
		FROM albums
		ORDER BY updated_at DESC
		LIMIT 50
	`)
	if err != nil {
		s.errorResponse(w, "Failed to fetch albums", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	albums := []map[string]interface{}{}
	for rows.Next() {
		var id, name, path string
		var photoCount int
		var sizeBytes int64
		var coverPhotoID *string
		var createdAt, updatedAt time.Time

		err := rows.Scan(&id, &name, &path, &photoCount, &sizeBytes, &coverPhotoID, &createdAt, &updatedAt)
		if err != nil {
			continue
		}

		album := map[string]interface{}{
			"id":          id,
			"name":        name,
			"path":        path,
			"photo_count": photoCount,
			"size_bytes":  sizeBytes,
			"created_at":  createdAt,
			"updated_at":  updatedAt,
		}
		if coverPhotoID != nil {
			album["cover_photo_id"] = *coverPhotoID
			album["cover_thumbnail_url"] = fmt.Sprintf("/api/v1/photos/%s/thumbnail", *coverPhotoID)
		}

		albums = append(albums, album)
	}

	s.jsonResponse(w, map[string]interface{}{
		"albums": albums,
		"pagination": map[string]interface{}{
			"page":        1,
			"limit":       50,
			"total":       len(albums),
			"total_pages": 1,
		},
	}, http.StatusOK)
}

func (s *Server) handleGetAlbum(w http.ResponseWriter, r *http.Request) {
	s.errorResponse(w, "Not implemented", http.StatusNotImplemented)
}

func (s *Server) handleListAlbumPhotos(w http.ResponseWriter, r *http.Request) {
	s.errorResponse(w, "Not implemented", http.StatusNotImplemented)
}

func (s *Server) handleGetPhoto(w http.ResponseWriter, r *http.Request) {
	s.errorResponse(w, "Not implemented", http.StatusNotImplemented)
}

func (s *Server) handleGetThumbnail(w http.ResponseWriter, r *http.Request) {
	s.errorResponse(w, "Not implemented", http.StatusNotImplemented)
}

func (s *Server) handleGetFullPhoto(w http.ResponseWriter, r *http.Request) {
	s.errorResponse(w, "Not implemented", http.StatusNotImplemented)
}

func (s *Server) handleSearchPhotos(w http.ResponseWriter, r *http.Request) {
	s.errorResponse(w, "Not implemented", http.StatusNotImplemented)
}

func (s *Server) handleGetVPNConfig(w http.ResponseWriter, r *http.Request) {
	s.errorResponse(w, "Not implemented", http.StatusNotImplemented)
}

func (s *Server) handleVPNStatus(w http.ResponseWriter, r *http.Request) {
	s.errorResponse(w, "Not implemented", http.StatusNotImplemented)
}

func (s *Server) handleHostStatus(w http.ResponseWriter, r *http.Request) {
	var photoCount, albumCount int
	s.db.QueryRow("SELECT COUNT(*) FROM photos").Scan(&photoCount)
	s.db.QueryRow("SELECT COUNT(*) FROM albums").Scan(&albumCount)

	s.jsonResponse(w, map[string]interface{}{
		"host_id":   s.config.HostID,
		"host_name": s.config.HostName,
		"version":   "1.0.0",
		"uptime_seconds": 0, // TODO: Calculate actual uptime
		"photo_roots": s.config.PhotoRoots,
		"indexing_status": map[string]interface{}{
			"in_progress":    false,
			"photos_indexed": photoCount,
		},
		"wireguard_status": map[string]interface{}{
			"enabled":         s.config.VPN.Enabled,
			"listening_port":  s.config.VPN.Port,
			"connected_peers": 0,
		},
	}, http.StatusOK)
}

func (s *Server) handleTriggerScan(w http.ResponseWriter, r *http.Request) {
	s.errorResponse(w, "Not implemented", http.StatusNotImplemented)
}
