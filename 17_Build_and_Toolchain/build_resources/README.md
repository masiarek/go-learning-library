# Build and toolchain: resources

**Level:** 201 · where the claims in this chapter come from

**One line:** The go command's own documentation settles most of this chapter — `go help build`, `go help buildconstraint`, `go help generate`, `go help environment` — and the release notes say when each piece arrived; the books cover the same ground under their tooling chapters.

## Primary sources

- [The go command ↗](https://pkg.go.dev/cmd/go) — one page holding `go help build` (the flags `-tags`, `-trimpath`, `-ldflags`, `-buildvcs`), [Build constraints ↗](https://pkg.go.dev/cmd/go#hdr-Build_constraints), [Generate Go files by processing source ↗](https://pkg.go.dev/cmd/go#hdr-Generate_Go_files_by_processing_source), [Print Go environment information ↗](https://pkg.go.dev/cmd/go#hdr-Print_Go_environment_information) and [Print Go version ↗](https://pkg.go.dev/cmd/go#hdr-Print_Go_version) for `go version -m`.
- [`embed` ↗](https://pkg.go.dev/embed) — the directive's rules, `embed.FS`, and the `all:` prefix; [`io/fs` ↗](https://pkg.go.dev/io/fs) for reading it.
- [`cmd/link` ↗](https://pkg.go.dev/cmd/link) — `-X`, `-s`, `-w`, and which variables `-X` can set.
- [`runtime/debug` ↗](https://pkg.go.dev/runtime/debug#ReadBuildInfo) — `ReadBuildInfo` and the `BuildSetting` keys a binary carries.
- [`go/build` ↗](https://pkg.go.dev/go/build#hdr-Build_Constraints) and [`go/build/constraint` ↗](https://pkg.go.dev/go/build/constraint) — the file-name suffixes, and the parser and evaluator for `//go:build` expressions.
- Release notes: [Go 1.13 ↗](https://go.dev/doc/go1.13) (`-trimpath`), [Go 1.16 ↗](https://go.dev/doc/go1.16) (`//go:embed`), [Go 1.17 ↗](https://go.dev/doc/go1.17) (`//go:build`), [Go 1.18 ↗](https://go.dev/doc/go1.18) (version-control stamping, `go version -m` build settings), [Go 1.21 ↗](https://go.dev/doc/go1.21) (the `go` line as a minimum, toolchains), [Go 1.24 ↗](https://go.dev/doc/go1.24) (the `tool` directive), [Go 1.25 ↗](https://go.dev/doc/go1.25).
- Design documents: [`//go:build` lines ↗](https://go.dev/design/draft-gobuild), [`go:embed` ↗](https://go.dev/design/draft-embed), and [issue 13560 ↗](https://go.dev/issue/13560), where the `// Code generated … DO NOT EDIT.` header was agreed.
- Go blog: Rob Pike, [Generating code ↗](https://go.dev/blog/generate) (2014); Russ Cox, [Perfectly Reproducible, Verified Go Toolchains ↗](https://go.dev/blog/rebuild) (2023) and [Forward Compatibility and Toolchain Management in Go 1.21 ↗](https://go.dev/blog/toolchain) (2023); [Go Toolchains ↗](https://go.dev/doc/toolchain) and [Go, Backwards Compatibility, and GODEBUG ↗](https://go.dev/doc/godebug).
- The vet analyzers this chapter measures: [`buildtag` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/buildtag), [`directive` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/directive), [`stdversion` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/stdversion), [`tests` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/tests).
- [`stringer` ↗](https://pkg.go.dev/golang.org/x/tools/cmd/stringer) and the Go wiki's [GoGenerateTools ↗](https://go.dev/wiki/GoGenerateTools) — the generators `go generate` was made for.
- The [Reproducible Builds project ↗](https://reproducible-builds.org/) — the term, defined across languages.

## Books

- Jon Bodner, *Learning Go*, 2nd ed. (O'Reilly, 2024), chapter 11, "Go Tooling" — the sections "Embedding Content into Your Program", "Embedding Hidden Files", "Using go generate", "Working with go generate and Makefiles", "Reading the Build Info Inside a Go Binary", "Building Go Binaries for Other Platforms" and "Using Build Tags". The one chapter that covers all five lessons.
- Miki Tebeka, *Effective Go Recipes* (Pragmatic, 2024), chapter 14, "Building Applications" — Recipe 72, "Embedding Assets in Your Binary"; Recipe 73, "Injecting Version to Your Executable"; Recipe 74, "Ensuring Static Builds"; Recipe 75, "Using Build Tags for Conditional Builds"; Recipe 76, "Building Executables for Different Platforms"; Recipe 77, "Generating Code".
- Alan A. A. Donovan and Brian W. Kernighan, *The Go Programming Language* (Addison-Wesley, 2015), chapter 10, "Packages and the Go Tool" — section 10.7, "The Go Tool", and 10.7.3, "Building Packages", where build tags appear. Written before modules, `//go:embed` and `//go:build`; the go command it describes is `GOPATH`'s.
- *Go in Practice*, 2nd ed. (Manning, 2025), chapter 10, "Sending and receiving data" — section 10.1.3, "Embedding files in a binary"; chapter 13, "Reflection, code generation, and advanced Go" — section 13.3, "Generating Go code with Go code".
- Adam Freeman, *Pro Go* (Apress, 2022) — a reference for the language and the standard library; build constraints, `//go:embed`, `-ldflags` and `go generate` are not among its topics.

### Not on the shelf

- Teiva Harsanyi, *100 Go Mistakes and How to Avoid Them* (Manning, 2022) — <https://100go.co/>.
- Bartłomiej Płotka, *Efficient Go* (O'Reilly, 2022) — the book's example repository, <https://github.com/efficientgo/examples>.

## Talks and videos

- Russ Cox, "Go with Versions", GopherCon Singapore 2018 — the design of modules and the `go.mod` file that every driver in this chapter creates with `go mod init`.
- Rob Pike's [Generating code ↗](https://go.dev/blog/generate) is a blog post rather than a talk; no recorded talk on `go generate`, `//go:embed` or reproducible toolchains is listed here, because none could be verified while writing this page.

## Read with care

- Any guide that ends at `// +build` — the line still works in Go 1.25 (measured on the vet page), but `gofmt` adds `//go:build` above it, and tools written after Go 1.17 read only the new line.
- Guides that say `-ldflags -X` silently ignores a variable of the wrong type — on Go 1.25 the linker refuses an `int` with `cannot set with -X: not a var of type string`; what is silent is a misspelt name or a computed initialiser.
- Tutorials that `go get` a code generator to install it — since Go 1.17 `go get` no longer installs binaries; use `go install pkg@version`, `go run pkg@version` in the directive, or the `tool` directive from Go 1.24.
- Examples that set `GOFLAGS` with `go env -w` on a developer machine and call it CI configuration — the file it edits is the user's, and an environment variable in the job overrides it anyway.
- Pre-release articles on `//go:embed` that put the directive on a local variable, or embed `..` paths — both are refused, as the compiler-errors page records.
- Advice to strip binaries with the system `strip` — Go's linker has `-s -w` for that; an external `strip` has damaged Go binaries on macOS in past releases and is not needed.

*Checked 2026-09-23.*
