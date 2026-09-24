#!/usr/bin/env bash
# The pkg/errors habit. The standard errors package has no Wrap and no Cause;
# since Go 1.13 the wrap is fmt.Errorf with %w and the walk is errors.Is,
# errors.As and errors.Unwrap.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/pkg_errors_habit.go" <<'GO'
package main

import (
	"errors"
	"fmt"
	"os"
)

func main() {
	_, err := os.Open("orders.csv")
	if err != nil {
		fmt.Println(errors.Wrap(err, "load orders"))
		fmt.Println(errors.Cause(err))
	}
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go build pkg_errors_habit.go'
(cd "$dir" && go build pkg_errors_habit.go) 2>&1
echo "exit status $?"
