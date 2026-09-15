// When several cases of a select are ready, one is chosen at random: the order
// the cases are written in is not a priority. Priority is something you write.
//
//	go run select_chooses_at_random_go.go
package main

import "fmt"

const selects = 10_000

func main() {
	fmt.Println("1. Two cases, both ready on every one of", selects, "selects")
	urgent := make(chan string, 1)
	routine := make(chan string, 1)
	fromUrgent, fromRoutine := 0, 0
	for range selects {
		if len(urgent) == 0 {
			urgent <- "disk almost full"
		}
		if len(routine) == 0 {
			routine <- "rotate the logs"
		}
		select {
		case <-urgent: // written first
			fromUrgent++
		case <-routine:
			fromRoutine++
		}
	}
	fmt.Println("   urgent chosen between 40% and 60% of the time: ", between40and60(fromUrgent))
	fmt.Println("   routine chosen between 40% and 60% of the time:", between40and60(fromRoutine))

	fmt.Println()
	fmt.Println("2. 100 urgent and 100 routine messages already queued")
	urgentQueue, routineQueue := queued(100)
	var plain []string
	for range 200 {
		plain = append(plain, plainSelect(urgentQueue, routineQueue))
	}
	fmt.Println("   plain select handled every urgent message first:       ", urgentFirst(plain))

	urgentQueue, routineQueue = queued(100)
	var prioritized []string
	for range 200 {
		prioritized = append(prioritized, urgentThenAny(urgentQueue, routineQueue))
	}
	fmt.Println("   urgent-first select handled every urgent message first:", urgentFirst(prioritized))
}

// plainSelect takes whichever message the select picks.
func plainSelect(urgent, routine <-chan string) string {
	select {
	case <-urgent:
		return "urgent"
	case <-routine:
		return "routine"
	}
}

// urgentThenAny looks at urgent alone first, without waiting, and only when it
// is empty waits on both.
func urgentThenAny(urgent, routine <-chan string) string {
	select {
	case <-urgent:
		return "urgent"
	default:
		select {
		case <-urgent:
			return "urgent"
		case <-routine:
			return "routine"
		}
	}
}

func between40and60(count int) bool {
	return count >= selects*40/100 && count <= selects*60/100
}

// queued returns two buffered channels holding n messages each.
func queued(n int) (urgent, routine chan string) {
	urgent = make(chan string, n)
	routine = make(chan string, n)
	for range n {
		urgent <- "disk almost full"
		routine <- "rotate the logs"
	}
	return urgent, routine
}

// urgentFirst reports whether no routine message came before the last urgent one.
func urgentFirst(handled []string) bool {
	seenRoutine := false
	for _, kind := range handled {
		if kind == "routine" {
			seenRoutine = true
		} else if seenRoutine {
			return false
		}
	}
	return true
}
