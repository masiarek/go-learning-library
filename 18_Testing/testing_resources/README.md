# Testing: resources

Where the claims in this chapter come from, and where to read further. Everything in the chapter was measured on Go 1.25; the sources below say what the tools promise, and the books say how their authors use them.

## Primary sources

- [`testing` ↗](https://pkg.go.dev/testing) — the package documentation: "Subtests and Sub-benchmarks", "Examples", "Fuzzing", "Skipping", "Main", and the methods `T.Run`, `T.Parallel`, `T.Cleanup`, `T.TempDir`, `T.Setenv`, `T.Chdir`, `T.Context`, `T.Helper`, `T.FailNow`. Settles what each method promises, and that a fuzz target without `-fuzz` runs its seed corpus only.
- [`go help test` ↗](https://pkg.go.dev/cmd/go#hdr-Test_packages) — local directory mode against package list mode, the test cache and which flags are cacheable, the vet subset `go test` runs, and the external `_test` package.
- [`go help testflag` ↗](https://pkg.go.dev/cmd/go#hdr-Testing_flags) — every flag: `-run` and `-skip` split on `/`, `-count`, `-cover`, `-coverprofile`, `-cpu`, `-failfast`, `-fuzz`, `-fuzztime`, `-json`, `-list`, `-parallel` (default `GOMAXPROCS`), `-shuffle`, `-short`, `-v`, `-vet`.
- [`cmd/cover` ↗](https://pkg.go.dev/cmd/cover) and [Coverage profiling support for integration tests ↗](https://go.dev/doc/build-cover) — the profile format, `-func` and `-html`, and `go build -cover` since Go 1.20.
- [Go Fuzzing ↗](https://go.dev/doc/security/fuzz/) — the corpus file format, custom settings, requirements and limitations (AMD64 and ARM64); [Tutorial: Getting started with fuzzing ↗](https://go.dev/doc/tutorial/fuzz).
- [`cmd/test2json` ↗](https://pkg.go.dev/cmd/test2json) — the events `go test -json` emits.
- The vet analyzers `go test` runs and the ones it does not: [`tests` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/tests), [`printf` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/printf), [`testinggoroutine` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/testinggoroutine), [`waitgroup` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/waitgroup), [`copylocks` ↗](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/copylocks).
- The Go blog: [*Using Subtests and Sub-benchmarks* ↗](https://go.dev/blog/subtests) (2016, subtests and `-run` per level), [*Testable Examples in Go* ↗](https://go.dev/blog/examples) (2015, `// Output:` and how the documentation renders examples), [*The cover story* ↗](https://go.dev/blog/cover) (2013, how coverage is instrumented and what it does not measure), [*Fuzzing is Beta Ready* ↗](https://go.dev/blog/fuzz-beta) (2021), [*Testing concurrent code with testing/synctest* ↗](https://go.dev/blog/synctest) (2025, the subject of [chapter 07](../../07_Testing_Concurrent_Code/README.md)).
- Release notes, for when each piece arrived: [Go 1.7 ↗](https://go.dev/doc/go1.7#testing) (subtests), [Go 1.10 ↗](https://go.dev/doc/go1.10#test) (the test cache, `-failfast`, `-json`, the vet subset), [Go 1.14 ↗](https://go.dev/doc/go1.14#testing) (`Cleanup`), [Go 1.15 ↗](https://go.dev/doc/go1.15#testing) (`TempDir`), [Go 1.17 ↗](https://go.dev/doc/go1.17#testing) (`Setenv`, `-shuffle`), [Go 1.18 ↗](https://go.dev/doc/go1.18#fuzzing) (fuzzing), [Go 1.20 ↗](https://go.dev/doc/go1.20#go-command) (`-skip`, `go build -cover`), [Go 1.22 ↗](https://go.dev/doc/go1.22#language) (the per-iteration loop variable, which retired `c := c` in subtest loops), [Go 1.24 ↗](https://go.dev/doc/go1.24#testingpkgtesting) (`T.Context`, `T.Chdir`, `b.Loop`), [Go 1.25 ↗](https://go.dev/doc/go1.25) (the `waitgroup` analyzer, `WaitGroup.Go`, `[recovered, repanicked]`, `synctest`).
- The source, for the messages the pages record: [`src/testing/testing.go` at go1.25.5 ↗](https://github.com/golang/go/blob/go1.25.5/src/testing/testing.go) (`Fail in goroutine after %s has completed`, `test using t.Setenv or t.Chdir can not use t.Parallel`), [`src/testing/fuzz.go` ↗](https://github.com/golang/go/blob/go1.25.5/src/testing/fuzz.go).

## Books

- Alan A. A. Donovan and Brian W. Kernighan, *The Go Programming Language* (Addison-Wesley, 2015), chapter 11, "Testing" — 11.1, "The go test Tool"; 11.2, "Test Functions", with 11.2.1, "Randomized Testing" (the hand-rolled ancestor of a fuzz target), 11.2.4, "External Test Packages", 11.2.5, "Writing Effective Tests" and 11.2.6, "Avoiding Brittle Tests"; 11.3, "Coverage"; 11.6, "Example Functions". Written for Go 1.5: no subtests, no `t.Cleanup`, no fuzzing — the sections on what a good test looks like have not aged.
- Jon Bodner, *Learning Go*, 2nd ed. (O'Reilly, 2024), chapter 15, "Writing Tests" — "Understanding the Basics of Testing" with "Reporting Test Failures", "Setting Up and Tearing Down", "Testing with Environment Variables", "Storing Sample Test Data", "Caching Test Results" and "Testing Your Public API"; then "Running Table Tests", "Running Tests Concurrently", "Checking Your Code Coverage", "Fuzzing", "Using Integration Tests and Build Tags" and "Finding Concurrency Problems with the Data Race Detector". The closest match to this chapter, section for section.
- *Go in Practice*, 2nd ed. (Manning, 2025), chapter 6, "Formatting, testing, debugging, and benchmarking" — 6.3, "Unit testing in Go": "Creating a test suit with table-driven tests", "Fuzzing test input", "Annotating tests with names" and "Checking test coverage with go cover".
- Adam Freeman, *Pro Go* (Apress, 2022), chapter 31, "Unit Testing, Benchmarking, and Logging" — "Using Testing", with "Running Unit Tests" and "Managing Test Execution" (`-run`, `-v`, `t.Fatal` against `t.Error`, `t.Skip`).
- Miki Tebeka, *Effective Go Recipes* (Pragmatic Bookshelf, 2024), chapter 13, "Testing Your Code" — recipe 65, "Conditionally Running Continuous Integration Tests" (`testing.Short` and environment checks), recipe 66, "Reading Test Cases from a File", recipe 67, "Fuzzing Bugs Away", recipe 69, "Writing Global Setup/Teardown Functions" (`TestMain`).

### Not on the shelf

- Teiva Harsanyi, *100 Go Mistakes and How to Avoid Them* (Manning, 2022) — [100go.co ↗](https://100go.co/): a chapter of testing mistakes, among them parallel tests that share state, `t.Cleanup` against `defer`, and not using table-driven tests.

## Talks and videos

- *Advanced Testing with Go* — Mitchell Hashimoto, GopherCon 2017 ([YouTube ↗](https://www.youtube.com/watch?v=8hQG7QlcLBk)): table-driven tests, `testdata/`, golden files, test helpers and `t.Helper`.
- *Testing in Go* — Rob Pike's account of the design runs through [*The cover story* ↗](https://go.dev/blog/cover); for fuzzing, *Go Fuzzing* — Katie Hockman, GopherCon 2022 ([YouTube ↗](https://www.youtube.com/watch?v=5VBqJFyAhVU)), the engine's design and what to fuzz.

## Read with care

- Any subtest loop with `c := c` (or `tc := tc`) as its first line: needed before Go 1.22 for parallel subtests, harmless and confusing after — [Go 1.22 release notes ↗](https://go.dev/doc/go1.22#language).
- Advice to use `t.Setenv` in a test that also calls `t.Parallel`, or to "save and restore" `os.Setenv` by hand around a parallel test: the first panics since Go 1.17, and the second is a data race; [Parallel subtests wait, Cleanup runs last](../t_parallel_and_t_cleanup/README.md).
- Tutorials whose `go test` transcripts show a `-2` suffix on test names under `-cpu`: benchmarks get the suffix, tests do not (measured in the same lesson).
- Descriptions of the test cache that say `-count=1` "clears" it: nothing is cleared, the run is not served from it; `go clean -testcache` clears it.
- `testing.T` passed by value in a helper: it compiles, and [the vet page](../testing_vet_and_lints/README.md) shows a `--- PASS` next to a `FAIL`.

*Checked 2026-09-23.*
