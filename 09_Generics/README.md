# 09 — Generics

Go 1.18 added type parameters: a function or a type declared once for a set of types, checked once against a *constraint*, and instantiated for each type it is used with. This chapter is that feature measured on Go 1.25 — what a constraint grants, what a method may and may not declare, what inference reads and what it ignores, what a generic type's instantiations are called, and what an interface is when it is read as a set of types. Every rule is a program's output or a compiler's refusal, recorded.

It assumes the language from the first chapters — functions, methods, interfaces, maps — and nothing about concurrency. The standard library's own generic packages, `cmp`, `slices` and `maps`, appear throughout as the model to copy; iterators, which are generic functions of a particular shape, have a chapter of their own: [10 — Iterators](../10_Iterators/README.md).

| Lesson | The one thing |
|---|---|
| [A type parameter needs a constraint](a_type_parameter_needs_a_constraint/README.md) | under `any` a `T` can do nothing but be stored; `cmp.Ordered` unlocks `<`, `comparable` unlocks `==`, and a `~int` term admits every type built on `int` |
| [A method cannot have type parameters](a_method_cannot_have_type_parameters/README.md) | `Map[U]` on a `Stack[T]` is a syntax error; the transformation is a top-level function or a method on a second generic type, and the FAQ says why |
| [Inference works from arguments, not results](inference_works_from_arguments_not_results/README.md) | `Zero[int]()` must be written, `Map(names, Identity)` need not since 1.21, and a function value needs every type argument |
| [A generic type and its zero value](a_generic_type_and_its_zero_value/README.md) | `Stack[int]` and `Stack[string]` are two types, `%T` prints each with its argument, and `var zero T` is what an empty `Pop` returns |
| [Constraints are type sets](constraints_are_type_sets/README.md) | a union is a set, a method beside it narrows the set, a constraint is not a type, and `comparable` admits `any` at the price of a run-time panic |

| Companion | What it holds |
|---|---|
| [The compiler errors](generics_compiler_errors/README.md) | eight refusals, recorded from real builds, with the mistake and the fix |
| [What go vet and gofmt catch](generics_vet_and_lints/README.md) | `copylocks`, `printf`, `composites`, `stdversion` and `gofmt -s` on generic code — and the mistakes no tool catches |
| [Resources](generics_resources/README.md) | the spec, the proposal, the release notes, the blog posts, the books and the talks |

## Planned

- **What an instantiation costs**: the GC-shape stenciling design measured — a benchmark of a generic function against its hand-written copy and against an interface, and `go build -gcflags=-m` on a call through a dictionary.
- **Generic type aliases** (Go 1.24): `type Set[T comparable] = map[T]struct{}` and what an alias with type parameters can and cannot do.
- **Recursive constraints**: `[T interface{ Less(T) bool }]`, the shape of `sort`-style code with type parameters, and where it meets the no-generic-methods rule.
- **Type parameters on channels and functions**: a generic worker pool, and how the concurrency chapters' patterns change when the payload is a `T`.
