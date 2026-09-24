#!/usr/bin/env bash
# The directive analyzer: a //go:debug line is honoured only before the
# package clause of package main (or a test). Anywhere else the compiler
# accepts it as a comment and the setting is never applied; vet is the tool
# that says so.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

go mod init example >/dev/null 2>&1 || exit 1

cat >main.go <<'GO'
package main

//go:debug panicnil=1

func main() {}
GO
say 'go vet .   # //go:debug after the package clause'
go vet . 2>&1
echo "exit status $?"
say 'go build -o report .'
go build -o report . 2>&1
echo "exit status $?"

mkdir orders
cat >orders/orders.go <<'GO'
//go:debug panicnil=1

package orders

func Count() int { return 3 }
GO
say 'go vet ./orders   # //go:debug in a library package'
go vet ./orders 2>&1
echo "exit status $?"

cat >main.go <<'GO'
//go:debug panicnil=1

package main

func main() {}
GO
say 'go vet .   # the good version'
go vet . 2>&1
echo "exit status $?"
