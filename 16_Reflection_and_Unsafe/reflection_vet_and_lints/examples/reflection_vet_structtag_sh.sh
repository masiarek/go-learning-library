#!/usr/bin/env bash
# structtag checks the key:"value" form that reflect.StructTag.Get parses, a
# json or xml name used twice in one struct, and a json tag on a field that
# the encoder can never see. The compiler accepts all five tags: a tag is a
# string. The corrected struct passes vet with exit status 0.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

mkdir bad good

cat >bad/main.go <<'GO'
package main

import (
	"encoding/json"
	"fmt"
)

type Customer struct {
	Name    string `json:name`
	Email   string `json: "email"`
	Phone   string `json:"phone",xml:"phone"`
	Contact string `json:"phone"`
	balance int    `json:"balance"`
}

func main() {
	data, err := json.Marshal(Customer{Name: "Ada", balance: 10})
	fmt.Println(string(data), err)
}
GO

cat >good/main.go <<'GO'
package main

import (
	"encoding/json"
	"fmt"
)

type Customer struct {
	Name    string `json:"name"`
	Email   string `json:"email"`
	Phone   string `json:"phone" xml:"phone"`
	Contact string `json:"contact"`
	balance int
}

func main() {
	data, err := json.Marshal(Customer{Name: "Ada", balance: 10})
	fmt.Println(string(data), err)
}
GO

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go build -o customer ./bad'
go build -o customer ./bad 2>&1
echo "exit status $?"

say 'go vet ./bad'
go vet ./bad 2>&1
echo "exit status $?"

say 'go vet ./good'
go vet ./good 2>&1
echo "exit status $?"

say 'go run ./good'
go run ./good
echo "exit status $?"
