# 01 — Goroutines

A goroutine is a function call that runs on its own. `go f()` starts it, and the statement is over before `f` has done anything. That is all the syntax there is, and it is where Go's reputation for concurrency begins. The lessons here are about the edges of a goroutine's life: what happens to it when `main` returns, how its answer gets back when there is no handle to ask, what its panic does to every other goroutine, and how many of them a program can afford. Those edges are where a first concurrent Go program goes wrong, before any question about channels or locks.

Each lesson ends by putting the same question to other languages — the [Concurrency library ↗](https://masiarek.github.io/concurrency-learning-library/) runs it in Rust, C, C++, Java and Python — and Go's answer is often the odd one out.

| Lesson | The one thing |
|---|---|
| [`main` does not wait](main_does_not_wait/README.md) | when `main` returns, the program exits: a running goroutine stops mid-work and its deferred calls never run, so the wait is something you write |
| [A goroutine has no handle](a_goroutine_has_no_handle/README.md) | `go` is a statement and return values are discarded, so a result — and its error — is something the goroutine sends |
| [A panic ends the whole program](a_panic_ends_the_whole_program/README.md) | a panic in any goroutine exits the process with status 2; only a `recover` deferred in that same goroutine stops it |
| [Goroutines are cheap](goroutines_are_cheap/README.md) | 100,000 blocked goroutines are ordinary, and `runtime.NumGoroutine` counts them exactly once nothing is starting or ending |

## Planned

- **Loop variables are per iteration** — since [Go 1.22 ↗](https://go.dev/doc/go1.22#language) each iteration of a `for` loop has its own variables, so a goroutine started in a loop sees its own value; what code written before then had to do instead.
- **GOMAXPROCS is how many run at once** — goroutines against the threads that run them, and the [container-aware default ↗](https://go.dev/doc/go1.25#container-aware-gomaxprocs) of Go 1.25.
- **A goroutine is not a thread** — `runtime.LockOSThread`, and the 10,000-thread limit of [`debug.SetMaxThreads` ↗](https://pkg.go.dev/runtime/debug#SetMaxThreads), which counts threads, not goroutines.
