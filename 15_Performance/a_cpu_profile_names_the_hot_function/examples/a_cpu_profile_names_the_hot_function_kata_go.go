// Kata: profile into memory instead of a file, and check the profile names
// the hot function without leaving the program. A CPU profile is a
// gzip-compressed protocol buffer whose string table holds every function
// name as plain UTF-8, so after gunzipping, bytes.Contains can find them.
//
//	go build a_cpu_profile_names_the_hot_function_kata_go.go && ./a_cpu_profile_names_the_hot_function_kata_go
package main

import (
	"bytes"
	"compress/gzip"
	"fmt"
	"io"
	"runtime/pprof"
)

var readings = make([]int64, 1<<20)

//go:noinline
func hot(rounds int) int64 {
	var total int64
	for range rounds {
		for _, r := range readings {
			total += r
		}
	}
	return total
}

func main() {
	for i := range readings {
		readings[i] = int64(i % 97)
	}

	var profile bytes.Buffer
	if err := pprof.StartCPUProfile(&profile); err != nil {
		panic(err)
	}
	total := hot(400)
	pprof.StopCPUProfile()
	fmt.Println("total is not zero:", total != 0)

	fmt.Printf("first two bytes: % x (the gzip magic number)\n", profile.Bytes()[:2])
	unzipped, err := gzip.NewReader(&profile)
	if err != nil {
		panic(err)
	}
	raw, err := io.ReadAll(unzipped)
	if err != nil {
		panic(err)
	}
	for _, name := range []string{"main.hot", "main.main", "cpu", "nanoseconds"} {
		fmt.Printf("profile names %-14q %t\n", name, bytes.Contains(raw, []byte(name)))
	}
}
