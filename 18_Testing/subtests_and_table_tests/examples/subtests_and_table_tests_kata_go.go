// Kata: a table whose error cases carry the error text they expect, one
// subtest per case, t.Fatalf for the error verdict, and a -run pattern that
// selects the error cases by name. The program writes the module to a
// temporary directory, runs go test there, and prints the transcript with
// the durations stripped.
//
//	go build subtests_and_table_tests_kata_go.go && ./subtests_and_table_tests_kata_go
package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
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

import "testing"

func TestParseQuantity(t *testing.T) {
	cases := []struct {
		name, in string
		n        int
		unit     string
		errText  string // "" when no error is expected
	}{
		{"crates", "12 crates", 12, "crates", ""},
		{"err empty", "", 0, "", "want a number and a unit"},
		{"err three fields", "1 2 3", 0, "", "want a number and a unit"},
		{"err not a number", "many crates", 0, "", "strconv.Atoi: parsing \"many\": invalid syntax"},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			n, unit, err := ParseQuantity(c.in)
			got := ""
			if err != nil {
				got = err.Error()
			}
			if got != c.errText {
				t.Fatalf("ParseQuantity(%q): error %q, want %q", c.in, got, c.errText)
			}
			if n != c.n || unit != c.unit {
				t.Errorf("ParseQuantity(%q) = %d, %q; want %d, %q", c.in, n, unit, c.n, c.unit)
			}
		})
	}
}
`

var durations = regexp.MustCompile(`(?m)( \([0-9.]+s\)$)|(^(ok|FAIL)(\s+example)\s+[0-9.]+s$)`)

func main() {
	dir, err := os.MkdirTemp("", "kata")
	if err != nil {
		panic(err)
	}
	defer os.RemoveAll(dir)
	must(os.WriteFile(filepath.Join(dir, "quantity.go"), []byte(source), 0o644))
	must(os.WriteFile(filepath.Join(dir, "quantity_test.go"), []byte(test), 0o644))
	init := exec.Command("go", "mod", "init", "example")
	init.Dir = dir
	must(init.Run())

	run(dir, "go", "test", "-v", "-run", "/err")
}

func run(dir string, name string, args ...string) {
	fmt.Println("$", name, joinArgs(args))
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	out, _ := cmd.CombinedOutput()
	fmt.Print(durations.ReplaceAllString(string(out), "$3$4"))
	fmt.Println("exit status", cmd.ProcessState.ExitCode())
}

func joinArgs(args []string) string {
	s := ""
	for i, a := range args {
		if i > 0 {
			s += " "
		}
		s += a
	}
	return s
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}
