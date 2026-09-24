# 11 — Interfaces and method sets

An interface in Go is satisfied by whatever has its methods, and nothing is declared: the compiler checks the method set of the concrete type against the interface wherever a value crosses from one to the other. That rule is short, and everything surprising about interfaces follows from it — why `*T` satisfies an interface that `T` does not, why an embedded type's method cannot see the outer type, why an `error` holding a nil pointer is not `nil`, why boxing an `int` allocates but boxing a pointer does not, and what a type assertion checks at run time. This chapter measures each of those on Go 1.25, with the compiler's and the runtime's exact messages recorded.

It builds on the first chapters only lightly: [A mutex guards a counter](../04_Sync/a_mutex_guards_a_counter/README.md) is the lock that the vet page's `copylocks` entry is about, and [The race detector](../07_Testing_Concurrent_Code/the_race_detector/README.md) shows the shape of a driver that makes a throwaway module. The reader should know what a method and an interface are — the Tour's [Methods and interfaces ↗](https://go.dev/tour/methods/1) is enough — and should have met [Generics](../09_Generics/README.md), whose constraints are interfaces read as type sets.

| Lesson | The one thing |
|---|---|
| [A pointer receiver changes the method set](a_pointer_receiver_changes_the_method_set/README.md) | `*T` has every method and `T` only the value-receiver ones; `v.M()` on a variable is `(&v).M()`, but a map element or a value in an interface has no address, and the compiler says so |
| [Embedding is not inheritance](embedding_is_not_inheritance/README.md) | an embedded type's methods are promoted, not overridden: `Account.Describe` calling `a.Name()` reaches `Account.Name`, whatever the outer type defines; two embedded `Name`s are an ambiguous selector, and an embedded nil interface panics when its missing method is called |
| [A nil pointer in an interface is not nil](a_nil_pointer_in_an_interface_is_not_nil/README.md) | returning a `*ValidationError` variable as an `error` makes `err != nil` true even when the pointer is nil; `%v` prints `<nil>` anyway; return a literal `nil` |
| [An interface is two words](an_interface_is_two_words/README.md) | `unsafe.Sizeof` says 16: a type word and a data word; boxing copies the value to the heap except for integers 0–255, empty and zero-size values, and pointers — measured with `testing.AllocsPerRun` |
| [A type assertion asks the dynamic type](type_switches_and_assertions/README.md) | `v, ok := x.(T)` answers; `x.(T)` panics with `interface conversion: interface {} is string, not int`; asserting to an interface checks the method set at run time; a multi-type case keeps the interface type; `switch v := x.(type)` shadows |

| Companion | What it holds |
|---|---|
| [Interfaces: the compiler errors](interfaces_compiler_errors/README.md) | eight refusals with the Go 1.25 wording: pointer receiver, missing and wrongly typed methods, an undefined method on the interface's static type, ambiguous selectors, impossible assertions, type-switch mistakes, invalid receiver types, and `need type assertion` |
| [Interfaces: what go vet and gofmt catch](interfaces_vet_and_lints/README.md) | `ifaceassert`, `stdmethods`, `composites`, `copylocks`, and `-gcflags=-m` as the lens on boxing — and the typed-nil error, the accidental value receiver and the oversized interface, which no tool catches |
| [Interfaces: resources](interfaces_resources/README.md) | the spec sections, the FAQ entry on nil errors, Russ Cox's "Go Data Structures: Interfaces", the books by chapter and section, three talks, and what to read with care |

## Planned

- **Method values and method expressions**: `c.Increment` as a `func()` that has already bound its receiver, `(*Counter).Increment` as a `func(*Counter)`, and what each copies.
- **Interfaces and generics side by side**: when a type parameter with a constraint replaces an interface parameter, and when it cannot (a heterogeneous slice), measured on the same program in both shapes.
- **`sync.Mutex` inside an interface**: the `copylocks` entry stops at the value receiver; the story of a lock held through an interface value belongs with `04_Sync`.
- **Comparable interfaces in map keys**: `map[any]int` with a slice as a key panics at insertion, not at declaration — the same run-time check as `==` on this chapter's two-words page, in a setting of its own.
