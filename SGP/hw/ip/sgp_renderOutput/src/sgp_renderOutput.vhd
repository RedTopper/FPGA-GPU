-------------------------------------------------------------------------
-- Joseph Zambreno and Ben Pierre but definitely note Dawson Munday
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------
-- sgp_renderOutput.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a Render Output (ROP) core that calculates
-- addresses and stores pixels based on incoming fragments. 
--
-- NOTES:
-- 12/01/20 by JAZ::Design created.
-------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE WORK.sgp_types.ALL;
ENTITY sgp_renderOutput IS

  GENERIC (
    -- Parameters of AXI-Lite slave interface
    C_S_AXI_DATA_WIDTH : INTEGER := 32;
    C_S_AXI_ADDR_WIDTH : INTEGER := 10;

    -- Parameters of AXI master interface
    C_M_AXI_BURST_LEN : INTEGER := 16;
    C_M_AXI_ID_WIDTH : INTEGER := 4;
    C_M_AXI_ADDR_WIDTH : INTEGER := 32;
    C_M_AXI_DATA_WIDTH : INTEGER := 32;

    -- Parameters for output vertex attribute stream
    C_NUM_VERTEX_ATTRIB : INTEGER := 4
  );

  PORT (
    ACLK : IN STD_LOGIC;
    ARESETN : IN STD_LOGIC;

    -- Ports of AXI-Lite slave interface
    s_axi_lite_awaddr : IN STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH - 1 DOWNTO 0);
    s_axi_lite_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi_lite_awvalid : IN STD_LOGIC;
    s_axi_lite_awready : OUT STD_LOGIC;
    s_axi_lite_wdata : IN STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
    s_axi_lite_wstrb : IN STD_LOGIC_VECTOR((C_S_AXI_DATA_WIDTH/8) - 1 DOWNTO 0);
    s_axi_lite_wvalid : IN STD_LOGIC;
    s_axi_lite_wready : OUT STD_LOGIC;
    s_axi_lite_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_lite_bvalid : OUT STD_LOGIC;
    s_axi_lite_bready : IN STD_LOGIC;
    s_axi_lite_araddr : IN STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH - 1 DOWNTO 0);
    s_axi_lite_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi_lite_arvalid : IN STD_LOGIC;
    s_axi_lite_arready : OUT STD_LOGIC;
    s_axi_lite_rdata : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
    s_axi_lite_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_lite_rvalid : OUT STD_LOGIC;
    s_axi_lite_rready : IN STD_LOGIC;
    -- AXIS slave interface
    S_AXIS_TREADY : OUT STD_LOGIC;
    S_AXIS_TDATA : IN STD_LOGIC_VECTOR(C_NUM_VERTEX_ATTRIB * 128 - 1 DOWNTO 0);
    S_AXIS_TLAST : IN STD_LOGIC;
    S_AXIS_TVALID : IN STD_LOGIC;

    -- AXI master interface
    m_axi_awid : OUT STD_LOGIC_VECTOR(C_M_AXI_ID_WIDTH - 1 DOWNTO 0);
    m_axi_awaddr : OUT STD_LOGIC_VECTOR(C_M_AXI_ADDR_WIDTH - 1 DOWNTO 0);
    m_axi_awlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axi_awsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_awburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_awlock : OUT STD_LOGIC;
    m_axi_awcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_awqos : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_awvalid : OUT STD_LOGIC;
    m_axi_awready : IN STD_LOGIC;
    m_axi_wdata : OUT STD_LOGIC_VECTOR(C_M_AXI_DATA_WIDTH - 1 DOWNTO 0);
    m_axi_wstrb : OUT STD_LOGIC_VECTOR(C_M_AXI_DATA_WIDTH/8 - 1 DOWNTO 0);
    m_axi_wlast : OUT STD_LOGIC;
    m_axi_wvalid : OUT STD_LOGIC;
    m_axi_wready : IN STD_LOGIC;
    m_axi_bid : IN STD_LOGIC_VECTOR(C_M_AXI_ID_WIDTH - 1 DOWNTO 0);
    m_axi_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_bvalid : IN STD_LOGIC;
    m_axi_bready : OUT STD_LOGIC;
    m_axi_arid : OUT STD_LOGIC_VECTOR(C_M_AXI_ID_WIDTH - 1 DOWNTO 0);
    m_axi_araddr : OUT STD_LOGIC_VECTOR(C_M_AXI_ADDR_WIDTH - 1 DOWNTO 0);
    m_axi_arlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    m_axi_arsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_arburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_arlock : OUT STD_LOGIC;
    m_axi_arcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_arprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_arqos : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_arvalid : OUT STD_LOGIC;
    m_axi_arready : IN STD_LOGIC;
    m_axi_rid : IN STD_LOGIC_VECTOR(C_M_AXI_ID_WIDTH - 1 DOWNTO 0);
    m_axi_rdata : IN STD_LOGIC_VECTOR(C_M_AXI_DATA_WIDTH - 1 DOWNTO 0);
    m_axi_rresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_rlast : IN STD_LOGIC;
    m_axi_rvalid : IN STD_LOGIC;
    m_axi_rready : OUT STD_LOGIC);

  ATTRIBUTE SIGIS : STRING;
  ATTRIBUTE SIGIS OF ACLK : SIGNAL IS "Clk";

END sgp_renderOutput;
ARCHITECTURE behavioral OF sgp_renderOutput IS
  -- component declaration
  COMPONENT sgp_renderOutput_axi_lite_regs IS
    GENERIC (
      C_S_AXI_DATA_WIDTH : INTEGER := 32;
      C_S_AXI_ADDR_WIDTH : INTEGER := 10
    );
    PORT (
      S_AXI_ACLK : IN STD_LOGIC;
      S_AXI_ARESETN : IN STD_LOGIC;
      S_AXI_AWADDR : IN STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH - 1 DOWNTO 0);
      S_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S_AXI_AWVALID : IN STD_LOGIC;
      S_AXI_AWREADY : OUT STD_LOGIC;
      S_AXI_WDATA : IN STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      S_AXI_WSTRB : IN STD_LOGIC_VECTOR((C_S_AXI_DATA_WIDTH/8) - 1 DOWNTO 0);
      S_AXI_WVALID : IN STD_LOGIC;
      S_AXI_WREADY : OUT STD_LOGIC;
      S_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S_AXI_BVALID : OUT STD_LOGIC;
      S_AXI_BREADY : IN STD_LOGIC;
      S_AXI_ARADDR : IN STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH - 1 DOWNTO 0);
      S_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S_AXI_ARVALID : IN STD_LOGIC;
      S_AXI_ARREADY : OUT STD_LOGIC;
      S_AXI_RDATA : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      S_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S_AXI_RVALID : OUT STD_LOGIC;
      S_AXI_RREADY : IN STD_LOGIC;

      -- Our registers that we need to operate this core. Manually map these in axi_lite_regs
      SGP_AXI_RENDEROUTPUT_COLORBUFFER        : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_DEPTHBUFFER        : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_CACHECTRL          : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_STRIDE             : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_HEIGHT             : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_DEPTHENA           : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_DEPTHCTRL          : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_BLENDENA           : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_BLENDCTRL_SFACTOR  : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_BLENDCTRL_DFACTOR  : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_TEXTURE            : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_TEXTURE_WIDTH	  : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_TEXTURE_HEIGHT	  : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_DEBUG              : IN STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_STATUS             : IN STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0)
    );
  END COMPONENT sgp_renderOutput_axi_lite_regs;

  COMPONENT dcache IS
    PORT (
      clk_i : IN STD_LOGIC;
      rst_i : IN STD_LOGIC;
      mem_addr_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      mem_data_wr_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      mem_rd_i : IN STD_LOGIC;
      mem_wr_i : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      mem_cacheable_i : IN STD_LOGIC;
      mem_req_tag_i : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
      mem_invalidate_i : IN STD_LOGIC;
      mem_writeback_i : IN STD_LOGIC;
      mem_flush_i : IN STD_LOGIC;
      axi_awready_i : IN STD_LOGIC;
      axi_wready_i : IN STD_LOGIC;
      axi_bvalid_i : IN STD_LOGIC;
      axi_bresp_i : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_bid_i : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_arready_i : IN STD_LOGIC;
      axi_rvalid_i : IN STD_LOGIC;
      axi_rdata_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      axi_rresp_i : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_rid_i : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_rlast_i : IN STD_LOGIC;
      mem_data_rd_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      mem_accept_o : OUT STD_LOGIC;
      mem_ack_o : OUT STD_LOGIC;
      mem_error_o : OUT STD_LOGIC;
      mem_resp_tag_o : OUT STD_LOGIC_VECTOR(10 DOWNTO 0);
      axi_awvalid_o : OUT STD_LOGIC;
      axi_awaddr_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      axi_awid_o : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_awlen_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      axi_awburst_o : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_wvalid_o : OUT STD_LOGIC;
      axi_wdata_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      axi_wstrb_o : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_wlast_o : OUT STD_LOGIC;
      axi_bready_o : OUT STD_LOGIC;
      axi_arvalid_o : OUT STD_LOGIC;
      axi_araddr_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      axi_arid_o : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      axi_arlen_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      axi_arburst_o : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axi_rready_o : OUT STD_LOGIC);
  END COMPONENT dcache;

  TYPE STATE_TYPE IS (WAIT_FOR_FRAGMENT, GEN_ADDRESS, GEN_ADDRESS_2, LOAD_DEPTH, WAIT_LOAD_DEPTH, CALC_DEPTH, WRITE_DEPTH, WAIT_DEPTH_RESPONSE, LOAD_RGBA, WAIT_FOR_RGBA, BLEND, FACTOR_FUNC, WAIT_LOAD_TEXTURE, TEXTURE, WRITE_ADDRESS, WAIT_FOR_RESPONSE);
  SIGNAL state : STATE_TYPE;

  TYPE BLEND_STATE_TYPE IS (FACTOR_CALC, CALC, MIN_VALS);
  SIGNAL BlendingState : BLEND_STATE_TYPE;
  -- User register values
  SIGNAL renderoutput_colorbuffer : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_depthbuffer : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_cachectrl : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_stride : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_depthEna : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_depthcrtl : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_blendEna : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_blendcrtl_sfactor : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_blendcrtl_dfactor : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_texture           : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_texture_width     : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_texture_height    : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_height : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_debug : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_status : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);

  SIGNAL input_fragment : vertexVector_t;
  SIGNAL input_fragment_array : vertexArray_t;

  -- Cache interface signals
  SIGNAL ARESET : STD_LOGIC;
  SIGNAL mem_addr : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL mem_data_wr : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL mem_rd : STD_LOGIC;
  SIGNAL mem_wr : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL mem_cacheable : STD_LOGIC;
  SIGNAL mem_req_tag : STD_LOGIC_VECTOR(10 DOWNTO 0);
  SIGNAL mem_invalidate : STD_LOGIC;
  SIGNAL mem_writeback : STD_LOGIC;
  SIGNAL mem_flush : STD_LOGIC;
  SIGNAL mem_data_rd : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL mem_rd_data_stored : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL mem_accept : STD_LOGIC;
  SIGNAL mem_ack : STD_LOGIC;
  SIGNAL mem_error : STD_LOGIC;
  SIGNAL mem_resp_tag : STD_LOGIC_VECTOR(10 DOWNTO 0);

  -- Renaming signals to simplify address and data calculation
  SIGNAL x_pos_fixed : fixed_t;
  SIGNAL x_pos_short : signed(15 DOWNTO 0);
  SIGNAL x_pos_short_reg : signed(15 DOWNTO 0);
  SIGNAL y_pos_fixed : fixed_t;
  SIGNAL y_pos_short : signed(15 DOWNTO 0);
  SIGNAL y_pos_short_reg : signed(15 DOWNTO 0);
  SIGNAL z_pos : signed(31 DOWNTO 0);
  SIGNAL frag_address : signed(31 DOWNTO 0);
  SIGNAL frag_color   : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL UVX_short    : unsigned(15 DOWNTO 0);
  SIGNAL UVY_short    : unsigned(15 DOWNTO 0);
  SIGNAL a_color      : wfixed_t;
  SIGNAL r_color      : wfixed_t;
  SIGNAL g_color      : wfixed_t;
  SIGNAL b_color      : wfixed_t;
  SIGNAL a_color_reg  : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL r_color_reg  : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL g_color_reg  : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL b_color_reg  : STD_LOGIC_VECTOR(7 DOWNTO 0);


  SIGNAL sourceFactorR, sourceFactorG, sourceFactorB, sourceFactorA : STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL destFactorR, destFactorG, destFactorB, destFactorA : STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL calcValR, calcValB, calcValG, calcValA : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL oneQ8 : unsigned(15 DOWNTO 0) := b"0000000100000000";
  SIGNAL outputValR, outputValB, outputValG, outputValA : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL rgbaCounter : INTEGER RANGE 0 TO 4;
  CONSTANT GL_LESS : STD_LOGIC_VECTOR(15 DOWNTO 0)    := x"0201";
  CONSTANT GL_ALWAYS : STD_LOGIC_VECTOR(15 DOWNTO 0)  := x"0207";
  CONSTANT GL_NEVER : STD_LOGIC_VECTOR(15 DOWNTO 0)   := x"0200";
  CONSTANT GL_EQUAL : STD_LOGIC_VECTOR(15 DOWNTO 0)   := x"0202";
  CONSTANT GL_LEQUAL : STD_LOGIC_VECTOR(15 DOWNTO 0)  := x"0203";
  CONSTANT GL_GREATER : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0204";
  CONSTANT GL_NOTEQUAL : STD_LOGIC_VECTOR(15 DOWNTO 0):= x"0205";
  CONSTANT GL_GEQUAL : STD_LOGIC_VECTOR(15 DOWNTO 0)  := x"0206";

  CONSTANT GL_ZERO : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0000";
  CONSTANT GL_ONE : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0001";
  CONSTANT GL_SRC_COLOR : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0300";
  CONSTANT GL_ONE_MINUS_SRC_COLOR : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0301";
  CONSTANT GL_SRC_ALPHA : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0302";
  CONSTANT GL_ONE_MINUS_SRC_ALPHA : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0303";
  CONSTANT GL_DST_ALPHA : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0304";
  CONSTANT GL_ONE_MINUS_DST_ALPHA : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0305";
  CONSTANT GL_SRC_ALPHA_SATURATE : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0305";
  CONSTANT GL_DST_COLOR : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0306";
  CONSTANT GL_ONE_MINUS_DST_COLOR : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0307";
  CONSTANT BLEND_MAX_R : unsigned(31 DOWNTO 0) := "00000000111111110000000000000000";
  CONSTANT BLEND_MAX_B : unsigned(31 DOWNTO 0) := "00000000111111110000000000000000";
  CONSTANT BLEND_MAX_G : unsigned(31 DOWNTO 0) := "00000000111111110000000000000000";
  CONSTANT BLEND_MAX_A : unsigned(31 DOWNTO 0) := "00000000111111110000000000000000";

  ALIAS XPosShort : signed(15 DOWNTO 0) IS input_fragment_array(0)(0)(31 DOWNTO 16);
  ALIAS YPosShort : signed(15 DOWNTO 0) IS input_fragment_array(0)(1)(31 DOWNTO 16);
  ALIAS XPosShortRnd : signed(1 DOWNTO 0) IS input_fragment_array(0)(0)(16 DOWNTO 15);
  ALIAS YPosShortRnd : signed(1 DOWNTO 0) IS input_fragment_array(0)(1)(16 DOWNTO 15);
  ALIAS zPosShort : signed(31 DOWNTO 0) IS input_fragment_array(0)(2)(31 DOWNTO 0);

  ALIAS DepthENA : STD_LOGIC IS renderoutput_depthEna(0);
  ALIAS DepthCtrl : STD_LOGIC_VECTOR(15 DOWNTO 0) IS renderoutput_depthcrtl(15 DOWNTO 0);
  ALIAS BlendENA : STD_LOGIC IS renderoutput_blendEna(0);
  ALIAS TextureENA : STD_LOGIC IS input_fragment_array(2)(3)(0);

BEGIN
  -- Instantiation of Axi Bus Interface S_AXI_LITE
  sgp_renderOutput_axi_lite_regs_inst : sgp_renderOutput_axi_lite_regs
  GENERIC MAP(
    C_S_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH,
    C_S_AXI_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH
  )

  PORT MAP(
    S_AXI_ACLK => ACLK,
    S_AXI_ARESETN => ARESETN,
    S_AXI_AWADDR => s_axi_lite_awaddr,
    S_AXI_AWPROT => s_axi_lite_awprot,
    S_AXI_AWVALID => s_axi_lite_awvalid,
    S_AXI_AWREADY => s_axi_lite_awready,
    S_AXI_WDATA => s_axi_lite_wdata,
    S_AXI_WSTRB => s_axi_lite_wstrb,
    S_AXI_WVALID => s_axi_lite_wvalid,
    S_AXI_WREADY => s_axi_lite_wready,
    S_AXI_BRESP => s_axi_lite_bresp,
    S_AXI_BVALID => s_axi_lite_bvalid,
    S_AXI_BREADY => s_axi_lite_bready,
    S_AXI_ARADDR => s_axi_lite_araddr,
    S_AXI_ARPROT => s_axi_lite_arprot,
    S_AXI_ARVALID => s_axi_lite_arvalid,
    S_AXI_ARREADY => s_axi_lite_arready,
    S_AXI_RDATA => s_axi_lite_rdata,
    S_AXI_RRESP => s_axi_lite_rresp,
    S_AXI_RVALID => s_axi_lite_rvalid,
    S_AXI_RREADY => s_axi_lite_rready,

    SGP_AXI_RENDEROUTPUT_COLORBUFFER => renderoutput_colorbuffer,
    SGP_AXI_RENDEROUTPUT_DEPTHBUFFER => renderoutput_depthbuffer,
    SGP_AXI_RENDEROUTPUT_CACHECTRL => renderoutput_cachectrl,
    SGP_AXI_RENDEROUTPUT_STRIDE => renderoutput_stride,
    SGP_AXI_RENDEROUTPUT_HEIGHT => renderoutput_height,
    SGP_AXI_RENDEROUTPUT_DEPTHENA => renderoutput_depthEna,
    SGP_AXI_RENDEROUTPUT_DEPTHCTRL => renderoutput_depthcrtl,
    SGP_AXI_RENDEROUTPUT_BLENDENA => renderoutput_blendEna,
    SGP_AXI_RENDEROUTPUT_BLENDCTRL_SFACTOR => renderoutput_blendcrtl_sfactor,
    SGP_AXI_RENDEROUTPUT_BLENDCTRL_DFACTOR => renderoutput_blendcrtl_dfactor,
    SGP_AXI_RENDEROUTPUT_TEXTURE            => renderoutput_texture,
    SGP_AXI_RENDEROUTPUT_TEXTURE_WIDTH      => renderoutput_texture_width,
    SGP_AXI_RENDEROUTPUT_TEXTURE_HEIGHT     => renderoutput_texture_height,
    SGP_AXI_RENDEROUTPUT_DEBUG => renderoutput_debug,
    SGP_AXI_RENDEROUTPUT_STATUS => renderoutput_status
  );
  -- Cache component's reset is active high
  ARESET <= NOT ARESETn;

  -- Instantation of cache
  sgp_renderOutput_dcache : dcache
  PORT MAP(
    clk_i => ACLK,
    rst_i => ARESET,
    mem_addr_i => mem_addr,
    mem_data_wr_i => mem_data_wr,
    mem_rd_i => mem_rd,
    mem_wr_i => mem_wr,
    mem_cacheable_i => mem_cacheable,
    mem_req_tag_i => mem_req_tag,
    mem_invalidate_i => mem_invalidate,
    mem_writeback_i => mem_writeback,
    mem_flush_i => mem_flush,
    axi_awready_i => m_axi_awready,
    axi_wready_i => m_axi_wready,
    axi_bvalid_i => m_axi_bvalid,
    axi_bresp_i => m_axi_bresp,
    axi_bid_i => m_axi_bid,
    axi_arready_i => m_axi_arready,
    axi_rvalid_i => m_axi_rvalid,
    axi_rdata_i => m_axi_rdata,
    axi_rresp_i => m_axi_rresp,
    axi_rid_i => m_axi_rid,
    axi_rlast_i => m_axi_rlast,
    mem_data_rd_o => mem_data_rd,
    mem_accept_o => mem_accept,
    mem_ack_o => mem_ack,
    mem_error_o => mem_error,
    mem_resp_tag_o => mem_resp_tag,
    axi_awvalid_o => m_axi_awvalid,
    axi_awaddr_o => m_axi_awaddr,
    axi_awid_o => m_axi_awid,
    axi_awlen_o => m_axi_awlen,
    axi_awburst_o => m_axi_awburst,
    axi_wvalid_o => m_axi_wvalid,
    axi_wdata_o => m_axi_wdata,
    axi_wstrb_o => m_axi_wstrb,
    axi_wlast_o => m_axi_wlast,
    axi_bready_o => m_axi_bready,
    axi_arvalid_o => m_axi_arvalid,
    axi_araddr_o => m_axi_araddr,
    axi_arid_o => m_axi_arid,
    axi_arlen_o => m_axi_arlen,
    axi_arburst_o => m_axi_arburst,
    axi_rready_o => m_axi_rready);
  --slighlty out of order but it makes the defaults thing easier.
  -- Many of the AXI signals can be hard-coded for our purposes. 
  m_axi_awsize <= "010"; -- AXI Write Burst Size. Set to 2 for 2^2=4 bytes for the write
  m_axi_awlock <= '0'; -- AXI Write Lock. Not supported in AXI-4
  m_axi_awcache <= "1111"; -- AXI Write Cache. Check the cache, and return a write response from the cache (vs final destination)
  m_axi_awprot <= "000"; -- AXI Write Protection. No special protection needed here. 
  m_axi_awqos <= "0000"; -- AXI Write QoS. Not used

  m_axi_arsize <= "010"; -- AXI Read Burst Size. Set to 2 for 2^2=4 bytes for the write
  m_axi_arlock <= '0'; -- AXI Read Lock. Not supported in AXI-4
  m_axi_arcache <= "1111"; -- AXI Read Cache. Check the cache, and return a write response from the cache (vs final destination)
  m_axi_arprot <= "000"; -- AXI Read Protection. No special protection needed here. 
  m_axi_arqos <= "0000"; -- AXI Read QoS. Not used

  -- We can assign some of the cache inputs to constants or control registers as well
  mem_cacheable <= renderoutput_cachectrl(0); -- Process request through cache
  mem_req_tag <= (OTHERS => '0'); -- Request tag - useful for tracking requests
  mem_invalidate <= renderoutput_cachectrl(1); -- Invalidate address
  mem_writeback <= renderoutput_cachectrl(2); -- Writeback request to memory through cache
  mem_flush <= renderoutput_cachectrl(3);

  S_AXIS_TREADY <= '1' WHEN state = WAIT_FOR_FRAGMENT ELSE
    '0';

  -- The vertexArray_t data types will make this code look much cleaner
  input_fragment_array <= to_vertexArray_t(input_fragment);

  -- Our framebuffer is currently ARBG, so we have to re-assemble a bit. We only need the integer values now
  -- At least set a unique ID for each synthesis run in the debug register, so we know that we're looking at the most recent IP core
  -- It would also be useful to connect internal signals to this register for software debug purposes
  renderoutput_debug <= x"00000073";
  -- A 4-state FSM, where we copy fragments, determine the address and color from the input attributes, 
  -- and generate an AXI Write request based on that data.
  --! fsm_extract
  PROCESS (ACLK) IS
  BEGIN
    IF rising_edge(ACLK) THEN
      IF ARESETN = '0' THEN

        -- Start at WAIT_FOR_FRAGMENT and initialize all other registers
        state <= WAIT_FOR_FRAGMENT;
        BlendingState <= Factor_calc;
        mem_addr <= (OTHERS => '0');
        mem_data_wr <= (OTHERS => '0');
        mem_rd <= '0';
        mem_wr <= (OTHERS => '0');
        input_fragment <= vertexVector_t_zero;
        x_pos_short_reg <= (OTHERS => '0');
        y_pos_short_reg <= (OTHERS => '0');
        a_color_reg <= (OTHERS => '0');
        r_color_reg <= (OTHERS => '0');
        b_color_reg <= (OTHERS => '0');
        g_color_reg <= (OTHERS => '0');
        mem_flush <= '0';
        renderoutput_status <= (OTHERS => '0');
        rgbaCounter <= 0;

      ELSE
        CASE state IS
            --(WAIT_FOR_FRAGMENT, GEN_ADDRESS, WRITE_ADDRESS, WAIT_FOR_RESPONSE);
            -- Wait here until we receive a fragment
          WHEN WAIT_FOR_FRAGMENT =>
            IF (S_AXIS_TVALID = '1') THEN
              renderoutput_status <= (OTHERS => '0');
              input_fragment <= signed(S_AXIS_TDATA);
              state <= GEN_ADDRESS;
            END IF;

          WHEN GEN_ADDRESS =>
            --busy
            renderoutput_status <= (OTHERS => '1');

            --fragment = potential pixel
            x_pos_short_reg <= input_fragment_array(0)(0)(31 DOWNTO 16) + input_fragment_array(0)(0)(15 DOWNTO 15); --(rounding)
            y_pos_short_reg <= input_fragment_array(0)(1)(31 DOWNTO 16) + input_fragment_array(0)(1)(15 DOWNTO 15); --(rounding)
            z_pos <= signed(zPosShort); --technically not a short but it follows naming conventions.

            UVX_short <= unsigned(input_fragment_array(2)(0)(31 DOWNTO 16));
            UVY_short <= unsigned(input_fragment_array(2)(1)(31 DOWNTO 16));
            STATE <= GEN_ADDRESS_2;

          WHEN GEN_ADDRESS_2 =>
            --we will say the order is argb, I don't think it matters as long as we are consistent.
            --multiple [0, 1.0] by 255 in Q16.16, output to a Q32.32.
            a_color <= input_fragment_array(1)(3) * x"00FF0000";
            b_color <= input_fragment_array(1)(2) * x"00FF0000";
            g_color <= input_fragment_array(1)(1) * x"00FF0000";
            r_color <= input_fragment_array(1)(0) * x"00FF0000";
            IF (x_pos_short_reg >= 0 AND x_pos_short_reg < 1920 AND y_pos_short_reg >= 0 AND y_pos_short_reg < 1080) THEN
              IF ((renderoutput_depthEna = x"00000000")) THEN
                state <= LOAD_RGBA;
              ELSE
                IF (renderoutput_depthcrtl(15 DOWNTO 0) = GL_ALWAYS) THEN
                  state <= LOAD_RGBA;
                ELSIF (renderoutput_depthcrtl(15 DOWNTO 0) = GL_NEVER) THEN
                  state <= WAIT_FOR_FRAGMENT;
                ELSE
                  IF (mem_accept = '1') THEN
                    mem_rd <= '1';
                    mem_addr <= STD_LOGIC_VECTOR(unsigned(renderoutput_depthbuffer) + unsigned((1079 - y_pos_short_reg) * 7680) + unsigned(4 * x_pos_short_reg));
                    state <= WAIT_LOAD_DEPTH;
                  ELSE
                    state <= GEN_ADDRESS_2;
                  END IF;
                END IF;
              END IF;
            ELSE
              state <= WAIT_FOR_FRAGMENT;
            END IF;

          WHEN WAIT_LOAD_DEPTH =>
            mem_rd <= '0';
            IF (mem_ack = '1') THEN
              mem_rd_data_stored <= mem_data_rd;
              state <= CALC_DEPTH;
            END IF;
            --wait for req done

          WHEN CALC_DEPTH =>
            --note never and always are accounted for already,
            --mildy sphaget but also mildy more efficient
            CASE DepthCtrl IS
              WHEN GL_LESS =>
                IF (z_pos < signed(mem_rd_data_stored)) THEN
                  state <= WRITE_DEPTH;
                ELSE
                  state <= WAIT_FOR_FRAGMENT;
                END IF;
              WHEN GL_EQUAL =>
                IF (z_pos = signed(mem_rd_data_stored)) THEN
                  state <= WRITE_DEPTH;
                ELSE
                  state <= WAIT_FOR_FRAGMENT;
                END IF;
              WHEN GL_LEQUAL =>
                IF (z_pos <= signed(mem_rd_data_stored)) THEN
                  state <= WRITE_DEPTH;
                ELSE
                  state <= WAIT_FOR_FRAGMENT;
                END IF;
              WHEN GL_GREATER =>
                IF (z_pos > signed(mem_rd_data_stored)) THEN
                  state <= WRITE_DEPTH;
                ELSE
                  state <= WAIT_FOR_FRAGMENT;
                END IF;
              WHEN GL_NOTEQUAL =>
                IF (z_pos /= signed(mem_rd_data_stored)) THEN
                  state <= WRITE_DEPTH;
                ELSE
                  state <= WAIT_FOR_FRAGMENT;
                END IF;
              WHEN GL_GEQUAL =>
                IF (z_pos > signed(mem_rd_data_stored)) THEN
                  state <= WRITE_DEPTH;
                ELSE
                  state <= WAIT_FOR_FRAGMENT;
                END IF;
              WHEN OTHERS =>
                state <= WAIT_FOR_FRAGMENT;
            END CASE;

          WHEN WRITE_DEPTH =>
            mem_addr <= STD_LOGIC_VECTOR(unsigned(renderoutput_depthbuffer) + unsigned((1079 - y_pos_short_reg) * 7680) + unsigned(4 * x_pos_short_reg));
            mem_data_wr <= STD_LOGIC_VECTOR(z_pos);

            --wait for mem_accept to go high. then write to the dcache.
            IF (mem_accept = '1') THEN
              mem_wr <= b"1111";
              state <= WAIT_DEPTH_RESPONSE;
            END IF;

          WHEN WAIT_DEPTH_RESPONSE =>
            mem_wr <= b"0000";
            IF (mem_ack = '1') THEN
              state <= LOAD_RGBA;
            END IF;

          WHEN LOAD_RGBA =>
            IF(TextureENA = '1') THEN 
              IF(mem_accept = '1') THEN
                mem_rd <= '1';
                mem_addr <= STD_LOGIC_VECTOR(unsigned(renderoutput_texture) + UVY_short * unsigned(renderoutput_texture_width) + UVX_short * 4); --it's legit I swear
                state <= WAIT_LOAD_TEXTURE;
              END IF;
            ELSIF (BlendENA = '0') THEN
              state <= WRITE_ADDRESS;
              outputValA <= STD_LOGIC_VECTOR(a_color(39 DOWNTO 32));
              outputValR <= STD_LOGIC_VECTOR(r_color(39 DOWNTO 32));
              outputValB <= STD_LOGIC_VECTOR(b_color(39 DOWNTO 32));
              outputValG <= STD_LOGIC_VECTOR(g_color(39 DOWNTO 32));
            ELSIF (mem_accept = '1') THEN
              mem_rd <= '1';
              mem_addr <= STD_LOGIC_VECTOR(unsigned(renderoutput_colorbuffer) + unsigned((1079 - y_pos_short_reg) * 7680) + unsigned(4 * x_pos_short_reg));
              state <= WAIT_FOR_RGBA;
            END IF;

          WHEN WAIT_FOR_RGBA =>
            mem_rd <= '0';
            IF (mem_ack = '1') THEN
              mem_rd_data_stored <= mem_data_rd;
              state <= BLEND;
              BlendingState <= FACTOR_CALC;
            END IF;

          WHEN BLEND =>
            CASE BlendingState IS
              WHEN FACTOR_CALC =>
                --factor
                CASE renderoutput_blendcrtl_sfactor(15 DOWNTO 0) IS
                  WHEN GL_ZERO =>
                    sourceFactorA <= (OTHERS => '0');
                    sourceFactorR <= (OTHERS => '0');
                    sourceFactorB <= (OTHERS => '0');
                    sourceFactorG <= (OTHERS => '0');
                  WHEN GL_ONE =>
                    sourceFactorA <= STD_LOGIC_VECTOR(oneQ8);
                    sourceFactorR <= STD_LOGIC_VECTOR(oneQ8);
                    sourceFactorB <= STD_LOGIC_VECTOR(oneQ8);
                    sourceFactorG <= STD_LOGIC_VECTOR(oneQ8);
                  WHEN GL_SRC_COLOR =>
                    sourceFactorA <= STD_LOGIC_VECTOR(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32))); --max value is 255, shift right by 8 to divide by 255
                    sourceFactorR <= STD_LOGIC_VECTOR(b"00000000" & STD_LOGIC_VECTOR(r_color(39 DOWNTO 32))); --max value is 255, shift right by 8 to divide by 255
                    sourceFactorB <= STD_LOGIC_VECTOR(b"00000000" & STD_LOGIC_VECTOR(g_color(39 DOWNTO 32))); --max value is 255, shift right by 8 to divide by 255
                    sourceFactorG <= STD_LOGIC_VECTOR(b"00000000" & STD_LOGIC_VECTOR(b_color(39 DOWNTO 32))); --max value is 255, shift right by 8 to divide by 255
                  WHEN GL_ONE_MINUS_SRC_COLOR =>
                    sourceFactorA <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32)))); --max value is 255, shift right by 8 to divide by 255
                    sourceFactorR <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(r_color(39 DOWNTO 32)))); --max value is 255, shift right by 8 to divide by 255
                    sourceFactorB <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(g_color(39 DOWNTO 32)))); --max value is 255, shift right by 8 to divide by 255    
                    sourceFactorG <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(b_color(39 DOWNTO 32)))); --max value is 255, shift right by 8 to divide by 255
                  WHEN GL_DST_COLOR =>
                    sourceFactorA <= (b"00000000" & mem_rd_data_stored(31 DOWNTO 24));
                    sourceFactorR <= (b"00000000" & mem_rd_data_stored(23 DOWNTO 16)); --max value is 255, shift right by 8 to divide by 255
                    sourceFactorB <= (b"00000000" & mem_rd_data_stored(15 DOWNTO 8));
                    sourceFactorG <= (b"00000000" & mem_rd_data_stored(7 DOWNTO 0)); --max value is 255, shift right by 8 to divide by 255
                  WHEN GL_ONE_MINUS_DST_COLOR =>
                    sourceFactorA <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(mem_rd_data_stored(31 DOWNTO 24))));
                    sourceFactorR <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(mem_rd_data_stored(23 DOWNTO 16))));
                    sourceFactorB <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(mem_rd_data_stored(15 DOWNTO 8))));
                    sourceFactorG <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(mem_rd_data_stored(7 DOWNTO 0))));
                  WHEN GL_SRC_ALPHA =>
                    sourceFactorA <= STD_LOGIC_VECTOR(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32)));
                    sourceFactorR <= STD_LOGIC_VECTOR(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32)));
                    sourceFactorB <= STD_LOGIC_VECTOR(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32)));
                    sourceFactorG <= STD_LOGIC_VECTOR(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32)));
                  WHEN GL_ONE_MINUS_SRC_ALPHA =>
                    sourceFactorA <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32))));
                    sourceFactorR <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32))));
                    sourceFactorB <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32))));
                    sourceFactorG <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32))));
                  WHEN GL_DST_ALPHA =>
                    sourceFactorA <= (b"00000000" & mem_rd_data_stored(31 DOWNTO 24));
                    sourceFactorR <= (b"00000000" & mem_rd_data_stored(31 DOWNTO 24));
                    sourceFactorB <= (b"00000000" & mem_rd_data_stored(31 DOWNTO 24));
                    sourceFactorG <= (b"00000000" & mem_rd_data_stored(31 DOWNTO 24));
                  WHEN GL_ONE_MINUS_DST_ALPHA =>
                    sourceFactorA <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(mem_rd_data_stored(31 DOWNTO 24))));
                    sourceFactorR <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(mem_rd_data_stored(31 DOWNTO 24))));
                    sourceFactorB <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(mem_rd_data_stored(31 DOWNTO 24))));
                    sourceFactorG <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(mem_rd_data_stored(31 DOWNTO 24))));
                  WHEN OTHERS =>
                    state <= WAIT_FOR_FRAGMENT;
                END CASE;

                CASE renderoutput_blendcrtl_dfactor(15 DOWNTO 0) IS
                  WHEN GL_ZERO =>
                    destFactorA <= (OTHERS => '0');
                    destFactorR <= (OTHERS => '0');
                    destFactorB <= (OTHERS => '0');
                    destFactorG <= (OTHERS => '0');
                  WHEN GL_ONE =>
                    destFactorA <= STD_LOGIC_VECTOR(oneQ8);
                    destFactorR <= STD_LOGIC_VECTOR(oneQ8);
                    destFactorB <= STD_LOGIC_VECTOR(oneQ8);
                    destFactorG <= STD_LOGIC_VECTOR(oneQ8);
                  WHEN GL_SRC_COLOR =>
                    destFactorA <= (b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32)));
                    destFactorR <= (b"00000000" & STD_LOGIC_VECTOR(r_color(39 DOWNTO 32))); --max value is 255, shift right by 8 to divide by 255
                    destFactorB <= (b"00000000" & STD_LOGIC_VECTOR(g_color(39 DOWNTO 32)));
                    destFactorG <= (b"00000000" & STD_LOGIC_VECTOR(b_color(39 DOWNTO 32))); --max value is 255, shift right by 8 to divide by 255
                  WHEN GL_ONE_MINUS_SRC_COLOR =>
                    destFactorA <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32))));
                    destFactorR <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(r_color(39 DOWNTO 32))));
                    destFactorB <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(g_color(39 DOWNTO 32))));
                    destFactorG <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(b_color(39 DOWNTO 32))));
                  WHEN GL_DST_COLOR =>
                    destFactorA <= (b"00000000" & mem_rd_data_stored(31 DOWNTO 24));
                    destFactorR <= (b"00000000" & mem_rd_data_stored(23 DOWNTO 16)); --max value is 255, shift right by 8 to divide by 255
                    destFactorB <= (b"00000000" & mem_rd_data_stored(15 DOWNTO 8));
                    destFactorG <= (b"00000000" & mem_rd_data_stored(7 DOWNTO 0)); --max value is 255, shift right by 8 to divide by 255
                  WHEN GL_ONE_MINUS_DST_COLOR =>
                    destFactorA <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & mem_rd_data_stored(31 DOWNTO 24)));
                    destFactorR <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & mem_rd_data_stored(23 DOWNTO 16)));
                    destFactorB <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & mem_rd_data_stored(15 DOWNTO 8)));
                    destFactorG <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & mem_rd_data_stored(7 DOWNTO 0)));
                  WHEN GL_SRC_ALPHA =>
                    destFactorA <= STD_LOGIC_VECTOR(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32)));
                    destFactorR <= STD_LOGIC_VECTOR(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32)));
                    destFactorB <= STD_LOGIC_VECTOR(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32)));
                    destFactorG <= STD_LOGIC_VECTOR(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32)));
                  WHEN GL_ONE_MINUS_SRC_ALPHA =>
                    destFactorA <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32))));
                    destFactorR <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32))));
                    destFactorB <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32))));
                    destFactorG <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(a_color(39 DOWNTO 32))));
                  WHEN GL_DST_ALPHA =>
                    destFactorA <= (b"00000000" & mem_rd_data_stored(31 DOWNTO 24));
                    destFactorR <= (b"00000000" & mem_rd_data_stored(31 DOWNTO 24));
                    destFactorB <= (b"00000000" & mem_rd_data_stored(31 DOWNTO 24));
                    destFactorG <= (b"00000000" & mem_rd_data_stored(31 DOWNTO 24));
                  WHEN GL_ONE_MINUS_DST_ALPHA =>
                    destFactorA <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(mem_rd_data_stored(31 DOWNTO 24))));
                    destFactorR <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(mem_rd_data_stored(31 DOWNTO 24))));
                    destFactorB <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(mem_rd_data_stored(31 DOWNTO 24))));
                    destFactorG <= STD_LOGIC_VECTOR(oneQ8 - unsigned(b"00000000" & STD_LOGIC_VECTOR(mem_rd_data_stored(31 DOWNTO 24))));
                  WHEN OTHERS =>
                    state <= WAIT_FOR_FRAGMENT;
                END CASE;
                BlendingState <= CALC;

              WHEN CALC =>
                calcValA <= STD_LOGIC_VECTOR(((unsigned(a_color(39 DOWNTO 32)) & b"00000000") * unsigned(sourceFactorA)) + ((unsigned(mem_rd_data_stored(31 DOWNTO 24)) & b"00000000") * unsigned(destFactorA)));
                calcValR <= STD_LOGIC_VECTOR(((unsigned(r_color(39 DOWNTO 32)) & b"00000000") * unsigned(sourceFactorR)) + ((unsigned(mem_rd_data_stored(23 DOWNTO 16)) & b"00000000") * unsigned(destFactorR)));
                calcValB <= STD_LOGIC_VECTOR(((unsigned(b_color(39 DOWNTO 32)) & b"00000000") * unsigned(sourceFactorB)) + ((unsigned(mem_rd_data_stored(15 DOWNTO 8)) & b"00000000") * unsigned(destFactorB)));
                calcValG <= STD_LOGIC_VECTOR(((unsigned(g_color(39 DOWNTO 32)) & b"00000000") * unsigned(sourceFactorG)) + ((unsigned(mem_rd_data_stored(7 DOWNTO 0)) & b"00000000") * unsigned(destFactorG)));
                BlendingState <= MIN_VALS;

              WHEN MIN_VALS =>

                IF (unsigned(calcValA) > BLEND_MAX_A) THEN
                  outputValA <= STD_LOGIC_VECTOR(BLEND_MAX_A(23 DOWNTO 16));
                ELSE
                  outputValA <= calcValA(23 DOWNTO 16);
                END IF;

                IF (unsigned(calcValR) > BLEND_MAX_R) THEN
                  outputValR <= STD_LOGIC_VECTOR(BLEND_MAX_R(23 DOWNTO 16));
                ELSE
                  outputValR <= calcValR(23 DOWNTO 16);
                END IF;

                IF (unsigned(calcValG) > BLEND_MAX_G) THEN
                  outputValG <= STD_LOGIC_VECTOR(BLEND_MAX_G(23 DOWNTO 16));
                ELSE
                  outputValG <= calcValG(23 DOWNTO 16);
                END IF;

                IF (unsigned(calcValB) > BLEND_MAX_B) THEN
                  outputValB <= STD_LOGIC_VECTOR(BLEND_MAX_B(23 DOWNTO 16));
                ELSE
                  outputValB <= calcValB(23 DOWNTO 16);
                END IF;

                state <= WRITE_ADDRESS;

              WHEN OTHERS =>
                state <= WAIT_FOR_FRAGMENT;
            END CASE;

          WHEN WAIT_LOAD_TEXTURE =>
          mem_rd <= '0';
          IF (mem_ack = '1') THEN
            mem_rd_data_stored <= mem_data_rd;
            state <= Texture;
          END IF;

          WHEN TEXTURE =>
            --IF(mem_rd_data_stored(23 DOWNTO 16) = b"00000000") THEN
              --state <= WAIT_FOR_FRAGMENT;
            --ELSE
              outputValA <= mem_rd_data_stored(31 DOWNTO 24);
              outputValR <= mem_rd_data_stored(23 DOWNTO 16);
              outputValG <= mem_rd_data_stored(15 DOWNTO 8);
              outputValB <= mem_rd_data_stored(7 DOWNTO 0);
              state <= WRITE_ADDRESS;
            --END IF;


          WHEN WRITE_ADDRESS =>
            mem_addr <= STD_LOGIC_VECTOR(unsigned(renderoutput_colorbuffer) + unsigned((1079 - y_pos_short_reg) * 7680) + unsigned(4 * x_pos_short_reg));
            mem_data_wr <= STD_LOGIC_VECTOR(outputValA) & STD_LOGIC_VECTOR(outputValR) & STD_LOGIC_VECTOR(outputValB) & STD_LOGIC_VECTOR(outputValG);

            --wait for mem_accept to go high. then write to the dcache.
            IF (mem_accept = '1') THEN
              mem_wr <= b"1111";
              state <= WAIT_FOR_RESPONSE;
            END IF;

          WHEN WAIT_FOR_RESPONSE =>
            mem_wr <= b"0000";
            IF (mem_ack = '1') THEN
              state <= WAIT_FOR_FRAGMENT;
            END IF;

          WHEN OTHERS =>
        END CASE;
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE behavioral;