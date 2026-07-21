#!/bin/sh
set -eu

# VCS W-2024 writes a malformed picarchive rule that deletes a generated .so
# and recreates it as a self-referential symlink. Patch only that generated
# rule before VCS invokes make.
if [ -f filelist.cu ]; then
  sed -i -E \
    -e '/^[[:space:]]*@rm -f \$@$/d' \
    -e '/^[[:space:]]*@ln -sf \.\/\/\/.* \$@$/d' \
    filelist.cu
fi

exec make "$@"
