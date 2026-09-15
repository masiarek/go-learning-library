# Conventions

House rules for writing a page here. Readers browsing lessons do not need this file; it is for whoever is about to add one.

## The rule that comes before the others

**A page never claims something a program has not printed — on both machines.** CI runs every example on `ubuntu-latest` and `macos-latest`, and an answer key is only what both agree on. A sentence that no program here backs — what the spec promises, what a runtime does internally — links its source (the spec, the package documentation, the Go source, a Go blog post), or the sibling library page that checks it, or ends with *(Not machine-checked here.)*

## What this library is

A Go library whose first chapters are the thing Go is best known for: goroutines, channels, `select`, the `sync` package, `context`, the patterns built from them, and the tools that test them. The programs are Go. The same questions put to Rust, C, C++, Java and Python live in the [Concurrency library ↗](https://masiarek.github.io/concurrency-learning-library/), and every lesson here that has a counterpart there links it — and is linked back.

## The shape of a lesson

```
02_Channels/
  closing_a_channel_ends_a_range/
    README.md                                   the lesson
    examples/
      closing_a_channel_ends_a_range_go.go      the Go program
      closing_a_channel_ends_a_range_go.out     its recorded output (generated — do not hand-edit)
      send_on_a_closed_channel_sh.sh            a driver, for a panic's exit status
    demo/                                       not run by CI: the scripts behind Real runs fences
```

One idea per folder. The folder name is the idea, in `lower_snake_case`, and it becomes a permanent URL — so name it for what it teaches, not for where it sits in the reading order. A page names an example by its bare stem, so stems are unique across the whole library: end a Go program's stem in `_go` and a driver's in `_sh`, and start it with words from its lesson.

## The page

- Open with the title, a `**Level:**` line (`101` / `201` / `301`, then `·`, then who it is for) and a `**One line:**` that states the claim rather than the topic.
- Put the output block early; explain it after, under **Reading the output**. Show the program with a `<!-- source:stem -->` block, folded inside `<details markdown="1">` when it is long.
- **What to do** — the rule a reader takes away.
- **In other languages** — the Concurrency library's lesson on the same question, which runs it in six languages, and the Rust library's page where one exists. Say in a sentence what differs; do not repeat their pages.
- **Sources** — the Go spec section, the `pkg.go.dev` entry, the Go blog post or release notes, and where it helps a chapter of one of the books in [Resources](08_Resources/README.md). Quote at most a short phrase; paraphrase the rest.

Do not hard-wrap paragraphs — one paragraph, one line.

## Deterministic about nondeterminism

Concurrency is where a recorded answer key is hardest to keep honest, because the interesting behaviour is so often the part that changes between runs. So:

- **A key records only what cannot vary.** Never the order in which goroutines printed, the count a race lost, a duration, a goroutine number from a panic trace, a pid, an address, or `runtime.NumGoroutine()` before everything it counts has settled.
- **Force the order you print in.** Collect results and print them from `main` — sorted, or in the order of the inputs — or print from one goroutine only.
- **A sleep is a margin, never a synchronizer.** A lesson may sleep to show that something did *not* happen, and then the competing events are at least two seconds apart. Never sleep to make a race come out one way; use a channel, a `WaitGroup`, or `testing/synctest`.
- **Show a distribution as a threshold.** "`select` picked each ready case between 40% and 60% of 10,000 times" is a key; the two counts are not.
- **Show variation as variation.** What differs between runs goes in a fence whose title starts `Real runs —` and names the Go version, the machine, the number of runs and the date. A script in the lesson's `demo/` folder, which the runner skips, produces it, and the page says how to run it.
- **An exit status is a result.** An example must itself exit 0, because the runner stops on anything else. A panic, a `fatal error: all goroutines are asleep - deadlock!`, or the race detector's exit status is shown by a `.sh` driver that runs the program and prints the exit status and only the lines of stderr that do not vary.

## Output is generated, never typed

Mark the spot and let the tool fill it:

```markdown
<!-- output:closing_a_channel_ends_a_range_go -->
<!-- /output -->
```

`tools/run_examples.py` runs the example and pastes what it actually printed, with a provenance line above the fence. Inside the markers is generated; outside is yours. A second kind, `<!-- source:stem -->`, pastes the program itself.

```bash
python3 tools/run_examples.py                      # verify + refill
python3 tools/run_examples.py --update --only X    # record X's output as its answer key (X: a stem or a lesson folder)
python3 tools/run_examples.py --check              # write nothing, fail on drift (CI)
python3 tools/check_all.py --staged                # every gate CI runs, on what you are about to commit
```

**Always pass `--only` with `--update`**, and read what it recorded before committing: `--update` accepts whatever the program printed. Run a concurrent example several times before recording it — a key that is right four runs in five is a flaky build waiting to happen.

## The programs

**Go: 1.25 or later, standard library only.** Nothing from `golang.org/x`: a lesson about a pattern that `errgroup` or `semaphore` packages links that package and builds the standard-library version itself.

**One `package main` file with a `func main()`**, formatted by `gofmt` (CI fails on any file `gofmt -l` lists). The runner builds it with `go build -trimpath` and runs it from its own folder under `GOTOOLCHAIN=local`, `LC_ALL=C`.

**A driver is `bash`**, compatible with the Mac's `/bin/bash` 3.2, and works in a `mktemp -d` directory, printing each command before running it with a `say` helper so that a verified block reads like a terminal. A driver that needs `go test` or `go run -race` creates a throwaway module there (`go mod init example`), and keeps `GOTOOLCHAIN=local`.

**Name things for what they are.** Workers, jobs, orders, URLs, readings — not `foo` and `bar`, and not ballots.

## Two machines

CI's *Show toolchain* step prints what each runner has. Add a row when CI finds a difference between them, with the date.

| | Ubuntu runner | macOS runner |
|---|---|---|
| CPU | x86-64 | arm64 |
| `go` | 1.25, from `actions/setup-go` | 1.25, from `actions/setup-go` |
| `bash` | 5.x | 3.2 |

Keys are recorded on an x86-64 Mac with go1.25.5. For a Linux check before pushing, the Docker image `golang:1.25-alpine` has Go but no python3, so run the program there with `go run` and compare with the `.out` by eye or with `diff`:

```bash
docker run --rm --ulimit fsize=104857600 -v "$PWD:/w:ro" golang:1.25-alpine sh -c 'cd /w/02_Channels/closing_a_channel_ends_a_range/examples && go run closing_a_channel_ends_a_range_go.go'
```

## Links

- Link a folder by naming its `README.md` — `[label](some_folder/README.md)`, never `[label](some_folder/)`.
- **A link that leaves the library ends its label with ` ↗`**; an internal link never does. `python3 tools/check_link_style.py --fix` adds and removes them; CI runs it without `--fix`.
- A sibling library's page is linked as `https://masiarek.github.io/<library>/<chapter>/<lesson>/index.html`.

## Nav order

A new lesson folder gets a row in `NAV_ORDER` in `mkdocs_hooks.py`. Its sidebar label is its README's `# H1` with the backticks dropped; give it an entry in `LABEL_OVERRIDES` only when that H1 is too long for a sidebar. `tools/check_nav_chain.py` fails on a row naming a folder that does not exist, so commit the folder and its row together.
