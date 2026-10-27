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

## Background

These flags are implemented as registers within the FSM and are **cleared only at the beginning of the `execute` state**. This mechanism ensures that the `write_reg` state (which occurs several cycles later) "remembers" whether it should write a result coming from the **ALU** (`ALU_REG`) or a value read from Memory (`DATA_IN`).

---

## 📂 4. File Structure

The main files of the project are:

* `FSM.vhd`: Contains the Finite State Machine (FSM) that controls the flow, cache registers, and the PC.
* `cpu_defs.vhd`: Package containing all Opcode constants and Register definitions (e.g., `RX`, `FLAG_RX`).
* `ALU.vhd`
* `blk_mem_gen_0.vhd`: The RAM module to hold the instructions.
* `TOP_CPU.vhd`: Integrates the FSM, ALU, and Memory.
* `.gitignore`: **Crucial** for ignoring all log, synthesis, and simulation files generated by Vivado.

---

## 🛠️ 5. Usage and Testing

1.  Clone the repository:
    ```bash
    git clone [URL]
    ```
2.  Open the project in **Vivado**.
3.  Simulate the `TOP_CPU_tb.vhd` file to observe the correct state transitions.
4.  Synthesize for the target FPGA platform (specify the board).

---

## 🧐 6. Example Opcodes

| Raw Opcode (Hex) | Opcode | Operand / Data (Hex) | Detailed Description |
| :---: | :--- | :--- | :--- |
| **0012** | `OP_LOAD` | `Ry` | Loads an immediate value into register `Ry` (Memory Data Register). |
| **00AF** | (Data) | `0x00AF` | Immediate value: **175** (decimal). Result: `Ry` = 175. |
| **0011** | `OP_STORE` | `Ry` | Stores the content of `Ry` into Memory. |
| **0650** | (Address) | `0x0650` | Memory address. Result: `MEM[0x0650]` = 175. |
| **0023** | `OP_LOADM` | `Rz` | Loads a value fetched from memory into register `Rz`. |
| **0650** | (Address) | `0x0650` | Reads from address 0x0650. Result: `Rz` = 175. |
| **021A** | `OP_ADDR` | `Rz, Ry` | Register Addition: `Rz` = `Rz + Ry`. (175 + 175 = **350**). |
| **021B** | `OP_SUBR` | `Rz, Ry` | Register Subtraction: `Rz` = `Rz - Ry`. (350 - 175 = **175**). |
| **0014** | `OP_ADD` | `Ry` | Immediate addition to register `Ry`. |
| **0016** | (Data) | `0x0016` | Value: 22. Result: `Ry` = `Ry + 22` (**197**). |
| **0015** | `OP_SUB` | `Ry` | Immediate subtraction from register `Ry`. |
| **0016** | (Data) | `0x0016` | Value: 22. Result: `Ry` = `Ry - 22` (**175**). |
| **0218** | `OP_COMPARE` | `Ry, Rz` | Compares `Ry` (175) with `Rz` (175). Result: Sets the **Z FLAG** (Zero) to 1. |
| **0024** | `OP_ADD` | `Rz` | Immediate addition to register `Rz`. |
| **0001** | (Data) | `0x0001` | Increments `Rz` by 1. Result: `Rz` = 176. |
| **0218** | `OP_COMPARE` | `Ry, Rz` | Compares `Ry` (175) with `Rz` (176). Result: Sets **NZ FLAG** (Non Zero). |
| **0002** | `OP_LOAD` | `Rx` | Loads an immediate value into register `Rx` (Counter Register). |
| **00B0** | (Data) | `0x00B0` | Value: 176. Result: `Rx` = 176. |
| **0009** | `OP_LABEL` | `-` | **Jump Label** (Start Loop). Saves the current PC. |
| **052C** | `OP_MOVE` | `Rc, Rz` | Moves the value from `Rz` to `Rc` (`Rc` = `Rz`). |
| **0024** | `OP_ADD` | `Rz` | Immediate addition to register `Rz`. |
| **00B0** | (Data) | `0x00B0` | Adds 176 to `Rz`. `Rz` = `Rz + 176`. |
| **0005** | `OP_SUB` | `Rx` | Immediate subtraction from register `Rx`. |
| **0001** | (Data) | `0x0001` | Decrements the loop counter. Result: `Rx` = `Rx - 1`. |
| **0308** | `OP_COMPARE` | `Rx, Ra` | Compares `Rx` with `Ra` (Ra = 0 by default). Checks the loop exit condition. |
| **0007** | `OP_JUMPNZ` | `-` | **Conditional Jump:** Jumps to the label address (`0009`) if the last comparison result was not Zero (i.e., if `Rx` > 0). |

---

## 👤 Author

**Raffaele Petrolo**
This project started as an attempt to understand what happens inside a processor, from the adder logic to instruction execution. The longer-term experiments include graphical output and increasingly complex software. Running a port of DOOM is an aspiration, not a current capability.
