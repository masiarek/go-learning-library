// Kata: a Wallet has Deposit and Balance. Choose the receivers so that
// Deposit changes the wallet it is called on, put three wallets in a slice,
// deposit into each by index, print the total, and show with reflect which
// of Wallet and *Wallet has both methods and so satisfies Depositor.
//
//	go build a_pointer_receiver_changes_the_method_set_kata_go.go && ./a_pointer_receiver_changes_the_method_set_kata_go
package main

import (
	"fmt"
	"reflect"
)

type Wallet struct{ cents int }

// Deposit changes the wallet, so its receiver is a pointer.
func (w *Wallet) Deposit(cents int) { w.cents += cents }

// Balance only reads, so a value receiver is enough and both types get it.
func (w Wallet) Balance() int { return w.cents }

type Depositor interface {
	Deposit(cents int)
	Balance() int
}

func names(t reflect.Type) []string {
	out := make([]string, 0, t.NumMethod())
	for i := range t.NumMethod() {
		out = append(out, t.Method(i).Name)
	}
	return out
}

func main() {
	wallets := []Wallet{{100}, {50}, {0}}
	deposits := []int{20, 30, 50}
	for i, d := range deposits {
		wallets[i].Deposit(d) // wallets[i] is addressable: (&wallets[i]).Deposit(d)
	}
	total := 0
	for _, w := range wallets { // w is a copy; Balance reads it, nothing writes it
		total += w.Balance()
	}
	fmt.Println("balances after deposits:", wallets)
	fmt.Println("total:", total)

	fmt.Println("methods of Wallet: ", names(reflect.TypeOf(Wallet{})))
	fmt.Println("methods of *Wallet:", names(reflect.TypeOf(&Wallet{})))
	_, valueOK := any(Wallet{}).(Depositor)
	_, pointerOK := any(&Wallet{}).(Depositor)
	fmt.Println("Wallet satisfies Depositor:", valueOK, "; *Wallet satisfies Depositor:", pointerOK)
}
