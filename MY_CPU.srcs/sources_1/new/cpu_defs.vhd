library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package cpu_defs is

    -- Larghezza dell'istruzione
    constant INSTR_WIDTH : integer := 16;

    ---------------------------------------------------------------------
    -- OPCODES (bits 0 .. 3)
    ---------------------------------------------------------------------
    constant OP_FETCH : std_logic_vector(3 downto 0) := "0000"; 
    constant OP_STORE : std_logic_vector(3 downto 0) := "0001";
    constant OP_LOAD  : std_logic_vector(3 downto 0) := "0010";
    constant OP_LOADM : std_logic_vector(3 downto 0) := "0011";
    constant OP_ADD   : std_logic_vector(3 downto 0) := "0100";
    constant OP_SUB   : std_logic_vector(3 downto 0) := "0101";
    constant OP_JUMPZ  : std_logic_vector(3 downto 0) := "0110";
    constant OP_JUMPNZ  : std_logic_vector(3 downto 0) := "0111";
    constant OP_COMPARE : std_logic_vector(3 downto 0) := "1000"; 
    constant OP_LABEL : std_logic_vector(3 downto 0) := "1001"; 
    constant OP_ADDR : std_logic_vector(3 downto 0) := "1010"; --000a
    constant OP_SUBR : std_logic_vector(3 downto 0) := "1011";  --000b
    constant OP_MOVE: std_logic_vector(3 downto 0) := "1100";  --000c

    ---------------------------------------------------------------------
    -- REGISTRI (bits 4 ... 7) e (8 ... 11)
    ---------------------------------------------------------------------
    constant RX: std_logic_vector(3 downto 0) := "0000"; 
    constant RY : std_logic_vector(3 downto 0) := "0001";
    constant RZ : std_logic_vector(3 downto 0) := "0010";
    constant RA : std_logic_vector(3 downto 0) := "0011";
    constant RB : std_logic_vector(3 downto 0) := "0100";
    constant RC : std_logic_vector(3 downto 0) := "0101";
        ---------------------------------------------------------------------
    -- FLAGS
    ---------------------------------------------------------------------
    constant FLAG_RX : std_logic_vector(7 downto 0) := "00000001";
    constant FLAG_RY : std_logic_vector(7 downto 0) := "00000010";
    constant FLAG_RZ : std_logic_vector(7 downto 0) := "00000100";
    constant FLAG_RA : std_logic_vector(7 downto 0) := "00001000";
    constant FLAG_RB : std_logic_vector(7 downto 0) := "00010000";
    constant FLAG_RC : std_logic_vector(7 downto 0) := "00100000";


end package cpu_defs;
