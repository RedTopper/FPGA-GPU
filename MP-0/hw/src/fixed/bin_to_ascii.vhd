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


library IEEE;
use IEEE.std_logic_1164.all;


entity bin_to_ascii is
  generic(N     : integer := 32);
  port(i_A      : in std_logic_vector(N-1 downto 0);
       o_F      : out std_logic_vector(2*N-1 downto 0));
end bin_to_ascii;

architecture dataflow of bin_to_ascii is

  -- Needed for VHDL wierdness
  type nibble_array is array(0 to N/4-1) of std_logic_vector(3 downto 0);
  signal s_A : nibble_array;

begin

  G1: for i in 0 to N/4-1 generate

    s_A(i) <= i_A(4*i+3 downto 4*i);
    with s_A(i) select
	   o_F(8*i+7 downto 8*i) <= x"30" when "0000",
		                  x"31" when "0001",
		                  x"32" when "0010",								
		                  x"33" when "0011",
		                  x"34" when "0100",								
		                  x"35" when "0101",
		                  x"36" when "0110",								
		                  x"37" when "0111",
		                  x"38" when "1000",								
		                  x"39" when "1001",
		                  x"61" when "1010",								
		                  x"62" when "1011",
		                  x"63" when "1100",								
		                  x"64" when "1101",								
		                  x"65" when "1110",								
		                  x"66" when "1111",
								x"7A" when others;


  end generate;


end dataflow;
