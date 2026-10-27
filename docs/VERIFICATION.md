# Verification protocol

## Retire event

The Vivado testbench must capture a snapshot **once per completed instruction**, including `COMPARE`, `STORE`, `LABEL`, `MOVE` and jumps, even when none of the general registers change. `instruction_retired` should be a one-clock pulse. A sample logger is in `tools/verification/TOP_CPU_tb_example.vhd`; adapt it to your actual debug ports. The working testbench you already verified should be retained unless explicitly updated.

## Vivado trace

Expected raw columns:

```csv
step,word,rx,ry,rz,ra,rb,rc,flags
```

Each register and `word` is hexadecimal (`4` digits). `flags` is a hexadecimal nibble, using `Z` bit 3, `NZ` bit 2, `N` bit 1, `P` bit 0. The converter outputs `step,word,RX,RY,RZ,RA,RB,RC,Z,NZ,N,P`.

## Interpretation of PASS

Matching all rows and fields demonstrates consistent **observable retired states** for the tested program. It does not independently prove BRAM writes, unobserved memory locations, unsupported instructions, timing closure or correct execution of all possible programs.

## PC convention

`simulator.py` stores a *software architectural* `next_pc`. The VHDL FSM's `PC` prepares memory addresses ahead of time and can diverge by varying offsets. Raw `PC` must **not** be renamed to `next_pc` for comparison without defining a true architectural retirement signal. For now, compare `word` and the architectural state.

## Memory verification (planned)

Trace synchronous BRAM write transactions at the clock edge where `wea=1`, saving `(transaction index, address, data)`. Compare the sequence with software model's memory writes. This closes an important verification gap that register/flag tests do not cover.
