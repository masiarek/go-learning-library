#!/usr/bin/env bash
# //go:embed applies only to a package-level var of type string, []byte or
# embed.FS, with no initialiser, in a file that imports embed. Each rule has
# its own compiler message.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

say() { printf '$ %s\n' "$*"; }

go mod init example >/dev/null 2>&1 || exit 1
printf '1.4.2\n' >VERSION

cat >main.go <<'GO'
package main

import (
	_ "embed"
	"fmt"
)

func main() {
	//go:embed VERSION
	var version string
	fmt.Println(version)
}
GO
say 'go build -o report .   # the var is inside a function'
go build -o report . 2>&1
echo "exit status $?"

cat >main.go <<'GO'
package main

import "fmt"

//go:embed VERSION
var version string

func main() { fmt.Println(version) }
GO
say 'go build -o report .   # nothing imports embed'
go build -o report . 2>&1
echo "exit status $?"

cat >main.go <<'GO'
package main

import (
	_ "embed"
	"fmt"
)

//go:embed VERSION
var version = "dev"

func main() { fmt.Println(version) }
GO
say 'go build -o report .   # the var has an initialiser'
go build -o report . 2>&1
echo "exit status $?"

cat >main.go <<'GO'
package main

import (
	_ "embed"
	"fmt"
)

//go:embed VERSION
var version int

func main() { fmt.Println(version) }
GO
say 'go build -o report .   # the var is an int'
go build -o report . 2>&1
echo "exit status $?"
