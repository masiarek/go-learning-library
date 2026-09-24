#!/usr/bin/env bash
# //go:embed copies files into the binary at build time: a text file into a
# string, a binary file into a []byte, a directory tree into an embed.FS. The
# proof is at the end: the sources are deleted and the binary still has them.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

go mod init example >/dev/null 2>&1 || exit 1

mkdir -p templates/emails
printf 'Dear %%s,\nyour order %%s has shipped.\n' >templates/emails/shipped.txt
printf 'Dear %%s,\nyour order %%s was cancelled.\n' >templates/emails/cancelled.txt
printf '1.4.2\n' >VERSION
printf '\211PNG\r\n' >logo.bin

cat >main.go <<'GO'
package main

import (
	"embed"
	"fmt"
	"io/fs"
)

//go:embed VERSION
var version string

//go:embed logo.bin
var logo []byte

//go:embed templates
var templates embed.FS

func main() {
	fmt.Printf("version: %q\n", version)
	fmt.Printf("logo: %d bytes, % x\n", len(logo), logo)

	entries, err := fs.ReadDir(templates, "templates/emails")
	if err != nil {
		panic(err)
	}
	for _, e := range entries {
		fmt.Println("ReadDir:", e.Name())
	}

	err = fs.WalkDir(templates, ".", func(path string, d fs.DirEntry, err error) error {
		fmt.Printf("WalkDir: %s dir=%t\n", path, d.IsDir())
		return err
	})
	if err != nil {
		panic(err)
	}

	body, err := templates.ReadFile("templates/emails/shipped.txt")
	if err != nil {
		panic(err)
	}
	fmt.Printf("shipped.txt: %q\n", body)
}
GO

say 'gofmt -l .'
gofmt -l .
say 'go build -o mailer .'
go build -o mailer . || exit 1
say 'rm -r templates VERSION logo.bin main.go go.mod'
rm -r templates VERSION logo.bin main.go go.mod
say 'ls'
ls
say './mailer'
./mailer
echo "exit status $?"
