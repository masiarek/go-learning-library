// Kata: report allocs/op and B/op for a third way of building the order line,
// strings.Join, from a plain program -- no test file. testing.Benchmark runs a
// benchmark function and returns a BenchmarkResult; the counts it holds are
// the same ones `go test -bench` prints. Nothing here prints a time.
//
//	go build allocs_per_op_is_a_key_ns_per_op_is_not_kata_go.go && ./allocs_per_op_is_a_key_ns_per_op_is_not_kata_go
package main

import (
	"flag"
	"fmt"
	"strings"
	"testing"
)

var fields = []string{
	"customer=acme-industries",
	"item=steel-bracket-40mm",
	"quantity=1200",
	"warehouse=rotterdam-east",
	"carrier=overnight-freight",
	"priority=high",
	"currency=EUR",
	"reference=PO-2026-000418",
}

func joinWithPlus(fields []string) string {
	line := "order:"
	for _, f := range fields {
		line += f + ";"
	}
	return line
}

func joinWithBuilder(fields []string) string {
	var b strings.Builder
	b.Grow(256)
	b.WriteString("order:")
	for _, f := range fields {
		b.WriteString(f)
		b.WriteByte(';')
	}
	return b.String()
}

// joinWithJoin lets strings.Join size the buffer, then concatenates once more
// for the prefix and the closing separator.
func joinWithJoin(fields []string) string {
	return "order:" + strings.Join(fields, ";") + ";"
}

func main() {
	// testing.Benchmark reads the -test.benchtime flag; outside `go test` the
	// flag has to be registered and set by hand. 1000x: exactly 1000 iterations.
	testing.Init()
	if err := flag.Set("test.benchtime", "1000x"); err != nil {
		panic(err)
	}
	candidates := []struct {
		name string
		join func([]string) string
	}{
		{"joinWithPlus", joinWithPlus},
		{"joinWithBuilder", joinWithBuilder},
		{"joinWithJoin", joinWithJoin},
	}
	for _, c := range candidates {
		result := testing.Benchmark(func(b *testing.B) {
			for b.Loop() {
				c.join(fields)
			}
		})
		fmt.Printf("%-16s iterations %d  %3d B/op  %d allocs/op\n", c.name, result.N, result.AllocedBytesPerOp(), result.AllocsPerOp())
	}
	fmt.Println("same line from all three:", joinWithPlus(fields) == joinWithBuilder(fields) && joinWithPlus(fields) == joinWithJoin(fields))
}
