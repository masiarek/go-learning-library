#!/usr/bin/env bash
# vet's unusedresult analyzer: slices.Sorted and slices.Collect build a new
# slice and return it, and a call whose result is dropped did nothing.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/dropped.go" <<'GO'
package main

import (
	"fmt"
	"maps"
	"slices"
)

func main() {
	stock := map[string]int{"bolt": 40, "nut": 12, "washer": 7}
	parts := maps.Keys(stock)
	slices.Sorted(parts)
	slices.Collect(parts)
	fmt.Println(len(stock))
}
GO

cat >"$dir/kept.go" <<'GO'
package main

import (
	"fmt"
	"maps"
	"slices"
)

func main() {
	stock := map[string]int{"bolt": 40, "nut": 12, "washer": 7}
	parts := slices.Sorted(maps.Keys(stock))
	fmt.Println(parts)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go vet dropped.go'
(cd "$dir" && go vet dropped.go) 2>&1
echo "exit status $?"

say 'go vet kept.go'
(cd "$dir" && go vet kept.go) 2>&1
echo "exit status $?"
