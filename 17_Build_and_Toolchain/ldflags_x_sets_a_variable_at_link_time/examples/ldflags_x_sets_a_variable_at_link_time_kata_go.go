// Kata: a program that reports its own version and whether that version was
// stamped at link time, by looking for -X main.version among the -ldflags the
// go command recorded in the binary. Built by this library's runner, with no
// -ldflags, it says "dev" and "stamped with -X: false"; the lesson's script
// shows the same check saying true. It prints nothing that names the
// machine: no GOOS, no GOARCH, no Go version.
//
//	go build -trimpath ldflags_x_sets_a_variable_at_link_time_kata_go.go && ./ldflags_x_sets_a_variable_at_link_time_kata_go
package main

import (
	"fmt"
	"runtime/debug"
	"strings"
)

var version = "dev"

func main() {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		fmt.Println("no build info: the binary was not built by the go command")
		return
	}
	fmt.Println("version:", version)
	fmt.Println("package path:", info.Path)
	fmt.Println("stamped with -X:", strings.Contains(setting(info, "-ldflags"), "-X main.version="))
	fmt.Println("compiler:", setting(info, "-compiler"))
	fmt.Println("build mode:", setting(info, "-buildmode"))
}

// setting returns the recorded value of one build setting, or "" when the
// go command recorded none under that key.
func setting(info *debug.BuildInfo, key string) string {
	for _, s := range info.Settings {
		if s.Key == key {
			return s.Value
		}
	}
	return ""
}
