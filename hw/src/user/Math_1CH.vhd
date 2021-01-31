LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.Common.ALL
ENTITY Math_1CH IS

    PORT (
        i_A : uint16_1x4array;
        i_X : STD_LOGIC_VECTOR(63 DOWNTO 0);
        o_Y : STD_LOGIC_VECTOR(63 DOWNTO 0);
    );
END Math_1CH
architecture myArchitecture OF Math_1CH IS


begin

--


end MyArchitcture