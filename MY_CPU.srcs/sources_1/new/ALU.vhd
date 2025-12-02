library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity ALU is
port ( A,B : in std_logic_vector (15 downto 0); 
 FAST_CMP_C : in std_logic_vector (15 downto 0); 
 FAST_CMP_D : in std_logic_vector (15 downto 0); 
Cin : in std_logic; 
compare : in std_logic; 
Sum : out std_logic_vector (16 downto 0);
FAST_RES: out std_logic_vector (15 downto 0);
COMPARE_RES: out std_logic_vector(1 downto 0)
);  
end ALU;

architecture Behavioral of ALU is

signal COMPARE_FIT: std_logic_vector(16 downto 0);
signal NEG_D: std_logic_vector(15 downto 0);
signal cin_int: std_logic;

component ADDER16 is 
port ( A,B : in std_logic_vector (15 downto 0);  
Cin : in std_logic; 
Sum : out std_logic_vector (16 downto 0)); 
end component;

begin
process(compare, FAST_CMP_D) 
begin
if (compare = '1') then
 NEG_D <= "1111111111111111" xor FAST_CMP_D;
 cin_int <= '1';
 elsif(compare = '0') then
 NEG_D <= FAST_CMP_D;
 cin_int <= '0';
 else 
  NEG_D <= FAST_CMP_D;
 cin_int <= '0';
 end if;
 end process;

ADDER_port_map: ADDER16 port map(A,B,Cin,sum);
CMP: ADDER16 port map(FAST_CMP_C,NEG_D,cin_int,COMPARE_FIT);

FAST_RES <= COMPARE_FIT(15 downto 0);

process(COMPARE_FIT(15 downto 0))
begin
if (COMPARE_FIT(15) = '1') then
COMPARE_RES <= "11";
elsif(COMPARE_FIT(15 downto 0) = "0000000000000000" ) then
COMPARE_RES <= "00";
else
COMPARE_RES <= "01"; 
end if;
end process;

end Behavioral;
