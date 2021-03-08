-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- triangleTraversal_core.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a the triangle 
-- traversal logic of the Steffen rasterization algorithm.
--
-- NOTES:
-- 12/07/20 by JAZ::Design created.
-------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
LIBRARY WORK;
USE WORK.sgp_types.ALL;
ENTITY triangleTraversal_core IS

    PORT (
        ACLK : IN STD_LOGIC;
        ARESETN : IN STD_LOGIC;

        -- AXIS-style triangle setup inputs
        boundingbox : IN boundingboxRecord_t;
        startposition : IN attributeRecord_t; -- Just need the x/y information to traverse the triangle
        setup_in_ready : OUT STD_LOGIC;
        setup_in_valid : IN STD_LOGIC;

        -- Asynchronous command-out, synchronous results in
        command_out : OUT traversal_cmds_t;
        fragment_out_valid : IN STD_LOGIC;
        fragment_test_result : IN STD_LOGIC;

        -- Status out
        status_out : OUT STD_LOGIC

    );
END triangleTraversal_core;
ARCHITECTURE behavioral OF triangleTraversal_core IS

    TYPE STATE_TYPE IS (WAIT_FOR_SETUP, TRAVERSAL_DONE, MOVE_NONE_IN, MOVE_RIGHT_IN, MOVE_LEFT_IN, PUSH_MOVE_DOWN, POP_MOVE_LEFT_IN, POP_MOVE_RIGHT_IN, MOVE_LEFT_OUT, MOVE_RIGHT_OUT, POP_MOVE_RIGHT_OUT, POP_MOVE_LEFT_OUT);
    SIGNAL triangleTraversal_state : STATE_TYPE;
    ATTRIBUTE fsm_encoding : STRING;
    ATTRIBUTE fsm_encoding OF triangleTraversal_state : SIGNAL IS "one_hot";
    -- Design registers and remapping signals
    SIGNAL start_position_reg : attributeRecord_t;
    SIGNAL boundingbox_reg : boundingboxRecord_t;
    SIGNAL current_position_reg : attributeRecord_t;
    SIGNAL linestart_position_reg : attributeRecord_t;
    SIGNAL linestart_testresult_reg : STD_LOGIC;
    SIGNAL linestart_direction_reg : STD_LOGIC;
    signal SeenTheLight : STD_LOGIC;

BEGIN

    -- 
    status_out <= status_idle WHEN triangleTraversal_state = WAIT_FOR_SETUP ELSE
        status_busy;

    setup_in_ready <= '1' WHEN triangleTraversal_state = WAIT_FOR_SETUP ELSE
        '0';

    -- Traversal commands
    command_out <= CMD_NONE WHEN triangleTraversal_state = WAIT_FOR_SETUP ELSE
        START_CMD WHEN triangleTraversal_state = MOVE_NONE_IN ELSE
        MOVE_RIGHT_CMD WHEN triangleTraversal_state = MOVE_RIGHT_IN ELSE
        MOVE_LEFT_CMD WHEN triangleTraversal_state = MOVE_LEFT_IN ELSE
        PUSH_MOVE_DOWN_CMD WHEN triangleTraversal_state = PUSH_MOVE_DOWN ELSE
        POP_MOVE_LEFT_CMD WHEN triangleTraversal_state = POP_MOVE_LEFT_IN ELSE
        POP_MOVE_RIGHT_CMD WHEN triangleTraversal_state = POP_MOVE_RIGHT_IN ELSE
        MOVE_LEFT_CMD WHEN triangleTraversal_state = MOVE_LEFT_OUT ELSE
        MOVE_RIGHT_CMD WHEN triangleTraversal_state = MOVE_RIGHT_OUT ELSE
        POP_MOVE_RIGHT_CMD WHEN triangleTraversal_state = POP_MOVE_RIGHT_OUT ELSE
        POP_MOVE_LEFT_CMD WHEN triangleTraversal_state = POP_MOVE_LEFT_OUT ELSE
        DONE_CMD WHEN triangleTraversal_state = TRAVERSAL_DONE ELSE
        CMD_NONE;
    PROCESS (ACLK) IS
    BEGIN
        IF rising_edge(ACLK) THEN

            -- Reset all interface registers
            IF ARESETN = '0' THEN
                triangleTraversal_state <= WAIT_FOR_SETUP;
                start_position_reg <= attributeRecord_t_zero;
                boundingbox_reg <= boundingboxRecord_t_zero;
                current_position_reg <= attributeRecord_t_zero;
                linestart_position_reg <= attributeRecord_t_zero;
                linestart_testresult_reg <= testresult_out;
                linestart_direction_reg <= direction_right;
            ELSE

                CASE triangleTraversal_state IS

                        -- Wait here until we receive a new triangle (with some setup information)
                    WHEN WAIT_FOR_SETUP =>
                        IF (setup_in_valid = '1') THEN
                            boundingbox_reg <= boundingbox;
                            start_position_reg <= startposition;
                            triangleTraversal_state <= MOVE_NONE_IN;
                        END IF;

                        -- MOVE_NONE_IN. For the top of the triangle only. We always have an in fragment here, but it's ok to check
                    WHEN MOVE_NONE_IN =>
                        current_position_reg <= start_position_reg;
                        linestart_position_reg <= start_position_reg;
                        linestart_direction_reg <= direction_right;
                        linestart_testresult_reg <= testresult_in;
                        IF (fragment_out_valid = '1') THEN -- We should always check if there was fragment_out backpressure
                            IF (fragment_test_result = testresult_in) THEN
                                triangleTraversal_state <= MOVE_RIGHT_IN;
                            END IF;
                        END IF;
                        -- MOVE_RIGHT_IN. If our fragment is in, keep on going. Otherwise if we've hit an edge or are out we should
                        -- either pop back and head back left or head down
                    WHEN MOVE_RIGHT_IN =>
                        IF (fragment_out_valid = '1') THEN
                            SeenTheLight <= '1';
                            current_position_reg.x <= current_position_reg.x + fixed_t_one;
                            IF ((fragment_test_result = testresult_out) OR ((current_position_reg.x + fixed_t_one) > boundingbox_reg.xmax)) THEN

                                -- We started in this direction, we should head in the other direction before moving down
                                IF (linestart_direction_reg = direction_right) THEN
                                    IF (linestart_testresult_reg = testresult_in) THEN
                                        triangleTraversal_state <= POP_MOVE_LEFT_IN;
                                    ELSE
                                        triangleTraversal_state <= POP_MOVE_LEFT_OUT;
                                    END IF;

                                    -- Otherwise, we're done with this line
                                ELSE
                                    linestart_direction_reg <= direction_right;
                                    triangleTraversal_state <= PUSH_MOVE_DOWN;
                                END IF;
                            ELSE
                                triangleTraversal_state <= MOVE_RIGHT_IN;
                            END IF;
                        END IF;
                        -- MOVE_LEFT_IN. If our fragment is in, keep on going. Otherwise if we've hit an edge or are out we should
                        -- either pop back and head back left or head down
                    WHEN MOVE_LEFT_IN =>
                        IF (fragment_out_valid = '1') THEN
                            SeenTheLight <= '1';
                            current_position_reg.x <= current_position_reg.x - fixed_t_one;
                            IF ((fragment_test_result = testresult_out) OR ((current_position_reg.x - fixed_t_one) < boundingbox_reg.xmin)) THEN

                                -- We started in this direction, we should head in the other direction before moving down
                                IF (linestart_direction_reg = direction_left) THEN
                                    IF (linestart_testresult_reg = testresult_in) THEN
                                        triangleTraversal_state <= POP_MOVE_RIGHT_IN;
                                    ELSE
                                        triangleTraversal_state <= POP_MOVE_RIGHT_OUT;
                                    END IF;

                                    -- Otherwise, we're done with this line
                                ELSE
                                    linestart_direction_reg <= direction_left;
                                    triangleTraversal_state <= PUSH_MOVE_DOWN;
                                END IF;

                            END IF;
                        END IF;

                        -- POP_MOVE_LEFT_IN. This is the backhalf of the linescan, so once we're out, we move down
                    WHEN POP_MOVE_LEFT_IN =>
                        IF (fragment_out_valid = '1') THEN
                            current_position_reg.x <= linestart_position_reg.x - fixed_t_one;
                            current_position_reg.y <= linestart_position_reg.y;
                            -- If we're out, we're done with this line
                            IF ((fragment_test_result = testresult_out) OR ((linestart_position_reg.x - fixed_t_one) < boundingbox_reg.xmin)) THEN
                                linestart_direction_reg <= direction_left;
                                triangleTraversal_state <= PUSH_MOVE_DOWN;
                            ELSE
                                triangleTraversal_state <= MOVE_LEFT_IN;
                            END IF;
                        END IF;
                        -- POP_MOVE_RIGHT_IN. This is the backhalf of the linescan, so once we're out, we move down
                    WHEN POP_MOVE_RIGHT_IN =>
                        IF (fragment_out_valid = '1') THEN
                            current_position_reg.x <= linestart_position_reg.x + fixed_t_one;
                            current_position_reg.y <= linestart_position_reg.y;
                            -- If we're out, we're done with this line
                            IF ((fragment_test_result = testresult_out) OR ((linestart_position_reg.x + fixed_t_one) < boundingbox_reg.xmin)) THEN
                                linestart_direction_reg <= direction_right;
                                triangleTraversal_state <= PUSH_MOVE_DOWN;
                            ELSE
                                triangleTraversal_state <= MOVE_RIGHT_IN;
                            END IF;
                        END IF;

                        -- PUSH_MOVE_DOWN. Move down one pixel and store this as the beginning of the line
                    WHEN PUSH_MOVE_DOWN =>
                        IF (fragment_out_valid = '1') THEN
                            SeenTheLight <= '0';
                            linestart_position_reg.x <= current_position_reg.x;
                            linestart_position_reg.y <= current_position_reg.y - fixed_t_one;
                            current_position_reg.y <= current_position_reg.y - fixed_t_one;
                            linestart_testresult_reg <= fragment_test_result;

                            IF ((current_position_reg.y - fixed_t_one) < boundingbox_reg.ymin) THEN
                                -- This is an appropriate time to check if we are completely done.
                                triangleTraversal_state <= TRAVERSAL_DONE;
                            ELSIF (fragment_test_result = testresult_out) THEN
                                IF (linestart_direction_reg = direction_right) THEN
                                    triangleTraversal_state <= MOVE_LEFT_OUT;
                                ELSE
                                    triangleTraversal_state <= MOVE_RIGHT_OUT;
                                END IF;
                                -- After moving down, are we in? Keep going in the direction we are in
                            ELSE
                                IF (linestart_direction_reg = direction_right) THEN
                                    triangleTraversal_state <= MOVE_RIGHT_IN;
                                ELSE
                                    triangleTraversal_state <= MOVE_LEFT_IN;
                                END IF;
                            END IF;
                        END IF;

                        -- MOVE_RIGHT_OUT. Keep moving right until we go back into the triangle or hit the bounding box
                    WHEN MOVE_RIGHT_OUT =>
                        IF (fragment_out_valid = '1') THEN
                            current_position_reg.x <= current_position_reg.x + fixed_t_one;
                            IF (fragment_test_result = testresult_in) THEN
                                triangleTraversal_state <= MOVE_RIGHT_IN;
                            ELSIF ((current_position_reg.x + fixed_t_one) > boundingbox_reg.xmax) THEN
                                IF (linestart_direction_reg = direction_left and SeenTheLight = '1') THEN
                                    triangleTraversal_state <= PUSH_MOVE_DOWN;
                                    linestart_direction_reg <= direction_right;
                                 ELSE
                                    triangleTraversal_state <= POP_MOVE_LEFT_OUT;
                                 END IF;
                            END IF;
                        END IF;

                        -- MOVE_LEFT_OUT. Keep moving left until we go back into the triangle or hit the bounding box
                    WHEN MOVE_LEFT_OUT =>
                        IF (fragment_out_valid = '1') THEN
                            current_position_reg.x <= current_position_reg.x - fixed_t_one;
                            IF (fragment_test_result = testresult_in) THEN
                                triangleTraversal_state <= MOVE_LEFT_IN;
                            ELSIF ((current_position_reg.x - fixed_t_one) < boundingbox_reg.xmin) THEN
                                IF (linestart_direction_reg = direction_right  and SeenTheLight = '1') THEN
                                    triangleTraversal_state <= PUSH_MOVE_DOWN;
                                    linestart_direction_reg <= direction_left;
                                ELSE
                                    triangleTraversal_state <= POP_MOVE_RIGHT_OUT;
                                END IF;
                            END IF;
                        END IF;

                        -- POP_MOVE_RIGHT_OUT.  Pop, then move by one. If we are inside the triangle it's time to move in, otherwise move out
                        -- Note it is impossible to hit the bounding box on this side, as the only way to get here is by hitting the left bounding box
                        --Hitting the bounding box would imply that there is no triangle
                    WHEN POP_MOVE_RIGHT_OUT =>
                        IF (fragment_out_valid = '1') THEN
                            current_position_reg.x <= linestart_position_reg.x + fixed_t_one;
                            current_position_reg.y <= linestart_position_reg.y;
                            IF (fragment_test_result = testresult_in) THEN
                                triangleTraversal_state <= MOVE_RIGHT_IN;
                            ELSE
                                triangleTraversal_state <= MOVE_RIGHT_OUT;
                            END IF;
                        END IF;

                        -- POP_MOVE_LEFT_OUT. TODO
                    WHEN POP_MOVE_LEFT_OUT =>
                        IF (fragment_out_valid = '1') THEN
                            current_position_reg.x <= linestart_position_reg.x - fixed_t_one;
                            current_position_reg.y <= linestart_position_reg.y;
                            IF (fragment_test_result = testresult_in) THEN
                                triangleTraversal_state <= MOVE_LEFT_IN;
                            ELSE
                                triangleTraversal_state <= MOVE_LEFT_OUT;
                            END IF;
                        END IF;

                    WHEN TRAVERSAL_DONE =>
                        IF (fragment_out_valid = '1') THEN
                            triangleTraversal_state <= WAIT_FOR_SETUP;
                        END IF;

                        -- This shouldn't happen
                    WHEN OTHERS =>
                        triangleTraversal_state <= WAIT_FOR_SETUP;
                END CASE;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE behavioral;