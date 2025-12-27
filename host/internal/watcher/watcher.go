package watcher

import (
	"log"
	"os"
	"path/filepath"

	"github.com/fsnotify/fsnotify"
	"github.com/vnallasamy/pixlsrve/host/internal/indexer"
)

// Watcher watches photo directories for changes
type Watcher struct {
	watcher *fsnotify.Watcher
	indexer *indexer.Indexer
	roots   []string
}

// New creates a new file watcher
func New(idx *indexer.Indexer, roots []string) *Watcher {
	return &Watcher{
		indexer: idx,
		roots:   roots,
	}
}

// Start starts watching the configured directories
func (w *Watcher) Start() error {
	var err error
	w.watcher, err = fsnotify.NewWatcher()
	if err != nil {
		return err
	}

	// Add all photo roots
	for _, root := range w.roots {
		if err := w.watcher.Add(root); err != nil {
			log.Printf("Warning: Failed to watch %s: %v", root, err)
		}

		// Also watch subdirectories
		filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return nil
			}
			if info.IsDir() {
				w.watcher.Add(path)
			}
			return nil
		})
	}

	// Start event processing in background
	go w.processEvents()

	return nil
}

// Stop stops the file watcher
func (w *Watcher) Stop() {
	if w.watcher != nil {
		w.watcher.Close()
	}
}

// processEvents processes file system events
func (w *Watcher) processEvents() {
	for {
		select {
		case event, ok := <-w.watcher.Events:
			if !ok {
				return
			}
			// Handle file creation/modification
			if event.Op&fsnotify.Write == fsnotify.Write || event.Op&fsnotify.Create == fsnotify.Create {
				log.Printf("File changed: %s", event.Name)
				// TODO: Trigger re-index of this file
			}
		case err, ok := <-w.watcher.Errors:
			if !ok {
				return
			}
			log.Printf("Watcher error: %v", err)
		}
	}
}
