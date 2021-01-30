-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- bin_to_ascii.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file the a simple binary to ASCII translator, 
-- operating on vectors of size N (where N must be a multiple of 4).
--
-- NOTES:
-- 12/16/20 by JAZ::Design created.
------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
ENTITY bin_to_ascii IS
	GENERIC (N : INTEGER := 32);
	PORT (
		i_A : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
		o_F : OUT STD_LOGIC_VECTOR(2 * N - 1 DOWNTO 0));
END bin_to_ascii;

ARCHITECTURE dataflow OF bin_to_ascii IS

	-- Needed for VHDL wierdness
	TYPE nibble_array IS ARRAY(0 TO N/4 - 1) OF STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL s_A : nibble_array;

BEGIN

	G1 : FOR i IN 0 TO N/4 - 1 GENERATE

		s_A(i) <= i_A(4 * i + 3 DOWNTO 4 * i);
		WITH s_A(i) SELECT
		o_F(8 * i + 7 DOWNTO 8 * i) <= x"30" WHEN "0000",
		x"31" WHEN "0001",
		x"32" WHEN "0010",
		x"33" WHEN "0011",
		x"34" WHEN "0100",
		x"35" WHEN "0101",
		x"36" WHEN "0110",
		x"37" WHEN "0111",
		x"38" WHEN "1000",
		x"39" WHEN "1001",
		x"61" WHEN "1010",
		x"62" WHEN "1011",
		x"63" WHEN "1100",
		x"64" WHEN "1101",
		x"65" WHEN "1110",
		x"66" WHEN "1111",
		x"7A" WHEN OTHERS;
	END GENERATE;
END dataflow;