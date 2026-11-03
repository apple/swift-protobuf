#!/usr/bin/env python3
#
# Benchmarks/report.py - collate KV lines from run.py into a comparison table.
#
# Copyright (c) 2014 - 2026 Apple Inc. and the project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See LICENSE.txt for license information:
# https://github.com/apple/swift-protobuf/blob/main/LICENSE.txt
#
# -----------------------------------------------------------------------------
#
# The first baseline named on the command line is the reference. Every other baseline
# is reported as a ratio against it. A number above 1.00x is slower or bigger than the
# reference.
#
# -----------------------------------------------------------------------------

import sys
import os

# A run whose interquartile range is more than this fraction of its median was
# probably contended. Do not trust it.
NOISE_THRESHOLD = 0.05


def parse(paths):
    timings = {}   # (type, op) -> {baseline: (median, min, rel_iqr)}
    metrics = {}   # metric -> {baseline: value}
    order = []
    for path in paths:
        with open(path) as handle:
            for line in handle:
                if not line.startswith("KV "):
                    continue
                kv = dict(part.split("=", 1) for part in line.split()[1:])
                baseline = kv["baseline"]
                if baseline not in order:
                    order.append(baseline)
                if "metric" in kv:
                    metrics.setdefault(kv["metric"], {})[baseline] = int(kv["value"])
                else:
                    timings.setdefault((kv["type"], kv["op"]), {})[baseline] = (
                        float(kv["per_op_ns"]),
                        float(kv["per_op_ns_min"]),
                        float(kv["rel_iqr"]),
                    )
    return timings, metrics, order


def ratio(value, reference):
    return f"{value / reference:.2f}x" if reference else "-"


def render(timings, metrics, order):
    reference = order[0]

    print()
    print(f"Wall clock, ns per message (median of repetitions; reference = {reference})")
    print()
    width = max(len(b) for b in order) + 2
    header = f"{'workload':<28}" + "".join(f"{b:>{width + 10}}" for b in order)
    print(header)
    print("-" * len(header))
    noisy = []
    for (type_name, op) in sorted(timings):
        row = f"{type_name + ' ' + op:<28}"
        ref_value = timings[(type_name, op)].get(reference, (0, 0, 0))[0]
        for baseline in order:
            entry = timings[(type_name, op)].get(baseline)
            if entry is None:
                row += f"{'-':>{width + 10}}"
                continue
            median, _minimum, rel_iqr = entry
            if rel_iqr > NOISE_THRESHOLD:
                noisy.append(f"{baseline} {type_name} {op} (IQR {rel_iqr:.1%})")
            cell = f"{median:>10.1f}  {ratio(median, ref_value):>7}"
            row += f"{cell:>{width + 10}}"
        print(row)

    if metrics:
        print()
        print(f"Size, bytes (reference = {reference})")
        print()
        print(header)
        print("-" * len(header))
        for metric in sorted(metrics):
            row = f"{metric:<28}"
            ref_value = metrics[metric].get(reference, 0)
            for baseline in order:
                value = metrics[metric].get(baseline)
                if value is None:
                    row += f"{'-':>{width + 10}}"
                    continue
                cell = f"{value:>10,}  {ratio(value, ref_value):>7}"
                row += f"{cell:>{width + 10}}"
            print(row)

    if noisy:
        print()
        print(f"WARNING: {len(noisy)} measurement(s) exceeded {NOISE_THRESHOLD:.0%} relative IQR:")
        for entry in noisy:
            print(f"  {entry}")
        print("Quiesce the machine and re-run before trusting these.")
    print()


def main():
    paths = sys.argv[1:]
    if not paths:
        print("usage: report.py <results>/*.kv", file=sys.stderr)
        return 1
    timings, metrics, order = parse(paths)
    if not order:
        print("no results found", file=sys.stderr)
        return 1
    render(timings, metrics, order)
    return 0


if __name__ == "__main__":
    sys.exit(main())
