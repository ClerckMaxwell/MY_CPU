# Python scripts — what each one does

| Script | Input | Output | Responsibility |
| --- | --- | --- | --- |
| `tools/assembler/assembler.py` | `.asm` | `.coe`, `.hex`, `.mem` | Parses assembly, encodes instructions and registers, resolves symbolic targets and loop labels, checks nesting depth (default 3). |
| `tools/simulator/simulator.py` | machine words (`.coe`, `.hex`, `.mem`) | `trace_python.csv`, `final_state.json` | Instruction-accurate reference model of registers, flags, RAM and control flow. Runs one architectural instruction per `step()`; does not model clock edges. |
| `tools/simulator/smoke_test.py` | no external input | terminal test results | Quick unit/smoke checks of selected ISA operations, arithmetic and jumps. Not a full verification suite. |
| `tools/verification/convert_vivado_trace.py` | `trace_vivado.csv` | `trace_vivado_converted.csv` | Normalizes lowercase Vivado fields, hexadecimal register values, instruction word; unpacks 4-bit `flags` into `Z,NZ,N,P`. Intentionally excludes the raw PC. |
| `tools/verification/compare_traces.py` | two normalized CSV traces | `PASS` or first mismatches | Compares corresponding retired instructions field-by-field; returns a nonzero status on mismatch or row count difference. |

## Sequence

1. Edit `programs/example.asm` (or `esempio.asm`).
2. Assemble into COE. The assembler counts **memory words**, including immediate operands; absolute jumps are encoded as `12-bit address + 4-bit opcode`.
3. Initialize Vivado Block RAM using the COE, regenerate its output products if required, run the behavioral testbench.
4. Run the same COE in `simulator.py`.
5. Convert Vivado's trace and compare.

## Command examples

```bash
python tools/assembler/assembler.py programs/salti.asm -o programs/salti.coe --symbols
python tools/simulator/simulator.py programs/salti.coe --max-steps 100 --trace trace_python.csv
python tools/verification/convert_vivado_trace.py trace_vivado.csv
python tools/verification/compare_traces.py trace_python.csv trace_vivado_converted.csv --fields word RX RY RZ RA RB RC Z NZ N P
```

**Terminology:** `.asm` is human-readable assembly; `.coe` initializes BRAM; `.csv` is a per-retired-instruction trace; `.json` summarizes final software state. `--max-steps` prevents infinite simulations of loops. The assembler and software model are separate intentionally: one emits machine code, the other interprets it and can catch independent RTL mismatches.

**Potential future improvements:** a single CLI runner (assemble -> simulate -> compare), separate test vectors for control flow and RAM, randomized tests with saved seeds, richer mismatch reports showing instruction addresses.
