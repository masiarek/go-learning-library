#!/usr/bin/env bash
# Two embedded types at the same depth that both have a Name field and a
# Describe method: the outer type has neither, and using either through it
# is a compile error, "ambiguous selector". Naming the path, or giving the
# outer type its own Name and Describe, resolves it.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/ambiguous.go" <<'GO'
package main

import "fmt"

type Person struct{ Name string }

func (p Person) Describe() string { return "person " + p.Name }

type Company struct{ Name string }

func (c Company) Describe() string { return "company " + c.Name }

// Contact embeds both, so both promote a Name and a Describe at depth 1.
type Contact struct {
	Person
	Company
}

func main() {
	c := Contact{Person{"Ann Lee"}, Company{"Northwind"}}
	fmt.Println(c.Name)
	fmt.Println(c.Describe())
}
GO

cat >"$dir/resolved.go" <<'GO'
package main

import "fmt"

type Person struct{ Name string }

func (p Person) Describe() string { return "person " + p.Name }

type Company struct{ Name string }

func (c Company) Describe() string { return "company " + c.Name }

type Contact struct {
	Person
	Company
}

// A Describe at depth 0 shadows both promoted ones.
func (c Contact) Describe() string { return c.Person.Describe() + " at " + c.Company.Name }

func main() {
	c := Contact{Person{"Ann Lee"}, Company{"Northwind"}}
	fmt.Println(c.Person.Name) // the full path is never ambiguous
	fmt.Println(c.Describe())
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build ambiguous.go'
(cd "$dir" && go build ambiguous.go) 2>&1
echo "exit status $?"

say 'go run resolved.go'
(cd "$dir" && go run resolved.go) 2>&1
echo "exit status $?"
