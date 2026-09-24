# Iterators: resources

**Level:** 201 · anyone who wants the primary sources behind this chapter, and to know which books predate it

**One line:** Range over a function is from August 2024, so the specification, the `iter` package documentation, one blog post, one wiki page and the proposals are the sources; every book on the shelf was written before it, and their `for-range` chapters need reading with that in mind.

## Primary sources

- [The Go specification, For statements with range clause ↗](https://go.dev/ref/spec#For_range) — the paragraph that defines ranging over a function: the synthesized `yield`, what its arguments become, when it returns true, and "yield returns false and must not be called again".
- [Package `iter` ↗](https://pkg.go.dev/iter) — `Seq`, `Seq2`, `Pull`, `Pull2`, and the sections on naming, single-use iterators, pulling values and mutation. The package documentation is the closest thing to a style guide for iterator APIs.
- Ian Lance Taylor, [*Range Over Function Types* ↗](https://go.dev/blog/range-functions), the Go blog, 20 August 2024 — why (push and pull `Set` elements), the three signatures, adapters, the binary-tree example, and the `go.mod` note. The blog form of his GopherCon 2024 talk.
- Russ Cox, [*Coroutines for Go* ↗](https://research.swtch.com/coro), 17 July 2023 — the design behind `iter.Pull`: why a coroutine and not a goroutine with channels, and the measured cost of a switch.
- [Go Wiki: Rangefunc Experiment ↗](https://go.dev/wiki/RangefuncExperiment) — the FAQ from the Go 1.22 experiment: how a loop runs, `defer` and panics in the body, what the runtime checks, and performance.
- [Go 1.23 release notes ↗](https://go.dev/doc/go1.23#language) — "Changes to the language" (the three signatures), "Iterators" (the `iter` package), and the `slices` and `maps` additions; [Go 1.24 release notes ↗](https://go.dev/doc/go1.24#stringspkg) — the `strings` and `bytes` iterator functions.
- The proposals: [spec: add range over int, range over func, 61405 ↗](https://github.com/golang/go/issues/61405); [iter: new package for iterators, 61897 ↗](https://github.com/golang/go/issues/61897); [slices, 61899 ↗](https://github.com/golang/go/issues/61899); [maps, 61900 ↗](https://github.com/golang/go/issues/61900); [bytes, strings: iterator forms, 61901 ↗](https://github.com/golang/go/issues/61901); [x/exp/xiter: iterator adapters, 61898 ↗](https://github.com/golang/go/issues/61898) — declined, which is why there is no standard `Filter`; [regexp: iterator forms of matching methods, 61902 ↗](https://github.com/golang/go/issues/61902) — open at the time of writing.
- The implementation: [`src/cmd/compile/internal/rangefunc/rewrite.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/cmd/compile/internal/rangefunc/rewrite.go), whose doc comment walks through the rewrite of `break`, `continue`, `return`, `goto` and `defer`; [`src/iter/iter.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/iter/iter.go) for `Pull`; [`src/runtime/coro.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/runtime/coro.go) for the coroutine switch; [`src/runtime/panic.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/runtime/panic.go) for the `range function …` messages.

## Books

None of these covers range over a function; they are listed for the parts they do cover — the `for-range` statement as it was, closures, and the deferred calls an iterator's cleanup is made of.

- Jon Bodner, *Learning Go*, 2nd ed. (O'Reilly, 2024) — chapter 4, "Blocks, Shadows, and Control Structures": "The for-range Statement" (with "Iterating over maps", the map-order randomization, and "Iterating over strings") and "Choosing the Right for Statement"; chapter 5, "Functions": "Closures", "Passing Functions as Parameters" and "Returning Functions from Functions"; chapter 7, "Types, Methods, and Interfaces": "Function Types Are a Bridge to Interfaces".
- Alan A. A. Donovan and Brian W. Kernighan, *The Go Programming Language* (Addison-Wesley, 2015) — chapter 5, "Functions": 5.5 "Function Values", 5.6 "Anonymous Functions", 5.8 "Deferred Function Calls", 5.9 "Panic" and 5.10 "Recover".
- Adam Freeman, *Pro Go* (Apress, 2022) — chapter 6, "Flow Control": "Enumerating Sequences"; chapter 9, "Using Function Types": "Using Functions as Arguments", "Using Functions as Results" and "Understanding Function Closure".
- Miki Tebeka, *Effective Go Recipes* (Pragmatic, 2024) — chapter 5, "Working with Functions": recipe 28 "Using Closures to Provide Options with Defaults" and recipe 29 "Passing Notifications with Functions" — callbacks, which is what `yield` is.
- *Go in Practice*, 2nd ed. (Manning, 2025) — chapter 3, "Structs, interfaces, and generics", the passage on functional style and passing functions as values; its 2025 date notwithstanding, it does not use `iter`.
- Katherine Cox-Buday, *Concurrency in Go* (O'Reilly, 2017) — chapter 4, "Concurrency Patterns in Go": the "Pipelines" section and its generator stage, the goroutine-and-channel shape that [An iterator is lazy](../an_iterator_is_lazy/README.md) compares with.

### Not on the shelf

- Teiva Harsanyi, *100 Go Mistakes and How to Avoid Them* (Manning, 2022) — [100go.co ↗](https://100go.co/); predates iterators, and its loop and closure mistakes still apply to the loop body.
- Bartłomiej Płotka, *Efficient Go* (O'Reilly, 2022) — [the publisher's page ↗](https://www.oreilly.com/library/view/efficient-go/9781098105709/); for the benchmark discipline the planned iterator benchmarks would follow.

## Talks and videos

- Ian Lance Taylor, "Range Over Function Types", GopherCon 2024 (Chicago) — the talk the [blog post ↗](https://go.dev/blog/range-functions) of the same title was written from; the post is the citable form.
- Takuya Ueda, "What is the iterator and how does it build an ecosystem in Go?", GopherDay Taiwan 2024 — [session page ↗](https://gopherday.golang.tw/2024/en/sessions/what-is-the-iterator-and-how-does-it-build-an-ecosystem-in-go/).

## Read with care

- **Any statement that `for-range` works only on built-in types** — *Learning Go*'s chapter 4 says a for-range loop iterates only the built-in compound types and user-defined types based on them, true for its Go 1.20 and wrong since 1.23.
- **Pre-1.23 "iterator pattern" advice**: a `Next() bool` / `Value()` pair on a struct, a channel fed by a goroutine, or a callback with no `bool` result. All still work; the first two are what `iter.Pull` and a `Seq` replace, and the third cannot be ranged over ([yield func does not return bool](../iterators_compiler_errors/README.md)).
- **Articles from the Go 1.22 experiment** (`GOEXPERIMENT=rangefunc`, late 2023 to mid-2024) — the semantics shipped as designed, but package names, the `xiter` adapters and some runtime messages in those posts differ from what 1.23 shipped.
- **Claims that `strings.Lines` or `SplitSeq` can be ranged twice** — they are documented single-use, and [`slices` and `maps` have iterators](../slices_and_maps_have_iterators/README.md) prints the empty second pass.
- **The `defer`-in-the-body rule stated without qualification** — correct as the wiki states it, and the fence in [`break` makes `yield` return false](../break_makes_yield_return_false/README.md) shows go1.25.5 breaking it for an inlined function literal.

*Checked 2026-09-23.*
