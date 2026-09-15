# 08 — Resources

## The primary sources

Everything in this library can be checked against these. Where a page says what Go promises, it links one of them.

- [**The Go Programming Language Specification** ↗](https://go.dev/ref/spec) — *Go statements*, *Channel types*, *Send statements*, *Select statements*, *Program execution*.
- [**The Go Memory Model** ↗](https://go.dev/ref/mem) — what one goroutine may assume about another's writes, and which operations synchronize.
- Packages: [**`sync`** ↗](https://pkg.go.dev/sync), [**`sync/atomic`** ↗](https://pkg.go.dev/sync/atomic), [**`context`** ↗](https://pkg.go.dev/context), [**`testing/synctest`** ↗](https://pkg.go.dev/testing/synctest).
- [**Data Race Detector** ↗](https://go.dev/doc/articles/race_detector) — how `-race` works, what it costs, and its exit status.
- [**Effective Go: Concurrency** ↗](https://go.dev/doc/effective_go#concurrency) and the Go blog's [**Share Memory By Communicating** ↗](https://go.dev/blog/codelab-share) — the idiom behind chapters 02 and 06.
- [**Go Concurrency Patterns: Pipelines and cancellation** ↗](https://go.dev/blog/pipelines) — the source of [chapter 06](../06_Patterns/README.md)'s first lessons.
- [**Testing concurrent code with testing/synctest** ↗](https://go.dev/blog/synctest) and the [**Go 1.25 release notes** ↗](https://go.dev/doc/go1.25) — `synctest` and `WaitGroup.Go`.

## Books

On the shelf beside this library, and cited by chapter in the lessons:

- *Concurrency in Go: Tools and Techniques for Developers* — Katherine Cox-Buday (O'Reilly, 2017).
- *Learn Concurrent Programming with Go* — James Cutajar (Manning, 2024).
- *Effective Concurrency in Go* — Burak Serdar (Packt, 2023).
- *Learning Go: An Idiomatic Approach to Real-World Go Programming*, 2nd edition — Jon Bodner (O'Reilly, 2024).

The Concurrency library keeps a longer list of concurrency books for every language, with their chapters: [books ↗](https://masiarek.github.io/concurrency-learning-library/10_Resources/index.html#books).

## The same ideas in other languages

Each Go lesson's **In other languages** section links its counterparts. The Concurrency library's [concept map ↗](https://masiarek.github.io/concurrency-learning-library/11_Concepts/index.html) goes the other way: a page per idea — goroutine, channel, select, mutex, cancellation, pipeline, race detector — with the construct in each language, and a link back to the lesson here.
