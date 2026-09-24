# 12 — Errors

Go's `error` is an interface with one method, and until Go 1.13 that was the whole of it: a function returned an error, the caller printed it or compared it with a sentinel. Go 1.13 added a structure underneath — an error may *wrap* another, `fmt.Errorf`'s `%w` does it in one verb, and `errors.Is`, `errors.As` and `errors.Unwrap` walk the chain that results — and Go 1.20 turned the chain into a tree with `errors.Join` and multiple `%w`. This chapter measures that machinery on Go 1.25: what wraps, what does not, what `Is` and `As` find, where the panics are, and which design decisions (wrap or hide, sentinel or type) the tooling can and cannot check.

The reader should know that `error` is an interface and how a method set decides which type satisfies it — [11 — Interfaces and method sets](../11_Interfaces_and_Method_Sets/README.md) — and, for the goroutine side of errors, [A goroutine has no handle](../01_Goroutines/a_goroutine_has_no_handle/README.md), [Cancel with a cause](../05_Context/cancel_with_a_cause/README.md) and [The first error cancels the rest](../06_Patterns/first_error_cancels_the_rest/README.md), which this chapter links back to rather than repeats.

| Lesson | The one thing |
|---|---|
| [`%w` wraps and `errors.Is` sees through it](wrap_with_w_unwrap_with_is/README.md) | `%w` keeps the cause and `%v` prints it away; `errors.Is` finds a sentinel at any depth, `==` sees only the outer value, `Unwrap` takes one layer, and an `Is` method extends matching |
| [`errors.As` finds a type in the chain](errors_as_finds_a_type_in_the_chain/README.md) | `As` fills a pointer to the stored type — pointer or value, as the method set decides — through any wrapping; a wrong target panics with one of three recorded messages |
| [`errors.Join` holds many errors in one](errors_join_holds_many/README.md) | `Join` and a two-`%w` `Errorf` make a tree that `Is` and `As` search; `Error()` joins with newlines, a join of nils is nil, and `errors.Unwrap` does not look inside |
| [An error type wraps through `Unwrap`](an_error_type_with_unwrap/README.md) | `Unwrap() error` or `Unwrap() []error` on your own type; wrap when the cause is API, hide it with `%v` when it is a detail; lower case, no trailing stop |

| Companion | What it holds |
|---|---|
| [Errors: the compiler errors](errors_compiler_errors/README.md) | seven refusals recorded verbatim — unused `err`, missing return, need type assertion, `errors.Wrap`, a string as an error, `errors.New` with arguments, the wrong `Error` signature |
| [Errors: what go vet and gofmt catch](errors_vet_and_lints/README.md) | `printf`, `errorsas`, `unusedresult` and `stdmethods` on error code, run and recorded; the shadowed `err`, the typed nil, `==` on a wrapped sentinel and a cause lost to `%v` that no tool sees |
| [Errors: resources](errors_resources/README.md) | the package docs, the 1.13 blog post and design document, the release notes, the book chapters and sections, two talks, and what to read with care |

## Planned

- **Stack traces**: the standard `error` carries none; `runtime/debug.Stack` at the point of creation, and what `log/slog` does with an error value.
- **`errors.ErrUnsupported`** (Go 1.21) and the `As(any) bool` method a type may provide, so it can be treated as another type.
- **Errors in tests**: `t.Fatal` vs returning, `errors.Is` in assertions, and testing a package's documented sentinels.
- **Panics as errors**: converting a recovered panic into an `error` at an API boundary — after [13 — Defer, panic and recover](../13_Defer_Panic_and_Recover/README.md).
