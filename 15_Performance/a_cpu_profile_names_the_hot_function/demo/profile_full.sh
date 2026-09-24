#!/usr/bin/env bash
# The whole `go tool pprof -top` table for the program in
# examples/a_cpu_profile_names_the_hot_function_sh.sh, then the same program's
# heap profile read two ways: by bytes still live (inuse_space, the default)
# and by bytes ever allocated (alloc_space). Every number here moves between
# runs, which is why the key keeps none of them.
#
#   bash demo/profile_full.sh          # from the lesson folder
set -u
cd "$(dirname "$0")" || exit 1
dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
export GOTOOLCHAIN=local

sed -n "/^cat >main.go <<'GO'\$/,/^GO\$/p" ../examples/a_cpu_profile_names_the_hot_function_sh.sh | sed '1d;$d' >"$dir/main.go"
# Add a heap profile at the end of main: runtime.GC first, so the profile is current.
sed -i.bak 's|^\tf.Close()$|\tf.Close()\n\truntime.GC()\n\th, _ := os.Create("mem.prof")\n\tpprof.WriteHeapProfile(h)\n\th.Close()|; s|^\t"os"$|\t"os"\n\t"runtime"|' "$dir/main.go"
cd "$dir" && go mod init example >/dev/null 2>&1 && gofmt -w main.go && go build -o sumreadings . || exit 1
echo '$ go version'
go version
echo '$ ./sumreadings'
./sumreadings
echo '$ go tool pprof -top ./sumreadings cpu.prof'
go tool pprof -top ./sumreadings cpu.prof
echo '$ go tool pprof -top -nodecount=3 ./sumreadings mem.prof'
go tool pprof -top -nodecount=3 ./sumreadings mem.prof
echo '$ go tool pprof -top -nodecount=3 -sample_index=alloc_space ./sumreadings mem.prof'
go tool pprof -top -nodecount=3 -sample_index=alloc_space ./sumreadings mem.prof
