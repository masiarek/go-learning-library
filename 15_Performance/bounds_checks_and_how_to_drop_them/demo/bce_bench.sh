#!/usr/bin/env bash
# What a bounds check costs, measured: the checksum functions from
# examples/bounds_checks_and_how_to_drop_them_sh.sh under `go test -bench`,
# with and without the hint, and a loop over a 1024-byte frame indexed two
# ways. ns/op is machine-dependent, which is why it lives here and not in a key.
#
#   bash demo/bce_bench.sh          # from the lesson folder
set -u
cd "$(dirname "$0")" || exit 1
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

cat >"$dir/bce_test.go" <<'GO'
package example

import "testing"

var frame = make([]byte, 1024)

func checksumUnchecked(s []byte) byte { return s[0] ^ s[1] ^ s[2] ^ s[3] }

func checksumHinted(s []byte) byte {
	_ = s[3]
	return s[0] ^ s[1] ^ s[2] ^ s[3]
}

func xorIndexed(s []byte, n int) byte {
	var x byte
	for i := 0; i < n; i++ {
		x ^= s[i]
	}
	return x
}

func xorRange(s []byte) byte {
	var x byte
	for i := range s {
		x ^= s[i]
	}
	return x
}

func BenchmarkChecksumUnchecked(b *testing.B) {
	for b.Loop() {
		checksumUnchecked(frame)
	}
}

func BenchmarkChecksumHinted(b *testing.B) {
	for b.Loop() {
		checksumHinted(frame)
	}
}

func BenchmarkXorIndexed(b *testing.B) {
	for b.Loop() {
		xorIndexed(frame, len(frame))
	}
}

func BenchmarkXorRange(b *testing.B) {
	for b.Loop() {
		xorRange(frame)
	}
}
GO
cd "$dir" && go mod init example >/dev/null 2>&1 || exit 1
echo '$ go build -gcflags=-d=ssa/check_bce . 2>&1'
go vet . >/dev/null 2>&1
go test -c -o /dev/null -gcflags=-d=ssa/check_bce . 2>&1 | grep Found
echo "\$ go test -bench=. -count=3 -run='^\$'"
go test -bench=. -count=3 -run='^$'
