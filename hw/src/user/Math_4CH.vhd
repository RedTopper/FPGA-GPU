LIBRARY IEEE;
USE Work.Common.ALL;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
ENTITY Math_4CH IS

    PORT (
        i_CLK : IN STD_LOGIC;
        i_MATH_EN : IN STD_LOGIC;
        i_A : uint16_4x4array;
        i_X : uint16_1x4array;

        o_MY0 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        o_MY1 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        o_MY2 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        o_MY3 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
END Math_4CH;

ARCHITECTURE theArchitect OF Math_4CH IS

    COMPONENT Math_1CH
        PORT (
            i_CLK : STD_LOGIC;
            i_MATH_EN : STD_LOGIC;
            i_A : uint16_1x4array;
            i_X :uint16_1x4array;
            o_Y : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
    END COMPONENT;
    --intermediary signals
    SIGNAL s_A : uint16_4x4array;
    SIGNAL s_X : uint16_1x4array;
    SIGNAL s_Y0, s_Y1, s_Y2, s_Y3 : STD_LOGIC_VECTOR(63 DOWNTO 0);

BEGIN

    s_A <= i_A;
    s_X <= i_X;
    o_MY0 <= s_Y0;
    o_MY1 <= s_Y1;
    o_MY2 <= s_Y2;
    o_MY3 <= s_Y3;
    --reminder to populate the signals
    --generate with the components
    Math_A0 : Math_1CH
    PORT MAP(
        i_CLK => i_CLK,
        i_MATH_EN => i_MATH_EN,
        i_A => s_A(0),
        i_X => s_X,
        o_Y => s_Y0
    );

    Math_A1 : Math_1CH
    PORT MAP(
        i_CLK => i_CLK,
        i_MATH_EN => i_MATH_EN,
        i_A => s_A(1),
        i_X => s_X,
        o_Y => s_Y1
    );

    Math_A2 : Math_1CH
    PORT MAP(
        i_CLK => i_CLK,
        i_MATH_EN => i_MATH_EN,
        i_A => s_A(2),
        i_X => s_X,
        o_Y => s_Y2
    );

    Math_A3 : Math_1CH
    PORT MAP(
        i_CLK => i_CLK,
        i_MATH_EN => i_MATH_EN,
        i_A => s_A(3),
        i_X => s_X,
        o_Y => s_Y3
    );
END theArchitect;