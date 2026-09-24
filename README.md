# Go — a learning library

**Go, starting with the thing it is best known for: concurrency, and going on to the advanced language.** Goroutines, channels, `select`, the `sync` package, `context`, the patterns built from them, and the tools that test them; then generics, iterators, interfaces and method sets, errors, `defer`, memory and the runtime, performance, reflection and `unsafe`, the build, and the `testing` package — one idea per page. Every claim on every page is backed by a Go program whose output is checked against a recorded answer key in CI, on Ubuntu and on macOS.

A concurrent program is the hardest kind to make that promise about, because the interesting part is often what changes from one run to the next. So the programs here print only what cannot vary — a value handed over a channel, a line that did or did not appear, an exit status — and what does vary is shown as a labelled count of real runs, with the script that produced it beside the page.

## Start here

[**00 — Start here**](00_Start_Here/README.md) — who this is for, the seven pages to read first, and how a page is laid out.

## The chapters

| | Chapter | What it covers |
|---|---|---|
| 01 | [Goroutines](01_Goroutines/README.md) | `main` does not wait, a goroutine has no handle, a panic ends the whole program, how cheap goroutines are |
| 02 | [Channels](02_Channels/README.md) | the unbuffered handshake, bounded queues and backpressure, closing a channel, the deadlock detector |
| 03 | [Select](03_Select/README.md) | waiting on many channels, random choice among ready cases, timeouts, switching a case off with a nil channel |
| 04 | [The sync package](04_Sync/README.md) | mutexes, atomic counters, `sync.Once`, the rules of a `WaitGroup` |
| 05 | [Context](05_Context/README.md) | cancellation, deadlines, leaked goroutines, cancelling with a cause |
| 06 | [Patterns](06_Patterns/README.md) | pipelines, fan-out and fan-in, worker pools, semaphores, the first error cancelling the rest |
| 07 | [Testing concurrent code](07_Testing_Concurrent_Code/README.md) | the race detector, `testing/synctest` and its fake clock |
Then the advanced language. Each of these chapters ends with three companion pages — the compiler errors of the topic, what `go vet` and `gofmt` catch, and its resources — and every lesson has a kata with a verified solution.

| | Chapter | What it covers |
|---|---|---|
| 09 | [Generics](09_Generics/README.md) | constraints, why a method cannot have type parameters, where inference stops, a generic type and its zero value, constraints as type sets |
| 10 | [Iterators](10_Iterators/README.md) | range over a function, what `break` does to `yield`, laziness, `iter.Pull` and its `stop`, the iterators in `slices` and `maps` |
| 11 | [Interfaces and method sets](11_Interfaces_and_Method_Sets/README.md) | pointer and value receivers, embedding is not inheritance, the typed nil, an interface is two words, assertions and type switches |
| 12 | [Errors](12_Errors/README.md) | `%w` and `errors.Is`, `errors.As`, `errors.Join`, writing an error type with `Unwrap` |
| 13 | [Defer, panic and recover](13_Defer_Panic_and_Recover/README.md) | when arguments are evaluated, last in first out, a defer that changes a named result, where `recover` works, `defer` in a loop |
| 14 | [Memory and the runtime](14_Memory_and_the_Runtime/README.md) | escape analysis, struct layout and padding, the growing stack and its limit, `GOGC` and `GOMEMLIMIT`, cleanups and weak pointers |
| 15 | [Performance](15_Performance/README.md) | what a benchmark may record, `AllocsPerRun`, what the compiler inlines, bounds checks, a CPU profile |
| 16 | [Reflection and unsafe](16_Reflection_and_Unsafe/README.md) | struct tags, addressability, `reflect.Select`, `unsafe.Pointer`'s rules, what reflection costs |
| 17 | [Build and toolchain](17_Build_and_Toolchain/README.md) | build constraints, `go:embed`, `-ldflags -X`, `go generate`, reproducible builds |
| 18 | [Testing](18_Testing/README.md) | subtests and tables, example tests, `t.Parallel` and `t.Cleanup`, fuzzing, coverage and `-run` |

And at the end:

| | Chapter | What it covers |
|---|---|---|
| 08 | [Resources](08_Resources/README.md) | the documentation, the books, and where each idea lives in the sibling libraries |

## In other languages

Every lesson ends with **In other languages**. The [Concurrency library ↗](https://masiarek.github.io/concurrency-learning-library/) puts the same questions to Rust, Go, C, C++, Java and Python side by side, and its [concept map ↗](https://masiarek.github.io/concurrency-learning-library/11_Concepts/index.html) names each idea across languages and links back to the lesson here that runs it in Go.

## Running the examples

You need **Go 1.25 or later** (`wg.Go` and `testing/synctest` are both new in 1.25, and the advanced chapters use `b.Loop`, `runtime.AddCleanup` and `weak` from 1.24 and range-over-function from 1.23). Each example is one `package main` file with nothing beyond the standard library, run from its own folder:

```bash
go run main_does_not_wait_go.go
```

A few examples are `.sh` drivers, for what a program cannot show about itself: a panic's exit status, the race detector's report, a `go test` run. To run all of them and check every recorded output:

```bash
python3 tools/run_examples.py --check
```

## The one rule

No page hand-types what a program prints. A lesson marks the spot and the runner fills it from a real run, so an example that behaves differently in a new Go release breaks the build instead of quietly making a page wrong. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Sibling libraries

- [**Concurrency** ↗](https://masiarek.github.io/concurrency-learning-library/) — one question per page, answered in Rust, Go, C, C++, Java and Python, plus a map of over 150 concurrency concepts, each with its name in every language.
- [**Rust** ↗](https://masiarek.github.io/rust-learning-library/) — threads, channels, `Arc`, `Send` and `Sync`, lock poisoning; and data races and forgotten unlocks for C programmers.
- [**C** ↗](https://masiarek.github.io/c-learning-library/) and [**C++** ↗](https://masiarek.github.io/cpp-learning-library/) — building, strings, bytes on the wire, clocks and benchmarking.
- [**Python** ↗](https://masiarek.github.io/python-learning-library/) — text and bytes.
- [**Linux** ↗](https://masiarek.github.io/linux-learning-library/) — pipelines, which are concurrent processes, and the signal that ends them.
