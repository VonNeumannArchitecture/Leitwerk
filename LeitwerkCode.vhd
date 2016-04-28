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
           Steuersignale : out STD_LOGIC_VECTOR (2 downto 0);
           RESET : in STD_LOGIC;
           Init: in STD_LOGIC_VECTOR(15 downto 0));
end LeitwerkCode;

architecture Behavioral of LeitwerkCode is

signal BEFEHLSZAEHLER : STD_LOGIC_VECTOR(15 downto 0) := Init; --schlechtes Programmieren? Eine Bit mit 16 lane die einmalig geladen wird 
signal Semaphor : STD_LOGIC := '0';
signal Semaphor2 : STD_LOGIC := '1';
signal OpCodeREG: STD_LOGIC_VECTOR(7 downto 0);
signal HighByte: STD_LOGIC_VECTOR(7 downto 0);
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
constant SHIFT_L: BEFEHL_TYPE := "00001100";
constant SHIFT_R: BEFEHL_TYPE := "00001101";

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

variable Opcode: STD_LOGIC_VECTOR(7 downto 0);
--variable HighByte: STD_LOGIC_VECTOR(7 downto 0);
variable Lowbyte: STD_LOGIC_VECTOR(7 downto 0);
variable JMP_ADRESS: STD_LOGIC(15 downto 0);
variable JMP_COND: STD_LOGIC;
begin
    if risng_edge(CLK) then
        if RESET = '1' then
            STATE <= Z0;
            BEFEHLSZAEHLER <= Init;
            Steuersignale <= "00000000";
        else
            STATE <= Z0;
            case STATE is
  -----------------------------------------OPCODE------------------------------------------------------------------------
                when Z0 =>
                    Adressbus <= BEFEHLSZAEHLER; --Befehlszaehler auf den Adressbus schreiben, um Speicher zu signalisieren, was man auf dem Datenbus haben möchte
                    BEFEHLSZAEHLER <= BEFEHLSZAEHLER +1;
                    CS_OUT <= '0'; --?? Muss noch deklariert werden, wie es genau ausgewaehlt werden soll
                    WRITE_ENABLE_OUT <= '1';
                    STATE <= Z1;
 -----------------------------------------DECODE------------------------------------------------------------------------
                when Z1 =>
                    STATE <= Z2;
                    Opcode <= Datenbus;
                    OpCodeREG <= Datenbus;
                        if Opcode(7) = '1' then
                            case OpCode is
                                when NOPE => --Adressbus <= BEFEHLSZAEHLER;
                                when LDA_kn => Adressbus <= BEFEHLSZAEHLER; CS <= '0'; WRITE_ENABLE_OUT <= '1';
                                when LDA_an => Adressbus <= BEFEHLSAEHLER; CS <= '0'; WRITE_ENABLE_OUT <= '1';
                                when STA_an => Adressbus <= BEFEHLSZAEHLER; CS <= '0'; WRITE_ENABLE_OUT <= '1';
                                when others => STATE <= Z0;
                            end case;
                        elsif Opcode(3) = '1' then 
                            case OpCode is
                                when ADD_kn =>Adressbus <= BEFEHLSZAEHLER; CS <= '0'; WRITE_ENABLE_OUT <= '1';
                                when SUB_kn => Adressbus <= BEFEHLSZAEHLER; CS <= '0'; WRITE_ENABLE_OUT <= '1';
                                --Shift Befehl ist hier schon im Operand - Fetch / Execulte --> Signal kann also direkt übergeben werden an das Rechenwerk, genauso wie bei NOT
                                when SHIFT_R => Steuersignale <= "001";  STATE <= Z3;
                                when SHIFT_L => Steuersignale <= "010";  STATE <= Z3;
                                when others => STATE <= Z0;
                            end case;
                        elsif Opcode(4) = '1' then
                            Adressbus <= BEFEHLSZAEHLER;
                        elsif Opcode(5) = '1' then
                            case OpCode is
                                when NOT_ => Steuersignale <= "111"; 
                                when AND_ => Adressbus <= BEFEHLSZAEHLER; CS <= '0'; WRITE_ENABLE_OUT <= '1';
                                when OR_ => Adressbus <= BEFEHLSZAEHLER; CS <= '0'; WRITE_ENABLE_OUT <= '1';
                                when others => STATE <= Z0;
                            end case;
                        end if;
                    
                    WRITE_ENABLE_OUT <= '0';
 -----------------------------------------OPERAND FETCH------------------------------------------------------------------------
                when Z2 =>
                  if OpCodeREG(7) = '1' then
                        case OpCodeREG is
                          when NOPE => --Adressbus <= BEFEHLSZAEHLER;
                          when LDA_an =>
                              if Semaphor = '0' then
                                  Semaphor <= '1';
                                  HighByte <= Datenbus;
                                  BEFEHLSZAEHLER <= BEFEHLSZAEHLER + 1;
                              else
                                  Semaphor <= '0';
                                  LowByte := Datenbus;
                                  Adressbus <= HighByte & LowByte; CS <= '0'; WRITE_ENABLE_OUT <= '1';
                              end if;
                              
                          when LDA_kn => Steuersignale <= "000";
                          
                          when STA_an => 
                              if Semaphor = '0' then
                                  Semaphor <= '1';
                                  HighByte <= Datenbus;
                                  BEFEHLSZAEHLER <= BEFEHLSZAEHLER + 1;
                              else
                                  Semaphor <= '0';
                                  LowByte := Datenbus;
                              end if;
                          when others => STATE <= Z0;
                      end case;
                      STATE <= Z3;
                  elsif OpCodeREG(3) = '1' then 
                      case OpCodeREG is                      
                          when SHIFT_R => Steuersignale <= "001";
                          when SHIFT_L => Steuersignale <= "010";
                          when ADD_kn => Steuersignale <= "011";
                          when SUB_kn => Steuersignale <= "100";
                          when others => STATE <= Z0;
                      end case;
                      STATE <= Z3;
                  elsif OpCodeREG(4) = '1' then --JMP BEFEHL
                        JMP_COND := '0'; --Unterscheidung ob ein JMP BEFEHl gemacht werden soll
                        case OpCodeReg(2 downto 0) is --Welcher JMP BEFEHL ? 
                        when "001" => JMP_COND := '1'; 
                            when "010" => 
                                if C = '1' then
                                    JMP_COND := '1';
                                end if;
                            when "011" =>
                                if N = '1' then
                                    JMP_COND := '1';
                                end if;
                            when "100" =>
                                if O = '1' then
                                    JMP_COND := '1';
                                end if;
                            when "101" =>
                                if Z = '1' then
                                    JMP_COND := '1';
                               end if;
                         end case;
                         
                         if JMP_COND = '1' then
                             if Semaphor = '0' then
                                 Semaphor <= '1';
                                 HighByte <= Datenbus;
                                 BEFEHLSZAEHLER <= BEFEHLSZAEHLER + 1;
                             else
                                 Semaphor <= '0';
                                 LowByte <= Datenbus;
                                 BEFEHLSZAEHLER <=  HighByte & LowByte;
                                 STATE <= Z0;
                             end if;
                          else
                            STATE <= Z0;
                          end if;

                  elsif OpCodeREG(5) = '1' then
                      case OpCodeREG is           
                          when AND_ => Steuersignale <= "101";
                          when OR_ => Steuersignale <= "110";
                          when NOT_ => Steuersignale <= "111";
                          when others => STATE <= Z0;
                      end case;
                      STATE <= Z3;
                  end if;         
 -----------------------------------------EXECUTE------------------------------------------------------------------------                  
                when Z3 =>
                    if OpCodeREG(7) = "1" then
                        if OpCodeReg(1 downto 0) = "10" then --Load Address
                            Steuersignale <= "000";
                        elsif OpCodeReg(1 downto 0) = "11" then --Store Address
                        
                        end if;
                    end if;
                
                
                
                    BEFEHLSZAHLER <= BEFEHLSZAEHLER + 1; --Um auf den nächsten Befehl zu kommen                
                    STATE <= Z4;
 -----------------------------------------STORE------------------------------------------------------------------------    
                when Z4 =>
                    STATE <= Z0;
            end case;
        end if;
    end if;
    
end process LWerk;
end Behavioral;
