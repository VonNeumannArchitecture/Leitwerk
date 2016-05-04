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
           RW : out STD_LOGIC;
           Adressbus : out STD_LOGIC_VECTOR (15 downto 0);
           StatusRegister : in STD_LOGIC_VECTOR (3 downto 0);
           Steuersignale : out STD_LOGIC_VECTOR (3 downto 0);
           RESET : in STD_LOGIC;
           Init: in STD_LOGIC_VECTOR(15 downto 0));
end LeitwerkCode;

architecture Behavioral of LeitwerkCode is

signal BEFEHLSZAEHLER : STD_LOGIC_VECTOR(15 downto 0) := Init; --schlechtes Programmieren? Eine Bit mit 16 lane die einmalig geladen wird 
signal Semaphor : STD_LOGIC := '0';
signal Semaphor2 : STD_LOGIC := '1';
signal Counter : STD_LOGIC_VECTOR(3 downto 0) := "0000";
signal OpCodeREG: STD_LOGIC_VECTOR(7 downto 0);
signal HighByte: STD_LOGIC_VECTOR(7 downto 0);
type STATE_TYPE is (Z0,Z1,Z2,Z3,Z4);
signal STATE, NEXT_ST: STATE_TYPE;

subtype BEFEHL_TYPE is STD_LOGIC_VECTOR(7 downto 0);

constant NOPE: BEFEHL_TYPE:=  "10000000";
constant LDA_kn: BEFEHL_TYPE:=  "10000001";
constant LDA_an: BEFEHL_TYPE:=  "10000010";
constant STA_an: BEFEHL_TYPE:=  "10000011";

constant SHIFT_R: BEFEHL_TYPE := "00001001";
constant SHIFT_L: BEFEHL_TYPE := "00001010";
constant ADD_kn: BEFEHL_TYPE:=  "00001011";
constant SUB_kn: BEFEHL_TYPE:=  "00001100"; 

--000,101,110,111

--unbenutzt:
constant ADD_an: BEFEHL_TYPE:=  "00001101"; 
constant SUB_an: BEFEHL_TYPE:=  "00001110";


constant JMP_an: BEFEHL_TYPE:=  "00010001";
constant JMPC_an: BEFEHL_TYPE:=  "00100010";
constant JMPN_an: BEFEHL_TYPE:=  "00100011";
constant JMPO_an: BEFEHL_TYPE:=  "00100100";
constant JMPZ_an: BEFEHL_TYPE:=  "00100101";

constant NOT_: BEFEHL_TYPE:=  "01000111";
constant AND_: BEFEHL_TYPE:=  "01000101";
constant OR_:  BEFEHL_TYPE:=  "01000110";



alias ArithmethischREG: STD_LOGIC is OpCodeREG(3);
alias JMPBefehlREG: STD_LOGIC is OpCodeREG(4);
alias LogischREG: STD_LOGIC is OpCodeREG(5);
alias KontrollflussREG: STD_LOGIC is OpcodeREG(7);

--000,001,010,011,100,

begin
--Zustandspeicher
LWerk: process(CLK,RESET) 

variable Opcode: STD_LOGIC_VECTOR(7 downto 0);
--variable HighByte: STD_LOGIC_VECTOR(7 downto 0);
variable Lowbyte: STD_LOGIC_VECTOR(7 downto 0);
variable JMP_ADRESS: STD_LOGIC(15 downto 0);
variable JMP_COND: STD_LOGIC;

alias Kontrollfluss: STD_LOGIC is Opcode(7);
alias Arithmetisch: STD_LOGIC is Opcode(3);
alias JMPBefehl: STD_LOGIC is Opcode(4);
alias Logisch: STD_LOGIC is Opcode(5);


begin
    if risng_edge(CLK) then
        if RESET = '1' then
            STATE <= Z0;
            BEFEHLSZAEHLER <= Init;
            Steuersignale <= "0000";      
        else
            STATE <= Z0;
            case STATE is
  -----------------------------------------OPCODE------------------------------------------------------------------------
                when Z0 =>
                    Steuersignale <= "0000";
                    Adressbus <= BEFEHLSZAEHLER; --Befehlszaehler auf den Adressbus schreiben, um Speicher zu signalisieren, was man auf dem Datenbus haben möchte
                    BEFEHLSZAEHLER <= BEFEHLSZAEHLER +1;
                    CS_OUT <= '0'; --?? Muss noch deklariert werden, wie es genau ausgewaehlt werden soll
                    RW <= '1';
                    STATE <= Z1;
 -----------------------------------------DECODE------------------------------------------------------------------------
                when Z1 =>
                    Steuersignale <= "0000";
                    STATE <= Z2;
                    Opcode <= Datenbus;
                    CS <= '1';
                    
                    OpCodeREG <= Datenbus;
                        if Kontrollfluss = '1' then --NOPE (00), LDA_kn(01), LDA_an(10), STA_an (11) --> Sobald ein Bit "1" ist muss immer das gleiche getan werden, andernfalls NICHTS
                            if OpCode(0) or OpCode(1) then
                                Adressbus <= BEFEHLSZAEHLER; CS <= '0'; RW <= '1';
                             end if;
                        elsif Arithmetisch = '1' then 
                            case OpCode is
                                when ADD_kn =>Adressbus <= BEFEHLSZAEHLER; CS <= '0'; RW <= '1';
                                when SUB_kn => Adressbus <= BEFEHLSZAEHLER; CS <= '0'; RW <= '1';
                                --Shift Befehl ist hier schon im Operand - Fetch / Execulte --> Signal kann also direkt übergeben werden an das Rechenwerk, genauso wie bei NOT
                                when SHIFT_R => Steuersignale <= "1001";  STATE <= Z3; --braucht kein Operand fetch
                                when SHIFT_L => Steuersignale <= "1010";  STATE <= Z3; --braucht kein Operand fetch
                                when others => STATE <= Z0;
                            end case;
                        elsif JMPBefehl = '1' then --JMP BEFEHLE
                            Adressbus <= BEFEHLSZAEHLER; CS <= '0'; RW <= '1';
                        elsif Logisch = '1' then
                            case OpCode is
                                when NOT_ => Steuersignale <= "0111"; STATE <= Z3;--braucht kein Operand
                                when AND_ => Adressbus <= BEFEHLSZAEHLER; CS <= '0'; RW <= '1';
                                when OR_ => Adressbus <= BEFEHLSZAEHLER; CS <= '0'; RW <= '1';
                                when others => STATE <= Z0;
                            end case;
                        end if;                
 -----------------------------------------OPERAND FETCH------------------------------------------------------------------------
                when Z2 =>
                  CS <= '1';
                  Steuersignale <= "0000"; 
                  STATE <= Z3;
                  --KONTROLLFLUSS BEFEHLE-----------------------------------------------------------------
                  if KontrollflussREG = '1' then
                        case OpCodeREG is
                          when NOPE => --Adressbus <= BEFEHLSZAEHLER;
                          when LDA_an =>
                              if Semaphor = '0' then
                                  Semaphor <= '1';
                                  HighByte <= Datenbus;
                                  Adressbus <= BEFEHLSZAEHLER + 1; CS <= '0'; RW <= '1';
                                  BEFEHLSZAEHLER <= BEFEHLSZAEHLER +1;
                                  STATE <= Z2;
                              else
                                  Semaphor <= '0';
                                  LowByte := Datenbus;
                                  Adressbus <= HighByte & LowByte; CS <= '0'; RW <= '1';
                              end if;
                              
                          when LDA_kn => Steuersignale <= "0001";
                          
                          when STA_an => 
                              if Semaphor = '0' then
                                  Semaphor <= '1';
                                  HighByte <= Datenbus;
                                  Adressbus <= BEFEHLSZAEHLER + 1; CS <= '0'; RW <= '1';
                                  BEFEHLSZAEHLER <= BEFEHLSZAEHLER +1;
                                  STATE <= Z2;
                              else
                                  Semaphor <= '0';
                                  LowByte := Datenbus;
                                  Adressbus <= HighByte & LowByte; CS <= '0'; RW <= '1';
                                  Steuersignale <= "0011"; -- ALU sagen, dass es die Daten auf den Bus legen soll
                              end if;
                          when others => STATE <= Z0;
                      end case;
                   
                   --ARITHMETHISCHE BEFEHLE--------------------------------------------------------------   
                  elsif ArithmetischREG = '1' then 
                    if  OpCodeREG(2 downto 0) = "000" or OpCodeREG(2 downto 0) = "101" or OpCodeREG(2 downto 0) = "110" or OpCodeREG(2 downto 0) = "111" then
                        STATE <= Z0; --Opcode wurde nicht richtig entschlüsselt
                    else
                        Steuersignale <= OpCodeREG(3 downto 0);
                    end if;
                  --JMP BEFEHL----------------------------------------------------------------------------
                  elsif JMPBefehlREG = '1' then 
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
                                 Adressbus <= BEFEHLSZAEHLER + 1; CS <= '0'; RW <= '1';
                                 BEFEHLSZAEHLER <= BEFEHLSZAEHLER +1;
                             else              
                                 Semaphor <= '0';
                                 LowByte <= Datenbus;
                                 BEFEHLSZAEHLER <=  HighByte & LowByte;
                                 STATE <= Z0;
                             end if;
                          else
                            STATE <= Z0;
                          end if;
                  --LOGISCHE BEFEHLE------------------------------------------------------------------------------------
                  elsif LogischREG = '1' then
                      if OpCodeREG(2 downto 0) = "000" or OpCodeREG(2 downto 0) = "001" or OpCodeREG(2 downto 0) = "010"  or OpCodeREG(2 downto 0) = "011" or OpCodeREG(2 downto 0) = "100" then
                        STATE <= Z0;
                      else
                        Steuersignale <= OpCodeREG(3 downto 0);
                      end if;
                  end if;         
 -----------------------------------------EXECUTE------------------------------------------------------------------------                  
                when Z3 =>
                Steuersignale <= "0000";
                    if ArithmethischREG = "1" then
                        if OpCodeReg(1 downto 0) = "01" then --Load Address
                            Steuersignale <= "0001";
                        elsif OpCodeReg(1 downto 0) = "11" then --Store Address
                            RW <= '0';
                            Steuersignale <= "0011"; -- ALU sagen, dass es die Daten auf den Bus legen soll
                        end if;
                    end if;
               
                    BEFEHLSZAHLER <= BEFEHLSZAEHLER + 1; --Um auf den nächsten Befehl zu kommen                
                    STATE <= Z4;
                    WRITE_ON_DATA_BUS <= '0'; --Nicht mehr erlauben auf den datenbus zu schreiben
 -----------------------------------------STORE------------------------------------------------------------------------    
                when Z4 =>
                    CS <= '1';
                    Steuersignale <= "0000";
                    RW <= '1'; --Standard Value
                    Counter <= "0000"; --Standard value
                    STATE <= Z0;
            end case;
        end if;
    end if;
    
end process LWerk;
end Behavioral;
