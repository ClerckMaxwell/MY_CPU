#!/usr/bin/env python3
"""Compare architecture-state CSV snapshots at instruction retirement.

Vivado CSV columns: step, next_pc, RX,RY,RZ,RA,RB,RC,Z,NZ,N,P
Other columns are ignored. Hex values can be 4-digit hexadecimal, 0x-prefixed
hexadecimal, or integer decimal if prefixed d: (d:123).
"""
import argparse
import csv
from pathlib import Path

FIELDS = ('next_pc', 'RX', 'RY', 'RZ', 'RA', 'RB', 'RC', 'Z', 'NZ', 'N', 'P')

def normalized(s):
    s = str(s).strip()
    if s.lower().startswith('d:'):
        return int(s[2:], 10)
    return int(s, 16)

def read(path):
    with path.open(newline='', encoding='utf-8-sig') as fp:
        return list(csv.DictReader(fp))

def main():
    p = argparse.ArgumentParser()
    p.add_argument('expected', type=Path)
    p.add_argument('actual', type=Path)
    p.add_argument('--fields', nargs='+', default=list(FIELDS), help='campi CSV da confrontare')
    args = p.parse_args()
    expected, actual = read(args.expected), read(args.actual)
    for table, path in ((expected, args.expected), (actual, args.actual)):
        if not table:
            raise SystemExit(f'Nessuna riga CSV in {path}')
        missing = set(args.fields) - set(table[0])
        if missing:
            raise SystemExit(f'Campi assenti in {path}: {sorted(missing)}')
    errors = 0
    for i, (e, a) in enumerate(zip(expected, actual), 1):
        for k in args.fields:
            if normalized(e[k]) != normalized(a[k]):
                print(f'MISMATCH instruction {i}: {k}: Python={e[k]} Vivado={a[k]}')
                errors += 1
                if errors >= 20:
                    raise SystemExit(1)
    if len(expected) != len(actual):
        print(f'MISMATCH count: Python={len(expected)} Vivado={len(actual)}')
        errors += 1
    if errors:
        raise SystemExit(1)
    print(f'PASS: {len(expected)} istruzioni, campi {", ".join(args.fields)}')

if __name__ == '__main__':
    main()
