#!/usr/bin/env bash
# Two embedded types at the same depth both promote Name and Describe; the
# outer type has no own Name or Describe to win, so either selector is
# ambiguous. The error appears only where the selector is used.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/contact.go" <<'GO'
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

func main() {
	c := Contact{Person{"Ann Lee"}, Company{"Northwind"}}
	fmt.Println(c.Name, c.Describe())
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build contact.go'
(cd "$dir" && go build contact.go) 2>&1
echo "exit status $?"
