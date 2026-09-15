# 02 — Channels

A channel carries values from one goroutine to another, and it is also where goroutines most often stop and wait: for a receiver, for room in a buffer, for a value that is never going to come. These lessons are about those waits — when a send returns, what a buffer buys, what `close` changes, and what the runtime says when every goroutine is waiting at once.

The programs do not rely on timing to show a goroutine waiting. They ask the runtime, which labels every parked goroutine with its reason — `[chan send]`, `[chan receive]` — in the same goroutine dump that a crash prints.

| Lesson | The one thing |
|---|---|
| [An unbuffered send waits for a receiver](an_unbuffered_send_waits_for_a_receiver/README.md) | a send on a channel with no buffer completes only when a receiver takes the value: a handshake |
| [A buffered channel is a bounded queue](a_buffered_channel_is_a_bounded_queue/README.md) | sends go through until the buffer is full and then wait, so a producer gets at most `cap` values ahead |
| [Closing a channel ends a range](closing_a_channel_ends_a_range/README.md) | `close` says "no more": receives drain the buffer, then return the zero value with `ok == false`, and a send after it panics |
| [All goroutines are asleep](all_goroutines_are_asleep/README.md) | the runtime reports a deadlock only when every goroutine is blocked, and one pending timer is enough to hide it |

## Planned

- **Send-only and receive-only channels** — `chan<- T` and `<-chan T` in a function's signature, and what each one stops the function from doing.
- **A channel of channels** — a request that carries its own reply channel, so that one goroutine can answer many callers.
- **Who owns a channel** — the goroutine that makes a channel sends on it and closes it, and every other goroutine gets a receive-only view.
