// Kata: a ledger receives entries as []any -- int cents, float64 dollars,
// string memos, nil placeholders, and Invoice values that are Stringers.
// Write tally with one type switch that adds up the money in cents, counts
// the memos and the nils, collects the Stringers' text, and print the totals.
//
//	go build type_switches_and_assertions_kata_go.go && ./type_switches_and_assertions_kata_go
package main

import (
	"fmt"
	"math"
	"strings"
)

type Invoice struct{ ID int }

func (i Invoice) String() string { return fmt.Sprintf("invoice %d", i.ID) }

type Tally struct {
	Cents    int
	Memos    int
	Nils     int
	Stringer []string
	Unknown  []string
}

func tally(entries []any) Tally {
	var t Tally
	for _, e := range entries {
		switch v := e.(type) {
		case nil:
			t.Nils++
		case int:
			t.Cents += v
		case float64:
			t.Cents += int(math.Round(v * 100))
		case string:
			t.Memos++
		case fmt.Stringer:
			t.Stringer = append(t.Stringer, v.String())
		default:
			t.Unknown = append(t.Unknown, fmt.Sprintf("%T", v))
		}
	}
	return t
}

func main() {
	entries := []any{250, 12.5, "paid by card", nil, Invoice{ID: 7}, 100, "refund", nil, Invoice{ID: 8}, 0.05, []int{1}}
	t := tally(entries)
	fmt.Printf("cents:     %d\n", t.Cents)
	fmt.Printf("memos:     %d\n", t.Memos)
	fmt.Printf("nils:      %d\n", t.Nils)
	fmt.Printf("stringers: %s\n", strings.Join(t.Stringer, ", "))
	fmt.Printf("unknown:   %s\n", strings.Join(t.Unknown, ", "))
}
