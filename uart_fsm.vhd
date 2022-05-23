-- uart_fsm.vhd: UART controller - finite state machine
-- Author(s): xmasek19
--
library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------
entity UART_FSM is
port(
   CLK : in std_logic;
   RST : in std_logic;
   DIN : in std_logic;
   RE : out std_logic;
	WE : out std_logic;
	VALID : out std_logic;
	CNT_RST : out std_logic;
   BIT_CNT : in std_logic_vector(3 downto 0)
   );
end entity UART_FSM;

-------------------------------------------------
architecture behavioral of UART_FSM is
  type FSM_STATE_T is (IDLE,READ_STATE,WAIT_STOP,SUCCESS);
  signal CUR_STATE 	: FSM_STATE_T := IDLE;
  signal NEXT_STATE 	: FSM_STATE_T := IDLE;
begin
 
-------------------------------------------------SET CUR STATE
	fsm_cur_state: process (CLK, RST)
	begin
		if (RST='1')then
			CUR_STATE <= IDLE;
		elsif CLK'event and CLK='1' then
			CUR_STATE <=NEXT_STATE;
		end if;
	end process;

-------------------------------------------------NEXT STATE
	fsm_next_state: process (CUR_STATE, DIN,BIT_CNT)
   begin
      NEXT_STATE <= CUR_STATE;
      case (CUR_STATE) is
         when IDLE =>
            if DIN = '0' then
               NEXT_STATE <= READ_STATE;
            end if;
				
         when READ_STATE =>
            if (BIT_CNT = "1000")then
               NEXT_STATE <= WAIT_STOP;
            end if;
				
         when WAIT_STOP =>
            if (BIT_CNT = "1001") and (DIN = '1')then
               NEXT_STATE <= SUCCESS;
            end if;
				
         when SUCCESS =>
            NEXT_STATE <= IDLE;
				
         when others =>
            NEXT_STATE <= IDLE;
      end case;      
   end process;

-------------------------------------------------OUT
	fsm_out_logic: process (CUR_STATE) begin
		case CUR_STATE is
				
          when IDLE =>
				RE <= '0';
				WE <= '0';
				VALID <= '0';
				CNT_RST <= '1';
            
          when READ_STATE =>
				RE <= '1';
				WE <= '1';
				VALID <= '0';
				CNT_RST <= '0';
            
          when WAIT_STOP =>
				RE <= '1';
				WE <= '0';
				VALID <= '0';
				CNT_RST <= '0';
            
          when SUCCESS =>  
            RE <= '0';
				WE <= '0';
				VALID <= '1';
            CNT_RST <= '0';
				
			 when others => null;
      
		end case;  			 
	end process;
end behavioral;
