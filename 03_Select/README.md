# 03 — Select

A goroutine with one channel to wait on just receives. Once it has two things to wait for, such as two inputs, an input and a clock, or work and a cancellation, it needs `select`: one statement that waits on several channel operations and carries out whichever can go first. Most of Go's concurrency patterns rest on it.

The four lessons are the rules that decide what `select` does. It waits until a case can proceed, and `default` lets it not wait at all. When several cases can proceed, it picks one at random. A timer is just another channel. And a nil channel is a case that can never proceed, which makes it an off switch.

| Lesson | The one thing |
|---|---|
| [`select` waits on many channels](select_waits_on_many/README.md) | it blocks until one case can proceed and does only that one; `default` makes it never block |
| [`select` chooses at random](select_chooses_at_random/README.md) | case order is not a priority; priority is a non-blocking check of the urgent channel first |
| [A timeout is a channel](a_timeout_is_a_channel/README.md) | `time.After`, a `Timer` and a `Ticker` are channels, so time is one more case |
| [A nil channel disables a case](a_nil_channel_disables_a_case/README.md) | a case on a nil channel never proceeds, so setting the variable to `nil` switches it off |

## Planned

- **`break` leaves the `select`, not the loop** — the `for`-`select` loop, why a bare `break` inside a case does not end it, and the labelled `break` or `return` that does.
- **Reset a timer instead of making a new one** — an idle timeout that restarts on every message, with `Timer.Reset` and the guarantees it has had since Go 1.23.
- **A `select` over channels known only at run time** — `reflect.Select`, for when the number of cases is not known until the program runs.
