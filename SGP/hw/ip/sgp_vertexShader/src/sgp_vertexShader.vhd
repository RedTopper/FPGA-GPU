-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
 

-- sgp_vertexShader.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a vertexShader core that executes
-- compiled GLSL shader code on input vertices.
--
-- NOTES:
-- 1/07/21 by JAZ::Design created.
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.sgp_types.all;


entity sgp_vertexShader is

    generic (
		-- Parameters of AXI-Lite slave interface
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 10;

		-- Parameters of AXI master interface
		C_M_AXI_BURST_LEN	: integer	:= 16;
		C_M_AXI_ID_WIDTH	: integer	:= 4;
		C_M_AXI_ADDR_WIDTH	: integer	:= 32;
		C_M_AXI_DATA_WIDTH	: integer	:= 32;

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
		M_AXIS_TREADY	: in	std_logic;


		-- AXI master interface - dcache
		m1_axi_awid	: out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		m1_axi_awaddr	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		m1_axi_awlen	: out std_logic_vector(7 downto 0);
		m1_axi_awsize	: out std_logic_vector(2 downto 0);
		m1_axi_awburst	: out std_logic_vector(1 downto 0);
		m1_axi_awlock	: out std_logic;
		m1_axi_awcache	: out std_logic_vector(3 downto 0);
		m1_axi_awprot	: out std_logic_vector(2 downto 0);
		m1_axi_awqos	: out std_logic_vector(3 downto 0);
		m1_axi_awvalid	: out std_logic;
		m1_axi_awready	: in std_logic;
		m1_axi_wdata	    : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		m1_axi_wstrb	    : out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
		m1_axi_wlast	    : out std_logic;
		m1_axi_wvalid	: out std_logic;
		m1_axi_wready	: in std_logic;
		m1_axi_bid	    : in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		m1_axi_bresp	    : in std_logic_vector(1 downto 0);
		m1_axi_bvalid	: in std_logic;
		m1_axi_bready	: out std_logic;
		m1_axi_arid	    : out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		m1_axi_araddr	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		m1_axi_arlen	    : out std_logic_vector(7 downto 0);
		m1_axi_arsize	: out std_logic_vector(2 downto 0);
		m1_axi_arburst	: out std_logic_vector(1 downto 0);
		m1_axi_arlock	: out std_logic;
		m1_axi_arcache	: out std_logic_vector(3 downto 0);
		m1_axi_arprot	: out std_logic_vector(2 downto 0);
		m1_axi_arqos	    : out std_logic_vector(3 downto 0);
		m1_axi_arvalid	: out std_logic;
		m1_axi_arready	: in std_logic;
		m1_axi_rid	    : in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		m1_axi_rdata	    : in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		m1_axi_rresp	    : in std_logic_vector(1 downto 0);
		m1_axi_rlast	    : in std_logic;
		m1_axi_rvalid	: in std_logic;
		m1_axi_rready	: out std_logic;


		-- AXI master interface - icache
		m2_axi_awid	: out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		m2_axi_awaddr	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		m2_axi_awlen	: out std_logic_vector(7 downto 0);
		m2_axi_awsize	: out std_logic_vector(2 downto 0);
		m2_axi_awburst	: out std_logic_vector(1 downto 0);
		m2_axi_awlock	: out std_logic;
		m2_axi_awcache	: out std_logic_vector(3 downto 0);
		m2_axi_awprot	: out std_logic_vector(2 downto 0);
		m2_axi_awqos	: out std_logic_vector(3 downto 0);
		m2_axi_awvalid	: out std_logic;
		m2_axi_awready	: in std_logic;
		m2_axi_wdata	    : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		m2_axi_wstrb	    : out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
		m2_axi_wlast	    : out std_logic;
		m2_axi_wvalid	: out std_logic;
		m2_axi_wready	: in std_logic;
		m2_axi_bid	    : in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		m2_axi_bresp	    : in std_logic_vector(1 downto 0);
		m2_axi_bvalid	: in std_logic;
		m2_axi_bready	: out std_logic;
		m2_axi_arid	    : out std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		m2_axi_araddr	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		m2_axi_arlen	    : out std_logic_vector(7 downto 0);
		m2_axi_arsize	: out std_logic_vector(2 downto 0);
		m2_axi_arburst	: out std_logic_vector(1 downto 0);
		m2_axi_arlock	: out std_logic;
		m2_axi_arcache	: out std_logic_vector(3 downto 0);
		m2_axi_arprot	: out std_logic_vector(2 downto 0);
		m2_axi_arqos	    : out std_logic_vector(3 downto 0);
		m2_axi_arvalid	: out std_logic;
		m2_axi_arready	: in std_logic;
		m2_axi_rid	    : in std_logic_vector(C_M_AXI_ID_WIDTH-1 downto 0);
		m2_axi_rdata	    : in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		m2_axi_rresp	    : in std_logic_vector(1 downto 0);
		m2_axi_rlast	    : in std_logic;
		m2_axi_rvalid	: in std_logic;
		m2_axi_rready	: out std_logic);



attribute SIGIS : string; 
attribute SIGIS of ACLK : signal is "Clk"; 

end sgp_vertexShader;


architecture behavioral of sgp_vertexShader is


	-- component declaration
	component sgp_vertexShader_axi_lite_regs is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 10
		);
		port (
		S_AXI_ACLK	    : in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	    : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	    : out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	    : out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic;
		
		-- Our registers that we need to operate this core. Manually map these in axi_lite_regs
	    SGP_AXI_VERTEXSHADER_PC             : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    SGP_AXI_VERTEXSHADER_NUMVERTEX      : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    SGP_AXI_VERTEXSHADER_VAL2           : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        SGP_AXI_VERTEXSHADER_VAL3           : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        SGP_AXI_VERTEXSHADER_FLUSH          : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        sgp_axi_vertexshader_iflush         : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);	        
        SGP_AXI_VERTEXSHADER_STATUS	        : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);	        
        SGP_AXI_VERTEXSHADER_DEBUG          : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0)	    
		
		);
	end component sgp_vertexShader_axi_lite_regs;

    component dcache is
		port (
        clk_i               : in std_logic;
        rst_i               : in std_logic;
        mem_addr_i          : in std_logic_vector(31 downto 0);
        mem_data_wr_i       : in std_logic_vector(31 downto 0);
        mem_rd_i            : in std_logic;
        mem_wr_i            : in std_logic_vector(3 downto 0);
        mem_cacheable_i     : in std_logic;
        mem_req_tag_i       : in std_logic_vector(10 downto 0);
        mem_invalidate_i    : in std_logic;
        mem_writeback_i     : in std_logic;
        mem_flush_i         : in std_logic;
        axi_awready_i       : in std_logic;
        axi_wready_i        : in std_logic;
        axi_bvalid_i        : in std_logic;
        axi_bresp_i         : in std_logic_vector(1 downto 0);
        axi_bid_i           : in std_logic_vector(3 downto 0);
        axi_arready_i       : in std_logic;
        axi_rvalid_i        : in std_logic;
        axi_rdata_i         : in std_logic_vector(31 downto 0);
        axi_rresp_i         : in std_logic_vector(1 downto 0);
        axi_rid_i           : in std_logic_vector(3 downto 0);
        axi_rlast_i         : in std_logic;
        mem_data_rd_o       : out std_logic_vector(31 downto 0);
        mem_accept_o        : out std_logic;
        mem_ack_o           : out std_logic;
        mem_error_o         : out std_logic;
        mem_resp_tag_o      : out std_logic_vector(10 downto 0);
        axi_awvalid_o       : out std_logic;
        axi_awaddr_o        : out std_logic_vector(31 downto 0);
        axi_awid_o          : out std_logic_vector(3 downto 0);
        axi_awlen_o         : out std_logic_vector(7 downto 0);
        axi_awburst_o       : out std_logic_vector(1 downto 0);
        axi_wvalid_o        : out std_logic;
        axi_wdata_o         : out std_logic_vector(31 downto 0);
        axi_wstrb_o         : out std_logic_vector(3 downto 0);
        axi_wlast_o         : out std_logic;
        axi_bready_o        : out std_logic;
        axi_arvalid_o       : out std_logic;
        axi_araddr_o        : out std_logic_vector(31 downto 0);
        axi_arid_o          : out std_logic_vector(3 downto 0);
        axi_arlen_o         : out std_logic_vector(7 downto 0);
        axi_arburst_o       : out std_logic_vector(1 downto 0);
        axi_rready_o        : out std_logic);
    end component dcache;


	component icache is
		port (
        clk_i               : in std_logic;
        rst_i               : in std_logic;
        req_pc_i            : in std_logic_vector(31 downto 0);
        req_rd_i            : in std_logic;
        req_invalidate_i    : in std_logic;
        req_flush_i         : in std_logic;
        axi_awready_i       : in std_logic;
        axi_wready_i        : in std_logic;
        axi_bvalid_i        : in std_logic;
        axi_bresp_i         : in std_logic_vector(1 downto 0);
        axi_bid_i           : in std_logic_vector(3 downto 0);
        axi_arready_i       : in std_logic;
        axi_rvalid_i        : in std_logic;
        axi_rdata_i         : in std_logic_vector(31 downto 0);
        axi_rresp_i         : in std_logic_vector(1 downto 0);
        axi_rid_i           : in std_logic_vector(3 downto 0);
        axi_rlast_i         : in std_logic;
        req_accept_o        : out std_logic;
        req_valid_o         : out std_logic;
        req_error_o         : out std_logic;
        req_inst_o          : out std_logic_vector(31 downto 0);
        axi_awvalid_o       : out std_logic;
        axi_awaddr_o        : out std_logic_vector(31 downto 0);
        axi_awid_o          : out std_logic_vector(3 downto 0);
        axi_awlen_o         : out std_logic_vector(7 downto 0);
        axi_awburst_o       : out std_logic_vector(1 downto 0);
        axi_wvalid_o        : out std_logic;
        axi_wdata_o         : out std_logic_vector(31 downto 0);
        axi_wstrb_o         : out std_logic_vector(3 downto 0);
        axi_wlast_o         : out std_logic;
        axi_bready_o        : out std_logic;
        axi_arvalid_o       : out std_logic;
        axi_araddr_o        : out std_logic_vector(31 downto 0);
        axi_arid_o          : out std_logic_vector(3 downto 0);
        axi_arlen_o         : out std_logic_vector(7 downto 0);
        axi_arburst_o       : out std_logic_vector(1 downto 0);
        axi_rready_o        : out std_logic);
  end component icache;


    component vertexShader_core is

	   port (ACLK	: in	std_logic;
		 ARESETN	: in	std_logic;

         startPC          : in unsigned(31 downto 0);
         inputVertex      : in vertexArray_t;
         outputVertex     : out vertexArray_t;
         vertexStart      : in std_logic; 
         vertexDone       : out std_logic;
    
         dmem_addr        : out std_logic_vector(31 downto 0);
         dmem_wdata       : out std_logic_vector(31 downto 0);
         dmem_rdata       : in std_logic_vector(31 downto 0);
         dmem_rd_req      : out std_logic;
         dmem_wr_req      : out std_logic;
         dmem_rdy         : in std_logic;
         dmem_req_done    : in std_logic;
         
         imem_addr        : out std_logic_vector(31 downto 0);
         imem_rdata       : in std_logic_vector(31 downto 0);
         imem_rd_req      : out std_logic;
         imem_req_done    : in std_logic;
         imem_rdy         : in std_logic);
    end component vertexShader_core;

  -- User register values
  signal vertexshader_pc 	        : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal vertexshader_numvertex 	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal vertexshader_val2 	        : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal vertexshader_val3          : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal vertexshader_flush         : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal vertexshader_iflush         : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal vertexshader_status        : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal vertexshader_debug 	    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

  signal vertexshader_flush_latch   : std_logic;
  signal vertexshader_iflush_latch   : std_logic;


  -- DCache interface signals
  signal ARESET                 : std_logic;
  signal reset_scuffed          : std_logic;
  signal ireset_scuffed         : std_logic;
  signal mem_addr               : std_logic_vector(31 downto 0);
  signal mem_data_wr            : std_logic_vector(31 downto 0);
  signal mem_rd                 : std_logic;
  signal mem_wr                 : std_logic_vector(3 downto 0);
  signal mem_cacheable          : std_logic;
  signal mem_req_tag            : std_logic_vector(10 downto 0);
  signal mem_invalidate         : std_logic;
  signal mem_writeback          : std_logic;
  signal mem_flush              : std_logic;
  signal mem_flush_scuffed      : std_logic:= '0';
  signal mem_iflush_scuffed      : std_logic:= '0';
  signal mem_data_rd            : std_logic_vector(31 downto 0);
  signal mem_accept             : std_logic;
  signal mem_ack                : std_logic;
  signal mem_error              : std_logic;
  signal mem_resp_tag           : std_logic_vector(10 downto 0);

  -- ICache interface signals
  signal req_pc               : std_logic_vector(31 downto 0);
  signal req_rd               : std_logic;
  signal req_invalidate       : std_logic;
  signal req_flush            : std_logic;
  signal req_inst             : std_logic_vector(31 downto 0);
  signal req_accept           : std_logic;
  signal req_valid            : std_logic;
  signal req_error            : std_logic;


  type STATE_TYPE is (WAIT_FOR_PROGRAM, WAIT_FOR_VERTEX, WAIT_FOR_DONE, WRITE_OUTPUT);
  signal vertexShader_state        : STATE_TYPE;

  -- vertexShader_core signals
  signal vertexShader_core_startPC          : unsigned(31 downto 0);
  signal vertexShader_core_inputVertex      : vertexArray_t;
  signal vertexShader_core_outputVertex     : vertexArray_t;
  signal vertexShader_core_Start            : std_logic; 
  signal vertexShader_core_Done             : std_logic;
  signal vertexShader_vertexCount           : unsigned(31 downto 0);
  signal vertexShader_core_mem_wr           : std_logic;

begin


  -- Instantiation of Axi Bus Interface S_AXI_LITE
  sgp_vertexShader_axi_lite_regs_inst : sgp_vertexShader_axi_lite_regs
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

	    SGP_AXI_VERTEXSHADER_PC => vertexshader_pc,
	    SGP_AXI_VERTEXSHADER_NUMVERTEX  => vertexshader_numvertex,
        SGP_AXI_VERTEXSHADER_VAL2 => vertexshader_val2,
        SGP_AXI_VERTEXSHADER_VAL3    => vertexshader_val3,
        SGP_AXI_VERTEXSHADER_FLUSH  => vertexshader_flush,
        SGP_AXI_VERTEXSHADER_IFLUSH  => vertexshader_iflush,	    		
        SGP_AXI_VERTEXSHADER_STATUS    => vertexshader_status,	    		
        SGP_AXI_VERTEXSHADER_DEBUG => vertexshader_debug
	);


    -- Cache components' reset are active high
    ARESET <= not ARESETn;

  -- Instantation of dcache
  sgp_vertexShader_dcache : dcache
		port map (
        clk_i               => ACLK,
        rst_i               => reset_scuffed,
        mem_addr_i          => mem_addr,
        mem_data_wr_i       => mem_data_wr,
        mem_rd_i            => mem_rd,
        mem_wr_i            => mem_wr,
        mem_cacheable_i     => mem_cacheable,
        mem_req_tag_i       => mem_req_tag,
        mem_invalidate_i    => mem_invalidate,
        mem_writeback_i     => mem_writeback,
        mem_flush_i         => mem_flush,
        axi_awready_i       => m1_axi_awready,
        axi_wready_i        => m1_axi_wready,
        axi_bvalid_i        => m1_axi_bvalid,
        axi_bresp_i         => m1_axi_bresp,
        axi_bid_i           => m1_axi_bid,
        axi_arready_i       => m1_axi_arready,
        axi_rvalid_i        => m1_axi_rvalid,
        axi_rdata_i         => m1_axi_rdata,
        axi_rresp_i         => m1_axi_rresp,
        axi_rid_i           => m1_axi_rid,
        axi_rlast_i         => m1_axi_rlast,
        mem_data_rd_o       => mem_data_rd,
        mem_accept_o        => mem_accept,
        mem_ack_o           => mem_ack,
        mem_error_o         => mem_error,
        mem_resp_tag_o      => mem_resp_tag,
        axi_awvalid_o       => m1_axi_awvalid,
        axi_awaddr_o        => m1_axi_awaddr,
        axi_awid_o          => m1_axi_awid,
        axi_awlen_o         => m1_axi_awlen,
        axi_awburst_o       => m1_axi_awburst,
        axi_wvalid_o        => m1_axi_wvalid,
        axi_wdata_o         => m1_axi_wdata,
        axi_wstrb_o         => m1_axi_wstrb,
        axi_wlast_o         => m1_axi_wlast,
        axi_bready_o        => m1_axi_bready,
        axi_arvalid_o       => m1_axi_arvalid,
        axi_araddr_o        => m1_axi_araddr,
        axi_arid_o          => m1_axi_arid,
        axi_arlen_o         => m1_axi_arlen,
        axi_arburst_o       => m1_axi_arburst,
        axi_rready_o        => m1_axi_rready);



  -- Instantation of dcache
  sgp_vertexShader_icache : icache
		port map (
        clk_i               => ACLK,
        rst_i               => ireset_scuffed,
        req_pc_i            => req_pc,
        req_rd_i            => req_rd,
        req_invalidate_i    => req_invalidate,
        req_flush_i         => req_flush,
        axi_awready_i       => m2_axi_awready,
        axi_wready_i        => m2_axi_wready,
        axi_bvalid_i        => m2_axi_bvalid,
        axi_bresp_i         => m2_axi_bresp,
        axi_bid_i           => m2_axi_bid,
        axi_arready_i       => m2_axi_arready,
        axi_rvalid_i        => m2_axi_rvalid,
        axi_rdata_i         => m2_axi_rdata,
        axi_rresp_i         => m2_axi_rresp,
        axi_rid_i           => m2_axi_rid,
        axi_rlast_i         => m2_axi_rlast,
        req_accept_o        => req_accept,
        req_valid_o         => req_valid,
        req_error_o         => req_error,
        req_inst_o          => req_inst,
        axi_awvalid_o       => m2_axi_awvalid,
        axi_awaddr_o        => m2_axi_awaddr,
        axi_awid_o          => m2_axi_awid,
        axi_awlen_o         => m2_axi_awlen,
        axi_awburst_o       => m2_axi_awburst,
        axi_wvalid_o        => m2_axi_wvalid,
        axi_wdata_o         => m2_axi_wdata,
        axi_wstrb_o         => m2_axi_wstrb,
        axi_wlast_o         => m2_axi_wlast,
        axi_bready_o        => m2_axi_bready,
        axi_arvalid_o       => m2_axi_arvalid,
        axi_araddr_o        => m2_axi_araddr,
        axi_arid_o          => m2_axi_arid,
        axi_arlen_o         => m2_axi_arlen,
        axi_arburst_o       => m2_axi_arburst,
        axi_rready_o        => m2_axi_rready);


    -- We'll never want to write to part of a word, so expand the single bit of write request
    mem_wr <= "1111" when vertexShader_core_mem_wr = '1' else "0000";

    sgp_vertexShader_core : vertexShader_core
	   port map(ACLK => ACLK,
                ARESETN => ARESETN,
                startPC => vertexShader_core_startPC,
                inputVertex => vertexShader_core_inputVertex,
                outputVertex => vertexShader_core_outputVertex,
                vertexStart => vertexShader_core_Start,
                vertexDone => vertexShader_core_Done,
                dmem_addr => mem_addr,
                dmem_wdata => mem_data_wr,
                dmem_rdata => mem_data_rd,
                dmem_rd_req => mem_rd,
                dmem_wr_req => vertexShader_core_mem_wr,
                dmem_rdy => mem_accept, 
                dmem_req_done => mem_ack,
                imem_addr => req_pc,
                imem_rdata => req_inst,
                imem_rdy => req_accept,
                imem_rd_req => req_rd,
                imem_req_done => req_valid);


  -- Many of the AXI signals can be hard-coded for our purposes. 
    m1_axi_awsize   <= "010";             -- AXI Write Burst Size. Set to 2 for 2^2=4 bytes for the write
    m1_axi_awlock   <= '0';               -- AXI Write Lock. Not supported in AXI-4
    m1_axi_awcache  <= "1111";            -- AXI Write Cache. Check the cache, and return a write response from the cache (vs final destination)
    m1_axi_awprot   <= "000";             -- AXI Write Protection. No special protection needed here. 
    m1_axi_awqos    <= "0000";            -- AXI Write QoS. Not used

    m1_axi_arsize   <= "010";             -- AXI Read Burst Size. Set to 2 for 2^2=4 bytes for the read
    m1_axi_arlock   <= '0';               -- AXI Read Lock. Not supported in AXI-4
    m1_axi_arcache  <= "1111";            -- AXI Read Cache. Check the cache, and return a read response from the cache (vs final destination)
    m1_axi_arprot   <= "000";             -- AXI Read Protection. No special protection needed here. 
    m1_axi_arqos    <= "0000";            -- AXI Read QoS. Not used

    m2_axi_awsize   <= "010";             -- AXI Write Burst Size. Set to 2 for 2^2=4 bytes for the write
    m2_axi_awlock   <= '0';               -- AXI Write Lock. Not supported in AXI-4
    m2_axi_awcache  <= "1111";            -- AXI Write Cache. Check the cache, and return a write response from the cache (vs final destination)
    m2_axi_awprot   <= "000";             -- AXI Write Protection. No special protection needed here. 
    m2_axi_awqos    <= "0000";            -- AXI Write QoS. Not used

    m2_axi_arsize   <= "010";             -- AXI Read Burst Size. Set to 2 for 2^2=4 bytes for the read
    m2_axi_arlock   <= '0';               -- AXI Read Lock. Not supported in AXI-4
    m2_axi_arcache  <= "1111";            -- AXI Read Cache. Check the cache, and return a read response from the cache (vs final destination)
    m2_axi_arprot   <= "000";             -- AXI Read Protection. No special protection needed here. 
    m2_axi_arqos    <= "0000";            -- AXI Read QoS. Not used



    -- We can assign some of the cache inputs to constants or control registers as well
    mem_cacheable   <= '1';   -- Process request through cache
    mem_req_tag     <= (others => '0');             -- Request tag - useful for tracking requests
    mem_flush       <= '0';
    mem_invalidate  <= '0';   -- Invalidate address
    mem_writeback   <= '0';   -- Writeback request to memory through cache
      -- Flush entire cache

    req_invalidate  <= '0';
    req_flush       <= '0';

    S_AXIS_TREADY <= '1' when vertexShader_state = WAIT_FOR_VERTEX else
                     '0';
    M_AXIS_TVALID <= '1' when vertexShader_state = WRITE_OUTPUT else
                     '0';

  -- At least set a unique ID for each synthesis run in the debug register, so we know that we're looking at the most recent IP core
  -- It would also be useful to connect internal signals to this register for software debug purposes
  vertexshader_debug <= x"00000044";
  vertexshader_status <= x"00000000";

 -- vertexshader_flush_latch <= '1' when vertexshader_flush /= x"00000000" else 
 --                              '0' when vertexShader_state = WAIT_FOR_PROGRAM else vertexshader_flush_latch ;

  vertexshader_iflush_latch <= '1' when vertexshader_iflush /= x"00000000" else 
                              '0' when vertexShader_state = WAIT_FOR_PROGRAM else vertexshader_iflush_latch ;


  reset_scuffed <= ARESET or mem_flush_scuffed;
  ireset_scuffed <= ARESET or mem_iflush_scuffed;

   process (ACLK) is
   begin 
    if rising_edge(ACLK) then  
      -- Reset all design registers
      if ARESETN = '0' then    
        vertexShader_core_startPC <= (others => '0');
        vertexShader_core_inputVertex <= vertexArray_t_zero;
        vertexShader_core_Start <= '0';
        vertexShader_vertexCount <= (others => '0');
        vertexShader_state <= WAIT_FOR_PROGRAM;
        M_AXIS_TDATA <= (others => '0');  
        mem_flush_scuffed       <= '0';
        mem_iflush_scuffed       <= '0';      
      else

        case vertexShader_state is

            -- Wait here until we get an updated PC from the driver
            when WAIT_FOR_PROGRAM =>
            mem_flush_scuffed <= '0';
            mem_iflush_scuffed <= '0';
                if (unsigned(vertexshader_pc) >= x"80000000") then
                    vertexShader_core_startPC <= unsigned(vertexshader_pc);
                    vertexShader_state <= WAIT_FOR_VERTEX;
                end if; 
            
            when WAIT_FOR_VERTEX =>
                mem_flush_scuffed <= '0';
                mem_iflush_scuffed <= '0';
                if (S_AXIS_TVALID = '1') then
                    vertexShader_core_inputVertex <= to_vertexArray_t(signed(S_AXIS_TDATA));
                    vertexShader_core_Start <= '1';
                    vertexShader_state <= WAIT_FOR_DONE;
                end if;
                if(vertexshader_iflush_latch = '1')then
                    mem_iflush_scuffed <= '1';
                    vertexShader_state <= WAIT_FOR_PROGRAM;
                end if;

            when WAIT_FOR_DONE =>
                vertexShader_core_Start <= '0';
                if (vertexShader_core_Done = '1') then
                    M_AXIS_TDATA <= std_logic_vector(to_vertexVector_t(vertexShader_core_outputVertex));
                    vertexShader_vertexCount <= vertexShader_vertexCount + 1;
                    if (vertexShader_vertexCount = unsigned(vertexshader_numvertex)) then
                        vertexShader_vertexCount <= (others => '0');
                        vertexshader_flush_latch <= '1';
                        M_AXIS_TLAST <= '1';
                    else
                        M_AXIS_TLAST <= '0';
                    end if;
                    vertexShader_state <= WRITE_OUTPUT;
                end if;            
            
            when WRITE_OUTPUT =>
                if (M_AXIS_TREADY = '1') then
                    if(vertexshader_flush_latch = '1')then
                        mem_flush_scuffed <='1';
                        vertexshader_flush_latch <= '0';
                    end if;
                    if(vertexshader_iflush_latch = '1')then
                        mem_iflush_scuffed <= '1';
                        vertexShader_state <= WAIT_FOR_PROGRAM;
                    else
                        vertexShader_state <= WAIT_FOR_VERTEX;   
                    end if;
                              
                end if;
          end case;
       end if;
    end if;
   end process;
end architecture behavioral;
