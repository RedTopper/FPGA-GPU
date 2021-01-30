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
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
ENTITY mvmac IS
  PORT (
    clk100 : IN STD_LOGIC;
    sys_rst_n : IN STD_LOGIC;
    LED0 : OUT STD_LOGIC;
    UART_RxD : IN STD_LOGIC;
    UART_TxD : OUT STD_LOGIC);
END mvmac;

ARCHITECTURE mixed OF mvmac IS

  -- component declarations
  COMPONENT fixed_logic
    PORT (
      i_CLK : IN STD_LOGIC;
      i_RST : IN STD_LOGIC;
      i_DONE : IN STD_LOGIC;
      i_Y0 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      i_Y1 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      i_Y2 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      i_Y3 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      RxD : IN STD_LOGIC;
      TxD : OUT STD_LOGIC);
  END COMPONENT;

  COMPONENT user_logic
    PORT (
      i_CLK : IN STD_LOGIC;
      i_RST : IN STD_LOGIC;
      o_DONE : OUT STD_LOGIC;
      o_Y0 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      o_Y1 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      o_Y2 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      o_Y3 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
  END COMPONENT;
  -- Signals for connection wires
  SIGNAL s_RST, s_DONE : STD_LOGIC;

  -- For the result vector. Currently s_Yx is stored to s_Yx_reg
  -- every cycle, which does not necessarily need to be changed.
  SIGNAL s_Y0, s_Y1, s_Y2, s_Y3 : STD_LOGIC_VECTOR(63 DOWNTO 0);
  SIGNAL s_Y0_reg, s_Y1_reg : STD_LOGIC_VECTOR(63 DOWNTO 0);
  SIGNAL s_Y2_reg, s_Y3_reg : STD_LOGIC_VECTOR(63 DOWNTO 0);
BEGIN

  -- Invert the button signal for an active high reset
  s_RST <= NOT sys_rst_n;

  -- Let's light up an LED when we are done
  LED0 <= s_DONE;
  -- User logic component - you may want to change this mapping to use
  -- a faster clock (if possible)
  U1 : user_logic
  PORT MAP(
    i_CLK => clk100,
    i_RST => s_RST,
    o_DONE => s_DONE,
    o_Y0 => s_Y0,
    o_Y1 => s_Y1,
    o_Y2 => s_Y2,
    o_Y3 => s_Y3);
  -- Fixed logic component - don't change this port mapping
  U2 : fixed_logic
  PORT MAP(
    i_CLK => clk100,
    i_RST => s_RST,
    i_DONE => s_DONE,
    i_Y0 => s_Y0_reg,
    i_Y1 => s_Y1_reg,
    i_Y2 => s_Y2_reg,
    i_Y3 => s_Y3_reg,
    RxD => UART_RxD,
    TxD => UART_TxD);
  -- This process implements the Y vector result registers. 
  P1 : PROCESS (clk100, s_RST)
  BEGIN
    IF (s_RST = '1') THEN
      s_Y0_reg <= (OTHERS => '0');
      s_Y1_reg <= (OTHERS => '0');
      s_Y2_reg <= (OTHERS => '0');
      s_Y3_reg <= (OTHERS => '0');
    ELSIF (rising_edge(clk100)) THEN
      s_Y0_reg <= s_Y0;
      s_Y1_reg <= s_Y1;
      s_Y2_reg <= s_Y2;
      s_Y3_reg <= s_Y3;
    END IF;
  END PROCESS;
END mixed;