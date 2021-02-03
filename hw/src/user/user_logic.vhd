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
USE Work.Common.ALL;
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
			i_ADDRa : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
			i_ADDRb : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
			i_ADDRc : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
			i_ADDRd : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
			i_ADDRe : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
			i_ADDRf : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
			i_ADDRg : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
			i_ADDRh : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
			o_RDATAa : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAc : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAd : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAe : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAf : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAg : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAh : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
	END COMPONENT;

	-- Glue logic signals.
	SIGNAL s_DONE : STD_LOGIC;
	SIGNAL s_CNT : unsigned(128 DOWNTO 0);

	-- Signals to interface with the dmem component
	SIGNAL s_ADDR : addr15_8array;
	SIGNAL s_RDATA : addr32_8array;
	SIGNAL s_vectorsRead : unsigned(11 DOWNTO 0);

	SIGNAL s_Y : std64_4x4array;
	SIGNAL s_Y_TOTAL : uint64_4x4array;

	-- Signals to hold the array values
	SIGNAL s_Amatrix : uint16_4x4array;
	SIGNAL s_XVECT : std64_1x4array;

	-- Finite State Machine signals
	TYPE state_type IS (S0, S1, S2, S3, S4);
	SIGNAL cur_state : state_type;

	COMPONENT Math_4CH
		PORT (
			i_CLK : IN STD_LOGIC;
			i_A : uint16_4x4array;
			i_X : STD_LOGIC_VECTOR(63 DOWNTO 0);

			o_MY0 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
			o_MY1 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
			o_MY2 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
			o_MY3 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
	END COMPONENT;

BEGIN

	-- Set o_DONE as s_DONE
	o_DONE <= s_DONE;
	-- Currently, we are just instantiating a single-port, read-only version
	-- of the dmem. You will want to improve upon this mapping.
	U1 : dmem
	PORT MAP(
		i_CLKa => i_CLK,
		i_CLKb => i_CLK,
		i_ADDRa => s_ADDR(0),
		i_ADDRb => s_ADDR(1),
		i_ADDRc => s_ADDR(2),
		i_ADDRd => s_ADDR(3),
		i_ADDRe => s_ADDR(4),
		i_ADDRf => s_ADDR(5),
		i_ADDRg => s_ADDR(6),
		i_ADDRh => s_ADDR(7),
		o_RDATAa => s_RDATA(0),
		o_RDATAb => s_RDATA(1),
		o_RDATAc => s_RDATA(2),
		o_RDATAd => s_RDATA(3),
		o_RDATAe => s_RDATA(4),
		o_RDATAf => s_RDATA(5),
		o_RDATAg => s_RDATA(6),
		o_RDATAh => s_RDATA(7));

	-- Temporary logic - set the result vector to arbitrary values. 
	-- o_Y0 <= x"1a1a1a1a2b2b2b2b";
	-- o_Y1 <= x"3c3c3c3c4d4d4d4d";
	-- o_Y2 <= x"5e5e5e5e6f6f6f6f";
	-- o_Y3 <= x"7070707081818181";

	-- Temporary process - this creates a simple FSM to load the 16 values of A
	-- by reading from dmem at the appropriate addresses. You may be able to 
	-- resuse / extend this code depending on your design strategy. 
	P2 : PROCESS (i_CLK, i_RST)
	BEGIN
		IF (i_RST = '1') THEN
			cur_state <= S0;
			s_DONE <= '0';
			s_CNT <= (OTHERS => '0');

		ELSIF (rising_edge(i_CLK)) THEN
			IF (s_DONE = '0') THEN
				s_CNT <= s_CNT + 1;
			END IF;

			CASE cur_state IS
					-- When we've reset, we can initialize the s_ADDRa signal
				WHEN S0 =>
					s_ADDR(0) <= "000000000000000";
					s_ADDR(1) <= "000000000000001";
					s_ADDR(2) <= "000000000000010";
					s_ADDR(3) <= "000000000000011";
					s_ADDR(4) <= "000000000000100";
					s_ADDR(5) <= "000000000000101";
					s_ADDR(6) <= "000000000000110";
					s_ADDR(7) <= "000000000000111";
					cur_state <= S1;
					s_vectorsRead <= x"000";

					-- The prev s_ADDRa takes a cycle to be latched by the BRAM, so 
					-- we wait a cycle to start our reading.
				WHEN S1 =>
					-- This is the recommended mechanism for doing math operations on 
					-- std_logic_vectors. 		  
					s_ADDR(0) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(0)) + 8);
					s_ADDR(1) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(1)) + 8);
					s_ADDR(2) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(2)) + 8);
					s_ADDR(3) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(3)) + 8);
					s_ADDR(4) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(4)) + 8);
					s_ADDR(5) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(5)) + 8);
					s_ADDR(6) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(6)) + 8);
					s_ADDR(7) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(7)) + 8);
					cur_state <= S2;

					-- We are grabbing two unit16's per 32-bit BRAM read
				WHEN S2 =>
					s_Amatrix(0)(0) <= unsigned(s_RDATA(0)(31 DOWNTO 16));
					s_Amatrix(0)(1) <= unsigned(s_RDATA(0)(15 DOWNTO 0));
					s_Amatrix(0)(2) <= unsigned(s_RDATA(1)(31 DOWNTO 16));
					s_Amatrix(0)(3) <= unsigned(s_RDATA(1)(15 DOWNTO 0));
					s_Amatrix(1)(0) <= unsigned(s_RDATA(2)(31 DOWNTO 16));
					s_Amatrix(1)(1) <= unsigned(s_RDATA(2)(15 DOWNTO 0));
					s_Amatrix(1)(2) <= unsigned(s_RDATA(3)(31 DOWNTO 16));
					s_Amatrix(1)(3) <= unsigned(s_RDATA(3)(15 DOWNTO 0));
					s_Amatrix(2)(0) <= unsigned(s_RDATA(4)(31 DOWNTO 16));
					s_Amatrix(2)(1) <= unsigned(s_RDATA(4)(15 DOWNTO 0));
					s_Amatrix(2)(2) <= unsigned(s_RDATA(5)(31 DOWNTO 16));
					s_Amatrix(2)(3) <= unsigned(s_RDATA(5)(15 DOWNTO 0));
					s_Amatrix(3)(0) <= unsigned(s_RDATA(6)(31 DOWNTO 16));
					s_Amatrix(3)(1) <= unsigned(s_RDATA(6)(15 DOWNTO 0));
					s_Amatrix(3)(2) <= unsigned(s_RDATA(7)(31 DOWNTO 16));
					s_Amatrix(3)(3) <= unsigned(s_RDATA(7)(15 DOWNTO 0));

					s_ADDR(0) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(0)) + 8);
					s_ADDR(1) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(1)) + 8);
					s_ADDR(2) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(2)) + 8);
					s_ADDR(3) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(3)) + 8);
					s_ADDR(4) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(4)) + 8);
					s_ADDR(5) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(5)) + 8);
					s_ADDR(6) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(6)) + 8);
					s_ADDR(7) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(7)) + 8);

					cur_state <= S3;

				WHEN S3 =>
					s_XVECT(0)(63 DOWNTO 48) <= s_RDATA(0)(31 DOWNTO 16);
					s_XVECT(0)(47 DOWNTO 32) <= s_RDATA(0)(15 DOWNTO 0);
					s_XVECT(0)(31 DOWNTO 16) <= s_RDATA(1)(31 DOWNTO 16);
					s_XVECT(0)(15 DOWNTO 0)  <= s_RDATA(1)(15 DOWNTO 0);

					s_XVECT(1)(63 DOWNTO 48) <= s_RDATA(2)(31 DOWNTO 16);
					s_XVECT(1)(47 DOWNTO 32) <= s_RDATA(2)(15 DOWNTO 0);
					s_XVECT(1)(31 DOWNTO 16) <= s_RDATA(3)(31 DOWNTO 16);
					s_XVECT(1)(15 DOWNTO 0)  <= s_RDATA(3)(15 DOWNTO 0);

					s_XVECT(2)(63 DOWNTO 48) <= s_RDATA(4)(31 DOWNTO 16);
					s_XVECT(2)(47 DOWNTO 32) <= s_RDATA(4)(15 DOWNTO 0);
					s_XVECT(2)(31 DOWNTO 16) <= s_RDATA(5)(31 DOWNTO 16);
					s_XVECT(2)(15 DOWNTO 0)  <= s_RDATA(5)(15 DOWNTO 0);

					s_XVECT(3)(63 DOWNTO 48) <= s_RDATA(6)(31 DOWNTO 16);
					s_XVECT(3)(47 DOWNTO 32) <= s_RDATA(6)(15 DOWNTO 0);
					s_XVECT(3)(31 DOWNTO 16) <= s_RDATA(7)(31 DOWNTO 16);
					s_XVECT(3)(15 DOWNTO 0)  <= s_RDATA(7)(15 DOWNTO 0);

					s_ADDR(0) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(0)) + 8);
					s_ADDR(1) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(1)) + 8);
					s_ADDR(2) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(2)) + 8);
					s_ADDR(3) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(3)) + 8);
					s_ADDR(4) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(4)) + 8);
					s_ADDR(5) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(5)) + 8);
					s_ADDR(6) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(6)) + 8);
					s_ADDR(7) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(7)) + 8);

					s_Y_TOTAL(0)(0) <= s_Y_TOTAL(0)(0) + unsigned(s_Y(0)(0));
					s_Y_TOTAL(0)(1) <= s_Y_TOTAL(0)(1) + unsigned(s_Y(0)(1));
					s_Y_TOTAL(0)(2) <= s_Y_TOTAL(0)(2) + unsigned(s_Y(0)(2));
					s_Y_TOTAL(0)(3) <= s_Y_TOTAL(0)(3) + unsigned(s_Y(0)(3));
					s_Y_TOTAL(1)(0) <= s_Y_TOTAL(1)(0) + unsigned(s_Y(1)(0));
					s_Y_TOTAL(1)(1) <= s_Y_TOTAL(1)(1) + unsigned(s_Y(1)(1));
					s_Y_TOTAL(1)(2) <= s_Y_TOTAL(1)(2) + unsigned(s_Y(1)(2));
					s_Y_TOTAL(1)(3) <= s_Y_TOTAL(1)(3) + unsigned(s_Y(1)(3));
					s_Y_TOTAL(2)(0) <= s_Y_TOTAL(2)(0) + unsigned(s_Y(2)(0));
					s_Y_TOTAL(2)(1) <= s_Y_TOTAL(2)(1) + unsigned(s_Y(2)(1));
					s_Y_TOTAL(2)(2) <= s_Y_TOTAL(2)(2) + unsigned(s_Y(2)(2));
					s_Y_TOTAL(2)(3) <= s_Y_TOTAL(2)(3) + unsigned(s_Y(2)(3));
					s_Y_TOTAL(3)(0) <= s_Y_TOTAL(3)(0) + unsigned(s_Y(3)(0));
					s_Y_TOTAL(3)(1) <= s_Y_TOTAL(3)(1) + unsigned(s_Y(3)(1));
					s_Y_TOTAL(3)(2) <= s_Y_TOTAL(3)(2) + unsigned(s_Y(3)(2));
					s_Y_TOTAL(3)(3) <= s_Y_TOTAL(3)(3) + unsigned(s_Y(3)(3));
					
					IF (s_vectorsRead = x"3E8") THEN
						cur_state <= S4;
					ELSE
						s_vectorsRead <= s_vectorsRead + x"004";
					END IF;

				WHEN S4 =>
					o_Y0 <= STD_LOGIC_VECTOR(s_Y_TOTAL(0)(0) + s_Y_TOTAL(0)(1) + s_Y_TOTAL(0)(2) + s_Y_TOTAL(0)(3));
					o_Y1 <= STD_LOGIC_VECTOR(s_Y_TOTAL(1)(0) + s_Y_TOTAL(1)(1) + s_Y_TOTAL(1)(2) + s_Y_TOTAL(1)(3));
					o_Y2 <= STD_LOGIC_VECTOR(s_Y_TOTAL(2)(0) + s_Y_TOTAL(2)(1) + s_Y_TOTAL(2)(2) + s_Y_TOTAL(2)(3));
					o_Y3 <= STD_LOGIC_VECTOR(s_Y_TOTAL(3)(0) + s_Y_TOTAL(3)(1) + s_Y_TOTAL(3)(2) + s_Y_TOTAL(3)(3));
					s_DONE <= '1';

				WHEN OTHERS =>
					cur_state <= S0;
					s_ADDR(0) <= (OTHERS => '0');
					s_ADDR(1) <= (OTHERS => '0');
					s_ADDR(2) <= (OTHERS => '0');
					s_ADDR(3) <= (OTHERS => '0');
					s_ADDR(4) <= (OTHERS => '0');
					s_ADDR(5) <= (OTHERS => '0');
					s_ADDR(6) <= (OTHERS => '0');
					s_ADDR(7) <= (OTHERS => '0');

			END CASE;
		END IF;
	END PROCESS;

	Math_4CHa : Math_4CH
	PORT MAP(
		i_CLK => i_CLK,
		i_A => s_Amatrix,
		i_X => s_XVECT(0),

		o_MY0 => s_Y(0)(0),
		o_MY1 => s_Y(0)(1),
		o_MY2 => s_Y(0)(2),
		o_MY3 => s_Y(0)(3));

	Math_4CHb : Math_4CH
	PORT MAP(
		i_CLK => i_CLK,
		i_A => s_Amatrix,
		i_X => s_XVECT(1),

		o_MY0 => s_Y(1)(0),
		o_MY1 => s_Y(1)(1),
		o_MY2 => s_Y(1)(2),
		o_MY3 => s_Y(1)(3));

	Math_4CHc : Math_4CH
	PORT MAP(
		i_CLK => i_CLK,
		i_A => s_Amatrix,
		i_X => s_XVECT(2),

		o_MY0 => s_Y(2)(0),
		o_MY1 => s_Y(2)(1),
		o_MY2 => s_Y(2)(2),
		o_MY3 => s_Y(2)(3));

	Math_4CHd : Math_4CH
	PORT MAP(
		i_CLK => i_CLK,
		i_A => s_Amatrix,
		i_X => s_XVECT(3),

		o_MY0 => s_Y(3)(0),
		o_MY1 => s_Y(3)(1),
		o_MY2 => s_Y(3)(2),
		o_MY3 => s_Y(3)(3));

END mixed;