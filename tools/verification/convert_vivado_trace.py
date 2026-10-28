
# !/usr/bin/env python3
"""Converti il trace Vivado nello schema di compare_traces.py.

Il testbench salva nella riga N la word dell'istruzione N ma i registri e
flag aggiornati sono nella riga N+1. Perciò uniamo word[N] e stato[N+1].
Il PC interno della FSM non viene confrontato.
"""
import argparse
import csv
from pathlib import Path

HEAD = ['step', 'word', 'RX', 'RY', 'RZ', 'RA', 'RB', 'RC', 'Z', 'NZ', 'N', 'P']
REGS = ('rx', 'ry', 'rz', 'ra', 'rb', 'rc')


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('input', type=Path)
    p.add_argument('output', nargs='?', type=Path,
                   default=Path('trace_vivado_converted.csv'))
    args = p.parse_args()

    with args.input.open('r', newline='', encoding='utf-8-sig') as fp:
        first = fp.readline()
        fp.seek(0)
        sep = ';' if first.count(';') > first.count(',') else ','
        reader = csv.DictReader(fp, delimiter=sep)
        if reader.fieldnames is None:
            p.error('CSV senza intestazione')
        reader.fieldnames = [k.strip().lower() for k in reader.fieldnames]
        required = ['step', 'word', *REGS, 'flags']
        missing = [k for k in required if k not in reader.fieldnames]
        if missing:
            p.error('Colonne mancanti: ' + ', '.join(missing))
        entries = [row for row in reader if row.get('step') and row['step'].strip()]

    if len(entries) < 2:
        p.error('Servono almeno due righe: word della prima e stato della successiva')

    with args.output.open('w', newline='', encoding='utf-8') as out:
        writer = csv.DictWriter(out, fieldnames=HEAD)
        writer.writeheader()
        for i in range(len(entries) - 1):
            instruction = entries[i]
            state = entries[i + 1]
            try:
                word = int(instruction['word'].strip(), 16)
                flags = int(state['flags'].strip(), 16)
                reg_values = {r.upper(): int(state[r].strip(), 16) for r in REGS}
            except (ValueError, TypeError, AttributeError) as exc:
                p.error(f'Valore non valido nelle righe {i + 1}-{i + 2}: {exc}')
            if not (0 <= word <= 0xFFFF and 0 <= flags <= 0xF and
                    all(0 <= v <= 0xFFFF for v in reg_values.values())):
                p.error(f'Valore fuori range nelle righe {i + 1}-{i + 2}')
            row = {
                'step': str(i + 1),
                'word': f'{word:04X}',
                **{r: f'{v:04X}' for r, v in reg_values.items()},
                'Z': str((flags >> 3) & 1),
                'NZ': str((flags >> 2) & 1),
                'N': str((flags >> 1) & 1),
                'P': str(flags & 1),
            }
            writer.writerow(row)

    print(f'Convertite {len(entries) - 1} istruzioni in {args.output}; PC interno escluso.')
    print('Allineamento: word riga N + registri/flag riga N+1; ultima word senza stato esclusa.')


if __name__ == '__main__':
    main()

