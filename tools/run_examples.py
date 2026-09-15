#!/usr/bin/env python3
"""Run every example, and hold its output to a recorded answer key.

This is the spine of the library. A lesson page never hand-types what a program
prints; it marks the spot and this tool fills it from a real run:

    <!-- output:who_waits_rs -->
    <!-- /output -->

Inside the markers is generated, outside is yours. There is a second kind,
`source:`, which pastes the program itself, so a page that shows the code cannot
quietly drift from the file CI runs.

Seven kinds of example, told apart by extension
-----------------------------------------------
    examples/<stem>.c      `cc -std=c17 -Wall -Wextra -pedantic -pthread` -- Apple clang
                           on a Mac, GCC on Linux; the key must match both
    examples/<stem>.cpp    `c++ -std=c++20 -O2 -Wall -Wextra -Wpedantic -pthread` --
                           libc++ on a Mac, libstdc++ on Linux
    examples/<stem>.rs     `rustc --edition 2024`, no cargo, no crates
    examples/<stem>.go     `go build -trimpath`, one file, standard library only, Go 1.25+
    examples/<stem>.java   `java <stem>.java`, the source launcher, Java 25+ (so a file
                           may be a compact source file, with no class declaration)
    examples/<stem>.py     `python3 -I`, standard library only
    examples/<stem>.sh     `bash`, for what a program cannot show about itself --
                           an exit status, a signal, a compiler's refusal

Stems are unique repo-wide *across* extensions, because a Markdown block names a
bare stem with no path and no extension. The convention is a language suffix:
`who_waits_rs`, `who_waits_go`, `who_waits_unjoined_cpp_sh`.

Every example runs under one fixed environment -- `LC_ALL=C`, `LANG=C`,
`PYTHONUTF8=1`, `GOTOOLCHAIN=local`, and none of the variables that make a JVM
print "Picked up ..." on stderr -- so the answer key does not depend on whoever
ran it. Output is captured as bytes and decoded as UTF-8.

A concurrency library has one more rule than its siblings: **a key records only
what cannot vary between runs.** Which of two threads printed first, how many
increments a race lost, how long something took -- none of those goes in a key.
See CONTRIBUTING.md, "Deterministic about nondeterminism".

Four modes
----------
    python3 tools/run_examples.py             verify + refill the .md blocks
    python3 tools/run_examples.py --update    accept current output as the key
    python3 tools/run_examples.py --check     write nothing; fail on any drift  (CI)
    python3 tools/run_examples.py --only X    touch example X and nothing else

``--only`` narrows both the running and the refilling to the stems you name
(a bare stem, a path to the file, or a lesson folder). A full ``--update``
re-records *every* answer key, which in a checkout open in two sessions means
adopting whatever a colleague's half-finished example happens to print.
"""

from __future__ import annotations

import argparse
import difflib
import functools
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# extension -> the language name a source fence is labelled with
LANGS = {
    ".c": "c",
    ".cpp": "cpp",
    ".rs": "rust",
    ".go": "go",
    ".java": "java",
    ".py": "python",
    ".sh": "bash",
}

C_FLAGS = ["-std=c17", "-Wall", "-Wextra", "-pedantic", "-pthread"]
CXX_FLAGS = ["-std=c++20", "-O2", "-Wall", "-Wextra", "-Wpedantic", "-pthread"]
RUST_EDITION = "2024"
MIN_GO = (1, 25)     # sync.WaitGroup.Go
MIN_JAVA = 25        # compact source files and IO.println, final in Java 25

# <!-- output:stem -->  ...generated...  <!-- /output -->
# <!-- source:stem -->  ...generated...  <!-- /source -->
BLOCK = re.compile(
    r"(?P<open><!--\s*(?P<kind>output|source):(?P<stem>[A-Za-z0-9_\-]+)\s*-->)"
    r"(?P<body>.*?)"
    r"(?P<close><!--\s*/(?P=kind)\s*-->)",
    re.DOTALL,
)

SKIP_DIRS = {".git", "site", ".venv", "__pycache__", ".github", "demo"}

# A fenced code block, opened or closed. The pages that DOCUMENT this mechanism
# (CONTRIBUTING.md) show the markers inside a fence -- those are documentation,
# not blocks to fill.
FENCE = re.compile(r"^[ \t]*(?P<f>`{3,}|~{3,})", re.MULTILINE)


def fenced_spans(text: str) -> list[tuple[int, int]]:
    """Character ranges covered by fenced code blocks."""
    spans: list[tuple[int, int]] = []
    open_at: int | None = None
    open_fence = ""
    for m in FENCE.finditer(text):
        fence = m.group("f")
        if open_at is None:
            open_at, open_fence = m.start(), fence
        elif fence[0] == open_fence[0] and len(fence) >= len(open_fence):
            spans.append((open_at, m.end()))
            open_at = None
    if open_at is not None:
        spans.append((open_at, len(text)))
    return spans


def walk(root: Path):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            yield Path(dirpath) / name


def find_examples() -> dict[str, Path]:
    """Map stem -> path for every example under an examples/ folder. Stems are unique."""
    found: dict[str, Path] = {}
    for path in sorted(walk(REPO)):
        if path.suffix not in LANGS or path.parent.name != "examples":
            continue
        if path.stem in found:
            sys.exit(
                f"ERROR: duplicate example stem {path.stem!r}\n"
                f"  {found[path.stem].relative_to(REPO)}\n  {path.relative_to(REPO)}\n"
                "Stems are named bare in Markdown blocks, so they must be unique across "
                "languages too -- add a _c / _cpp / _rs / _go / _java / _py / _sh suffix."
            )
        found[path.stem] = path
    return found


# --- toolchains --------------------------------------------------------------
#
# Each is looked up only when an example needs it, so a Linux container with a C
# compiler and nothing else can still run `--only` over the C examples.


def _first_line(cmd: list[str]) -> str:
    done = subprocess.run(cmd, capture_output=True, text=True)
    return (done.stdout or done.stderr).strip().splitlines()[0] if done.returncode == 0 else ""


@functools.cache
def go_binary() -> str:
    go = os.environ.get("GO") or shutil.which("go")
    if not go:
        sys.exit("ERROR: a .go example needs Go 1.25 or later on PATH (or $GO)")
    version = _first_line([go, "env", "GOVERSION"])  # "go1.25.5"
    m = re.match(r"go(\d+)\.(\d+)", version)
    if not m or (int(m.group(1)), int(m.group(2))) < MIN_GO:
        sys.exit(f"ERROR: {go} is {version or 'unrecognised'}; the examples need Go 1.25 or later")
    return go


@functools.cache
def java_binary() -> str:
    """$JAVA, then $JAVA_HOME/bin/java, then PATH, then Homebrew's openjdk -- the first 25+."""
    candidates = [os.environ.get("JAVA", "")]
    if os.environ.get("JAVA_HOME"):
        candidates.append(str(Path(os.environ["JAVA_HOME"]) / "bin" / "java"))
    candidates.append(shutil.which("java") or "")
    candidates += ["/opt/homebrew/opt/openjdk/bin/java", "/usr/local/opt/openjdk/bin/java"]
    seen = []
    for java in filter(None, candidates):
        if java in seen or not Path(java).exists():
            continue
        seen.append(java)
        version = _first_line([java, "--version"])  # "openjdk 25.0.4.1 2026-08-18"
        m = re.search(r" (\d+)[.\s]", version + " ")
        if m and int(m.group(1)) >= MIN_JAVA:
            return java
    sys.exit(
        f"ERROR: a .java example needs Java {MIN_JAVA} or later; tried {', '.join(seen) or 'nothing'}\n"
        "  macOS:          brew install openjdk\n"
        "  anywhere:       set $JAVA to a Java 25 `java`\n"
    )


def fixed_env() -> dict[str, str]:
    """One environment for every run, so the key is the program's and not the machine's."""
    env = dict(os.environ)
    for k in list(env):
        if k.startswith("LC_") or k in {"LANG", "LANGUAGE"}:
            del env[k]
    # A JVM announces these on stderr ("Picked up JAVA_TOOL_OPTIONS: ...").
    for k in ("JAVA_TOOL_OPTIONS", "_JAVA_OPTIONS", "JDK_JAVA_OPTIONS"):
        env.pop(k, None)
    env.update({
        "LC_ALL": "C",
        "LANG": "C",
        "PYTHONUTF8": "1",
        "PYTHONIOENCODING": "utf-8",
        "GOTOOLCHAIN": "local",  # never download a different Go mid-run
    })
    return env


def _decode(raw: bytes) -> str:
    return raw.decode("utf-8", errors="backslashreplace")


def build_command(src: Path, binary: Path) -> list[str] | None:
    """The compile step for a compiled example, or None for one that is run directly."""
    if src.suffix == ".c":
        return [os.environ.get("CC", "cc"), *C_FLAGS, str(src), "-o", str(binary)]
    if src.suffix == ".cpp":
        return [os.environ.get("CXX", "c++"), *CXX_FLAGS, str(src), "-o", str(binary)]
    if src.suffix == ".rs":
        return ["rustc", "--edition", RUST_EDITION, str(src), "-o", str(binary)]
    if src.suffix == ".go":
        return [go_binary(), "build", "-trimpath", "-o", str(binary), str(src)]
    return None


def run_example(src: Path, workdir: Path) -> str:
    """Run (or compile and run) one example; return its stdout. Exits on failure.

    Run from the example's own folder, so a page can tell the reader to `cd` there
    and type the same command.
    """
    env = fixed_env()
    binary = workdir / src.stem
    build = build_command(src, binary)
    if build is not None:
        done = subprocess.run(build, capture_output=True, text=True, env=env)
        if done.returncode != 0:
            sys.exit(f"ERROR: {src.relative_to(REPO)} failed to compile\n{done.stdout}{done.stderr}")
        if done.stderr.strip():
            print(f"  note: {src.relative_to(REPO)} compiled with warnings:\n{done.stderr}")
        cmd = [str(binary)]
    elif src.suffix == ".java":
        cmd = [java_binary(), src.name]
    elif src.suffix == ".py":
        cmd = [sys.executable, "-I", src.name]
    else:
        cmd = ["bash", src.name]

    proc = subprocess.run(cmd, cwd=src.parent, capture_output=True, env=env, timeout=120)
    if proc.returncode != 0:
        sys.exit(f"ERROR: {src.relative_to(REPO)} exited {proc.returncode}\n{_decode(proc.stderr)}")
    if proc.stderr.strip():
        print(f"  note: {src.relative_to(REPO)} wrote to stderr:\n{_decode(proc.stderr)}")
    return _decode(proc.stdout)


def rendered_block(kind: str, src: Path, output: str, page: Path) -> str:
    """The generated body that goes between the markers on `page`."""
    href = os.path.relpath(src, page.parent)
    if kind == "source":
        body = src.read_text(encoding="utf-8").strip("\n")
        return (
            f"\n*[`{src.name}`]({href}) in full — pasted here by "
            f"`tools/run_examples.py` from the file CI runs.*\n\n"
            f"```{LANGS[src.suffix]}\n{body}\n```\n"
        )
    return (
        f"\n*Verified output of [`{src.name}`]({href}) — regenerated by "
        f"`tools/run_examples.py`, never hand-typed.*\n\n"
        f"```text\n{output.strip(chr(10))}\n```\n"
    )


def fill_pages(
    outputs: dict[str, str],
    sources: dict[str, Path],
    write: bool,
    problems: list[str],
    only: set[str] | None = None,
) -> list[str]:
    """Refill every generated block on every Markdown page. Returns drift.

    A block naming a stem that no longer exists is recorded in `problems` and left
    untouched rather than exiting on the spot. With `only` set, a block naming any
    other stem is left exactly as it is.
    """
    drift: list[str] = []
    for page in sorted(walk(REPO)):
        if page.suffix != ".md":
            continue
        text = page.read_text(encoding="utf-8")
        if "<!-- output:" not in text and "<!-- source:" not in text:
            continue
        skip = fenced_spans(text)

        def replace(m: re.Match) -> str:
            if any(lo <= m.start() < hi for lo, hi in skip):
                return m.group(0)
            stem, kind = m.group("stem"), m.group("kind")
            if only is not None and stem not in only:
                return m.group(0)
            known = sources if kind == "source" else outputs
            if stem not in known:
                problems.append(
                    f"{page.relative_to(REPO)}: asks for {kind} block {stem!r}, "
                    "but no examples/ file has that stem"
                )
                return m.group(0)
            return (
                m.group("open")
                + rendered_block(kind, sources[stem], outputs.get(stem, ""), page)
                + m.group("close")
            )

        new = BLOCK.sub(replace, text)
        if new != text:
            drift.append(str(page.relative_to(REPO)))
            if write:
                page.write_text(new, encoding="utf-8")
    return drift


def examples_under(token: Path, examples: dict[str, Path]) -> set[str]:
    """Every example stem inside `token`, if `token` names a directory."""
    for base in (token, REPO / token):
        try:
            if not base.is_dir():
                continue
            resolved = base.resolve()
        except OSError:
            continue
        held = {s for s, p in examples.items() if resolved in p.parents}
        if held:
            return held
    return set()


def resolve_selection(raw: list[str], examples: dict[str, Path]) -> set[str]:
    """Turn `--only` values into stems. A token that names nothing is an error."""
    wanted: set[str] = set()
    unknown: list[str] = []
    for token in (t.strip() for value in raw for t in value.split(",")):
        if not token:
            continue
        as_path = Path(token)
        held = examples_under(as_path, examples)
        if held:
            wanted |= held
            continue
        for candidate in (token, as_path.stem, as_path.name):
            if candidate in examples:
                wanted.add(candidate)
                break
        else:
            unknown.append(token)
    if unknown:
        sys.exit(
            f"ERROR: --only names no such example: {', '.join(unknown)}\n"
            f"Known stems: {', '.join(sorted(examples))}"
        )
    return wanted


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--update", action="store_true", help="record current output as the answer key")
    ap.add_argument("--check", action="store_true", help="write nothing; fail on drift (CI)")
    ap.add_argument(
        "--only",
        action="append",
        metavar="STEM[,STEM…]",
        help="restrict to these example stems (a path or a folder works too); "
        "repeat the flag or comma-separate. Not for CI.",
    )
    args = ap.parse_args()

    examples = find_examples()
    if not examples:
        print("No examples found under any examples/ folder.")
        return 0

    selected = resolve_selection(args.only, examples) if args.only else None

    outputs: dict[str, str] = {}
    failures: list[str] = []

    with tempfile.TemporaryDirectory(prefix="concurrency-examples-") as tmp:
        workdir = Path(tmp)
        for stem, src in sorted(examples.items()):
            if selected is not None and stem not in selected:
                continue
            key = src.with_suffix(".out")
            actual = run_example(src, workdir)
            outputs[stem] = actual

            if args.update:
                key.write_text(actual, encoding="utf-8")
                print(f"  recorded  {key.relative_to(REPO)}")
                continue
            if not key.exists():
                failures.append(f"{src.relative_to(REPO)}: no answer key — run with --update")
                continue
            recorded = key.read_text(encoding="utf-8")
            if recorded != actual:
                failures.append(f"{src.relative_to(REPO)}: output differs from {key.name}")
                # The diff goes in the log: on a CI runner it is the only place
                # anyone can see which line moved.
                print(f"  DIFF      {src.relative_to(REPO)} (recorded -> actual)")
                for line in difflib.unified_diff(
                    recorded.splitlines(), actual.splitlines(),
                    fromfile=key.name, tofile="actual", lineterm="", n=1,
                ):
                    print("    " + line)
            else:
                print(f"  ok        {src.relative_to(REPO)}")

    drift = fill_pages(outputs, examples, write=not args.check, problems=failures, only=selected)

    if args.check and drift:
        failures.append(
            "Markdown output blocks are stale: " + ", ".join(drift)
            + " — run tools/run_examples.py"
        )
    elif drift:
        for page in drift:
            print(f"  filled    {page}")

    if failures:
        print("\nFAILED:")
        for f in failures:
            print(f"  - {f}")
        return 1

    if selected is not None:
        print(
            f"\n{len(selected)} of {len(examples)} example(s) verified. --only was in "
            f"effect: the other {len(examples) - len(selected)} were left untouched. "
            "Do a full run before committing."
        )
        return 0

    print(f"\n{len(examples)} example(s) verified against their recorded output.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
