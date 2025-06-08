#!/bin/sh -v
# Show hashes that exist in A but are not found in B
# This is useful for spotting files that you used to have but are no longer present in a new hash file, ignoring anything that was added or moved.
# This is what you want to know when you are checking if you have any data loss or corruption.
cargo run --bin md5-diff -- a.md5 b.md5 | grep --regexp '^\+A' | awk '{print $2 " " $3}'
