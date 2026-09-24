# Memory: resources

**Level:** 301 · for whoever wants the primary sources behind this chapter, and the books' chapter names

**One line:** The garbage collector guide, the spec's size and alignment rules, the `runtime`, `runtime/debug`, `unsafe` and `weak` packages, and the release notes that added the memory limit, cleanups and weak pointers — plus which chapters of the books on the shelf cover them.

## Primary sources

- [A Guide to the Go Garbage Collector ↗](https://go.dev/doc/gc-guide) — the one document to read: where values live, the GC cycle and its costs, `GOGC`, the memory limit and when to use it, latency, finalizers, cleanups and weak pointers, and an optimization guide with escape analysis and heap profiling.
- [The Go specification, "Size and alignment guarantees" ↗](https://go.dev/ref/spec#Size_and_alignment_guarantees) — the three rules every `Sizeof` on this chapter's pages follows; ["Package unsafe" ↗](https://go.dev/ref/spec#Package_unsafe) — when `Sizeof`, `Alignof` and `Offsetof` are constants.
- [Go FAQ, "How do I know whether a variable is allocated on the heap or the stack?" ↗](https://go.dev/doc/faq#stack_or_heap) — the rule escape analysis applies, and the advice not to think about it until a profile says so.
- [Package `runtime` ↗](https://pkg.go.dev/runtime) — the environment variables (`GOGC`, `GOMEMLIMIT`, `GODEBUG=gctrace=1`), `GC`, `MemStats`, `AddCleanup`, `KeepAlive`, `SetFinalizer`.
- [Package `runtime/debug` ↗](https://pkg.go.dev/runtime/debug) — `SetGCPercent`, `SetMemoryLimit`, `SetMaxStack`, `FreeOSMemory`.
- [Package `runtime/metrics` ↗](https://pkg.go.dev/runtime/metrics) — the stable, documented counterpart of `MemStats`, for a program that watches its own heap.
- [Package `unsafe` ↗](https://pkg.go.dev/unsafe) — the six valid `Pointer` patterns, `Add`, `Slice`, `String`.
- [Package `weak` ↗](https://pkg.go.dev/weak) — `Make` and `Pointer.Value`, new in Go 1.24.
- Release notes: [Go 1.4 ↗](https://go.dev/doc/go1.4#runtime) (contiguous stacks, 2 KB start), [Go 1.19 ↗](https://go.dev/doc/go1.19#runtime) (the soft memory limit, adaptive initial stacks), [Go 1.24 ↗](https://go.dev/doc/go1.24#runtime) (`AddCleanup`, `weak`), [Go 1.25 ↗](https://go.dev/doc/go1.25) (slices of non-constant size on the stack; cleanups run concurrently).
- Design documents and proposals: [Soft memory limit ↗](https://github.com/golang/proposal/blob/master/design/48409-soft-memory-limit.md) (Michael Knyszek, 2021); [Contiguous stacks ↗](https://docs.google.com/document/d/1wAaf1rYoM4S4gtnPh0zOlGzWtrZFQ5suE8qr2sD8uWQ/pub) (Keith Randall, 2013); [runtime: add AddCleanup ↗](https://github.com/golang/go/issues/67535); [weak: new package ↗](https://github.com/golang/go/issues/67552).
- The Go blog: [*Getting to Go: The Journey of Go's Garbage Collector* ↗](https://go.dev/blog/ismmkeynote) (Rick Hudson, 2018) — how the collector became concurrent and why its pauses are short; [*Go runtime: 4 years later* ↗](https://go.dev/blog/go119runtime) (Michael Knyszek, 2022) — what changed between 1.13 and 1.19, the memory limit among it; [*Go GC: Prioritizing low latency and simplicity* ↗](https://go.dev/blog/go15gc) (2015).
- The source, at go1.25.5: [`runtime/stack.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/runtime/stack.go) (growth, copying, the overflow throw), [`runtime/proc.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/runtime/proc.go) (`maxstacksize`), [`runtime/mgc.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/runtime/mgc.go) (the triggers), [`runtime/malloc.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/runtime/malloc.go) (the tiny allocator), [`cmd/compile/internal/escape` ↗](https://github.com/golang/go/tree/go1.25.5/src/cmd/compile/internal/escape) (escape analysis) and [`cmd/compile/internal/types/size.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/cmd/compile/internal/types/size.go) (struct layout).

## Books

- Alan A. A. Donovan and Brian W. Kernighan, *The Go Programming Language* (Addison-Wesley, 2015) — chapter 2, "Program Structure", section 2.3.4, "Lifetime of Variables" (escape, in two pages); chapter 13, "Low-Level Programming", section 13.1, "unsafe.Sizeof, Alignof, and Offsetof".
- Jon Bodner, *Learning Go*, 2nd ed. (O'Reilly, 2024) — chapter 6, "Pointers": "Pointers Are a Last Resort", "Pointer Passing Performance", "Slices as Buffers", "Reducing the Garbage Collector's Workload" and "Tuning the Garbage Collector".
- Katherine Cox-Buday, *Concurrency in Go* (O'Reilly, 2017) — chapter 3, "Go's Concurrency Building Blocks", the section "Goroutines", which measures a goroutine's memory and works out how many fit.
- James Cutajar, *Learn Concurrent Programming with Go* (Manning, 2024) — chapter 2, "Dealing with threads", the section "What goes on the stack space?".
- Burak Serdar, *Effective Concurrency in Go* (Packt, 2023) — chapter 2, "Go Concurrency Primitives", the section "Goroutines", on closures and the variables that escape to the heap because a goroutine captures them.
- *Go in Practice*, 2nd ed. (Manning, 2025) — chapter 1, "Getting started with Go", the note on `GOGC=off`; the chapter promises more on collector control in chapter 13, "Reflection, code generation, and advanced Go", whose sections are about reflection, tags, code generation and C.

### Not on the shelf

- Teiva Harsanyi, *100 Go Mistakes and How to Avoid Them* (Manning, 2022) — [publisher's page ↗](https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them); a chapter on optimizations covers escape analysis, `sync.Pool` and GC tuning.
- Bartłomiej Płotka, *Efficient Go* (O'Reilly, 2022) — [publisher's page ↗](https://www.oreilly.com/library/view/efficient-go/9781098105709/); memory, the allocator and the collector from a profiling angle.

## Talks and videos

- Jacob Walker, *Understanding Allocations: the Stack and the Heap*, GopherCon Singapore 2019 — [video ↗](https://www.youtube.com/watch?v=ZMZpH4yT7M0). Escape analysis explained with `-gcflags=-m`.
- Rick Hudson, *Go GC: Solving the Latency Problem*, GopherCon 2015 — [video ↗](https://www.youtube.com/watch?v=aiv1JOfMjm0). The concurrent collector's design, as it shipped in Go 1.5.
- Dave Cheney, *High Performance Go Workshop*, GopherCon 2019 — [notes ↗](https://dave.cheney.net/high-performance-go-workshop/gophercon-2019.html). Escape analysis, inlining and the collector, with exercises.

## Read with care

- **"A goroutine's stack starts at 8 KB" or "4 KB"** — true for Go 1.2 and 1.3; it has been 2 KB since 1.4, and since 1.19 the runtime adapts the starting size to recent goroutines.
- **"Go's collector is stop-the-world"** — the collector has been concurrent since Go 1.5; the two brief pauses per cycle are the point of the 2015 and 2018 talks above.
- **`runtime.SetFinalizer` as the way to release a resource** — still works, but the package's own documentation now steers new code to `AddCleanup`, and the finalizer's handing back of the object is what made it error-prone.
- **"`GOGC` is the only knob"** — true before Go 1.19; `GOMEMLIMIT` is the second, and `GOGC=off` with a limit is a supported configuration.
- **"Pass pointers to avoid copying"** — a 24-byte struct copies faster than it allocates; [Escape analysis decides stack or heap](../escape_analysis_decides_stack_or_heap/README.md) measures it, and Bodner's "Pointers Are a Last Resort" says the same.
- **Any transcript of `-gcflags=-m`** — the wording changes between compiler versions and inlining changes the verdicts; the keys in this chapter are go1.25's, with `//go:noinline` where a stable transcript needed it.
- **"`make([]T, n)` with a variable `n` always allocates"** — true until Go 1.25, which keeps a small one in the frame.

*Checked 2026-09-23.*
