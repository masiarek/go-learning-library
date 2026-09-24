# 10 — Iterators

Go 1.23 gave `for … range` a fourth kind of operand: a function. Range over a slice, a map or a channel was fixed in the language; range over `func(yield func(V) bool)` lets a package hand out *its* sequence — the lines of a file, the nodes of a tree, an infinite series — as something a plain loop can walk, stop early, and compose with adapters, without building a slice first and without a goroutine and a channel. The `iter` package names the two function types (`Seq`, `Seq2`) and adds `Pull`, which turns a push iterator into `next` and `stop`; `slices`, `maps`, `strings` and `bytes` grew iterator forms of their functions in 1.23 and 1.24. This chapter measures all of it on Go 1.25.

Read [Closing a channel ends a range](../02_Channels/closing_a_channel_ends_a_range/README.md) first: it is the other way Go walks a sequence a function produces, and this chapter keeps comparing the two. The adapters in [An iterator is lazy](an_iterator_is_lazy/README.md) are generic functions, so [A type parameter needs a constraint](../09_Generics/a_type_parameter_needs_a_constraint/README.md) helps but is not required. `iter.Pull` is built on coroutines, and [The sync package](../04_Sync/README.md) and [Context](../05_Context/README.md) are the background for what a forgotten `stop` leaks.

| Lesson | The one thing |
|---|---|
| [Range over a function](range_over_a_function/README.md) | the loop body becomes the `yield` argument, so producer and loop take turns on one goroutine; `iter.Seq` and `iter.Seq2` are just names for the function types |
| [`break` makes `yield` return false](break_makes_yield_return_false/README.md) | `break`, `return` and a panic all end the `yield` call; the iterator's `defer` runs before the code after the loop; calling `yield` again is a runtime panic with a message that names the misuse |
| [An iterator is lazy](an_iterator_is_lazy/README.md) | an infinite `Naturals` is fine to range over; `Filter` and `Take` compose without a slice, and a counter shows the producer made only what the loop consumed |
| [`iter.Pull` needs its `stop`](iter_pull_needs_its_stop/README.md) | `next` runs the producer one step; `stop` is what lets its deferred cleanup run when the caller stops early; after `stop`, `next` returns the zero value and `false` |
| [`slices` and `maps` have iterators](slices_and_maps_have_iterators/README.md) | `slices.Values`/`All`/`Backward`/`Chunk`/`Collect`, `maps.Keys`/`All`/`Collect`, `strings.SplitSeq`/`Lines`; `slices.Sorted(maps.Keys(m))` is how a map gets a fixed order, and `strings.Lines` is single-use |

| Companion | What it holds |
|---|---|
| [Iterators: the compiler errors](iterators_compiler_errors/README.md) | eight refusals with the 1.25 compiler's wording — the wrong function shape, `yield` with the wrong arity, `Seq` where `Seq2` is needed, `Seq[int]` as `Seq[string]`, a `go 1.22` module |
| [Iterators: what `go vet` and `gofmt` catch](iterators_vet_and_lints/README.md) | `stdversion`, `copylocks` (which sees through `slices.Values`), `unusedresult` on `slices.Collect`, the `-gcflags=-m` view of the loop body — and the list of what no tool catches |
| [Iterators: resources](iterators_resources/README.md) | the spec, the `iter` package, the blog post, the proposals, the books that predate the feature and what to read with care |

## Planned

- **Benchmarks**: a range over a function against the hand-written loop and against a channel pipeline, with `-gcflags=-m` showing which loop bodies inline. The tools are in [`allocs/op` is a key, `ns/op` is not](../15_Performance/allocs_per_op_is_a_key_ns_per_op_is_not/README.md).
- **`iter.Pull` under the race detector**, and a goroutine-backed iterator that yields values received from a channel, with its cancellation through a `context.Context`.
- **Iterators over I/O**: a `bufio` line iterator that returns an error after the loop, the pattern the standard library still lacks, and the `regexp` iterator methods (proposal 61902, open at the time of writing).
