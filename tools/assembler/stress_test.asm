; MY_CPU functional stress test - 3 nested hardware loops + absolute jumps.
; Expected RX = 12 at exit (2 outer * 2 middle * 3 inner).
; Expected RAM[0x0650] = 12; RAM[0x0651] = 0x00F0.
; Registers used: RX total, RY temporary, RZ zero, RA outer,
; RB middle, RC inner.

LOAD RX, 0
LOAD RZ, 0
LOAD RA, 2

outer:
    LOAD RB, 2
middle:
    LOAD RC, 3
inner:
    ADD RX, 1
    SUB RC, 1
    COMPARE RC, RZ
    JUMPNZ inner
    SUB RB, 1
    COMPARE RB, RZ
    JUMPNZ middle
    SUB RA, 1
    COMPARE RA, RZ
    JUMPNZ outer

; Exercise store, load-from-memory, ADDR and SUBR.
STORE RX, 0x0650
LOADM RY, 0x0650
ADDR RY, RX       ; RY = RY + RX = 24
SUBR RX, RY       ; RX = RX - RY = 0xFFF4
ADD RX, 12        ; RX = 0 again

; Absolute jumps: taken and not taken.
COMPARE RX, RZ
JUMPIZ equal_zero
LOAD RX, 0xDEAD     ; must be skipped

equal_zero:
    JUMPINZ bad_path ; not taken (Z=1)
    LOAD RX, 12
    COMPARE RX, RZ
    JUMPINZ nonzero  ; taken (NZ=1)
    LOAD RX, 0xBEEF ; must be skipped

nonzero:
    JUMPIZ bad_path ; not taken (NZ=1)
    MOVE RC, RX
    STORE RC, 0x0650
    LOAD RY, 0x00F0
    STORE RY, 0x0651
    LOADM RB, 0x0651
    COMPARE RB, RY
    JUMPIZ success  ; taken

bad_path:
    LOAD RX, 0xBAD0
    STORE RX, 0x0650

success:
    MOVE RA, RC
; End: after this word, RAM is zero-filled (FETCH 0000 sentinel).
