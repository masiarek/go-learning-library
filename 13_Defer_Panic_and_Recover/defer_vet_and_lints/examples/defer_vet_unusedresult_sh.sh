#!/usr/bin/env bash
# unusedresult: fmt.Errorf builds an error and returns it; a deferred closure
# that calls it without assigning to the named result wraps nothing. The
# good version assigns, and the caller sees the wrapped error.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/dropped.go" <<'GO'
package main

import (
	"errors"
	"fmt"
)

func saveOrder(id int) (err error) {
	defer func() {
		if err != nil {
			fmt.Errorf("saving order %d: %w", id, err)
		}
	}()
	return errors.New("disk full")
}

func main() { fmt.Println(saveOrder(18)) }
GO

cat >"$dir/assigned.go" <<'GO'
package main

import (
	"errors"
	"fmt"
)

func saveOrder(id int) (err error) {
	defer func() {
		if err != nil {
			err = fmt.Errorf("saving order %d: %w", id, err)
		}
	}()
	return errors.New("disk full")
}

func main() { fmt.Println(saveOrder(18)) }
GO

say() { printf '$ %s\n' "$*"; }
cd "$dir" || exit 1

say 'go vet dropped.go'
go vet dropped.go 2>&1
echo "exit status $?"

say 'go vet assigned.go'
go vet assigned.go 2>&1
echo "exit status $?"
say 'go run assigned.go'
go run assigned.go
