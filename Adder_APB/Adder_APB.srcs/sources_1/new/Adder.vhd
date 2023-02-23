----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/22/2023 07:40:49 PM
-- Design Name: 
-- Module Name: Adder - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- AUTHOR: Hasan Al-Shaikh

-- This ADDER module is a simple APB master entity. For simplicity's sake some signals (e.g. STB, SLV_ERR) from the protocol has been eliminated
-- We further assume that the input add_i is going to be asserted only for a cycle before being deasserted.
entity apb_master_adder is
    Port ( pclk : in STD_LOGIC;
           preset_n : in STD_LOGIC;
           add_i : in STD_LOGIC_VECTOR (1 downto 0); -- 00: NOP, 01- READ, 10- NOP, 11- WRITE
           
           psel_o : out STD_LOGIC;
           penable_o : out STD_LOGIC;
           paddr_o : out STD_LOGIC_VECTOR (31 downto 0);
           pwrite_o : out STD_LOGIC;
           pwdata_o : out STD_LOGIC_VECTOR (31 downto 0);
           
           prdata_i : in STD_LOGIC_VECTOR (31 downto 0);
           pready_i : in STD_LOGIC);
end apb_master_adder;

architecture Behavioral of apb_master_adder is

type state_t is (IDLE, SETUP, ACESS);
signal state_r: state_t;
signal apb_acess_state:  STD_LOGIC :='0';
signal pwrite_o_t: STD_LOGIC;
signal pread_data: std_logic_vector(prdata_i'range);
signal pwdata_o_t: std_logic_vector (pwdata_o'range);
--signal add_i_high: std_logic ;
begin
    --add_i_high<=add_i(1);
    pwrite_o<=pwrite_o_t;
    process (pclk, preset_n)
    begin
        if (preset_n='0') then 
            state_r<=IDLE;
            psel_o<='0';
            penable_o<='0';
            pwrite_o_t<='0';
            pread_data <=(others=>'0');
            paddr_o<=(others=>'0');
            pwdata_o<=(others=>'0');
            --add_i_high<='0';
        elsif(rising_edge (pclk)) then
            case state_r is 
            when IDLE=>
                psel_o<='0';
                penable_o<='0';
 --               if (pwrite_o_t='0' and pready_i='1') then -- IF WE DO HERE THIS, this is not an accurate capture of the intent of the protocol. 
                                                            -- pready will come only while the master is in ACESS STATE
 --                     pread_data<=prdata_i; 
 --               end if;
                if (add_i(0)='1') then
                    state_r<=SETUP; 
                    pwrite_o_t<=add_i(1);-- We have to keep pwrite_o asserted after which operation to perform which is why 
                                    -- we flopped pwrite_o. Additionally, this has to be asserted as soon as p_enable_o is asserted                  
                else
                    state_r<=IDLE;                    
                end if;
            when SETUP=>
                
                psel_o<='1';
                penable_o<='0';     
                state_r<=ACESS;
            when ACESS=>
                --psel_o<='1'; 
                if (pwrite_o_t='1') then
                    pwdata_o<=pwdata_o_t;
                end if;
                paddr_o<=(31=> '1', 30=>'0', 29=>'1', 28=>'0', others=>'0'); -- APB ADDRESS: We assume only one adddress (32'hA000) to be written to / read from
                
                penable_o<='1'; -- penable should become high one cycle afer psel_o as psel_o is asserted in SETUP state. 
                                -- We enter ACESS state automatically one cycle later.
                if (pready_i='1') then
                    state_r<=IDLE;   -- We are not supporting back to back transactions. 
                                     -- We assume that for one assertion of PSEL_O, only one PEN_O assertion will happen 
                    if (pwrite_o_t='0') then -- EKHON KAR JE VALUE ACHE, SEITA NIYE NEXT STATE E DHUKTE HOILE OI STATE
                        pread_data<=prdata_i;
                    end if;                                                 
                else
                    state_r<=ACESS;
                    apb_acess_state<='1';
                  end if;   
            when others=> null;
            end case;
        end if;
    end process;
    
--    IF WE DO HERE THE FOLLOWING, IT's A GROSS VIOLATION OF DR. STITT's 1 PROCESS FSM CODING GUIDELINES. DONT DO IT.
--    ASSIGN ALL OUTPUTS/SIGNALS CORRESPONDING TO THE STATES IN THE SAME PROCESS BLOCK.
--    process (state_r) begin
--        if (state_r=ACESS) then
--            apb_acess_state<='1';
--        else
--            apb_acess_state<='0';
--        end if;
--    end process;

-- 
--    with apb_acess_state select
--    paddr_o<=(31=> '1', 30=>'0', 29=>'1', 28=>'0', others=>'0') when '1', 
--            (others=>'0') when others;



                
    -- PWDATA_O
    -- Read a value from the slave at address 0xA000 => This is already done in the 
    -- Increment that value
    -- Sned that value back during the write operation to address 0xA000
    process (pread_data) begin
        pwdata_o_t<= std_logic_vector(unsigned(pread_data)+1);
    end process;
end Behavioral;
