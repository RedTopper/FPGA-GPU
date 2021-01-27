-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- mvmac.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains the top level design for the matrix-
-- vector multiply-accumulate design. Your main code can go here and in
-- user_logic.vhd
--
-- NOTES:
-- 12/16/20 by JAZ::Design created.
------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity mvmac is
  port(clk100     : in std_logic;
       sys_rst_n  : in std_logic;
       LED0       : out std_logic;
	   UART_RxD   : in std_logic;
	   UART_TxD   : out std_logic);
end mvmac;

architecture mixed of mvmac is

  -- component declarations
  component fixed_logic
    port(i_CLK    : in std_logic;
         i_RST    : in std_logic;
         i_DONE   : in std_logic;
         i_Y0     : in std_logic_vector(63 downto 0);
		 i_Y1     : in std_logic_vector(63 downto 0);
		 i_Y2     : in std_logic_vector(63 downto 0);
		 i_Y3     : in std_logic_vector(63 downto 0);		
		 RxD      : in std_logic;
		 TxD      : out std_logic);
  end component;

  component user_logic
    port(i_CLK    : in std_logic;
         i_RST    : in std_logic;
         o_DONE   : out std_logic;
         o_Y0     : out std_logic_vector(63 downto 0);
		 o_Y1     : out std_logic_vector(63 downto 0);
		 o_Y2     : out std_logic_vector(63 downto 0);
		 o_Y3     : out std_logic_vector(63 downto 0));
  end component;


  -- Signals for connection wires
  signal s_RST, s_DONE : std_logic;

  -- For the result vector. Currently s_Yx is stored to s_Yx_reg
  -- every cycle, which does not necessarily need to be changed.
  signal s_Y0, s_Y1, s_Y2, s_Y3 : std_logic_vector(63 downto 0);
  signal s_Y0_reg, s_Y1_reg : std_logic_vector(63 downto 0);
  signal s_Y2_reg, s_Y3_reg : std_logic_vector(63 downto 0);


begin

  -- Invert the button signal for an active high reset
  s_RST <= not sys_rst_n;

  -- Let's light up an LED when we are done
  LED0 <= s_DONE;


  -- User logic component - you may want to change this mapping to use
  -- a faster clock (if possible)
  U1: user_logic
    port map(i_CLK   => clk100,
             i_RST   => s_RST,
             o_DONE  => s_DONE,
		     o_Y0    => s_Y0,
             o_Y1    => s_Y1,	
             o_Y2    => s_Y2,
             o_Y3    => s_Y3);			 


  -- Fixed logic component - don't change this port mapping
  U2: fixed_logic
    port map(i_CLK   => clk100,
             i_RST   => s_RST,
             i_DONE  => s_DONE,
             i_Y0    => s_Y0_reg,
             i_Y1    => s_Y1_reg,
             i_Y2    => s_Y2_reg,
             i_Y3    => s_Y3_reg,
				 RxD     => UART_RxD,
				 TxD     => UART_TxD);


  -- This process implements the Y vector result registers. 
  P1: process(clk100, s_RST)
  begin
    if (s_RST = '1') then
      s_Y0_reg <= (others => '0');
      s_Y1_reg <= (others => '0');
      s_Y2_reg <= (others => '0');
      s_Y3_reg <= (others => '0');
	 elsif (rising_edge(clk100)) then
      s_Y0_reg <= s_Y0;
      s_Y1_reg <= s_Y1;
      s_Y2_reg <= s_Y2;
      s_Y3_reg <= s_Y3;
	 end if;
  end process;


end mixed;
