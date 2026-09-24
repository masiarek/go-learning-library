# Reflection and unsafe: resources

**Level:** 301 · where the claims on this chapter's pages come from, and what to read next

**One line:** The package docs and *The Laws of Reflection* settle almost every question; the release notes for 1.14, 1.17, 1.20, 1.21 and 1.25 are where the answers changed; and the books are best read for their examples, with the caution sections taken seriously.

## Primary sources

- [`reflect` ↗](https://pkg.go.dev/reflect) — the package docs: `Type`, `Value`, `Kind`, `StructTag`, `Select`, `SelectCase`, `TypeAssert` (1.25), `TypeFor` (1.22), and the sentence that a method inappropriate to a Kind panics.
- [`unsafe` ↗](https://pkg.go.dev/unsafe) — the six valid `Pointer` patterns, `Add`, `Slice`, `SliceData`, `String`, `StringData`, `Sizeof`, `Alignof`, `Offsetof`.
- [*The Laws of Reflection* ↗](https://go.dev/blog/laws-of-reflection) — Rob Pike, the Go blog, 2011: the three laws, `Type` versus `Kind`, and settability — still the best short introduction.
- The Go specification: [Struct types ↗](https://go.dev/ref/spec#Struct_types) (tags), [Package unsafe ↗](https://go.dev/ref/spec#Package_unsafe), [Conversions ↗](https://go.dev/ref/spec#Conversions), [Address operators ↗](https://go.dev/ref/spec#Address_operators), [Select statements ↗](https://go.dev/ref/spec#Select_statements).
- Release notes: [Go 1.14 ↗](https://go.dev/doc/go1.14#compiler) (`-d=checkptr`, on with `-race`), [Go 1.17 ↗](https://go.dev/doc/go1.17#unsafe) (`unsafe.Add`, `unsafe.Slice`), [Go 1.20 ↗](https://go.dev/doc/go1.20#unsafe) (`unsafe.String`, `StringData`, `SliceData`), [Go 1.21 ↗](https://go.dev/doc/go1.21#reflectpkgreflect) (`ValueOf` no longer forces a heap allocation), [Go 1.22 ↗](https://go.dev/doc/go1.22#reflectpkgreflect) (`TypeFor`), [Go 1.25 ↗](https://go.dev/doc/go1.25#reflectpkgreflect) (`TypeAssert`).
- [Design document: `unsafe.Slice` and `unsafe.Add` ↗](https://github.com/golang/go/issues/19367) — the proposal that added the first two, and [`unsafe.String` and friends ↗](https://github.com/golang/go/issues/53003) for the 1.20 set.
- The source, for the messages the pages record: [`src/reflect/value.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/reflect/value.go), [`src/reflect/type.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/reflect/type.go), [`src/runtime/checkptr.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/runtime/checkptr.go), [`src/math/unsafe.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/math/unsafe.go).
- [`go vet` ↗](https://pkg.go.dev/cmd/vet) and the analyzers [`unsafeptr` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/unsafeptr), [`structtag` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/structtag), [`unmarshal` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/unmarshal).
- [`encoding/json` ↗](https://pkg.go.dev/encoding/json) — the tag options and the exported-fields rule; [`testing.AllocsPerRun` ↗](https://pkg.go.dev/testing#AllocsPerRun).

## Books

- Alan A. A. Donovan and Brian W. Kernighan, *The Go Programming Language* (Addison-Wesley, 2015) — chapter 12, "Reflection": "Why Reflection?", "reflect.Type and reflect.Value", "Display, a Recursive Value Printer", "Setting Variables with reflect.Value", "Accessing Struct Field Tags", "Displaying the Methods of a Type" and "A Word of Caution"; chapter 13, "Low-Level Programming": "unsafe.Sizeof, Alignof, and Offsetof", "unsafe.Pointer", "Example: Deep Equivalence" and "Another Word of Caution". The `Display` and S-expression examples are still the best worked reflection code in print.
- Jon Bodner, *Learning Go*, 2nd ed. (O'Reilly, 2024) — chapter 16, "Here Be Dragons: Reflect, Unsafe, and Cgo": "Reflection Lets You Work with Types at Runtime", "Types, Kinds, and Values", "Make New Values", "Use Reflection to Check If an Interface's Value Is nil", "Use Reflection to Write a Data Marshaler", "You Can Build Structs with Reflection, but Don't", "Reflection Can't Make Methods", "Use Reflection Only if It's Worthwhile", "unsafe Is Unsafe", "Using Sizeof and Offsetof", "Using unsafe to Convert External Binary Data", "Accessing Unexported Fields", "Using unsafe Tools"; and chapter 13, "The Standard Library": "Using Struct Tags to Add Metadata".
- *Go in Practice*, 2nd ed. (Manning, 2025) — chapter 13, "Reflection, code generation, and advanced Go": "Three features of reflection", "Structs, tags, and annotations" and "Generating Go code with Go code".
- Adam Freeman, *Pro Go* (Apress, 2022) — chapter 27, "Using Reflection"; chapter 28, "Using Reflection, Part 2" ("Inspecting Struct Tags", "Setting Struct Field Values", "Creating, Copying, and Appending Elements to Slices"); chapter 29, "Using Reflection, Part 3" ("Working with Channel Values", "Selecting from Multiple Channels"). Exhaustive on the API, method by method.
- Miki Tebeka, *Effective Go Recipes* (Pragmatic, 2024) — chapter 2, "Serializing Data", Recipe 14, "Parsing Struct Tags".
- Burak Serdar, *Effective Concurrency in Go* (Packt, 2023) — chapter 5, "Worker Pools and Pipelines": the side note that `reflect.Select` is the fan-in for a dynamic number of channels.

### Not on the shelf

- Teiva Harsanyi, *100 Go Mistakes and How to Avoid Them* (Manning, 2022) — <https://100go.co/>.
- Bartłomiej Płotka, *Efficient Go* (O'Reilly, 2022) — <https://www.oreilly.com/library/view/efficient-go/9781098105709/>.

## Talks and videos

- *The Laws of Reflection* has no talk, but Rob Pike's GopherCon 2014 keynote, *Hello Gophers*, and his *Go Proverbs* talk (Gopherfest 2015) carry the line that reflection is never clear: <https://go-proverbs.github.io/>.
- Dave Cheney, *Understanding Allocations: the Stack and the Heap* — GopherCon SG 2019; the escape-analysis background for why `ValueOf` used to allocate. <https://www.youtube.com/watch?v=ZMZpH4yT7M0>
- Matthew Dempsky, *checkptr* is described in the Go 1.14 release notes and in the proposal discussion at <https://github.com/golang/go/issues/34964>.

## Read with care

- Any source that reads a `[]byte` as a `string` through `reflect.SliceHeader` / `StringHeader` — deprecated since Go 1.20; `unsafe.String` and `unsafe.Slice` replace them, and `staticcheck` flags the old form.
- Benchmarks of `reflect.ValueOf` published before Go 1.21 — they include a heap allocation that no longer happens.
- Advice that `Interface()` followed by a type assertion is the only way to get a typed value out — true until Go 1.25's `TypeAssert`, which also removes the copy for an addressable value.
- Tutorials that store an address in a `uintptr` "to keep it small" — invalid under pattern 2 of the `unsafe` docs, flagged by `vet`, fatal under `-race`.
- *The Go Programming Language*'s `Sizeof` table was written for Go 1.5: the numbers are the same on today's 64-bit platforms, but check them with a program, as chapter 14 does.

*Checked 2026-09-23.*
