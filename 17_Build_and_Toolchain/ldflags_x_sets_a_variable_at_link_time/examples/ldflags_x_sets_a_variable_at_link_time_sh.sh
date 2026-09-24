#!/usr/bin/env bash
# -X sets a package-level string variable at link time, so one source tree
# gives a binary that knows its version. It reaches only a string that is
# uninitialised or initialised with a constant: an int is refused, a computed
# initialiser keeps its own value without a word, and a name that does not
# exist is ignored without a word. The binary records the flag it was built
# with, and -s -w makes it smaller.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

go mod init example >/dev/null 2>&1 || exit 1

cat >main.go <<'GO'
package main

import (
	"fmt"
	"runtime/debug"
	"strings"
)

const defaultVersion = "0.0.0"

var (
	version   = "dev"                     // -X main.version=... replaces this
	commit    string                      // uninitialised: -X reaches it too
	channel   = strings.ToLower("STABLE") // computed at run time: -X cannot
	fromConst = defaultVersion            // a constant initialiser: -X can
	build     = 0                         // not a string: the linker refuses
)

func main() {
	fmt.Printf("version=%q commit=%q channel=%q fromConst=%q build=%d\n", version, commit, channel, fromConst, build)
	if info, ok := debug.ReadBuildInfo(); ok {
		for _, s := range info.Settings {
			if s.Key == "-ldflags" {
				fmt.Printf("recorded in the binary: %s=%s\n", s.Key, s.Value)
			}
		}
	}
}
GO

say 'gofmt -l .'
gofmt -l .

say 'go build -o release . && ./release'
go build -o release . && ./release

say 'go build -ldflags "-X main.version=1.4.2 -X main.commit=9f3a1c0 -X main.channel=beta -X main.fromConst=2.0" -o release . && ./release'
go build -ldflags "-X main.version=1.4.2 -X main.commit=9f3a1c0 -X main.channel=beta -X main.fromConst=2.0" -o release . && ./release

say 'go build -ldflags "-X main.build=7" -o release .'
go build -ldflags "-X main.build=7" -o release . 2>&1
echo "exit status $?"

say 'go build -ldflags "-X main.nosuch=1" -o release . && ./release'
go build -ldflags "-X main.nosuch=1" -o release . 2>&1 && ./release
echo "exit status $?"

say 'go build -ldflags "-s -w -X main.version=1.4.2" -o stripped . && ./stripped'
go build -ldflags "-s -w -X main.version=1.4.2" -o stripped . && ./stripped
if [ "$(wc -c <stripped)" -lt "$(wc -c <release)" ]; then
	echo "stripped is smaller: yes"
else
	echo "stripped is smaller: no"
fi

say 'go version -m stripped | grep ldflags'
go version -m stripped | grep ldflags
