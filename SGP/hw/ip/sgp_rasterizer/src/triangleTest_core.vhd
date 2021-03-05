-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- triangleTest_core.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a the triangle 
-- testing (in/out) logic of the Steffen rasterization algorithm. It also
-- does the linear interpolation based on previously computed C5 and C6
-- values. 
--
-- NOTES:
-- 12/07/20 by JAZ::Design created.
-------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
LIBRARY WORK;
USE WORK.sgp_types.ALL;
ENTITY triangleTest_core IS

    PORT (
        ACLK : IN STD_LOGIC;
        ARESETN : IN STD_LOGIC;

        -- AXIS-style triangle setup inputs
        Area : IN signed(23 DOWNTO 0);
        direction : IN STD_LOGIC;
        C5 : IN vertexArray_t; -- Our x-dim linear interpolation for all attributes
        C6 : IN vertexArray_t; -- Our y-dim linear interpolation for all attributes
        triangle_in : IN triangleArray_t; -- Potentially re-ordered vertices
        setup_in_ready : OUT STD_LOGIC;
        setup_in_valid : IN STD_LOGIC;

        -- Asynchronous command stream
        command_in : IN traversal_cmds_t;
        fragment_test_result : OUT STD_LOGIC;

        -- AXIS-style fragment output
        fragment_out_ready : IN STD_LOGIC;
        fragment_out_valid : OUT STD_LOGIC;
        fragment_out : OUT vertexArray_t

    );
END triangleTest_core;
ARCHITECTURE behavioral OF triangleTest_core IS
    TYPE STATE_TYPE IS (WAIT_FOR_SETUP, WAIT_FOR_START_CMD, WAIT_FOR_DONE_CMD);
    SIGNAL triangleTest_state : STATE_TYPE;

    -- Design registers and remapping signals
    SIGNAL triangle_reg : triangleArray_t;
    SIGNAL V0_array, V1_array, V2_array : vertexArray_t;
    SIGNAL C5_reg, C6_reg : vertexArray_t;
    SIGNAL start_Area_reg : signed(23 DOWNTO 0);
    SIGNAL start_direction_reg : STD_LOGIC;
    SIGNAL in_vals : STD_LOGIC_VECTOR(2 DOWNTO 0);

    -- C7, C8 for updating the areas of the three lines. These values are fixed per-triangle. 
    -- Note, we have to be consistent with what each index means for these 3-length arrays:
    -- [0] - line from {V0-V1}
    -- [1] - line from {V1-V2}
    -- [2] - line from {V2-V0}
    TYPE lineArray_t IS ARRAY (2 DOWNTO 0) OF fixed_t;
    TYPE lineAreaArray_t IS ARRAY (2 DOWNTO 0) OF signed(23 DOWNTO 0);
    SIGNAL C7_wire : lineArray_t;
    SIGNAL C8_wire : lineArray_t;
    SIGNAL C7_reg : lineAreaArray_t;
    SIGNAL C8_reg : lineAreaArray_t;

    -- Area, direction, and attribute values for the triangles formed by the lines and a new point. We are being a little verbose here to simplify the stack/store
    -- logic below
    SIGNAL Area_line_nextreg, Area_line_reg, Area_line_nextstack, Area_line_stack : lineAreaArray_t;
    SIGNAL newfragment_nextreg, newfragment_reg, newfragment_nextstack, newfragment_stack : vertexArray_t;
BEGIN

    -- Remap the triangle to the vertexArray and vertexRecord data structure so we can access elements easily
    V0_array <= to_vertexArray_t(triangle_reg(0));
    V1_array <= to_vertexArray_t(triangle_reg(1));
    V2_array <= to_vertexArray_t(triangle_reg(2));
    setup_in_ready <= '1' WHEN triangleTest_state = WAIT_FOR_SETUP ELSE
        '0';

    -- Our fragment is in if the direction of the point relative to all three lines is the same as our triangle's starting direction. 
    -- We can check the sign bits of the Area_line wire to confirm (also consider A=0 to be in)
    G1 : FOR i IN 2 DOWNTO 0 GENERATE
        in_vals(i) <= testresult_in WHEN Area_line_nextreg(i) = 0 ELSE 
        testresult_in WHEN Area_line_nextreg(i)(Area_line_nextreg(i)'high) = start_direction_reg ELSE testresult_out;
    END GENERATE;
    fragment_test_result <= testresult_in WHEN in_vals = "111" ELSE testresult_out;

    -- We're using fragment_out_valid as backpressure on triangleTraversal
    fragment_out <= newfragment_nextreg WHEN triangleTest_state = WAIT_FOR_DONE_CMD ELSE vertexArray_t_zero;
    fragment_out_valid <= fragment_out_ready WHEN ((triangleTest_state = WAIT_FOR_DONE_CMD)) ELSE '0';
    
    -- Process commmands as they come in and update Area, direction, and the fragment itself. Note, this is a combinational process so be careful with the
    -- sensitivity list (process(all) not supported yet in V2020.1)
    PROCESS (command_in, Area_line_reg, Area_line_stack, newfragment_reg, newfragment_stack, start_Area_reg, V0_array, C5_reg, C6_reg, C7_reg, C8_reg)
    BEGIN
        -- Default signal assignment. Best to avoid latches.
        Area_line_nextreg <= Area_line_reg;
        Area_line_nextstack <= Area_line_stack;
        newfragment_nextreg <= newfragment_reg;
        newfragment_nextstack <= newfragment_stack;

        CASE command_in IS
            WHEN START_CMD =>
                Area_line_nextreg <= (0 => (OTHERS => '0'), 1 => start_Area_reg, 2 => (OTHERS => '0'));
                Area_line_nextstack <= (0 => (OTHERS => '0'), 1 => start_Area_reg, 2 => (OTHERS => '0'));
                newfragment_nextreg <= V0_array;
                newfragment_nextstack <= V0_array;

                -- When we pop and move left, we should wind up 1 pixel to the left of what is stored on our stack. 
                -- Move all values 1 interpolated amount in -x dimension (-C5, -C7)
            WHEN POP_MOVE_LEFT_CMD =>
                FOR i IN 0 TO 2 LOOP
                    Area_line_nextreg(i) <= Area_line_stack(i) - C7_reg(i);
                END LOOP;
                FOR i IN 0 TO C_SGP_NUM_VERTEX_ATTRIB - 1 LOOP
                    FOR j IN 0 TO C_SGP_VERTEX_ATTRIB_SIZE - 1 LOOP
                        newfragment_nextreg(i)(j) <= newfragment_stack(i)(j) - C5_reg(i)(j);
                    END LOOP;
                END LOOP;

                -- When we pop and move right, we should wind up 1 pixel to the right of what is stored on our stack. 
                -- Move all values 1 interpolated amount in +x dimension (+C5, +C7)
            WHEN POP_MOVE_RIGHT_CMD =>
                FOR i IN 0 TO 2 LOOP
                    Area_line_nextreg(i) <= Area_line_stack(i) + C7_reg(i);
                END LOOP;
                FOR i IN 0 TO C_SGP_NUM_VERTEX_ATTRIB - 1 LOOP
                    FOR j IN 0 TO C_SGP_VERTEX_ATTRIB_SIZE - 1 LOOP
                        newfragment_nextreg(i)(j) <= newfragment_stack(i)(j) + C5_reg(i)(j);
                    END LOOP;
                END LOOP;

                -- When moving right, move all values 1 interpolated amount in +x dimension (+C5, +C7)
            WHEN MOVE_RIGHT_CMD =>
                FOR i IN 0 TO 2 LOOP
                    Area_line_nextreg(i) <= Area_line_reg(i) + C7_reg(i);
                END LOOP;
                FOR i IN 0 TO C_SGP_NUM_VERTEX_ATTRIB - 1 LOOP
                    FOR j IN 0 TO C_SGP_VERTEX_ATTRIB_SIZE - 1 LOOP
                        newfragment_nextreg(i)(j) <= newfragment_reg(i)(j) + C5_reg(i)(j);
                    END LOOP;
                END LOOP;

                -- When moving left, move all values 1 interpolated amount in +x dimension (-C5, -C7)
            WHEN MOVE_LEFT_CMD =>
                FOR i IN 0 TO 2 LOOP
                    Area_line_nextreg(i) <= Area_line_reg(i) - C7_reg(i);
                END LOOP;
                FOR i IN 0 TO C_SGP_NUM_VERTEX_ATTRIB - 1 LOOP
                    FOR j IN 0 TO C_SGP_VERTEX_ATTRIB_SIZE - 1 LOOP
                        newfragment_nextreg(i)(j) <= newfragment_reg(i)(j) - C5_reg(i)(j);
                    END LOOP;
                END LOOP;

                -- When moving down, we should wind up 1 pixel below where we currently are. 
                -- Move all values 1 interpolated amount in -y dimension (-C6, -C8)               
            WHEN PUSH_MOVE_DOWN_CMD =>
                FOR i IN 0 TO 2 LOOP
                    Area_line_nextreg(i) <= Area_line_reg(i) - C8_reg(i);
                    Area_line_nextstack(i) <= Area_line_reg(i) - C8_reg(i);
                END LOOP;
                FOR i IN 0 TO C_SGP_NUM_VERTEX_ATTRIB - 1 LOOP
                    FOR j IN 0 TO C_SGP_VERTEX_ATTRIB_SIZE - 1 LOOP
                        newfragment_nextreg(i)(j) <= newfragment_reg(i)(j) - C6_reg(i)(j);
                        newfragment_nextstack(i)(j) <= newfragment_reg(i)(j) - C6_reg(i)(j);
                    END LOOP;
                END LOOP;
                
            WHEN OTHERS =>

        END CASE;
    END PROCESS;
    -- Calculate the area change for +x, +y. We will convert down to Area signed int format in the register
    -- [0] - line from {V0-V1}
    -- [1] - line from {V1-V2}
    -- [2] - line from {V2-V0}
    C7_wire(0) <= V0_array(0)(1) - V1_array(0)(1);
    C7_wire(1) <= V1_array(0)(1) - V2_array(0)(1);
    C7_wire(2) <= V2_array(0)(1) - V0_array(0)(1);
    C8_wire(0) <= V1_array(0)(0) - V0_array(0)(0); -- (x_1 - x_0)
    C8_wire(1) <= V2_array(0)(0) - V1_array(0)(0);
    C8_wire(2) <= V0_array(0)(0) - V2_array(0)(0);

    -- This process sets the internal registers for the design.
    PROCESS (ACLK) IS
    BEGIN
        IF rising_edge(ACLK) THEN
            IF ARESETN = '0' THEN
                Area_line_reg <= (OTHERS => (OTHERS => '0'));
                Area_line_stack <= (OTHERS => (OTHERS => '0'));
                newfragment_reg <= vertexArray_t_zero;
                newfragment_stack <= vertexArray_t_zero;

            ELSE
                IF (fragment_out_ready = '1') THEN
                    Area_line_reg <= Area_line_nextreg;
                    Area_line_stack <= Area_line_nextstack;
                    newfragment_reg <= newfragment_nextreg;
                    newfragment_stack <= newfragment_nextstack;
                END IF;

            END IF;
        END IF;
    END PROCESS;

    PROCESS (ACLK) IS
    BEGIN
        IF rising_edge(ACLK) THEN

            -- Reset all interface registers
            IF ARESETN = '0' THEN
                triangleTest_state <= WAIT_FOR_SETUP;
                triangle_reg <= triangleArray_t_zero;
                C5_reg <= vertexArray_t_zero;
                C6_reg <= vertexArray_t_zero;
                C7_reg <= (OTHERS => (OTHERS => '0'));
                C8_reg <= (OTHERS => (OTHERS => '0'));
                start_Area_reg <= (OTHERS => '0');
                start_direction_reg <= '0';

            ELSE

                CASE triangleTest_state IS

                        -- Wait here until we receive a new triangle (with setup information)
                    WHEN WAIT_FOR_SETUP =>
                        IF (setup_in_valid = '1') THEN
                            triangle_reg <= triangle_in;
                            C5_reg <= C5;
                            C6_reg <= C6;
                            start_Area_reg <= Area;
                            start_direction_reg <= direction;
                            triangleTest_state <= WAIT_FOR_START_CMD;
                        END IF;

                    WHEN WAIT_FOR_START_CMD =>

                        IF (fragment_out_ready = '1') THEN

                            -- Grab (and sign extend) the integer component of the area change for each line
                            FOR i IN 0 TO 2 LOOP
                                C7_reg(i) <= resize(C7_wire(i)(31 DOWNTO 16), 24);
                                C8_reg(i) <= resize(C8_wire(i)(31 DOWNTO 16), 24);
                            END LOOP;

                            IF (command_in = START_CMD) THEN
                                triangleTest_state <= WAIT_FOR_DONE_CMD;
                            END IF;

                        END IF;

                    WHEN WAIT_FOR_DONE_CMD =>

                        IF (fragment_out_ready = '1') THEN
                            IF (command_in = DONE_CMD) THEN
                                triangleTest_state <= WAIT_FOR_SETUP;
                            END IF;
                        END IF;

                END CASE;

            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE behavioral;