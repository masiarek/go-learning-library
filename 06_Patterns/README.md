# 06 — Patterns

The chapters before this one cover the parts: goroutines, channels, `select`, the `sync` package and `context`. This chapter puts them together into the shapes Go programs are built from: a chain of stages, a split and a merge, a pool, a limit, and a group that fails as one. Each of these shapes has to settle two questions, and each lesson shows how: in what order do the results come out, and how does everything stop?

Every program here has a nondeterministic middle and a deterministic answer. The goroutines run in whatever order the scheduler picks. The pattern decides the order of the report, by sorting, by indexing, or by forcing it with a barrier, and the answer key records only that. Where an order really does vary from run to run, the lesson shows real runs and says so.

| Lesson | The one thing |
|---|---|
| [A pipeline of stages](a_pipeline_of_stages/README.md) | Each stage closes the channel it owns. A canceled context lets the stages upstream of a reader that stopped early return, instead of blocking on their sends for good. |
| [Fan-out, fan-in](fan_out_fan_in/README.md) | Several goroutines share one input channel, and a merge closes one output channel after a `WaitGroup` sees every copy finish. The order is lost, so sort. |
| [A worker pool](a_worker_pool/README.md) | A job that carries its index puts its result back in input order. Shut down by closing the jobs, waiting for the workers, then closing the results. |
| [A buffered channel as a semaphore](a_buffered_channel_as_a_semaphore/README.md) | `make(chan struct{}, n)` lets at most `n` goroutines in at once, and exactly `n` when a barrier holds them there. |
| [The first error cancels the rest](first_error_cancels_the_rest/README.md) | `errgroup` from the standard library: the first error cancels a shared context, with itself as the cause, and is the error `Wait` returns. |

## Planned

- **Rate limiting with a ticker**: a `time.Ticker` spacing out calls, checked in virtual time ([synctest makes time virtual](../07_Testing_Concurrent_Code/synctest_makes_time_virtual/README.md)).
- **Publish and subscribe**: one publisher, a channel per subscriber, and what to do about a slow subscriber.
- **Deduplicating calls, `singleflight`-style**: one call in flight per key, with every other caller for that key waiting for its result.
- **The or-done, tee and bridge channels**: the channel-wrapping helpers from chapter 4 of Katherine Cox-Buday's *Concurrency in Go*.
- **A limit and a first error together**: the semaphore and the error group combined, as errgroup's `SetLimit` does.
