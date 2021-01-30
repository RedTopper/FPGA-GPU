-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- user_logic.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains the user logic that reads values from 
-- data memory and calculates a matrix-vector multiply-accumulate 
-- operation. Make most of your changes in this file. 
--
-- NOTES:
-- 12/16/20 by JAZ::Design created.
------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
ENTITY user_logic IS

  PORT (
    i_CLK : IN STD_LOGIC;
    i_RST : IN STD_LOGIC;
    o_DONE : OUT STD_LOGIC;

    o_Y0 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    o_Y1 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    o_Y2 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    o_Y3 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));

END user_logic;
ARCHITECTURE mixed OF user_logic IS

  -- component declarations
  COMPONENT dmem
    PORT (
      i_CLKa, i_CLKb : IN STD_LOGIC;
      i_ENa, i_ENb, i_ENc, i_ENd, i_ENe, i_ENf, i_ENg, i_ENh : IN STD_LOGIC;
      i_WEa, i_WEb : IN STD_LOGIC;
      i_ADDRa : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
      i_ADDRb : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
      i_ADDRc : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
      i_ADDRd : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
      i_ADDRe : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
      i_ADDRf : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
      i_ADDRg : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
      i_ADDRh : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
      i_WDATAa : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      i_WDATAb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      o_RDATAa : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      o_RDATAb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      o_RDATAc : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      o_RDATAd : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      o_RDATAe : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      o_RDATAf : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      o_RDATAg : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      o_RDATAh : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      );
  END COMPONENT;

  -- Glue logic signals.
  SIGNAL s_DONE : STD_LOGIC;
  SIGNAL s_CNT : unsigned(128 DOWNTO 0);

  -- Signals to interface with the dmem component
  SIGNAL s_ADDRa : STD_LOGIC_VECTOR(14 DOWNTO 0);
  SIGNAL s_RDATAa : STD_LOGIC_VECTOR(31 DOWNTO 0);

  -- Signals to hold the array values
  TYPE uint16_1x4array IS ARRAY(0 TO 3) OF unsigned(15 DOWNTO 0);
  TYPE uint16_4x4array IS ARRAY(0 TO 3) OF uint16_1x4array;
  SIGNAL s_Amatrix : uint16_4x4array;

  -- Finite State Machine signals
  TYPE state_type IS (S0, S1, S2, S3, S4);
  SIGNAL cur_state : state_type;
  SIGNAL count_i, count_j : NATURAL RANGE 0 TO 4;

BEGIN

  -- Set o_DONE as s_DONE
  o_DONE <= s_DONE;
  -- Currently, we are just instantiating a single-port, read-only version
  -- of the dmem. You will want to improve upon this mapping.
  U1 : dmem
  PORT MAP(
    i_CLKa => i_CLK,
    i_CLKb => i_CLK,
    i_ENa => '1',
    i_ENb => '1',
    i_ENc => '1',
    i_ENd => '1',
    i_ENe => '1',
    i_ENf => '1',
    i_ENg => '1',
    i_ENh => '1',
    i_WEa => '0',
    i_WEb => '0',
    i_ADDRa => s_ADDRa,
    i_ADDRb => (OTHERS => '0'),
    i_ADDRc => (OTHERS => '0'),
    i_ADDRd => (OTHERS => '0'),
    i_ADDRe => (OTHERS => '0'),
    i_ADDRf => (OTHERS => '0'),
    i_ADDRg => (OTHERS => '0'),
    i_ADDRh => (OTHERS => '0'),
    i_WDATAa => (OTHERS => '0'),
    i_WDATAb => (OTHERS => '0'),
    o_RDATAa => s_RDATAa,
    o_RDATAb => OPEN);
  -- Temporary logic - set the result vector to arbitrary values. 
  o_Y0 <= x"1a1a1a1a2b2b2b2b";
  o_Y1 <= x"3c3c3c3c4d4d4d4d";
  o_Y2 <= x"5e5e5e5e6f6f6f6f";
  o_Y3 <= x"7070707081818181";
  -- Temporary process - this waits for 200001 clock cycles and then sets 
  -- s_DONE. You will need to replace this with your own s_DONE calculation
  -- logic
  P1 : PROCESS (i_CLK, i_RST)
  BEGIN
    IF (i_RST = '1') THEN
      s_DONE <= '0';
      s_CNT <= (OTHERS => '0');
    ELSIF (rising_edge(i_CLK)) THEN
      s_CNT <= s_CNT + 1;
      IF (s_CNT = 200000) THEN
        s_DONE <= '1';
      ELSE
        s_DONE <= '0';
      END IF;
    END IF;
  END PROCESS;
  -- Temporary process - this creates a simple FSM to load the 16 values of A
  -- by reading from dmem at the appropriate addresses. You may be able to 
  -- resuse / extend this code depending on your design strategy. 
  P2 : PROCESS (i_CLK, i_RST)
  BEGIN
    IF (i_RST = '1') THEN
      cur_state <= S0;
      s_ADDRa <= (OTHERS => '0');
      count_i <= 0;
      count_j <= 0;

    ELSIF (rising_edge(i_CLK)) THEN

      CASE cur_state IS
          -- When we've reset, we can initialize the s_ADDRa signal
        WHEN S0 =>
          s_ADDRa <= (OTHERS => '0');
          count_i <= 0;
          count_j <= 0;
          cur_state <= S1;

          -- The prev s_ADDRa takes a cycle to be latched by the BRAM, so 
          -- we wait a cycle to start our reading.
        WHEN S1 =>
          -- This is the recommended mechanism for doing math operations on 
          -- std_logic_vectors. 		  
          s_ADDRa <= STD_LOGIC_VECTOR(unsigned(s_ADDRa) + 1);
          cur_state <= S2;

          -- We are grabbing two unit16's per 32-bit BRAM read
        WHEN S2 =>
          s_Amatrix(count_i)(count_j) <= unsigned(s_RDATAa(31 DOWNTO 16));
          s_Amatrix(count_i)(count_j + 1) <= unsigned(s_RDATAa(15 DOWNTO 0));
          IF (count_j = 2) THEN
            count_j <= 0;
            IF (count_i = 3) THEN
              count_i <= 0;
              cur_state <= S3;
            ELSE
              count_i <= count_i + 1;
            END IF;
          ELSE
            count_j <= count_j + 2;
          END IF;

          s_ADDRa <= STD_LOGIC_VECTOR(unsigned(s_ADDRa) + 1);

        WHEN S3 =>
        WHEN OTHERS =>
          cur_state <= S0;
          s_ADDRa <= (OTHERS => '0');

      END CASE;

    END IF;

  END PROCESS;

END mixed;