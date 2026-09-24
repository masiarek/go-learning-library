#!/usr/bin/env bash
# recover is a built-in, not a function value, and it takes no argument: it
# cannot be stored in a variable to defer later, and it cannot be told which
# panic to catch.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/recover_misuse.go" <<'GO'
package main

func main() {
	onPanic := recover
	defer onPanic()
	defer recover("invoice 18 has no customer")
	panic("invoice 18 has no customer")
}
GO

say() { printf '$ %s\n' "$*"; }
cd "$dir" || exit 1

say 'go build recover_misuse.go'
go build recover_misuse.go 2>&1
echo "exit status $?"
