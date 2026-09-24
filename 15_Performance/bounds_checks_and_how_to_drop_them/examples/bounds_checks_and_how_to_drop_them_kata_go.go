// Kata: add the `_ = s[3]` hint to a four-byte checksum, then prove the safety
// net is still there and now sits on the hint line: call both versions with a
// two-byte slice and recover the panics. The index in each message says which
// check fired first.
//
//	go build bounds_checks_and_how_to_drop_them_kata_go.go && ./bounds_checks_and_how_to_drop_them_kata_go
package main

import "fmt"

func checksum(s []byte) byte {
	return s[0] ^ s[1] ^ s[2] ^ s[3]
}

func checksumHinted(s []byte) byte {
	_ = s[3] // one check here; the four below are proven safe by it
	return s[0] ^ s[1] ^ s[2] ^ s[3]
}

// panicOf runs f and returns the panic it raised, or "none".
func panicOf(f func()) (value any) {
	defer func() {
		if r := recover(); r != nil {
			value = r
		}
	}()
	f()
	return "none"
}

func main() {
	frame := []byte{0x5a, 0xa5, 0x0f, 0x01}
	fmt.Printf("four bytes: checksum %#x, hinted %#x\n", checksum(frame), checksumHinted(frame))

	short := frame[:2]
	fmt.Println("two bytes, checksum:      ", panicOf(func() { checksum(short) }))
	fmt.Println("two bytes, checksumHinted:", panicOf(func() { checksumHinted(short) }))
}
