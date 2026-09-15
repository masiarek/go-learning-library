#!/usr/bin/env bash
# The runtime's deadlock detector, twice.
#
# lonely_send: main sends on an unbuffered channel that nothing will ever
# receive from. The runtime stops the program with a fatal error, exit status 2.
#
# sleeper: a packer and a shipper wait for each other forever, main waits for
# the shipment, and one more goroutine sleeps for 2 s and returns. The runtime
# reports nothing while the sleeper sleeps; its line is printed, and only then
# does the fatal error come.
#
# stderr also carries goroutine numbers, a temporary path and code offsets,
# which vary. This script keeps the fatal error line and, for each goroutine,
# its state and the function it is in, with its number replaced by N.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/lonely_send.go" <<'GO'
package main

import "fmt"

func main() {
	orders := make(chan string)
	fmt.Println("main: sending an order that nothing will receive")
	orders <- "order-17"
	fmt.Println("main: never printed")
}
GO

cat >"$dir/sleeper.go" <<'GO'
package main

import (
	"fmt"
	"time"
)

func main() {
	boxes := make(chan string)
	labels := make(chan string)
	shipped := make(chan string)

	fmt.Println("main: waiting for a shipment")
	go packer(labels, boxes)
	go shipper(boxes, labels, shipped)
	go sleeper()
	fmt.Println("main: shipped", <-shipped)
}

// packer will not pack a box until it has a shipping label.
func packer(labels <-chan string, boxes chan<- string) {
	label := <-labels
	boxes <- "box with " + label
}

// shipper will not print a label until it has a box.
func shipper(boxes <-chan string, labels chan<- string, shipped chan<- string) {
	box := <-boxes
	labels <- "label-1"
	shipped <- box
}

// sleeper is not part of the deadlock: it sleeps for 2 s and returns.
func sleeper() {
	time.Sleep(2 * time.Second)
	fmt.Println("sleeper: awake after 2 s, returning")
}
GO

say() { printf '$ %s\n' "$*"; }

# run NAME: build NAME.go, run it, and print its stdout, the stable part of its
# stderr, and its exit status.
run() {
	say "go build $1.go"
	(cd "$dir" && go build "$1.go") || exit 1
	say "./$1"
	(cd "$dir" && "./$1" 2>stderr.txt)
	local status=$?
	awk '
		/^fatal error:/ { print }
		/^goroutine [0-9]+ \[/ {
			state = $0
			sub(/^goroutine [0-9]+ /, "goroutine N ", state)
			sub(/:$/, "", state)
			getline frame
			sub(/\(.*/, "", frame)
			print state " in " frame
		}
	' "$dir/stderr.txt"
	echo "exit status $status"
}

run lonely_send
run sleeper
