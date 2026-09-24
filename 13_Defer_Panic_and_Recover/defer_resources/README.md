# Defer, panic and recover: resources

**Level:** 201 · anyone who wants the primary sources behind this chapter, and the books that cover it

**One line:** The spec's three short sections say almost everything; the blog post from 2010 says it with examples; the release notes for 1.14, 1.21 and 1.25 hold the three changes that matter.

## Primary sources

- [The Go specification, Defer statements ↗](https://go.dev/ref/spec#Defer_statements) — arguments evaluated at the `defer`, last in, first out, named results modifiable, and which expressions may be deferred.
- [Handling panics ↗](https://go.dev/ref/spec#Handling_panics) — `panic` and `recover`, and the two conditions under which `recover` returns nil.
- [Run-time panics ↗](https://go.dev/ref/spec#Run_time_panics) — a run-time error panics with a value that implements `runtime.Error`.
- [Terminating statements ↗](https://go.dev/ref/spec#Terminating_statements) — why a function may end in `panic` and not in a call to a function that panics.
- [`panic` ↗](https://pkg.go.dev/builtin#panic) and [`recover` ↗](https://pkg.go.dev/builtin#recover) in package `builtin`.
- [`runtime.Goexit` ↗](https://pkg.go.dev/runtime#Goexit), [`runtime.Error` ↗](https://pkg.go.dev/runtime#Error), [`runtime.PanicNilError` ↗](https://pkg.go.dev/runtime#PanicNilError), and the [`runtime` environment variables ↗](https://pkg.go.dev/runtime#hdr-Environment_Variables) for `GOTRACEBACK`.
- [`os.Exit` ↗](https://pkg.go.dev/os#Exit) — deferred functions are not run; [`log.Fatal` ↗](https://pkg.go.dev/log#Fatal) — `Print` followed by `os.Exit(1)`.
- [*Defer, Panic, and Recover* ↗](https://go.dev/blog/defer-panic-and-recover) — Andrew Gerrand, the Go blog, 2010: the three rules of `defer` and the `recover` example this chapter's first three lessons follow.
- [Effective Go, Defer ↗](https://go.dev/doc/effective_go#defer), [Panic ↗](https://go.dev/doc/effective_go#panic) and [Recover ↗](https://go.dev/doc/effective_go#recover) — the `trace`/`un` idiom, the advice against panicking in a library, and the `regexp` package's `recover` around its parser.
- [Go 1.14 release notes, Runtime ↗](https://go.dev/doc/go1.14#runtime) — `defer` at almost zero overhead; and the design document [*Low-cost defers through inline code, and extra funcdata to manage the panic case* ↗](https://go.googlesource.com/proposal/+/master/design/34481-opencoded-defers.md) — the limits (eight defers, none in a loop) and the measurements.
- [Go 1.19 release notes, os ↗](https://go.dev/doc/go1.19#os) — the open-file soft limit raised to the hard limit at startup, which lets a loop of deferred `Close` calls run further before it fails.
- [Go 1.21 release notes, Changes to the language ↗](https://go.dev/doc/go1.21#language) — `panic(nil)` becomes a `*runtime.PanicNilError`; `GODEBUG=panicnil=1`.
- [Go 1.25 release notes, Runtime ↗](https://go.dev/doc/go1.25#runtime) — `[recovered, repanicked]` replaces the repeated panic text.
- [`go vet` ↗](https://pkg.go.dev/cmd/vet) and the analyzers this chapter runs: [`lostcancel` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/lostcancel), [`unreachable` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/unreachable), [`unusedresult` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/unusedresult), [`copylocks` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/copylocks).
- Outside the distribution, named on the vet page and not run: staticcheck [SA5001 ↗](https://staticcheck.dev/docs/checks/#SA5001) and [SA9001 ↗](https://staticcheck.dev/docs/checks/#SA9001), revive's [`defer` rule ↗](https://github.com/mgechev/revive/blob/master/RULES_DESCRIPTIONS.md#defer), go-critic's [`deferInLoop` ↗](https://go-critic.com/overview#deferinloop), [errcheck ↗](https://github.com/kisielk/errcheck).

## Books

- Alan A. A. Donovan and Brian W. Kernighan, *The Go Programming Language* (Addison-Wesley, 2015), chapter 5, "Functions" — sections 5.8, "Deferred Function Calls" (the loop-of-files case and the helper fix, deferred closures and named results), 5.9, "Panic", and 5.10, "Recover" (recovering selectively, by a private panic type).
- Jon Bodner, *Learning Go*, 2nd ed. (O'Reilly, 2024), chapter 5, "Functions" — the section "defer"; chapter 9, "Errors" — the section "panic and recover".
- Matt Butcher, Matt Farina and Nathan Kozyra, *Go in Practice*, 2nd ed. (Manning, 2025), chapter 4, "Handling errors and panics" — section 4.3, "The panic system": "Differentiating panics from errors", "Working with panics", "Recovering from panics", "Capturing panics with defer" and "Handling panics on goroutines".
- Adam Freeman, *Pro Go* (Apress, 2022), chapter 8, "Defining and Using Functions" — "Using the defer Keyword"; chapter 15, "Error Handling" — "Dealing with Unrecoverable Errors": "Recovering from Panics", "Panicking After a Recovery" and "Recovering from Panics in Go Routines".
- Miki Tebeka, *Effective Go Recipes* (Pragmatic Bookshelf, 2024), chapter 8, "Working with Errors" — Recipe 43, "Handling Panics", and Recipe 44, "Handling Panics in Goroutines".
- Katherine Cox-Buday, *Concurrency in Go* (O'Reilly, 2017), and James Cutajar, *Learn Concurrent Programming with Go* (Manning, 2024), use `defer` throughout and have no section on it; for a panic inside a goroutine, [A panic ends the whole program](../../01_Goroutines/a_panic_ends_the_whole_program/README.md) is this library's page.

### Not on the shelf

- Teiva Harsanyi, *100 Go Mistakes and How to Avoid Them* (Manning, 2022) — [100go.co ↗](https://100go.co/) — several of its mistakes are this chapter's lessons: how `defer` arguments and receivers are evaluated, `defer` in a loop, an ignored `Close` error.
- Bartłomiej Płotka, *Efficient Go* (O'Reilly, 2022) — [efficientgo.com ↗](https://www.efficientgo.com/) — for measuring what a `defer` costs rather than assuming it.

## Talks and videos

- Dave Cheney, "Don't just check errors, handle them gracefully" — GoCon Spring 2016, Tokyo; the text is on his blog, [dave.cheney.net ↗](https://dave.cheney.net/2016/04/27/dont-just-check-errors-handle-them-gracefully): why a library returns errors rather than panicking, and how to wrap them.
- No GopherCon talk devoted to `defer` itself is listed here; the design document above is the primary account of open-coded defers, and its authors' measurements are the ones to cite.

## Read with care

- **"`defer` is slow, keep it out of hot paths."** True before Go 1.14, when a deferred call cost an allocation and tens of nanoseconds; since then most defers are open-coded and the advice is stale — [What a `defer` costs](../deferred_calls_run_last_in_first_out/README.md#what-a-defer-costs). A `defer` in a loop is still heap-allocated.
- **"`recover()` returns nil for `panic(nil)`, so you cannot tell it from no panic."** True before Go 1.21; now `panic(nil)` recovers as a `*runtime.PanicNilError` unless the module's `go` line is 1.20 or earlier — [`recover` works only in the deferred call](../recover_only_in_the_deferred_call_itself/README.md).
- **Panic output in older books and posts** shows `panic: X [recovered]` and then `panic: X` on a second line; Go 1.25 prints `panic: X [recovered, repanicked]`.
- **`defer recover()`** turns up in forum answers as a one-liner; it compiles and does nothing.
- **`recover` in `main` as a safety net** for the whole program covers `main`'s goroutine only — [A panic ends the whole program](../../01_Goroutines/a_panic_ends_the_whole_program/README.md).
- **Pro Go's section "Deferring Execution of a Function"** (chapter 19, "Dates, Times, and Durations") is about `time.AfterFunc`, not `defer`; the `defer` section is the one in chapter 8.

*Checked 2026-09-23.*
