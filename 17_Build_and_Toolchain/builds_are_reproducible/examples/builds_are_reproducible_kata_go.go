// Kata: prove reproducibility from Go rather than from the shell. The program
// writes a small module into two temporary directories, builds it twice with
// -trimpath in the first, once with -trimpath in the second, and once without
// in each, and compares the bytes. It needs the go command on PATH and prints
// no path, hash or size.
//
//	go build -trimpath builds_are_reproducible_kata_go.go && ./builds_are_reproducible_kata_go
package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

const source = `package main

import "fmt"

func main() {
	fmt.Println("invoice printer")
}
`

func main() {
	first := module()
	defer os.RemoveAll(first)
	second := module()
	defer os.RemoveAll(second)

	one := build(first, "one", "-trimpath")
	two := build(first, "two", "-trimpath")
	fmt.Println("same directory, -trimpath twice, identical:", bytes.Equal(one, two))

	three := build(second, "three", "-trimpath")
	fmt.Println("other directory, -trimpath, identical:     ", bytes.Equal(one, three))

	plainOne := build(first, "plain")
	plainTwo := build(second, "plain")
	fmt.Println("both directories, no -trimpath, identical: ", bytes.Equal(plainOne, plainTwo))
}

// module writes go.mod and main.go into a fresh temporary directory.
func module() string {
	dir, err := os.MkdirTemp("", "reproducible")
	if err != nil {
		panic(err)
	}
	must(os.WriteFile(filepath.Join(dir, "go.mod"), []byte("module example\n\ngo 1.25\n"), 0o644))
	must(os.WriteFile(filepath.Join(dir, "main.go"), []byte(source), 0o644))
	return dir
}

// build runs go build in dir with the given flags and returns the binary's bytes.
func build(dir, name string, flags ...string) []byte {
	args := append([]string{"build", "-o", name}, flags...)
	cmd := exec.Command("go", append(args, ".")...)
	cmd.Dir = dir
	cmd.Env = append(os.Environ(), "GOTOOLCHAIN=local")
	if out, err := cmd.CombinedOutput(); err != nil {
		panic(fmt.Sprintf("go build: %v\n%s", err, out))
	}
	data, err := os.ReadFile(filepath.Join(dir, name))
	must(err)
	return data
}

func must(err error) {
	if err != nil {
		panic(err)
	}
}
