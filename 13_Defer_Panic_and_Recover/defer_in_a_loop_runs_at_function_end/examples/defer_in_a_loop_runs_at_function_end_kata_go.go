// Kata: add up the boxes in five shipment files, reading each file in a
// helper whose deferred Close runs when the helper returns, and prove that
// no more than one file was ever open at once.
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
)

var open, mostOpen int

// openCounted is os.Open with a count of the files open right now.
func openCounted(path string) (*os.File, error) {
	f, err := os.Open(path)
	if err == nil {
		open++
		mostOpen = max(mostOpen, open)
	}
	return f, err
}

func closeCounted(f *os.File) {
	f.Close()
	open--
}

// boxesIn reads one shipment file; its Close runs when boxesIn returns.
func boxesIn(path string) (int, error) {
	f, err := openCounted(path)
	if err != nil {
		return 0, err
	}
	defer closeCounted(f)
	var boxes int
	_, err = fmt.Fscan(f, &boxes)
	return boxes, err
}

func main() {
	dir, err := os.MkdirTemp("", "shipments")
	if err != nil {
		panic(err)
	}
	defer os.RemoveAll(dir)

	var paths []string
	for i := 1; i <= 5; i++ {
		path := filepath.Join(dir, "shipment-"+strconv.Itoa(i)+".txt")
		if err := os.WriteFile(path, []byte(strconv.Itoa(i*2)+"\n"), 0o644); err != nil {
			panic(err)
		}
		paths = append(paths, path)
	}

	total := 0
	for _, path := range paths {
		boxes, err := boxesIn(path)
		if err != nil {
			panic(err)
		}
		total += boxes
	}
	fmt.Printf("shipments: %d, boxes: %d, most open at once: %d, still open: %d\n", len(paths), total, mostOpen, open)
}
