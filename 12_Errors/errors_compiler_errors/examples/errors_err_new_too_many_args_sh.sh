#!/usr/bin/env bash
# errors.New takes one string and does no formatting. A format verb and an
# argument belong to fmt.Errorf.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/new_with_args.go" <<'GO'
package main

import "errors"

func main() {
	id := 7
	err := errors.New("order %d not found", id)
	_ = err
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build new_with_args.go'
(cd "$dir" && go build new_with_args.go) 2>&1
echo "exit status $?"
