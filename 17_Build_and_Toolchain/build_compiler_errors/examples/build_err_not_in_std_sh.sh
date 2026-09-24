#!/usr/bin/env bash
# An import path names a package by its full path, module path first. A bare
# "orders" is looked up in the standard library, and the message names the
# one place it looked. The directory in that message is GOROOT, which differs
# between machines, so this script replaces it with the word GOROOT.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

go mod init example >/dev/null 2>&1 || exit 1
mkdir orders
cat >orders/orders.go <<'GO'
package orders

func Count() int { return 3 }
GO

cat >main.go <<'GO'
package main

import (
	"fmt"
	"orders"
)

func main() { fmt.Println("orders:", orders.Count()) }
GO

say 'go build -o report .'
go build -o report . 2>&1 | sed -E 's#\(.*/src/orders\)#(GOROOT/src/orders)#'
echo "exit status ${PIPESTATUS[0]}"

cat >main.go <<'GO'
package main

import (
	"example/orders"
	"fmt"
)

func main() { fmt.Println("orders:", orders.Count()) }
GO

say 'go build -o report . && ./report'
go build -o report . 2>&1 && ./report
echo "exit status $?"
