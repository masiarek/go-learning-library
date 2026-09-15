#!/usr/bin/env bash
# Build the counter from examples/the_race_detector_sh.sh with -race, print one
# report in full, then run it N more times (default 20) with two workers, first
# with GOMAXPROCS unset and then with GOMAXPROCS=1, and count how many reports
# each run printed. -trimpath keeps the temporary directory out of the paths.
#
#   bash demo/race_reports.sh          # from the lesson folder
#   bash demo/race_reports.sh 100
set -u
cd "$(dirname "$0")" || exit 1
runs=${1:-20}
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

# The program is the one the example script writes, so the two cannot drift.
sed -n "/^cat >counter.go <<'GO'\$/,/^GO\$/p" ../examples/the_race_detector_sh.sh | sed '1d;$d' >"$dir/counter.go"
(cd "$dir" && go mod init example 2>/dev/null && go build -race -trimpath -o counter_race .) || exit 1

echo "One run of ./counter_race 2, its first report:"
"$dir/counter_race" 2 2>&1 >/dev/null | awk '/^==================$/ { n++ } n <= 2 { print } n == 2 { exit }'

for procs in "" 1; do
	echo
	echo "Reports per run, over $runs runs with GOMAXPROCS=${procs:-unset}:"
	for _ in $(seq "$runs"); do
		if [ -n "$procs" ]; then
			GOMAXPROCS=$procs "$dir/counter_race" 2 2>&1 >/dev/null
		else
			"$dir/counter_race" 2 2>&1 >/dev/null
		fi | grep -c '^WARNING: DATA RACE$'
	done | sort -n | uniq -c | awk '{ printf "  %4d runs printed %d report(s)\n", $1, $2 }'
done
