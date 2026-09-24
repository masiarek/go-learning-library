# Generics: resources

**Level:** 201 · anyone who wants the primary sources behind this chapter

**One line:** The spec sections, release notes, design documents, blog posts, books and talks that settle what this chapter claims about type parameters — and three sources to read with care.

## Primary sources

- [The Go Programming Language Specification ↗](https://go.dev/ref/spec) — [Type parameter declarations ↗](https://go.dev/ref/spec#Type_parameter_declarations), [Type constraints ↗](https://go.dev/ref/spec#Type_constraints), [General interfaces ↗](https://go.dev/ref/spec#General_interfaces) (unions, `~`, type sets as intersections), [Satisfying a type constraint ↗](https://go.dev/ref/spec#Satisfying_a_type_constraint) (the `comparable` exception), [Instantiations ↗](https://go.dev/ref/spec#Instantiations), [Type inference ↗](https://go.dev/ref/spec#Type_inference) and [Type unification ↗](https://go.dev/ref/spec#Type_unification), [Method declarations ↗](https://go.dev/ref/spec#Method_declarations). Since Go 1.25 the spec no longer uses the notion of a *core type*; the [1.25 release notes ↗](https://go.dev/doc/go1.25#changes-to-the-language) and the [*Goodbye core types* ↗](https://go.dev/blog/coretypes) post say what replaced it.
- [Type Parameters Proposal ↗](https://go.googlesource.com/proposal/+/refs/heads/master/design/43651-type-parameters.md) — Ian Lance Taylor and Robert Griesemer: the design, its [omissions ↗](https://go.googlesource.com/proposal/+/refs/heads/master/design/43651-type-parameters.md#omissions) (no specialization, no operator methods, no variadic type parameters) and [why methods may not take type arguments ↗](https://go.googlesource.com/proposal/+/refs/heads/master/design/43651-type-parameters.md#methods-may-not-take-additional-type-arguments).
- [Generics implementation - GC Shape Stenciling ↗](https://github.com/golang/proposal/blob/master/design/generics-implementation-gcshape.md) — how the compiler instantiates: one copy of the code per *GC shape* (size, alignment, pointer layout), with a dictionary for what differs within a shape. This is the claim "Go is neither C++ monomorphization nor Java erasure", and it is not machine-checked in this chapter.
- Release notes: [Go 1.18, *Generics* ↗](https://go.dev/doc/go1.18#generics) — the feature and the restrictions it shipped with; [Go 1.20, *Changes to the language* ↗](https://go.dev/doc/go1.20#language) — interfaces satisfy `comparable`; [Go 1.21, *Changes to the language* ↗](https://go.dev/doc/go1.21#language) — inference for generic functions as arguments and in assignments, untyped constants, and the `cmp`, `slices` and `maps` packages; [Go 1.24 ↗](https://go.dev/doc/go1.24#language) — generic type aliases.
- Packages: [`cmp` ↗](https://pkg.go.dev/cmp) (`Ordered`, `Compare`, `Less`, `Or`), [`slices` ↗](https://pkg.go.dev/slices), [`maps` ↗](https://pkg.go.dev/maps), [`iter` ↗](https://pkg.go.dev/iter) — the standard library's generic code, worth reading as models of constraints and signatures.
- The Go blog: Robert Griesemer and Ian Lance Taylor, [*An Introduction To Generics* ↗](https://go.dev/blog/intro-generics) (22 March 2022); Ian Lance Taylor, [*When To Use Generics* ↗](https://go.dev/blog/when-generics) (12 April 2022); Robert Griesemer, [*All your comparable types* ↗](https://go.dev/blog/comparable) (17 February 2023) and [*Everything You Always Wanted to Know About Type Inference - And a Little Bit More* ↗](https://go.dev/blog/type-inference) (9 October 2023).
- The Go FAQ, [*Generics* ↗](https://go.dev/doc/faq#generics) — nine entries, among them [why not methods with type parameters ↗](https://go.dev/doc/faq#generics_methods), [why the receiver cannot name a specific type ↗](https://go.dev/doc/faq#generics_receiver_type), [why inference stops where it does ↗](https://go.dev/doc/faq#generics_type_inference) and [how generics are implemented ↗](https://go.dev/doc/faq#generics_implementation).
- [golang/go#49085 ↗](https://github.com/golang/go/issues/49085) — the proposal issue to allow type parameters in methods, closed as a duplicate in April 2026; the rule stands.

## Books

- Jon Bodner, *Learning Go: An Idiomatic Approach to Real-World Go Programming*, 2nd ed. (O'Reilly, 2024), chapter 8, "Generics" — "Introducing Generics in Go" (a stack, and the zero value in `Pop`), "Generic Functions Abstract Algorithms", "Generics and Interfaces", "Use Type Terms to Specify Operators", "Type Inference and Generics", "Type Elements Limit Constants", "Combining Generic Functions with Generic Data Structures", "More on comparable", "Things That Are Left Out", "Idiomatic Go and Generics", "Adding Generics to the Standard Library". The most complete book treatment on the shelf, and current for Go 1.22.
- *Go in Practice*, 2nd ed. (Manning, 2025), chapter 3, "Structs, interfaces, and generics" — section 3.4, "Simplifying code with generics", with "Using functions with generics" and "Using constraints and type approximations".
- Miki Tebeka, *Effective Go Recipes: Fast Solutions to Common Tasks* (Pragmatic, 2024), chapter 7, "Working with Structs, Methods, and Interfaces" — Recipe 39, "Using Generics to Reduce Code Size"; Recipe 40, "Using Generics for Type-Safe Data Structures"; Recipe 41, "Using Generics for Better Type Safety".

### Not on the shelf

- Teiva Harsanyi, *100 Go Mistakes and How to Avoid Them* (Manning, 2022) — [publisher's page ↗](https://www.manning.com/books/100-go-mistakes-and-how-to-avoid-them); its mistakes on generics are about when not to use them.
- Bartłomiej Płotka, *Efficient Go* (O'Reilly, 2022) — [the book's example repository ↗](https://github.com/efficientgo/examples); on measuring costs, for readers of the GC-shape document who want to benchmark an instantiation.

## Talks and videos

- [GopherCon 2021: Generics! — Robert Griesemer and Ian Lance Taylor ↗](https://www.youtube.com/watch?v=Pa_e9EeCdy8) — the design as it shipped in 1.18, from its authors.
- [Go Day 2021 on Google Open Source Live: Using Generics in Go — Ian Lance Taylor ↗](https://www.youtube.com/watch?v=nr8EpUO9jhw) — the guidelines that became *When To Use Generics*.
- [GopherCon 2019: Generics in Go — Ian Lance Taylor ↗](https://www.youtube.com/watch?v=WzgLqE-3IhY) — the *contracts* draft; watch it for the reasoning, not the syntax, which changed before 1.18.

## Read with care

- Alan A. A. Donovan and Brian W. Kernighan, *The Go Programming Language* (Addison-Wesley, 2015) — written for Go 1.5, seven years before type parameters: its `sort.Interface` and `interface{}` idioms are how the same problems were solved without generics, and its chapter 7, "Interfaces", is still the best account of what a basic interface is. Nothing in it is wrong; nothing in it mentions `[T any]`.
- Adam Freeman, *Pro Go* (Apress, 2022) — covers Go 1.17 and has no generics at all, so its container and "any value" chapters solve with `interface{}` what this chapter solves with type parameters.
- The pre-1.18 design drafts — *contracts* (2018–2019), and code written against `golang.org/x/exp/constraints`: `constraints.Ordered` became [`cmp.Ordered` ↗](https://pkg.go.dev/cmp#Ordered) in Go 1.21, and the rest of that package (`Integer`, `Float`, `Signed`) never moved into the standard library.
- Anything that says an interface type cannot be a `comparable` type argument — true until Go 1.19, false since 1.20 ([Constraints are type sets](../constraints_are_type_sets/README.md)).
- Anything that says `slices.SortFunc(xs, cmp.Compare[string])` needs the explicit instantiation — true until Go 1.20, unnecessary since 1.21 ([Inference works from arguments, not results](../inference_works_from_arguments_not_results/README.md)).

*Checked 2026-09-23.*
