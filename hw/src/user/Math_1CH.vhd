LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_unsigned.all;
USE work.Common.ALL;
ENTITY Math_1CH IS

    PORT (
        i_A : uint16_1x4array;
        i_X : STD_LOGIC_VECTOR(63 DOWNTO 0);
        o_Y : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));

END Math_1CH;
ARCHITECTURE myArchitecture OF Math_1CH IS
    SIGNAL s_Mult0, s_Mult1, s_Mult2, s_Mult3 : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN
    -- Multiply * 4
    s_Mult0 <= STD_LOGIC_VECTOR(unsigned(i_A(0)) * unsigned(i_X(15 DOWNTO 0)));
    s_Mult1 <= STD_LOGIC_VECTOR(unsigned(i_A(1)) * unsigned(i_X(31 DOWNTO 16)));
    s_Mult2 <= STD_LOGIC_VECTOR(unsigned(i_A(2)) * unsigned(i_X(47 DOWNTO 32)));
    s_Mult3 <= STD_LOGIC_VECTOR(unsigned(i_A(3)) * unsigned(i_X(63 DOWNTO 48)));

    -- Add
    o_Y <= (63 downto 32 => '0') & STD_LOGIC_VECTOR(unsigned(s_Mult0) + unsigned(s_Mult1) + unsigned(s_Mult2) + unsigned(s_Mult3));
END myArchitecture;