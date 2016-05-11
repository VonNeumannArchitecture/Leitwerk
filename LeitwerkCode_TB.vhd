----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Kevin Höfle, Kevin Grygosch
-- 
-- Create Date: 11.05.2016 19:35:34
-- Design Name: 
-- Module Name: LeitwerkCode_TB - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity LeitwerkCode_TB is
--  Port ( );
end LeitwerkCode_TB;

architecture Behavioral of LeitwerkCode_TB is
    component LeitwerkCode
        Port ( CLK : in STD_LOGIC;
               Datenbus : in STD_LOGIC_VECTOR (7 downto 0);
               CS : out STD_LOGIC;
               RW : out STD_LOGIC;
               Adressbus : out STD_LOGIC_VECTOR (15 downto 0);
               StatusRegister : in STD_LOGIC_VECTOR (3 downto 0);
               Steuersignale : out STD_LOGIC_VECTOR (3 downto 0);
               RESET : in STD_LOGIC;
               Init: in STD_LOGIC_VECTOR(15 downto 0));
    end component;
    
    --Testbench Signale:
    signal opcode : STD_LOGIC_VECTOR (7 downto 0);
    signal CS : STD_LOGIC;
    signal RW : STD_LOGIC;
    signal Adressbus : STD_LOGIC_VECTOR (15 downto 0);
    signal StatusRegister : STD_LOGIC_VECTOR (3 downto 0);
    signal Steuersignale : STD_LOGIC_VECTOR (3 downto 0);
    signal RESET : STD_LOGIC;
    signal Init : STD_LOGIC_VECTOR(15 downto 0);
    
    --Clock init:
    signal CLK: std_logic := '1'; 
    constant CLK_PERIOD: time := 10 ns;

--Component für Test initialisieren, Signale zuweisen:
begin
    UUT: LeitwerkCode port map (
        CLK => CLK, 
        Datenbus => opcode,
        CS => CS,
        RW => RW,
        Adressbus => Adressbus,
        StatusRegister => StatusRegister,
        Steuersignale => Steuersignale,
        RESET => RESET,
        Init => Init);

CLK_GEN: process 
begin 
    CLK <= not CLK; 
    wait for CLK_PERIOD/2; 
end process CLK_GEN;

OPCODE_TEST: process 
begin 
    wait for 100ns;
    opcode <= "00001001"; --SHIFT_R
--    opcode <= "00001010"; --SHIFT_L
--    opcode <= "00001011"; --ADD_kn
--    opcode <= "00001100"; --SUB_kn
--    opcode <= "00001101"; --ADD_an
--    opcode <= "00001110"; --ADD_an
    
--    wait for 500ns;
--    opcode <= "00010001"; --JMP_an
--    opcode <= "00100010"; --JMPC_an
--    opcode <= "00100011"; --JMPN_an
--    opcode <= "00100100"; --JMPO_an
--    opcode <= "00100101"; --JMPZ_an
    
--    wait for 500ns;
--    opcode <= "01000111"; --NOT_B
--    opcode <= "01000101"; --AND_B
--    opcode <= "01000110"; --OR_B
    
--    wait for 500ns;
--    opcode <= "10000000"; --NOPE
--    opcode <= "10000001"; --LDA_kn
--    opcode <= "10000010"; --LDA_an
--    opcode <= "10000011"; --STA_an
    
    end process;
end Behavioral;
