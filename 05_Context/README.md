# 05 — Context

Nothing outside a goroutine can stop it. A `go` statement hands back no handle ([A goroutine has no handle](../01_Goroutines/a_goroutine_has_no_handle/README.md)), so a caller that wants work to stop has to ask, and the goroutine has to listen. `context.Context` is Go's standard way of asking. It carries a `Done` channel that is closed when the work should stop, an `Err` that says why, and sometimes a deadline, and it is passed down as the first argument of every function on a request's path. The package has been in the standard library since [Go 1.7 ↗](https://go.dev/doc/go1.7#context).

The four lessons follow one cancellation from start to finish. A single `cancel` reaches a whole tree of contexts. A deadline is the same cancel, fired by a clock. A cancel stops only a goroutine that is listening, and a goroutine whose caller has gone can wait forever. And `ctx.Err()` loses the reason for the cancel unless the reason is recorded as its cause.

| Lesson | The one thing |
|---|---|
| [One `cancel` reaches every goroutine](cancel_reaches_every_goroutine/README.md) | a cancel closes `Done` for the context and everything derived from it, never for its parent; call `cancel` on every path, and `go vet` checks that you do |
| [A deadline is a cancel with a clock](a_deadline_is_a_cancel_with_a_clock/README.md) | the time runs out, `Done` closes, and `Err` says `DeadlineExceeded`; a child can shorten its parent's deadline but never extend it |
| [A leaked goroutine never ends](a_leaked_goroutine_never_ends/README.md) | a goroutine blocked on a send its caller stopped waiting for stays blocked; a buffer of one or a `select` on `ctx.Done()` lets it finish |
| [Cancel with a cause](cancel_with_a_cause/README.md) | `ctx.Err()` says only "canceled"; `WithCancelCause` records why, and `context.Cause` reads the reason back from any context in the tree |

## Planned

- **`context.WithValue` is for request-scoped data only** — the package's rule that values carry data belonging to a request across API and process boundaries, not optional parameters, and why each key gets an unexported type of its own. The Rust library's stubs [Carrying the trace across a boundary ↗](https://masiarek.github.io/rust-learning-library/21_Observability/context_propagation/index.html) and [Instrumenting async code ↗](https://masiarek.github.io/rust-learning-library/21_Observability/instrumenting_async/index.html) are the same problem for a trace id, between processes and inside one.
- **`context.AfterFunc`** — Go 1.21's way to run a function once a context is canceled, for waking something that cannot `select` on `Done`, such as a `sync.Cond` wait.
- **`context.WithoutCancel`** — Go 1.21's context that points to its parent but is never canceled and has no deadline, for work that must finish after its request has gone.
- **A context is an argument, not a field** — the package's rule against storing a context in a struct, and the Go blog's [Contexts and structs ↗](https://go.dev/blog/context-and-structs).
- **`signal.NotifyContext`** — Ctrl-C as a cancel.
