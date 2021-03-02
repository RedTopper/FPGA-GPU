-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- triangleSetup_core.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of the triangle 
-- interpolation setup of the Steffen rasterization algorithm.
--
-- NOTES:
-- 12/06/20 by JAZ::Design created.
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library WORK;
use WORK.sgp_types.all;


entity triangleSetup_core is

	port (ACLK	    : in	std_logic;
		  ARESETN	: in	std_logic;

          -- AXIS-style vertex input
		  triangle_in_ready		        : out	std_logic;
		  triangle_in_valid 			: in 	std_logic; 
          triangle_in                   : in    triangleArray_t;

          -- AXIS-style triangle setup outputs
          boundingbox                   : out   boundingboxRecord_t;          
          Area                          : out   signed(23 downto 0); 
          direction                     : out   std_logic;
          C5                            : out   vertexArray_t;  -- Our x-dim linear interpolation for all attributes
          C6                            : out   vertexArray_t;  -- Our y-dim linear interpolation for all attributes
          triangle_out                  : out   triangleArray_t; -- Potentially re-ordered vertices
          setup_out_ready 				: in 	std_logic;
          setup_out_valid 				: out 	std_logic;
          command_in                    : in    traversal_cmds_t
);


end triangleSetup_core;


architecture behavioral of triangleSetup_core is

    COMPONENT shared_divider
    PORT (
        aclk : IN STD_LOGIC;
        s_axis_divisor_tvalid : IN STD_LOGIC;
        s_axis_divisor_tready : OUT STD_LOGIC;
        s_axis_divisor_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axis_dividend_tvalid : IN STD_LOGIC;
        s_axis_dividend_tready : OUT STD_LOGIC;
        s_axis_dividend_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axis_dout_tvalid : OUT STD_LOGIC;
        m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
      );
    END COMPONENT;


    type STATE_TYPE is (WAIT_FOR_TRIANGLE, CALC_C1, WAIT_FOR_DIVIDER, CALC_C2, CALC_C3, CALC_C4, CALC_C5, CALC_C6, CALC_AREA, CALC_BOUNDINGBOX, REORDER_TRIANGLE, WRITE_SETUP, WAIT_FOR_TRIANGLE_DONE);
    signal triangleSetup_state        : STATE_TYPE;
    attribute fsm_encoding : string;
    attribute fsm_encoding of triangleSetup_state : signal is "one_hot";


    -- Design registers and remapping signals
    signal triangle_reg                     : triangleArray_t;
    signal V0_array, V1_array, V2_array     : vertexArray_t;
    signal V0_record, V1_record, V2_record  : vertexRecord_t;
    signal C1_reg, C4_reg                   : wfixed_t;
    signal C2_reg, C3_reg                   : fixed_t;
    signal C5_reg, C6_reg                   : vertexArray_t;
    signal C5C6_attribute_count             : integer range 0 to C_SGP_NUM_VERTEX_ATTRIB;
    signal C5C6_size_count                  : integer range 0 to C_SGP_VERTEX_ATTRIB_SIZE;
    signal Area_reg                         : signed(23 downto 0);
    signal boundingbox_reg                  : boundingboxRecord_t;
    signal topVertexIndex                   : integer range 0 to 3;
    signal direction_reg                    : std_logic;

    -- Circuit1 signals
    signal In1_wire, In2_wire, In3_wire, In4_wire, In5_wire, In6_wire, In7_wire, In8_wire : fixed_t;
    signal Val1_wire, Val2_wire, Val3_wire, Val4_wire   : fixed_t;
    signal Val1_reg, Val2_reg, Val3_reg, Val4_reg       : fixed_t;
    signal Val5_wire, Val6_wire                         : wfixed_t;
    signal Val5_reg, Val6_reg                           : wfixed_t;
    signal Val7_wire                                    : wfixed_t;
    signal Val7_reg                                     : wfixed_t;
    constant CIRCUIT1_LATENCY                           : integer := 3;
    signal circuit1_state                               : std_logic_vector(CIRCUIT1_LATENCY downto 0);

    -- shared_diviser signals
    signal shared_divider_divisor_tvalid                : std_logic;                      
    signal shared_divider_divisor_tready                : std_logic;                      
    signal shared_divider_divisor_tdata                 : std_logic_vector(31 downto 0);
    signal shared_divider_dividend_tvalid               : std_logic;
    signal shared_divider_dividend_tready               : std_logic;
    signal shared_divider_dout_tvalid                   : std_logic;
    signal shared_divider_dout_tdata                    : std_logic_vector(63 downto 0);


begin



   -- None of this code will make sense without reviewing the algorithm. 
   -- It's important to note that C1, C4 are constant per triangle, and C5, C6 are varying per-attribute. We even
   -- calculate C5 and C6 for x and y even though that should be +1, and +1, mutually. A good value to check for debug
   -- General philosophy: 
   -- 1) add a pipeline register after every level of mults and add/subs to help with timing
   -- 2) Keep 16.16 to 32.32 promotion until output (for C5/C6) and until end (for Area)
   -- 3) Reuse the general (In1-In2)*(In3-In4)-(In5-In6)*(In7-In8) logic as much as possible
   -- 4) Try to keep the design relatively readable. Focus on simple FSMs vs complex pipelines


    -- Divider which is only used for calcluating C4 = 1/C1, so why it is called shared_divider is a bit of a mystery. 
    -- Treats the inputs as 32-bit integers, as we will have trouble managing precision otherwise. Convert back to 32.32
    -- after the divide.
    C4_divider : shared_divider
    PORT MAP (
        aclk => aclk,
        s_axis_divisor_tvalid => shared_divider_divisor_tvalid,
        s_axis_divisor_tready => shared_divider_divisor_tready,
        s_axis_divisor_tdata => shared_divider_divisor_tdata,
        s_axis_dividend_tvalid => shared_divider_dividend_tvalid,
        s_axis_dividend_tready => shared_divider_dividend_tready,
        s_axis_dividend_tdata => x"00000001", -- Signed value of "1" for C4 = 1/C1
        m_axis_dout_tvalid => shared_divider_dout_tvalid,
        m_axis_dout_tdata => shared_divider_dout_tdata
      );

    shared_divider_divisor_tvalid <= '1' when triangleSetup_state = CALC_C4 else '0';
    shared_divider_dividend_tvalid <= '1' when triangleSetup_state = CALC_C4 else '0';
    shared_divider_divisor_tdata <= std_logic_vector(C1_reg(63 downto 32));  -- Grab just the integer aspect of C1 value



   -- Remap back to the vertexArray and vertexRecord data structure so we can access elements easily
   V0_array <= to_vertexArray_t(triangle_reg(0));
   V1_array <= to_vertexArray_t(triangle_reg(1));
   V2_array <= to_vertexArray_t(triangle_reg(2));
   V0_record <= to_vertexRecord_t(triangle_reg(0));
   V1_record <= to_vertexRecord_t(triangle_reg(1));
   V2_record <= to_vertexRecord_t(triangle_reg(2));


   -- Circuit1: calculates (In1-In2)*(In3-In4)-(In5-In6)*(In7-In8), pipelined over three cycles
   Val1_wire <= In1_wire - In2_wire;
   Val2_wire <= In3_wire - In4_wire;
   Val3_wire <= In5_wire - In6_wire;
   Val4_wire <= In7_wire - In8_wire;
   Val5_wire <= Val1_reg * Val2_reg;
   Val6_wire <= Val3_reg * Val4_reg;
   Val7_wire <= Val5_reg - Val6_reg;


   -- Based on the state, we can set the inputs to circuit1. We are calculating C1, C2, C3, C5, C6, and Area with this circuit
   -- We know that |C4| << 1, so converting that from 32.32 to 1.31 will allow us to use this circuit while saving precision. 
   In1_wire <= V1_array(0)(0) when triangleSetup_state = CALC_C1 else 
               V1_array(C5C6_attribute_count)(C5C6_size_count) when triangleSetup_state = CALC_C2 else
               V1_array(0)(0) when triangleSetup_state = CALC_C3 else
               C2_reg  when triangleSetup_state = CALC_C5 else
               C3_reg  when triangleSetup_state = CALC_C6 else
               V0_array(0)(0) when triangleSetup_state = CALC_AREA else
               fixed_t_zero;

   In2_wire <= V0_array(0)(0) when triangleSetup_state = CALC_C1 else 
               V0_array(C5C6_attribute_count)(C5C6_size_count) when triangleSetup_state = CALC_C2 else
               V0_array(0)(0) when triangleSetup_state = CALC_C3 else
               fixed_t_zero  when triangleSetup_state = CALC_C5 else
               fixed_t_zero  when triangleSetup_state = CALC_C6 else
               V2_array(0)(0) when triangleSetup_state = CALC_AREA else
               fixed_t_zero;

   In3_wire <= V2_array(0)(1) when triangleSetup_state = CALC_C1 else 
               V2_array(0)(1) when triangleSetup_state = CALC_C2 else
               V2_array(C5C6_attribute_count)(C5C6_size_count) when triangleSetup_state = CALC_C3 else
               C4_reg  when triangleSetup_state = CALC_C5 else
               C4_reg  when triangleSetup_state = CALC_C6 else
               V1_array(0)(1) when triangleSetup_state = CALC_AREA else
               fixed_t_zero;

   In4_wire <= V0_array(0)(1) when triangleSetup_state = CALC_C1 else 
               V0_array(0)(1) when triangleSetup_state = CALC_C2 else
               V0_array(C5C6_attribute_count)(C5C6_size_count) when triangleSetup_state = CALC_C3 else
               fixed_t_zero  when triangleSetup_state = CALC_C5 else
               fixed_t_zero  when triangleSetup_state = CALC_C6 else
               V2_array(0)(1) when triangleSetup_state = CALC_AREA else
               fixed_t_zero;

   In5_wire <= V1_array(0)(1) when triangleSetup_state = CALC_C1 else 
               V1_array(0)(1) when triangleSetup_state = CALC_C2 else
               V1_array(C5C6_attribute_count)(C5C6_size_count) when triangleSetup_state = CALC_C3 else
               fixed_t_zero  when triangleSetup_state = CALC_C5 else
               fixed_t_zero  when triangleSetup_state = CALC_C6 else
               V1_array(0)(0) when triangleSetup_state = CALC_AREA else
               fixed_t_zero;

   In6_wire <= V0_array(0)(1) when triangleSetup_state = CALC_C1 else 
               V0_array(0)(1) when triangleSetup_state = CALC_C2 else
               V0_array(C5C6_attribute_count)(C5C6_size_count) when triangleSetup_state = CALC_C3 else
               fixed_t_zero  when triangleSetup_state = CALC_C5 else
               fixed_t_zero  when triangleSetup_state = CALC_C6 else
               V2_array(0)(0) when triangleSetup_state = CALC_AREA else
               fixed_t_zero;

   In7_wire <= V2_array(0)(0) when triangleSetup_state = CALC_C1 else 
               V2_array(C5C6_attribute_count)(C5C6_size_count) when triangleSetup_state = CALC_C2 else
               V2_array(0)(0) when triangleSetup_state = CALC_C3 else
               fixed_t_zero  when triangleSetup_state = CALC_C5 else
               fixed_t_zero  when triangleSetup_state = CALC_C6 else
               V0_array(0)(1) when triangleSetup_state = CALC_AREA else
               fixed_t_zero;

   In8_wire <= V0_array(0)(0) when triangleSetup_state = CALC_C1 else 
               V0_array(C5C6_attribute_count)(C5C6_size_count) when triangleSetup_state = CALC_C2 else
               V0_array(0)(0) when triangleSetup_state = CALC_C3 else
               fixed_t_zero  when triangleSetup_state = CALC_C5 else
               fixed_t_zero  when triangleSetup_state = CALC_C6 else
               V2_array(0)(1) when triangleSetup_state = CALC_AREA else
               fixed_t_zero;


   Circuit1_regs: process (ACLK) is
   begin 
    if rising_edge(ACLK) then  
      if ARESETN = '0' then    
        Val1_reg <= fixed_t_zero;
        Val2_reg <= fixed_t_zero;
        Val3_reg <= fixed_t_zero;
        Val4_reg <= fixed_t_zero;
        Val5_reg <= wfixed_t_zero;
        Val6_reg <= wfixed_t_zero;
        Val7_reg <= wfixed_t_zero;
      else
        Val1_reg <= Val1_wire; 
        Val2_reg <= Val2_wire; 
        Val3_reg <= Val3_wire; 
        Val4_reg <= Val4_wire; 
        Val5_reg <= Val5_wire; 
        Val6_reg <= Val6_wire; 
        Val7_reg <= Val7_wire; 
      end if;
    end if;
   end process;

   triangle_in_ready <= '1' when triangleSetup_state = WAIT_FOR_TRIANGLE else '0';


   -- Output remapping
    boundingbox <= boundingbox_reg;
    Area        <= Area_reg;
    C5          <= C5_reg;
    C6          <= C6_reg;
    direction   <= direction_reg;

    setup_out_valid <= '1' when triangleSetup_state = WRITE_SETUP else '0';


   process (ACLK) is
   begin 
    if rising_edge(ACLK) then  

      -- Reset all interface registers
      if ARESETN = '0' then    
            triangleSetup_state <= WAIT_FOR_TRIANGLE;
            triangle_reg <= triangleArray_t_zero;
            triangle_out <= triangleArray_t_zero;
            circuit1_state <= (others => '0');
            C1_reg <= wfixed_t_zero;
            C2_reg <= fixed_t_zero;
            C3_reg <= fixed_t_zero;
            C4_reg <= wfixed_t_zero;

            C5_reg <= vertexArray_t_zero;
            C5_reg(0)(0) <= fixed_t_one;
            C6_reg <= vertexArray_t_zero;
            C6_reg(0)(1) <= fixed_t_one;

            C5C6_attribute_count <= 0;
            C5C6_size_count <= 0;
            Area_reg <= (others => '0');
            boundingbox_reg <= boundingboxRecord_t_zero;
            topVertexIndex <= 0;
            direction_reg <= '0';

      else

        -- Shift register for circuit1_state, default assignment for bit(0)    
        circuit1_state(CIRCUIT1_LATENCY downto 0) <= circuit1_state(CIRCUIT1_LATENCY-1 downto 0) & '0';

        case triangleSetup_state is

            -- Wait here until we receive a new triangle
            when WAIT_FOR_TRIANGLE =>
                if (triangle_in_valid = '1') then                    
                    triangle_reg <= triangle_in;
                    triangleSetup_state <= CALC_C1;
                    circuit1_state(0) <= '1';
                end if;

            -- Calculating C1 should only take 3 cycles
            when CALC_C1 =>
                C1_reg <= Val7_reg;
                if (circuit1_state(CIRCUIT1_LATENCY) = '1') then
                    triangleSetup_state <= CALC_C4;                    
                end if;

            when CALC_C4 =>
                if (shared_divider_divisor_tready = '1' and shared_divider_dividend_tready = '1') then
                    triangleSetup_state <= WAIT_FOR_DIVIDER;
                end if;

            when WAIT_FOR_DIVIDER =>
                C4_reg <= signed(shared_divider_dout_tdata);
                if (shared_divider_dout_tvalid = '1') then
                    -- We could start by calculating C5, C6 for x and y, but they should work out to be C5=1,0 and C6=0,1, so they can be skipped
                    C5C6_attribute_count <= 0;
                    C5C6_size_count <= 2;
                    triangleSetup_state <= CALC_C2;
                    circuit1_state(0) <= '1';
                end if;

            -- We want to calculate C2-C6 16 times (per-attribute, per-dim)
            when CALC_C2 =>
                C2_reg <= wfixed_t_to_fixed_t(Val7_reg);
                if (circuit1_state(CIRCUIT1_LATENCY) = '1') then
                    triangleSetup_state <= CALC_C3;                    
                    circuit1_state(0) <= '1';
                end if;
                        
            when CALC_C3 =>
                C3_reg <= wfixed_t_to_fixed_t(Val7_reg);
            when CALC_C5 =>
                -- For the C5 and C6 calculations, the result is in 17.47 format (Q1.31 x Q16.16)
                C5_reg(C5C6_attribute_count)(C5C6_size_count) <= Val7_reg(62 downto 31);

            when CALC_C6 =>
                C6_reg(C5C6_attribute_count)(C5C6_size_count) <= Val7_reg(62 downto 31);

            -- For area calculations, we do need 24-bits of integer value (large triangles can have ~2M fragments in them). 
            -- We can likely drop the fractional components also, since our x/y are all in screen space at this point. 
            when CALC_AREA =>
                Area_reg <= Val7_reg(55 downto 32);
                if (circuit1_state(CIRCUIT1_LATENCY) = '1') then
                    triangleSetup_state <= CALC_BOUNDINGBOX;                    
                end if;            


            when CALC_BOUNDINGBOX =>
                -- If the area is > 0, the triangle has a CCW direction
                direction_reg <= Area_reg(Area_reg'high);
                
                -- Whole lot of comparators here. Xmin first
                if ((V0_record.att0.x <= V1_record.att0.x) and (V0_record.att0.x <= V2_record.att0.x)) then
                    boundingbox_reg.xmin <= V0_record.att0.x;
                elsif (V1_record.att0.x <= V2_record.att0.x) then
                    boundingbox_reg.xmin <= V1_record.att0.x;
                else
                    boundingbox_reg.xmin <= V2_record.att0.x;                
                end if;           

                -- Ymin. Do not overthink top vs bottom, either ymin or ymax is ok as long as we are consistent. 

                -- XMax

                -- YMax
--                if ((V0_record.att0.y >= V1_record.att0.y) and (V0_record.att0.y >= V2_record.att0.y)) then
--                    topVertexIndex <= 0;
--                    boundingbox_reg.ymax <= V0_record.att0.y;

                triangleSetup_state <= REORDER_TRIANGLE;

            -- "Up/Top" and "Down/Bottom" are relative to screen-space. We take the ymin index to mean our "top". 
            -- For line-checking purposes, we need the triangle in the same order (CW vs CCW) as the original 
            -- triangle - the sign bit of the Area will let us know this. 
            when REORDER_TRIANGLE =>
                triangle_out(0) <= triangle_reg(topVertexIndex);
                if (topVertexIndex = 0) then
                    if (direction_reg = direction_ccw) then
                        triangle_out(1) <= triangle_reg(1);
                        triangle_out(2) <= triangle_reg(2);
                    else
                        triangle_out(1) <= triangle_reg(1);
                        triangle_out(2) <= triangle_reg(2);
                    end if;
                elsif (topVertexIndex = 1) then 
                else
                end if;
                triangleSetup_state <= WRITE_SETUP;

            when WRITE_SETUP =>
                if (setup_out_ready = '1') then
                      triangleSetup_state <= WAIT_FOR_TRIANGLE_DONE;
 --                   triangleSetup_state <= WAIT_FOR_TRIANGLE;
                end if;
  
            when WAIT_FOR_TRIANGLE_DONE =>
                 if (command_in = DONE_CMD) then
                    triangleSetup_state <= WAIT_FOR_TRIANGLE;
                end if;
  
                
        end case;

      end if;
    end if;
   end process;
end architecture behavioral;
