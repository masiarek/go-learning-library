// Kata: three parallel subtests, each with its own t.TempDir, that record
// their names for the parent; the parent's Cleanup -- which runs after all
// three -- prints the names sorted and checks that every directory is gone.
// The program writes the test to a temporary module, runs it, and prints
// only the lines whose order cannot vary.
//
//	go build t_parallel_and_t_cleanup_kata_go.go && ./t_parallel_and_t_cleanup_kata_go
package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

const test = `package warehouse

import (
	"os"
	"sort"
	"sync"
	"testing"
)

func TestRegions(t *testing.T) {
	var mu sync.Mutex
	var finished []string
	var dirs []string
	for _, region := range []string{"north", "south", "east"} {
		t.Run(region, func(t *testing.T) {
			t.Parallel()
			dir := t.TempDir()
			mu.Lock()
			finished = append(finished, region)
			dirs = append(dirs, dir)
			mu.Unlock()
		})
	}
	t.Cleanup(func() {
		sort.Strings(finished)
		t.Log("kata: subtests finished:", finished)
		gone := 0
		for _, dir := range dirs {
			if _, err := os.Stat(dir); os.IsNotExist(err) {
				gone++
			}
		}
		t.Logf("kata: temp dirs removed: %d of %d", gone, len(dirs))
	})
}
`

var keep = regexp.MustCompile(`^(=== RUN|=== PAUSE|--- PASS|PASS|ok)|kata:`)

func main() {
	dir, err := os.MkdirTemp("", "kata")
	if err != nil {
		panic(err)
	}
	defer os.RemoveAll(dir)
	must(os.WriteFile(filepath.Join(dir, "regions_test.go"), []byte(test), 0o644))
	init := exec.Command("go", "mod", "init", "example")
	init.Dir = dir
	must(init.Run())

	fmt.Println("$ go test -v -parallel 3 -run TestRegions")
	cmd := exec.Command("go", "test", "-v", "-parallel", "3", "-run", "TestRegions")
	cmd.Dir = dir
	out, _ := cmd.CombinedOutput()
	for _, line := range strings.Split(string(out), "\n") {
		if keep.MatchString(line) {
			line = regexp.MustCompile(` \([0-9.]+s\)$|\t[0-9.]+s$`).ReplaceAllString(line, "")
			if strings.HasPrefix(line, "--- PASS") {
				fmt.Println(line) // the parent's line; its subtests' lines are indented
				continue
			}
			fmt.Println(strings.TrimSpace(line))
		}
	}
	fmt.Println("exit status", cmd.ProcessState.ExitCode())
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}
