// Kata: run the steps of a job and defer an undo for each one, so that the
// undos run in reverse — after a normal finish, and while a panic unwinds.
// This is the one loop in which a defer per iteration is what you want.
package main

import "fmt"

func runJob(steps []string, failAt string) {
	for _, step := range steps {
		fmt.Println("  do  ", step)
		defer fmt.Println("  undo", step)
		if step == failAt {
			panic(step + ": printer offline")
		}
	}
	fmt.Println("  all steps done")
}

func main() {
	steps := []string{"reserve stock", "charge card", "print label"}

	fmt.Println("job 1: every step succeeds")
	runJob(steps, "")

	fmt.Println("job 2: the last step fails")
	func() {
		defer func() { fmt.Println("  recovered:", recover()) }()
		runJob(steps, "print label")
	}()
}
