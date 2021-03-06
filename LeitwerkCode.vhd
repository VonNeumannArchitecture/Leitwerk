----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Kevin Grygosch, Kevin Höfle
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity LeitwerkCode is
    Port ( CLK : in STD_LOGIC;
           Datenbus : in STD_LOGIC_VECTOR (7 downto 0);
           CS : out STD_LOGIC;
           RW : out STD_LOGIC;
           Adressbus : out STD_LOGIC_VECTOR (15 downto 0);
           StatusRegister : in STD_LOGIC_VECTOR (3 downto 0);
           Steuersignale : out STD_LOGIC_VECTOR (3 downto 0);
           RESET : in STD_LOGIC;
           Init: in STD_LOGIC_VECTOR(15 downto 0));
end LeitwerkCode;

architecture Behavioral of LeitwerkCode is

signal BEFEHLSZAEHLER : unsigned(15 downto 0) := unsigned(Init); --schlechtes Programmieren? Eine Bit mit 16 lane die einmalig geladen wird 
signal Semaphor : STD_LOGIC := '0';

signal HOLD : STD_LOGIC := '0';

--signal Semaphor2 : STD_LOGIC := '1';
--signal Counter : STD_LOGIC_VECTOR(3 downto 0) := "0000";
signal OpCodeREG: STD_LOGIC_VECTOR(7 downto 0);
signal HighByte: STD_LOGIC_VECTOR(7 downto 0);
signal LowByte: STD_LOGIC_VECTOR(7 downto 0);

signal JMP_CONDREG: STD_LOGIC := '0';
--type STATE_TYPE is (Z0,Z1,Z2,Z3,Z4);
type STATE_TYPE is (OPCODE_FETCH,DECODE,OPERAND_FETCH,EXECUTE,WRITE_BACK);
signal STATE, NEXT_ST: STATE_TYPE;

subtype BEFEHL_TYPE is STD_LOGIC_VECTOR(7 downto 0);

constant NOPE: BEFEHL_TYPE:=  "10000000";
constant LDA_kn: BEFEHL_TYPE:=  "10000001"; --Typ 1
constant LDA_an: BEFEHL_TYPE:=  "10000010"; --Typ 2
constant STA_an: BEFEHL_TYPE:=  "10000011"; --Typ 3

constant SHIFT_R: BEFEHL_TYPE := "00001001"; --Typ 4
constant SHIFT_L: BEFEHL_TYPE := "00001010"; --Typ 4
constant ADD_kn: BEFEHL_TYPE:=  "00001011"; --Typ 5
constant SUB_kn: BEFEHL_TYPE:=  "00001100";  --Typ 5

--000,101,110,111

--unbenutzt:
constant ADD_an: BEFEHL_TYPE:=  "00001101"; 
constant SUB_an: BEFEHL_TYPE:=  "00001110";


constant JMP_an: BEFEHL_TYPE:=  "00010001";  --Typ 6
constant JMPC_an: BEFEHL_TYPE:=  "00010010"; --Typ 7
constant JMPN_an: BEFEHL_TYPE:=  "00010011"; --Typ 6
constant JMPO_an: BEFEHL_TYPE:=  "00010100"; -- "
constant JMPZ_an: BEFEHL_TYPE:=  "00010101"; -- "

constant NOT_B: BEFEHL_TYPE:=  "01000111"; --Typ 4
constant AND_B: BEFEHL_TYPE:=  "01000101"; --Typ 5
constant OR_B:  BEFEHL_TYPE:=  "01000110"; -- Typ 5


alias SpeicherzugriffREG: STD_LOGIC is OpcodeREG(7);
alias ArithmethischREG: STD_LOGIC is OpCodeREG(3);
alias JMPBefehlREG: STD_LOGIC is OpCodeREG(4);
alias LogischREG: STD_LOGIC is OpCodeREG(6);

alias c : STD_LOGIC is StatusRegister(0);
alias z : STD_LOGIC is StatusRegister(1);
alias n : STD_LOGIC is StatusRegister(2);
alias o : STD_LOGIC is StatusRegister(3);
--000,001,010,011,100,

begin
--Zustandspeicher
LWerk: process(CLK,RESET) 

variable Opcode: STD_LOGIC_VECTOR(7 downto 0);
--variable HighByte: STD_LOGIC_VECTOR(7 downto 0);
--variable Lowbyte: STD_LOGIC_VECTOR(7 downto 0);
variable JMP_ADRESS: STD_LOGIC_VECTOR(15 downto 0);
variable JMP_COND: STD_LOGIC := '0';

variable ADDR_COND: STD_LOGIC_VECTOR(1 downto 0) := "00";
alias Speicherzugriff: STD_LOGIC is Opcode(7);
alias Arithmetisch: STD_LOGIC is Opcode(3);
alias JMPBefehl: STD_LOGIC is Opcode(4);
alias Logisch: STD_LOGIC is Opcode(6);


begin
    if rising_edge(CLK) then
        if RESET = '1' then
            STATE <= OPCODE_FETCH;
            BEFEHLSZAEHLER <= unsigned(Init);-- +1;
            Steuersignale <= "0000";
            Adressbus <= (others => 'Z');
            CS <= 'Z';
            RW <= 'Z';
            JMP_CONDREG <= '0';   
            Semaphor <= '0';
            Hold <= '0';

        else
            STATE <= OPCODE_FETCH;
            

            case STATE is
-----------------------------------------OPCODE------------------------------------------------------------------------
                when OPCODE_FETCH =>
                    Steuersignale <= "0000";
                    CS <= '1';
                    if HOLD = '0' then
                        Adressbus <= std_logic_vector(BEFEHLSZAEHLER); CS <= '0'; RW <= '1';--Befehlszaehler auf den Adressbus schreiben, um Speicher zu signalisieren, was man auf dem Datenbus haben möchte
                        HOLD <= '1';
                        STATE <= OPCODE_FETCH;
                    else
                        STATE <= DECODE;
                        HOLD <= '0';
                    end if;
 -----------------------------------------DECODE------------------------------------------------------------------------
                when DECODE =>
                    Steuersignale <= "0000";
                    STATE <= OPERAND_FETCH;
                    Opcode := Datenbus; 
                    OpCodeREG <= Datenbus;
                    CS <= '1'; 
                        if Speicherzugriff = '1' then --NOPE (00), LDA_kn(01), LDA_an(10), STA_an (11) --> Sobald ein Bit "1" ist muss immer das gleiche getan werden, andernfalls NICHTS
                              if Opcode = LDA_an or Opcode = LDA_kn or Opcode = STA_an or Opcode = NOPE then
                                 ADDR_COND := "00";
                              else
                                 ADDR_COND := "11";                               
                              end if;
                        elsif Arithmetisch = '1' then 
                            case OpCode is
                                when ADD_kn =>  ADDR_COND := "00";         
                                when SUB_kn =>  ADDR_COND := "00";
                                when SHIFT_R =>  ADDR_COND := "01";
                                when SHIFT_L => ADDR_COND := "01";
                                when others => ADDR_COND := "11";
                            end case;
                        elsif JMPBefehl = '1' then --JMP BEFEHLE
                               ADDR_COND := "00";
                        elsif Logisch = '1' then
                            case OpCode is
                                when NOT_B => ADDR_COND := "01";
                                when AND_B => ADDR_COND := "00";
                                when OR_B =>  ADDR_COND := "00";
                                when others => ADDR_COND := "11";
                            end case;
                        else
                            ADDR_COND := "11";
                        end if;   
                                  
                        if ADDR_COND = "00" then
                            Adressbus <= std_logic_vector(BEFEHLSZAEHLER+1); CS <= '0'; RW <= '1';
                            BEFEHLSZAEHLER <= BEFEHLSZAEHLER + 1;
                        elsif ADDR_COND = "01" then
                            Steuersignale <= Opcode(3 downto 0);
                            STATE <= EXECUTE;
                        else 
                            STATE <= OPCODE_FETCH; BEFEHLSZAEHLER <= BEFEHLSZAEHLER + 1;
                        end if;                                                             
                        

 -----------------------------------------OPERAND FETCH------------------------------------------------------------------------
                when OPERAND_FETCH =>
                  CS <= '1';
                  Steuersignale <= "0000"; 
                  STATE <= EXECUTE;
                  --Speicherzugriff BEFEHLE-----------------------------------------------------------------
                  if SpeicherzugriffREG = '1' then
                      if OpCodeREG = NOPE then
                      elsif OpCodeREG = LDA_an or OpCodeREG = STA_an then
                         ADDR_COND := "00";
                      elsif OpCodeREG = LDA_kn then
                         ADDR_COND := "01";
                      else
                        ADDR_COND := "11";
                      end if;
                  
                  --ARITHMETHISCHE BEFEHLE--------------------------------------------------------------   
                  elsif ArithmethischREG = '1' then 
                    if  OpCodeREG(2 downto 0) = "000" or OpCodeREG(2 downto 0) = "101" or OpCodeREG(2 downto 0) = "110" or OpCodeREG(2 downto 0) = "111" then
                        ADDR_COND := "11";
                    else
                        ADDR_COND := "01";
                    end if;
                  --JMP BEFEHL----------------------------------------------------------------------------
                  elsif JMPBefehlREG = '1' then 
                        JMP_COND := '0'; --Unterscheidung ob ein JMP BEFEHl gemacht werden soll
                        case OpCodeREG(2 downto 0) is --Welcher JMP BEFEHL ? 
                            when "001" => 
                                JMP_COND := '1'; 
                                JMP_CONDREG <= '1';
                            when "010" => 
                                if C = '1' then
                                    JMP_COND := '1';
                                    JMP_CONDREG <= '1';
                                end if;
                            when "011" =>
                                if N = '1' then
                                    JMP_COND := '1';
                                    JMP_CONDREG <= '1';
                                end if;
                            when "100" =>
                                if O = '1' then
                                    JMP_COND := '1';
                                    JMP_CONDREG <= '1';
                                end if;
                            when "101" =>
                                if Z = '1' then
                                    JMP_COND := '1';
                                    JMP_CONDREG <= '1';
                               end if;
                             when others =>  STATE <= OPCODE_FETCH; BEFEHLSZAEHLER <= BEFEHLSZAEHLER +1;
                         end case;
                         
                         if JMP_COND = '1' or JMP_CONDREG = '1' then
                            ADDR_COND := "00";
                         else
                            ADDR_COND := "11";
                         end if;
                  --LOGISCHE BEFEHLE------------------------------------------------------------------------------------
                  elsif LogischREG = '1' then
                      if OpCodeREG(2 downto 0) = "000" or OpCodeREG(2 downto 0) = "001" or OpCodeREG(2 downto 0) = "010"  or OpCodeREG(2 downto 0) = "011" or OpCodeREG(2 downto 0) = "100" then
                        ADDR_COND := "11";
                      else
                        ADDR_COND := "01";
                      end if;
                  else
                    ADDR_COND := "11"; --Sollte nicht passieren, aber wegen variable - sonst entsteht evtl. kombinatorische Schleife!
                  end if;    

                  if ADDR_COND = "00" then
                      if Semaphor = '0' then
                       If Hold = '0' then
                           STATE <= OPERAND_FETCH;
                           Adressbus <= std_logic_vector(BEFEHLSZAEHLER + 1); CS <= '0'; RW <= '1';
                           BEFEHLSZAEHLER <= BEFEHLSZAEHLER +1;
                           Hold <= '1';
                       else                                                       
                            STATE <= OPERAND_FETCH;
                            HOLD <= '0';       
                            HighByte <= Datenbus;
                            Semaphor <= '1';                
                       end if;
                      else
                          LowByte <= Datenbus;
                          Semaphor <= '0';
                          if OpCodeREG = LDA_an or JMP_CONDREG = '1'  then
                               STATE <= EXECUTE;
                          elsif OpCodeREG = STA_an then
                               STATE <= WRITE_BACK;
                               Steuersignale <= OpCodeReg(3 downto 0); 
                          end if;
                       end if;
                  elsif ADDR_COND = "01" then
                     Steuersignale <= OpCodeREG(3 downto 0);
                  else 
                      STATE <= OPCODE_FETCH; 
                      BEFEHLSZAEHLER <= BEFEHLSZAEHLER + 1;
                      if JMPBefehlREG = '1' then
                        BEFEHLSZAEHLER <= BEFEHLSZAEHLER + 2;
                      end if;
                  end if;   
                       
 -----------------------------------------EXECUTE------------------------------------------------------------------------                  
                when EXECUTE =>
                Steuersignale <= "0000";
                STATE <= WRITE_BACK;
                
               --wenn kein Sprung hochzählen
               if JMP_CONDREG = '1' then
                    BEFEHLSZAEHLER <=  unsigned(HighByte & LowByte);
                    JMP_CONDREG <= '0';
                else
                    BEFEHLSZAEHLER <= BEFEHLSZAEHLER +1;
                end if;       
               
                --Just for Load Address N    
                if SpeicherzugriffREG = '1' then
                    if OpCodeReg(1 downto 0) = "10" then
                        Adressbus <= HighByte & LowByte; CS <= '0'; RW <= '1';
                    end if;
                end if;
                    
 -----------------------------------------STORE------------------------------------------------------------------------    
                when WRITE_BACK =>
                    CS <= '1';
                    Steuersignale <= "0000";
                    RW <= '1'; --Standard Value
                    STATE <= OPCODE_FETCH;
                    if SpeicherzugriffREG = '1' then
                        if OpCodeReg(1 downto 0) = "10" then--or OpCodeReg(1 downto 0) = "11" then --Load Address
                            Steuersignale <= "0001"; --im Adresse Execute rausgegeben
                        elsif OpCodeReg(1 downto 0) = "11" then --Store Address
                            Adressbus <= HighByte & LowByte; CS <= '0'; RW <= '0';
                        end if;
                    end if;
            end case;
        end if;
    end if;
end process LWerk;
end Behavioral;
