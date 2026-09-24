#!/usr/bin/env bash
# lostcancel: a context.WithCancel whose cancel function is not called on
# every path. The early return leaks the context; `defer cancel()` right
# after the WithCancel is the version vet accepts.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/lost.go" <<'GO'
package main

import (
	"context"
	"fmt"
)

func fetchOrder(ctx context.Context, id int) error {
	ctx, cancel := context.WithCancel(ctx)
	if id < 0 {
		return fmt.Errorf("bad order id %d", id)
	}
	fmt.Println("fetching order", id, "with", ctx.Err())
	cancel()
	return nil
}

func main() { fmt.Println(fetchOrder(context.Background(), 18)) }
GO

cat >"$dir/kept.go" <<'GO'
package main

import (
	"context"
	"fmt"
)

func fetchOrder(ctx context.Context, id int) error {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	if id < 0 {
		return fmt.Errorf("bad order id %d", id)
	}
	fmt.Println("fetching order", id, "with", ctx.Err())
	return nil
}

func main() { fmt.Println(fetchOrder(context.Background(), 18)) }
GO

say() { printf '$ %s\n' "$*"; }
cd "$dir" || exit 1

say 'go vet lost.go'
go vet lost.go 2>&1
echo "exit status $?"

say 'go vet kept.go'
go vet kept.go 2>&1
echo "exit status $?"
