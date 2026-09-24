// Kata: a Registry keyed by any -- comparable admits the interface type, and
// a []byte key panics at run time -- and a Tag constraint that is both a
// ~string term and a method.
//
//	go build constraints_are_type_sets_kata_go.go && ./constraints_are_type_sets_kata_go
package main

import "fmt"

type Registry[K comparable, V any] map[K]V

func (r Registry[K, V]) Put(k K, v V) { r[k] = v }

func (r Registry[K, V]) Get(k K) (V, bool) {
	v, ok := r[k]
	return v, ok
}

// Tag: the string types that also say what kind of tag they are.
type Tag interface {
	~string
	Kind() string
}

type Label string

func (Label) Kind() string { return "label" }

func Describe[T Tag](tags []T) {
	for _, t := range tags {
		fmt.Printf("  %s: %q (%d bytes)\n", t.Kind(), string(t), len(t))
	}
}

func main() {
	handlers := Registry[any, string]{}
	handlers.Put(404, "not found")
	handlers.Put("timeout", "retry")
	v, ok := handlers.Get(404)
	fmt.Printf("Registry[any, string]: Get(404) = %q, %t; len = %d\n", v, ok, len(handlers))

	func() {
		defer func() { fmt.Println("Put([]byte key) panicked:", recover()) }()
		handlers.Put([]byte("raw"), "never stored")
	}()

	fmt.Println("Describe over ~string with Kind:")
	Describe([]Label{"paid", "overdue"})
}
