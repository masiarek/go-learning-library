# Errors: resources

**Level:** 201 · anyone who wants the primary sources behind this chapter, and the book chapters that cover them

**One line:** Everything in this chapter is Go 1.13's `%w`, `errors.Is`, `errors.As` and `errors.Unwrap`, plus Go 1.20's `errors.Join` and multiple `%w`; the sources below are where those were specified, explained and argued over, and the book sections that teach them.

## Primary sources

- [Package `errors` ↗](https://pkg.go.dev/errors) — the definition of wrapping (`Unwrap() error`, `Unwrap() []error`), the tree that `Is` and `As` walk, and the `Is`/`As` methods a type may add; [`fmt.Errorf` ↗](https://pkg.go.dev/fmt#Errorf) — `%w`, and what more than one `%w` returns.
- [Working with Errors in Go 1.13 ↗](https://go.dev/blog/go1.13-errors), the Go blog — the "Whether to Wrap" section is the one to read twice; it settles that wrapping is an API decision.
- [Errors are values ↗](https://go.dev/blog/errors-are-values), Rob Pike (2015) — why `if err != nil` is not the whole story, and the `errWriter` pattern for checking once at the end.
- [Error handling and Go ↗](https://go.dev/blog/error-handling-and-go), Andrew Gerrand (2011) — the original explanation of `error` as an interface and of custom error types.
- [Error Values ↗](https://go.googlesource.com/proposal/+/master/design/29934-error-values.md), the design document, and [proposal #29934 ↗](https://github.com/golang/go/issues/29934) — where `%w`, `Is` and `As` were designed, and what was dropped on the way (the `xerrors` frame and formatting parts).
- The [Go 1.13 release notes ↗](https://go.dev/doc/go1.13#error_wrapping) and the [Go 1.20 release notes ↗](https://go.dev/doc/go1.20#errors) — the two releases this chapter measures.
- The [Error Value FAQ ↗](https://go.dev/wiki/ErrorValueFAQ) on the Go wiki — how to migrate `==` and type assertions, and how a package that returns wrapped errors should document them.
- [Code Review Comments: Error Strings ↗](https://go.dev/wiki/CodeReviewComments#error-strings) and [Effective Go: Errors ↗](https://go.dev/doc/effective_go#errors) — the message conventions.
- The source, for the exact panics and formats: [`errors/wrap.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/errors/wrap.go), [`errors/join.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/errors/join.go), [`fmt/errors.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/fmt/errors.go), all at go1.25.5.
- The `go vet` analyzers this chapter runs: [`printf` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/printf), [`errorsas` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/errorsas), [`unusedresult` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/unusedresult), [`stdmethods` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/stdmethods).

## Books

- Jon Bodner, *Learning Go*, 2nd ed. (O'Reilly, 2024), chapter 9, "Errors" — "How to Handle Errors: The Basics", "Use Strings for Simple Errors", "Sentinel Errors", "Errors Are Values", "Wrapping Errors", "Wrapping Multiple Errors", "Is and As", "Wrapping Errors with defer", "panic and recover", "Getting a Stack Trace from an Error". The most complete treatment on the shelf, and the only one that covers `errors.Join`.
- Alan A. A. Donovan and Brian W. Kernighan, *The Go Programming Language* (Addison-Wesley, 2015), section 5.4, "Errors" — 5.4.1 "Error-Handling Strategies", 5.4.2 "End of File (EOF)" — section 7.8, "The error Interface", and section 7.11, "Discriminating Errors with Type Assertions". Written before `%w`: the strategies and the `io.EOF` discussion hold, the type assertions in 7.11 are what `errors.As` replaced.
- Nathan Kozyra, Matt Butcher and Matt Farina, *Go in Practice*, 2nd ed. (Manning, 2025), chapter 4, "Handling errors and panics" — 4.1 "Error handling" (with "Nil best practices", "Custom error types" and "Error variables"), 4.2 "Wrapping errors", 4.3 "The panic system".
- Adam Freeman, *Pro Go* (Apress, 2022), chapter 15, "Error Handling" — "Dealing with Recoverable Errors", "Generating Errors", "Reporting Errors via Channels", "Using the Error Convenience Functions", "Dealing with Unrecoverable Errors", "Recovering from Panics".
- Miki Tebeka, *Effective Go Recipes* (Pragmatic Bookshelf, 2024), chapter 8, "Working with Errors" — Recipe 42 "Handling and Returning Errors", Recipe 45 "Checking Errors", Recipe 46 "Wrapping Errors" (an error type with `Unwrap`, and `errors.Join` collecting goroutine failures).
- Katherine Cox-Buday, *Concurrency in Go* (O'Reilly, 2017), chapter 4, "Concurrency Patterns in Go" — the section "Error Handling": who should handle an error that a goroutine produced, and the result-plus-error struct sent on a channel.
- Burak Serdar, *Effective Concurrency in Go* (Packt, 2023), chapter 6, "Error Handling" — "Error handling", "Pipelines", "Servers", "Panics": errors crossing goroutine boundaries.

### Not on the shelf

- Teiva Harsanyi, *100 Go Mistakes and How to Avoid Them* (Manning, 2022) — its chapter on error management covers `%w` vs `%v`, comparing errors with `==`, `errors.As` targets, and handling an error once; the mistakes are listed at [100go.co ↗](https://100go.co/).

## Talks and videos

- Marwan Sulaiman, [Handling Go Errors ↗](https://www.youtube.com/watch?v=4WIhhzTTd0Y), GopherCon 2019 — programmable errors: designing error types so that the layers of a system can tell failures apart; [slides ↗](https://github.com/gophercon/2019-talks/blob/master/MarwanSulaiman-HandlingGoErrors/handling-go-errors.pdf).
- Dave Cheney, "Don't just check errors, handle them gracefully", GopherCon 2016 — the talk's text is his [blog post of the same name ↗](https://dave.cheney.net/2016/04/27/dont-just-check-errors-handle-them-gracefully): sentinel errors, error types, opaque errors, and "handle an error once".

## Read with care

- Dave Cheney's [post above ↗](https://dave.cheney.net/2016/04/27/dont-just-check-errors-handle-them-gracefully) and anything else built on [`github.com/pkg/errors` ↗](https://github.com/pkg/errors): the advice stands, but `errors.Wrap` is `fmt.Errorf("…: %w", err)` now, `errors.Cause` is a loop over `errors.Unwrap`, and the package is in maintenance mode — [Errors: the compiler errors](../errors_compiler_errors/README.md) records what happens when the old names are typed.
- *The Go Programming Language*, section 7.11 — a type switch on an error is correct only for an error that was never wrapped; after `%w`, `errors.As`.
- Pre-1.20 advice that "Go has no way to hold several errors" and points at `go.uber.org/multierr` or `hashicorp/go-multierror` — `errors.Join` covers the common case, and both packages now build on it.
- Any page that says `errors.Is` "compares error messages" — it compares values, and a message match is exactly what it does not do; [`%w` wraps and `errors.Is` sees through it](../wrap_with_w_unwrap_with_is/README.md).
- `golang.org/x/xerrors` — the prototype for Go 1.13; its `%+v` frames and `xerrors.Errorf` did not make it into the standard library, and the package says to use `errors` and `fmt` instead.

*Checked 2026-09-23.*
