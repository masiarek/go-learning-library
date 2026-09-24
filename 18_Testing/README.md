# 18 — Testing

A `func TestX(t *testing.T)` and `go test` are where most Go programmers stop reading the [`testing` ↗](https://pkg.go.dev/testing) package. This chapter is the rest of it, measured on Go 1.25: subtests that turn a table of cases into named, individually runnable tests; Example functions whose `// Output:` comment is checked on every run; `t.Parallel`, `t.Cleanup`, `t.TempDir`, `t.Setenv` and `t.Context`, which share one test process safely; fuzzing, whose seed corpus is an ordinary deterministic test; and the flags that choose, cache, shuffle and measure — `-run`, `-skip`, `-count`, `-cover`, `-shuffle`, `-short`, `-failfast`.

Every example is a bash driver that writes a throwaway module, runs `go test`, and prints the transcript with the durations stripped, so what the pages show is what `go test` printed on both CI machines. The reader should know a `TestX` and a `t.Errorf`; [The race detector](../07_Testing_Concurrent_Code/the_race_detector/README.md) and [`synctest.Wait` instead of a sleep](../07_Testing_Concurrent_Code/synctest_wait/README.md) cover `-race` and `testing/synctest` and are not repeated here. Benchmarks are in [Performance](../15_Performance/allocs_per_op_is_a_key_ns_per_op_is_not/README.md).

| Lesson | The one thing |
|---|---|
| [A table case is a subtest with `t.Run`](subtests_and_table_tests/README.md) | `go test -v` names each case `TestParseQuantity/empty`, `-run` selects one, a failing case does not stop its siblings, and `t.Fatal` ends only its own subtest |
| [An Example test runs its `// Output:`](an_example_test_checks_its_output/README.md) | an Example with an `// Output:` comment is compiled and run, a wrong comment fails with `got:`/`want:`, and one without a comment is compiled but never run |
| [Parallel subtests wait, Cleanup runs last](t_parallel_and_t_cleanup/README.md) | `t.Parallel` subtests pause until the parent returns, `t.Cleanup` runs after the subtests in reverse order, `t.Context` is cancelled first, and `t.Setenv` in a parallel test panics |
| [Fuzzing finds the input you did not write](fuzzing_finds_the_input_you_did_not_write/README.md) | without `-fuzz` a fuzz target runs its seed corpus and is deterministic; a corpus file written by hand pins a crashing input; `-fuzz` finds one you did not think of |
| [Coverage and the flags that choose tests](coverage_and_the_run_flag/README.md) | `-cover` and `go tool cover -func` are exact for fixed code, `-run`/`-skip` match per `/`-separated level, `(cached)` appears only with a package argument, and `-shuffle=1` is repeatable |

| Companion | What it holds |
|---|---|
| [Testing: the errors go test stops on](testing_compiler_errors/README.md) | a wrong `TestX` signature, an unexported name from an external test package, an unsupported fuzz argument, `[no test files]`, a panic that ends the binary, and `Fail in goroutine after TestX has completed` |
| [Testing: what go vet catches](testing_vet_and_lints/README.md) | the `tests`, `printf`, `testinggoroutine`, `waitgroup` and `copylocks` analyzers on test code, which of them `go test` runs on its own, and what no tool catches |
| [Testing: resources](testing_resources/README.md) | the package documentation, the Go blog posts on subtests, examples, fuzzing and coverage, the release notes, and the books' chapters |

## Planned

- **`TestMain`** — one `func TestMain(m *testing.M)` per package for set-up that every test shares, `m.Run()`, and why a `TestMain` that forgets to call `os.Exit` with the result used to hide failures.
- **`httptest` and `iotest`** — the standard library's test doubles for HTTP servers and misbehaving readers.
- **Benchmarks in this chapter's terms** — `b.Loop`, sub-benchmarks with `b.Run`, and `-benchmem`; the measurements live in [Performance](../15_Performance/allocs_per_op_is_a_key_ns_per_op_is_not/README.md).
- **`go test -json` and `test2json`** — machine-readable events for a CI dashboard.
