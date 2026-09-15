# Go — a learning library

**Go, starting with the thing it is best known for: concurrency.** Goroutines, channels, `select`, the `sync` package, `context`, the patterns built from them, and the tools that test them — one idea per page. Every claim on every page is backed by a Go program whose output is checked against a recorded answer key in CI, on Ubuntu and on macOS.

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
| 08 | [Resources](08_Resources/README.md) | the documentation, the books, and where each idea lives in the sibling libraries |

## In other languages

Every lesson ends with **In other languages**. The [Concurrency library ↗](https://masiarek.github.io/concurrency-learning-library/) puts the same questions to Rust, Go, C, C++, Java and Python side by side, and its [concept map ↗](https://masiarek.github.io/concurrency-learning-library/11_Concepts/index.html) names each idea across languages and links back to the lesson here that runs it in Go.

## Running the examples

You need **Go 1.25 or later** (`wg.Go` and `testing/synctest` are both new in 1.25). Each example is one `package main` file with nothing beyond the standard library, run from its own folder:

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

- [**Concurrency** ↗](https://masiarek.github.io/concurrency-learning-library/) — one question per page, answered in Rust, Go, C, C++, Java and Python, plus a map of 149 concurrency concepts.
- [**Rust** ↗](https://masiarek.github.io/rust-learning-library/) — threads, channels, `Arc`, `Send` and `Sync`, lock poisoning; and data races and forgotten unlocks for C programmers.
- [**C** ↗](https://masiarek.github.io/c-learning-library/) and [**C++** ↗](https://masiarek.github.io/cpp-learning-library/) — building, strings, bytes on the wire, clocks and benchmarking.
- [**Python** ↗](https://masiarek.github.io/python-learning-library/) — text and bytes.
- [**Linux** ↗](https://masiarek.github.io/linux-learning-library/) — pipelines, which are concurrent processes, and the signal that ends them.
