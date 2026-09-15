#!/usr/bin/env bash
# go vet's lostcancel check. A CancelFunc that is thrown away, or called on only
# some of the paths out of a function, is reported, and vet exits 1. The same
# two functions with `defer cancel()` straight after each context is made pass.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

say() { printf '$ %s\n' "$*"; }

# vet names the package on lines that start with #; its findings are the rest.
vet() {
    go vet . 2>"$dir/vet.txt"
    local status=$?
    grep -v '^#' "$dir/vet.txt"
    echo "exit status $status"
}

cd "$dir" || exit 1
go mod init example 2>/dev/null

cat >quote.go <<'GO'
package main

import (
	"context"
	"errors"
	"time"
)

func quoteDiscarded(parent context.Context) error {
	ctx, _ := context.WithTimeout(parent, time.Minute)
	return ctx.Err()
}

func quoteOnePath(parent context.Context, supplier string) error {
	ctx, cancel := context.WithCancel(parent)
	if supplier == "" {
		return errors.New("no supplier")
	}
	defer cancel()
	return ctx.Err()
}

func main() {
	_ = quoteDiscarded(context.Background())
	_ = quoteOnePath(context.Background(), "acme")
}
GO

say 'go vet .'
vet

cat >quote.go <<'GO'
package main

import (
	"context"
	"errors"
	"time"
)

func quoteDiscarded(parent context.Context) error {
	ctx, cancel := context.WithTimeout(parent, time.Minute)
	defer cancel()
	return ctx.Err()
}

func quoteOnePath(parent context.Context, supplier string) error {
	ctx, cancel := context.WithCancel(parent)
	defer cancel()
	if supplier == "" {
		return errors.New("no supplier")
	}
	return ctx.Err()
}

func main() {
	_ = quoteDiscarded(context.Background())
	_ = quoteOnePath(context.Background(), "acme")
}
GO

say 'go vet .    # after moving defer cancel() to the line after each context.With...'
vet
