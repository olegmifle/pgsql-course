#!/bin/sh
set -eu
source_file=$1
segment=$2
archive=/var/lib/postgresql/hw07/archive
destination=$archive/$segment
if [ -f "$destination" ]; then
  # An existing pathname is acceptable only when its complete contents match.
  cmp -s "$source_file" "$destination"
  exit $?
fi
temporary=$archive/.$segment.$$
trap 'rm -f "$temporary"' 0 1 2 15
cp "$source_file" "$temporary"
sync "$temporary"
mv "$temporary" "$destination"
sync "$archive"
