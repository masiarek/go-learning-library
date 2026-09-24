#!/usr/bin/env bash
# The unabridged -m=2 report for the file in
# examples/the_compiler_says_what_it_inlines_sh.sh: every inlining line with
# its cost and, for the functions the compiler can inline, the body it would
# paste. The costs are what the key blanks out.
#
#   bash demo/inline_full.sh          # from the lesson folder
set -u
cd "$(dirname "$0")" || exit 1
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

sed -n "/^cat >main.go <<'GO'\$/,/^GO\$/p" ../examples/the_compiler_says_what_it_inlines_sh.sh | sed '1d;$d' >"$dir/main.go"
cd "$dir" && go mod init example >/dev/null 2>&1 || exit 1
echo '$ go version'
go version
echo '$ go build -gcflags=-m=2 . 2>&1 | grep inlin'
go build -gcflags=-m=2 . 2>&1 | grep inlin
