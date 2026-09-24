#!/usr/bin/env bash
# composites: an unkeyed struct literal of a type from another package is
# reported, and an instantiated generic struct is no exception. Keyed fields
# are silent.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
mkdir -p "$dir/ledger"
cd "$dir" || exit 1

cat >ledger/ledger.go <<'GO'
package ledger

type Entry[A any] struct {
	Account string
	Amount  A
}
GO

cat >main.go <<'GO'
package main

import (
	"fmt"

	"example/ledger"
)

func main() {
	fmt.Println(ledger.Entry[int]{"cash", 100})
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go vet ./...'
go vet ./... 2>&1
echo "exit status $?"

cat >main.go <<'GO'
package main

import (
	"fmt"

	"example/ledger"
)

func main() {
	fmt.Println(ledger.Entry[int]{Account: "cash", Amount: 100})
}
GO

say 'go vet ./...   # with keyed fields'
go vet ./... 2>&1
echo "exit status $?"
