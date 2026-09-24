#!/usr/bin/env bash
# Inside a git checkout, go build stamps the commit into the binary: the same
# source built in a repository and outside one gives different bytes, and a
# tree with uncommitted changes is recorded as vcs.modified=true. With
# -buildvcs=false the bytes match the build outside git again. The revision
# and the commit time are never printed here, only the keys.
set -u
export GOTOOLCHAIN=local

plain=$(mktemp -d)
repo=$(mktemp -d)
trap 'rm -rf "$plain" "$repo"' EXIT

say() { printf '$ %s\n' "$*"; }
same() { if cmp -s "$1" "$2"; then echo "identical: yes"; else echo "identical: no"; fi; }

for dir in "$plain" "$repo"; do
	(cd "$dir" && go mod init example >/dev/null 2>&1) || exit 1
	cat >"$dir/main.go" <<'GO'
package main

import "fmt"

func main() {
	fmt.Println("invoice printer")
}
GO
done
(cd "$plain" && go build -trimpath -o outside .) || exit 1

cd "$repo" || exit 1
say 'git init && git add . && git commit -m "invoice printer"'
git -c init.defaultBranch=main init -q . && git add . && git -c user.name=ci -c user.email=ci@example.com commit -q -m "invoice printer"

say 'go build -trimpath -o stamped . && cmp "$plain/outside" stamped'
go build -trimpath -o stamped . && same "$plain/outside" stamped

say 'go version -m stamped | grep vcs'
go version -m stamped | awk '$1 == "build" && $2 ~ /^vcs/ { split($2, kv, "="); if (kv[1] == "vcs" || kv[1] == "vcs.modified") print "\t" $1 "\t" $2; else print "\t" $1 "\t" kv[1] "=..." }'

say 'go build -trimpath -buildvcs=false -o unstamped . && cmp "$plain/outside" unstamped'
go build -trimpath -buildvcs=false -o unstamped . && same "$plain/outside" unstamped

say 'echo "// a change that is not committed" >>main.go && go build -trimpath -o dirty . && go version -m dirty | grep vcs.modified'
echo "// a change that is not committed" >>main.go && go build -trimpath -o dirty . && go version -m dirty | grep vcs.modified
