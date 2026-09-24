#!/usr/bin/env bash
# Run the fuzzing engine against the Parse from examples/fuzzing_seed_corpus_sh.sh
# for up to N seconds (default 10) and print what it reports: the input it
# found, where it wrote the corpus file, and the file's contents. The
# worker count, the elapsed times, the file's name (a hash of the input)
# and the input itself can all differ between runs, which is why this is a
# demo and not an example.
#
#   bash demo/fuzz_run.sh          # from the lesson folder
#   bash demo/fuzz_run.sh 30
set -u
cd "$(dirname "$0")" || exit 1
seconds=${1:-10}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

# The package and the fuzz target are the ones the example script writes.
sed -n "/^cat >sku.go <<'GO'\$/,/^GO\$/p" ../examples/fuzzing_seed_corpus_sh.sh | sed '1d;$d' >"$dir/sku.go"
sed -n "/^cat >sku_test.go <<'GO'\$/,/^GO\$/p" ../examples/fuzzing_seed_corpus_sh.sh | sed '1d;$d' >"$dir/sku_test.go"
cd "$dir" && go mod init example 2>/dev/null

echo "\$ go test -run=FuzzParse -fuzz=FuzzParse -fuzztime=${seconds}s"
# Drop the goroutine trace under the panic line: frames end in ")", paths
# start with "/", and the "goroutine N [running]:" and "created by" lines.
go test -run=FuzzParse -fuzz=FuzzParse -fuzztime="${seconds}s" 2>&1 | grep -v -E '^[[:space:]]+(/|.*\)$|created by |goroutine [0-9]+ \[)' | grep -v '^[[:space:]]*$' | sed -E "s#$dir#<tmp>#g"
echo "exit status ${PIPESTATUS[0]}"
echo
for f in testdata/fuzz/FuzzParse/*; do
	echo "\$ cat $f"
	cat "$f"
done
