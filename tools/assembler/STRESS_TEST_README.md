# MY_CPU functional stress test

This is a 63-word program that exercises 3 nested hardware loops, ALU operations, RAM access, and both taken and not-taken absolute conditional jumps.

## Files
- `stress_test.asm`: human-readable source.
- `stress_test.coe`: assembled program (import as Block Memory Generator initialization).
- `stress_trace_python.csv`: reference trace, one row per retired instruction (102 rows).
- `stress_final_state.json`: reference result including register values and written RAM cells.

## Rebuild on your own computer
From the repository root:

```powershell
python tools/assembler/assembler.py programs/stress_test.asm -o programs/stress_test.coe --symbols
python tools/simulator/simulator.py programs/stress_test.coe --max-steps 200 --trace programs/stress_trace_python.csv --state programs/stress_final_state.json
```

## Vivado 2018.3
1. Back up your existing Block Memory Generator .coe/configuration.
2. Change the RAM initialization to `programs/stress_test.coe`, regenerate IP output products when necessary, and rerun Behavioral Simulation. It is not enough to merely change the file on disk if the IP already has generated initialization data.
3. Increase testbench `SIM_TIME` if needed (e.g. 100 us) to accommodate 102 retired instructions. Retire logging must continue one row per completed instruction, including LABEL and COMPARE.
4. Copy `trace_vivado.csv` out of the XSim run directory.
5. Convert the trace and compare with the Python reference using the verified commands for your existing scripts:

```powershell
python tools/verification/convert_vivado_trace.py trace_vivado.csv trace_vivado_converted.csv
python tools/verification/compare_traces.py programs/stress_trace_python.csv trace_vivado_converted.csv --fields word RX RY RZ RA RB RC Z NZ N P
```

**Reference:** Python executes 102 instructions and stops before the zero-filled memory word at `0x003F`. Final register state: RX=000C, RY=00F0, RZ=0000, RA=000C, RB=00F0, RC=000C. Memory writes: [0650]=000C, [0651]=00F0. Loop stack ends empty.

**Important:** The provided result was verified in the Python simulator, **not in Vivado**. The trace comparison is the next test, not a pre-existing PASS. The simulator treats `0000` at end of loaded program as a stop sentinel; the current VHDL FSM has no identical HALT instruction, so XSim can keep executing after the program. Compare the first 102 retired instructions and do not assume later rows are meaningful. 
