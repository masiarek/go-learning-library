#!/usr/bin/env bash
# What no tool in the distribution catches: `defer rows.Close()` written
# before the error from Query is checked. When Query fails, rows is nil and
# the deferred Close dereferences it as the function returns. vet is silent;
# the program panics. The connector stands in for a database that is down.
# The panic's second stderr line names a signal and an address that vary, so
# only the panic line and the frame that panicked are kept.
set -u
export GOTOOLCHAIN=local

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

cat >"$dir/close_before_check.go" <<'GO'
package main

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"errors"
	"fmt"
)

// downConnector fails every connection attempt, as a database that is down would.
type downConnector struct{}

func (downConnector) Connect(context.Context) (driver.Conn, error) {
	return nil, errors.New("database is down")
}

func (downConnector) Driver() driver.Driver { return nil }

func countOrders(db *sql.DB) (int, error) {
	rows, err := db.Query("SELECT COUNT(*) FROM orders")
	defer rows.Close() // rows is nil whenever err is not
	if err != nil {
		return 0, err
	}
	var n int
	for rows.Next() {
		if err := rows.Scan(&n); err != nil {
			return 0, err
		}
	}
	return n, rows.Err()
}

func main() {
	db := sql.OpenDB(downConnector{})
	fmt.Println("counting orders on a database that is down")
	n, err := countOrders(db)
	fmt.Println(n, err)
}
GO

say() { printf '$ %s\n' "$*"; }
cd "$dir" || exit 1

say 'go vet close_before_check.go'
go vet close_before_check.go 2>&1
echo "exit status $?"

say 'go build close_before_check.go'
go build close_before_check.go || exit 1
say './close_before_check'
./close_before_check 2>stderr.txt
status=$?
grep '^panic:' stderr.txt
grep -o 'database/sql\.(\*Rows)\.Close' stderr.txt | head -n 1 | sed 's/^/deferred call that panicked: /'
echo "exit status $status"
