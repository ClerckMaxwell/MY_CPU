# MY_CPU — Custom 16-bit VHDL Processor

A custom 16-bit, multi-cycle processor designed in VHDL, with its own instruction set architecture (ISA), Python assembler, instruction-level software simulator, and automated comparison between RTL and software execution traces.

The project began as an attempt to understand how processors work, starting from basic arithmetic circuits and progressing to an executable CPU and its supporting software tools.

## Verification milestones

The Python reference simulator and the Vivado behavioral simulation have produced matching **instruction words, all six registers, and all four condition flags** for:

| Program | Retired instructions | Result |
| --- | ---: | --- |
| Basic instruction test | 30 | **PASS** |
| Extended stress test | 102 | **PASS** |

The extended test exercises arithmetic, memory operations, conditional jumps and three levels of nested hardware loops. These are program-level regression results, **not exhaustive ISA verification or proof of timing closure**. Memory write transactions are not yet compared independently.

## Architecture

- **Datapath:** 16-bit data and instructions, with six 16-bit general-purpose registers: `RX`, `RY`, `RZ`, `RA`, `RB`, `RC`.
- **Control:** multi-cycle finite state machine coordinating memory operations, instruction execution and register updates.
- **Arithmetic:** custom adder-based ALU supporting arithmetic operations and comparisons.
- **Memory:** Xilinx Block Memory Generator IP, used for program and data storage.
- **Control flow:** three-level hardware loop-address stack and absolute conditional jumps.
- **Verification interface:** `instruction_retired` signal and instruction/register/flag debug outputs for execution tracing.

### Instruction format

The opcode occupies bits `[3:0]` of each 16-bit instruction. For register-to-register operations, the destination register is encoded in bits `[11:8]` and the source register in bits `[7:4]`.

```asm
MOVE RC, RZ    ; 052C — RC = RZ
ADDR RZ, RY    ; 021A — RZ = RZ + RY
```

Instructions with immediate values or memory addresses may occupy two consecutive 16-bit words. Absolute conditional jumps embed a 12-bit address in the instruction word:

- `JUMPIZ` (`0xD`): jump to the encoded address when the zero flag is set.
- `JUMPINZ` (`0xE`): jump to the encoded address when the non-zero flag is set.

The existing `LABEL`, `JUMPZ` and `JUMPNZ` instructions support hardware-managed loop control; the software assembler additionally supports symbolic labels.

## Repository structure

```text
MY_CPU/
├── MY_CPU.xpr
├── MY_CPU.srcs/                 # Vivado RTL, IP and simulation sources
├── tools/
│   ├── assembler/assembler.py
│   ├── simulator/
│   │   ├── simulator.py
│   │   └── smoke_test.py
│   └── verification/
│       ├── convert_vivado_trace.py
│       └── compare_traces.py
├── programs/                    # Assembly programs and memory initialization files
├── docs/
│   ├── TOOLCHAIN.md
│   └── VERIFICATION.md
├── .gitignore
└── README.md
```

The Vivado project and its IP sources remain in their existing locations to avoid breaking project-relative paths in Vivado 2018.3.

## Quick start

**Requirements:** Python 3 (no third-party packages for the supplied scripts) and Vivado 2018.3 for the VHDL simulation.

The commands below assume you are in the repository root; adapt file names to the program you want to test.

### 1. Assemble a program

```bash
python tools/assembler/assembler.py programs/esempio.asm -o programs/esempio.coe --symbols
```

### 2. Run the instruction-level Python simulator

```bash
python tools/simulator/simulator.py programs/esempio.coe --max-steps 100 --trace trace_python.csv --state final_state.json
```

The software model executes complete instructions, not individual FSM clock cycles. It writes the execution trace and a final architectural state summary.

### 3. Run the RTL behavioral simulation

Open `MY_CPU.xpr` in Vivado, load the **same** program into the Block Memory Generator, and run the existing testbench. The testbench exports `trace_vivado.csv` using `instruction_retired` to observe execution.

### 4. Convert and compare traces

```bash
python tools/verification/convert_vivado_trace.py trace_vivado.csv trace_vivado_converted.csv
python tools/verification/compare_traces.py trace_python.csv trace_vivado_converted.csv --fields word RX RY RZ RA RB RC Z NZ N P
```

The Vivado trace converter also aligns the instruction words with the register/flag snapshots according to the testbench's sampling convention. The instruction-word comparison tests the observed execution sequence without trying to equate the internal prefetched FSM `PC` with Python's architectural `next_pc`.

### 5. Run Python smoke tests

```bash
python tools/simulator/smoke_test.py
```

Smoke tests check selected simulator behaviors independently of Vivado; they do not replace RTL-vs-software comparison.

## Verification flow

```text
program.asm
    |
    v
assembler.py ----> program.coe -------+------> simulator.py --> trace_python.csv
                                      |
                                      +------> Vivado / VHDL testbench
                                                       |
                                                       v
                                               trace_vivado.csv
                                                       |
                                                       v
                                           convert_vivado_trace.py
                                                       |
                                                       v
                                           trace_vivado_converted.csv
                                                       |
                         +-----------------------------+
                         v
                  compare_traces.py <---- trace_python.csv
                         |
                    PASS / MISMATCH
```

For more detail see [Toolchain](docs/TOOLCHAIN.md) and [Verification](docs/VERIFICATION.md).

## Current limitations and next steps

- Compare memory write transactions (address and data) in addition to instruction words, registers and flags.
- Expand the test suite with additional programs and edge cases.
- Automate the full assemble/simulate/compare workflow.
- Explore video output and software that makes use of the custom ISA.

The simulator uses `0000` as an end-of-test sentinel; this is **not** a documented hardware `HALT` instruction. Successful behavioral simulation does not by itself establish FPGA timing closure or operation on a physical board.

## Author

**Raffaele Petrolo** — Electronic Engineering, University of Calabria.

> I remember when I was a child, computers seemed like black magic to me. Now I can build my own.

The long-term dream is to run increasingly complex software on MY_CPU — perhaps even a DOOM port. That remains a goal, not a current feature.
