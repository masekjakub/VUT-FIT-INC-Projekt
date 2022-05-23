-- uart.vhd: UART controller - receiving part
-- Author(s): xmasek19
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------
entity UART_RX is
port(	
	CLK: 	    in std_logic;
	RST: 	    in std_logic;
	DIN: 	    in std_logic;
	DOUT: 	 out std_logic_vector(7 downto 0);
	DOUT_VLD: out std_logic
);
end UART_RX;  

-------------------------------------------------
architecture behavioral of UART_RX is
  signal bit_cnt 			: std_logic_vector(3 downto 0):="0000";
  signal clk_cnt 			: std_logic_vector (4 downto 0):="00000";
  signal we 				: std_logic:='0';
  signal re 				: std_logic:='0';
  signal cnt_rst 			: std_logic:='0';
  signal mid_bit_tick 	: std_logic:='0';
  signal mux_out 			: std_logic_vector (4 downto 0):="10110";
  signal dmux_out 		: std_logic_vector (7 downto 0);
  signal bit_is_first 	: std_logic:='0';
  signal dmux_in 			: std_logic:='0';
  signal din_stable 		: std_logic:='1';
  signal dout_vld_fsm 	: std_logic:='0';
  signal din_register 	: std_logic_vector (2 downto 0):="111";

begin

------------------------------------------------FSM
    FSM: entity work.UART_FSM (behavioral)
    port map (
        CLK 	   => CLK,
        RST 	   => RST,
        DIN 	   => din_stable,
		  RE			=> re,
		  WE			=> we,
        BIT_CNT 	=> bit_cnt,
        VALID 		=> dout_vld_fsm,
		  CNT_RST 	=> cnt_rst
    );
			
------------------------------------------------SHIFT REGISTER (DIN -> din_stable)
	din_shift_register: process (CLK) is
	begin
		if CLK'event and CLK='1' then  
			 din_stable 	  <= din_register(0);
			 din_register(0) <= din_register(1);
			 din_register(1) <= din_register(2);
			 din_register(2) <= DIN;
		end if;
	end process;
------------------------------------------------CLK COUNTER
	clk_counter: process (CLK,RST,re,mid_bit_tick)
	begin
		if (CLK='1' and CLK'event) then
			if (mid_bit_tick = '1' or cnt_rst='1') then
				clk_cnt <= "00000";
			elsif (re ='1') then
				clk_cnt <= clk_cnt + 1;
			end if;
		end if; 
	end process;

------------------------------------------------BIT COUNTER
	bit_counter: process (CLK,mid_bit_tick) 
	begin
		if (CLK='1' and CLK'event) then
			if (cnt_rst = '1') then
				bit_cnt <= "0000";
			elsif (mid_bit_tick = '1') then
				bit_cnt <= bit_cnt + 1;
			end if;
		end if;
	end process;
	
------------------------------------------------MID BIT COMPARATOR
	mid_bit_cmp: process(clk_cnt, mux_out)
	begin   
		if ( clk_cnt = mux_out ) then 
			mid_bit_tick <= '1';
		else 
			mid_bit_tick <= '0';
		end if;
	end process; 
	
------------------------------------------------FIRST BIT COMPARATOR
	first_bit_cmp: process(bit_cnt)
	begin 
		if ( bit_cnt = "0000" ) then 
			bit_is_first <= '1';
		else 
			bit_is_first <= '0';
		end if; 
	end process; 

------------------------------------------------MUX 15/22
	mux_out <= "10110" WHEN bit_is_first ='1' ELSE "01111";
	
------------------------------------------------AND (demux input)
	dmux_in <= mid_bit_tick and we;
	
------------------------------------------------DEMUX
	demux: process(bit_cnt,dmux_in)
	begin
		dmux_out <= "00000000";
		if (dmux_in = '1') then
			case bit_cnt is
				when "0000" => dmux_out(0) <= '1';
				when "0001" => dmux_out(1) <= '1';
				when "0010" => dmux_out(2) <= '1';
				when "0011" => dmux_out(3) <= '1';
				when "0100" => dmux_out(4) <= '1';
				when "0101" => dmux_out(5) <= '1';
				when "0110" => dmux_out(6) <= '1';
				when "0111" => dmux_out(7) <= '1';
				when others => dmux_out <= "00000000";
			end case;
		end if;
	end process;
-----------------------------------------------DOUT D-FLIP-FLOPs
	dout_registers: process(CLK, dmux_out,RST)
	begin  
		if CLK'event and CLK='1' then
			for index in 0 to 7 loop
				if (RST='1') then
					DOUT(index) <= '0';
				elsif(dmux_out(index) = '1')then
					DOUT(index) <= din_stable; 
				end if; 
			end loop;	 
		end if;	 	 
	end process; 
-----------------------------------------------DOUT_VLD D-FLIP-FLOP
	dout_vld_register: process (CLK)
	begin
		if CLK'event and CLK='1' then  
			DOUT_VLD <= dout_vld_fsm;
		end if;
	end process;
	
-----------------------------------------------	
end behavioral;