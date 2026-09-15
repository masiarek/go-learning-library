#!/usr/bin/env bash
# testing/synctest: inside a bubble, the time package reads a fake clock that
# moves only when every goroutine in the bubble is blocked. A test that waits
# out a one-hour timeout passes at once. go test prints how long each test and
# the whole run took, which varies, so this script removes those durations and
# prints a threshold instead.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >fetch_test.go <<'GO'
package example

import (
	"fmt"
	"testing"
	"testing/synctest"
	"time"
)

// fetch waits for a reply, and gives up after timeout.
func fetch(replies <-chan string, timeout time.Duration) (string, error) {
	select {
	case reply := <-replies:
		return reply, nil
	case <-time.After(timeout):
		return "", fmt.Errorf("no reply within %v", timeout)
	}
}

func TestSilentServerTimesOut(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		start := time.Now()
		t.Log("the bubble's clock starts at", start.UTC())

		replies := make(chan string) // nobody ever replies
		_, err := fetch(replies, time.Hour)
		if err == nil {
			t.Fatal("fetch returned without an error")
		}
		t.Logf("fetch returned %q after %v", err, time.Since(start))
	})
}

func TestSlowReplyBeatsTimeout(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		start := time.Now()
		replies := make(chan string)
		go func() {
			time.Sleep(30 * time.Minute)
			replies <- "order 1042 shipped"
		}()
		reply, err := fetch(replies, time.Hour)
		if err != nil {
			t.Fatal(err)
		}
		t.Logf("fetch returned %q after %v", reply, time.Since(start))
	})
}

func TestBusyWorkTakesNoTime(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		start := time.Now()
		total := 0
		for n := range 100_000_000 {
			total += n
		}
		t.Logf("adding up 100,000,000 numbers (total %d) took %v", total, time.Since(start))
	})
}
GO

say() { printf '$ %s\n' "$*"; }

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test -v -count=1'
go test -v -count=1 >test.txt 2>&1
status=$?
# Drop "(0.03s)" after each test's name and the time at the end of "ok  example".
sed -E 's/ \([0-9.]+s\)$//; s/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/' test.txt
echo "exit status $status"

# The time go test printed after "ok  example" is how long the test binary ran.
seconds=$(awk '$1 == "ok" { sub(/s$/, "", $3); print $3 }' test.txt)
awk -v s="$seconds" 'BEGIN { print "the test binary ran for under 10 s of wall time: " (s != "" && s + 0 < 10 ? "true" : "false") }'
