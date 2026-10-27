#!/usr/bin/env python3
"""MY_CPU ISA reference model: one step = one *instruction*, not a clock.

Assumptions not fully settled by FSM alone:
- PC in this model is the address of the next instruction word (architectural PC).
- hardware LABEL denotes loop-body entry and pushes it only once per active loop.
- CMP_RES is sign-of-16-bit modular subtraction as implemented in ALU RTL.
- fetch/initialization details and ALU behaviour require RTL-level confirmation.
"""
from __future__ import annotations
import argparse
import csv
import json
import re
from dataclasses import dataclass, field
from pathlib import Path

NAMES = ('RX', 'RY', 'RZ', 'RA', 'RB', 'RC')
OP_NAMES = ('FETCH', 'STORE', 'LOAD', 'LOADM', 'ADD', 'SUB', 'JUMPZ',
            'JUMPNZ', 'COMPARE', 'LABEL', 'ADDR', 'SUBR', 'MOVE',
            'JUMPIZ', 'JUMPINZ')
DOUBLE_WORD = {1, 2, 3, 4, 5}
MASK = 0xffff


def read_program(path: Path) -> list[int]:
    txt = path.read_text(encoding='utf-8-sig')
    if path.suffix.lower() == '.coe' or 'memory_initialization_vector' in txt.lower():
        match = re.search(r'memory_initialization_radix\s*=\s*(\d+)\s*;', txt, re.I)
        radix = int(match.group(1)) if match else 16
        match = re.search(r'memory_initialization_vector\s*=\s*(.*?);', txt, re.I | re.S)
        if not match:
            raise ValueError('Formato COE non valido: manca memory_initialization_vector')
        items = [s.strip() for s in re.split(r'[\s,]+', match.group(1)) if s.strip()]
        words = [int(s, radix) for s in items]
    else:
        words = []
        for line in txt.splitlines():
            line = re.split(r'[;#]', line, 1)[0].strip()
            if not line:
                continue
            for tok in re.split(r'[\s,]+', line):
                if tok:
                    words.append(int(tok, 16))
    if not words or any(not 0 <= w <= MASK for w in words):
        raise ValueError('Programma vuoto o word fuori range 16 bit')
    return words


@dataclass
class CPU:
    mem: list[int]
    pc: int = 0
    compare_mode: str = 'rtl'
    registers: list[int] = field(default_factory=lambda: [0] * 6)
    flagz: int = 0
    flagnz: int = 0
    flagn: int = 0
    flagp: int = 0
    loop_stack: list[int] = field(default_factory=list)
    steps: int = 0
    writes: dict[int, int] = field(default_factory=dict)

    def __post_init__(self):
        self.mem = (self.mem + [0] * (65536 - len(self.mem)))[:65536]

    def read(self, addr: int) -> int:
        return self.mem[addr & MASK]

    def next_word(self) -> int:
        value = self.read(self.pc)
        self.pc = (self.pc + 1) & MASK
        return value

    def getreg(self, idx: int) -> int:
        if idx >= 6:
            raise ValueError(f'Registro non valido: {idx}')
        return self.registers[idx]

    def setreg(self, idx: int, value: int):
        if idx >= 6:
            raise ValueError(f'Registro non valido: {idx}')
        self.registers[idx] = value & MASK

    def step(self) -> dict:
        before = self.pc
        inst = self.next_word()
        op = inst & 0xf
        low = (inst >> 4) & 0xf
        high = (inst >> 8) & 0xf
        name = OP_NAMES[op] if op < len(OP_NAMES) else 'UNKNOWN'
        operands = ''
        write = ''
        # The FSM clears compare flags at instruction dispatch. Preserve them
        # only for the immediately following branch instruction.
        z, nz = self.flagz, self.flagnz
        self.flagz = self.flagnz = self.flagn = self.flagp = 0
        if op == 0:  # FETCH is used as zero-op / unspecified by FSM
            raise ValueError('Opcode FETCH (0) non implementato nella FSM: esecuzione interrotta')
        elif op in DOUBLE_WORD:
            arg = self.next_word()
            operands = f'{NAMES[low]}, 0x{arg:04X}' if low < 6 else f'R{low}, 0x{arg:04X}'
            if op == 1:   # STORE
                self.mem[arg] = self.getreg(low)
                self.writes[arg] = self.mem[arg]
                write = f'MEM[{arg:04X}]={self.mem[arg]:04X}'
            elif op == 2:  # LOAD
                self.setreg(low, arg)
            elif op == 3:  # LOADM
                self.setreg(low, self.read(arg))
            elif op == 4:  # ADD
                self.setreg(low, self.getreg(low) + arg)
            elif op == 5:  # SUB
                self.setreg(low, self.getreg(low) - arg)
        elif op in (10, 11, 12, 8):
            operands = f'{NAMES[high]}, {NAMES[low]}' if max(low, high) < 6 else f'R{high}, R{low}'
            a, b = self.getreg(high), self.getreg(low)
            if op == 10:
                self.setreg(high, a + b)
            elif op == 11:
                self.setreg(high, a - b)
            elif op == 12:
                self.setreg(high, b)
            else:
                # ALU.vhd: COMPARE_FIT = FAST_COMP_C + not(FAST_COMP_D) + 1.
                # The 16-bit sign bit is used directly, including overflow cases.
                diff = (a - b) & MASK
                self.flagz = int(diff == 0)
                self.flagnz = int(diff != 0)
                self.flagn = int(bool(diff & 0x8000))
                self.flagp = int(diff != 0 and not self.flagn)
        elif op == 9:  # LABEL saves loop entry
            if len(self.loop_stack) >= 3:
                raise ValueError('Stack loop oltre 3 livelli')
            self.loop_stack.append(self.pc)
        elif op in (6, 7):
            should_jump = z if op == 6 else nz
            if not self.loop_stack:
                raise ValueError(f'{name} senza LABEL attivo')
            if should_jump:
                self.pc = self.loop_stack[-1]
            else:
                self.loop_stack.pop()
        elif op in (13, 14):
            target = (inst >> 4) & 0xfff
            operands = f'0x{target:03X}'
            if (z if op == 13 else nz):
                self.pc = target
        else:
            raise ValueError(f'Opcode 0x{op:X} non supportato')
        self.steps += 1
        return dict(step=self.steps, address=f'{before:04X}', word=f'{inst:04X}',
                    opcode=name, operands=operands, next_pc=f'{self.pc:04X}',
                    **{k: f'{v:04X}' for k, v in zip(NAMES, self.registers)},
                    Z=self.flagz, NZ=self.flagnz, N=self.flagn, P=self.flagp,
                    loops='|'.join(f'{v:04X}' for v in self.loop_stack), memory_write=write)


def main():
    p = argparse.ArgumentParser(description='MY_CPU reference simulator (instruction-accurate)')
    p.add_argument('program', type=Path, help='programma .coe / .mem / .hex')
    p.add_argument('--max-steps', type=int, default=1000)
    p.add_argument('--start', type=lambda x: int(x, 0), default=0, help='indirizzo di prima istruzione (default 0)')
    p.add_argument('--compare-mode', choices=('rtl',), default='rtl', help='FLAGN/P derivati dal bit 15 di (A-B) mod 2^16')
    p.add_argument('--trace', type=Path, default=Path('trace_python.csv'))
    p.add_argument('--state', type=Path, default=Path('final_state.json'))
    args = p.parse_args()
    cpu = CPU(read_program(args.program), pc=args.start, compare_mode=args.compare_mode)
    rows = []
    stop = 'max_steps'
    for _ in range(args.max_steps):
        if cpu.read(cpu.pc) == 0:
            stop = f'zero_word_at_{cpu.pc:04X}'
            break
        try:
            rows.append(cpu.step())
        except ValueError as exc:
            stop = f'ERROR at {cpu.pc:04X}: {exc}'
            break
    if rows:
        with args.trace.open('w', newline='', encoding='utf-8') as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)
    state = dict(stop=stop, instructions=cpu.steps, pc=f'{cpu.pc:04X}',
                 registers={k: f'{v:04X}' for k, v in zip(NAMES, cpu.registers)},
                 flags=dict(Z=cpu.flagz, NZ=cpu.flagnz, N=cpu.flagn, P=cpu.flagp),
                 loop_stack=[f'{v:04X}' for v in cpu.loop_stack],
                 modified_memory={f'{k:04X}': f'{v:04X}' for k, v in sorted(cpu.writes.items())})
    args.state.write_text(json.dumps(state, indent=2), encoding='utf-8')
    print(json.dumps(state, indent=2))
    if stop.startswith('ERROR'):
        raise SystemExit(1)


if __name__ == '__main__':
    main()
