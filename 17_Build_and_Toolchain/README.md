# 17 — Build and toolchain

The `go` command beyond `go run`: which files a build compiles, what it copies into the binary, what the linker can write into a variable, what runs only when you ask, and why the same source gives the same bytes. Every claim is measured on Go 1.25 by a script that makes a throwaway module in a temporary directory, the way [The race detector](../07_Testing_Concurrent_Code/the_race_detector/README.md) does, and prints nothing that differs between the Linux and Mac runners that check it — no `GOOS`, no version, no path, no size.

Read [The race detector](../07_Testing_Concurrent_Code/the_race_detector/README.md) first for the shape of a driver, and keep [Subtests and table tests](../18_Testing/subtests_and_table_tests/README.md) nearby: `go test` and `go vet` read the same build constraints and the same generated files as `go build`.

| Lesson | The one thing |
|---|---|
| [`//go:build` chooses which files are compiled](build_constraints_choose_files/README.md) | `fast` and `!fast` files define one function twice and only one is ever compiled; `go list -f '{{.GoFiles}}'` shows the choice for any `GOOS` without building, and `go vet` needs the same `-tags` |
| [`//go:embed` puts files in the binary](go_embed_puts_files_in_the_binary/README.md) | a `string`, a `[]byte` and an `embed.FS` are filled at build time; the sources are deleted and the binary still has them, in sorted order |
| [`-ldflags -X` sets a variable at link time](ldflags_x_sets_a_variable_at_link_time/README.md) | `dev` becomes `1.4.2` without a source change; only a string, only package-level, only with a constant initialiser — an `int` is refused, a misspelt name is silent |
| [`go generate` runs a command you name](go_generate_runs_a_command/README.md) | `go build` before `go generate` is an `undefined` error; the generator sees `$GOFILE`, `$GOPACKAGE` and `$GOLINE`, and writes a first line every tool recognises |
| [Builds are reproducible with `-trimpath`](builds_are_reproducible/README.md) | two directories give identical bytes with `-trimpath` and different ones without; a git checkout stamps the commit in, and `go env -w` is shown without touching your configuration |

| Companion | What it holds |
|---|---|
| [The compiler errors](build_compiler_errors/README.md) | `go.mod file not found`, `is not in std`, `imported and not used`, `main redeclared`, the `//go:embed` refusals, `cannot set with -X`, `misplaced compiler directive` — each with its transcript and its fix |
| [What vet and gofmt catch](build_vet_and_lints/README.md) | `buildtag`, `directive`, `stdversion`, `tests`, `gofmt` on constraint lines, and the longer list of what no tool catches |
| [Resources](build_resources/README.md) | the go command's documentation by section, release notes by feature, the books' tooling chapters, and what to read with care |

## Planned

- **Cross-compiling with cgo**: `GOOS`/`GOARCH` builds are shown here only as `go list` file lists; a lesson that builds for another platform and checks the binary with `file` needs an answer key that does not name the platform.
- **The `tool` directive and `go tool`** (Go 1.24): a module-versioned `stringer`, in place of this chapter's `go run ./gen`.
- **Workspaces, `go.sum` and `go mod vendor`**: what `go work` changes and what `-mod=vendor` builds from.
- **`-gcflags` and `-pgo`**: the compiler's own flags are in [The compiler says what it inlines](../15_Performance/the_compiler_says_what_it_inlines/README.md); profile-guided optimisation has no page yet.
