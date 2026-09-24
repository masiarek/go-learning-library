# 13 — Defer, panic and recover

`defer` is how a Go function promises to do something on the way out — close the file, unlock the mutex, cancel the context — on every path out, a panic included. Its rules are few and each has a trap: the arguments are saved when the `defer` runs, not when the call does; the calls run last in, first out; a deferred closure can rewrite a named result; `recover` works only in the deferred function itself; and a `defer` in a loop waits for the function, not the iteration. Every lesson here measures one of those on Go 1.25, with the exit status wherever the program does not survive.

Read [A panic ends the whole program](../01_Goroutines/a_panic_ends_the_whole_program/README.md) first: it shows what a panic does to a program with goroutines and the deferred `recover` inside the goroutine that fixes it, and this chapter does not repeat it. [Wrap with `%w`, unwrap with `Is`](../12_Errors/wrap_with_w_unwrap_with_is/README.md) is the error wrapping this chapter's deferred closures do.

| Lesson | The one thing |
|---|---|
| [`defer` evaluates its arguments now](defer_evaluates_its_arguments_now/README.md) | `defer fmt.Println(x)` prints the `x` of the `defer` line, a closure prints the `x` at exit, and a value receiver is copied at the `defer` |
| [Deferred calls run last in, first out](deferred_calls_run_last_in_first_out/README.md) | releases run in the reverse of the acquires — on return, on a panic and on `Goexit`; `os.Exit` skips them; since Go 1.14 a plain `defer` is open-coded, and the compiler will say so |
| [A `defer` can change a named result](a_defer_can_change_a_named_result/README.md) | `return` sets the results, then the deferred closure runs: wrap the error once, recover into it, keep a `Close` error |
| [`recover` works only in the deferred call](recover_only_in_the_deferred_call_itself/README.md) | a helper's `recover` and `defer recover()` return nil; `panic(nil)` is a `*runtime.PanicNilError`; a run-time error is a `runtime.Error`; a re-panic exits 2 with `[recovered, repanicked]` |
| [A `defer` in a loop runs at function end](defer_in_a_loop_runs_at_function_end/README.md) | 1,000 deferred `Close` calls hold 1,000 files until the function returns, a helper per iteration holds one, and `go vet` says nothing |

| Companion | What it holds |
|---|---|
| [The compiler errors](defer_compiler_errors/README.md) | `expression in defer must be function call`, `defer discards result of append`, `recover (built-in) must be called`, `missing return` after a helper that panics — and the fixes |
| [What `go vet` and `gofmt` catch](defer_vet_and_lints/README.md) | `lostcancel`, `unreachable`, `unusedresult`, `copylocks` — and the mistakes no tool in the distribution catches, a nil `rows.Close()` among them |
| [Resources](defer_resources/README.md) | the spec sections, the 2010 blog post, the release notes for 1.14, 1.21 and 1.25, the books by chapter and section, and the advice that has gone stale |

## Planned

- **`debug.Stack` inside a `recover`**: logging the stack of the panic you caught, and what `GOTRACEBACK` changes about the one you did not.
- **`net/http`'s recovery of handler panics**, and `http.ErrAbortHandler` for the panic you want it to keep quiet about.
- **`t.FailNow` and `t.Cleanup`**: `testing`'s use of `runtime.Goexit`, and when a `Cleanup` beats a `defer` in a test.
- **Panics inside `sync.Once`**: [`sync.Once` runs exactly once](../04_Sync/once_runs_exactly_once/README.md) shows `Once` forgetting a panic; `OnceValue` and `OnceFunc` re-panicking is not covered here.
