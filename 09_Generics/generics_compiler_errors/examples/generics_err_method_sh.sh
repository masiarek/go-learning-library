#!/usr/bin/env bash
# A method may not declare type parameters of its own. This is a syntax error:
# the parser refuses it before the type checker sees the file.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/method.go" <<'GO'
package main

type Ledger struct{ amounts []int }

func (l Ledger) Convert[U any](f func(int) U) []U {
	out := make([]U, 0, len(l.amounts))
	for _, a := range l.amounts {
		out = append(out, f(a))
	}
	return out
}

func main() {}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build method.go'
(cd "$dir" && go build method.go) 2>&1
echo "exit status $?"
