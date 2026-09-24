// Kata: take ParseQuantity's coverage from two test cases to 100% by adding
// the case that reaches the last untested branch, and prove it with go tool
// cover -func before and after. The program writes the module to a
// temporary directory and prints both per-function tables.
//
//	go build coverage_and_the_run_flag_kata_go.go && ./coverage_and_the_run_flag_kata_go
package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
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
	if n, unit, err := ParseQuantity("12 crates"); n != 12 || unit != "crates" || err != nil {
		t.Errorf("ParseQuantity(\"12 crates\") = %d, %q, %v", n, unit, err)
	}
	if _, _, err := ParseQuantity(""); err == nil {
		t.Error("want an error for an empty quantity")
	}
}
`

const moreTest = `package stock

import "testing"

func TestParseQuantityNotANumber(t *testing.T) {
	if _, _, err := ParseQuantity("many crates"); err == nil {
		t.Error("want an error for a quantity that is not a number")
	}
}
`

func main() {
	dir, err := os.MkdirTemp("", "kata")
	if err != nil {
		panic(err)
	}
	defer os.RemoveAll(dir)
	must(os.WriteFile(filepath.Join(dir, "quantity.go"), []byte(source), 0o644))
	must(os.WriteFile(filepath.Join(dir, "quantity_test.go"), []byte(test), 0o644))
	run(dir, "go", "mod", "init", "example")

	coverage(dir)
	fmt.Println("$ cat >more_test.go   # the case that reaches the Atoi error branch")
	must(os.WriteFile(filepath.Join(dir, "more_test.go"), []byte(moreTest), 0o644))
	coverage(dir)
}

// coverage records a profile and prints the per-function table.
func coverage(dir string) {
	run(dir, "go", "test", "-coverprofile=cover.out")
	fmt.Println("$ go tool cover -func=cover.out")
	cmd := exec.Command("go", "tool", "cover", "-func=cover.out")
	cmd.Dir = dir
	out, err := cmd.CombinedOutput()
	fmt.Print(string(out))
	must(err)
}

// run runs a command whose output is not part of the key.
func run(dir string, name string, args ...string) {
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	if out, err := cmd.CombinedOutput(); err != nil {
		panic(string(out))
	}
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}
