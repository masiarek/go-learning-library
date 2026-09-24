// Embedding a type promotes its fields and methods to the outer type, and that
// is all it does. A promoted method still runs with the inner value as its
// receiver, so Account.Describe calling a.Name() reaches Account.Name even
// when the outer Savings has a Name of its own: there is no virtual dispatch.
// Embedding an interface in a struct gives the struct the whole method set at
// compile time; a method the struct did not fill in is a nil-pointer panic at
// run time.
//
//	go build embedding_is_not_inheritance_go.go && ./embedding_is_not_inheritance_go
package main

import (
	"fmt"
	"reflect"
	"strconv"
	"strings"
)

type Account struct {
	Owner   string
	balance int
}

func (a Account) Name() string { return "account of " + a.Owner }

// Describe calls a.Name() -- and a is the Account, whatever embeds it.
func (a Account) Describe() string { return a.Name() + " holding " + strconv.Itoa(a.balance) }

func (a *Account) Deposit(cents int) { a.balance += cents }

// Savings embeds Account and gives Name a new meaning.
type Savings struct {
	Account
	Rate int
}

func (s Savings) Name() string { return "savings of " + s.Owner }

type Depositor interface{ Deposit(cents int) }

// Notifier is the interface a delivery service needs. LoudNotifier embeds it
// and fills in Notify only; Close is promoted from whatever is inside.
type Notifier interface {
	Notify(message string) string
	Close() error
}

type consoleNotifier struct{}

func (consoleNotifier) Notify(message string) string { return "console: " + message }
func (consoleNotifier) Close() error                 { return nil }

type LoudNotifier struct{ Notifier }

func (LoudNotifier) Notify(message string) string { return "LOUD: " + strings.ToUpper(message) }

func methods(t reflect.Type) string {
	names := make([]string, 0, t.NumMethod())
	for i := range t.NumMethod() {
		names = append(names, t.Method(i).Name)
	}
	return "[" + strings.Join(names, " ") + "]"
}

func panicOf(f func()) (value any) {
	defer func() { value = recover() }()
	f()
	return "none"
}

func main() {
	s := Savings{Account: Account{Owner: "Ann"}, Rate: 3}
	s.Deposit(100) // promoted pointer method: s.Account is addressable, so (&s.Account).Deposit(100)
	fmt.Println("s.Owner (promoted field) =", s.Owner, "; same variable as s.Account.Owner:", &s.Owner == &s.Account.Owner)
	fmt.Println("s.Name()         =", s.Name())
	fmt.Println("s.Describe()     =", s.Describe())
	fmt.Println("s.Account.Name() =", s.Account.Name())

	fmt.Println("method set of Savings: ", methods(reflect.TypeOf(s)))
	fmt.Println("method set of *Savings:", methods(reflect.TypeOf(&s)))
	_, valueOK := any(s).(Depositor)
	_, pointerOK := any(&s).(Depositor)
	fmt.Println("Savings is a Depositor:", valueOK, "; *Savings is a Depositor:", pointerOK)

	var n Notifier = LoudNotifier{consoleNotifier{}}
	fmt.Println("LoudNotifier over consoleNotifier: Notify ->", n.Notify("order 7 shipped"), "; Close() =", n.Close())

	n = LoudNotifier{} // the embedded Notifier is nil, and the compiler cannot tell
	fmt.Println("LoudNotifier over nothing:         Notify ->", n.Notify("order 8 shipped"))
	fmt.Println("LoudNotifier over nothing:         Close() panicked:", panicOf(func() { _ = n.Close() }))
}
