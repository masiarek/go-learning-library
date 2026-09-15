// Not run by CI. Prints how many of 10,000 selects chose each of two cases that
// were both ready every time. demo/tally.sh runs it several times.
package main

import "fmt"

func main() {
	urgent := make(chan string, 1)
	routine := make(chan string, 1)
	fromUrgent, fromRoutine := 0, 0
	for range 10_000 {
		if len(urgent) == 0 {
			urgent <- "disk almost full"
		}
		if len(routine) == 0 {
			routine <- "rotate the logs"
		}
		select {
		case <-urgent:
			fromUrgent++
		case <-routine:
			fromRoutine++
		}
	}
	fmt.Printf("urgent %d  routine %d\n", fromUrgent, fromRoutine)
}
