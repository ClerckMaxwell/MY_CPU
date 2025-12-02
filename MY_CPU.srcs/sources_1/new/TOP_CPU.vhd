library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity TOP_CPU is
port(clock ,reset : in std_logic);
end TOP_CPU;

architecture Behavioral of TOP_CPU is

signal DATA_FROM_FSM, DATA_FROM_RAM, ADDRESS_TOP : std_logic_vector (15 downto 0); 
signal DATA_A, DATA_B, DATA, ALU_REG: std_logic_vector (15 downto 0);
signal C, D, FAST_RES: std_logic_vector (15 downto 0);
signal DATA_ALU: std_logic_vector(16 downto 0);
signal read_top, cin, start, done: std_logic;
signal write_top : std_logic_vector(0 downto 0);
signal CMP : std_logic_vector(1 downto 0);
signal compare_alu: std_logic;



component FSM is
    port (
        clock, reset : in std_logic;
        DATA_IN      : in std_logic_vector (15 downto 0);
        ALU_REG      : in std_logic_vector (15 downto 0);
        ALU_REG2      : in std_logic_vector (15 downto 0);
        CMP_RES      : in std_logic_vector (1 downto 0);
        ADDRESS      : out std_logic_vector (15 downto 0);
        DATA_OUT     : out std_logic_vector (15 downto 0);
        FAST_COMP_C  : out std_logic_vector (15 downto 0);
        FAST_COMP_D  : out std_logic_vector (15 downto 0);
        read         : out std_logic;
        write        : out std_logic_vector(0 downto 0);
        cin_alu      : out std_logic;
        compare_alu      : out std_logic
    ); 
end component;

--component memory is 
--port(
--        clk      : in  std_logic;
--        read     : in  std_logic;
--        write    : in  std_logic;
--        address  : in  std_logic_vector(15 downto 0);
--        data_in  : in  std_logic_vector(15 downto 0);
--        data_out : out std_logic_vector(15 downto 0)
--    );
--end component;

component blk_mem_gen_0 IS
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END component;

component ALU is 
port ( A,B : in std_logic_vector (15 downto 0); 
 FAST_CMP_C : in std_logic_vector (15 downto 0); 
 FAST_CMP_D : in std_logic_vector (15 downto 0); 
Cin : in std_logic; 
compare : in std_logic; 
Sum : out std_logic_vector (16 downto 0);
FAST_RES: out std_logic_vector (15 downto 0);
COMPARE_RES: out std_logic_vector(1 downto 0)
);   
end component;

begin

process(clock)
begin
if(rising_edge(clock)) then 
DATA_A <= DATA_FROM_FSM;
DATA_B <= DATA_A;
end if;
end process;



FSM_port: FSM port map(clock, reset, DATA_FROM_RAM, DATA_ALU(15 downto 0),FAST_RES,CMP, ADDRESS_TOP, DATA_FROM_FSM, C, D, read_top, write_top,cin, compare_alu);
MEMORY_PORT: blk_mem_gen_0 port map(clock, read_top, write_top, ADDRESS_TOP, DATA_FROM_FSM, DATA_FROM_RAM);
ALU_PORT: ALU port map(DATA_A, DATA_B, C, D, cin, compare_alu,DATA_ALU, FAST_RES,CMP);
end Behavioral;
