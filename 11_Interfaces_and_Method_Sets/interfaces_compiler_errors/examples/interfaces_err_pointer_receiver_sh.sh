#!/usr/bin/env bash
# Wallet has Deposit on a pointer receiver, so only *Wallet satisfies
# Depositor. Passing a Wallet value where a Depositor is wanted is refused,
# and the message names the method and the receiver kind.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/wallet.go" <<'GO'
package main

import "fmt"

type Wallet struct{ cents int }

func (w *Wallet) Deposit(cents int) { w.cents += cents }

type Depositor interface{ Deposit(cents int) }

func payday(d Depositor) { d.Deposit(5000) }

func main() {
	var w Wallet
	payday(w)
	fmt.Println(w.cents)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build wallet.go'
(cd "$dir" && go build wallet.go) 2>&1
echo "exit status $?"
