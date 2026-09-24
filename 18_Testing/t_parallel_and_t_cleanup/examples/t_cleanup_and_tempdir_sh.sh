#!/usr/bin/env bash
# t.Cleanup functions run after the test and its subtests, last registered
# first. t.TempDir is removed by one of them, so it still exists inside a
# Cleanup and is gone by the next test. t.Context is cancelled just before
# the Cleanup functions run. None of this depends on timing, so the whole
# -v transcript is the key, minus the durations.
set -u

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cd "$dir" || exit 1
export GOTOOLCHAIN=local

cat >warehouse_test.go <<'GO'
package warehouse

import (
	"os"
	"path/filepath"
	"testing"
)

func TestCleanupOrder(t *testing.T) {
	t.Cleanup(func() { t.Log("cleanup 1: registered first, runs last") })
	t.Cleanup(func() { t.Log("cleanup 2: registered second") })
	t.Run("child", func(t *testing.T) {
		t.Cleanup(func() { t.Log("child's cleanup") })
		t.Log("child's body")
	})
	t.Log("parent's body ends")
}

var manifestDir string

func TestTempDir(t *testing.T) {
	dir := t.TempDir()
	manifest := filepath.Join(dir, "manifest.csv")
	if err := os.WriteFile(manifest, []byte("WH-1,12\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, err := os.Stat(dir)
		t.Log("in Cleanup, the TempDir still exists:", err == nil)
	})
	manifestDir = dir
}

func TestTempDirIsGone(t *testing.T) {
	_, err := os.Stat(manifestDir)
	t.Log("after TestTempDir, its directory exists:", err == nil)
}

func TestContextEndsBeforeCleanup(t *testing.T) {
	ctx := t.Context()
	t.Cleanup(func() { t.Log("in Cleanup, ctx.Err() =", ctx.Err()) })
	t.Log("in the body, ctx.Err() =", ctx.Err())
}
GO

say() { printf '$ %s\n' "$*"; }

tidy() {
	sed -E 's/ \([0-9.]+s\)$//; s/^(ok|FAIL)([[:space:]]+example)[[:space:]]+[0-9.]+s$/\1\2/' test.txt
}

say 'go mod init example'
go mod init example 2>/dev/null || exit 1

say 'go test -v'
go test -v >test.txt 2>&1
status=$?
tidy
echo "exit status $status"
