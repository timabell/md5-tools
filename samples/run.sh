#/bin/sh -v
# A very rudimentary test

# should error and show usage
cargo run --bin md5-diff

# should error for missing files
cargo run --bin md5-diff -- nothing-here  and-nothing-here

set -e # exit on error

cargo run --bin md5-diff -h
cargo run --bin md5-diff -- a.md5 b.md5
cargo run --bin md5-diff -- --gzip a.md5.gz b.md5.gz
