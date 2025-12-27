package indexer

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/vnallasamy/pixlsrve/host/internal/config"
	"github.com/vnallasamy/pixlsrve/host/internal/db"
)

// Indexer handles photo indexing
type Indexer struct {
	db     *db.Database
	config *config.Config
}

// New creates a new indexer
func New(database *db.Database, cfg *config.Config) *Indexer {
	return &Indexer{
		db:     database,
		config: cfg,
	}
}

// ScanAll performs a full scan of all photo roots
func (i *Indexer) ScanAll(ctx context.Context) error {
	jobID := uuid.New().String()
	
	// Create scan job
	_, err := i.db.Exec(`
		INSERT INTO scan_jobs (id, status, started_at)
		VALUES (?, ?, ?)
	`, jobID, "running", time.Now())
	if err != nil {
		return fmt.Errorf("failed to create scan job: %w", err)
	}

	photosFound := 0
	photosAdded := 0

	for _, root := range i.config.PhotoRoots {
		err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return nil // Skip errors
			}

			if info.IsDir() {
				return nil
			}

			// Check if it's an image file
			if !isImageFile(path) {
				return nil
			}

			photosFound++

			// Check if already indexed
			var exists bool
			err = i.db.QueryRow("SELECT EXISTS(SELECT 1 FROM photos WHERE path = ?)", path).Scan(&exists)
			if err != nil {
				return nil
			}

			if exists {
				return nil // Already indexed
			}

			// Index the photo
			if err := i.indexPhoto(path, root); err != nil {
				return nil // Skip on error
			}

			photosAdded++
			return nil
		})

		if err != nil {
			return err
		}
	}

	// Update scan job
	_, err = i.db.Exec(`
		UPDATE scan_jobs 
		SET status = ?, completed_at = ?, photos_found = ?, photos_added = ?
		WHERE id = ?
	`, "completed", time.Now(), photosFound, photosAdded, jobID)

	return err
}

// indexPhoto indexes a single photo file
func (i *Indexer) indexPhoto(path string, root string) error {
	info, err := os.Stat(path)
	if err != nil {
		return err
	}

	// Calculate file hash
	hash, err := calculateFileHash(path)
	if err != nil {
		return err
	}

	// Determine album (directory containing the photo)
	albumPath := filepath.Dir(path)
	albumID, err := i.ensureAlbum(albumPath)
	if err != nil {
		return err
	}

	photoID := uuid.New().String()
	filename := filepath.Base(path)
	format := strings.TrimPrefix(strings.ToLower(filepath.Ext(path)), ".")

	_, err = i.db.Exec(`
		INSERT INTO photos (id, filename, album_id, path, size_bytes, format, created_at, modified_at, indexed_at, hash, taken_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, photoID, filename, albumID, path, info.Size(), format, info.ModTime(), info.ModTime(), time.Now(), hash, info.ModTime())

	if err != nil {
		return err
	}

	// Update album photo count
	_, err = i.db.Exec(`
		UPDATE albums 
		SET photo_count = (SELECT COUNT(*) FROM photos WHERE album_id = ?),
		    size_bytes = (SELECT COALESCE(SUM(size_bytes), 0) FROM photos WHERE album_id = ?),
		    updated_at = ?
		WHERE id = ?
	`, albumID, albumID, time.Now(), albumID)

	return err
}

// ensureAlbum ensures an album exists for the given path
func (i *Indexer) ensureAlbum(path string) (string, error) {
	var albumID string
	err := i.db.QueryRow("SELECT id FROM albums WHERE path = ?", path).Scan(&albumID)
	if err == nil {
		return albumID, nil
	}

	// Create new album
	albumID = uuid.New().String()
	albumName := filepath.Base(path)

	_, err = i.db.Exec(`
		INSERT INTO albums (id, name, path, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?)
	`, albumID, albumName, path, time.Now(), time.Now())

	return albumID, err
}

// isImageFile checks if a file is an image based on extension
func isImageFile(path string) bool {
	ext := strings.ToLower(filepath.Ext(path))
	imageExts := []string{".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".heic", ".webp"}
	
	for _, imgExt := range imageExts {
		if ext == imgExt {
			return true
		}
	}
	return false
}

// calculateFileHash calculates SHA256 hash of file
func calculateFileHash(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()

	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}

	return hex.EncodeToString(h.Sum(nil)), nil
}
