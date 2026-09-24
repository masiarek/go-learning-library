// unsafe.Sizeof, Alignof and Offsetof are compile-time constants that show
// where the compiler put each field and how much padding it added. Every
// number here is the same on amd64 and arm64.
//
//	go build struct_layout_and_padding_go.go && ./struct_layout_and_padding_go
package main

import (
	"fmt"
	"unsafe"
)

// Padded lists its fields in the order a reader might write them:
// 1 + 8 + 1 bytes of data, and a 24-byte struct.
type Padded struct {
	Urgent bool
	Cents  int64
	Paid   bool
}

// Packed holds the same fields, largest first: 16 bytes.
type Packed struct {
	Cents  int64
	Urgent bool
	Paid   bool
}

// Mixed pads after the int32 so that the int64 starts at a multiple of 8.
type Mixed struct {
	Sensor int32
	At     int64
}

// TrailingMark ends with a zero-size field, which the compiler pads as if
// it were one byte, so that a pointer to it cannot point past the struct.
type TrailingMark struct {
	Cents int64
	mark  struct{}
}

// LeadingMark puts the zero-size field first and pays nothing for it.
type LeadingMark struct {
	mark  struct{}
	Cents int64
}

// Sizeof is a constant, so it can size an array.
var raw [unsafe.Sizeof(Packed{})]byte

func main() {
	var p Padded
	var q Packed
	var m Mixed
	fmt.Println("Padded {bool, int64, bool}: Sizeof", unsafe.Sizeof(p), " Alignof", unsafe.Alignof(p))
	fmt.Println("  Offsetof: Urgent", unsafe.Offsetof(p.Urgent), " Cents", unsafe.Offsetof(p.Cents), " Paid", unsafe.Offsetof(p.Paid))
	fmt.Println("Packed {int64, bool, bool}: Sizeof", unsafe.Sizeof(q), " Alignof", unsafe.Alignof(q))
	fmt.Println("  Offsetof: Cents", unsafe.Offsetof(q.Cents), " Urgent", unsafe.Offsetof(q.Urgent), " Paid", unsafe.Offsetof(q.Paid))
	fmt.Println("Mixed {int32, int64}: Sizeof", unsafe.Sizeof(m), " Offsetof At", unsafe.Offsetof(m.At))
	fmt.Println("[1000]Padded:", unsafe.Sizeof([1000]Padded{}), "bytes   [1000]Packed:", unsafe.Sizeof([1000]Packed{}), "bytes")
	fmt.Println("TrailingMark {int64, struct{}}:", unsafe.Sizeof(TrailingMark{}), "  LeadingMark {struct{}, int64}:", unsafe.Sizeof(LeadingMark{}))
	fmt.Println("len(raw), an array sized by unsafe.Sizeof(Packed{}):", len(raw))
	fmt.Println()
	fmt.Println("type       Sizeof  Alignof")
	fmt.Printf("bool       %6d  %7d\n", unsafe.Sizeof(false), unsafe.Alignof(false))
	fmt.Printf("int32      %6d  %7d\n", unsafe.Sizeof(int32(0)), unsafe.Alignof(int32(0)))
	fmt.Printf("int64      %6d  %7d\n", unsafe.Sizeof(int64(0)), unsafe.Alignof(int64(0)))
	fmt.Printf("int        %6d  %7d\n", unsafe.Sizeof(int(0)), unsafe.Alignof(int(0)))
	fmt.Printf("float64    %6d  %7d\n", unsafe.Sizeof(float64(0)), unsafe.Alignof(float64(0)))
	fmt.Printf("*Packed    %6d  %7d\n", unsafe.Sizeof(&q), unsafe.Alignof(&q))
	fmt.Printf("string     %6d  %7d\n", unsafe.Sizeof(""), unsafe.Alignof(""))
	fmt.Printf("[]byte     %6d  %7d\n", unsafe.Sizeof([]byte(nil)), unsafe.Alignof([]byte(nil)))
	fmt.Printf("any        %6d  %7d\n", unsafe.Sizeof(any(nil)), unsafe.Alignof(any(nil)))
	fmt.Printf("[3]int64   %6d  %7d\n", unsafe.Sizeof([3]int64{}), unsafe.Alignof([3]int64{}))
	fmt.Printf("struct{}   %6d  %7d\n", unsafe.Sizeof(struct{}{}), unsafe.Alignof(struct{}{}))
	fmt.Printf("[0]int64   %6d  %7d\n", unsafe.Sizeof([0]int64{}), unsafe.Alignof([0]int64{}))
}
