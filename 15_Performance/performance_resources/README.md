# Performance: resources

**Level:** 301 · where the lessons of this chapter came from, and what to read next

**One line:** The primary sources are the `testing` package's documentation, the compiler's own source for its budgets and messages, and the Go blog's posts on `b.Loop`, profiling and PGO; the books cover benchmarking and profiling in their testing chapters; and a good deal of older advice about benchmark loops and inlining no longer describes Go 1.25.

## Primary sources

- [`testing`, Benchmarks ↗](https://pkg.go.dev/testing#hdr-Benchmarks), [`B.Loop` ↗](https://pkg.go.dev/testing#B.Loop), [`B.ReportAllocs` ↗](https://pkg.go.dev/testing#B.ReportAllocs), [`Benchmark` ↗](https://pkg.go.dev/testing#Benchmark), [`BenchmarkResult` ↗](https://pkg.go.dev/testing#BenchmarkResult) and [`AllocsPerRun` ↗](https://pkg.go.dev/testing#AllocsPerRun) — what a benchmark is, what `Loop` guarantees, what the result holds.
- [`go help testflag` ↗](https://pkg.go.dev/cmd/go#hdr-Testing_flags) — `-bench`, `-benchmem`, `-benchtime`, `-count`, `-cpuprofile`, `-memprofile`, `-trace`.
- [Go 1.24 release notes, `testing` ↗](https://go.dev/doc/go1.24#testingpkgtesting) and Junyang Shao, [More predictable benchmarking with testing.B.Loop ↗](https://go.dev/blog/testing-b-loop), the Go blog, April 2025 — why `b.Loop` replaced the `b.N` loop.
- [`cmd/compile` ↗](https://pkg.go.dev/cmd/compile) — the `-m` and `-d` flags and the `//go:noinline` directive; [`src/cmd/compile/internal/inline/inl.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/cmd/compile/internal/inline/inl.go) — the budget of 80, the extra call cost of 57, the hot budget of 2000, and every `cannot inline` message.
- [Go 1.16 release notes ↗](https://go.dev/doc/go1.16) and [Go 1.18 release notes ↗](https://go.dev/doc/go1.18) — inlining of functions with `for` loops, then `range` and labeled loops; [Go 1.21 release notes ↗](https://go.dev/doc/go1.21) — profile-guided optimization ready for general use.
- [Profile-guided optimization ↗](https://go.dev/doc/pgo) and [Profile-guided optimization in Go 1.21 ↗](https://go.dev/blog/pgo) — how a profile raises the inlining budget on the hot path.
- [`src/cmd/compile/internal/ssa/checkbce.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/cmd/compile/internal/ssa/checkbce.go) and [`prove.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/cmd/compile/internal/ssa/prove.go) — the debug pass that lists bounds checks and the pass that removes them; [issue 14808 ↗](https://github.com/golang/go/issues/14808) — the `_ = b[3]` hint.
- The Go wiki, [Compiler And Runtime Optimizations ↗](https://go.dev/wiki/CompilerOptimizations) — escape analysis, inlining and the other things `-gcflags=-m` reports.
- [`runtime/pprof` ↗](https://pkg.go.dev/runtime/pprof), [`runtime/trace` ↗](https://pkg.go.dev/runtime/trace), [`go tool trace` ↗](https://pkg.go.dev/cmd/trace) and the [`pprof` documentation ↗](https://github.com/google/pprof/blob/main/doc/README.md) — collecting and reading profiles and traces; the [profile format ↗](https://github.com/google/pprof/blob/main/proto/README.md).
- Russ Cox and Shenghou Ma, [Profiling Go Programs ↗](https://go.dev/blog/pprof), the Go blog, 2011 (updated 2013) — still the clearest walk from a slow program to a fast one; [Diagnostics ↗](https://go.dev/doc/diagnostics) — the map of profiling, tracing, debugging and runtime statistics; [More powerful Go execution traces ↗](https://go.dev/blog/execution-traces-2024).
- [`benchstat` ↗](https://pkg.go.dev/golang.org/x/perf/cmd/benchstat) — comparing sets of benchmark runs; outside the standard library.
- The runtime sources behind the allocation counts: [`iface.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/runtime/iface.go), [`string.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/runtime/string.go), [`slice.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/runtime/slice.go), [`sizeclasses.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/internal/runtime/gc/sizeclasses.go) and [`strconv/itoa.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/strconv/itoa.go).
- The [GC guide ↗](https://go.dev/doc/gc-guide) — what allocation costs after the allocation; the chapter [Memory and the runtime](../../14_Memory_and_the_Runtime/README.md) is this library's take.

## Books

- Alan Donovan and Brian Kernighan, *The Go Programming Language* (Addison-Wesley, 2015), chapter 11, "Testing" — 11.4, "Benchmark Functions" (the `b.N` loop of its day, `-benchmem`, and why absolute times mislead) and 11.5, "Profiling" (`-cpuprofile`, `-memprofile`, `-blockprofile` and `go tool pprof`).
- Jon Bodner, *Learning Go*, 2nd ed. (O'Reilly, 2024), chapter 15, "Writing Tests" — "Using Benchmarks", with the box "Profiling Your Go Code"; chapter 6, "Pointers" — "Reducing the Garbage Collector's Workload" and "Tuning the Garbage Collector".
- *Go in Practice*, 2nd ed. (Manning, 2025), chapter 6, "Formatting, testing, debugging, and benchmarking" — 6.4, "Benchmarking and performance tuning".
- Adam Freeman, *Pro Go* (Apress, 2022), chapter 31, "Unit Testing, Benchmarking, and Logging" — "Benchmarking Code" and "Removing Setup from the Benchmark" (`ResetTimer`, `StopTimer`, `StartTimer`, which `b.Loop` now handles for the common case).
- Miki Tebeka, *Effective Go Recipes* (Pragmatic, 2024), Recipe 33, "Calculating Cumulative Sum" — a benchmark, its allocations, and a CPU profile read with `top`; Recipe 56, "Using sync/atomic for a Faster Now" — a benchmark deciding between two designs; Recipe 75, "Using Build Tags for Conditional Builds" — `net/http/pprof` behind a build tag.

### Not on the shelf

- Bartłomiej Płotka, *Efficient Go* (O'Reilly, 2022): <https://www.oreilly.com/library/view/efficient-go/9781098105709/> — a whole book on the measure-first discipline this chapter practises in five pages.
- Teiva Harsanyi, *100 Go Mistakes and How to Avoid Them* (Manning, 2022): <https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them> — its optimization chapter collects the benchmarking mistakes.

## Talks and videos

- Jacob Walker, [Understanding Allocations: the Stack and the Heap ↗](https://www.youtube.com/watch?v=ZMZpH4yT7M0), GopherCon SG 2019 — the talk behind [`AllocsPerRun` counts allocations](../allocsperrun_counts_allocations/README.md) and chapter 14's escape analysis lesson.
- Dave Cheney, [High Performance Go Workshop ↗](https://dave.cheney.net/high-performance-go-workshop/gophercon-2019.html), GopherCon 2019 — a written workshop covering benchmarking, profiling, tracing, the compiler's `-m` output and bounds-check elimination, from the same starting point as this chapter.

## Read with care

- **Benchmark tutorials written before Go 1.24**, with `for i := 0; i < b.N; i++`. The loop still works, but it runs the benchmark function several times, times whatever setup sits above it on every round, and does nothing to stop the compiler discarding an unused result — [`allocs/op` is a key, `ns/op` is not](../allocs_per_op_is_a_key_ns_per_op_is_not/README.md).
- **"Functions with loops cannot be inlined."** True before Go 1.16 for `for` loops and before 1.18 for `range` loops; the lesson [The compiler says what it inlines](../the_compiler_says_what_it_inlines/README.md) shows `sumTo` inlined with its loop.
- **Tables of `ns/op` quoted as facts.** Every such number is one machine on one day; without the machine, the Go version and the number of runs, it cannot be compared with anything.
- **"`fmt.Sprintf` allocates N times."** The count depends on whether the arguments are constants, small integers or run-time values — [`AllocsPerRun` counts allocations](../allocsperrun_counts_allocations/README.md) shows 1 and 2 for the same format string.
- **Advice to remove bounds checks with `unsafe`.** The prove pass removes the common shapes by itself, and a benchmark is the only way to know whether the remaining checks cost anything — [Bounds checks, and how to drop them](../bounds_checks_and_how_to_drop_them/README.md).

*Checked 2026-09-23.*
