// Kata: a trace helper. `defer trace("name")()` prints "enter" at once,
// because the outer call is an argument and defer evaluates arguments now;
// the function it returns prints "leave" when the caller returns. Nested
// calls show their nesting.
package main

import "fmt"

var depth int

func trace(name string) func() {
	fmt.Printf("%*senter %s\n", depth*2, "", name)
	depth++
	return func() {
		depth--
		fmt.Printf("%*sleave %s\n", depth*2, "", name)
	}
}

func processOrder(id int) {
	defer trace(fmt.Sprintf("processOrder(%d)", id))()
	checkStock(id)
	charge(id)
}

func checkStock(id int) {
	defer trace("checkStock")()
	fmt.Printf("%*sorder %d: 3 items in stock\n", depth*2, "", id)
}

func charge(id int) {
	defer trace("charge")()
	fmt.Printf("%*sorder %d: charged\n", depth*2, "", id)
}

func main() {
	processOrder(18)
}
