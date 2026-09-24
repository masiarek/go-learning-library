// Allocations per call, counted with testing.AllocsPerRun: a type switch
// against reflect.ValueOf(x).Kind(), Interface() round trips, and json.Marshal
// against hand-written formatting. Counts, never nanoseconds: the counts are
// the same on every machine running the same Go version.
//
//	go build reflection_costs_allocations_go.go && ./reflection_costs_allocations_go
package main

import (
	"encoding/json"
	"fmt"
	"reflect"
	"strconv"
	"testing"
)

type Invoice struct {
	Number   string  `json:"number"`
	Customer string  `json:"customer"`
	Amount   float64 `json:"amount"`
	Paid     bool    `json:"paid"`
}

// Package-level, so the compiler cannot fold them into constants.
var (
	orderCount = 1000
	invoice    = Invoice{Number: "INV-1001", Customer: "Ada Lovelace", Amount: 1250.5, Paid: true}

	sinkAny     any
	sinkKind    reflect.Kind
	sinkStr     string
	sinkBytes   []byte
	sinkInvoice Invoice
)

func kindBySwitch(x any) reflect.Kind {
	switch x.(type) {
	case int:
		return reflect.Int
	case string:
		return reflect.String
	case Invoice:
		return reflect.Struct
	}
	return reflect.Invalid
}

func appendInvoice(buf []byte, inv Invoice) []byte {
	buf = append(buf, `{"number":`...)
	buf = strconv.AppendQuote(buf, inv.Number)
	buf = append(buf, `,"customer":`...)
	buf = strconv.AppendQuote(buf, inv.Customer)
	buf = append(buf, `,"amount":`...)
	buf = strconv.AppendFloat(buf, inv.Amount, 'f', -1, 64)
	buf = append(buf, `,"paid":`...)
	buf = strconv.AppendBool(buf, inv.Paid)
	return append(buf, '}')
}

func main() {
	count := func(what string, f func()) {
		fmt.Printf("%-50s %v\n", what, testing.AllocsPerRun(100, f))
	}
	var boxedInt any = orderCount
	var boxedInvoice any = invoice
	buf := make([]byte, 0, 128)

	fmt.Println("allocations per call")
	count("box an int into any", func() { sinkAny = orderCount })
	count("box a 4-field struct into any", func() { sinkAny = invoice })
	count("type switch on the boxed int", func() { sinkKind = kindBySwitch(boxedInt) })
	count("reflect.ValueOf(boxed int).Kind()", func() { sinkKind = reflect.ValueOf(boxedInt).Kind() })
	count("reflect.ValueOf(int).Kind(), boxing inside", func() { sinkKind = reflect.ValueOf(orderCount).Kind() })
	count("reflect.TypeOf(boxed struct).Kind()", func() { sinkKind = reflect.TypeOf(boxedInvoice).Kind() })
	count("ValueOf(boxed int).Interface() round trip", func() { sinkAny = reflect.ValueOf(boxedInt).Interface() })
	count("ValueOf(boxed struct).Field(0).Interface()", func() { sinkAny = reflect.ValueOf(boxedInvoice).Field(0).Interface() })
	count("ValueOf(&invoice).Elem().Field(0).Interface()", func() { sinkAny = reflect.ValueOf(&invoice).Elem().Field(0).Interface() })
	count("ValueOf(&invoice).Elem().Field(0).String()", func() { sinkStr = reflect.ValueOf(&invoice).Elem().Field(0).String() })
	count("TypeAssert[string](same Field(0)), Go 1.25", func() { sinkStr, _ = reflect.TypeAssert[string](reflect.ValueOf(&invoice).Elem().Field(0)) })
	count("TypeAssert[Invoice](ValueOf(&invoice).Elem())", func() { sinkInvoice, _ = reflect.TypeAssert[Invoice](reflect.ValueOf(&invoice).Elem()) })
	count("ValueOf(&invoice).Elem().Interface().(Invoice)", func() { sinkInvoice = reflect.ValueOf(&invoice).Elem().Interface().(Invoice) })
	count("TypeOf(invoice).Field(0).Tag.Get(\"json\")", func() { sinkStr = reflect.TypeOf(invoice).Field(0).Tag.Get("json") })
	count("json.Marshal(invoice)", func() { sinkBytes, _ = json.Marshal(invoice) })
	count("json.Marshal(&invoice)", func() { sinkBytes, _ = json.Marshal(&invoice) })
	count("appendInvoice into a reused 128-byte buffer", func() { sinkBytes = appendInvoice(buf[:0], invoice) })
	count("appendInvoice into nil, growing as it goes", func() { sinkBytes = appendInvoice(nil, invoice) })
	count("fmt.Sprintf(\"%T\", invoice)", func() { sinkStr = fmt.Sprintf("%T", invoice) })
	count("reflect.TypeOf(invoice).String()", func() { sinkStr = reflect.TypeOf(invoice).String() })

	same := string(appendInvoice(nil, invoice)) == string(must(json.Marshal(invoice)))
	fmt.Println("hand-written and json.Marshal agree byte for byte:", same)
}

func must(b []byte, err error) []byte {
	if err != nil {
		panic(err)
	}
	return b
}
