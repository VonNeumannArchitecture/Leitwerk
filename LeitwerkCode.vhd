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
           Datenbus : in STD_LOGIC_VECTOR (7 downto 0);
           CS_out : out STD_LOGIC;
           WRITE_ENABLE_OUT : out STD_LOGIC;
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

subtype BEFEHL_TYPE is STD_LOGIC_VECTOR(7 downto 0);
constant NOPE: BEFEHL_TYPE:=  "10000000";
constant LDA_kn: BEFEHL_TYPE:=  "10000001";
constant LDA_an: BEFEHL_TYPE:=  "10000010";
constant STA_an: BEFEHL_TYPE:=  "10000011";

constant ADD_kn: BEFEHL_TYPE:=  "00001000";
constant ADD_an: BEFEHL_TYPE:=  "00001001";
constant SUB_kn: BEFEHL_TYPE:=  "00001010";
constant SUB_an: BEFEHL_TYPE:=  "00001011";
constant SHIFT_L: BEFEHL_TYPE = "00001100";
constant SHIFT_R: BEFEHL_TYPE = "00001101";

constant JMP_an: BEFEHL_TYPE:=  "00010001";
constant JMPC_an: BEFEHL_TYPE:=  "00100010";
constant JMPN_an: BEFEHL_TYPE:=  "00100011";
constant JMPO_an: BEFEHL_TYPE:=  "00100100";
constant JMPZ_an: BEFEHL_TYPE:=  "00100101";

constant NOT_: BEFEHL_TYPE:=  "01000000";
constant AND_: BEFEHL_TYPE:=  "01000010";
constant OR_:  BEFEHL_TYPE:=  "01000011";


begin
--Zustandspeicher
LWerk: process(CLK,RESET) 
begin
    variable Opcode : STD_LOGIC_VECTOR(7 downto 0);
    variable HighByte: STD_LOGIC_VECTOR(7 downto 0);
    variable Lowbyte: STD_LOGIC_VECTOR(7 downto 0);
    variable JMP_ADRESS: STD_LOGIC(15 downto 0);
    if risng_edge(CLK) then
        if RESET = '1' then
            STATE <= Z0;
            BEFEHLSZAEHLER <= Init;
            Steuersignale <= "00000000";
        else
            STATE <= Z0;
            case STATE is
                when Z0 => --- opcode fetch
                    Adressbus <= BEFEHLSZAEHLER; --Befehlszaehler auf den Adressbus schreiben, um Speicher zu signalisieren, was man auf dem Datenbus haben möchte
                    BEFEHLSZAEHLER <= BEFEHLSZAEHLER +1;
                    CS_OUT <= '0'; --?? Muss noch deklariert werden, wie es genau ausgewaehlt werden soll
                    WRITE_ENABLE_OUT <= '1';
                    STATE <= Z1;
                when Z1 => --- decode
                    Opcode <= Datenbus;
                        if Opcode(7) = '1' then
                            case OpCode is
                                when NOPE => --Adressbus <= BEFEHLSZAEHLER;
                                when LDA_kn => Adressbus <= BEFEHLSZAEHLER;
                                when LDA_an => 
                                when STA_an =>
                                when others =>
                            end case;
                        elsif Opcode(3) = '1' then 
                            case OpCode is
                                when ADD_kn =>
                                when ADD_an => 
                                when SUB_kn => 
                                when SUB_an => 
                                when SHIFT_L => 
                                when SHIFT_R =>
                                when others =>
                            end case;
                        elsif Opcode(4) = '1' then
                            case OpCode is
                                when JMP_an =>
                                when JMPC_an =>
                                when JMPN_an =>
                                when JMPO_an =>
                                when JMPZ_an =>
                                when others =>
                            end case;
                        elsif Opcode(5) = '1' then
                            case OpCode is
                                when NOT_ =>
                                when AND_ =>
                                when OR_ =>
                                when others =>
                            end case;
                        end if;
                    STATE <= Z2;
                    WRITE_ENABLE_OUT <= '0';
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
