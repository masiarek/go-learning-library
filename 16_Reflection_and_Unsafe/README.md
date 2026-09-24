# 16 — Reflection and unsafe

Most Go programs never import `reflect` or `unsafe`; they use them through `encoding/json`, `fmt` and `strings.Builder`, which do it for them. This chapter is for the moment that stops being enough: a validator that reads its rules from struct tags, a merge over as many channels as a config file names, a bit pattern that has to be read as another type, or a benchmark that says an encoder allocates and you want to know why. The two packages are the two ways out of Go's static types. `reflect` inspects and builds values whose types the program learns while it runs; `unsafe` reinterprets memory without changing it. Both come with rules the compiler cannot enforce, so every page here measures what the runtime, `go vet` and `-d=checkptr` do when a rule is broken.

Read [11 — Interfaces and method sets](../11_Interfaces_and_Method_Sets/README.md) first: `reflect.ValueOf` takes an interface value, and [An interface is two words](../11_Interfaces_and_Method_Sets/an_interface_is_two_words/README.md) is what it receives. [`select` waits on many channels](../03_Select/select_waits_on_many/README.md) is the statement `reflect.Select` generalizes, and the last lesson counts allocations with [`AllocsPerRun`](../15_Performance/allocsperrun_counts_allocations/README.md) from chapter 15.

| Lesson | The one thing |
|---|---|
| [`reflect` reads struct tags](reflect_reads_struct_tags/README.md) | `Field(i).Tag.Get("json")` is the string the compiler kept with the field, and `encoding/json` reads the same one; `Kind` is a type's shape, `Type` is its name |
| [`reflect` sets only addressable values](reflect_sets_only_addressable_values/README.md) | `ValueOf(x)` is a copy and `CanSet` is false; `ValueOf(&x).Elem()` is the variable; an unexported field is readable and never settable, and each mistake is a panic with a message worth knowing |
| [`reflect.Select` over cases known at run time](reflect_select_over_cases_known_at_run_time/README.md) | a `[]SelectCase` built in a loop is a `select` over N channels; the chosen index, the value and `recvOK` come back, a nil or zero `Chan` switches a case off, and each call allocates |
| [`unsafe.Pointer` reinterprets memory](unsafe_pointer_reinterprets_memory/README.md) | `*(*uint64)(unsafe.Pointer(&f))` is `math.Float64bits(f)`; `unsafe.String` and `unsafe.Slice` view bytes as a string and back for 0 allocations; the `uintptr` round trip is flagged by `vet` and fatal under `-d=checkptr` |
| [Reflection costs allocations](reflection_costs_allocations/README.md) | on Go 1.25 `reflect.ValueOf(x).Kind()` allocates 0 times, like a type switch; `Interface()` on an addressable field copies (1), and `json.Marshal` of a struct is 1 or 2 against 0 for hand-written appends |

| Companion | What it holds |
|---|---|
| [Reflection and unsafe: the compiler errors](reflection_compiler_errors/README.md) | the conversions the compiler refuses, a `reflect.Value` mistaken for the value, `unsafe.Sizeof` on non-expressions, and the panics that only the run time can raise |
| [Reflection and unsafe: what go vet and gofmt catch](reflection_vet_and_lints/README.md) | `unsafeptr`, `structtag`, `unmarshal`, the `-d=checkptr` instrumentation, and the mistakes none of them sees |
| [Reflection and unsafe: resources](reflection_resources/README.md) | the package docs, *The Laws of Reflection*, the release notes that changed the answers, and the book chapters |

## Planned

- **`reflect.Value.Call` and `MakeFunc`** — calling a method found by name, building a function at run time, and what each costs.
- **`reflect.StructOf` and `reflect.TypeFor`** — building a struct type at run time (Learning Go's advice: you can, but don't), and the Go 1.22 generic way to name a type.
- **cgo** — `unsafe.Pointer` at the C boundary, `C.CString` and the rules for passing Go pointers to C.
- **`unsafe.Sizeof`, `Alignof` and `Offsetof`** are measured in [Struct layout and padding](../14_Memory_and_the_Runtime/struct_layout_and_padding/README.md), not repeated here.
