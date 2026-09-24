// Kata: the mechanism behind an Example test, by hand. checkExample runs a
// function with os.Stdout redirected to a pipe, reads back what it printed,
// trims the surrounding space and compares it with the expected text -- and
// for an unordered example compares the sorted lines instead. A mismatch is
// reported as got/want, the way go test reports it.
//
//	go build an_example_test_checks_its_output_kata_go.go && ./an_example_test_checks_its_output_kata_go
package main

import (
	"fmt"
	"io"
	"os"
	"sort"
	"strings"
)

type invoice struct{ lines map[string]int }

func (inv invoice) printLines() {
	for item, cents := range inv.lines {
		fmt.Printf("%s %d\n", item, cents)
	}
}

func (inv invoice) total() int {
	sum := 0
	for _, cents := range inv.lines {
		sum += cents
	}
	return sum
}

// capture returns what run printed to os.Stdout.
func capture(run func()) string {
	saved := os.Stdout
	r, w, err := os.Pipe()
	if err != nil {
		panic(err)
	}
	os.Stdout = w
	run()
	w.Close()
	os.Stdout = saved
	printed, _ := io.ReadAll(r)
	return string(printed)
}

func sortedLines(s string) string {
	lines := strings.Split(s, "\n")
	sort.Strings(lines)
	return strings.Join(lines, "\n")
}

func checkExample(name string, run func(), want string, unordered bool) {
	got := strings.TrimSpace(capture(run))
	want = strings.TrimSpace(want)
	if unordered {
		got, want = sortedLines(got), sortedLines(want)
	}
	if got == want {
		fmt.Printf("--- PASS: %s\n", name)
		return
	}
	fmt.Printf("--- FAIL: %s\ngot:\n%s\nwant:\n%s\n", name, got, want)
}

func main() {
	inv := invoice{lines: map[string]int{"crates": 2500, "pallet": 9900, "delivery": 1500}}
	checkExample("ExampleInvoice_total", func() { fmt.Println(inv.total()) }, "13900", false)
	checkExample("ExampleInvoice_total_wrong", func() { fmt.Println(inv.total()) }, "13000", false)
	checkExample("ExampleInvoice_printLines", inv.printLines, "pallet 9900\ncrates 2500\ndelivery 1500\n", true)
}
