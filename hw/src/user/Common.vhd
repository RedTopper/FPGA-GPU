LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std .all;
package Common is

    TYPE uint16_1x4array IS ARRAY(0 TO 3) OF unsigned(15 DOWNTO 0);
    TYPE uint16_4x4array IS ARRAY(0 TO 3) OF uint16_1x4array;

    TYPE uint64_1x4array IS ARRAY(0 TO 3) OF unsigned(63 DOWNTO 0);
    TYPE uint64_4x4array IS ARRAY(0 TO 3) OF uint64_1x4array;

    TYPE std64_1x4array IS ARRAY(0 TO 3) OF STD_LOGIC_VECTOR(63 DOWNTO 0);
    TYPE std64_4x4array IS ARRAY(0 TO 3) OF std64_1x4array;

    TYPE addr15_8array IS ARRAY(0 TO 7) OF STD_LOGIC_VECTOR(14 DOWNTO 0);
    TYPE addr32_8array IS ARRAY(0 TO 7) OF STD_LOGIC_VECTOR(31 DOWNTO 0);

end Common; 
