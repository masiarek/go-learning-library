// Kata: an invoice line "item:quantity" is built with fmt.Sprintf on a hot
// path. Rebuild it with append and strconv.AppendInt into a buffer that is
// reused between calls, and let AllocsPerRun show what that saved.
//
//	go build allocsperrun_counts_allocations_kata_go.go && ./allocsperrun_counts_allocations_kata_go
package main

import (
	"fmt"
	"os"
	"strconv"
	"testing"
)

func main() {
	item := "steel-bracket"
	quantity := 1200 + len(os.Args) // not a constant, so it is boxed at run time

	var viaSprintf string
	fmt.Printf("fmt.Sprintf(\"%%s:%%d\", item, quantity): %v\n", testing.AllocsPerRun(200, func() {
		viaSprintf = fmt.Sprintf("%s:%d", item, quantity)
	}))

	buf := make([]byte, 0, 64) // allocated once, before the measurement
	var viaAppend []byte
	fmt.Printf("append + strconv.AppendInt into a reused buffer: %v\n", testing.AllocsPerRun(200, func() {
		buf = buf[:0]
		buf = append(buf, item...)
		buf = append(buf, ':')
		buf = strconv.AppendInt(buf, int64(quantity), 10)
		viaAppend = buf
	}))

	fmt.Println("same text:", viaSprintf == string(viaAppend))
}
