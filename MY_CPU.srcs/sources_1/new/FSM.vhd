--This project was done by Raffaele Petrolo (class 2002), Electronic Engineering student at University of Calabria.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.cpu_defs.all;

entity FSM is
    port (
        clock, reset : in std_logic;
        DATA_IN      : in std_logic_vector (15 downto 0);
        ALU_REG      : in std_logic_vector (15 downto 0);
        ALU_REG2     : in std_logic_vector (15 downto 0);
        CMP_RES      : in std_logic_vector (1 downto 0);
        ADDRESS      : out std_logic_vector (15 downto 0);
        DATA_OUT     : out std_logic_vector (15 downto 0);
        FAST_COMP_C  : out std_logic_vector (15 downto 0);
        FAST_COMP_D  : out std_logic_vector (15 downto 0);
        read         : out std_logic;
        write        : out std_logic_vector(0 downto 0);
        cin_alu      : out std_logic;
        compare_alu  : out std_logic
    ); 
end FSM;

architecture Behavioral of FSM is

    type state_type is (init, execute, wait_address, wait_data, write_reg, 
                        write_mem, wait_mem, wait_generic, compare);
    signal state : state_type;

    signal DATA_OP, DATA_REG, DATA_REG2 : std_logic_vector(3 downto 0);
    signal PC, PC_REG, PC_REG2, PC_REG3 : std_logic_vector(15 downto 0);

    -- flags e segnali interni
    signal flags : std_logic_vector(7 downto 0);
    signal flag_pickup, flag_alu, flag_sub, flag_reg : std_logic;
    signal FLAGZ, FLAGNZ, FLAGN, FLAGP : std_logic;
    signal JUMPATO : std_logic;

    -- REGISTER CACHE
    signal DATA_RX, DATA_RY, DATA_RZ : std_logic_vector(15 downto 0);
    signal DATA_RA, DATA_RB, DATA_RC : std_logic_vector(15 downto 0);

begin

    DATA_OP   <= DATA_IN(3 downto 0);
    DATA_REG  <= DATA_IN(7 downto 4);
    DATA_REG2 <= DATA_IN(11 downto 8);

    process (clock, reset)
    begin
        if (reset = '1') then
            state       <= init;
            ADDRESS     <= (others => '0'); 
            DATA_RX  <= (others => '0');
            DATA_RY  <= (others => '0');
            DATA_RZ  <= (others => '0');
            DATA_RA  <= (others => '0');
            DATA_RB  <= (others => '0');
            DATA_RC  <= (others => '0');
            DATA_OUT    <= (others => '0');
            FAST_COMP_C <= (others => '0');
            FAST_COMP_D <= (others => '0');
            PC_REG      <= (others => '0');
            PC_REG2     <= (others => '0');
            PC_REG3     <= (others => '0');
            PC          <= (others => '0');      
            flags       <= (others => '0');
            compare_alu <= '0';
            flag_reg    <= '0';
            FLAGZ       <= '0'; 
            FLAGNZ      <= '0';
            FLAGN       <= '0';
            FLAGP       <= '0';
            read        <= '0';
            JUMPATO     <= '0';
            write       <= "0";
            flag_pickup <= '0';  
            flag_alu    <= '0';
            cin_alu     <= '0';           
        elsif rising_edge(clock) then

            case state is

                ------------------------------------------------
                -- INIT
                ------------------------------------------------
                when init =>
                    read <= '1';
                    if (DATA_IN /= "0000000000000000") then
                        ADDRESS <= "0000000000000001";
                        PC      <= "0000000000000010";
                        state   <= execute;
                    else
                        state <= init;
                    end if;

                ------------------------------------------------
                -- FETCH & EXECUTE
                ------------------------------------------------
                when execute =>
                    -- Reset segnali di controllo per la nuova istruzione
                    flag_pickup <= '0';
                    flag_alu    <= '0';
                    flag_sub    <= '0';
                    flag_reg    <= '0';
                    JUMPATO     <= '0';
                    write       <= "0";
                    cin_alu     <= '0';
                    compare_alu <= '0';
                    
                    FLAGZ <= '0'; 
                    FLAGNZ <= '0'; 
                    FLAGN <= '0'; 
                    FLAGP <= '0';

                    case DATA_OP is

                        -- STORE
                        when OP_STORE =>
                            ADDRESS <= PC;
                            state   <= wait_address;
                            case DATA_REG is
                                when RX => flags <= FLAG_RX;
                                when RY => flags <= FLAG_RY;
                                when RZ => flags <= FLAG_RZ;
                                when RA => flags <= FLAG_RA;
                                when RB => flags <= FLAG_RB;
                                when RC => flags <= FLAG_RC;
                                when others => state <= execute;
                            end case;

                        -- LOAD DIRECTLY
                        when OP_LOAD =>
                            ADDRESS <= PC;
                            PC      <= PC + 1;
                            state   <= write_reg;
                            case DATA_REG is
                                when RX => flags <= FLAG_RX;
                                when RY => flags <= FLAG_RY;
                                when RZ => flags <= FLAG_RZ;
                                when RA => flags <= FLAG_RA;
                                when RB => flags <= FLAG_RB;
                                when RC => flags <= FLAG_RC;
                                when others => state <= execute;
                            end case;

                        -- LOAD FROM MEMORY
                        when OP_LOADM =>
                            ADDRESS     <= PC;
                            flag_pickup <= '1';
                            PC          <= PC + 1;
                            state       <= wait_address;
                            case DATA_REG is
                                when RX => flags <= FLAG_RX;
                                when RY => flags <= FLAG_RY;
                                when RZ => flags <= FLAG_RZ;
                                when RA => flags <= FLAG_RA;
                                when RB => flags <= FLAG_RB;
                                when RC => flags <= FLAG_RC;
                                when others => state <= execute;
                            end case;

                        -- ADD / SUB (Custom Value)
                        when OP_ADD | OP_SUB =>
                            flag_alu <= '1';
                            ADDRESS  <= PC;
                            state    <= wait_data;
                            if DATA_OP = OP_SUB then
                                flag_sub <= '1';
                                cin_alu  <= '1';
                            end if;
                            
                            case DATA_REG is
                                when RX => flags <= FLAG_RX; DATA_OUT <= DATA_RX;
                                when RY => flags <= FLAG_RY; DATA_OUT <= DATA_RY;
                                when RZ => flags <= FLAG_RZ; DATA_OUT <= DATA_RZ;
                                when RA => flags <= FLAG_RA; DATA_OUT <= DATA_RA;
                                when RB => flags <= FLAG_RB; DATA_OUT <= DATA_RB;
                                when RC => flags <= FLAG_RC; DATA_OUT <= DATA_RC;
                                when others => state <= execute;
                            end case;

                        -- ADD / SUB (Register)
                        when OP_ADDR | OP_SUBR =>
                            flag_alu <= '1';
                            flag_reg <= '1';
                            state    <= write_reg;
                            
                            if DATA_OP = OP_SUBR then
                                flag_sub    <= '1';
                                compare_alu <= '1'; 
                            end if;

                            -- Selezione Primo Registro (Source 2) -> imposta flags di destinazione
                            case DATA_REG2 is
                                when RX => flags <= FLAG_RX; FAST_COMP_C <= DATA_RX;
                                when RY => flags <= FLAG_RY; FAST_COMP_C <= DATA_RY;
                                when RZ => flags <= FLAG_RZ; FAST_COMP_C <= DATA_RZ;
                                when RA => flags <= FLAG_RA; FAST_COMP_C <= DATA_RA;
                                when RB => flags <= FLAG_RB; FAST_COMP_C <= DATA_RB;
                                when RC => flags <= FLAG_RC; FAST_COMP_C <= DATA_RC;
                                when others => state <= execute;
                            end case;
                            
                            -- Selezione Secondo Registro (Source 1)
                            case DATA_REG is
                                when RX => FAST_COMP_D <= DATA_RX;
                                when RY => FAST_COMP_D <= DATA_RY;
                                when RZ => FAST_COMP_D <= DATA_RZ;
                                when RA => FAST_COMP_D <= DATA_RA;
                                when RB => FAST_COMP_D <= DATA_RB;
                                when RC => FAST_COMP_D <= DATA_RC;
                                when others => state <= execute;
                            end case;

                        -- COMPARE
                        when OP_COMPARE =>
                            compare_alu <= '1';
                            state       <= compare;
                            
                            case DATA_REG2 is
                                when RX => FAST_COMP_C <= DATA_RX;
                                when RY => FAST_COMP_C <= DATA_RY;
                                when RZ => FAST_COMP_C <= DATA_RZ;
                                when RA => FAST_COMP_C <= DATA_RA;
                                when RB => FAST_COMP_C <= DATA_RB;
                                when RC => FAST_COMP_C <= DATA_RC;
                                when others => state <= execute;
                            end case;

                            case DATA_REG is
                                when RX => FAST_COMP_D <= DATA_RX;
                                when RY => FAST_COMP_D <= DATA_RY;
                                when RZ => FAST_COMP_D <= DATA_RZ;
                                when RA => FAST_COMP_D <= DATA_RA;
                                when RB => FAST_COMP_D <= DATA_RB;
                                when RC => FAST_COMP_D <= DATA_RC;
                                when others => state <= execute;
                            end case;

                        -- LABEL
                        when OP_LABEL =>              
                            PC_REG  <= PC - 1;
                            PC_REG2 <= PC_REG;
                            PC_REG3 <= PC_REG2;
                            PC      <= PC + 1;
                            ADDRESS <= PC; 
                            state   <= execute;    
                        
                        -- JUMPZ
                        when OP_JUMPZ =>
                            ADDRESS <= PC;
                            if (FLAGZ = '1') then
                                ADDRESS <= PC_REG; 
                                PC      <= PC_REG + 1;
                                JUMPATO <= '1';
                                state <= wait_generic;                          
                            else 
                                PC_REG  <= PC_REG2;
                                PC_REG2 <= PC_REG3;
                                PC_REG3 <= (others => '0');                        
                                PC      <= PC + 1;
                                state <= execute;
                            end if;
                            

                        -- JUMPNZ
                        when OP_JUMPNZ =>
                            ADDRESS <= PC;
                            if (FLAGNZ = '1') then
                                ADDRESS <= PC_REG; 
                                PC      <= PC_REG + 1;
                                JUMPATO <= '1';
                                state <= wait_generic;                          
                            else 
                                PC_REG  <= PC_REG2;
                                PC_REG2 <= PC_REG3;
                                PC_REG3 <= (others => '0');                        
                                PC      <= PC + 1;
                                state <= execute;
                            end if;
                                                   

when OP_MOVE =>
    ADDRESS <= PC;
    PC      <= PC + 1;
    state   <= execute; 

    -- Primo livello: Seleziona CHI riceve il dato (Destinazione = DATA_REG2)
    case DATA_REG2 is
    
        -- Destinazione: O
        when RX =>
            case DATA_REG is -- Seleziona la Sorgente
                when RX => DATA_RX <= DATA_RX; -- (nop)
                when RY => DATA_RX <= DATA_RY;
                when RZ => DATA_RX <= DATA_RZ;
                when RA => DATA_RX <= DATA_RA;
                when RB => DATA_RX <= DATA_RB;
                when RC => DATA_RX <= DATA_RC;
                when others => null;
            end case;

        -- Destinazione: M
        when RY =>
            case DATA_REG is
                when RX => DATA_RY <= DATA_RX;
                when RY => DATA_RY <= DATA_RY;
                when RZ => DATA_RY <= DATA_RZ;
                when RA => DATA_RY <= DATA_RA;
                when RB => DATA_RY <= DATA_RB;
                when RC => DATA_RY <= DATA_RC;
                when others => null;
            end case;

        -- Destinazione: E
        when RZ =>
            case DATA_REG is
                when RX => DATA_RZ <= DATA_RX;
                when RY => DATA_RZ <= DATA_RY;
                when RZ => DATA_RZ <= DATA_RZ;
                when RA => DATA_RZ <= DATA_RA;
                when RB => DATA_RZ <= DATA_RB;
                when RC => DATA_RZ <= DATA_RC;
                when others => null;
            end case;

        -- Destinazione: R
        when RA =>
            case DATA_REG is
                when RX => DATA_RA <= DATA_RX;
                when RY => DATA_RA <= DATA_RY;
                when RZ => DATA_RA <= DATA_RZ;
                when RA => DATA_RA <= DATA_RA;
                when RB => DATA_RA <= DATA_RB;
                when RC => DATA_RA <= DATA_RC;
                when others => null;
            end case;

        -- Destinazione: D
        when RB =>
            case DATA_REG is
                when RX => DATA_RB <= DATA_RX;
                when RY => DATA_RB <= DATA_RY;
                when RZ => DATA_RB <= DATA_RZ;
                when RA => DATA_RB <= DATA_RA;
                when RB => DATA_RB <= DATA_RB;
                when RC => DATA_RB <= DATA_RC;
                when others => null;
            end case;

        -- Destinazione: A
        when RC =>
            case DATA_REG is
                when RX => DATA_RC <= DATA_RX;
                when RY => DATA_RC <= DATA_RY;
                when RZ => DATA_RC <= DATA_RZ;
                when RA => DATA_RC <= DATA_RA;
                when RB => DATA_RC <= DATA_RB;
                when RC => DATA_RC <= DATA_RC;
                when others => null;
            end case;

        when others => 
            state <= execute;
            
    end case;
                        
                        when others =>
                            state <= execute;
                    end case; 
                    

                        
 
                        

                ------------------------------------------------
                -- WAIT ADDRESS (STORE / LOADM phase 1)
                ------------------------------------------------
                when wait_address =>
                    ADDRESS <= DATA_IN;
                    if (flag_pickup = '1') then
                        state <= wait_mem;
                    else 
                        state <= write_mem; 
                        write <= "1";
                        case flags is
                            when FLAG_RX => DATA_OUT <= DATA_RX;
                            when FLAG_RY => DATA_OUT <= DATA_RY;
                            when FLAG_RZ => DATA_OUT <= DATA_RZ;
                            when FLAG_RA => DATA_OUT <= DATA_RA;
                            when FLAG_RB => DATA_OUT <= DATA_RB;
                            when FLAG_RC => DATA_OUT <= DATA_RC;
                            when others => null;
                        end case;                     
                    end if;

                ------------------------------------------------
                -- WRITE MEMORY
                ------------------------------------------------
                when write_mem =>
                    ADDRESS <= PC;
                    PC      <= PC + 1;
                    write   <= "0";
                    state   <= wait_generic;

                ------------------------------------------------
                -- WAIT DATA (ADD/SUB immediate phase)
                ------------------------------------------------
                when wait_data =>
                    if (flag_alu = '1' and flag_sub = '0') then
                        DATA_OUT <= DATA_IN; 
                        state    <= wait_generic;
                        ADDRESS <= PC;
                    elsif (flag_alu = '1' and flag_sub = '1') then
                        DATA_OUT <= "1111111111111111" xor DATA_IN; -- Complemento a 1
                        state    <= wait_generic;
                        ADDRESS <= PC;
                    else
                        ADDRESS <= PC;
                        PC      <= PC + 1;
                        state   <= write_reg;
                    end if;

                ------------------------------------------------
                -- WRITE REGISTER
                ------------------------------------------------
                when write_reg =>
                    ADDRESS <= PC; 
                    PC      <= PC + 1;
                    state <= execute;
                    -- Gestione scrittura registri (logica unificata)
                    case flags is
                        when FLAG_RX => 
                            if    (flag_alu = '0') then DATA_RX <= DATA_IN;
                            elsif (flag_reg = '0') then DATA_RX <= ALU_REG;
                            else                        DATA_RX <= ALU_REG2; end if;
                        when FLAG_RY => 
                            if    (flag_alu = '0') then DATA_RY <= DATA_IN;
                            elsif (flag_reg = '0') then DATA_RY <= ALU_REG;
                            else                        DATA_RY <= ALU_REG2; end if;
                        when FLAG_RZ => 
                            if    (flag_alu = '0') then DATA_RZ <= DATA_IN;
                            elsif (flag_reg = '0') then DATA_RZ <= ALU_REG;
                            else                        DATA_RZ <= ALU_REG2; end if;
                        when FLAG_RA => 
                            if    (flag_alu = '0') then DATA_RA <= DATA_IN;
                            elsif (flag_reg = '0') then DATA_RA <= ALU_REG;
                            else                        DATA_RA <= ALU_REG2; end if;
                        when FLAG_RB => 
                            if    (flag_alu = '0') then DATA_RB <= DATA_IN;
                            elsif (flag_reg = '0') then DATA_RB <= ALU_REG;
                            else                        DATA_RB <= ALU_REG2; end if;
                        when FLAG_RC => 
                            if    (flag_alu = '0') then DATA_RC <= DATA_IN;
                            elsif (flag_reg = '0') then DATA_RC <= ALU_REG;
                            else                        DATA_RC <= ALU_REG2; end if;
                        when others => null;
                    end case;

                ------------------------------------------------
                -- WAIT MEM (LOADM phase 2)
                ------------------------------------------------
                when wait_mem => 
                    PC      <= PC + 1;
                    ADDRESS <= PC;
                    state   <= write_reg;
                 
                ------------------------------------------------
                -- COMPARE EXECUTION
                ------------------------------------------------
                when compare => 
                    PC      <= PC + 1;
                    ADDRESS <= PC;
                    state   <= execute;
                    case CMP_RES is
                        when "11" => 
                            FLAGN  <= '1';
                            FLAGNZ <= '1';
                        when "00" => 
                            FLAGZ <= '1';
                        when others => 
                            FLAGP  <= '1';
                            FLAGNZ <= '1';  
                    end case;        
                 
                ------------------------------------------------
                -- WAIT GENERIC (Delay Slot / Wait ALU)
                ------------------------------------------------
                when wait_generic =>
                    ADDRESS <= PC;
                    if (flag_alu = '1') then 
                        PC    <= PC + 1;
                        state <= write_reg;
                    elsif (JUMPATO = '1') then
                        PC    <= PC + 1;
                        state <= execute;
                    else 
                        state <= execute;
                    end if;

                when others =>
                    state <= execute;

            end case;
        end if;
    end process;

end Behavioral;