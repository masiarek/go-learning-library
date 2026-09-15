# 07 — Testing concurrent code

A concurrency bug is a poor witness. The lost update is missing from the run you are watching, and the goroutine you are waiting on has usually finished by the time you look. Go's tooling takes the luck out of the test instead of trying to catch the bug in the act. Build or test with `-race` and every memory access is instrumented, so a data race is reported on a run in which it happens — even when only one thread is running Go code. Run a test inside `testing/synctest`, generally available since Go 1.25, and its goroutines live in a bubble with a fake clock and a way to wait until all of them are stuck: a one-hour timeout takes no time, and "has the worker stopped yet?" gets the same answer on every run.

The lessons build on each other. The race detector comes first, because the last lesson uses it to catch a test that checks too early.

| Lesson | The one thing |
|---|---|
| [The race detector](the_race_detector/README.md) | `-race` reports two goroutines touching one variable without synchronization, on a run in which it happens, and exits 66 |
| [`synctest` makes time virtual](synctest_makes_time_virtual/README.md) | in a bubble the clock moves only when every goroutine is blocked, so a one-hour timeout passes at once |
| [`synctest.Wait` instead of a sleep](synctest_wait/README.md) | a check after `Wait` sees what the other goroutines did, on every run — and without it, `go test -race` fails the test |

## Planned

- **Stress runs with `go test -count`** — running one test hundreds of times to shake out a rare interleaving, what `-count` and `-cpu` change, and what a clean stress run does and does not show.
- **Goroutine leak checks** — a test that fails when it leaves a goroutine running: `synctest.Test`, which waits for every goroutine in its bubble, next to counting goroutines once they have settled.
- **A deadlock inside a bubble** — what `synctest.Test` reports when every goroutine is blocked and no timer is left to wake one.
- **`go vet` for concurrency mistakes** — a `sync.Mutex` or `sync.WaitGroup` copied by value, which vet's `copylocks` check reports.
