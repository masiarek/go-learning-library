#!/usr/bin/env bash
# unmarshal: json.Unmarshal into a value rather than a pointer to it. The
# call compiles, and at run time it returns an error instead of filling the
# struct; vet reports it before the program runs.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

cat >main.go <<'GO'
package main

import (
	"encoding/json"
	"fmt"
)

type Customer struct {
	Name string `json:"name"`
}

func main() {
	var c Customer
	err := json.Unmarshal([]byte(`{"name": "Ada"}`), c)
	fmt.Printf("name %q, err: %v\n", c.Name, err)
}
GO

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go vet .'
go vet . 2>&1
echo "exit status $?"

say 'go run .'
go run .
echo "exit status $?"
