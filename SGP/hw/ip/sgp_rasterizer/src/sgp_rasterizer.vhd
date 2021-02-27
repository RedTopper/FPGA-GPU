-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- sgp_rasterizer.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains the top-level instantiation of the 
-- rasterizer unit that generates fragments based on primitive type via
-- in/out tests and interpolating vertex attributes.
--
-- NOTES:
-- 12/06/20 by JAZ::Design created.
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library WORK;
use WORK.sgp_types.all;


entity sgp_rasterizer is

    generic (
		-- Parameters of AXI-Lite slave interface
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 10;
		
		-- Parameters for output vertex attribute stream
		C_NUM_VERTEX_ATTRIB : integer := 4
	);

	port (ACLK	: in	std_logic;
		ARESETN	: in	std_logic;

		-- Ports of AXI-Lite slave interface
		s_axi_lite_awaddr	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		s_axi_lite_awprot	: in std_logic_vector(2 downto 0);
		s_axi_lite_awvalid	: in std_logic;
		s_axi_lite_awready	: out std_logic;
		s_axi_lite_wdata	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		s_axi_lite_wstrb	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		s_axi_lite_wvalid	: in std_logic;
		s_axi_lite_wready	: out std_logic;
		s_axi_lite_bresp	: out std_logic_vector(1 downto 0);
		s_axi_lite_bvalid	: out std_logic;
		s_axi_lite_bready	: in std_logic;
		s_axi_lite_araddr	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		s_axi_lite_arprot	: in std_logic_vector(2 downto 0);
		s_axi_lite_arvalid	: in std_logic;
		s_axi_lite_arready	: out std_logic;
		s_axi_lite_rdata	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		s_axi_lite_rresp	: out std_logic_vector(1 downto 0);
		s_axi_lite_rvalid	: out std_logic;
		s_axi_lite_rready	: in std_logic;        


        -- AXIS slave interface
		S_AXIS_TREADY	: out	std_logic;
		S_AXIS_TDATA	: in	std_logic_vector(C_NUM_VERTEX_ATTRIB*128-1 downto 0);
		S_AXIS_TLAST	: in	std_logic;
		S_AXIS_TVALID	: in	std_logic;

        -- AXIS master interface
		M_AXIS_TVALID	: out	std_logic;
		M_AXIS_TDATA	: out	std_logic_vector(C_NUM_VERTEX_ATTRIB*128-1 downto 0);
		M_AXIS_TLAST	: out	std_logic;
		M_AXIS_TREADY	: in	std_logic);

attribute SIGIS : string; 
attribute SIGIS of ACLK : signal is "Clk"; 

end sgp_rasterizer;


architecture behavioral of sgp_rasterizer is


	-- component declaration
	component sgp_rasterizer_axi_lite_regs is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 10
		);
		port (
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic;
		
		-- Our registers that we need to operate this core. Manually map these in axi_lite_regs
        SGP_AXI_RASTERIZER_PRIMTYPE_REG   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    SGP_AXI_RASTERIZER_UNUSED1_REG    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    SGP_AXI_RASTERIZER_UNUSED2_REG    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    SGP_AXI_RASTERIZER_UNUSED3_REG    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    SGP_AXI_RASTERIZER_UNUSED4_REG    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    SGP_AXI_RASTERIZER_UNUSED5_REG    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        SGP_AXI_RASTERIZER_STATUS         : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        SGP_AXI_RASTERIZER_DEBUG          : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0)
		
		);
	end component sgp_rasterizer_axi_lite_regs;


    component primitiveAssembly_core is
	   port (ACLK	: in	std_logic;
		    ARESETN	: in	std_logic;
            primtype                    : in     primtype_t;
            vertex_in_final             : in     std_logic;
    		vertex_in_ready		        : out	std_logic;
		    vertex_in					: in	vertexVector_t;
		    vertex_valid 				: in 	std_logic; 
            primout_ready 				: in 	std_logic;
            primout_valid 				: out 	std_logic;
		    V0							: out	vertexVector_t;
		    V1							: out	vertexVector_t;
		    V2							: out	vertexVector_t
        );
    end component primitiveAssembly_core;


    component triangleSetup_core is
	port (ACLK	    : in	std_logic;
		  ARESETN	: in	std_logic;
		  triangle_in_ready		        : out	std_logic;
		  triangle_in_valid 			: in 	std_logic; 
          triangle_in                   : in    triangleArray_t;
          boundingbox                   : out   boundingboxRecord_t;          
          AREA                          : out   signed(23 downto 0); 
          direction                     : out   std_logic;
          C5                            : out   vertexArray_t;
          C6                            : out   vertexArray_t;
          triangle_out                  : out   triangleArray_t;
          setup_out_ready 				: in 	std_logic;
          setup_out_valid 				: out 	std_logic;
          command_in                    : in    traversal_cmds_t
    );
    end component triangleSetup_core;

    component triangleTraversal_core is
	port (ACLK	                        : in	std_logic;
		  ARESETN	                    : in	std_logic;
          boundingbox                   : in    boundingboxRecord_t;          
          startposition                 : in    attributeRecord_t; 
          setup_in_ready 				: out 	std_logic;
          setup_in_valid 				: in 	std_logic;
		  command_out		            : out	traversal_cmds_t;
          fragment_out_valid            : in    std_logic;
		  fragment_test_result          : in    std_logic;
		  status_out                    : out   std_logic
    );
    end component triangleTraversal_core;

    component triangleTest_core is
	port (ACLK	    : in	std_logic;
		  ARESETN	: in	std_logic;
          AREA                          : in   signed(23 downto 0); 
          direction                     : in   std_logic;
          C5                            : in   vertexArray_t;
          C6                            : in   vertexArray_t;
          triangle_in                   : in   triangleArray_t;
          setup_in_ready 				: out 	std_logic;
          setup_in_valid 				: in 	std_logic;
		  command_in		            : in	traversal_cmds_t;
          fragment_test_result          : out   std_logic;
		  fragment_out_ready		    : in	std_logic;
		  fragment_out_valid 			: out   std_logic; 
          fragment_out                  : out   vertexArray_t
    );
    end component triangleTest_core;




    -- User register values
    signal rasterizer_primtype_reg 	    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal rasterizer_debug 	        : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal rasterizer_status            : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);


    -- Interface signals for the primitiveAssembly_core
    signal primtype                             : primtype_t;
    signal primitiveAssembly_vertex_in_ready    : std_logic;
    signal primitiveAssembly_vertex_in          : vertexVector_t;
    signal primitiveAssembly_vertex_valid       : std_logic;
    signal primitiveAssembly_primout_ready      : std_logic;
    signal primitiveAssembly_primout_valid      : std_logic;
    signal primitiveAssembly_V0                 : vertexVector_t;
    signal primitiveAssembly_V1                 : vertexVector_t;
    signal primitiveAssembly_V2                 : vertexVector_t;
    
    -- Interface signals for the triangleSetup_core
    signal triangleSetup_triangle_in_ready     : std_logic;
    signal triangleSetup_triangle_in_valid     : std_logic;
    signal triangleSetup_triangle_in           : triangleArray_t;
    signal triangleSetup_boundingbox           : boundingboxRecord_t;
    signal triangleSetup_Area                  : signed(23 downto 0);
    signal triangleSetup_direction             : std_logic;
    signal triangleSetup_C5                    : vertexArray_t;
    signal triangleSetup_C6                    : vertexArray_t;
    signal triangleSetup_triangle_out          : triangleArray_t;
    signal triangleSetup_setup_out_ready       : std_logic;
    signal triangleSetup_setup_out_valid       : std_logic;  

    -- Interface signals for the triangleTraversal_core
    signal triangleTraversal_startvertex       : vertexRecord_t;
    signal triangleTraversal_startposition_in  : attributeRecord_t;
    signal triangleTraversal_setup_in_ready    : std_logic;
    --signal triangleTraversal_setup_in_valid    : std_logic;
    signal triangleTraversal_command_out       : traversal_cmds_t;
    signal triangleTraversal_status_out        : std_logic;

    -- Interface signals for the triangleTest_core
    signal triangleTest_setup_in_ready         : std_logic;
    signal triangleTest_fragment_test_result   : std_logic; 
    signal triangleTest_fragment_out_ready     : std_logic;
    signal triangleTest_fragment_out_valid     : std_logic;
    signal triangleTest_fragment_out           : vertexArray_t;
    signal fragment_valid                      : std_logic;

begin


  -- Instantiation of Axi Bus Interface S_AXI_LITE
  sgp_rasterizer_axi_lite_regs_inst : sgp_rasterizer_axi_lite_regs
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_ADDR_WIDTH
	)
	port map (
		S_AXI_ACLK	=> ACLK,
		S_AXI_ARESETN	=> ARESETN,
		S_AXI_AWADDR	=> s_axi_lite_awaddr,
		S_AXI_AWPROT	=> s_axi_lite_awprot,
		S_AXI_AWVALID	=> s_axi_lite_awvalid,
		S_AXI_AWREADY	=> s_axi_lite_awready,
		S_AXI_WDATA	=> s_axi_lite_wdata,
		S_AXI_WSTRB	=> s_axi_lite_wstrb,
		S_AXI_WVALID	=> s_axi_lite_wvalid,
		S_AXI_WREADY	=> s_axi_lite_wready,
		S_AXI_BRESP	=> s_axi_lite_bresp,
		S_AXI_BVALID	=> s_axi_lite_bvalid,
		S_AXI_BREADY	=> s_axi_lite_bready,
		S_AXI_ARADDR	=> s_axi_lite_araddr,
		S_AXI_ARPROT	=> s_axi_lite_arprot,
		S_AXI_ARVALID	=> s_axi_lite_arvalid,
		S_AXI_ARREADY	=> s_axi_lite_arready,
		S_AXI_RDATA	=> s_axi_lite_rdata,
		S_AXI_RRESP	=> s_axi_lite_rresp,
		S_AXI_RVALID	=> s_axi_lite_rvalid,
		S_AXI_RREADY	=> s_axi_lite_rready,

        SGP_AXI_RASTERIZER_PRIMTYPE_REG            => rasterizer_primtype_reg,
	    SGP_AXI_RASTERIZER_UNUSED1_REG            => open,
	    SGP_AXI_RASTERIZER_UNUSED2_REG            => open,
	    SGP_AXI_RASTERIZER_UNUSED3_REG            => open,
	    SGP_AXI_RASTERIZER_UNUSED4_REG            => open,
	    SGP_AXI_RASTERIZER_UNUSED5_REG            => open,
        SGP_AXI_RASTERIZER_STATUS                 => rasterizer_status,	
        SGP_AXI_RASTERIZER_DEBUG                  => rasterizer_debug	
		
	);


    --todo vertex_in_final is prolly mapped incorrectly
    primitiveAssembly_inst: primitiveAssembly_core 
	   port map (
	       ACLK	            => ACLK,
           ARESETN          => ARESETN,
           primtype         => primtype,
           vertex_in_final  => S_AXIS_TLAST,
           vertex_in_ready  => primitiveAssembly_vertex_in_ready,
           vertex_in        => primitiveAssembly_vertex_in,
           vertex_valid     => primitiveAssembly_vertex_valid,
           primout_ready    => primitiveAssembly_primout_ready,
           primout_valid    => primitiveAssembly_primout_valid,
           V0               => primitiveAssembly_V0,
           V1               => primitiveAssembly_V1,
           V2               => primitiveAssembly_V2
           );


    triangleSetup_inst: triangleSetup_core 
	   port map (
	       ACLK	                => ACLK,
           ARESETN              => ARESETN,
           triangle_in_ready    => triangleSetup_triangle_in_ready,
           triangle_in_valid    => triangleSetup_triangle_in_valid,
           triangle_in          => triangleSetup_triangle_in,
           boundingbox          => triangleSetup_boundingbox,
           Area                 => triangleSetup_Area,
           direction            => triangleSetup_direction,
           C5                   => triangleSetup_C5,
           C6                   => triangleSetup_C6,
           triangle_out         => trianglesetup_triangle_out,
           setup_out_ready      => triangleSetup_setup_out_ready,
           setup_out_valid      => triangleSetup_setup_out_valid,
           command_in           => triangleTraversal_command_out
           );

    triangleTraversal_inst: triangleTraversal_core
	port map (
	      ACLK	               => ACLK,
          ARESETN              => ARESETN,
          boundingbox          => triangleSetup_boundingbox,
          startposition        => triangleTraversal_startposition_in,
          setup_in_ready       => triangleTraversal_setup_in_ready,
          setup_in_valid       => triangleSetup_setup_out_valid,
          command_out          => triangleTraversal_command_out,
          status_out           => triangleTraversal_status_out,
          fragment_out_valid   => triangleTest_fragment_out_valid,
          fragment_test_result => triangleTest_fragment_test_result
          );

    triangleTest_inst: triangleTest_core 
	port map (
	       ACLK	                => ACLK,
           ARESETN              => ARESETN,
           Area                 => triangleSetup_Area,
           direction            => triangleSetup_direction,
           C5                   => triangleSetup_C5,
           C6                   => triangleSetup_C6,
           triangle_in          => triangleSetup_triangle_out,
           setup_in_ready       => triangleTest_setup_in_ready,
           setup_in_valid       => triangleSetup_setup_out_valid,
           command_in           => triangleTraversal_command_out,
           fragment_test_result => triangleTest_fragment_test_result,
           fragment_out_ready   => triangleTest_fragment_out_ready,
           fragment_out_valid   => triangleTest_fragment_out_valid,
           fragment_out         => triangleTest_fragment_out
          );




   -- At least set a unique ID for each synthesis run in the debug register, so we know that we're looking at the most recent IP core
   -- It would also be useful to connect internal signals to this register for software debug purposes
   rasterizer_debug  <= x"00000006";
   rasterizer_status <= (0 => triangleTraversal_status_out, others => '0'); 

   -- Convert the register to the primtype_t.
   primtype <= to_integer(unsigned(rasterizer_primtype_reg));

   -- We can read from the AXIS bus when the primitiveAssembly module is ready.
   S_AXIS_TREADY <= primitiveAssembly_vertex_in_ready;
   primitiveAssembly_vertex_valid <= S_AXIS_TVALID;
   primitiveAssembly_vertex_in <= signed(S_AXIS_TDATA);

   -- Output mux. If GL_POINTS, we can directly connect the primitiveAssembly output (vertex -> fragment). 
   -- Otherwise the output of the triangleTest needs to go out. 
   M_AXIS_TDATA <= std_logic_vector(primitiveAssembly_V0) when primtype=SGP_GL_POINTS else
                   std_logic_vector(to_vertexVector_t(triangleTest_fragment_out)) when primtype=SGP_GL_TRIANGLES else                   
                   std_logic_vector(to_vertexVector_t(triangleTest_fragment_out)) when primtype=SGP_GL_TRIANGLE_STRIP else                   
                   std_logic_vector(to_vertexVector_t(triangleTest_fragment_out)) when primtype=SGP_GL_TRIANGLE_FAN else                   
                   (others => '0');                       


   -- We should only store a triangle setup if both the triangleTraversal and triangleTest modules are ready
   triangleSetup_setup_out_ready <= triangleTraversal_setup_in_ready and triangleTest_setup_in_ready;


   -- We only have a valid output when the triangleTest outputs a fragment and it is IN the triangle
   fragment_valid <= triangleTest_fragment_out_valid and triangleTest_fragment_test_result;
   M_AXIS_TVALID <= primitiveAssembly_primout_valid when primtype=SGP_GL_POINTS else
                    fragment_valid when primtype=SGP_GL_TRIANGLES else
                    fragment_valid when primtype=SGP_GL_TRIANGLE_STRIP else
                    fragment_valid when primtype=SGP_GL_TRIANGLE_FAN else
                    '0';

   -- Todo: propagate TLAST properly. We can't rely on TLAST downstream. 
   M_AXIS_TLAST <= S_AXIS_TLAST;

   primitiveAssembly_primout_ready <= M_AXIS_TREADY when primtype=SGP_GL_POINTS else
                                      triangleSetup_triangle_in_ready when primtype=SGP_GL_TRIANGLES else
                                      triangleSetup_triangle_in_ready when primtype=SGP_GL_TRIANGLE_STRIP else
                                      triangleSetup_triangle_in_ready when primtype=SGP_GL_TRIANGLE_FAN else
                                      '0';

   -- Map the primitiveAssembly output vertex values to a single triangle for triangleSetup
   triangleSetup_triangle_in <= (0 => primitiveAssembly_V0, 1 => primitiveAssembly_V1, 2 => primitiveAssembly_V2);
   triangleSetup_triangle_in_valid <= '0' when primtype=SGP_GL_POINTS else
                                      primitiveAssembly_primout_valid when primtype=SGP_GL_TRIANGLES else
                                      primitiveAssembly_primout_valid when primtype=SGP_GL_TRIANGLE_STRIP else
                                      primitiveAssembly_primout_valid when primtype=SGP_GL_TRIANGLE_FAN else
                                      '0';
   
   
   
   -- Map the other inputs to triangleTraversal from triangleSetup. We only need the xy position of the first vertex. 
   -- Acknowledged that this is a littly ugly looking.
   triangleTraversal_startvertex <= to_vertexRecord_t(trianglesetup_triangle_out(0)); 
   triangleTraversal_startposition_in <= triangleTraversal_startvertex.att0;
   
   triangleTest_fragment_out_ready <= M_AXIS_TREADY;
   
end architecture behavioral;
