; Le label referenziate da JUMPNZ/JUMPZ emettono LABEL (0009).
; Le label per JUMPIZ/JUMPINZ sono indirizzi, senza word aggiuntiva.
LOAD RY, 0x00AF
STORE RY, 0x0650
LOADM RZ, 0x0650
ADDR RZ, RY
SUBR RZ, RY
ADD RY, 0x0016
SUB RY, 0x0016
COMPARE RZ, RY
ADD RZ, 1
COMPARE RZ, RY
LOAD RX, 0x00B0
loop1:
    MOVE RC, RZ
    ADD RZ, 0x00B0
    SUB RX, 1
    COMPARE RA, RX
    JUMPNZ loop1
