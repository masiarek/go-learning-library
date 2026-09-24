#!/usr/bin/env bash
# The buildtag analyzer: a //go:build line after the package clause or
# inside a block comment is misplaced, and an old // +build line that says
# something else than the //go:build line above it is a mismatch. A line
# with a space, // go:build, is none of these to vet: it is an ordinary
# comment, and go list shows the file compiled into every build.
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
say 'go vet .   # //go:build after the package clause'
go vet . 2>&1
echo "exit status $?"

cat >pricing_fast.go <<'GO'
/*
//go:build fast
*/

package main

func pricing() string { return "fast" }
GO
say 'go vet .   # //go:build inside a block comment'
go vet . 2>&1
echo "exit status $?"

cat >pricing_fast.go <<'GO'
//go:build fast
// +build slow

package main

func pricing() string { return "fast" }
GO
say 'go vet .   # the old +build line disagrees'
go vet . 2>&1
echo "exit status $?"

cat >pricing_fast.go <<'GO'
// go:build fast

package main

func pricing() string { return "fast" }
GO
say 'go vet .   # a space after //'
go vet . 2>&1
echo "exit status $?"
say "go list -f '{{.GoFiles}}' ."
go list -f '{{.GoFiles}}' .

cat >pricing_fast.go <<'GO'
//go:build fast

package main

func pricing() string { return "fast" }
GO
say 'go vet .   # the good version'
go vet . 2>&1
echo "exit status $?"
say "go list -f '{{.GoFiles}}' ."
go list -f '{{.GoFiles}}' .
