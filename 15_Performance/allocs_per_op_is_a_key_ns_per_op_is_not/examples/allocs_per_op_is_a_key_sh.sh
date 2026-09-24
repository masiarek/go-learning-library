#!/usr/bin/env bash
# A benchmark's allocs/op and B/op come out the same on every run and on every
# machine; its ns/op does not. This script runs `go test -bench` on two ways of
# building an order line and prints only the columns that cannot vary -- the
# benchmark names, B/op and allocs/op -- plus how many times each benchmark
# function was entered. The full table, ns/op included, is in demo/bench_table.sh.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >line_test.go <<'GO'
package example

import (
	"fmt"
	"os"
	"strings"
	"testing"
)

var fields = []string{
	"customer=acme-industries",
	"item=steel-bracket-40mm",
	"quantity=1200",
	"warehouse=rotterdam-east",
	"carrier=overnight-freight",
	"priority=high",
	"currency=EUR",
	"reference=PO-2026-000418",
}

// joinWithPlus makes a new string for every field: one allocation each.
func joinWithPlus(fields []string) string {
	line := "order:"
	for _, f := range fields {
		line += f + ";"
	}
	return line
}

// joinWithBuilder asks for the room once; String() hands the bytes over
// without copying them.
func joinWithBuilder(fields []string) string {
	var b strings.Builder
	b.Grow(256)
	b.WriteString("order:")
	for _, f := range fields {
		b.WriteString(f)
		b.WriteByte(';')
	}
	return b.String()
}

// entered counts how many times each benchmark function was called.
var entered = map[string]int{}

func BenchmarkJoinWithPlus(b *testing.B) {
	entered[b.Name()]++
	for b.Loop() {
		joinWithPlus(fields)
	}
}

func BenchmarkJoinWithBuilder(b *testing.B) {
	entered[b.Name()]++
	for b.Loop() {
		joinWithBuilder(fields)
	}
}

// The loop shape every benchmark used before Go 1.24.
func BenchmarkJoinWithPlusOldLoop(b *testing.B) {
	entered[b.Name()]++
	for i := 0; i < b.N; i++ {
		joinWithPlus(fields)
	}
}

func TestMain(m *testing.M) {
	code := m.Run()
	for _, name := range []string{"BenchmarkJoinWithPlus", "BenchmarkJoinWithBuilder", "BenchmarkJoinWithPlusOldLoop"} {
		fmt.Printf("%s entered %d time(s)\n", name, entered[name])
	}
	os.Exit(code)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

# -benchtime=2000x runs each loop exactly 2000 times, so this takes well under a
# second; the default is one second of iterations per benchmark.
say "go test -bench=. -benchmem -benchtime=2000x -run='^$' >bench.txt"
go test -bench=. -benchmem -benchtime=2000x -run='^$' >bench.txt 2>&1
status=$?

# Only the columns that cannot vary: drop the -N GOMAXPROCS suffix from the
# name, the iteration count and ns/op.
columns='/allocs\/op$/ { sub(/-[0-9]+$/, "", $1); printf "%-30s %5s B/op %3s allocs/op\n", $1, $(NF-3), $(NF-1) }'
say "awk '$columns' bench.txt"
awk "$columns" bench.txt

say "grep -E '^(PASS|FAIL|ok|Benchmark.* entered)' bench.txt"
grep -E '^(PASS|FAIL|ok|Benchmark.* entered)' bench.txt | sed -E 's/\t[0-9.]+s$//'
echo "exit status $status"
