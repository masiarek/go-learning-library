// Kata: an invoice loader whose named error is shaped by two deferred
// closures. The one deferred last runs first and turns a panic from a helper
// into an error that wraps a sentinel; the one deferred first runs last and
// adds the invoice's name to any error on the way out.
package main

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
)

var errBadLine = errors.New("bad line")

func mustParse(line string) (item string, cents int) {
	item, price, ok := strings.Cut(line, ",")
	if !ok {
		panic(fmt.Errorf("%w: %q", errBadLine, line))
	}
	cents, err := strconv.Atoi(price)
	if err != nil {
		panic(fmt.Errorf("%w: %q", errBadLine, line))
	}
	return item, cents
}

func loadInvoice(name string, lines []string) (total int, err error) {
	defer func() {
		if err != nil {
			err = fmt.Errorf("loading %s: %w", name, err)
		}
	}()
	defer func() {
		if r := recover(); r != nil {
			total = 0
			if e, ok := r.(error); ok {
				err = e
			} else {
				err = fmt.Errorf("%v", r)
			}
		}
	}()
	for _, line := range lines {
		_, cents := mustParse(line)
		total += cents
	}
	return total, nil
}

func main() {
	good := []string{"widget,1999", "shipping,450"}
	bad := []string{"widget,1999", "shipping 450"}
	for _, inv := range []struct {
		name  string
		lines []string
	}{{"INV-18", good}, {"INV-19", bad}} {
		total, err := loadInvoice(inv.name, inv.lines)
		fmt.Printf("%s: total = %d, err = %v, errors.Is(errBadLine) = %t\n", inv.name, total, err, errors.Is(err, errBadLine))
	}
}
