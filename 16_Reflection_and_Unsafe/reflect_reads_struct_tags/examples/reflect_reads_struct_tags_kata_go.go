// Kata: a CSV header and one row from struct tags. Each exported field gives a
// column named by its csv tag, or by the field name when it has no tag; a
// field tagged csv:"-" gives no column, and an unexported field is skipped.
//
//	go build reflect_reads_struct_tags_kata_go.go && ./reflect_reads_struct_tags_kata_go
package main

import (
	"fmt"
	"reflect"
	"strings"
)

type Order struct {
	ID       int     `csv:"order_id"`
	Customer string  `csv:"customer"`
	Total    float64 // no tag: the column is called Total
	Secret   string  `csv:"-"`
	internal string  `csv:"never_seen"`
}

// columns returns the CSV column for each field of v, and the field index it came from.
func columns(t reflect.Type) (names []string, fields []int) {
	for i := range t.NumField() {
		f := t.Field(i)
		if !f.IsExported() {
			continue
		}
		name, tagged := f.Tag.Lookup("csv")
		if !tagged {
			name = f.Name
		}
		if name == "-" {
			continue
		}
		names = append(names, name)
		fields = append(fields, i)
	}
	return names, fields
}

func csvLines(v any) (header, row string, err error) {
	rv := reflect.ValueOf(v)
	if rv.Kind() != reflect.Struct {
		return "", "", fmt.Errorf("csvLines: got %s (kind %s), not a struct", rv.Type(), rv.Kind())
	}
	names, fields := columns(rv.Type())
	cells := make([]string, len(fields))
	for i, f := range fields {
		cells[i] = fmt.Sprint(rv.Field(f).Interface())
	}
	return strings.Join(names, ","), strings.Join(cells, ","), nil
}

func main() {
	order := Order{ID: 7, Customer: "Ada", Total: 19.5, Secret: "pin 1234", internal: "x"}
	header, row, err := csvLines(order)
	fmt.Println(header)
	fmt.Println(row)
	fmt.Println("err:", err)

	_, _, err = csvLines(42)
	fmt.Println("err:", err)
}
