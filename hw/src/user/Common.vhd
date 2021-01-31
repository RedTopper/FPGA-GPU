package Common is

    TYPE uint16_1x4array IS ARRAY(0 TO 3) OF unsigned(15 DOWNTO 0);
    TYPE uint16_4x4array IS ARRAY(0 TO 3) OF uint16_1x4array;

end Common; 
