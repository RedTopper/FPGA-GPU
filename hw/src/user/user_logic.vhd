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
		NUMVECTORS: integer := 8 -- counter width
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
			i_ADDR : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
			o_RDATAa : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAc : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAd : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAe : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAf : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAg : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAh : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAi : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAj : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAk : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAl : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAm : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAn : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAo : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			o_RDATAp : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
	END COMPONENT;

	-- Glue logic signals.
	SIGNAL s_DONE : STD_LOGIC;
	SIGNAL s_MATH_EN : STD_LOGIC;
	SIGNAL s_CNT : unsigned(128 DOWNTO 0);

	-- Signals to interface with the dmem component
	SIGNAL s_ADDR : STD_LOGIC_VECTOR(14 DOWNTO 0);
	SIGNAL s_RDATA : addr32_2Narray;
	SIGNAL s_vectorsRead : unsigned(15 DOWNTO 0);

	-- Signals to hold Y outputs
	SIGNAL s_Y : std64_Nx4array;
	SIGNAL s_Y_TOTAL : uint64_Nx4array;

	-- Signals to hold the array values
	SIGNAL s_Amatrix : uint16_4x4array;
	SIGNAL s_XVECT : uint16_Nx4array;

	--Signals for the DMEM -> Math Pipeline
	SIGNAL s_XVECTMath : uint16_Nx4array;
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
		i_ADDR => s_ADDR,
		o_RDATAa => s_RDATA(0),
		o_RDATAb => s_RDATA(1),
		o_RDATAc => s_RDATA(2),
		o_RDATAd => s_RDATA(3),
		o_RDATAe => s_RDATA(4),
		o_RDATAf => s_RDATA(5),
		o_RDATAg => s_RDATA(6),
		o_RDATAh => s_RDATA(7),
		o_RDATAi => s_RDATA(8),
		o_RDATAj => s_RDATA(9),
		o_RDATAk => s_RDATA(10),
		o_RDATAl => s_RDATA(11),
		o_RDATAm => s_RDATA(12),
		o_RDATAn => s_RDATA(13),
		o_RDATAo => s_RDATA(14),
		o_RDATAp => s_RDATA(15));

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
				WHEN S0 =>
					-- When we've reset, we can initialize the s_ADDR signal
					s_ADDR <= (OTHERS => '0');

					FOR I IN 0 TO (NUMVECTORS-1) LOOP
						FOR J IN 0 TO 3 LOOP
							s_Y_TOTAL(I)(J) <= (OTHERS => '0');
						END LOOP;
					END LOOP;

					s_vectorsRead <= x"0000";
					cur_state <= S1;

				WHEN S1 =>
					-- Need to wait a cycle for RAM
					s_ADDR <= STD_LOGIC_VECTOR(unsigned(s_ADDR) + 8);

					cur_state <= S2;

				WHEN S2 =>
					-- Read A Matrix
					FOR I IN 0 TO 3 LOOP
						s_Amatrix(I)(0) <= unsigned(s_RDATA(I*2)(31 DOWNTO 16));
						s_Amatrix(I)(1) <= unsigned(s_RDATA(I*2)(15 DOWNTO 0));
						s_Amatrix(I)(2) <= unsigned(s_RDATA(I*2 + 1)(31 DOWNTO 16));
						s_Amatrix(I)(3) <= unsigned(s_RDATA(I*2 + 1)(15 DOWNTO 0));
					END LOOP;

					s_ADDR <= STD_LOGIC_VECTOR(unsigned(s_ADDR) + 2*NUMVECTORS);

					cur_state <= S3;

				WHEN S3 =>
					FOR I IN 0 TO (NUMVECTORS-1) LOOP
						s_XVECT(I)(0) <= unsigned(s_RDATA(I*2)(31 DOWNTO 16));
						s_XVECT(I)(1) <= unsigned(s_RDATA(I*2)(15 DOWNTO 0));
						s_XVECT(I)(2) <= unsigned(s_RDATA(I*2 + 1)(31 DOWNTO 16));
						s_XVECT(I)(3) <= unsigned(s_RDATA(I*2 + 1)(15 DOWNTO 0));
					END LOOP;

					s_ADDR <= STD_LOGIC_VECTOR(unsigned(s_ADDR) + 2*NUMVECTORS);

					FOR I IN 0 TO (NUMVECTORS-1) LOOP
						FOR J IN 0 TO 3 LOOP
							s_Y_TOTAL(I)(J) <= s_Y_TOTAL(I)(J) + unsigned(s_Y(I)(J));
						END LOOP;
					END LOOP;

					s_MATH_EN <= '1';

					-- Wait until the next state to finalize, since the Math Pipeline delays the outputs by one cycle.
					-- This also delays the done signal
					IF (s_vectorsRead = x"2710" + NUMVECTORS*2) THEN
						cur_state <= S4;
					ELSE
						s_vectorsRead <= s_vectorsRead + NUMVECTORS;
					END IF;

				WHEN S4 =>
					o_Y0 <= STD_LOGIC_VECTOR(unsigned(s_Y_TOTAL(0)(0) + s_Y_TOTAL(1)(0) + s_Y_TOTAL(2)(0) + s_Y_TOTAL(3)(0) + s_Y_TOTAL(4)(0) + s_Y_TOTAL(5)(0) + s_Y_TOTAL(6)(0) + s_Y_TOTAL(7)(0)));
					o_Y1 <= STD_LOGIC_VECTOR(unsigned(s_Y_TOTAL(0)(1) + s_Y_TOTAL(1)(1) + s_Y_TOTAL(2)(1) + s_Y_TOTAL(3)(1) + s_Y_TOTAL(4)(1) + s_Y_TOTAL(5)(1) + s_Y_TOTAL(6)(1) + s_Y_TOTAL(7)(1)));
					o_Y2 <= STD_LOGIC_VECTOR(unsigned(s_Y_TOTAL(0)(2) + s_Y_TOTAL(1)(2) + s_Y_TOTAL(2)(2) + s_Y_TOTAL(3)(2) + s_Y_TOTAL(4)(2) + s_Y_TOTAL(5)(2) + s_Y_TOTAL(6)(2) + s_Y_TOTAL(7)(2)));
					o_Y3 <= STD_LOGIC_VECTOR(unsigned(s_Y_TOTAL(0)(3) + s_Y_TOTAL(1)(3) + s_Y_TOTAL(2)(3) + s_Y_TOTAL(3)(3) + s_Y_TOTAL(4)(3) + s_Y_TOTAL(5)(3) + s_Y_TOTAL(6)(3) + s_Y_TOTAL(7)(3)));
					cur_state <= S5;

				WHEN S5 =>
					s_DONE <= '1';

					cur_state <= S6;

				WHEN S6 =>
				    s_DONE <= '0';

				WHEN OTHERS =>
					s_ADDR <= (OTHERS => '0');

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