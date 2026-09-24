#!/usr/bin/env bash
# Subtests that call t.Parallel pause until the parent's function has
# returned, then run together, up to -parallel of them at once. The order in
# which they resume changes from run to run, so this script prints the lines
# up to the parent's last log line verbatim, then counts and sorts the rest.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >warehouse_test.go <<'GO'
package warehouse

import (
	"sync"
	"sync/atomic"
	"testing"
)

// running counts subtests inside their body; peak is the most seen at once.
var running, peak atomic.Int32

func enter() {
	n := running.Add(1)
	for {
		p := peak.Load()
		if n <= p || peak.CompareAndSwap(p, n) {
			return
		}
	}
}

func leave() { running.Add(-1) }

var names = []string{"north", "south", "east", "west"}

// The four subtests wait for each other at a barrier, so this test can only
// pass when all four are running at the same time: go test -parallel 4.
func TestWarehousesTogether(t *testing.T) {
	var allStarted sync.WaitGroup
	allStarted.Add(len(names))
	for _, name := range names {
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			enter()
			defer leave()
			allStarted.Done()
			allStarted.Wait() // returns only once all four subtests are running
			t.Log("checking", name)
		})
	}
	t.Log("parent: the loop is done; subtests running right now:", running.Load())
	t.Cleanup(func() { t.Log("parent's Cleanup: most subtests running at once:", peak.Load()) })
}

// No barrier: under -parallel 1 the subtests still pause and resume, one
// at a time.
func TestWarehousesOneAtATime(t *testing.T) {
	peak.Store(0)
	for _, name := range names {
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			enter()
			defer leave()
			t.Log("checking", name)
		})
	}
	t.Cleanup(func() { t.Log("parent's Cleanup: most subtests running at once:", peak.Load()) })
}
GO

say() { printf '$ %s\n' "$*"; }

# The transcript, with what varies between runs made fixed: the lines up to
# the parent's log line are in a fixed order; after it the subtests resume in
# any order, so those lines are counted or sorted.
report() {
	sed -n '1,/parent: the loop/p' test.txt
	echo "=== CONT lines: $(grep -c '^=== CONT' test.txt)"
	grep 'checking' test.txt | sort
	grep "parent's Cleanup" test.txt
	grep -E '^ *--- ' test.txt | sed -E 's/ \([0-9.]+s\)$//' | sort
	tail -n 2 test.txt | sed -E 's/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/'
}

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say "go test -v -parallel 4 -run 'TestWarehousesTogether$'"
go test -v -parallel 4 -run 'TestWarehousesTogether$' >test.txt 2>&1
status=$?
report
echo "exit status $status"

say "go test -v -parallel 1 -run 'TestWarehousesOneAtATime$'"
go test -v -parallel 1 -run 'TestWarehousesOneAtATime$' >test.txt 2>&1
status=$?
echo "=== PAUSE lines: $(grep -c '^=== PAUSE' test.txt)"
echo "=== CONT lines: $(grep -c '^=== CONT' test.txt)"
grep "parent's Cleanup" test.txt
tail -n 2 test.txt | sed -E 's/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/'
echo "exit status $status"

say "go test -v -cpu 1,2 -run 'TestWarehousesOneAtATime$'"
go test -v -cpu 1,2 -run 'TestWarehousesOneAtATime$' >test.txt 2>&1
status=$?
echo "the test ran $(grep -c '^--- PASS: TestWarehousesOneAtATime' test.txt) times, under the name $(grep '^--- PASS' test.txt | cut -d' ' -f3 | sort -u | tr '\n' ' ' | sed 's/ $//')"
echo "exit status $status"
