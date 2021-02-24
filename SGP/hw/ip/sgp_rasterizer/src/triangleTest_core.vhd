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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library WORK;
use WORK.sgp_types.all;


entity triangleTest_core is

	port (ACLK	    : in	std_logic;
		  ARESETN	: in	std_logic;

          -- AXIS-style triangle setup inputs
          Area                          : in   signed(23 downto 0); 
          direction                     : in   std_logic;
          C5                            : in   vertexArray_t;  -- Our x-dim linear interpolation for all attributes
          C6                            : in   vertexArray_t;  -- Our y-dim linear interpolation for all attributes
          triangle_in                   : in   triangleArray_t; -- Potentially re-ordered vertices
          setup_in_ready 				: out 	std_logic;
          setup_in_valid 				: in 	std_logic;
        
          -- Asynchronous command stream
		  command_in		            : in	traversal_cmds_t;
          fragment_test_result          : out   std_logic;

          -- AXIS-style fragment output
		  fragment_out_ready		    : in	std_logic;
		  fragment_out_valid 			: out 	std_logic; 
          fragment_out                  : out    vertexArray_t

);


end triangleTest_core;


architecture behavioral of triangleTest_core is


    type STATE_TYPE is (WAIT_FOR_SETUP, WAIT_FOR_START_CMD, WAIT_FOR_DONE_CMD);
    signal triangleTest_state        : STATE_TYPE;



    -- Design registers and remapping signals
    signal triangle_reg                     : triangleArray_t;
    signal V0_array, V1_array, V2_array     : vertexArray_t;
    signal C5_reg, C6_reg                   : vertexArray_t;
    signal start_Area_reg                   : signed(23 downto 0);
    signal start_direction_reg              : std_logic;
    signal in_vals                          : std_logic_vector(2 downto 0);



    -- C7, C8 for updating the areas of the three lines. These values are fixed per-triangle. 
    -- Note, we have to be consistent with what each index means for these 3-length arrays:
    -- [0] - line from {V0-V1}
    -- [1] - line from {V1-V2}
    -- [2] - line from {V2-V0}
    type lineArray_t is array (2 downto 0) of fixed_t;
    type lineAreaArray_t is array (2 downto 0) of signed(23 downto 0);
    signal C7_wire : lineArray_t;
    signal C8_wire : lineArray_t;
    signal C7_reg  : lineAreaArray_t;
    signal C8_reg  : lineAreaArray_t;

    -- Area, direction, and attribute values for the triangles formed by the lines and a new point. We are being a little verbose here to simplify the stack/store
    -- logic below
    signal Area_line_nextreg, Area_line_reg, Area_line_nextstack, Area_line_stack         : lineAreaArray_t;
    signal newfragment_nextreg, newfragment_reg, newfragment_nextstack, newfragment_stack : vertexArray_t;


begin

   -- Remap the triangle to the vertexArray and vertexRecord data structure so we can access elements easily
   V0_array <= to_vertexArray_t(triangle_reg(0));
   V1_array <= to_vertexArray_t(triangle_reg(1));
   V2_array <= to_vertexArray_t(triangle_reg(2));


   setup_in_ready <= '1' when triangleTest_state = WAIT_FOR_SETUP else '0';

    -- Our fragment is in if the direction of the point relative to all three lines is the same as our triangle's starting direction. 
    -- We can check the sign bits of the Area_line wire to confirm (also consider A=0 to be in)
    G1: for i in 2 downto 0 generate
        in_vals(i) <= testresult_in when Area_line_nextreg(i) = 0 else
                      testresult_in when Area_line_nextreg(i)(Area_line_nextreg(i)'high) = start_direction_reg else
                      testresult_out;
    end generate;
    fragment_test_result <= testresult_in when in_vals="111" else
                            testresult_out;
    
    -- We're using fragment_out_valid as backpressure on triangleTraversal
    fragment_out <= newfragment_nextreg when triangleTest_state = WAIT_FOR_DONE_CMD else vertexArray_t_zero;
    fragment_out_valid <= fragment_out_ready when ((triangleTest_state = WAIT_FOR_DONE_CMD)) else '0';
 

	-- Process commmands as they come in and update Area, direction, and the fragment itself. Note, this is a combinational process so be careful with the
	-- sensitivity list (process(all) not supported yet in V2020.1)
	process(command_in, Area_line_reg, Area_line_stack, newfragment_reg, newfragment_stack, start_Area_reg, V0_array, C5_reg, C6_reg, C7_reg, C8_reg)
	begin
        -- Default signal assignment. Best to avoid latches.
        Area_line_nextreg <= Area_line_reg;
        Area_line_nextstack <= Area_line_stack;
        newfragment_nextreg <= newfragment_reg;
        newfragment_nextstack <= newfragment_stack;

        case command_in is
            when START_CMD =>
                Area_line_nextreg   <= (0 => (others => '0'), 1 => start_Area_reg, 2 => (others => '0'));
                Area_line_nextstack <= (0 => (others => '0'), 1 => start_Area_reg, 2 => (others => '0')); 
                newfragment_nextreg <= V0_array;
                newfragment_nextstack <= V0_array;

            -- When we pop and move left, we should wind up 1 pixel to the left of what is stored on our stack. 
            -- Move all values 1 interpolated amount in -x dimension (-C5, -C7)
            when POP_MOVE_LEFT_CMD =>
                for i in 0 to 2 loop
                    Area_line_nextreg(i)  <= Area_line_stack(i) - C7_reg(i);
                end loop;
                for i in 0 to C_SGP_NUM_VERTEX_ATTRIB-1 loop
                    for j in 0 to C_SGP_VERTEX_ATTRIB_SIZE-1 loop
                        newfragment_nextreg(i)(j) <= newfragment_stack(i)(j) - C5_reg(i)(j);
                    end loop;
                end loop;

            -- When we pop and move right, we should wind up 1 pixel to the right of what is stored on our stack. 
            -- Move all values 1 interpolated amount in +x dimension (+C5, +C7)
            when POP_MOVE_RIGHT_CMD =>

            -- When moving right, move all values 1 interpolated amount in +x dimension (+C5, +C7)
            when MOVE_RIGHT_CMD =>

            when MOVE_LEFT_CMD =>

            -- When moving down, we should wind up 1 pixel below where we currently are. 
            -- Move all values 1 interpolated amount in -y dimension (-C6, -C8)               
            when PUSH_MOVE_DOWN_CMD =>

            when others =>

        end case;
	end process;


    -- Calculate the area change for +x, +y. We will convert down to Area signed int format in the register
    -- [0] - line from {V0-V1}
    -- [1] - line from {V1-V2}
    -- [2] - line from {V2-V0}
    C7_wire(0) <= V0_array(0)(1) - V1_array(0)(1); 
    C7_wire(1) <= V1_array(0)(1) - V2_array(0)(1);
    C7_wire(2) <= V2_array(0)(1) - V0_array(0)(1);
    C8_wire(0) <= V1_array(0)(0) - V0_array(0)(0);  -- (x_1 - x_0)
    C8_wire(1) <= V2_array(0)(0) - V1_array(0)(0);  
    C8_wire(2) <= V0_array(0)(0) - V2_array(0)(0);



    -- This process sets the internal registers for the design.
    process(ACLK) is
    begin
        if rising_edge(ACLK) then
            if ARESETN = '0' then
                Area_line_reg   <= (others => (others => '0'));               
                Area_line_stack <= (others => (others => '0'));               
                newfragment_reg <= vertexArray_t_zero;
                newfragment_stack <= vertexArray_t_zero;

            else
                if (fragment_out_ready = '1') then
                    Area_line_reg <= Area_line_nextreg;
                    Area_line_stack <= Area_line_nextstack;
                    newfragment_reg <= newfragment_nextreg;
                    newfragment_stack <= newfragment_nextstack;
                end if;

            end if;
        end if;
    end process;



   process (ACLK) is
   begin 
        if rising_edge(ACLK) then  

        -- Reset all interface registers
        if ARESETN = '0' then    
                triangleTest_state <= WAIT_FOR_SETUP;
                triangle_reg <= triangleArray_t_zero;
                C5_reg <= vertexArray_t_zero;
                C6_reg <= vertexArray_t_zero;
                C7_reg <= (others => (others => '0'));                
                C8_reg <= (others => (others => '0')); 
                start_Area_reg <= (others => '0');
                start_direction_reg <= '0';
            
          else

            case triangleTest_state is
    
            -- Wait here until we receive a new triangle (with setup information)
            when WAIT_FOR_SETUP =>
                if (setup_in_valid = '1') then                    
                    triangle_reg <= triangle_in;
                    C5_reg <= C5;
                    C6_reg <= C6;
                    start_Area_reg <= Area;
                    start_direction_reg <= direction;
                    triangleTest_state <= WAIT_FOR_START_CMD;
                end if;

            when WAIT_FOR_START_CMD =>

                if (fragment_out_ready = '1') then

                    -- Grab (and sign extend) the integer component of the area change for each line
                    for i in 0 to 2 loop
                        C7_reg(i) <= resize(C7_wire(i)(31 downto 16), 24);
                        C8_reg(i) <= resize(C8_wire(i)(31 downto 16), 24);
                    end loop;

                    if (command_in = START_CMD) then
                        triangleTest_state <= WAIT_FOR_DONE_CMD;
                    end if;

                end if;

             when WAIT_FOR_DONE_CMD =>
             
                if (fragment_out_ready = '1') then 
                    if (command_in = DONE_CMD) then
                        triangleTest_state <= WAIT_FOR_SETUP;
                    end if;
                end if;
                
        end case;

      end if;
    end if;
   end process;
end architecture behavioral;
