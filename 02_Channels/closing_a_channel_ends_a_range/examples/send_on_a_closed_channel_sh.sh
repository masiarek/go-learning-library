#!/usr/bin/env bash
# A send on a closed channel, with nothing to recover the panic: the program
# ends with exit status 2. Its stderr also carries a goroutine trace with a
# temporary path and code offsets, so this script keeps only the panic line.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/closed_send.go" <<'GO'
package main

import "fmt"

func main() {
	orders := make(chan string, 1)
	close(orders)
	fmt.Println("main: closed the channel, now sending on it")
	orders <- "order-18"
	fmt.Println("main: never printed")
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build closed_send.go'
(cd "$dir" && go build closed_send.go) || exit 1

say './closed_send'
(cd "$dir" && ./closed_send 2>stderr.txt)
status=$?
grep '^panic:' "$dir/stderr.txt"
echo "exit status $status"
