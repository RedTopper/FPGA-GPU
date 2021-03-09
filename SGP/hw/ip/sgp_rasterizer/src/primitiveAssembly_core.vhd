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

          --Dictate if this is the final vertex or not.
          vertex_in_final             : in     std_logic:='0';
        
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


    type STATE_TYPE is (WAIT_FOR_VERTEX0, WAIT_FOR_VERTEX1, WAIT_FOR_VERTEX2, PRIM_WRITE, READ_FANA, READ_FANB, READ_STRIP);
    signal primitiveAssembly_state        : STATE_TYPE;
    
   
    -- Registers to store vertex data (needed for some primitive types)
    signal V0_reg, V1_reg, V2_reg : vertexVector_t;
    signal vertexReplace : integer range 0 to 2;
    signal finishedFlag : std_logic;

begin


   -- We are ready when waiting for a vertex and can output data
   vertex_in_ready <= primout_ready when primitiveAssembly_state = WAIT_FOR_VERTEX0 else
                      primout_ready when primitiveAssembly_state = WAIT_FOR_VERTEX1 else
                      primout_ready when primitiveAssembly_state = WAIT_FOR_VERTEX2 else
                      primout_ready when primitiveAssembly_state = READ_FANA else
                      primout_ready when primitiveAssembly_state = READ_FANB else
                      primout_ready when primitiveAssembly_state = READ_STRIP else
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
            V0_reg <= vertexVector_t_zero;
            V1_reg <= vertexVector_t_zero;
            V2_reg <= vertexVector_t_zero;
            vertexReplace <= 2;
            finishedFlag <= '0';
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
                    if(vertex_in_final  = '1')then
                        finishedFlag <= '1';
                    end if;
                    V2_reg <= vertex_in;
                    -- Modifying this to support other primitive types would be very straightforward.
                    primitiveAssembly_state <= PRIM_WRITE;
                end if; 
            
            when READ_STRIP =>
                if ((vertex_valid = '1') and (primout_ready = '1')) then
                    if(vertex_in_final  = '1')then
                        finishedFlag <= '1';
                    end if;

                    if(vertexReplace = 0)then
                        V0_reg <= vertex_in;
                    elsif(vertexReplace = 1)then
                        V1_reg <= vertex_in;
                    elsif(vertexReplace = 2)then
                        V2_reg <= vertex_in;
                    else
                        --uh oh
                    end if;
                    primitiveAssembly_state <= PRIM_WRITE;
                end if;

            when READ_FANA =>
                if ((vertex_valid = '1') and (primout_ready = '1')) then
                    V1_reg <= vertex_in;
                    primitiveAssembly_state <= READ_FANB;
                end if;

            when READ_FANB =>
                if ((vertex_valid = '1') and (primout_ready = '1')) then
                    if(vertex_in_final  = '1')then
                        finishedFlag <= '1';
                    end if;

                    V2_reg <= vertex_in;
                    primitiveAssembly_state <= PRIM_WRITE;
                end if;

            when PRIM_WRITE => 
                if (primout_ready = '1') then
                    if(finishedFlag = '1')then
                        finishedFlag <='0';
                        vertexReplace <= 0;
                        primitiveAssembly_state <= WAIT_FOR_VERTEX0;
                    elsif(primtype = SGP_GL_TRIANGLE_STRIP) then
                        primitiveAssembly_state <= READ_STRIP;
                        if((vertexReplace + 1) = 3)then
                            vertexReplace <= 0;
                        else
                         vertexReplace <= vertexReplace + 1;
                        end if;
                    elsif(primtype = SGP_GL_TRIANGLE_FAN)then
                        primitiveAssembly_state <= READ_FANA;
                    else
                        primitiveAssembly_state <= WAIT_FOR_VERTEX0;
                    end if;
                end if;
                
        end case;

      end if;
    end if;
   end process;
end architecture behavioral;
