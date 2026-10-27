#!/usr/bin/env python3
"""Converti trace Vivado in schema compare_traces.py; include la word istruzione.
Richiede colonna 'word' aggiunta nel testbench. Il PC interno non viene confrontato.
"""
import argparse
import csv
from pathlib import Path

HEAD = ['step', 'word', 'RX', 'RY', 'RZ', 'RA', 'RB', 'RC', 'Z', 'NZ', 'N', 'P']


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('input', type=Path)
    p.add_argument('output', nargs='?', type=Path, default=Path('trace_vivado_converted.csv'))
    args = p.parse_args()

    with args.input.open('r', newline='', encoding='utf-8-sig') as fp:
        first = fp.readline()
        fp.seek(0)
        sep = ';' if first.count(';') > first.count(',') else ','
        reader = csv.DictReader(fp, delimiter=sep)
        if reader.fieldnames is None:
            p.error('CSV senza intestazione')
        reader.fieldnames = [k.strip().lower() for k in reader.fieldnames]
        required = ['step', 'word', 'rx', 'ry', 'rz', 'ra', 'rb', 'rc', 'flags']
        missing = [k for k in required if k not in reader.fieldnames]
        if missing:
            p.error('Colonne mancanti: ' + ', '.join(missing))

        with args.output.open('w', newline='', encoding='utf-8') as out:
            writer = csv.DictWriter(out, fieldnames=HEAD)
            writer.writeheader()
            n = 0
            for entry in reader:
                if not entry['step'] or not entry['step'].strip():
                    continue
                flags = int(entry['flags'].strip(), 16)
                word = int(entry['word'].strip(), 16)
                if not 0 <= flags <= 0xf or not 0 <= word <= 0xffff:
                    p.error(f'Valore fuori range alla riga step={entry["step"]}')
                row = {'step': entry['step'].strip(), 'word': f'{word:04X}'}
                row.update({r.upper(): f'{int(entry[r].strip(), 16):04X}'
                            for r in ('rx', 'ry', 'rz', 'ra', 'rb', 'rc')})
                row.update({'Z': str((flags >> 3) & 1), 'NZ': str((flags >> 2) & 1),
                            'N': str((flags >> 1) & 1), 'P': str(flags & 1)})
                writer.writerow(row)
                n += 1
    print(f'Convertite {n} istruzioni in {args.output}; PC interno escluso.')

if __name__ == '__main__':
    main()
