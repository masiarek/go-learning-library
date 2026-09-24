#!/usr/bin/env bash
# Three ways to misuse b.Loop: leaving the loop early with break, nesting one
# b.Loop inside another, and mixing it with a b.N loop. None is a compile
# error; the testing package fails the benchmark at run time. The messages
# name a line of testing's benchmark.go, which moves between Go versions, so
# the number is replaced.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >loop_test.go <<'GO'
package example

import (
	"strings"
	"testing"
)

var fields = []string{"customer=acme-industries", "item=steel-bracket-40mm"}

func BenchmarkBreak(b *testing.B) {
	for b.Loop() {
		if strings.Join(fields, ";") != "" {
			break // measured one iteration, then left
		}
	}
}

func BenchmarkNested(b *testing.B) {
	for b.Loop() {
		for b.Loop() {
			strings.Join(fields, ";")
		}
	}
}

func BenchmarkMixed(b *testing.B) {
	for i := 0; i < b.N; i++ {
		for b.Loop() {
			strings.Join(fields, ";")
		}
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say "go test -bench=. -run='^$'"
go test -bench=. -run='^$' 2>&1 | grep -v '^goos:\|^goarch:\|^pkg:\|^cpu:' | sed -E 's/benchmark\.go:[0-9]+:/benchmark.go:<line>:/; s/\t[0-9.]+s$//'
echo "exit status ${PIPESTATUS[0]}"
