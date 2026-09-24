// Kata: embed this program's own source file into the binary it becomes, and
// prove it by reading the copy back: the copy names the package, holds its
// own //go:embed directive, and ends with a newline like every gofmt file.
//
//	go build -trimpath go_embed_puts_files_in_the_binary_kata_go.go && ./go_embed_puts_files_in_the_binary_kata_go
package main

import (
	_ "embed"
	"fmt"
	"strings"
)

//go:embed go_embed_puts_files_in_the_binary_kata_go.go
var source string

func main() {
	lines := strings.Split(strings.TrimSuffix(source, "\n"), "\n")
	fmt.Println("first line:", lines[0])
	fmt.Println("declares package main:", strings.Contains(source, "\npackage main\n"))
	fmt.Println("holds its own directive:", strings.Contains(source, "//go:embed go_embed_puts_files_in_the_binary_kata_go.go"))
	fmt.Println("ends with a newline:", strings.HasSuffix(source, "\n"))
	fmt.Println("lines:", len(lines))
}
