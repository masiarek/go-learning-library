// Benchmarks behind the "Real runs" fence: the same work as the lesson's
// program, with ns/op and B/op that the answer key never records.
//
//	bash bench.sh       (copies this file into a throwaway module and runs it)
package demo

import (
	"encoding/json"
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

var (
	orderCount     = 1000
	invoice        = Invoice{Number: "INV-1001", Customer: "Ada Lovelace", Amount: 1250.5, Paid: true}
	boxedInt   any = orderCount
	sinkAny    any
	sinkKind   reflect.Kind
	sinkBytes  []byte
	sinkInt    int
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

func BenchmarkTypeSwitch(b *testing.B) {
	for b.Loop() {
		sinkKind = kindBySwitch(boxedInt)
	}
}

func BenchmarkReflectKind(b *testing.B) {
	for b.Loop() {
		sinkKind = reflect.ValueOf(boxedInt).Kind()
	}
}

func BenchmarkFieldInterfaceCopy(b *testing.B) {
	for b.Loop() {
		sinkAny = reflect.ValueOf(&invoice).Elem().Field(0).Interface()
	}
}

func BenchmarkJSONMarshal(b *testing.B) {
	for b.Loop() {
		sinkBytes, _ = json.Marshal(&invoice)
	}
}

func BenchmarkAppendInvoice(b *testing.B) {
	buf := make([]byte, 0, 128)
	for b.Loop() {
		sinkBytes = appendInvoice(buf[:0], invoice)
	}
}

func BenchmarkSelectStatement(b *testing.B) {
	x, y := make(chan int, 1), make(chan int, 1)
	for b.Loop() {
		x <- 1
		select {
		case v := <-x:
			sinkInt = v
		case v := <-y:
			sinkInt = v
		}
	}
}

func BenchmarkReflectSelect(b *testing.B) {
	x, y := make(chan int, 1), make(chan int, 1)
	cases := []reflect.SelectCase{{Dir: reflect.SelectRecv, Chan: reflect.ValueOf(x)}, {Dir: reflect.SelectRecv, Chan: reflect.ValueOf(y)}}
	for b.Loop() {
		x <- 1
		_, v, _ := reflect.Select(cases)
		sinkInt = int(v.Int())
	}
}
