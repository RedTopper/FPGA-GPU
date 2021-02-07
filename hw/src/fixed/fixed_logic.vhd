-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- fixed_logic.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains the fixed glue logic that records the 
-- results, and sends the printable data to the UART FIFO. Do not change
-- anything in this portion of the design.
--
-- NOTES:
-- 12/16/20 by JAZ::Design created.
------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity fixed_logic is
  port(i_CLK    : in std_logic;
       i_RST    : in std_logic;
       i_DONE   : in std_logic;

       i_Y0     : in std_logic_vector(63 downto 0);
	   i_Y1     : in std_logic_vector(63 downto 0);
	   i_Y2     : in std_logic_vector(63 downto 0);
	   i_Y3     : in std_logic_vector(63 downto 0);
		 
	   RxD      : in std_logic;
	   TxD      : out std_logic);
end fixed_logic;

architecture mixed of fixed_logic is

  -- component declarations
  component outmem
    port(i_CLKa, i_CLKb : in std_logic;
         i_ENa, i_ENb   : in std_logic;
		 i_WEa, i_WEb   : in std_logic;
		 i_ADDRa        : in std_logic_vector(4 downto 0);
		 i_ADDRb        : in std_logic_vector(4 downto 0);
         i_WDATAa       : in std_logic_vector(63 downto 0);
		 i_WDATAb       : in std_logic_vector(63 downto 0);
		 o_RDATAa       : out std_logic_vector(63 downto 0);
		 o_RDATAb       : out std_logic_vector(63 downto 0));
  end component;

  component uart_Controller
    port(clk100, rst    : in std_logic;
	     RxD            : in std_logic;
		 TxD            : out std_logic;
		 msg_din        : in std_logic_vector(63 downto 0);
		 msg_wren       : in std_logic;
		 msg_afull      : out std_logic);
  end component;

  component bin_to_ascii
    generic(N           : integer := 64);
    port(i_A            : in std_logic_vector(N-1 downto 0);
         o_F            : out std_logic_vector(2*N-1 downto 0));
  end component;

  -- outmem interface signals
  signal s_ADDRa, s_ADDRb   : std_logic_vector(4 downto 0);
  signal s_RDATAa, s_RDATAb : std_logic_vector(63 downto 0);
  signal s_WDATAa, s_WDATAb : std_logic_vector(63 downto 0);
  signal s_WEa, s_WEb : std_logic;

  -- uart_Controller interface signals
  signal s_msg_wren, s_msg_afull : std_logic;

  -- We're only interested in a single i_DONE cycle
  signal s_DONE, s_DONE_reg   : std_logic;

  -- To hold the running timer and the final timer value
  signal s_timer1     : unsigned(31 downto 0);
  signal s_timer2     : unsigned(34 downto 0);
  signal s_timer_reg  : std_logic_vector(31 downto 0);
  signal s_timer_reg2 : std_logic_vector(63 downto 0);

  -- To hold the y vector in a second register that only gets written once
  signal s_Y0_reg, s_Y1_reg, s_Y2_reg, s_Y3_reg : std_logic_vector(63 downto 0);
  signal s_Y0_reg2, s_Y1_reg2, s_Y2_reg2, s_Y3_reg2 : std_logic_vector(127 downto 0);

  -- Finite State Machine signals
  type state_type is (S0, S1, S2, S3, S4, S5, S6);
  signal cur_state : state_type;

begin


  U1: outmem
    port map(i_CLKa     => i_CLK,
             i_CLKb     => i_CLK,
       	     i_ENa      => '1',
		     i_ENb      => '1',
	         i_WEa      => s_WEa,
	         i_WEb      => s_WEb,
             i_ADDRa    => s_ADDRa,
	         i_ADDRb    => s_ADDRb,
	         i_WDATAa   => s_WDATAa,
	         i_WDATAb   => s_WDATAb,
             o_RDATAa   => s_RDATAa,
             o_RDATAb   => s_RDATAb);	

  U2: uart_Controller
    port map(clk100     => i_CLK,
             rst        => i_RST,
             RxD        => RxD,
		     TxD        => TxD,
             msg_din    => s_RDATAb,
			 msg_wren   => s_msg_wren,
			 msg_afull  => s_msg_afull);

  U3_0: bin_to_ascii
    generic map(N       => 64)
    port map(i_A        => s_Y0_reg,
	         o_F        => s_Y0_reg2);

  U3_1: bin_to_ascii
    generic map(N       => 64)
    port map(i_A        => s_Y1_reg,
	         o_F        => s_Y1_reg2);

  U3_2: bin_to_ascii
    generic map(N       => 64)
    port map(i_A        => s_Y2_reg,
	         o_F        => s_Y2_reg2);

  U3_3: bin_to_ascii
    generic map(N       => 64)
    port map(i_A        => s_Y3_reg,
	         o_F        => s_Y3_reg2);

  U3_4: bin_to_ascii
    generic map(N       => 32)
    port map(i_A        => s_timer_reg,
	         o_F        => s_timer_reg2);


  -- This process registers the i_DONE signal so that it only
  -- pulses for 1 cycle
  P0: process(i_CLK, i_RST, i_DONE)
  begin

    if (i_RST = '1') then
      s_DONE <= '0';
    elsif (rising_edge(i_CLK)) then
      s_DONE <= i_DONE;
    end if;
  end process;

  s_DONE_reg <= (not s_DONE) and i_DONE;

  -- To calculate the result in ns, multiply by 10
  s_timer2 <= (s_timer1 & "000") + (s_timer1 & "0");


  -- This process enables the timer counter when i_RST is received,
  -- and then stores the result when i_DONE is received
  P1: process(i_CLK, i_RST, s_DONE_reg, s_timer1, s_timer2)
  begin

    if (i_RST = '1') then  
	   s_timer1 <= (others => '0');

    elsif (rising_edge(i_CLK)) then
	   s_timer1 <= s_TIMER1 + 1;

      if (s_DONE_REG = '1') then
        s_timer_reg <= std_logic_vector(s_timer2(31 downto 0));
		end if;

	 end if;
  
  end process;


  -- This process registers the Y vector values when the computation is done
  P2: process(i_CLK, i_RST, s_DONE_reg, i_Y0, i_Y1, i_Y2, i_Y3)
  begin

    if (i_RST = '1') then
        s_Y0_reg <= (others => '0');
		s_Y1_reg <= (others => '0');
		s_Y2_reg <= (others => '0');
		s_Y3_reg <= (others => '0');
	 elsif (rising_edge(i_CLK)) then
        if (s_DONE_reg = '1') then
          s_Y0_reg <= i_Y0;
		  s_Y1_reg <= i_Y1;
		  s_Y2_reg <= i_Y2;
		  s_Y3_reg <= i_Y3;
		end if;
	 end if;

  end process;


  -- When we receive the DONE signal, we can write the 5 values to memory and 
  -- then push values into the uart_Controller FIFO
  P3: process(i_CLK, i_RST, s_DONE_reg)
  begin
    if (i_RST = '1') then
      cur_state <= S0;

	   s_ADDRa <= (others => '0');
	   s_ADDRb <= (others => '0');
	   s_WDATAa <= (others => '0');
	   s_WDATAb <= (others => '0');
	   s_WEa <= '0';
	   s_WEb <= '0';

       s_msg_wren <= '0';

	 elsif (rising_edge(i_CLK)) then

      case cur_state is
 
        when S0 =>
		  
			  s_ADDRa <= (others => '0');
		      s_ADDRb <= (others => '0');
		      s_WDATAa <= (others => '0');
		      s_WDATAb <= (others => '0');
		      s_WEa <= '0';
		      s_WEb <= '0';

            s_msg_wren <= '0';			 

            if (s_DONE_reg = '1') then
              cur_state <= S1;
			   else
			     cur_state <= S0;
            end if;				
				
				
        when S1 =>
 
			   cur_state <= S2;
				
				-- Write y[0] to addr 4 and 5 
				s_ADDRa <= "00100";
				s_ADDRb <= "00101";
				s_WDATAa <= s_Y0_reg2(127 downto 64);
				s_WDATAb <= s_Y0_reg2(63 downto 0);
				s_WEa <= '1';
				s_WEb <= '1';
				
				s_msg_wren <= '0';
				

        when S2 =>
		  
            cur_state <= S3;
	
			   -- Write y[1] to addr 8 and 9	
				s_ADDRa <= "01000";
				s_ADDRb <= "01001";
				s_WDATAa <= s_Y1_reg2(127 downto 64);
				s_WDATAb <= s_Y1_reg2(63 downto 0);
				s_WEa <= '1';
				s_WEb <= '1';
				
				s_msg_wren <= '0';


        when S3 =>
		  
            cur_state <= S4;
	
			   -- Write y[2] to addr 12 and 13	
				s_ADDRa <= "01100";
				s_ADDRb <= "01101";
				s_WDATAa <= s_Y2_reg2(127 downto 64);
				s_WDATAb <= s_Y2_reg2(63 downto 0);
				s_WEa <= '1';
				s_WEb <= '1';
				
				s_msg_wren <= '0';

        when S4 =>
		  
            cur_state <= S5;
	
			   -- Write y[3] to addr 16 and 17	
				s_ADDRa <= "10000";
				s_ADDRb <= "10001";
				s_WDATAa <= s_Y3_reg2(127 downto 64);
				s_WDATAb <= s_Y3_reg2(63 downto 0);
				s_WEa <= '1';
				s_WEb <= '1';
				
				s_msg_wren <= '0';

			
        when S5 =>
				
				-- Write the timer to addr 20, and start reading
				s_ADDRa <= "10100";
				s_ADDRb <= "00000";
				s_WDATAa <= s_timer_reg2;
				s_WDATAb <= (others => '0');
				s_WEa <= '1';
				s_WEb <= '0';
				
				s_msg_wren <= '0';
				
				if (s_msg_afull = '0') then
			     cur_state <= S6;
				else
				  cur_state <= S5;
				end if;
				


        when S6 =>
				
				-- Continue reading
				s_ADDRa <= (others => '0');
				s_WDATAa <= (others => '0');
				s_WDATAb <= (others => '0');
				s_WEa <= '0';
				s_WEb <= '0';
				
				if (s_msg_afull = '0') then
				  s_msg_wren <= '1';
			     
				  -- If we're about to do our 22th read, we are done.
				  if (s_ADDRb = "10101") then
				    cur_state <= S0;
				  else
				    cur_state <= S6;
				  end if;
			     s_ADDRb <= std_logic_vector(unsigned(s_ADDRb) + 1);

				else
				  s_msg_wren <= '0';
				  cur_state <= S6;
				end if;
				

 
        when others =>
            cur_state <= S0;
	         
			s_ADDRa <= (others => '0');
		    s_ADDRb <= (others => '0');
		    s_WDATAa <= (others => '0');
		    s_WDATAb <= (others => '0');
		    s_WEa <= '0';
		    s_WEb <= '0';

            s_msg_wren <= '0';			 
			   
      end case;
		
	 end if;

  end process;

  


end mixed;
