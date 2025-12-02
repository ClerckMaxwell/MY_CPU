library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TOP_CPU_tb is
end TOP_CPU_tb;

architecture tb of TOP_CPU_tb is

    -- Segnali per pilotare il DUT
    signal clock_tb : std_logic := '0';
    signal reset_tb : std_logic := '1';

    -- Component del progetto
    component TOP_CPU is
        port(
            clock : in std_logic;
            reset : in std_logic
        );
    end component;

begin
    -------------------------------------------------------------------------
    -- Clock: 10 ns periodo (100 MHz)
    -------------------------------------------------------------------------
    clock_process : process
    begin
        clock_tb <= '0';
        wait for 5 ns;
        clock_tb <= '1';
        wait for 5 ns;
    end process;

    -------------------------------------------------------------------------
    -- Reset pulse
    -------------------------------------------------------------------------
    reset_process : process
    begin
        reset_tb <= '1';
        wait for 300 ns;
        reset_tb <= '0';   -- rilascia reset dopo 20 ns
        wait;
    end process;

    -------------------------------------------------------------------------
    -- Instanzia la CPU
    -------------------------------------------------------------------------
    DUT: TOP_CPU
    port map(
        clock => clock_tb,
        reset => reset_tb
    );

    -------------------------------------------------------------------------
    -- Simulazione
    -------------------------------------------------------------------------
    stim_proc : process
    begin
        -- Simula per 2000 ns
        wait for 2000 ns;
        report "SIMULAZIONE COMPLETATA" severity note;
        wait;
    end process;

end tb;
