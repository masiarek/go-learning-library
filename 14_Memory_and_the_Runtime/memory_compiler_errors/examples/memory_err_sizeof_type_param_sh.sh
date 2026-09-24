#!/usr/bin/env bash
# unsafe.Sizeof is a constant for every ordinary type, and so it can size an
# array. For a value of a type parameter's type the size depends on the type
# argument, so Sizeof is not a constant and the array declaration fails.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/encode.go" <<'GO'
package main

import "unsafe"

type Reading struct {
	Sensor int32
	Value  float64
}

// rawReading is fine: Sizeof(Reading{}) is the constant 16.
var rawReading [unsafe.Sizeof(Reading{})]byte

// encode is not: Sizeof(v) is only known once T is.
func encode[T any](v T) []byte {
	var raw [unsafe.Sizeof(v)]byte
	return raw[:]
}

func main() {
	_ = rawReading
	_ = encode(Reading{})
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build encode.go'
(cd "$dir" && go build encode.go) 2>&1
echo "exit status $?"
