LIBRARY IEEE;
USE work.Common.ALL
USE IEEE.std_logic_1164.ALL;
USE IEE.numeric_std.ALL;
ENTITY Math_4CH IS

    PORT (
        i_CLK : IN STD_LOGIC;
        i_A : uint16_4x4array;
        i_X : STD_LOGIC_VECTOR(31 DOWNTO 0);

        o_Y0 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        o_Y1 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        o_Y2 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        o_Y3 : OUT STD_LOGIC_VECTOR(63 DOWNTO 0));
END Math_4CH;

ARCHITECTURE theArchitect OF Math_4CH IS

    COMPONENT Math_1CH
        PORT (
            i_A : uint16_1x4array;
            i_X : STD_LOGIC_VECTOR(63 DOWNTO 0);
            o_Y : STD_LOGIC_VECTOR(63 DOWNTO 0);
        );
    END COMPONENT;
    --intermediary signals
    SIGNAL s_A : unit16_4x4array;
    SIGNAL s_X : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL s_Y0, s_Y1, s_Y2, s_Y3 : STD_LOGIC_VECTOR(63 DOWNTO 0);

BEGIN

    s_A <= i_A;
    s_X <= i_X;
    o_Y0 <= s_Y0;
    o_Y1 <= s_Y1;
    o_Y2 <= s_Y2;
    o_Y3 <= s_Y3;  
    --reminder to populate the signals
    --generate with the components
    Math_A0 : Math_1CH
    PORT MAP(
        i_A => s_A(0);
        i_X => s_X;
        o_Y => s_Y0;
    );

    Math_A1 : Math_1CH
    PORT MAP(
        i_A => s_A(1);
        i_X => s_X;
        o_Y => s_Y1;
    );

    Math_A2 : Math_1CH
    PORT MAP(
        i_A => s_A(2);
        i_X => s_X;
        o_Y => s_Y2;
    );

    Math_A3 : Math_1CH
    PORT MAP(
        i_A => s_A(3);
        i_X => s_X;
        o_Y => s_Y3;
    );
END theArchitect;