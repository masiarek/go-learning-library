// Kata: a fuzz target for ParseQuantity whose property is that a quantity
// printed as "<n> <unit>" parses back to n and unit, with two corpus files
// written by hand in the fuzzer's own format -- one of them a unit with a
// space in it, which the property cannot hold for. The first run fails on
// that entry; the second, with the target skipping units that contain
// white space, passes. The program writes the module to a temporary
// directory and prints both transcripts with the durations stripped.
//
//	go build fuzzing_finds_the_input_you_did_not_write_kata_go.go && ./fuzzing_finds_the_input_you_did_not_write_kata_go
package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

const source = `package stock

import (
	"errors"
	"strconv"
	"strings"
)

func ParseQuantity(s string) (int, string, error) {
	fields := strings.Fields(s)
	if len(fields) != 2 {
		return 0, "", errors.New("want a number and a unit")
	}
	n, err := strconv.Atoi(fields[0])
	if err != nil {
		return 0, "", err
	}
	return n, fields[1], nil
}
`

const test = `package stock

import (
	"fmt"
	"strings"
	"testing"
)

func FuzzParseQuantity(f *testing.F) {
	f.Add(12, "crates")
	f.Fuzz(func(t *testing.T, n int, unit string) {
		GUARD
		got, gotUnit, err := ParseQuantity(fmt.Sprintf("%d %s", n, unit))
		if err != nil || got != n || gotUnit != unit {
			t.Errorf("ParseQuantity(%q) = %d, %q, %v; want %d, %q", fmt.Sprintf("%d %s", n, unit), got, gotUnit, err, n, unit)
		}
	})
}
`

var durations = regexp.MustCompile(`(?m)( \([0-9.]+s\)$)|(^(ok|FAIL)(\s+example)\s+[0-9.]+s$)`)

func main() {
	dir, err := os.MkdirTemp("", "kata")
	if err != nil {
		panic(err)
	}
	defer os.RemoveAll(dir)
	corpus := filepath.Join(dir, "testdata", "fuzz", "FuzzParseQuantity")
	must(os.MkdirAll(corpus, 0o755))
	must(os.WriteFile(filepath.Join(dir, "quantity.go"), []byte(source), 0o644))
	must(os.WriteFile(filepath.Join(corpus, "negative_pallets"), []byte("go test fuzz v1\nint(-3)\nstring(\"pallets\")\n"), 0o644))
	must(os.WriteFile(filepath.Join(corpus, "unit_with_a_space"), []byte("go test fuzz v1\nint(2)\nstring(\"big crates\")\n"), 0o644))
	init := exec.Command("go", "mod", "init", "example")
	init.Dir = dir
	must(init.Run())

	for _, guard := range []string{"", `if strings.ContainsAny(unit, " \t\n") || unit == "" {
			t.Skip("the property is only for units without white space")
		}`} {
		body := strings.Replace(test, "GUARD", guard, 1)
		if guard == "" {
			body = strings.Replace(body, "\t\"strings\"\n", "", 1)
		}
		must(os.WriteFile(filepath.Join(dir, "quantity_test.go"), []byte(body), 0o644))
		fmt.Println("$ go test -v -run=FuzzParseQuantity")
		cmd := exec.Command("go", "test", "-v", "-run=FuzzParseQuantity")
		cmd.Dir = dir
		out, _ := cmd.CombinedOutput()
		for _, line := range strings.Split(durations.ReplaceAllString(string(out), "$3$4"), "\n") {
			trimmed := strings.TrimSpace(line)
			if strings.HasPrefix(line, "===") || strings.HasPrefix(trimmed, "---") || strings.HasPrefix(trimmed, "quantity_test.go:") || strings.HasPrefix(line, "ok") || strings.HasPrefix(line, "FAIL") || strings.HasPrefix(line, "PASS") {
				fmt.Println(line)
			}
		}
		fmt.Println("exit status", cmd.ProcessState.ExitCode())
	}
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}
