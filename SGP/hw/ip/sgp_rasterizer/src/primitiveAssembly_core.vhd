-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- primitiveAssembly_core.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a primitive
-- assembly unit that outputs up to 3 vertices corresponding to a triangle
--
-- NOTES:
-- 12/06/20 by JAZ::Design created.
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library WORK;
use WORK.sgp_types.all;


entity primitiveAssembly_core is

	port (ACLK	: in	std_logic;
		  ARESETN	: in	std_logic;

		  -- Primtive type
          primtype                    : in     primtype_t;
        
          -- AXIS-style vertex input
		  vertex_in_ready		        : out	std_logic;
		  vertex_in					    : in	vertexVector_t;
		  vertex_valid 				    : in 	std_logic; 

          -- AXIS-style vertex outputs
          primout_ready 				: in 	std_logic;
          primout_valid 				: out 	std_logic;
		  V0							: out	vertexVector_t;
		  V1							: out	vertexVector_t;
		  V2							: out	vertexVector_t
);


end primitiveAssembly_core;


architecture behavioral of primitiveAssembly_core is


    type STATE_TYPE is (WAIT_FOR_VERTEX0, WAIT_FOR_VERTEX1, WAIT_FOR_VERTEX2, PRIM_WRITE, ADDITIONAL_VERTICES);
    signal primitiveAssembly_state        : STATE_TYPE;
   
    -- Registers to store vertex data (needed for some primitive types)
    signal V0_reg, V1_reg, V2_reg : vertexVector_t;
    signal vertexReplace : integer range 0 to 2;

begin


   -- We are ready when waiting for a vertex and can output data
   vertex_in_ready <= primout_ready when primitiveAssembly_state = WAIT_FOR_VERTEX0 else
                      primout_ready when primitiveAssembly_state = WAIT_FOR_VERTEX1 else
                      primout_ready when primitiveAssembly_state = WAIT_FOR_VERTEX2 else
                      '0';
                      
   -- We have valid output when we are at the end of a primitive
--   primout_valid <= '1' when primitiveAssembly_state = PRIM_WRITE else
--                 '0';

   -- We have a valid output primitive when we're fetched a whole primitive, or always in passthrough mode (GL_POINTS)
   primout_valid <= '1' when primitiveAssembly_state = PRIM_WRITE else
                    vertex_valid when primtype = SGP_GL_POINTS else
                    '0';



--   V0 <= V0_reg;
   V0 <= vertex_in when primtype = SGP_GL_POINTS else
         V0_reg;


   V1 <= V1_reg;
   V2 <= V2_reg;
   
   process (ACLK) is
   begin 
    if rising_edge(ACLK) then  

      -- Reset all design registers
      if ARESETN = '0' then
            vertexReplace <= 2;
            V0_reg <= vertexVector_t_zero;
            V1_reg <= vertexVector_t_zero;
            V2_reg <= vertexVector_t_zero;
            primitiveAssembly_state <= WAIT_FOR_VERTEX0;
      else

        case primitiveAssembly_state is

            -- Wait here until we receive a vertex
            when WAIT_FOR_VERTEX0 =>
                if ((vertex_valid = '1') and (primout_ready = '1')) then
                    V0_reg <= vertex_in;
                    -- If this was GL_POINTS, we are done, otherwise we have to keep grabbing vertices
                    if (primtype = SGP_GL_POINTS) then
                    --    primitiveAssembly_state <= PRIM_WRITE;
                    else
                        primitiveAssembly_state <= WAIT_FOR_VERTEX1;
                    end if;
                end if; 

            when WAIT_FOR_VERTEX1 =>
                if ((vertex_valid = '1') and (primout_ready = '1')) then
                    V1_reg <= vertex_in;
                    -- Modifying this to support other primitive types would be very straightforward.
                    primitiveAssembly_state <= WAIT_FOR_VERTEX2;
                end if; 

            when WAIT_FOR_VERTEX2 =>
                if ((vertex_valid = '1') and (primout_ready = '1')) then
                    V2_reg <= vertex_in;
                    -- Modifying this to support other primitive types would be very straightforward.
                    primitiveAssembly_state <= PRIM_WRITE;
                end if; 

            when ADDITIONAL_VERTICES =>
                case vertexReplace is
                    when 0 =>
                        V0_reg <= vertex_in;
                    when 1 =>
                        V1_reg <= vertex_in;
                    when 2 =>
                        V2_reg <= vertex_in;
                    when others =>
                end case;
                primitiveAssembly_state <= PRIM_WRITE;
                
            when PRIM_WRITE =>
                if (primout_ready = '1') then
                    primitiveAssembly_state <= WAIT_FOR_VERTEX0;
                end if;
                
                if (primtype = SGP_GL_TRIANGLE_STRIP) then
                    if (vertexReplace = 2) then
                        vertexReplace <= 0;
                    else
                        vertexReplace <= vertexReplace + 1;
                    end if;
                    primitiveAssembly_state <= ADDITIONAL_VERTICES;
                    
                else if (primtype = SGP_GL_TRIANGLE_FAN) then
                    if (vertexReplace = 2) then
                        vertexReplace <= 1;
                    else
                        vertexReplace <= vertexReplace + 1;
                    end if;
                    primitiveAssembly_state <= ADDITIONAL_VERTICES;
                end if;

                -- case primtype is
                --     when SGP_GL_POINTS =>
                --         if (primout_ready = '1') then
                --             primitiveAssembly_state <= WAIT_FOR_VERTEX0;
                --         end if;
                --     when SGP_GL_TRIANGLES =>
                --         if (primout_ready = '1') then
                --             primitiveAssembly_state <= WAIT_FOR_VERTEX0;
                --         end if;
                --     when others =>
                -- end case;
            end if;
        end case;
      end if;
    end if;
   end process;
end architecture behavioral;
