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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
LIBRARY WORK;
USE WORK.sgp_types.ALL;
ENTITY triangleSetup_core IS

    PORT (
        ACLK : IN STD_LOGIC;
        ARESETN : IN STD_LOGIC;

        -- AXIS-style vertex input
        triangle_in_ready : OUT STD_LOGIC;
        triangle_in_valid : IN STD_LOGIC;
        triangle_in : IN triangleArray_t;

        -- AXIS-style triangle setup outputs
        boundingbox : OUT boundingboxRecord_t;
        Area : OUT signed(23 DOWNTO 0);
        direction : OUT STD_LOGIC;
        C5 : OUT vertexArray_t; -- Our x-dim linear interpolation for all attributes
        C6 : OUT vertexArray_t; -- Our y-dim linear interpolation for all attributes
        triangle_out : OUT triangleArray_t; -- Potentially re-ordered vertices
        setup_out_ready : IN STD_LOGIC;
        setup_out_valid : OUT STD_LOGIC;
        command_in : IN traversal_cmds_t
    );
END triangleSetup_core;
ARCHITECTURE behavioral OF triangleSetup_core IS

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
    TYPE STATE_TYPE IS (WAIT_FOR_TRIANGLE, CALC_C1, WAIT_FOR_DIVIDER, CALC_C2, CALC_C3, CALC_C4, CALC_C5, CALC_C6, CALC_AREA, CALC_BOUNDINGBOX, REORDER_TRIANGLE, WRITE_SETUP, WAIT_FOR_TRIANGLE_DONE);
    SIGNAL triangleSetup_state : STATE_TYPE;
    ATTRIBUTE fsm_encoding : STRING;
    ATTRIBUTE fsm_encoding OF triangleSetup_state : SIGNAL IS "one_hot";
    -- Design registers and remapping signals
    SIGNAL triangle_reg : triangleArray_t;
    SIGNAL V0_array, V1_array, V2_array : vertexArray_t;
    SIGNAL V0_record, V1_record, V2_record : vertexRecord_t;
    SIGNAL C1_reg, C4_reg : wfixed_t;
    SIGNAL C2_reg, C3_reg : fixed_t;
    SIGNAL C5_reg, C6_reg : vertexArray_t;
    SIGNAL C5C6_attribute_count : INTEGER RANGE 0 TO C_SGP_NUM_VERTEX_ATTRIB;
    SIGNAL C5C6_size_count : INTEGER RANGE 0 TO C_SGP_VERTEX_ATTRIB_SIZE;
    SIGNAL Area_reg : signed(23 DOWNTO 0);
    SIGNAL boundingbox_reg : boundingboxRecord_t;
    SIGNAL topVertexIndex : INTEGER RANGE 0 TO 3;
    SIGNAL direction_reg : STD_LOGIC;

    -- Circuit1 signals
    SIGNAL In1_wire, In2_wire, In3_wire, In4_wire, In5_wire, In6_wire, In7_wire, In8_wire : fixed_t;
    SIGNAL Val1_wire, Val2_wire, Val3_wire, Val4_wire : fixed_t;
    SIGNAL Val1_reg, Val2_reg, Val3_reg, Val4_reg : fixed_t;
    SIGNAL Val5_wire, Val6_wire : wfixed_t;
    SIGNAL Val5_reg, Val6_reg : wfixed_t;
    SIGNAL Val7_wire : wfixed_t;
    SIGNAL Val7_reg : wfixed_t;
    CONSTANT CIRCUIT1_LATENCY : INTEGER := 3;
    SIGNAL circuit1_state : STD_LOGIC_VECTOR(CIRCUIT1_LATENCY DOWNTO 0);

    -- shared_diviser signals
    SIGNAL shared_divider_divisor_tvalid : STD_LOGIC;
    SIGNAL shared_divider_divisor_tready : STD_LOGIC;
    SIGNAL shared_divider_divisor_tdata : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL shared_divider_dividend_tvalid : STD_LOGIC;
    SIGNAL shared_divider_dividend_tready : STD_LOGIC;
    SIGNAL shared_divider_dout_tvalid : STD_LOGIC;
    SIGNAL shared_divider_dout_tdata : STD_LOGIC_VECTOR(63 DOWNTO 0);
BEGIN

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
    PORT MAP(
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

    shared_divider_divisor_tvalid <= '1' WHEN triangleSetup_state = CALC_C4 ELSE
        '0';
    shared_divider_dividend_tvalid <= '1' WHEN triangleSetup_state = CALC_C4 ELSE
        '0';
    shared_divider_divisor_tdata <= STD_LOGIC_VECTOR(C1_reg(63 DOWNTO 32)); -- Grab just the integer aspect of C1 value

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
    In1_wire <= V1_array(0)(0) WHEN triangleSetup_state = CALC_C1 ELSE
        V1_array(C5C6_attribute_count)(C5C6_size_count) WHEN triangleSetup_state = CALC_C2 ELSE
        V1_array(0)(0) WHEN triangleSetup_state = CALC_C3 ELSE
        C2_reg WHEN triangleSetup_state = CALC_C5 ELSE
        C3_reg WHEN triangleSetup_state = CALC_C6 ELSE
        V0_array(0)(0) WHEN triangleSetup_state = CALC_AREA ELSE
        fixed_t_zero;

    In2_wire <= V0_array(0)(0) WHEN triangleSetup_state = CALC_C1 ELSE
        V0_array(C5C6_attribute_count)(C5C6_size_count) WHEN triangleSetup_state = CALC_C2 ELSE
        V0_array(0)(0) WHEN triangleSetup_state = CALC_C3 ELSE
        fixed_t_zero WHEN triangleSetup_state = CALC_C5 ELSE
        fixed_t_zero WHEN triangleSetup_state = CALC_C6 ELSE
        V2_array(0)(0) WHEN triangleSetup_state = CALC_AREA ELSE
        fixed_t_zero;

    In3_wire <= V2_array(0)(1) WHEN triangleSetup_state = CALC_C1 ELSE
        V2_array(0)(1) WHEN triangleSetup_state = CALC_C2 ELSE
        V2_array(C5C6_attribute_count)(C5C6_size_count) WHEN triangleSetup_state = CALC_C3 ELSE
        C4_reg(32 downto 1) WHEN triangleSetup_state = CALC_C5 ELSE
        C4_reg(32 downto 1) WHEN triangleSetup_state = CALC_C6 ELSE
        V1_array(0)(1) WHEN triangleSetup_state = CALC_AREA ELSE
        fixed_t_zero;

    In4_wire <= V0_array(0)(1) WHEN triangleSetup_state = CALC_C1 ELSE
        V0_array(0)(1) WHEN triangleSetup_state = CALC_C2 ELSE
        V0_array(C5C6_attribute_count)(C5C6_size_count) WHEN triangleSetup_state = CALC_C3 ELSE
        fixed_t_zero WHEN triangleSetup_state = CALC_C5 ELSE
        fixed_t_zero WHEN triangleSetup_state = CALC_C6 ELSE
        V2_array(0)(1) WHEN triangleSetup_state = CALC_AREA ELSE
        fixed_t_zero;

    In5_wire <= V1_array(0)(1) WHEN triangleSetup_state = CALC_C1 ELSE
        V1_array(0)(1) WHEN triangleSetup_state = CALC_C2 ELSE
        V1_array(C5C6_attribute_count)(C5C6_size_count) WHEN triangleSetup_state = CALC_C3 ELSE
        fixed_t_zero WHEN triangleSetup_state = CALC_C5 ELSE
        fixed_t_zero WHEN triangleSetup_state = CALC_C6 ELSE
        V1_array(0)(0) WHEN triangleSetup_state = CALC_AREA ELSE
        fixed_t_zero;

    In6_wire <= V0_array(0)(1) WHEN triangleSetup_state = CALC_C1 ELSE
        V0_array(0)(1) WHEN triangleSetup_state = CALC_C2 ELSE
        V0_array(C5C6_attribute_count)(C5C6_size_count) WHEN triangleSetup_state = CALC_C3 ELSE
        fixed_t_zero WHEN triangleSetup_state = CALC_C5 ELSE
        fixed_t_zero WHEN triangleSetup_state = CALC_C6 ELSE
        V2_array(0)(0) WHEN triangleSetup_state = CALC_AREA ELSE
        fixed_t_zero;

    In7_wire <= V2_array(0)(0) WHEN triangleSetup_state = CALC_C1 ELSE
        V2_array(C5C6_attribute_count)(C5C6_size_count) WHEN triangleSetup_state = CALC_C2 ELSE
        V2_array(0)(0) WHEN triangleSetup_state = CALC_C3 ELSE
        fixed_t_zero WHEN triangleSetup_state = CALC_C5 ELSE
        fixed_t_zero WHEN triangleSetup_state = CALC_C6 ELSE
        V0_array(0)(1) WHEN triangleSetup_state = CALC_AREA ELSE
        fixed_t_zero;

    In8_wire <= V0_array(0)(0) WHEN triangleSetup_state = CALC_C1 ELSE
        V0_array(C5C6_attribute_count)(C5C6_size_count) WHEN triangleSetup_state = CALC_C2 ELSE
        V0_array(0)(0) WHEN triangleSetup_state = CALC_C3 ELSE
        fixed_t_zero WHEN triangleSetup_state = CALC_C5 ELSE
        fixed_t_zero WHEN triangleSetup_state = CALC_C6 ELSE
        V2_array(0)(1) WHEN triangleSetup_state = CALC_AREA ELSE
        fixed_t_zero;
    Circuit1_regs : PROCESS (ACLK) IS
    BEGIN
        IF rising_edge(ACLK) THEN
            IF ARESETN = '0' THEN
                Val1_reg <= fixed_t_zero;
                Val2_reg <= fixed_t_zero;
                Val3_reg <= fixed_t_zero;
                Val4_reg <= fixed_t_zero;
                Val5_reg <= wfixed_t_zero;
                Val6_reg <= wfixed_t_zero;
                Val7_reg <= wfixed_t_zero;
            ELSE
                Val1_reg <= Val1_wire;
                Val2_reg <= Val2_wire;
                Val3_reg <= Val3_wire;
                Val4_reg <= Val4_wire;
                Val5_reg <= Val5_wire;
                Val6_reg <= Val6_wire;
                Val7_reg <= Val7_wire;
            END IF;
        END IF;
    END PROCESS;

    triangle_in_ready <= '1' WHEN triangleSetup_state = WAIT_FOR_TRIANGLE ELSE
        '0';
    -- Output remapping
    boundingbox <= boundingbox_reg;
    Area <= Area_reg;
    C5 <= C5_reg;
    C6 <= C6_reg;
    direction <= direction_reg;

    setup_out_valid <= '1' WHEN triangleSetup_state = WRITE_SETUP ELSE
        '0';
    PROCESS (ACLK) IS
    BEGIN
        IF rising_edge(ACLK) THEN

            -- Reset all interface registers
            IF ARESETN = '0' THEN
                triangleSetup_state <= WAIT_FOR_TRIANGLE;
                triangle_reg <= triangleArray_t_zero;
                triangle_out <= triangleArray_t_zero;
                circuit1_state <= (OTHERS => '0');
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
                Area_reg <= (OTHERS => '0');
                boundingbox_reg <= boundingboxRecord_t_zero;
                topVertexIndex <= 0;
                direction_reg <= '0';

            ELSE

                -- Shift register for circuit1_state, default assignment for bit(0)    
                circuit1_state(CIRCUIT1_LATENCY DOWNTO 0) <= circuit1_state(CIRCUIT1_LATENCY - 1 DOWNTO 0) & '0';

                CASE triangleSetup_state IS

                        -- Wait here until we receive a new triangle
                    WHEN WAIT_FOR_TRIANGLE =>
                        IF (triangle_in_valid = '1') THEN
                            triangle_reg <= triangle_in;
                            triangleSetup_state <= CALC_C1;
                            circuit1_state(0) <= '1';
                        END IF;

                        -- Calculating C1 should only take 3 cycles
                    WHEN CALC_C1 =>
                        C1_reg <= Val7_reg;
                        IF (circuit1_state(CIRCUIT1_LATENCY) = '1') THEN
                            triangleSetup_state <= CALC_C4;
                        END IF;

                    WHEN CALC_C4 =>
                        IF (shared_divider_divisor_tready = '1' AND shared_divider_dividend_tready = '1') THEN
                            triangleSetup_state <= WAIT_FOR_DIVIDER;
                        END IF;

                    WHEN WAIT_FOR_DIVIDER =>
                        C4_reg <= signed(shared_divider_dout_tdata);
                        IF (shared_divider_dout_tvalid = '1') THEN
                            -- We could start by calculating C5, C6 for x and y, but they should work out to be C5=1,0 and C6=0,1, so they can be skipped
                            C5C6_attribute_count <= 0;
                            C5C6_size_count <= 2;
                            triangleSetup_state <= CALC_C2;
                            circuit1_state(0) <= '1';
                        END IF;

                        -- We want to calculate C2-C6 16 times (per-attribute, per-dim)
                    WHEN CALC_C2 =>
                    C2_reg <= wfixed_t_to_fixed_t(Val7_reg);
                        IF (circuit1_state(CIRCUIT1_LATENCY) = '1') THEN
                            triangleSetup_state <= CALC_C5;
                            circuit1_state(0) <= '1';
                        END IF;

                    WHEN CALC_C3 =>
                        C3_reg <= wfixed_t_to_fixed_t(Val7_reg);
                        IF (circuit1_state(CIRCUIT1_LATENCY) = '1') THEN
                            triangleSetup_state <= CALC_C6;
                            circuit1_state(0) <= '1';
                        END IF;

                    WHEN CALC_C5 =>
                        -- For the C5 and C6 calculations, the result is in 17.47 format (Q1.31 x Q16.16)
                        C5_reg(C5C6_attribute_count)(C5C6_size_count) <= Val7_reg(62 DOWNTO 31);

                        IF (circuit1_state(CIRCUIT1_LATENCY) = '1') THEN
                            IF (C5C6_size_count = 3) THEN
                                IF (C5C6_attribute_count = 3) THEN
                                    triangleSetup_state <= CALC_C3;
                                    C5C6_attribute_count <= 0;
                                    C5C6_size_count <= 2;
                                ELSE
                                    C5C6_attribute_count <= C5C6_attribute_count + 1;
                                    triangleSetup_state <= CALC_C2;
                                END IF;
                                C5C6_size_count <= 0;
                            ELSE
                                C5C6_size_count <= C5C6_size_count + 1;
                                triangleSetup_state <= CALC_C2;
                            END IF;
                            circuit1_state(0) <= '1';
                        END IF;
                    WHEN CALC_C6 =>
                        C6_reg(C5C6_attribute_count)(C5C6_size_count) <= Val7_reg(62 DOWNTO 31);

                        IF (circuit1_state(CIRCUIT1_LATENCY) = '1') THEN
                            IF (C5C6_size_count = 3) THEN
                                IF (C5C6_attribute_count = 3) THEN
                                    triangleSetup_state <= CALC_AREA;
                                ELSE
                                    C5C6_attribute_count <= C5C6_attribute_count + 1;
                                    triangleSetup_state <= CALC_C3;
                                END IF;
                                C5C6_size_count <= 0;
                            ELSE
                                C5C6_size_count <= C5C6_size_count + 1;
                                triangleSetup_state <= CALC_C3;
                            END IF;
                            circuit1_state(0) <= '1';
                        END IF;

                        -- For area calculations, we do need 24-bits of integer value (large triangles can have ~2M fragments in them). 
                        -- We can likely drop the fractional components also, since our x/y are all in screen space at this point. 
                    WHEN CALC_AREA =>
                        Area_reg <= Val7_reg(55 DOWNTO 32);
                        IF (circuit1_state(CIRCUIT1_LATENCY) = '1') THEN
                            triangleSetup_state <= CALC_BOUNDINGBOX;
                        END IF;

                    WHEN CALC_BOUNDINGBOX =>
                        -- If the area is > 0, the triangle has a CCW direction
                        direction_reg <= Area_reg(Area_reg'high);

                        -- Whole lot of comparators here. Xmin first
                        IF ((V0_record.att0.x <= V1_record.att0.x) AND (V0_record.att0.x <= V2_record.att0.x)) THEN
                            boundingbox_reg.xmin <= V0_record.att0.x;
                        ELSIF (V1_record.att0.x <= V2_record.att0.x) THEN
                            boundingbox_reg.xmin <= V1_record.att0.x;
                        ELSE
                            boundingbox_reg.xmin <= V2_record.att0.x;
                        END IF;

                        -- Ymin. Do not overthink top vs bottom, either ymin or ymax is ok as long as we are consistent. 
                        IF ((V0_record.att0.y <= V1_record.att0.y) AND (V0_record.att0.y <= V2_record.att0.y)) THEN
                            boundingbox_reg.ymin <= V0_record.att0.y;
                        ELSIF (V1_record.att0.y <= V2_record.att0.y) THEN
                            boundingbox_reg.ymin <= V1_record.att0.y;
                        ELSE
                            boundingbox_reg.ymin <= V2_record.att0.y;
                        END IF;

                        -- XMax
                        IF ((V0_record.att0.x >= V1_record.att0.x) AND (V0_record.att0.x >= V2_record.att0.x)) THEN
                            boundingbox_reg.xmax <= V0_record.att0.x;
                        ELSIF (V1_record.att0.x >= V2_record.att0.x) THEN
                            boundingbox_reg.xmax <= V1_record.att0.x;
                        ELSE
                            boundingbox_reg.xmax <= V2_record.att0.x;
                        END IF;

                        -- YMax
                        IF ((V0_record.att0.y >= V1_record.att0.y) AND (V0_record.att0.y >= V2_record.att0.y)) THEN
                            topVertexIndex <= 0;
                            boundingbox_reg.ymax <= V0_record.att0.y;
                        ELSIF (V1_record.att0.y >= V2_record.att0.y) THEN
                            topVertexIndex <= 1;
                            boundingbox_reg.ymax <= V1_record.att0.y;
                        ELSE
                            topVertexIndex <= 2;
                            boundingbox_reg.ymax <= V2_record.att0.y;
                        END IF;

                        triangleSetup_state <= REORDER_TRIANGLE;

                        -- "Up/Top" and "Down/Bottom" are relative to screen-space. We take the ymin index to mean our "top". 
                        -- For line-checking purposes, we need the triangle in the same order (CW vs CCW) as the original 
                        -- triangle - the sign bit of the Area will let us know this. 
                    WHEN REORDER_TRIANGLE =>
                        triangle_out(0) <= triangle_reg(topVertexIndex);
                        IF (topVertexIndex = 0) THEN
                            triangle_out(1) <= triangle_reg(1);
                            triangle_out(2) <= triangle_reg(2);
                        ELSIF (topVertexIndex = 1) THEN
                            triangle_out(1) <= triangle_reg(2);
                            triangle_out(2) <= triangle_reg(0);
                        ELSE
                            triangle_out(1) <= triangle_reg(0);
                            triangle_out(2) <= triangle_reg(1);
                        END IF;
                        
                        triangleSetup_state <= WRITE_SETUP;

                    WHEN WRITE_SETUP =>
                        IF (setup_out_ready = '1') THEN
                            triangleSetup_state <= WAIT_FOR_TRIANGLE_DONE;
                            --                   triangleSetup_state <= WAIT_FOR_TRIANGLE;
                        END IF;

                    WHEN WAIT_FOR_TRIANGLE_DONE =>
                        IF (command_in = DONE_CMD) THEN
                            triangleSetup_state <= WAIT_FOR_TRIANGLE;
                        END IF;
                END CASE;

            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE behavioral;