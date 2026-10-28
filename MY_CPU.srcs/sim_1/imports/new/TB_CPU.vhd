library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;
use STD.ENV.ALL;

entity TOP_CPU_tb is
end TOP_CPU_tb;

architecture tb of TOP_CPU_tb is
    constant CLK_PERIOD : time := 10 ns;
    constant SIM_TIME   : time := 200 us;

    signal clock_tb : std_logic := '0';
    signal reset_tb : std_logic := '1';
    signal retired_tb : std_logic;
    signal word_tb : std_logic_vector(15 downto 0);
    signal flags_tb : std_logic_vector(3 downto 0);
    signal rx_tb, ry_tb, rz_tb, ra_tb, rb_tb, rc_tb : std_logic_vector(15 downto 0);

begin
    clock_tb <= not clock_tb after CLK_PERIOD / 2;

    reset_proc : process
    begin
        reset_tb <= '1';
        wait for 300 ns;
        reset_tb <= '0';
        wait;
    end process;

    DUT : entity work.TOP_CPU
        port map (
            clock => clock_tb, reset => reset_tb,
            instruction_retired_top => retired_tb,
            INSTRUCTION_WORD_debug => word_tb,
            FLAGS_debug_top => flags_tb,
            RX_top => rx_tb, RY_top => ry_tb, RZ_top => rz_tb,
            RA_top => ra_tb, RB_top => rb_tb, RC_top => rc_tb
        );

    trace_proc : process
        file f : text open write_mode is "C:\Users\raffy\Documents\Python_scripts\CPU_utils\MY_CPU_simulator_v02\trace_vivado.csv";
        variable l : line;
        variable step_count : natural := 0;
    begin
        write(l, string'("step,word,rx,ry,rz,ra,rb,rc,flags"));
        writeline(f, l);
        loop
            wait until falling_edge(clock_tb);
            if reset_tb = '0' and retired_tb = '1' then
                step_count := step_count + 1;
                write(l, step_count);
                write(l, string'(",")); hwrite(l, word_tb);
                write(l, string'(",")); hwrite(l, rx_tb);
                write(l, string'(",")); hwrite(l, ry_tb);
                write(l, string'(",")); hwrite(l, rz_tb);
                write(l, string'(",")); hwrite(l, ra_tb);
                write(l, string'(",")); hwrite(l, rb_tb);
                write(l, string'(",")); hwrite(l, rc_tb);
                write(l, string'(",")); hwrite(l, flags_tb);
                writeline(f, l);
            end if;
        end loop;
    end process;

    stim_proc : process
    begin
        wait for SIM_TIME;
        report "SIMULAZIONE COMPLETATA" severity note;
        finish;
    end process;
end tb;
