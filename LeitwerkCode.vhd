----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.04.2016 12:16:07
-- Design Name: 
-- Module Name: LeitwerkCode - Behavioral
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

entity LeitwerkCode is
    Port ( CLK : in STD_LOGIC;
           DatabusRE : in STD_LOGIC_VECTOR (7 downto 0);
           DatabusWR : out STD_LOGIC_VECTOR (7 downto 0);
           Adressbus : out STD_LOGIC_VECTOR (15 downto 0);
           StatusRegister : in STD_LOGIC_VECTOR (3 downto 0);
           Steuersignale : out STD_LOGIC_VECTOR (7 downto 0);
           RESET : in STD_LOGIC;
           Init: in STD_LOGIC_VECTOR(15 downto 0));
end LeitwerkCode;

architecture Behavioral of LeitwerkCode is

signal BEFEHLSZAEHLER : STD_LOGIC_VECTOR(15 downto 0) := Init; --schlechtes Programmieren? Eine Bit mit 16 lane die einmalig geladen wird 
signal Semaphor : STD_LOGIC := '0';
type STATE_TYPE is (Z0,Z1,Z2,Z3,Z4);
signal STATE, NEXT_ST: STATE_TYPE;
begin
--Zustandspeicher
LWerk: process(CLK,RESET) 
begin
    if risng_edge(CLK) then
        if RESET = '1' then
            STATE <= Z0;
            BEFEHLSZAEHLER <= Init;
            Steuersignale <= "00000000";
        else
            STATE <= Z0;
            case STATE is
                when Z0 => --- opcode fetch
                    STATE <= Z1;
                when Z1 => --- decode
                    STATE <= Z2;
                when Z2 => --- operand fetch
                    STATE <= Z3;
                when Z3 => --- execute
                    STATE <= Z4;
                when Z4 => --- write backk 
                    STATE <= Z0;
            end case;
        end if;
    end if;




end process LWerk;

end Behavioral;
