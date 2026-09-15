#!/usr/bin/env bash
# "Only the sender closes" can be written into a type. A function that takes a
# receive-only channel, <-chan T, cannot close it: the compiler refuses.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/receiver_closes.go" <<'GO'
package main

func main() {
	orders := make(chan string, 1)
	orders <- "order-19"
	pack(orders)
}

// pack only receives orders, and its parameter type says so.
func pack(orders <-chan string) {
	<-orders
	close(orders)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build receiver_closes.go'
(cd "$dir" && go build receiver_closes.go) 2>&1
echo "exit status $?"
