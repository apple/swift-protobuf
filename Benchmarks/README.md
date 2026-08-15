# Benchmarks

Wall-clock and code-size benchmarks for comparing swift-protobuf branches on real-world
message shapes.

This exists next to the older [`Performance/`](../Performance) harness rather than
replaces it. The two answer different questions. `Performance/` generates synthetic
messages, N fields of one type or one of every type. It is the right tool for "*which
field kind* regressed". This one decodes checked-in fixtures from real schemas. It is
the right tool for "what would an app see".

## Running

```sh
./run.py                                    # upstream main vs. this worktree
./run.py main=../../swift-protobuf td=..    # explicit baselines
SP_REPETITIONS=15 ./run.py                  # more timed repetitions
SP_GEN_OPTS=ExperimentalHiddenNames=All ./run.py
```

A "baseline" is a whole swift-protobuf checkout. Both the runtime *and* the
`protoc-gen-swift` that generates the message types come from it. The table-driven branch
emits a different shape of generated code than main. The measurement therefore covers
codegen and runtime together, which is what ships.

Results land in `_results/<label>.kv` as `KV key=value` lines. `report.py` collates them.
The first baseline named is the reference. Other baselines are shown as a ratio against
it.

## Methodology

Every measurement warms up for at least 200 ms before the first timed batch. It then
reports the **median** of `SP_REPETITIONS` batches along with the min and the relative
interquartile range. `report.py` prints a warning that names any measurement whose
relative IQR was more than 5%. That value means the machine was contended and you must
discard the run.

This is a deliberate departure from `Performance/Harness.swift`, which does no warmup
and takes the mean of all ten attempts. Cold iterations dominate that mean. A 5-field
message measured there showed encode fall monotonically from 1.657 µs on attempt 1 to
0.662 µs on attempt 10, for a relative stddev of 24–35%.

Each type has a full decode → encode → decode round-trip equality check before it is
timed. A decoder that silently drops fields then cannot post a fast number.

## Fixtures

- `protos/catalog.proto` + `fixtures/catalog_entries.pb` — `CatalogEntry`, ~80 fields
  across scalars, enums, submessages, repeated fields and strings. 1000 messages of
  recorded data. Shared with a companion Swift decoder's benchmarks and with
  `tools/upb-benchmark` in that repo, so numbers are comparable across all three
  implementations.

Fixtures are checked in rather than synthesized so that every baseline decodes
byte-identical input.

## Notes

`run.py` passes `--disable-sandbox` to SwiftPM. Manifest compilation runs `swiftc`
under `sandbox-exec`. That fails with `sandbox_apply: Operation not permitted` when the
build already runs inside a sandbox.
