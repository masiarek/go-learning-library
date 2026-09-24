# 15 — Performance

Go's answer to "is it fast?" is a tool, not an opinion: `go test -bench` measures, `testing.AllocsPerRun` counts, `-gcflags=-m` says what the compiler inlined, `-gcflags=-d=ssa/check_bce` says which index checks it kept, and `runtime/pprof` names the function the time went to. This chapter is about reading what those tools print, and about which of their numbers are worth keeping. The library's rule bites hardest here: a key records only what cannot vary, and a nanosecond varies — so the answer keys hold `allocs/op` and `B/op`, `Found IsInBounds` counts, `can inline` lines, the name in a profile's top row and exit statuses, while every `ns/op`, `MB/s` and percentage lives in a `Real runs —` fence produced by a `demo/` script beside the page.

It builds on [Memory and the runtime](../14_Memory_and_the_Runtime/README.md) — escape analysis is why an allocation count is what it is, and the collector is who pays for it — and on the `go test` habits of [Testing concurrent code](../07_Testing_Concurrent_Code/README.md); [Testing](../18_Testing/README.md) covers `go test` itself. The reader should be at ease with a module, a `_test.go` file and a `go build` flag.

| Lesson | The one thing |
|---|---|
| [`allocs/op` is a key, `ns/op` is not](allocs_per_op_is_a_key_ns_per_op_is_not/README.md) | eight concatenations are 8 allocs/op and 880 B/op on every machine, a `Builder` with `Grow` is 1 and 256; `ns/op` is a sample; `b.Loop` runs the benchmark function once |
| [`AllocsPerRun` counts allocations](allocsperrun_counts_allocations/README.md) | a whole number per call from an ordinary program — 4 vs 1, 2 vs 1 vs 0, 5 vs 1, and 0 or 1 for boxing an `int` depending on its value |
| [The compiler says what it inlines](the_compiler_says_what_it_inlines/README.md) | `-m` lists what can be inlined and what was; only `-m=2` says why not — `DEFER`, `recover`, cost over the budget of 80, `go:noinline` |
| [Bounds checks, and how to drop them](bounds_checks_and_how_to_drop_them/README.md) | `check_bce` prints one line per check kept; a `range` loop, a masked index or a `_ = s[3]` hint takes four checks to one, or to none |
| [A CPU profile names the hot function](a_cpu_profile_names_the_hot_function/README.md) | `pprof -top` puts `main.hot` in the first row on every run; everything else in the table — samples, duration, percentages — is a real run |

| Companion | What it holds |
|---|---|
| [Performance: the compiler errors](performance_compiler_errors/README.md) | the benchmark signature the go command refuses, `b.Loop` left early or nested, mistyped `-gcflags`, and the runs that measured nothing and said `ok` |
| [Performance: what go vet and gofmt catch](performance_vet_and_lints/README.md) | `tests`, `unusedresult`, `printf`; `copylocks` staying silent on a copied `strings.Builder` while the Builder panics; and what no tool catches |
| [Performance: resources](performance_resources/README.md) | the `testing` documentation, the compiler's source for its budgets, the profiling posts, the books' benchmarking sections, and the pre-1.24 advice to read with care |

## Planned

- **`benchstat`**: comparing two sets of runs with a confidence interval — it lives in `golang.org/x/perf`, outside the standard library this library runs.
- **PGO end to end**: a profile saved as `default.pgo`, the build that uses it, and a `-m=2` report showing a hot call inlined past the budget of 80.
- **`sync.Pool` and reuse**: when a pool cuts `allocs/op` and when it only moves the cost; the sync chapter's Planned list names it too.
- **Execution traces**: `runtime/trace` and `go tool trace` on a program whose problem is waiting rather than computing.
