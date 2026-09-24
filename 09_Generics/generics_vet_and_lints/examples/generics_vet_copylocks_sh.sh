#!/usr/bin/env bash
# copylocks sees through a type parameter: a Counter[K] that holds a
# sync.Mutex is reported wherever it is passed by value -- a value receiver,
# a parameter, and the call site -- and the pointer version is clean.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
mkdir -p "$dir/bad" "$dir/good"

cat >"$dir/bad/main.go" <<'GO'
package main

import (
	"fmt"
	"sync"
)

type Counter[K comparable] struct {
	mu     sync.Mutex
	counts map[K]int
}

func (c Counter[K]) Add(key K) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.counts[key]++
}

func Size[K comparable](c Counter[K]) int { return len(c.counts) }

func main() {
	c := Counter[string]{counts: map[string]int{}}
	c.Add("orders")
	fmt.Println(Size(c))
}
GO

cat >"$dir/good/main.go" <<'GO'
package main

import (
	"fmt"
	"sync"
)

type Counter[K comparable] struct {
	mu     sync.Mutex
	counts map[K]int
}

func (c *Counter[K]) Add(key K) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.counts[key]++
}

func Size[K comparable](c *Counter[K]) int { return len(c.counts) }

func main() {
	c := &Counter[string]{counts: map[string]int{}}
	c.Add("orders")
	fmt.Println(Size(c))
}
GO

say() { printf '$ %s\n' "$*"; }

for variant in bad good; do
	cd "$dir/$variant" || exit 1
	go mod init example >/dev/null 2>&1 || exit 1
	say "cd $variant && go vet ."
	go vet . 2>&1
	echo "exit status $?"
done
