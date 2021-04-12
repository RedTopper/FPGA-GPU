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
      SGP_AXI_RENDEROUTPUT_COLORBUFFER : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_DEPTHBUFFER : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_CACHECTRL : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_STRIDE : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_HEIGHT : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_DEPTHENA : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_DEPTHCTRL : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_BLENDENA : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_BLENDCTRL_SFACTOR : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_BLENDCTRL_DFACTOR : OUT STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_DEBUG : IN STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
      SGP_AXI_RENDEROUTPUT_STATUS : IN STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0)
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

  TYPE STATE_TYPE IS (WAIT_FOR_FRAGMENT, GEN_ADDRESS, LOAD_DEPTH, WAIT_LOAD_DEPTH, CALC_DEPTH, LOAD_RGBA, WAIT_FOR_RGBA, BLEND, FACTOR_FUNC, WRITE_ADDRESS, WAIT_FOR_RESPONSE);
  SIGNAL state : STATE_TYPE;

  TYPE BLEND_STATE_TYPE IS (FACTOR_CALC, CALC, MIN_VALS);
  SIGNAL BlendingState : BLEND_STATE_TYPE;
  
  
  -- User register values
  SIGNAL renderoutput_colorbuffer : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_depthbuffer : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_cachectrl : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_stride : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL renderoutput_depthEna : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH -1 DOWNTO 0);
  SIGNAL renderoutput_depthcrtl :   STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH -1 DOWNTO 0);
  SIGNAL renderoutput_blendEna : STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH -1 DOWNTO 0);
  SIGNAL renderoutput_blendcrtl_sfactor :   STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH -1 DOWNTO 0);
  SIGNAL renderoutput_blendcrtl_dfactor :   STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH -1 DOWNTO 0);
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
  SIGNAL z_pos : std_logic_vector(31 downto 0);
  SIGNAL frag_address : signed(31 DOWNTO 0);
  SIGNAL frag_color : STD_LOGIC_VECTOR(31 DOWNTO 0);
  SIGNAL a_color : wfixed_t;
  SIGNAL r_color : wfixed_t;
  SIGNAL g_color : wfixed_t;
  SIGNAL b_color : wfixed_t;
  SIGNAL a_color_reg : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL r_color_reg : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL g_color_reg : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL b_color_reg : STD_LOGIC_VECTOR(7 DOWNTO 0);
  
  SIGNAL sourceFactorR, sourceFactorG, sourceFactorB, sourceFactorA : std_logic_vector(15 downto 0);
  SIGNAL destFactorR, destFactorG, destFactorB, destFactorA : std_logic_vector(15 downto 0);
  SIGNAL calcValR, calcValB, calcValG, calcValA : std_logic_vector(31 downto 0);
  SIGNAL oneQ8 : unsigned(15 downto 0) := b"0000000100000000";
  SIGNAL outputValR, outputValB, outputValG, outputValA : std_logic_vector(7 downto 0);
  SIGNAL rgbaCounter : INTEGER RANGE 0 TO 4;
  
  
  CONSTANT GL_LESS      :  std_logic_vector(2 downto 0) := "000";
  CONSTANT GL_ALWAYS    :  std_logic_vector(2 downto 0) := "001";
  CONSTANT GL_NEVER     :  std_logic_vector(2 downto 0) := "010";
  CONSTANT GL_EQUAL     :  std_logic_vector(2 downto 0) := "011";
  CONSTANT GL_LEQUAL    :  std_logic_vector(2 downto 0) := "100";
  CONSTANT GL_GREATER   :  std_logic_vector(2 downto 0) := "101";
  CONSTANT GL_NOTEQUAL  :  std_logic_vector(2 downto 0) := "110";
  CONSTANT GL_GEQUAL	:  std_logic_vector(2 downto 0) := "111";

  CONSTANT GL_ZERO                :  std_logic_vector(3 downto 0) := "0000";
  CONSTANT GL_ONE                 :  std_logic_vector(3 downto 0) := "0001";
  CONSTANT GL_SRC_COLOR           :  std_logic_vector(3 downto 0) := "0010";
  CONSTANT GL_ONE_MINUS_SRC_COLOR :  std_logic_vector(3 downto 0) := "0011";
  CONSTANT GL_DST_COLOR           :  std_logic_vector(3 downto 0) := "0100";
  CONSTANT GL_ONE_MINUS_DST_COLOR :  std_logic_vector(3 downto 0) := "0101";
  CONSTANT GL_SRC_ALPHA           :  std_logic_vector(3 downto 0) := "0110";
  CONSTANT GL_ONE_MINUS_SRC_ALPHA :  std_logic_vector(3 downto 0) := "0111";
  CONSTANT GL_DST_ALPHA           :  std_logic_vector(3 downto 0) := "1000";
  CONSTANT GL_ONE_MINUS_DST_ALPHA :  std_logic_vector(3 downto 0) := "1001";

  CONSTANT BLEND_MAX_R : unsigned(7 downto 0) := "11111111";
  CONSTANT BLEND_MAX_B : unsigned(7 downto 0) := "11111111";
  CONSTANT BLEND_MAX_G : unsigned(7 downto 0) := "11111111";
  CONSTANT BLEND_MAX_A : unsigned(7 downto 0) := "11111111";

  ALIAS XPosShort   : signed(15 DOWNTO 0) is input_fragment_array(0)(0)(31 DOWNTO 16);
  ALIAS YPosShort   : signed(15 DOWNTO 0) is input_fragment_array(0)(1)(31 DOWNTO 16);
  ALIAS XPosShortRnd: signed(1 DOWNTO 0) is input_fragment_array(0)(0)(16 DOWNTO 15);
  ALIAS YPosShortRnd: signed(1 DOWNTO 0) is input_fragment_array(0)(1)(16 DOWNTO 15);
  ALIAS zPosShort   : signed(31 DOWNTO 0) is input_fragment_array(0)(2)(31 DOWNTO 0);

  ALIAS DepthENA    : std_logic is renderoutput_depthEna(0);
  ALIAS DepthCtrl   : std_logic_vector(2 downto 0) is renderoutput_depthcrtl(2 downto 0);
  ALIAS BlendENA    : std_logic is renderoutput_blendEna(0);
  ALIAS BlendCtrl   : std_logic_vector(2 downto 0) is renderoutput_depthcrtl(2 downto 0);
  
  
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

  S_AXIS_TREADY <= '1' WHEN state = WAIT_FOR_FRAGMENT ELSE '0';

  -- The vertexArray_t data types will make this code look much cleaner
  input_fragment_array <= to_vertexArray_t(input_fragment);

  -- Our framebuffer is currently ARBG, so we have to re-assemble a bit. We only need the integer values now
  -- At least set a unique ID for each synthesis run in the debug register, so we know that we're looking at the most recent IP core
  -- It would also be useful to connect internal signals to this register for software debug purposes
  renderoutput_debug <= x"00000046";

  -- A 4-state FSM, where we copy fragments, determine the address and color from the input attributes, 
  -- and generate an AXI Write request based on that data.
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
            z_pos           <= std_logic_vector(zPosShort);                   --technically not a short but it follows naming conventions.

            --we will say the order is argb, I don't think it matters as long as we are consistent.
            --multiple [0, 1.0] by 255 in Q16.16, output to a Q32.32.
            a_color <= input_fragment_array(1)(0) * x"00FF0000";
            b_color <= input_fragment_array(1)(1) * x"00FF0000";
            g_color <= input_fragment_array(1)(2) * x"00FF0000";
            r_color <= input_fragment_array(1)(3) * x"00FF0000";

            
            IF((x_pos_short_reg >= 0 AND x_pos_short_reg < 1920 AND y_pos_short_reg >= 0 AND y_pos_short_reg < 1080) or DepthCtrl != GL_NEVER) THEN
              IF((renderoutput_depthEna(0) = '0') or (renderoutput_depthcrtl(2 downto 0) = GL_ALWAYS)) THEN
                state <= load_rgba;
              else                
                mem_rd <= '1';
                mem_addr <= STD_LOGIC_VECTOR(signed(renderoutput_depthbuffer) + signed((1079 - input_fragment_array(0)(1)(31 DOWNTO 16) + input_fragment_array(0)(1)(15 DOWNTO 15)) * 7680) + signed(4 * input_fragment_array(0)(0)(31 DOWNTO 16) + input_fragment_array(0)(0)(15 DOWNTO 15)));
                state <= WAIT_LOAD_DEPTH;
              end if;
            else
              state <= WAIT_FOR_FRAGMENT;
            end if;
          
          WHEN WAIT_LOAD_DEPTH =>
            mem_rd <= '0';
            if(mem_ack = '1')then
              mem_rd_data_stored <= mem_data_rd;
              state <= CALC_DEPTH;
            end if;
            --wait for req done

          WHEN CALC_DEPTH =>
            --note never and always are accounted for already,
            --mildy sphaget but also mildy more efficient

            CASE DepthCtrl IS
              when GL_LESS =>
                if(z_pos < mem_rd_data_stored)then
                  state <= BLEND;
                else
                  state <= WAIT_FOR_FRAGMENT;
                end if;
              when GL_EQUAL =>
                if(z_pos = mem_rd_data_stored)then
                  state <= BLEND;
                else
                  state <= WAIT_FOR_FRAGMENT;
                end if;
              when GL_LEQUAL =>
                if(z_pos <= mem_rd_data_stored)then
                  state <= BLEND;
                else
                  state <= WAIT_FOR_FRAGMENT;
                end if;
              when GL_GREATER =>
                if(z_pos > mem_rd_data_stored)then
                  state <= BLEND;
                else
                  state <= WAIT_FOR_FRAGMENT;
                end if;
              when GL_NOTEQUAL =>
                if(z_pos /= mem_rd_data_stored)then
                  state <= BLEND;
                else
                  state <= WAIT_FOR_FRAGMENT;
                end if;
              when GL_GEQUAL =>
                if(z_pos > mem_rd_data_stored)then
                  state <= BLEND;
                else
                  state <= WAIT_FOR_FRAGMENT;
                end if;
              when others=>
                state <= WAIT_FOR_FRAGMENT;
              END CASE;

          WHEN LOAD_RGBA =>
              IF(BlendENA = '0') THEN
                state <= WRITE_ADDRESS;
                outputValR <= std_logic_vector(r_color(39 downto 32));
                outputValG <=  std_logic_vector(g_color(39 downto 32));
                outputValB <=  std_logic_vector(b_color(39 downto 32));
                outputValA <=  std_logic_vector(a_color(39 downto 32));
              ELSIF (mem_accept = '1') THEN
                mem_addr <= STD_LOGIC_VECTOR(signed(renderoutput_colorbuffer) + signed((1079 - y_pos_short_reg) * 7680) + signed(4 * x_pos_short_reg));
                state <= WAIT_FOR_RGBA;
              END IF;

          WHEN WAIT_FOR_RGBA =>
            IF (mem_ack = '1') THEN
              mem_rd_data_stored <= mem_data_rd;
              state <= LOAD_RGBA;
            END IF;

          WHEN BLEND =>
            CASE BlendingState is
              WHEN FACTOR_CALC =>
              --factor
                CASE renderoutput_blendcrtl_sfactor(3 downto 0) is
                  WHEN GL_ZERO =>
                    sourceFactorR <= (others => '0');
                    sourceFactorG <= (others => '0');
                    sourceFactorB <= (others => '0');
                    sourceFactorA <= (others => '0');
                  WHEN GL_ONE =>
                    sourceFactorR <= (others => '1');
                    sourceFactorG <= (others => '1');
                    sourceFactorB <= (others => '1');
                    sourceFactorA <= (others => '1');
                  WHEN GL_SRC_COLOR =>
                    sourceFactorR <= std_logic_vector(b"00000000" & std_logic_vector(r_color(39 downto 32)));   --max value is 255, shift right by 8 to divide by 255
                    sourceFactorG <= std_logic_vector(b"00000000" & std_logic_vector(b_color(39 downto 32)));   --max value is 255, shift right by 8 to divide by 255
                    sourceFactorB <= std_logic_vector(b"00000000" & std_logic_vector(g_color(39 downto 32)));   --max value is 255, shift right by 8 to divide by 255
                    sourceFactorA <= std_logic_vector(b"00000000" & std_logic_vector(a_color(39 downto 32)));   --max value is 255, shift right by 8 to divide by 255
                  WHEN GL_ONE_MINUS_SRC_COLOR =>
                    sourceFactorR <= std_logic_vector(oneQ8 - unsigned(b"00000000" & std_logic_vector(r_color(39 downto 32))));   --max value is 255, shift right by 8 to divide by 255
                    sourceFactorG <= std_logic_vector(oneQ8 - unsigned(b"00000000" & std_logic_vector(b_color(39 downto 32))));   --max value is 255, shift right by 8 to divide by 255
                    sourceFactorB <= std_logic_vector(oneQ8 - unsigned(b"00000000" & std_logic_vector(g_color(39 downto 32))));   --max value is 255, shift right by 8 to divide by 255
                    sourceFactorA <= std_logic_vector(oneQ8 - unsigned(b"00000000" & std_logic_vector(a_color(39 downto 32))));   --max value is 255, shift right by 8 to divide by 255
                  WHEN OTHERS =>
                    state <= WAIT_FOR_FRAGMENT;
                END CASE;

                CASE renderoutput_blendcrtl_dfactor(3 downto 0) is
                  WHEN GL_ZERO =>
                    destFactorR <= (others => '0');
                    destFactorG <= (others => '0');
                    destFactorB <= (others => '0');
                    destFactorA <= (others => '0');
                  WHEN GL_ONE =>
                    destFactorR <= (others => '1');
                    destFactorG <= (others => '1');
                    destFactorB <= (others => '1');
                    destFactorA <= (others => '1');
                  WHEN GL_SRC_COLOR =>
                    destFactorR <= (b"00000000" & mem_rd_data_stored(31 downto 24)); --max value is 255, shift right by 8 to divide by 255
                    destFactorG <= (b"00000000" & mem_rd_data_stored(15 downto 8));  --max value is 255, shift right by 8 to divide by 255
                    destFactorB <= (b"00000000" & mem_rd_data_stored(7 downto 0));
                    destFactorA <= (b"00000000" & mem_rd_data_stored(23 downto 16));
                  WHEN GL_ONE_MINUS_SRC_COLOR =>
                   destFactorR <= std_logic_vector(oneQ8 - unsigned(b"00000000" & mem_rd_data_stored(31 downto 24)));
                   destFactorG <= std_logic_vector(oneQ8 - unsigned(b"00000000" & mem_rd_data_stored(15 downto 8)));
                   destFactorB <= std_logic_vector(oneQ8 - unsigned(b"00000000" & mem_rd_data_stored(7 downto 0)));
                   destFactorA <= std_logic_vector(oneQ8 - unsigned(b"00000000" & mem_rd_data_stored(23 downto 16)));
                  WHEN OTHERS =>
                   state <= WAIT_FOR_FRAGMENT;
                END CASE;
                
                BlendingState <= CALC;
              WHEN CALC =>
                calcValR <= std_logic_vector(unsigned(r_color) * unsigned(sourceFactorR) + unsigned(mem_rd_data_stored(31 downto 24))  * unsigned(destFactorR));
                calcValG <= std_logic_vector(unsigned(g_color) * unsigned(sourceFactorG) + unsigned(mem_rd_data_stored(15 downto 8) )  * unsigned(destFactorG));
                calcValB <= std_logic_vector(unsigned(b_color) * unsigned(sourceFactorB) + unsigned(mem_rd_data_stored(7 downto 0)  )  * unsigned(destFactorB));
                calcValA <= std_logic_vector(unsigned(a_color) * unsigned(sourceFactorA) + unsigned(mem_rd_data_stored(23 downto 16))  * unsigned(destFactorA));
                BlendingState <= MIN_VALS;

              WHEN MIN_VALS =>

                IF (unsigned(calcValR(23 downto 16)) > BLEND_MAX_R) THEN
                  outputValR <= std_logic_vector(BLEND_MAX_R);
                else
                  outputValR <= calcValR(23 downto 16);
                END IF;

                IF (unsigned(calcValG(23 downto 16)) > BLEND_MAX_G) THEN
                  outputValG <= std_logic_vector(BLEND_MAX_G);
                else
                  outputValG <= calcValG(23 downto 16);
                END IF;

                IF (unsigned(calcValB(23 downto 16)) > BLEND_MAX_B) THEN
                  outputValB <= std_logic_vector(BLEND_MAX_B);
                else
                  outputValB <= calcValB(23 downto 16);
                END IF;

                IF (unsigned(calcValA(23 downto 16)) > BLEND_MAX_A) THEN
                  outputValA <= std_logic_vector(BLEND_MAX_A);
                else
                  outputValA <= calcValA(23 downto 16);
                END IF;
                
                state <= WRITE_ADDRESS;
                
              WHEN OTHERS =>
                state <= WAIT_FOR_FRAGMENT;
              END CASE;
          WHEN WRITE_ADDRESS =>
            mem_addr <= STD_LOGIC_VECTOR(signed(renderoutput_colorbuffer) + signed((1079 - y_pos_short_reg) * 7680) + signed(4 * x_pos_short_reg));
            mem_data_wr <= STD_LOGIC_VECTOR(outputValR) & STD_LOGIC_VECTOR(outputValA) & STD_LOGIC_VECTOR(outputValG) & STD_LOGIC_VECTOR(outputValB);

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