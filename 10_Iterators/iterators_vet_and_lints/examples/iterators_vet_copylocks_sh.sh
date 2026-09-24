#!/usr/bin/env bash
# vet's copylocks analyzer on a range loop whose variable copies a struct that
# holds a sync.Mutex -- over the slice directly, and through slices.Values,
# which vet sees through as well. The good version ranges over indexes.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/copies.go" <<'GO'
package main

import (
	"fmt"
	"slices"
	"sync"
)

// Account guards its balance with a mutex, so it must not be copied.
type Account struct {
	mu      sync.Mutex
	balance int
}

func main() {
	accounts := []Account{{balance: 10}, {balance: 20}}
	for _, a := range accounts {
		fmt.Println(a.balance)
	}
	for a := range slices.Values(accounts) {
		fmt.Println(a.balance)
	}
}
GO

cat >"$dir/indexes.go" <<'GO'
package main

import (
	"fmt"
	"slices"
	"sync"
)

// Account guards its balance with a mutex, so it must not be copied.
type Account struct {
	mu      sync.Mutex
	balance int
}

func main() {
	accounts := []Account{{balance: 10}, {balance: 20}}
	for i := range accounts {
		fmt.Println(accounts[i].balance)
	}
	for i := range slices.All(accounts) {
		fmt.Println(accounts[i].balance)
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go vet copies.go'
(cd "$dir" && go vet copies.go) 2>&1
echo "exit status $?"

say 'go vet indexes.go'
(cd "$dir" && go vet indexes.go) 2>&1
echo "exit status $?"
