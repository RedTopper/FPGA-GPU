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
			o_RDATAh : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
	END COMPONENT;

	-- Glue logic signals.
	SIGNAL s_DONE : STD_LOGIC;
	SIGNAL s_CNT : unsigned(128 DOWNTO 0);

	-- Signals to interface with the dmem component
	SIGNAL s_ADDRa, s_ADDRb, s_ADDRc, s_ADDRd, s_ADDRe, s_ADDRf, s_ADDRg, s_ADDRh : STD_LOGIC_VECTOR(14 DOWNTO 0);
	SIGNAL s_RDATAa, s_RDATAb, s_RDATAc, s_RDATAd, s_RDATAe, s_RDATAf, s_RDATAg, s_RDATAh : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL s_vectorsRead : unsigned(11 DOWNTO 0);

	SIGNAL s_Y0a, s_Y0b, s_Y0c, s_Y0d : STD_LOGIC_VECTOR(63 DOWNTO 0);
	SIGNAL s_Y1a, s_Y1b, s_Y1c, s_Y1d : STD_LOGIC_VECTOR(63 DOWNTO 0);
	SIGNAL s_Y2a, s_Y2b, s_Y2c, s_Y2d : STD_LOGIC_VECTOR(63 DOWNTO 0);
	SIGNAL s_Y3a, s_Y3b, s_Y3c, s_Y3d : STD_LOGIC_VECTOR(63 DOWNTO 0);

	SIGNAL s_Y0_Summing, s_Y1_Summing, s_Y2_Summing, s_Y3_Summing : STD_LOGIC_VECTOR(63 DOWNTO 0);
	SIGNAL s_Y0_SUM_TOTAL, s_Y1_SUM_TOTAL, s_Y2_SUM_TOTAL, s_Y3_SUM_TOTAL : unsigned(128 DOWNTO 0);

	-- Signals to hold the array values
	SIGNAL s_Amatrix : uint16_4x4array;
	SIGNAL s_XVECTa, s_XVECTb, s_XVECTc, s_XVECTd : STD_LOGIC_VECTOR(63 DOWNTO 0);

	-- Finite State Machine signals
	TYPE state_type IS (S0, S1, S2, S3, S4);
	SIGNAL cur_state : state_type;

	COMPONENT Math_4CH
		PORT (
			i_CLK : IN STD_LOGIC;
			i_A : uint16_4x4array;
			i_X : STD_LOGIC_VECTOR(63 DOWNTO 0);

			o_Y0 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
			o_Y1 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
			o_Y2 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
			o_Y3 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
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
		i_ADDRb => s_ADDRb,
		i_ADDRc => s_ADDRc,
		i_ADDRd => s_ADDRd,
		i_ADDRe => s_ADDRe,
		i_ADDRf => s_ADDRf,
		i_ADDRg => s_ADDRg,
		i_ADDRh => s_ADDRh,
		i_WDATAa => (OTHERS => '0'),
		i_WDATAb => (OTHERS => '0'),
		o_RDATAa => s_RDATAa,
		o_RDATAb => s_RDATAb,
		o_RDATAc => s_RDATAc,
		o_RDATAd => s_RDATAd,
		o_RDATAe => s_RDATAe,
		o_RDATAf => s_RDATAf,
		o_RDATAg => s_RDATAg,
		o_RDATAh => s_RDATAh);

	-- Temporary logic - set the result vector to arbitrary values. 
	-- o_Y0 <= x"1a1a1a1a2b2b2b2b";
	-- o_Y1 <= x"3c3c3c3c4d4d4d4d";
	-- o_Y2 <= x"5e5e5e5e6f6f6f6f";
	-- o_Y3 <= x"7070707081818181";

	-- Temporary process - this waits for 200001 clock cycles and then sets 
	-- s_DONE. You will need to replace this with your own s_DONE calculation
	-- logic
	P1 : PROCESS (i_CLK, i_RST)
	BEGIN
		IF (i_RST = '1') THEN
			s_DONE <= '0';
			s_CNT <= (OTHERS => '0');
		ELSIF (rising_edge(i_CLK)) THEN
			IF (s_DONE = '0') THEN
				s_CNT <= s_CNT + 1;
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

		ELSIF (rising_edge(i_CLK)) THEN

			CASE cur_state IS
					-- When we've reset, we can initialize the s_ADDRa signal
				WHEN S0 =>
					s_ADDRa <= (OTHERS => '0');
					s_ADDRa <= "000000000000000";
					s_ADDRb <= "000000000000001";
					s_ADDRc <= "000000000000010";
					s_ADDRd <= "000000000000011";
					s_ADDRe <= "000000000000100";
					s_ADDRf <= "000000000000101";
					s_ADDRg <= "000000000000110";
					s_ADDRh <= "000000000000111";
					cur_state <= S1;
					s_vectorsRead <= x"000";

					-- The prev s_ADDRa takes a cycle to be latched by the BRAM, so 
					-- we wait a cycle to start our reading.
				WHEN S1 =>
					-- This is the recommended mechanism for doing math operations on 
					-- std_logic_vectors. 		  
					s_ADDRa <= STD_LOGIC_VECTOR(unsigned(s_ADDRa) + 8);
					s_ADDRb <= STD_LOGIC_VECTOR(unsigned(s_ADDRb) + 8);
					s_ADDRc <= STD_LOGIC_VECTOR(unsigned(s_ADDRc) + 8);
					s_ADDRd <= STD_LOGIC_VECTOR(unsigned(s_ADDRd) + 8);
					s_ADDRe <= STD_LOGIC_VECTOR(unsigned(s_ADDRe) + 8);
					s_ADDRf <= STD_LOGIC_VECTOR(unsigned(s_ADDRf) + 8);
					s_ADDRg <= STD_LOGIC_VECTOR(unsigned(s_ADDRg) + 8);
					s_ADDRh <= STD_LOGIC_VECTOR(unsigned(s_ADDRh) + 8);
					cur_state <= S2;

					-- We are grabbing two unit16's per 32-bit BRAM read
				WHEN S2 =>
					s_Amatrix(0)(0) <= unsigned(s_RDATAa(31 DOWNTO 16));
					s_Amatrix(0)(1) <= unsigned(s_RDATAa(15 DOWNTO 0));
					s_Amatrix(0)(2) <= unsigned(s_RDATAb(31 DOWNTO 16));
					s_Amatrix(0)(3) <= unsigned(s_RDATAb(15 DOWNTO 0));
					s_Amatrix(1)(0) <= unsigned(s_RDATAc(31 DOWNTO 16));
					s_Amatrix(1)(1) <= unsigned(s_RDATAc(15 DOWNTO 0));
					s_Amatrix(1)(2) <= unsigned(s_RDATAd(31 DOWNTO 16));
					s_Amatrix(1)(3) <= unsigned(s_RDATAd(15 DOWNTO 0));
					s_Amatrix(2)(0) <= unsigned(s_RDATAe(31 DOWNTO 16));
					s_Amatrix(2)(1) <= unsigned(s_RDATAe(15 DOWNTO 0));
					s_Amatrix(2)(2) <= unsigned(s_RDATAf(31 DOWNTO 16));
					s_Amatrix(2)(3) <= unsigned(s_RDATAf(15 DOWNTO 0));
					s_Amatrix(3)(0) <= unsigned(s_RDATAg(31 DOWNTO 16));
					s_Amatrix(3)(1) <= unsigned(s_RDATAg(15 DOWNTO 0));
					s_Amatrix(3)(2) <= unsigned(s_RDATAh(31 DOWNTO 16));
					s_Amatrix(3)(3) <= unsigned(s_RDATAh(15 DOWNTO 0));

					s_ADDRa <= STD_LOGIC_VECTOR(unsigned(s_ADDRa) + 8);
					s_ADDRb <= STD_LOGIC_VECTOR(unsigned(s_ADDRb) + 8);
					s_ADDRc <= STD_LOGIC_VECTOR(unsigned(s_ADDRc) + 8);
					s_ADDRd <= STD_LOGIC_VECTOR(unsigned(s_ADDRd) + 8);
					s_ADDRe <= STD_LOGIC_VECTOR(unsigned(s_ADDRe) + 8);
					s_ADDRf <= STD_LOGIC_VECTOR(unsigned(s_ADDRf) + 8);
					s_ADDRg <= STD_LOGIC_VECTOR(unsigned(s_ADDRg) + 8);
					s_ADDRh <= STD_LOGIC_VECTOR(unsigned(s_ADDRh) + 8);

					cur_state <= S3;

				WHEN S3 =>
					s_XVECTa(63 DOWNTO 48) <= s_RDATAa(31 DOWNTO 16);
					s_XVECTa(47 DOWNTO 32) <= s_RDATAa(15 DOWNTO 0);
					s_XVECTa(31 DOWNTO 16) <= s_RDATAb(31 DOWNTO 16);
					s_XVECTa(15 DOWNTO 0) <= s_RDATAb(15 DOWNTO 0);

					s_XVECTb(63 DOWNTO 48) <= s_RDATAc(31 DOWNTO 16);
					s_XVECTb(47 DOWNTO 32) <= s_RDATAc(15 DOWNTO 0);
					s_XVECTb(31 DOWNTO 16) <= s_RDATAd(31 DOWNTO 16);
					s_XVECTb(15 DOWNTO 0) <= s_RDATAd(15 DOWNTO 0);

					s_XVECTc(63 DOWNTO 48) <= s_RDATAe(31 DOWNTO 16);
					s_XVECTc(47 DOWNTO 32) <= s_RDATAe(15 DOWNTO 0);
					s_XVECTc(31 DOWNTO 16) <= s_RDATAf(31 DOWNTO 16);
					s_XVECTc(15 DOWNTO 0) <= s_RDATAf(15 DOWNTO 0);

					s_XVECTd(63 DOWNTO 48) <= s_RDATAg(31 DOWNTO 16);
					s_XVECTd(47 DOWNTO 32) <= s_RDATAg(15 DOWNTO 0);
					s_XVECTd(31 DOWNTO 16) <= s_RDATAh(31 DOWNTO 16);
					s_XVECTd(15 DOWNTO 0) <= s_RDATAh(15 DOWNTO 0);

					s_ADDRa <= STD_LOGIC_VECTOR(unsigned(s_ADDRa) + 8);
					s_ADDRb <= STD_LOGIC_VECTOR(unsigned(s_ADDRb) + 8);
					s_ADDRc <= STD_LOGIC_VECTOR(unsigned(s_ADDRc) + 8);
					s_ADDRd <= STD_LOGIC_VECTOR(unsigned(s_ADDRd) + 8);
					s_ADDRe <= STD_LOGIC_VECTOR(unsigned(s_ADDRe) + 8);
					s_ADDRf <= STD_LOGIC_VECTOR(unsigned(s_ADDRf) + 8);
					s_ADDRg <= STD_LOGIC_VECTOR(unsigned(s_ADDRg) + 8);
					s_ADDRh <= STD_LOGIC_VECTOR(unsigned(s_ADDRh) + 8);

					cur_state <= S4;

					s_Y0_SUM_TOTAL <= s_Y0_SUM_TOTAL + unsigned(s_Y0_Summing);
					s_Y1_SUM_TOTAL <= s_Y1_SUM_TOTAL + unsigned(s_Y1_Summing);
					s_Y2_SUM_TOTAL <= s_Y2_SUM_TOTAL + unsigned(s_Y2_Summing);
					s_Y3_SUM_TOTAL <= s_Y3_SUM_TOTAL + unsigned(s_Y3_Summing);

					IF (s_vectorsRead = x"3E8") THEN
						cur_state <= S4;
					ELSE
						s_vectorsRead <= s_vectorsRead + x"004";
					END IF;

				WHEN S4 =>
					s_DONE <= '1';

				WHEN OTHERS =>
					cur_state <= S0;
					s_ADDRa <= (OTHERS => '0');

			END CASE;
		END IF;
	END PROCESS;

	Math_4CHa : Math_4CH
	PORT MAP(
	i_CLK => i_CLK,
	i_A => s_Amatrix,
	i_X => s_XVECTa,

	o_Y0 =>	s_Y0a,
	o_Y1 =>	s_Y1a,
	o_Y2 => s_Y2a,
	o_Y3 => s_Y3a);

	Math_4CHb : Math_4CH
	PORT MAP(
	i_CLK => i_CLK,
	i_A => s_Amatrix,
	i_X => s_XVECTb,

	o_Y0 =>	s_Y0b,
	o_Y1 =>	s_Y1b,
	o_Y2 => s_Y2b,
	o_Y3 => s_Y3b);

	Math_4CHc : Math_4CH
	PORT MAP(
	i_CLK => i_CLK,
	i_A => s_Amatrix,
	i_X => s_XVECTc,

	o_Y0 =>	s_Y0c,
	o_Y1 =>	s_Y1c,
	o_Y2 => s_Y2c,
	o_Y3 => s_Y3c);

	Math_4CHd : Math_4CH
	PORT MAP(
	i_CLK => i_CLK,
	i_A => s_Amatrix,
	i_X => s_XVECTd,

	o_Y0 =>	s_Y0d,
	o_Y1 =>	s_Y1d,
	o_Y2 => s_Y2d,
	o_Y3 => s_Y3d);

	s_Y0_Summing <= STD_LOGIC_VECTOR(unsigned(s_Y0a) + unsigned(s_Y0d) + unsigned(s_Y0c) + unsigned(s_Y0d));
	s_Y1_Summing <= STD_LOGIC_VECTOR(unsigned(s_Y1a) + unsigned(s_Y1d) + unsigned(s_Y1c) + unsigned(s_Y1d));
	s_Y2_Summing <= STD_LOGIC_VECTOR(unsigned(s_Y2a) + unsigned(s_Y2d) + unsigned(s_Y2c) + unsigned(s_Y2d));
	s_Y3_Summing <= STD_LOGIC_VECTOR(unsigned(s_Y3a) + unsigned(s_Y3d) + unsigned(s_Y3c) + unsigned(s_Y3d));

END mixed;