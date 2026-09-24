# Interfaces: resources

**Level:** 201 · anyone who wants the sources behind this chapter, by section

**One line:** The spec sections that define method sets, embedding, interface satisfaction and type assertions; the runtime and FAQ pages behind the two-word layout and the typed nil; the shelf books by chapter and section; three talks; and the advice that no longer holds.

## Primary sources

- The Go specification, [Method sets ↗](https://go.dev/ref/spec#Method_sets) — the rule everything else follows: `*T` gets both kinds of method, `T` only value receivers.
- The Go specification, [Method declarations ↗](https://go.dev/ref/spec#Method_declarations) — what may be a receiver type: a defined type of this package, not a pointer or an interface.
- The Go specification, [Calls ↗](https://go.dev/ref/spec#Calls) and [Address operators ↗](https://go.dev/ref/spec#Address_operators) — `x.m()` as `(&x).m()` when `x` is addressable, and the list of what is addressable.
- The Go specification, [Struct types ↗](https://go.dev/ref/spec#Struct_types) and [Selectors ↗](https://go.dev/ref/spec#Selectors) — embedded fields, promotion, depth, shadowing and the ambiguous selector.
- The Go specification, [Interface types ↗](https://go.dev/ref/spec#Interface_types) — basic interfaces, embedded interfaces, and the general interfaces (type sets) that Go 1.18 added for constraints.
- The Go specification, [Type assertions ↗](https://go.dev/ref/spec#Type_assertions), [Type switches ↗](https://go.dev/ref/spec#Type_switches) and [Comparison operators ↗](https://go.dev/ref/spec#Comparison_operators) — the run-time checks, and the panic on comparing uncomparable dynamic types.
- The Go FAQ, [Why is my nil error value not equal to nil? ↗](https://go.dev/doc/faq#nil_error) and [Should I define methods on values or pointers? ↗](https://go.dev/doc/faq#methods_on_values_or_pointers).
- [Effective Go ↗](https://go.dev/doc/effective_go) — "Interfaces and other types", "Embedding", and the `Stringer` and `sort.Interface` examples.
- Russ Cox, [Go Data Structures: Interfaces ↗](https://research.swtch.com/interfaces), 2009 — the two words, the itab and the method table; still the layout in [`runtime2.go` at go1.25.5 ↗](https://github.com/golang/go/blob/go1.25.5/src/runtime/runtime2.go).
- The runtime, [`iface.go` at go1.25.5 ↗](https://github.com/golang/go/blob/go1.25.5/src/runtime/iface.go) — the conversion functions and `staticuint64s`, the 256-entry table that spares small integers an allocation; and [`error.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/runtime/error.go) for `TypeAssertionError`'s three messages.
- Rob Pike, [The Laws of Reflection ↗](https://go.dev/blog/laws-of-reflection), the Go blog, 2011 — an interface variable as a (value, type) pair, from the reflection side.
- The [Go 1.18 release notes ↗](https://go.dev/doc/go1.18) — interfaces as type sets; the Generics chapter's [Constraints are type sets](../../09_Generics/constraints_are_type_sets/README.md) measures it.
- The Go wiki, [Go Code Review Comments ↗](https://go.dev/wiki/CodeReviewComments) — the sections "Interfaces" and "Receiver Type".
- The vet analyzers this chapter runs: [`ifaceassert` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/ifaceassert), [`stdmethods` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/stdmethods), [`composite` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/composite), [`copylock` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/copylock).

## Books

- Alan A. A. Donovan and Brian W. Kernighan, *The Go Programming Language* (Addison-Wesley, 2015) — chapter 6, "Methods": 6.2 "Methods with a Pointer Receiver", 6.3 "Composing Types by Struct Embedding", 6.4 "Method Values and Expressions"; chapter 7, "Interfaces": 7.3 "Interface Satisfaction", 7.5 "Interface Values" (with the caveat "An Interface Containing a Nil Pointer Is Non-Nil"), 7.6 "Sorting with sort.Interface", 7.10 "Type Assertions", 7.12 "Querying Behaviors with Interface Type Assertions", 7.13 "Type Switches". Still the most precise book treatment of method sets and interface values.
- Jon Bodner, *Learning Go*, 2nd ed. (O'Reilly, 2024) — chapter 7, "Types, Methods, and Interfaces": "Pointer Receivers and Value Receivers", "Code Your Methods for nil Instances", "Use Embedding for Composition", "Embedding Is Not Inheritance", "Interfaces Are Type-Safe Duck Typing", "Embedding and Interfaces", "Accept Interfaces, Return Structs", "Interfaces and nil", "Interfaces Are Comparable", "The Empty Interface Says Nothing", "Type Assertions and Type Switches", "Use Type Assertions and Type Switches Sparingly".
- Adam Freeman, *Pro Go* (Apress, 2022) — chapter 11, "Using Methods and Interfaces": "Understanding Pointer and Value Receivers", "Understanding the Effect of Pointer Method Receivers", "Comparing Interface Values", "Performing Type Assertions", "Switching on Dynamic Types", "Using the Empty Interface"; chapter 13, "Type and Interface Composition": "Composing Types", "Understanding When Promotion Cannot Be Performed", "Using Composition to Implement Interfaces", "Composing Interfaces".
- *Go in Practice*, 2nd ed. (Manning, 2025) — chapter 3, "Structs, interfaces, and generics": 3.3 "Extending functionality with interfaces"; chapter 13, on reflection: 13.1.2 "Discovering whether a value implements an interface" — the `reflect` view of the method-set check.
- Miki Tebeka, *Effective Go Recipes* (Pragmatic, 2024) — chapter 7, "Working with Structs, Methods, and Interfaces": Recipe 37, "Using Ad Hoc Interfaces", and Recipe 38, "Wrapping the http.ResponseWriter Interface" — the second is embedding an interface to override one method, the shape of this chapter's `sort.Reverse` kata.

### Not on the shelf

- Teiva Harsanyi, *100 Go Mistakes and How to Avoid Them* (Manning, 2022) — [100go.co ↗](https://100go.co/); its mistakes on interface pollution, returning interfaces, and the nil receiver in an interface cover this chapter's ground.
- Bartłomiej Płotka, *Efficient Go* (O'Reilly, 2022) — [the publisher's page ↗](https://www.oreilly.com/library/view/efficient-go/9781098105709/); the allocation cost of interfaces among its optimisations.

## Talks and videos

- Francesc Campoy, [Understanding nil ↗](https://www.youtube.com/watch?v=ynoY2xz-F8s), GopherCon 2016 — nil interfaces, typed nils, and methods on nil receivers.
- Rob Pike, [Go Proverbs ↗](https://www.youtube.com/watch?v=PAAkCSZUG1c), Gopherfest 2015 — "The bigger the interface, the weaker the abstraction", and the rest; the proverbs are collected at [go-proverbs.github.io ↗](https://go-proverbs.github.io/).
- Dave Cheney, [SOLID Go Design ↗](https://www.youtube.com/watch?v=zzAdEt3xZ1M), Golang UK Conference 2016 — small interfaces, embedding, and dependency inversion; the [written version ↗](https://dave.cheney.net/2016/08/20/solid-go-design) is on his blog.

## Read with care

- Pre-1.18 explanations of "the empty interface" as `interface{}` are right but dated: `any` is its alias since Go 1.18, and interfaces have had a second life as type sets since then — an interface with a type union can be a constraint only, not a variable's type ([A type parameter needs a constraint](../../09_Generics/a_type_parameter_needs_a_constraint/README.md)).
- Advice that interface method calls are "slow" in the abstract. The itab makes a call one indirection; what costs is the boxing on the way in, which is zero for pointers and small integers and one allocation for most other values — measured, not assumed, in [An interface is two words](../an_interface_is_two_words/README.md).
- Claims that `go vet` catches the typed-nil error. It does not, at go1.25; the [vet page](../interfaces_vet_and_lints/README.md#what-no-tool-catches) runs it and lists what does.
- Descriptions of embedding as "inheritance" or of promoted methods as "overridable". [Embedding is not inheritance](../embedding_is_not_inheritance/README.md) prints the call that inheritance would have dispatched the other way.
- Older tutorials that store a `sync.Mutex` in a struct and pass the struct by value, or give such a struct value-receiver methods; `go vet`'s `copylocks` reports every such copy, and the [vet page](../interfaces_vet_and_lints/README.md#copylocks-a-value-receiver-on-a-type-that-holds-a-lock) shows the message.

*Checked 2026-09-23.*
