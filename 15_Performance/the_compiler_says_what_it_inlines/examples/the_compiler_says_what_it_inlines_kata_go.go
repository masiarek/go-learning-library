// Kata: three functions from a warehouse program -- a clamp, a loop that
// totals weights, and a function that closes every file in a slice with a
// deferred call inside the loop. Say which the compiler inlines and why not
// the others, by asking it: write the file, run `go build -gcflags=-m=2`, and
// read the verdicts back.
//
//	go build the_compiler_says_what_it_inlines_kata_go.go && ./the_compiler_says_what_it_inlines_kata_go
package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

const source = `package main

import "os"

func clamp(weight, limit int) int {
	if weight > limit {
		return limit
	}
	return weight
}

func totalWeight(weights []int) int {
	total := 0
	for _, w := range weights {
		total += w
	}
	return total
}

func closeAll(files []*os.File) {
	for _, f := range files {
		defer f.Close()
	}
}

func main() {
	println(clamp(50, 40), totalWeight([]int{1, 2, 3}))
	closeAll(nil)
}
`

func main() {
	dir, err := os.MkdirTemp("", "inline-kata")
	if err != nil {
		panic(err)
	}
	defer os.RemoveAll(dir)
	src := filepath.Join(dir, "warehouse.go")
	if err := os.WriteFile(src, []byte(source), 0o644); err != nil {
		panic(err)
	}

	cmd := exec.Command("go", "build", "-gcflags=-m=2", "-o", filepath.Join(dir, "warehouse"), src)
	cmd.Env = append(os.Environ(), "GOTOOLCHAIN=local")
	report, err := cmd.CombinedOutput()
	if err != nil {
		panic(fmt.Sprintf("%v\n%s", err, report))
	}

	// "./warehouse.go:5:6: can inline clamp with cost 9 as: ..." or
	// "./warehouse.go:20:6: cannot inline closeAll: unhandled op DEFER"
	verdict := regexp.MustCompile(`^\S+ (can|cannot) inline (\w+)(?:: (.*?))?(?: with cost \d+ as: .*)?$`)
	for _, name := range []string{"clamp", "totalWeight", "closeAll"} {
		for _, line := range strings.Split(string(report), "\n") {
			m := verdict.FindStringSubmatch(line)
			if m == nil || m[2] != name {
				continue
			}
			if m[1] == "can" {
				fmt.Printf("%-12s inlined: yes\n", name)
			} else {
				fmt.Printf("%-12s inlined: no  (%s)\n", name, m[3])
			}
		}
	}
}
