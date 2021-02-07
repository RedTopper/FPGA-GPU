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
	generic (
		NUMVECTORS: integer := 4 -- counter width
	);
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
	SIGNAL s_MATH_EN : STD_LOGIC;
	SIGNAL s_CNT : unsigned(128 DOWNTO 0);

	-- Signals to interface with the dmem component
	SIGNAL s_ADDR : addr15_8array;
	SIGNAL s_RDATA : addr32_8array;
	SIGNAL s_vectorsRead : unsigned(15 DOWNTO 0);

	-- Signals to hold Y outputs
	SIGNAL s_Y : std64_4x4array;
	SIGNAL s_Y_TOTAL : uint64_4x4array;

	-- Signals to hold the array values
	SIGNAL s_Amatrix : uint16_4x4array;
	SIGNAL s_XVECT : uint16_4x4array;

	--Signals for the DMEM -> Math Pipeline
	SIGNAL s_XVECTMath : uint16_4x4array;
	SIGNAL s_MATH_ENDmemMath : STD_LOGIC;

	-- Finite State Machine signals
	TYPE state_type IS (S0, S1, S2, S3, S4, S5, S6);
	SIGNAL cur_state : state_type;

	COMPONENT Math_4CH
		PORT (
			i_CLK : IN STD_LOGIC;
			i_MATH_EN : IN STD_LOGIC;
			i_A : uint16_4x4array;
			i_X : uint16_1x4array;

			o_MY0 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
			o_MY1 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
			o_MY2 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
			o_MY3 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
	END COMPONENT;

BEGIN

	-- Set o_DONE as s_DONE
	o_DONE <= s_DONE;

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

	P2 : PROCESS (i_CLK, i_RST)
	BEGIN
		IF (i_RST = '1') THEN
			cur_state <= S0;
			s_DONE <= '0';
			s_MATH_EN <= '0';
			s_CNT <= (OTHERS => '0');

		ELSIF (rising_edge(i_CLK)) THEN
			IF (s_DONE = '0') THEN
				s_CNT <= s_CNT + 1;
			END IF;

			CASE cur_state IS
				-- When we've reset, we can initialize the s_ADDR signal
				WHEN S0 =>
					FOR I IN 0 TO (2*NUMVECTORS-1) LOOP
						-- Set each ADDR(I) = I in binary
						s_ADDR(I) <= std_logic_vector(to_unsigned(I, s_ADDR(I)'length));
					END LOOP;

					FOR I IN 0 TO (NUMVECTORS-1) LOOP
						FOR J IN 0 TO 3 LOOP
							s_Y_TOTAL(I)(J) <= (OTHERS => '0');
						END LOOP;
					END LOOP;

					s_vectorsRead <= x"0000";
					cur_state <= S1;

				WHEN S1 =>
					-- Need to wait a cycle for RAM
					FOR I IN 0 TO (2*NUMVECTORS-1) LOOP
						-- The 8 needs to be fixed here since there are only 8 values needed
						-- to fill the A Matrix
						s_ADDR(I) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(I)) + 8);
					END LOOP;

					cur_state <= S2;

				WHEN S2 =>
					-- Read A Matrix
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

					FOR I IN 0 TO (2*NUMVECTORS-1) LOOP
						s_ADDR(I) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(I)) + 2*NUMVECTORS);
					END LOOP;

					cur_state <= S3;

				WHEN S3 =>
					FOR I IN 0 TO (NUMVECTORS-1) LOOP
						s_XVECT(I)(0) <= unsigned(s_RDATA(I*2)(31 DOWNTO 16));
						s_XVECT(I)(1) <= unsigned(s_RDATA(I*2)(15 DOWNTO 0));
						s_XVECT(I)(2) <= unsigned(s_RDATA(I*2 + 1)(31 DOWNTO 16));
						s_XVECT(I)(3) <= unsigned(s_RDATA(I*2 + 1)(15 DOWNTO 0));
					END LOOP;

					FOR I IN 0 TO (2*NUMVECTORS-1) LOOP
						s_ADDR(I) <= STD_LOGIC_VECTOR(unsigned(s_ADDR(I)) + 2*NUMVECTORS);
					END LOOP;

					FOR I IN 0 TO (NUMVECTORS-1) LOOP
						FOR J IN 0 TO 3 LOOP
							s_Y_TOTAL(I)(J) <= s_Y_TOTAL(I)(J) + unsigned(s_Y(I)(J));
						END LOOP;
					END LOOP;

					s_MATH_EN <= '1';

					-- Wait until the next state to finalize, since the Math Pipeline delays the outputs by one cycle.
					-- This also delays the done signal
					IF (s_vectorsRead = x"2710" + x"008") THEN
						cur_state <= S4;
					ELSE
						s_vectorsRead <= s_vectorsRead + x"004";
					END IF;

				WHEN S4 =>
					o_Y0 <= STD_LOGIC_VECTOR(unsigned(s_Y_TOTAL(0)(0) + s_Y_TOTAL(1)(0) + s_Y_TOTAL(2)(0) + s_Y_TOTAL(3)(0)));
					o_Y1 <= STD_LOGIC_VECTOR(unsigned(s_Y_TOTAL(0)(1) + s_Y_TOTAL(1)(1) + s_Y_TOTAL(2)(1) + s_Y_TOTAL(3)(1)));
					o_Y2 <= STD_LOGIC_VECTOR(unsigned(s_Y_TOTAL(0)(2) + s_Y_TOTAL(1)(2) + s_Y_TOTAL(2)(2) + s_Y_TOTAL(3)(2)));
					o_Y3 <= STD_LOGIC_VECTOR(unsigned(s_Y_TOTAL(0)(3) + s_Y_TOTAL(1)(3) + s_Y_TOTAL(2)(3) + s_Y_TOTAL(3)(3)));
					cur_state <= S5;

				WHEN S5 =>
					s_DONE <= '1';

					cur_state <= S6;

				WHEN S6 =>
				    s_DONE <= '0';
					
				WHEN OTHERS =>
					FOR I IN 0 TO (2*NUMVECTORS-1) LOOP
						s_ADDR(I) <= (OTHERS => '0');
					END LOOP;

					cur_state <= S0;

			END CASE;
		END IF;
	END PROCESS;

	DmemMathPipe : PROCESS (i_CLK, i_RST) BEGIN
		IF (rising_edge(i_CLK)) THEN
			s_XVECTMath <= s_XVECT;
			s_MATH_ENDmemMath <= s_MATH_EN;
		END IF;
	END PROCESS;

	VECTORS: FOR I IN 0 TO (NUMVECTORS-1) GENERATE
		Math_4CHM : Math_4CH
		PORT MAP(
			i_CLK => i_CLK,
			i_MATH_EN => s_MATH_ENDmemMath,
			i_A => s_Amatrix,
			i_X => s_XVECTMath(I),

			o_MY0 => s_Y(I)(0),
			o_MY1 => s_Y(I)(1),
			o_MY2 => s_Y(I)(2),
			o_MY3 => s_Y(I)(3));
	END GENERATE VECTORS;

END mixed;