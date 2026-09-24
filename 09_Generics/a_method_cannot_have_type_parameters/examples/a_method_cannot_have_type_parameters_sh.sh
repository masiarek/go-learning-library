#!/usr/bin/env bash
# A method may use its receiver's type parameters, and may not declare any of
# its own. Stack[T].Map[U] is refused by the parser, before type checking.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/generic_method.go" <<'GO'
package main

type Stack[T any] struct{ items []T }

// Map would turn a Stack[T] into a Stack[U] -- but U is the method's own
// type parameter, and a method may not have one.
func (s *Stack[T]) Map[U any](f func(T) U) *Stack[U] {
	out := &Stack[U]{}
	for _, v := range s.items {
		out.items = append(out.items, f(v))
	}
	return out
}

func main() {}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build generic_method.go'
(cd "$dir" && go build generic_method.go) 2>&1
echo "exit status $?"
