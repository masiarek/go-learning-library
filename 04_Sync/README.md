# 04 — The sync package

Channels are for goroutines that hand each other work and results. The `sync` package is for the other case: several goroutines reading and writing the same variable. The [Go memory model ↗](https://go.dev/ref/mem) states the rule in one sentence: a program whose goroutines modify data that others are accessing at the same time must serialize that access, with channel operations or with the primitives in `sync` and `sync/atomic`. This chapter covers those primitives and the rules that come with each.

A mutex is often the simpler choice. A counter, a cache, or a struct that goroutines read and update is *state*. The [Go wiki ↗](https://go.dev/wiki/MutexOrChannel) lists state and caches under the mutex. Passing ownership of data, handing out work and delivering results go under channels. Its advice is to use whichever is more expressive or simpler. A `Mutex` around three lines beats a goroutine that owns a map plus a channel protocol to reach it. If the locking rules grow too tangled to keep in your head, that is when to reconsider channels.

| Lesson | The one thing |
|---|---|
| [A mutex guards a counter](a_mutex_guards_a_counter/README.md) | goroutines adding to one `int` lose increments; with a `sync.Mutex` around the increment they lose none |
| [Atomic counters](atomic_counters/README.md) | `atomic.Int64` counts exactly with no lock, and `CompareAndSwap` lets exactly one goroutine win |
| [`sync.Once` runs exactly once](once_runs_exactly_once/README.md) | ten simultaneous callers, one run; a panic is forgotten by `Once` and repeated by `OnceFunc` |
| [A WaitGroup counts goroutines](a_waitgroup_counts_goroutines/README.md) | `Add` goes before the `go` statement, because an `Add` inside the goroutine can come after `Wait` has returned |

A struct holding a `Mutex` passed by value is what `go vet`'s `copylocks` reports; the transcript is on [Interfaces: what go vet and gofmt catch](../11_Interfaces_and_Method_Sets/interfaces_vet_and_lints/README.md).

## Planned

- **`sync.RWMutex`**: many readers or one writer, and how to tell whether that beats a plain `Mutex` for a given workload.
- **`sync.Cond`**: waiting for a condition, and the channel that usually replaces it.
- **`sync.Map`**: the two access patterns it is built for, and a map with a `Mutex` for everything else.
- **`sync.Pool`**: reusing allocations the garbage collector is free to discard.
