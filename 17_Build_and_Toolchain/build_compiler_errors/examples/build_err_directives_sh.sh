#!/usr/bin/env bash
# A //go:build line after the package clause, two of them, or one whose
# expression does not parse: the first is a compiler error, the other two
# are refused by the go command while it decides which files to build.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

go mod init example >/dev/null 2>&1 || exit 1

cat >main.go <<'GO'
package main

func main() {}
GO

cat >pricing_fast.go <<'GO'
package main

//go:build fast

func pricing() string { return "fast" }
GO
say 'go build -o report .   # //go:build after the package clause'
go build -o report . 2>&1
echo "exit status $?"

cat >pricing_fast.go <<'GO'
//go:build fast
//go:build !debug

package main

func pricing() string { return "fast" }
GO
say 'go build -o report .   # two //go:build lines'
go build -o report . 2>&1
echo "exit status $?"

cat >pricing_fast.go <<'GO'
//go:build fast &&

package main

func pricing() string { return "fast" }
GO
say 'go build -o report .   # an expression that does not parse'
go build -o report . 2>&1
echo "exit status $?"

cat >pricing_fast.go <<'GO'
//go:build fast && !debug

package main

func pricing() string { return "fast" }
GO
say 'go build -o report .'
go build -o report . 2>&1
echo "exit status $?"
