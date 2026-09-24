// Kata: without building anything, decide which of four target builds would
// compile a file constrained by (linux && amd64) || (darwin && !cgo), using
// the same parser and evaluator the go command uses, go/build/constraint.
// Then print the old // +build spelling of the same expression.
//
//	go build -trimpath build_constraints_choose_files_kata_go.go && ./build_constraints_choose_files_kata_go
package main

import (
	"fmt"
	"go/build/constraint"
	"slices"
	"strings"
)

func main() {
	line := "//go:build (linux && amd64) || (darwin && !cgo)"
	expr, err := constraint.Parse(line)
	if err != nil {
		panic(err)
	}
	fmt.Println("expression:", expr)

	// The tags a build satisfies: GOOS, GOARCH, "unix" for Unix-like systems,
	// the compiler, and "cgo" when cgo is enabled. Go 1.25 adds nothing here
	// that would change the answers.
	builds := []struct {
		name string
		tags []string
	}{
		{"linux/amd64, cgo on", []string{"linux", "amd64", "unix", "gc", "cgo"}},
		{"linux/arm64, cgo on", []string{"linux", "arm64", "unix", "gc", "cgo"}},
		{"darwin/arm64, cgo on", []string{"darwin", "arm64", "unix", "gc", "cgo"}},
		{"darwin/arm64, CGO_ENABLED=0", []string{"darwin", "arm64", "unix", "gc"}},
	}
	for _, b := range builds {
		compiled := expr.Eval(func(tag string) bool { return slices.Contains(b.tags, tag) })
		fmt.Printf("%-28s compiled: %t\n", b.name, compiled)
	}

	lines, err := constraint.PlusBuildLines(expr)
	if err != nil {
		panic(err)
	}
	fmt.Println("the same constraint before Go 1.17:", strings.Join(lines, " "))
}
