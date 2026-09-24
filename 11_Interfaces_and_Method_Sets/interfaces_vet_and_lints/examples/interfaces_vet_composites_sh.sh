#!/usr/bin/env bash
# composites: a struct literal of a type from another package with its
# fields given by position. Employee embeds net/mail.Address; vet flags the
# unkeyed mail.Address literal and says nothing about the local Employee
# literal around it, keyed or not. The good version names the fields.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >main.go <<'GO'
package main

import (
	"fmt"
	"net/mail"
)

type Employee struct {
	mail.Address
	Dept string
}

func main() {
	e := Employee{mail.Address{"Ann Lee", "ann@example.com"}, "Sales"}
	fmt.Println(e.Name, e.Address.String(), e.Dept)
}
GO

cat >keyed.go <<'GO'
package main

import (
	"fmt"
	"net/mail"
)

type Employee struct {
	mail.Address
	Dept string
}

func main() {
	e := Employee{Address: mail.Address{Name: "Ann Lee", Address: "ann@example.com"}, Dept: "Sales"}
	fmt.Println(e.Name, e.Address.String(), e.Dept)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go vet main.go'
go vet main.go 2>&1
echo "exit status $?"

say 'go vet keyed.go'
go vet keyed.go 2>&1
echo "exit status $?"
