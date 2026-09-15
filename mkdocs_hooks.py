"""Build-time fixes that would otherwise cost a pinned plugin dependency.

Three jobs, all about the sidebar. This file is the Ruby text library's (which
is the C library's without its TAB check), with its own reading order:

1. **Clean chapter labels.** MkDocs derives a section label from the folder name
   on disk, so `01_Strings_Carry_an_Encoding/` reads as "01 Strings Carry An
   Encoding". The numeric prefix exists to set reading order in a file listing;
   it should not be visible in the nav. Only *prefixed* folders are relabelled
   from their name — a lesson folder takes its README's own H1 (job 3).

2. **Order the sections.** `NAV_ORDER` states the intended reading order per
   folder, keyed by folder path, listing children by their on-disk name.

3. **Label lessons from their H1.** Left alone, MkDocs titles a lesson folder
   from its name, so `w_is_ascii_b_is_not` reads "W is ascii b is not" — and
   `mkdocs build --strict` passes either way. A lesson folder takes its README's
   H1 instead, backticks dropped. `LABEL_OVERRIDES` holds the exceptions: an H1
   too long for a sidebar.

Why order here rather than by renaming files: a filename is a permanent URL.
Renumbering `03_` to `04_` to insert a chapter would move every page after it
and break any link anyone saved. Ordering is presentation, so it belongs in the
presentation layer. Unlisted pages keep their alphabetical slot at the bottom.

One structural note that is easy to get wrong: the top-level object MkDocs hands
`on_nav` is a `Navigation`, whose children live on `.items`. Only `Section` has
`.children`. A hook that reaches for `.children` at the top level silently does
nothing at all — the build still succeeds, and the sidebar is simply never
touched.
"""

from __future__ import annotations

import re

PREFIX = re.compile(r"^(\d+)[_-]")

# Words the naive title-caser gets wrong.
FIXUPS = {
    "Vs": "vs",
    "And": "and",
    "Or": "or",
    "The": "the",
    "To": "to",
    "A": "a",
    "An": "an",
    "In": "in",
    "Of": "of",
}

# Lesson folders whose sidebar label is deliberately not their H1. Keyed by
# on-disk folder name. An entry naming a folder that no longer exists is a
# silent no-op, which tools/check_nav_chain.py reports.
LABEL_OVERRIDES: dict[str, str] = {}

# Reading order per folder path. Children named by on-disk name; anything not
# listed sorts alphabetically after the listed ones.
NAV_ORDER: dict[str, list[str]] = {
    "": [
        "index.md",
        "00_Start_Here",
        "01_Goroutines",
        "02_Channels",
        "03_Select",
        "04_Sync",
        "05_Context",
        "06_Patterns",
        "07_Testing_Concurrent_Code",
        "08_Resources",
    ],
    # A goroutine's life: how it ends, how its result comes back, how it fails,
    # and then how many a program can afford.
    "01_Goroutines": [
        "README.md",
        "main_does_not_wait",
        "a_goroutine_has_no_handle",
        "a_panic_ends_the_whole_program",
        "goroutines_are_cheap",
    ],
    # The handshake, then the buffer that removes it, then closing a buffer that
    # still holds values, then what the runtime says when everyone is stuck.
    "02_Channels": [
        "README.md",
        "an_unbuffered_send_waits_for_a_receiver",
        "a_buffered_channel_is_a_bounded_queue",
        "closing_a_channel_ends_a_range",
        "all_goroutines_are_asleep",
    ],
    # Waiting and default; several ready cases; time as one more case; switching
    # a case off.
    "03_Select": [
        "README.md",
        "select_waits_on_many",
        "select_chooses_at_random",
        "a_timeout_is_a_channel",
        "a_nil_channel_disables_a_case",
    ],
    # The problem (lost updates), the lock-free fix for one value, run-once
    # setup, and last the WaitGroup's rules, since chapter 01 already uses wg.Go.
    "04_Sync": [
        "README.md",
        "a_mutex_guards_a_counter",
        "atomic_counters",
        "once_runs_exactly_once",
        "a_waitgroup_counts_goroutines",
    ],
    # The mechanism, the mechanism fired by a clock, what happens when a
    # goroutine does not listen, and the error that says why.
    "05_Context": [
        "README.md",
        "cancel_reaches_every_goroutine",
        "a_deadline_is_a_cancel_with_a_clock",
        "a_leaked_goroutine_never_ends",
        "cancel_with_a_cause",
    ],
    # Stages, copies of a stage, a fixed pool that restores order, a limit
    # without a pool, and cancellation driven by the first error.
    "06_Patterns": [
        "README.md",
        "a_pipeline_of_stages",
        "fan_out_fan_in",
        "a_worker_pool",
        "a_buffered_channel_as_a_semaphore",
        "first_error_cancels_the_rest",
    ],
    # The race detector first, because the last lesson uses -race to catch a
    # test that checks too early; the fake clock before Wait, which builds on it.
    "07_Testing_Concurrent_Code": [
        "README.md",
        "the_race_detector",
        "synctest_makes_time_virtual",
        "synctest_wait",
    ],
}


def _label(name: str) -> str:
    """Folder name on disk -> sidebar label."""
    words = PREFIX.sub("", name).replace("_", " ").replace("-", " ").split()
    out = [FIXUPS.get(w.capitalize(), w.capitalize()) for w in words]
    if out:
        out[0] = out[0][0].upper() + out[0][1:]
    return " ".join(out)


def _is_section(item) -> bool:
    return getattr(item, "children", None) is not None


def _first_src(item) -> str:
    """Source path of `item`, or of the first page anywhere beneath it."""
    page_file = getattr(item, "file", None)
    if page_file is not None:
        return page_file.src_uri
    for child in getattr(item, "children", None) or []:
        found = _first_src(child)
        if found:
            return found
    return ""


def _on_disk_name(item, depth: int) -> str:
    """The name NAV_ORDER lists this child by: a filename, or a folder segment."""
    src = _first_src(item)
    if not src:
        return (getattr(item, "title", "") or "").lower()
    parts = src.split("/")
    if not _is_section(item):
        return parts[-1]
    return parts[depth] if depth < len(parts) - 1 else parts[-1]


def _order_key(path: str, name: str) -> tuple[int, str]:
    listed = NAV_ORDER.get(path, [])
    if name in listed:
        return (listed.index(name), "")
    return (len(listed), name.lower())


def _readme_h1(section) -> str:
    """The H1 of a section's own README.md, read from disk ("" if it has none).

    Read from disk because MkDocs fills in a page's title only when it renders
    the page, long after `on_nav`. Backticks are dropped: the sidebar prints
    them as literal characters.
    """
    for child in section.children:
        page_file = getattr(child, "file", None)
        if page_file is None or page_file.src_uri.rsplit("/", 1)[-1] != "README.md":
            continue
        with open(page_file.abs_src_path, encoding="utf-8") as fh:
            for line in fh:
                if line.startswith("# "):
                    return line[2:].strip().replace("`", "")
    return ""


def _visit(items: list, path: str, depth: int) -> None:
    for child in items:
        if not _is_section(child):
            continue
        name = _on_disk_name(child, depth)
        if name in LABEL_OVERRIDES:
            child.title = LABEL_OVERRIDES[name]
        elif PREFIX.match(name):
            child.title = _label(name)
        else:
            child.title = _readme_h1(child) or child.title

    items.sort(key=lambda c: _order_key(path, _on_disk_name(c, depth)))

    for child in items:
        if not _is_section(child):
            continue
        name = _on_disk_name(child, depth)
        _visit(child.children, f"{path}/{name}".lstrip("/"), depth + 1)


def _pages_in_nav_order(items: list) -> list:
    """Every page under `items`, depth-first, in the order the sidebar shows."""
    out = []
    for item in items:
        if item.is_page:
            out.append(item)
        elif item.is_section:
            out.extend(_pages_in_nav_order(item.children))
    return out


def on_nav(nav, config, files):
    """Relabel numbered chapters, apply NAV_ORDER, and re-chain prev/next."""
    _visit(nav.items, "", 0)

    # Sorting nav.items fixes the sidebar and nothing else. MkDocs computes every
    # page's previous_page/next_page inside get_navigation(), which runs BEFORE
    # this hook -- so without the re-chain below, the arrows at the foot of a
    # lesson walk the reader alphabetically while the sidebar beside them reads
    # in order. For a library with a reading order, the arrow IS the order.
    ordered = _pages_in_nav_order(nav.items)
    # Compared by source path, not by identity: MkDocs' Page defines __eq__
    # without __hash__, so a Page cannot go in a set.
    walked = {page.file.src_uri for page in ordered}
    known = {page.file.src_uri for page in nav.pages}
    assert walked == known, (
        "_pages_in_nav_order is out of step with mkdocs.structure.nav: "
        f"missed {sorted(known - walked)}, invented {sorted(walked - known)}"
    )
    for i, page in enumerate(ordered):
        page.previous_page = ordered[i - 1] if i else None
        page.next_page = ordered[i + 1] if i + 1 < len(ordered) else None
    nav.pages[:] = ordered

    return nav
