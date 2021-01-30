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
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
ENTITY fixed_logic IS
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
END fixed_logic;

ARCHITECTURE mixed OF fixed_logic IS

	-- component declarations
	COMPONENT outmem
		PORT (
			i_CLKa, i_CLKb : IN STD_LOGIC;
			i_ENa, i_ENb : IN STD_LOGIC;
			i_WEa, i_WEb : IN STD_LOGIC;
			i_ADDRa : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			i_ADDRb : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
			i_WDATAa : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
			i_WDATAb : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
			o_RDATAa : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
			o_RDATAb : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
	END COMPONENT;

	COMPONENT uart_Controller
		PORT (
			clk100, rst : IN STD_LOGIC;
			RxD : IN STD_LOGIC;
			TxD : OUT STD_LOGIC;
			msg_din : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
			msg_wren : IN STD_LOGIC;
			msg_afull : OUT STD_LOGIC);
	END COMPONENT;

	COMPONENT bin_to_ascii
		GENERIC (N : INTEGER := 64);
		PORT (
			i_A : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
			o_F : OUT STD_LOGIC_VECTOR(2 * N - 1 DOWNTO 0));
	END COMPONENT;

	-- outmem interface signals
	SIGNAL s_ADDRa, s_ADDRb : STD_LOGIC_VECTOR(4 DOWNTO 0);
	SIGNAL s_RDATAa, s_RDATAb : STD_LOGIC_VECTOR(63 DOWNTO 0);
	SIGNAL s_WDATAa, s_WDATAb : STD_LOGIC_VECTOR(63 DOWNTO 0);
	SIGNAL s_WEa, s_WEb : STD_LOGIC;

	-- uart_Controller interface signals
	SIGNAL s_msg_wren, s_msg_afull : STD_LOGIC;

	-- We're only interested in a single i_DONE cycle
	SIGNAL s_DONE, s_DONE_reg : STD_LOGIC;

	-- To hold the running timer and the final timer value
	SIGNAL s_timer1 : unsigned(31 DOWNTO 0);
	SIGNAL s_timer2 : unsigned(34 DOWNTO 0);
	SIGNAL s_timer_reg : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL s_timer_reg2 : STD_LOGIC_VECTOR(63 DOWNTO 0);

	-- To hold the y vector in a second register that only gets written once
	SIGNAL s_Y0_reg, s_Y1_reg, s_Y2_reg, s_Y3_reg : STD_LOGIC_VECTOR(63 DOWNTO 0);
	SIGNAL s_Y0_reg2, s_Y1_reg2, s_Y2_reg2, s_Y3_reg2 : STD_LOGIC_VECTOR(127 DOWNTO 0);

	-- Finite State Machine signals
	TYPE state_type IS (S0, S1, S2, S3, S4, S5, S6);
	SIGNAL cur_state : state_type;

BEGIN
	U1 : outmem
	PORT MAP(
		i_CLKa => i_CLK,
		i_CLKb => i_CLK,
		i_ENa => '1',
		i_ENb => '1',
		i_WEa => s_WEa,
		i_WEb => s_WEb,
		i_ADDRa => s_ADDRa,
		i_ADDRb => s_ADDRb,
		i_WDATAa => s_WDATAa,
		i_WDATAb => s_WDATAb,
		o_RDATAa => s_RDATAa,
		o_RDATAb => s_RDATAb);

	U2 : uart_Controller
	PORT MAP(
		clk100 => i_CLK,
		rst => i_RST,
		RxD => RxD,
		TxD => TxD,
		msg_din => s_RDATAb,
		msg_wren => s_msg_wren,
		msg_afull => s_msg_afull);

	U3_0 : bin_to_ascii
	GENERIC MAP(N => 64)
	PORT MAP(
		i_A => s_Y0_reg,
		o_F => s_Y0_reg2);

	U3_1 : bin_to_ascii
	GENERIC MAP(N => 64)
	PORT MAP(
		i_A => s_Y1_reg,
		o_F => s_Y1_reg2);

	U3_2 : bin_to_ascii
	GENERIC MAP(N => 64)
	PORT MAP(
		i_A => s_Y2_reg,
		o_F => s_Y2_reg2);

	U3_3 : bin_to_ascii
	GENERIC MAP(N => 64)
	PORT MAP(
		i_A => s_Y3_reg,
		o_F => s_Y3_reg2);

	U3_4 : bin_to_ascii
	GENERIC MAP(N => 32)
	PORT MAP(
		i_A => s_timer_reg,
		o_F => s_timer_reg2);
	-- This process registers the i_DONE signal so that it only
	-- pulses for 1 cycle
	P0 : PROCESS (i_CLK, i_RST, i_DONE)
	BEGIN

		IF (i_RST = '1') THEN
			s_DONE <= '0';
		ELSIF (rising_edge(i_CLK)) THEN
			s_DONE <= i_DONE;
		END IF;
	END PROCESS;

	s_DONE_reg <= (NOT s_DONE) AND i_DONE;

	-- To calculate the result in ns, multiply by 10
	s_timer2 <= (s_timer1 & "000") + (s_timer1 & "0");
	-- This process enables the timer counter when i_RST is received,
	-- and then stores the result when i_DONE is received
	P1 : PROCESS (i_CLK, i_RST, s_DONE_reg, s_timer1, s_timer2)
	BEGIN

		IF (i_RST = '1') THEN
			s_timer1 <= (OTHERS => '0');

		ELSIF (rising_edge(i_CLK)) THEN
			s_timer1 <= s_TIMER1 + 1;

			IF (s_DONE_REG = '1') THEN
				s_timer_reg <= STD_LOGIC_VECTOR(s_timer2(31 DOWNTO 0));
			END IF;

		END IF;

	END PROCESS;
	-- This process registers the Y vector values when the computation is done
	P2 : PROCESS (i_CLK, i_RST, s_DONE_reg, i_Y0, i_Y1, i_Y2, i_Y3)
	BEGIN

		IF (i_RST = '1') THEN
			s_Y0_reg <= (OTHERS => '0');
			s_Y1_reg <= (OTHERS => '0');
			s_Y2_reg <= (OTHERS => '0');
			s_Y3_reg <= (OTHERS => '0');
		ELSIF (rising_edge(i_CLK)) THEN
			IF (s_DONE_reg = '1') THEN
				s_Y0_reg <= i_Y0;
				s_Y1_reg <= i_Y1;
				s_Y2_reg <= i_Y2;
				s_Y3_reg <= i_Y3;
			END IF;
		END IF;

	END PROCESS;
	-- When we receive the DONE signal, we can write the 5 values to memory and 
	-- then push values into the uart_Controller FIFO
	P3 : PROCESS (i_CLK, i_RST, s_DONE_reg)
	BEGIN
		IF (i_RST = '1') THEN
			cur_state <= S0;

			s_ADDRa <= (OTHERS => '0');
			s_ADDRb <= (OTHERS => '0');
			s_WDATAa <= (OTHERS => '0');
			s_WDATAb <= (OTHERS => '0');
			s_WEa <= '0';
			s_WEb <= '0';

			s_msg_wren <= '0';

		ELSIF (rising_edge(i_CLK)) THEN

			CASE cur_state IS

				WHEN S0 =>

					s_ADDRa <= (OTHERS => '0');
					s_ADDRb <= (OTHERS => '0');
					s_WDATAa <= (OTHERS => '0');
					s_WDATAb <= (OTHERS => '0');
					s_WEa <= '0';
					s_WEb <= '0';

					s_msg_wren <= '0';

					IF (s_DONE_reg = '1') THEN
						cur_state <= S1;
					ELSE
						cur_state <= S0;
					END IF;
				WHEN S1 =>

					cur_state <= S2;

					-- Write y[0] to addr 4 and 5 
					s_ADDRa <= "00100";
					s_ADDRb <= "00101";
					s_WDATAa <= s_Y0_reg2(127 DOWNTO 64);
					s_WDATAb <= s_Y0_reg2(63 DOWNTO 0);
					s_WEa <= '1';
					s_WEb <= '1';

					s_msg_wren <= '0';
				WHEN S2 =>

					cur_state <= S3;

					-- Write y[1] to addr 8 and 9	
					s_ADDRa <= "01000";
					s_ADDRb <= "01001";
					s_WDATAa <= s_Y1_reg2(127 DOWNTO 64);
					s_WDATAb <= s_Y1_reg2(63 DOWNTO 0);
					s_WEa <= '1';
					s_WEb <= '1';

					s_msg_wren <= '0';
				WHEN S3 =>

					cur_state <= S4;

					-- Write y[2] to addr 12 and 13	
					s_ADDRa <= "01100";
					s_ADDRb <= "01101";
					s_WDATAa <= s_Y2_reg2(127 DOWNTO 64);
					s_WDATAb <= s_Y2_reg2(63 DOWNTO 0);
					s_WEa <= '1';
					s_WEb <= '1';

					s_msg_wren <= '0';

				WHEN S4 =>

					cur_state <= S5;

					-- Write y[3] to addr 16 and 17	
					s_ADDRa <= "10000";
					s_ADDRb <= "10001";
					s_WDATAa <= s_Y3_reg2(127 DOWNTO 64);
					s_WDATAb <= s_Y3_reg2(63 DOWNTO 0);
					s_WEa <= '1';
					s_WEb <= '1';

					s_msg_wren <= '0';
				WHEN S5 =>

					-- Write the timer to addr 20, and start reading
					s_ADDRa <= "10100";
					s_ADDRb <= "00000";
					s_WDATAa <= s_timer_reg2;
					s_WDATAb <= (OTHERS => '0');
					s_WEa <= '1';
					s_WEb <= '0';

					s_msg_wren <= '0';

					IF (s_msg_afull = '0') THEN
						cur_state <= S6;
					ELSE
						cur_state <= S5;
					END IF;

				WHEN S6 =>

					-- Continue reading
					s_ADDRa <= (OTHERS => '0');
					s_WDATAa <= (OTHERS => '0');
					s_WDATAb <= (OTHERS => '0');
					s_WEa <= '0';
					s_WEb <= '0';

					IF (s_msg_afull = '0') THEN
						s_msg_wren <= '1';

						-- If we're about to do our 22th read, we are done.
						IF (s_ADDRb = "10101") THEN
							cur_state <= S0;
						ELSE
							cur_state <= S6;
						END IF;
						s_ADDRb <= STD_LOGIC_VECTOR(unsigned(s_ADDRb) + 1);

					ELSE
						s_msg_wren <= '0';
						cur_state <= S6;
					END IF;

				WHEN OTHERS =>
					cur_state <= S0;

					s_ADDRa <= (OTHERS => '0');
					s_ADDRb <= (OTHERS => '0');
					s_WDATAa <= (OTHERS => '0');
					s_WDATAb <= (OTHERS => '0');
					s_WEa <= '0';
					s_WEb <= '0';

					s_msg_wren <= '0';

			END CASE;

		END IF;

	END PROCESS;
END mixed;