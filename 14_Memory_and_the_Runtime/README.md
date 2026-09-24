# 14 — Memory and the runtime

The first seven chapters were about goroutines; this one is about the memory they run in. Go gives every value a place — a function's frame, or the garbage-collected heap — and the compiler, not the programmer, decides which, by whether the value's address can outlive the call. The runtime then grows each goroutine's stack as it needs, collects the heap on a schedule set by two knobs, and, since Go 1.24, can run a cleanup when an object is gone. Each of those is a fact a program can print, and each lesson here prints it: `-gcflags=-m` and `testing.AllocsPerRun` for the compiler's decisions, `unsafe.Sizeof` for a struct's bytes, `MemStats` and `debug.SetMaxStack` for the stack, `debug.SetGCPercent` and `SetMemoryLimit` for the collector, `runtime.AddCleanup` and `weak.Make` for object death.

Read [Goroutines are cheap](../01_Goroutines/goroutines_are_cheap/README.md) first, for the goroutines whose stacks the third lesson grows, and [An interface is two words](../11_Interfaces_and_Method_Sets/an_interface_is_two_words/README.md), because putting a value in an interface is the commonest way it reaches the heap. [Performance](../15_Performance/README.md) is the chapter after this one: where this chapter asks *where does the value live*, that one asks *what did it cost*. Everything here was measured on Go 1.25 on an x86-64 Mac and an amd64 Linux container, and the keys record only what both printed; the arm64 runner checks them in CI.

| Lesson | The one thing |
|---|---|
| [Escape analysis decides stack or heap](escape_analysis_decides_stack_or_heap/README.md) | a returned pointer, an interface, a closure or an 800 KB slice moves a value to the heap; `-gcflags=-m` says which, and `AllocsPerRun` counts 0, 1 or 2 |
| [Field order decides a struct's size](struct_layout_and_padding/README.md) | `{bool, int64, bool}` is 24 bytes and `{int64, bool, bool}` is 16; a trailing `struct{}` costs 8; `Sizeof` is a constant |
| [A goroutine stack grows and has a limit](a_goroutine_stack_grows_and_has_a_limit/README.md) | a million frames deep succeeds; the limit is 1,000,000,000 bytes, `SetMaxStack` returns it, and past it is a fatal error, not a panic |
| [GOGC and GOMEMLIMIT tune the collector](gogc_and_gomemlimit_tune_the_collector/README.md) | `SetGCPercent(50)` returns 100, `SetMemoryLimit(-1)` returns `MaxInt64`; with the collector off, only a memory limit starts a collection |
| [A cleanup runs after the last reference](a_cleanup_runs_after_the_last_reference/README.md) | a cleanup and a nil weak pointer follow the last *use*, not the scope; `KeepAlive` is a use; a tiny pointer-free object may never be cleaned up |

| Companion | What it holds |
|---|---|
| [Memory: the compiler errors](memory_compiler_errors/README.md) | `cannot take address of m["k"]`, `cannot assign to struct field in map`, `invalid array length`, `Sizeof` of a type parameter, `Offsetof` without a selector, `uintptr` to `*T` |
| [Memory: what go vet and gofmt catch](memory_vet_and_lints/README.md) | `copylocks`, `unsafeptr`, the vocabulary of `-gcflags=-m`, and the pinned backing array no tool catches |
| [Memory: resources](memory_resources/README.md) | the GC guide, the spec's alignment rules, the packages, the release notes and proposals, the books' chapters, the talks |

## Planned

- **The heap profile**: `go test -memprofile` and `pprof -sample_index=alloc_space`, naming the function that allocates most; the CPU side is [A CPU profile names the hot function](../15_Performance/a_cpu_profile_names_the_hot_function/README.md).
- **`sync.Pool`**: reusing buffers the collector may discard, and the size-mixing mistake; it is on [The sync package's Planned list](../04_Sync/README.md) too.
- **`runtime/metrics` and `expvar`**: a program that reports its own heap, goroutine count and GC CPU fraction.
- **`GOEXPERIMENT=greenteagc`**: the Go 1.25 experimental collector, once it is on by default and its numbers can be a key.
