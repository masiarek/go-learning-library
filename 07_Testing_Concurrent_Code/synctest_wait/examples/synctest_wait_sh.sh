#!/usr/bin/env bash
# synctest.Wait blocks until every other goroutine in the bubble is durably
# blocked, so a test can ask "has the worker reacted yet?" and get the same
# answer on every run, with no sleep. The same test without the Wait is a data
# race, and go test -race fails it. Whether that version's own check fires
# depends on the scheduler, so this script does not print that line, and it
# drops the durations go test prints.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >worker_test.go <<'GO'
package example

import (
	"context"
	"testing"
	"testing/synctest"
)

// worker handles orders until ctx is cancelled.
func worker(ctx context.Context, orders <-chan int) {
	for {
		select {
		case <-orders:
		case <-ctx.Done():
			return
		}
	}
}

func TestWorkerStops(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		ctx, cancel := context.WithCancel(t.Context())
		orders := make(chan int)
		stopped := false
		go func() {
			worker(ctx, orders)
			stopped = true
		}()

		orders <- 1042
		synctest.Wait() // returns once the worker is blocked in its select again
		t.Log("after an order: stopped =", stopped)
		if stopped {
			t.Fatal("the worker stopped before it was cancelled")
		}

		cancel()
		synctest.Wait() // returns once the worker's goroutine has ended
		t.Log("after cancel:   stopped =", stopped)
		if !stopped {
			t.Fatal("cancel did not stop the worker")
		}
	})
}

func TestWorkerStopsWithoutWait(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		ctx, cancel := context.WithCancel(t.Context())
		orders := make(chan int)
		stopped := false
		go func() {
			worker(ctx, orders)
			stopped = true
		}()

		orders <- 1042
		cancel()
		if !stopped { // races with the write above: nothing says which runs first
			t.Error("the worker has not stopped yet")
		}
	})
}
GO

say() { printf '$ %s\n' "$*"; }

# Print go test's output without what varies: "(0.00s)" after a test's name,
# the time after "ok  example" or "FAIL  example", and testing.go's line number.
tidy() {
	sed -E 's/ \([0-9.]+s\)$//; s/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/; s/testing\.go:[0-9]+:/testing.go:/' test.txt
}

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

# -race needs cgo, and on Linux a C compiler. Stop, rather than print a key
# in which go test failed to build.
if [ "$(go env CGO_ENABLED)" != 1 ]; then
	echo 'go test -race needs cgo (and on Linux a C compiler); CGO_ENABLED is not 1' >&2
	exit 1
fi

say "go test -v -count=1 -run 'TestWorkerStops\$'"
go test -v -count=1 -run 'TestWorkerStops$' >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

say "go test -race -count=1 -run 'TestWorkerStops\$'"
go test -race -count=1 -run 'TestWorkerStops$' >test.txt 2>&1
status=$?
tidy
echo "exit status $status"

say 'go test -race -count=1 -run TestWorkerStopsWithoutWait'
go test -race -count=1 -run TestWorkerStopsWithoutWait >test.txt 2>&1
status=$?
if grep -q '^WARNING: DATA RACE$' test.txt; then
	echo 'race report: yes'
else
	echo 'race report: no'
fi
tidy | grep -E '^(--- |ok|FAIL|PASS)|race detected'
echo "exit status $status"
