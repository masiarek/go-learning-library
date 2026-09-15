# CLAUDE.md — Go learning library

Standing guidance for Claude working in this repo. Created 2026-09-14/15, when Adam asked for a Go library because "Go has good concurrency solutions", alongside the Concurrency library.

## What this is

A Go library in the same format as its siblings: one idea per page, every claim backed by a program whose output is an answer key checked in CI (Ubuntu x86-64 and macOS arm64). Its first seven chapters are Go's concurrency. Public repo `masiarek/go-learning-library`, site <https://masiarek.github.io/go-learning-library/>.

**The rules live in [CONTRIBUTING.md](CONTRIBUTING.md)** — especially "Deterministic about nondeterminism" and "The programs". This file carries only the operational context.

## Cross-references

- Every lesson's **In other languages** links the Concurrency library's matching lesson and the Rust library's page where one exists.
- The Concurrency library's `11_Concepts/**/concepts.toml` links back to lessons here (`pages` entries of the form `https://masiarek.github.io/go-learning-library/<chapter>/<lesson>/index.html`). A renamed lesson folder breaks those links: rename there too.

## Toolchains (measured 2026-09-14)

- `go` 1.25.5 (Homebrew) on an x86-64 Mac. Homebrew's `go@1.23` keg is really 1.25.5, so older Go cannot be tested locally.
- Linux column: Docker `golang:1.25-alpine` (go1.25.14; no bash — `apk add bash` — and no C compiler, so `-race` needs `apk add gcc musl-dev` or the Debian image `golang:1.25`). Pass `--ulimit fsize=104857600`.
- CI: `actions/setup-go` 1.25 gave go1.25.14 on both runners on 2026-09-15.

## How the first chapters were written

Seven background agents, one per chapter, each verifying every example five or more times, in Docker, and with `-race`; the main session integrated NAV_ORDER, the front pages and CI, and committed. Their reports noted: `closing_a_receive_only_channel_sh.out` records the compiler's exact wording (a patch release could reword it); lessons 02/`all_goroutines_are_asleep` and 05/`a_leaked_goroutine_never_ends` each take about 2 s.

## Working with Adam

- **Be self-driven**: build, verify, commit, push, then report — flag only what is genuinely uncertain.
- Several sessions may share a checkout: `git status` before numbering a chapter, gate with `tools/check_all.py --staged`, stage only your own paths.
- **Never `-m` a commit message that contains backticks** — write it to a file and use `-F`.
- Markdown is not hard-wrapped.
