// reflect reads a struct's field tags at run time: the same key:"value" strings
// that encoding/json reads to name the JSON keys. A Type says which type a
// value has; its Kind says only what shape that type is.
//
//	go build reflect_reads_struct_tags_go.go && ./reflect_reads_struct_tags_go
package main

import (
	"encoding/json"
	"fmt"
	"reflect"
	"strings"
)

// An Invoice as a JSON encoder and a validator see it: through its tags.
type Invoice struct {
	Number   string  `json:"number" validate:"required"`
	Customer string  `json:"customer,omitempty" validate:"required"`
	Amount   float64 `json:"amount"`
	Note     string  `json:"-"`
	draft    bool    // unexported: no tag, and json.Marshal never sees it
}

// A ledger with no exported fields at all.
type ledger struct {
	balance int
	owner   string
}

// Celsius is its own type; its kind is float64.
type Celsius float64

func main() {
	t := reflect.TypeOf(Invoice{})
	fmt.Printf("%s has %d fields:\n", t, t.NumField())
	for i := range t.NumField() {
		f := t.Field(i)
		rule, tagged := f.Tag.Lookup("validate")
		fmt.Printf("  %-8s exported %-5t json=%-21q validate=%q (tag present %t)\n",
			f.Name, f.IsExported(), f.Tag.Get("json"), rule, tagged)
	}

	paid := Invoice{Number: "INV-1001", Customer: "Ada Lovelace", Amount: 1250.5, Note: "net 30", draft: true}
	blank := Invoice{Amount: 99}
	fmt.Println("required fields missing in paid: ", missing(paid))
	fmt.Println("required fields missing in blank:", missing(blank))

	for _, inv := range []Invoice{paid, blank} {
		data, err := json.Marshal(inv)
		fmt.Printf("json.Marshal: %s (err %v)\n", data, err)
	}
	data, err := json.Marshal(ledger{balance: 10, owner: "Ada"})
	fmt.Printf("json.Marshal of a struct with only unexported fields: %s (err %v)\n", data, err)

	var reading Celsius = 21.5
	ct := reflect.TypeOf(reading)
	fmt.Printf("Celsius: Type %s, Name %q, Kind %s\n", ct, ct.Name(), ct.Kind())
	fmt.Println("  Type == TypeOf(float64):", ct == reflect.TypeOf(float64(0)))
	fmt.Println("  Kind == reflect.Float64:", ct.Kind() == reflect.Float64)
	fmt.Println("  Kind of *Celsius:", reflect.TypeOf(&reading).Kind(), " Elem:", reflect.TypeOf(&reading).Elem())

	// The three laws: an interface value in, a reflection object, and back out.
	var v reflect.Value = reflect.ValueOf(reading) // law 1: interface value -> Value
	back := v.Interface()                          // law 2: Value -> interface value
	c, ok := back.(Celsius)                        // the dynamic type is still Celsius
	fmt.Printf("round trip: %v %T, Celsius %t, CanSet %t\n", back, back, ok, v.CanSet())
	_ = c
}

// missing names the fields tagged validate:"required" that hold their zero value.
func missing(v any) string {
	rv := reflect.ValueOf(v)
	rt := rv.Type()
	var names []string
	for i := range rt.NumField() {
		if rt.Field(i).Tag.Get("validate") == "required" && rv.Field(i).IsZero() {
			names = append(names, rt.Field(i).Name)
		}
	}
	if len(names) == 0 {
		return "none"
	}
	return strings.Join(names, ", ")
}
