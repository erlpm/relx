#!/usr/bin/env bash

set -xe

cd $(dirname $(realpath $0))

export TERM=dumb

find . -name _build | xargs rm -rf

current_dir=$(pwd)
epm_dir=$(mktemp -d)

pushd "${epm_dir}"

# clone latest epm and build with relx as a checkout
git clone https://github.com/erlpm/epm .
mkdir _checkouts
ln -s "$current_dir/../../relx" _checkouts/relx
sed -i 's_relx\(.*\)build/default/lib/_relx\1checkouts_' epm.config
./bootstrap

popd

PATH="${epm_dir}":~/.cabal/bin/:$PATH shelltest -c --diff --all --execdir -- */*.test
