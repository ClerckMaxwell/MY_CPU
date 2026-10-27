from simulator import CPU
# LOAD RY,175; LOAD RZ,175; ADDR RZ,RY; MOVE RC,RZ; STORE RC,0x650
prog = [0x0012, 0x00AF, 0x0022, 0x00AF, 0x021A, 0x052C, 0x0051, 0x0650]
cpu = CPU(prog)
for _ in range(5):
    cpu.step()
assert cpu.registers == [0, 175, 350, 0, 0, 350], cpu.registers
assert cpu.mem[0x650] == 350
# simple loop: load counter; label; sub; compare zero; JUMPNZ
loop = CPU([0x0002, 3, 0x0009, 0x0005, 1, 0x0308, 0x0007])
for _ in range(11):
    loop.step()
assert loop.registers[0] == 0, loop.registers
assert loop.loop_stack == [], loop.loop_stack
print('OK: ALU, MOVE, STORE e loop hardware')
# ALU compares using the MSB of the wrapped subtraction, not Python signed ordering.
cpu = CPU([0x0002, 0x7FFF, 0x0012, 0xFFFF, 0x0108])
for _ in range(3): cpu.step()
assert (cpu.flagz,cpu.flagnz,cpu.flagn,cpu.flagp) == (0,1,1,0)
# Absolute forward branch: RY=0, compare RX=RY, jump to address 9
cpu = CPU([0x0002, 0, 0x0012, 0, 0x0108, 0x009D, 0x0022, 0x1234, 0x0014, 0x0022, 0xBEEF])
for _ in range(5): cpu.step()
assert cpu.registers[2] == 0xBEEF and cpu.pc == 11
print('OK: RTL CMP flags and absolute conditional jump')
