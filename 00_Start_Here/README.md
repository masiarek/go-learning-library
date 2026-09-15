# 00 — Start here

**Level:** 101 · read this first

This library is for someone who can read Go — functions, structs, slices, errors — and wants to understand what its concurrency actually does: why a goroutine's output never appeared, why a program hangs, why a count comes out short one run in ten, and what the standard library gives you to prevent each of those. If the syntax itself is new, [A Tour of Go ↗](https://go.dev/tour/) comes first.

## The seven to read first

1. [**`main` does not wait**](../01_Goroutines/main_does_not_wait/README.md) — the first surprise, and the `WaitGroup` that fixes it.
2. [**An unbuffered send waits for a receiver**](../02_Channels/an_unbuffered_send_waits_for_a_receiver/README.md) — a channel is a meeting as well as a pipe.
3. [**`select` chooses at random**](../03_Select/select_chooses_at_random/README.md) — case order is not a priority.
4. [**A mutex guards a counter**](../04_Sync/a_mutex_guards_a_counter/README.md) — the lost update, and when a lock beats a channel.
5. [**One `cancel` reaches every goroutine**](../05_Context/cancel_reaches_every_goroutine/README.md) — how a whole tree of work is stopped.
6. [**A worker pool**](../06_Patterns/a_worker_pool/README.md) — the pattern most programs end up needing.
7. [**The race detector**](../07_Testing_Concurrent_Code/the_race_detector/README.md) — the tool to run before trusting any of the above in your own code.

## How to read a page

Each page has the same shape: a **one-line** claim, an output block from the program in that page's `examples/` folder, **Reading the output**, **What to do**, **In other languages**, and **Sources**. The output blocks are generated, never typed: if a page shows a value, Go printed it, on both CI machines.

A fence titled **Real runs** is different. It shows something that changes from run to run — how many increments a race lost, the order goroutines finished in — counted on one machine on one date. It is not an answer key; the `demo/` script beside the page reproduces it on yours.

## Go's concurrency in one paragraph

A goroutine is a function call started with `go`; it costs a few kilobytes, so starting a hundred thousand is ordinary ([Goroutines are cheap](../01_Goroutines/goroutines_are_cheap/README.md)). It hands nothing back, so results travel on channels ([A goroutine has no handle](../01_Goroutines/a_goroutine_has_no_handle/README.md)). Channels synchronize as well as carry ([An unbuffered send waits for a receiver](../02_Channels/an_unbuffered_send_waits_for_a_receiver/README.md)), `select` waits on several of them, and `context` carries cancellation through all of it ([One `cancel` reaches every goroutine](../05_Context/cancel_reaches_every_goroutine/README.md)). When sharing memory is simpler, the `sync` package has the locks ([A mutex guards a counter](../04_Sync/a_mutex_guards_a_counter/README.md)) — and `go test -race` finds the places where neither was used ([The race detector](../07_Testing_Concurrent_Code/the_race_detector/README.md)).
