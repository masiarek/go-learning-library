#!/usr/bin/env bash
# A CPU profile names the function the time went to. The program below sums a
# million readings four hundred times in `hot` and once in `cold`, writing a
# profile with runtime/pprof; `go tool pprof -top` then lists functions by the
# time sampled in them. Every number in that table changes from run to run, so
# this script prints only what does not: the two header lines that name the
# binary and the profile type, and which function sits in the top row. The
# whole table is in demo/profile_full.sh.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1

cat >main.go <<'GO'
package main

import (
	"fmt"
	"os"
	"runtime/pprof"
)

var readings = make([]int64, 1<<20)

// hot does almost all the work. go:noinline keeps it a function of its own in
// the profile rather than a line inside main.
//
//go:noinline
func hot(rounds int) int64 {
	var total int64
	for range rounds {
		for _, r := range readings {
			total += r
		}
	}
	return total
}

//go:noinline
func cold() int64 {
	var total int64
	for _, r := range readings {
		total += r % 7
	}
	return total
}

func main() {
	for i := range readings {
		readings[i] = int64(i % 97)
	}
	f, err := os.Create("cpu.prof")
	if err != nil {
		panic(err)
	}
	if err := pprof.StartCPUProfile(f); err != nil {
		panic(err)
	}
	total := hot(400) + cold()
	pprof.StopCPUProfile()
	f.Close()
	fmt.Println("total is not zero:", total != 0)
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example >/dev/null 2>&1 || exit 1

say 'go build -o sumreadings .'
go build -o sumreadings . || exit 1

say './sumreadings'
./sumreadings
echo "exit status $?"

say 'go tool pprof -top -nodecount=5 ./sumreadings cpu.prof >top.txt'
go tool pprof -top -nodecount=5 ./sumreadings cpu.prof >top.txt 2>&1
echo "exit status $?"

# The header: File and Type are fixed; Time, Duration and the sample totals
# are not, and Linux adds a Build ID line that macOS does not.
say "grep -E '^(File|Type):' top.txt"
grep -E '^(File|Type):' top.txt

# The table: the function in the first row after the column headings, and
# whether main.hot is among the five rows at all.
first='header { print "top row: " $NF; exit } /^ *flat +flat%/ { header = 1 }'
say "awk '$first' top.txt"
awk "$first" top.txt

say "grep -c ' main\\.hot\$' top.txt"
if [ "$(grep -c ' main\.hot$' top.txt)" -ge 1 ]; then
	echo "main.hot in the top 5: yes"
else
	echo "main.hot in the top 5: no"
fi
