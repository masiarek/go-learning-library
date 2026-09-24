#!/usr/bin/env bash
# Every s[i] the compiler cannot prove safe keeps a bounds check, and
# -gcflags=-d=ssa/check_bce prints one line per check it kept. This script
# builds a file of seven small functions, prints those lines, then counts them
# per function. The functions are marked go:noinline so that each check is
# reported once, in the function itself, and not again wherever main inlined it.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >main.go <<'GO'
package main

// Four indexes, four checks.
//
//go:noinline
func checksumUnchecked(s []byte) byte {
	return s[0] ^ s[1] ^ s[2] ^ s[3]
}

// The hint checks index 3 once; the four reads after it need no check.
//
//go:noinline
func checksumHinted(s []byte) byte {
	_ = s[3]
	return s[0] ^ s[1] ^ s[2] ^ s[3]
}

// The range loop's i is within the slice by construction.
//
//go:noinline
func sumRange(readings []int) int {
	total := 0
	for i := range readings {
		total += readings[i]
	}
	return total
}

// n is unrelated to len(readings), so every readings[i] is checked.
//
//go:noinline
func sumIndexed(readings []int, n int) int {
	total := 0
	for i := 0; i < n; i++ {
		total += readings[i]
	}
	return total
}

// code&7 is 0..7, which fits an [8]int exactly.
//
//go:noinline
func histogramMasked(codes []int) [8]int {
	var buckets [8]int
	for _, code := range codes {
		buckets[code&7]++
	}
	return buckets
}

// code%8 can be negative for a negative code, so the check stays.
//
//go:noinline
func histogramModulo(codes []int) [8]int {
	var buckets [8]int
	for _, code := range codes {
		buckets[code%8]++
	}
	return buckets
}

// A slice expression is checked too: IsSliceInBounds.
//
//go:noinline
func header(frame []byte, n int) []byte {
	return frame[:n]
}

func main() {
	frame := []byte{1, 2, 3, 4, 5, 6, 7, 8}
	println(checksumUnchecked(frame), checksumHinted(frame), len(header(frame, 4)))
	readings := []int{3, 1, 4}
	println(sumRange(readings), sumIndexed(readings, 3))
	println(histogramMasked(readings)[3], histogramModulo(readings)[3])
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go build -gcflags=-d=ssa/check_bce . 2>&1'
go build -gcflags=-d=ssa/check_bce . >bce.txt 2>&1
status=$?
cat bce.txt
echo "exit status $status"

# Count the checks per function: a check on line L belongs to the last
# `func` declared at or before L.
say 'checks kept, per function:'
awk -F: '
FNR == NR { if ($0 ~ /^func /) { n++; name[n] = $1; sub(/^func /, "", name[n]); sub(/\(.*/, "", name[n]); start[n] = FNR }; next }
/Found Is/ { line = $2 + 0; for (i = n; i >= 1; i--) if (line >= start[i]) { count[name[i]]++; break } }
END { for (i = 1; i <= n; i++) printf "  %-18s %d\n", name[i], count[name[i]] + 0 }
' main.go bce.txt
