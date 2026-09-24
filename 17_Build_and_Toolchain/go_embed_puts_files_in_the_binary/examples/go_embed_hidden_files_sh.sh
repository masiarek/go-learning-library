#!/usr/bin/env bash
# A directory pattern skips files whose names begin with . or _ ; a pattern
# with a wildcard names the top-level entries and so keeps them; the all:
# prefix keeps them at every depth.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

go mod init example >/dev/null 2>&1 || exit 1

mkdir -p notes/drafts
printf 'editor state\n' >notes/.swap
printf 'not ready\n' >notes/_draft.txt
printf 'published\n' >notes/release.txt
printf 'also not ready\n' >notes/drafts/_next.txt
printf 'planned\n' >notes/drafts/roadmap.txt

cat >main.go <<'GO'
package main

import (
	"embed"
	"fmt"
	"io/fs"
)

//go:embed notes
var plain embed.FS

//go:embed notes/*
var starred embed.FS

//go:embed all:notes
var everything embed.FS

func list(label string, files embed.FS) {
	fs.WalkDir(files, "notes", func(path string, d fs.DirEntry, err error) error {
		if !d.IsDir() {
			fmt.Printf("%-14s %s\n", label+":", path)
		}
		return nil
	})
}

func main() {
	list("notes", plain)
	list("notes/*", starred)
	list("all:notes", everything)
}
GO

say 'gofmt -l .'
gofmt -l .
say 'go run .'
go run .
