#!/usr/bin/env python3
"""MY_CPU assembler. Word addressed, origin 0, jump immediate address 12 bit."""
import argparse
import re
from pathlib import Path

OPS = dict(FETCH=0, STORE=1, LOAD=2, LOADM=3, ADD=4, SUB=5,
           JUMPZ=6, JUMPNZ=7, COMPARE=8, LABEL=9, ADDR=10,
           SUBR=11, MOVE=12, JUMPIZ=13, JUMPINZ=14)
REG = dict(RX=0, RY=1, RZ=2, RA=3, RB=4, RC=5)
IMM = {'STORE', 'LOAD', 'LOADM', 'ADD', 'SUB'}
PAIR = {'COMPARE', 'ADDR', 'SUBR', 'MOVE'}
HWJ = {'JUMPZ', 'JUMPNZ'}
ABSJ = {'JUMPIZ', 'JUMPINZ'}
RE_LABEL = re.compile(r'^([A-Za-z_][A-Za-z_0-9]*):(?:\s*(.*))?$')
RE_LOOP = re.compile(r'^LOOP\s+([A-Za-z_][A-Za-z_0-9]*):(?:\s*(.*))?$', re.I)


def number(token):
    try:
        return int(token, 0) if not re.fullmatch(r'[0-9]+', token) else int(token, 10)
    except ValueError:
        raise ValueError(f'numero non valido: {token}') from None


def parse(source):
    items = []
    for line_no, raw in enumerate(source.splitlines(), 1):
        line = raw.split(';', 1)[0].split('#', 1)[0].strip()
        if not line:
            continue
        while line:
            m = RE_LOOP.fullmatch(line) or RE_LABEL.fullmatch(line)
            if m:
                items.append((line_no, 'LABEL_DECL', [m[1].upper()], line.upper().startswith('LOOP ')))
                line = (m[2] or '').strip()
                continue
            tokens = line.replace(',', ' ').split()
            items.append((line_no, tokens[0].upper(), [x.upper() for x in tokens[1:]], False))
            break
    return items


def assemble(source, max_depth=3):
    items = parse(source)
    hardware_targets = set()
    for ln, op, args, _ in items:
        if op in HWJ and len(args) == 1:
            hardware_targets.add(args[0])
    symbols = {}
    kind = {}
    pos = 0
    # Passaggio 1: conta le word e risolve gli indirizzi delle label.
    for ln, op, args, forced_hw in items:
        if op == 'LABEL_DECL':
            name = args[0]
            if name in symbols:
                raise ValueError(f'Riga {ln}: label duplicata {name}')
            hw = forced_hw or name in hardware_targets
            symbols[name] = pos
            kind[name] = 'hw' if hw else 'abs'
            if hw:
                pos += 1  # LABEL e una istruzione vera: 0009
        elif op in IMM:
            pos += 2
        elif op in OPS:
            pos += 1
        else:
            raise ValueError(f'Riga {ln}: istruzione sconosciuta {op}')
        if pos > 65536:
            raise ValueError('Programma troppo grande per indirizzi a 16 bit')
    words = []
    active = []
    for ln, op, args, forced_hw in items:
        try:
            if op == 'LABEL_DECL':
                label = args[0]
                if kind[label] == 'hw':
                    active.append(label)
                    if len(active) > max_depth:
                        raise ValueError(f'superata profondita loop {max_depth}')
                    words.append(OPS['LABEL'])
            elif op in IMM:
                if len(args) != 2 or args[0] not in REG:
                    raise ValueError(f'{op} richiede REG, valore')
                value = number(args[1])
                if not 0 <= value <= 0xffff:
                    raise ValueError('immediato fuori range 0..65535')
                words.extend([(REG[args[0]] << 4) | OPS[op], value])
            elif op in PAIR:
                if len(args) != 2 or any(r not in REG for r in args):
                    raise ValueError(f'{op} richiede DEST, SRC')
                words.append((REG[args[0]] << 8) | (REG[args[1]] << 4) | OPS[op])
            elif op in ABSJ:
                if len(args) != 1:
                    raise ValueError(f'{op} richiede indirizzo o label')
                target = symbols[args[0]] if args[0] in symbols else number(args[0])
                if not 0 <= target <= 0xfff:
                    raise ValueError('destinazione fuori range 0x000..0xFFF')
                words.append((target << 4) | OPS[op])
            elif op in HWJ:
                if len(args) > 1:
                    raise ValueError(f'{op} ammette al massimo una label')
                if args:
                    name = args[0]
                    if name not in symbols or kind[name] != 'hw':
                        raise ValueError(f'loop non definito: {name}')
                    if not active or active[-1] != name:
                        raise ValueError(f'{op} deve riferirsi al loop piu interno')
                    active.pop()  # convenzione lessicale, non modifica hardware
                words.append(OPS[op])
            elif op in ('FETCH', 'LABEL'):
                if args:
                    raise ValueError(f'{op} non accetta operandi')
                words.append(OPS[op])
            else:
                raise ValueError(f'istruzione non supportata: {op}')
        except ValueError as exc:
            raise ValueError(f'Riga {ln}: {exc}') from None
    return words, symbols


def main():
    p = argparse.ArgumentParser(description='MY_CPU assembler (indirizzi word da zero)')
    p.add_argument('input', type=Path)
    p.add_argument('-o', '--output', type=Path)
    p.add_argument('--max-depth', type=int, default=3)
    p.add_argument('--symbols', action='store_true', help='stampa indirizzi label')
    a = p.parse_args()
    if a.max_depth < 1:
        p.error('--max-depth deve essere positivo')
    out = a.output or a.input.with_suffix('.coe')
    if out.suffix.lower() not in ('.coe', '.hex', '.mem'):
        p.error('formato supportato: .coe, .hex, .mem')
    try:
        words, labels = assemble(a.input.read_text(encoding='utf-8'), a.max_depth)
        if out.suffix.lower() == '.coe':
            data = 'memory_initialization_radix=16;\nmemory_initialization_vector=\n' + ',\n'.join(f'{x:04X}' for x in words) + ';\n'
        else:
            data = '\n'.join(f'{x:04X}' for x in words) + '\n'
        out.write_text(data, encoding='utf-8')
    except (ValueError, OSError) as exc:
        p.error(str(exc))
    print(f'{len(words)} word -> {out}')
    if a.symbols:
        for k, v in labels.items():
            print(f'{k:20s} = 0x{v:03X}')


if __name__ == '__main__':
    main()
