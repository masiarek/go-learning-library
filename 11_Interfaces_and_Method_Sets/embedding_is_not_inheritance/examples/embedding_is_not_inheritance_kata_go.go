// Kata: write descending(s sort.Interface) sort.Interface the way the standard
// library writes sort.Reverse -- a struct that embeds the given sort.Interface
// and overrides Less only -- and use it to sort invoices largest first.
// Print the result and confirm it with sort.IsSorted.
//
//	go build embedding_is_not_inheritance_kata_go.go && ./embedding_is_not_inheritance_kata_go
package main

import (
	"fmt"
	"sort"
)

type Invoice struct {
	ID     string
	Amount int
}

// byAmount sorts invoices by amount, smallest first.
type byAmount []Invoice

func (b byAmount) Len() int           { return len(b) }
func (b byAmount) Less(i, j int) bool { return b[i].Amount < b[j].Amount }
func (b byAmount) Swap(i, j int)      { b[i], b[j] = b[j], b[i] }

// reversed embeds a sort.Interface: Len and Swap are promoted from it, and
// only Less is written here. Its Less calls the embedded Less with the
// indexes swapped -- it has to name it, r.Interface.Less, because a plain
// r.Less would be this method calling itself.
type reversed struct{ sort.Interface }

func (r reversed) Less(i, j int) bool { return r.Interface.Less(j, i) }

func descending(s sort.Interface) sort.Interface { return reversed{s} }

func main() {
	invoices := byAmount{{"INV-1", 120}, {"INV-2", 250}, {"INV-3", 75}, {"INV-4", 300}}
	sort.Sort(invoices)
	fmt.Println("ascending: ", invoices)
	sort.Sort(descending(invoices))
	fmt.Println("descending:", invoices)
	fmt.Println("sort.IsSorted(descending(invoices)):", sort.IsSorted(descending(invoices)))
	fmt.Println("sort.IsSorted(invoices):            ", sort.IsSorted(invoices))
}
