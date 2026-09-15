#!/usr/bin/env bash
# The race detector, on a counter that goroutines increment without a lock.
# Built without -race, the program exits 0 and says nothing. Built with -race,
# it prints a report and exits 66 -- on a run in which the race happens. The
# count, the addresses and the goroutine numbers change from run to run, so
# this script prints none of them: only exit statuses, whether a report
# appeared, and which lines of counter.go the report points at.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >counter.go <<'GO'
// Command counter counts orders with as many workers as its argument says,
// and no lock around the count.
package main

import (
	"fmt"
	"os"
	"strconv"
	"sync"
)

func main() {
	workers, err := strconv.Atoi(os.Args[1])
	if err != nil {
		panic(err)
	}
	orders := 0
	var wg sync.WaitGroup
	for range workers {
		wg.Go(func() {
			for range 1000 {
				orders++ // read, add one, write back: no lock
			}
		})
	}
	wg.Wait()
	fmt.Println("orders:", orders)
}
GO

say() { printf '$ %s\n' "$*"; }

# The exit status in $1, and whether the last run's stderr held a race report.
verdict() {
	if grep -q '^WARNING: DATA RACE$' stderr.txt; then
		echo "exit status $1, race report: yes"
	else
		echo "exit status $1, race report: no"
	fi
}

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go build -o counter .'
go build -o counter . || exit 1

say './counter 2 >/dev/null'
./counter 2 >/dev/null 2>stderr.txt
verdict $?

# -race needs cgo, and on Linux a C compiler; without them this stops here.
say 'go build -race -o counter_race .'
go build -race -o counter_race . || exit 1

say './counter_race 1 >/dev/null'
./counter_race 1 >/dev/null 2>stderr.txt
verdict $?

say './counter_race 2 >/dev/null'
./counter_race 2 >/dev/null 2>stderr.txt
verdict $?

echo 'lines of counter.go the report points at:'
grep -o 'counter\.go:[0-9]*' stderr.txt | sort -u -t: -k2,2n | while IFS=: read -r file line; do
	printf '  %s:%s  %s\n' "$file" "$line" "$(sed -n "${line}s/^[[:space:]]*//p" counter.go)"
done

say 'GOMAXPROCS=1 ./counter_race 2 >/dev/null'
GOMAXPROCS=1 ./counter_race 2 >/dev/null 2>stderr.txt
verdict $?

say 'go run -race . 2 >/dev/null'
go run -race . 2 >/dev/null 2>stderr.txt
verdict $?
echo "go run's last line on stderr: $(tail -n 1 stderr.txt)"
