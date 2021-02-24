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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library WORK;
use WORK.sgp_types.all;


entity triangleTraversal_core is

	port (ACLK	    : in	std_logic;
		  ARESETN	: in	std_logic;

          -- AXIS-style triangle setup inputs
          boundingbox                   : in   boundingboxRecord_t;          
          startposition                 : in   attributeRecord_t; -- Just need the x/y information to traverse the triangle
          setup_in_ready 				: out  std_logic;
          setup_in_valid 				: in   std_logic;

          -- Asynchronous command-out, synchronous results in
		  command_out		            : out  traversal_cmds_t;
          fragment_out_valid            : in   std_logic;
          fragment_test_result          : in   std_logic;
          
          -- Status out
           status_out                   : out  std_logic
          
);


end triangleTraversal_core;


architecture behavioral of triangleTraversal_core is



    type STATE_TYPE is (WAIT_FOR_SETUP, TRAVERSAL_DONE, MOVE_NONE_IN, MOVE_RIGHT_IN, MOVE_LEFT_IN, PUSH_MOVE_DOWN, POP_MOVE_LEFT_IN, POP_MOVE_RIGHT_IN, MOVE_LEFT_OUT, MOVE_RIGHT_OUT, POP_MOVE_RIGHT_OUT, POP_MOVE_LEFT_OUT);
    signal triangleTraversal_state        : STATE_TYPE;
    attribute fsm_encoding : string;
    attribute fsm_encoding of triangleTraversal_state : signal is "one_hot";


    -- Design registers and remapping signals
    signal start_position_reg                    : attributeRecord_t;
    signal boundingbox_reg                       : boundingboxRecord_t;
    signal current_position_reg                  : attributeRecord_t;
    signal linestart_position_reg                : attributeRecord_t;
    signal linestart_testresult_reg              : std_logic;
    signal linestart_direction_reg               : std_logic;

begin

    -- 
    status_out <= status_idle when triangleTraversal_state = WAIT_FOR_SETUP else
                  status_busy;

    setup_in_ready <= '1' when triangleTraversal_state = WAIT_FOR_SETUP else '0';

    -- Traversal commands
    command_out <= CMD_NONE                 when triangleTraversal_state = WAIT_FOR_SETUP else
                   START_CMD                when triangleTraversal_state = MOVE_NONE_IN else
                   MOVE_RIGHT_CMD           when triangleTraversal_state = MOVE_RIGHT_IN else
                   MOVE_LEFT_CMD            when triangleTraversal_state = MOVE_LEFT_IN else
                   PUSH_MOVE_DOWN_CMD       when triangleTraversal_state = PUSH_MOVE_DOWN else
                   POP_MOVE_LEFT_CMD        when triangleTraversal_state = POP_MOVE_LEFT_IN else
                   POP_MOVE_RIGHT_CMD       when triangleTraversal_state = POP_MOVE_RIGHT_IN else
                   MOVE_LEFT_CMD            when triangleTraversal_state = MOVE_LEFT_OUT else
                   MOVE_RIGHT_CMD           when triangleTraversal_state = MOVE_RIGHT_OUT else
                   POP_MOVE_RIGHT_CMD       when triangleTraversal_state = POP_MOVE_RIGHT_OUT else
                   POP_MOVE_LEFT_CMD        when triangleTraversal_state = POP_MOVE_LEFT_OUT else
                   DONE_CMD                 when triangleTraversal_state = TRAVERSAL_DONE else
                   CMD_NONE;


   process (ACLK) is
   begin 
    if rising_edge(ACLK) then  

      -- Reset all interface registers
      if ARESETN = '0' then    
            triangleTraversal_state <= WAIT_FOR_SETUP;
            start_position_reg       <= attributeRecord_t_zero;
            boundingbox_reg          <= boundingboxRecord_t_zero;
            current_position_reg     <= attributeRecord_t_zero;
            linestart_position_reg   <= attributeRecord_t_zero;
            linestart_testresult_reg <= testresult_out;
            linestart_direction_reg  <= direction_right;
      else

        case triangleTraversal_state is

            -- Wait here until we receive a new triangle (with some setup information)
            when WAIT_FOR_SETUP =>
                if (setup_in_valid = '1') then                    
                    boundingbox_reg <= boundingbox;
                    start_position_reg <= startposition;
                    triangleTraversal_state <= MOVE_NONE_IN;
                end if;

            -- MOVE_NONE_IN. For the top of the triangle only. We always have an in fragment here, but it's ok to check
            when MOVE_NONE_IN =>
                current_position_reg     <= start_position_reg;
                linestart_position_reg   <= start_position_reg;
                linestart_direction_reg  <= direction_right;
                linestart_testresult_reg <= testresult_in;
                if (fragment_out_valid = '1') then -- We should always check if there was fragment_out backpressure
                    if (fragment_test_result = testresult_in) then
                        triangleTraversal_state <= MOVE_RIGHT_IN;
                    end if;
                end if;


            -- MOVE_RIGHT_IN. If our fragment is in, keep on going. Otherwise if we've hit an edge or are out we should
            -- either pop back and head back left or head down
            when MOVE_RIGHT_IN =>
                if (fragment_out_valid = '1') then
                    current_position_reg.x <= current_position_reg.x + fixed_t_one;
                    if ((fragment_test_result = testresult_out) or ((current_position_reg.x+fixed_t_one) > boundingbox_reg.xmax)) then

                        -- We started in this direction, we should head in the other direction before moving down
                        if (linestart_direction_reg = direction_right) then
                            if (linestart_testresult_reg = testresult_in) then
                                triangleTraversal_state <= POP_MOVE_LEFT_IN;
                            else
                                triangleTraversal_state <= POP_MOVE_LEFT_OUT;
                            end if;

                        -- Otherwise, we're done with this line
                        else
                            triangleTraversal_state <= PUSH_MOVE_DOWN;
                        end if;
                    else
                        triangleTraversal_state <= MOVE_RIGHT_IN;                
                    end if;
                end if;
                

            -- MOVE_LEFT_IN. If our fragment is in, keep on going. Otherwise if we've hit an edge or are out we should
            -- either pop back and head back left or head down
            when MOVE_LEFT_IN =>
                if (fragment_out_valid = '1') then
                    current_position_reg.x <= current_position_reg.x - fixed_t_one;
                    if ((fragment_test_result = testresult_out) or ((current_position_reg.x-fixed_t_one) < boundingbox_reg.xmin)) then

                        -- We started in this direction, we should head in the other direction before moving down
                        if (linestart_direction_reg = direction_left) then
                            if (linestart_testresult_reg = testresult_in) then
                                triangleTraversal_state <= POP_MOVE_RIGHT_IN;
                            else
                                triangleTraversal_state <= POP_MOVE_RIGHT_OUT;
                            end if;

                        -- Otherwise, we're done with this line
                        else
                            triangleTraversal_state <= PUSH_MOVE_DOWN;
                        end if;
                        
                    end if;
                end if;



            -- POP_MOVE_LEFT_IN. This is the backhalf of the linescan, so once we're out, we move down
            when POP_MOVE_LEFT_IN =>
                if (fragment_out_valid = '1') then
                    current_position_reg.x <= linestart_position_reg.x - fixed_t_one;
                    current_position_reg.y <= linestart_position_reg.y;
                    -- If we're out, we're done with this line
                    if ((fragment_test_result = testresult_out) or ((linestart_position_reg.x-fixed_t_one) < boundingbox_reg.xmin)) then
                        triangleTraversal_state <= PUSH_MOVE_DOWN;
                    else
                        triangleTraversal_state <= MOVE_LEFT_IN;                
                    end if;
                end if;


            -- POP_MOVE_RIGHT_IN. This is the backhalf of the linescan, so once we're out, we move down



            -- PUSH_MOVE_DOWN. Move down one pixel and store this as the beginning of the line
            when PUSH_MOVE_DOWN =>
                if (fragment_out_valid = '1') then
                    linestart_position_reg.x <= current_position_reg.x; 
                    linestart_position_reg.y <= current_position_reg.y - fixed_t_one; 
                    current_position_reg.y   <= current_position_reg.y - fixed_t_one; 
                    linestart_testresult_reg <= fragment_test_result;

                    -- After moving down are we out? If so, we only need to check the other direction.
                    --if (fragment_test_result = testresult_out) then 

                    -- After moving down, are we in? Keep going in the direction we are in
                    --else

                    -- Separately, this is an appropriate time to check if we are completely done.
                    if ((current_position_reg.y - fixed_t_one) < boundingbox_reg.ymin) then
                        triangleTraversal_state <= TRAVERSAL_DONE;
                    end if;

                end if;

             -- MOVE_RIGHT_OUT. Keep moving right until we go back into the triangle or hit the bounding box
                
             -- MOVE_LEFT_OUT. Keep moving left until we go back into the triangle or hit the bounding box
    

            -- POP_MOVE_RIGHT_OUT. 

    
            -- POP_MOVE_LEFT_OUT.
												

             when TRAVERSAL_DONE =>
                if (fragment_out_valid = '1') then
                    triangleTraversal_state <= WAIT_FOR_SETUP;
                end if;


             -- This shouldn't happen
             when others =>
                triangleTraversal_state <= WAIT_FOR_SETUP;


        end case;

      end if;
    end if;
   end process;
end architecture behavioral;
