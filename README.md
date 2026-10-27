# MY_CPU — Custom 16-bit VHDL processor

A custom 16-bit, multi-cycle CPU implemented in VHDL, with its own instruction set, Python assembler, instruction-level reference simulator, and automated RTL-vs-software trace comparison.

> **Verification milestone:** 30 retired instructions matched between the Python reference model and Vivado for the instruction word, all six registers, and all four flags. This is a single-program regression result, **not** exhaustive verification or proof of timing closure.

## Architecture

- Six 16-bit registers: `RX`, `RY`, `RZ`, `RA`, `RB`, `RC`.
- Multi-cycle control FSM and a custom arithmetic / comparison datapath.
- Shared memory via Xilinx Block Memory Generator IP.
- Immediate and register arithmetic, memory access, comparison, register moves.
- Hardware loop-address stack (three nested levels as currently implemented).
- Absolute conditional jumps encoded with a 12-bit target: `JUMPIZ` (`0xD`) and `JUMPINZ` (`0xE`).
- `instruction_retired` pulse to capture architectural state after each completed instruction.

The instruction word has a 4-bit opcode in bits `[3:0]`. Register-to-register operations encode the destination in bits `[11:8]` and source in `[7:4]`. Immediate memory instructions can occupy two 16-bit words. For an example, `052C` means `MOVE RC, RZ`, and `021A` means `ADDR RZ, RY`.

## Repository layout

```text
MY_CPU/
├── MY_CPU.xpr                  # Existing Vivado project: keep at root
├── MY_CPU.srcs/               # Existing Vivado RTL/IP/simulation sources
├── README.md
├── .gitignore
├── tools/
│   ├── assembler/assembler.py
│   ├── simulator/{simulator.py,smoke_test.py}
│   └── verification/{convert_vivado_trace.py,compare_traces.py,TOP_CPU_tb_example.vhd}
├── programs/{esempio.asm,salti.asm}
└── docs/{TOOLCHAIN.md,VERIFICATION.md}
```

**Migration note:** `tools/`, `programs/` and `docs/` are additions to the current Vivado repository. **Do not move `MY_CPU.xpr`, `MY_CPU.srcs` or the Block Memory Generator IP paths blindly:** Vivado 2018.3 can retain path-dependent IP references. `TOP_CPU_tb_example.vhd` is a reference copy; use your already working Vivado testbench as the source of truth and port any improvements to it.

## Quick start

Requirements: Python 3, no third-party Python packages for these scripts; Vivado 2018.3 for RTL simulation.

From the repository root:

```bash
# Assembly -> .coe for the Vivado block RAM
python tools/assembler/assembler.py programs/esempio.asm -o programs/esempio.coe --symbols

# Instruction-level software model -> CSV + JSON
python tools/simulator/simulator.py programs/esempio.coe --max-steps 100 --trace trace_python.csv --state final_state.json

# Built-in Python smoke tests
python tools/simulator/smoke_test.py
```

Run the Behavioral Simulation using your project testbench. It should write `trace_vivado.csv` (usually inside the XSim working directory). Then:

```bash
python tools/verification/convert_vivado_trace.py trace_vivado.csv trace_vivado_converted.csv
python tools/verification/compare_traces.py trace_python.csv trace_vivado_converted.csv --fields word RX RY RZ RA RB RC Z NZ N P
```

Do **not** compare the Vivado internal `PC` directly with the Python `next_pc`: the FSM prefetches memory and those signals have different meanings. The instruction word comparison helps validate the instruction sequence without imposing an incorrect PC offset.

## How the tools fit together

```text
Assembly (.asm)
     |
     v
assembler.py ------> program.coe ---------> Vivado Block RAM / TOP_CPU_tb
                         |                             |
                         v                             v
                    simulator.py                 trace_vivado.csv
                         |                             |
                         v                             v
                  trace_python.csv         convert_vivado_trace.py
                         |                             |
                         +------> compare_traces.py <--+
                                      |
                                PASS / MISMATCH
```

See [Toolchain](docs/TOOLCHAIN.md) for each Python script and [Verification](docs/VERIFICATION.md) for trace conventions and known limitations.

## Current verification scope and next steps

The current differential test compares the retired **instruction word**, `RX`, `RY`, `RZ`, `RA`, `RB`, `RC`, and flags `Z`, `NZ`, `N`, `P`. More useful coverage: check RAM write transactions (address/data), exercise more nested-loop and jump programs, and automate regression execution. The Python model executes **instructions**, not the clock-by-clock FSM. `0000` is used by the simulator as an end-of-test sentinel; it is **not** a documented RTL `HALT` instruction.

## 👤 Author

**Raffaele Petrolo**
This project started as an attempt to understand what happens inside a processor, from the adder logic to instruction execution. The longer-term experiments include graphical output and increasingly complex software. Running a port of DOOM is an aspiration, not a current capability.
