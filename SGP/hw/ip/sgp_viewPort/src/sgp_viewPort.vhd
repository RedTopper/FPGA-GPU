-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- sgp_viewPort.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a viewport unit
-- applies a user-supplied viewport transformation to incoming vertex values
--
-- NOTES:
-- 12/01/20 by JAZ::Design created.
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.sgp_types.all;


entity sgp_viewPort is

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

end sgp_viewPort;


architecture behavioral of sgp_viewPort is


	-- component declaration
	component sgp_viewPort_axi_lite_regs is
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
        SGP_AXI_VIEWPORT_X_REG            : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    SGP_AXI_VIEWPORT_Y_REG            : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    SGP_AXI_VIEWPORT_WIDTH_REG        : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    SGP_AXI_VIEWPORT_HEIGHT_REG       : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    SGP_AXI_VIEWPORT_NEARVAL_REG      : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	    SGP_AXI_VIEWPORT_FARVAL_REG       : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        SGP_AXI_VIEWPORT_DEBUG            : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0)
		
		);
	end component sgp_viewPort_axi_lite_regs;


    -- User register values
    signal viewport_x_reg 	            : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal viewport_y_reg 	            : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal viewport_width_reg 	        : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal viewport_height_reg 	        : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal viewport_nearval_reg 	    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal viewport_farval_reg 	        : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal viewport_debug 	            : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);


    -- Intermediate values for viewport transformation. 
    signal tdata_reg  : std_logic_vector(C_NUM_VERTEX_ATTRIB*128-1 downto 64);
    signal viewport_x                   : fixed_t;
    signal viewport_y                   : fixed_t;
    signal viewport_width_div_2         : fixed_t;
    signal viewport_height_div_2        : fixed_t;
    signal viewport_xmult               : wfixed_t;
    signal viewport_ymult               : wfixed_t;
	signal viewport_zmult               : wfixed_t;


    -- Input and output of viewport transformation. Keep in Q16.16 format and if input is normalized, there should be no overflow. 
    signal x_ndc_coords : fixed_t;
    signal y_ndc_coords : fixed_t;
	signal z_ndc_coords : fixed_t;
    signal x_vp_coords  : fixed_t;
    signal y_vp_coords  : fixed_t;
	signal z_vp_coords  : fixed_t;

	signal z_far_near_diff : fixed_t;
    signal z_near_far_sum : fixed_t;
    signal z_diff_div_2 : fixed_t;
    signal z_sum_div_2 : fixed_t;


    type STATE_TYPE is (WAIT_FOR_VERTEX, CALC_XMULT, CALC_YMULT, CALC_ZMULT,CALC_VPCOORDS, VERTEX_WRITE);
    signal state        : STATE_TYPE;
   

begin


  -- Instantiation of Axi Bus Interface S_AXI_LITE
  sgp_viewPort_axi_lite_regs_inst : sgp_viewPort_axi_lite_regs
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_ADDR_WIDTH
	)
	port map (
		S_AXI_ACLK		=> ACLK,
		S_AXI_ARESETN	=> ARESETN,
		S_AXI_AWADDR	=> s_axi_lite_awaddr,
		S_AXI_AWPROT	=> s_axi_lite_awprot,
		S_AXI_AWVALID	=> s_axi_lite_awvalid,
		S_AXI_AWREADY	=> s_axi_lite_awready,
		S_AXI_WDATA		=> s_axi_lite_wdata,
		S_AXI_WSTRB		=> s_axi_lite_wstrb,
		S_AXI_WVALID	=> s_axi_lite_wvalid,
		S_AXI_WREADY	=> s_axi_lite_wready,
		S_AXI_BRESP		=> s_axi_lite_bresp,
		S_AXI_BVALID	=> s_axi_lite_bvalid,
		S_AXI_BREADY	=> s_axi_lite_bready,
		S_AXI_ARADDR	=> s_axi_lite_araddr,
		S_AXI_ARPROT	=> s_axi_lite_arprot,
		S_AXI_ARVALID	=> s_axi_lite_arvalid,
		S_AXI_ARREADY	=> s_axi_lite_arready,
		S_AXI_RDATA		=> s_axi_lite_rdata,
		S_AXI_RRESP		=> s_axi_lite_rresp,
		S_AXI_RVALID	=> s_axi_lite_rvalid,
		S_AXI_RREADY	=> s_axi_lite_rready,
		
        SGP_AXI_VIEWPORT_X_REG            => viewport_x_reg,
	    SGP_AXI_VIEWPORT_Y_REG            => viewport_y_reg,
	    SGP_AXI_VIEWPORT_WIDTH_REG        => viewport_width_reg,
	    SGP_AXI_VIEWPORT_HEIGHT_REG       => viewport_height_reg,
	    SGP_AXI_VIEWPORT_NEARVAL_REG      => viewport_nearval_reg,
	    SGP_AXI_VIEWPORT_FARVAL_REG       => viewport_farval_reg,
        SGP_AXI_VIEWPORT_DEBUG            => viewport_debug	
	);

   M_AXIS_TDATA(C_NUM_VERTEX_ATTRIB*128-1 downto 96) <= tdata_reg(C_NUM_VERTEX_ATTRIB*128-1 downto 96);
   M_AXIS_TDATA(31 downto 0)  <= std_logic_vector(x_vp_coords);
   M_AXIS_TDATA(63 downto 32) <= std_logic_vector(y_vp_coords);
   M_AXIS_TDATA(95 downto 64) <= std_logic_vector(z_vp_coords);
   
   M_AXIS_TLAST  <= S_AXIS_TLAST;

   M_AXIS_TVALID <= '1' when state = VERTEX_WRITE else
                    '0';

   S_AXIS_TREADY <= '1' when state = WAIT_FOR_VERTEX else
                    '0';



   -- The glViewport call provides unsigned integer values, convert to Q16.16 by shifting left 16. 
   -- We can also divide by 2 here by only shifting left only 15
   viewport_x <= signed(viewport_x_reg(15 downto 0) & x"0000");
   viewport_y <= signed(viewport_y_reg(15 downto 0) & x"0000");
   viewport_width_div_2 <= signed('0' & viewport_width_reg(15 downto 0) & "000000000000000");
   viewport_height_div_2 <= signed('0' & viewport_height_reg(15 downto 0) & "000000000000000");


   z_far_near_diff <= signed(viewport_farval_reg) - signed(viewport_nearval_reg);
   z_near_far_sum  <= signed(viewport_farval_reg) + signed(viewport_nearval_reg);
   z_diff_div_2 	<= signed('0' & z_far_near_diff(31 downto 1));
   z_sum_div_2 		<= signed('0' & z_near_far_sum(31 downto 1));
   
  -- At least set a unique ID for each synthesis run in the debug register, so we know that we're looking at the most recent IP core
  -- It would also be useful to connect internal signals to this register for software debug purposes
  viewport_debug <= x"00000021";


   
   process (ACLK) is
   begin 
    if rising_edge(ACLK) then  

      -- Reset all the pipeline registers
      if ARESETN = '0' then    
        state           <= WAIT_FOR_VERTEX;
        tdata_reg       <= (others => '0');
        x_ndc_coords    <= fixed_t_zero;
        y_ndc_coords    <= fixed_t_zero;
		z_ndc_coords	<= fixed_t_zero;
        viewport_xmult  <= wfixed_t_zero;
        viewport_ymult  <= wfixed_t_zero;
        x_vp_coords     <= fixed_t_zero;
        y_vp_coords     <= fixed_t_zero;
		z_vp_coords     <= fixed_t_zero;

      else

        case state is

            -- Wait here until we receive a vertex
            when WAIT_FOR_VERTEX =>
                if (S_AXIS_TVALID = '1') then
                    tdata_reg(C_NUM_VERTEX_ATTRIB*128-1 downto 64) <= S_AXIS_TDATA(C_NUM_VERTEX_ATTRIB*128-1 downto 64);

                     -- Our incoming vertices are in Q16.16 format, and will be in the range [-1, 1] 
                    x_ndc_coords <= signed(S_AXIS_TDATA(31 downto 0)) + fixed_t_one;
                    y_ndc_coords <= signed(S_AXIS_TDATA(63 downto 32)) + fixed_t_one;
					z_ndc_coords <= signed(S_AXIS_TDATA(95 downto 64)) + fixed_t_one;
                    state <= CALC_XMULT;
                end if;

			-- Calcualte the X multiplcation
			when CALC_XMULT =>
				viewport_xmult <= viewport_width_div_2 * (x_ndc_coords);
				state <= CALC_YMULT;

			when CALC_YMULT =>
				viewport_ymult <= viewport_height_div_2 * (y_ndc_coords);
				state <= CALC_ZMULT;

			when CALC_ZMULT =>
				viewport_zmult <= z_diff_div_2 * (z_ndc_coords);
				state <= CALC_VPCOORDS;

			when CALC_VPCOORDS =>
				x_vp_coords <= wfixed_t_to_fixed_t(viewport_xmult) + viewport_x;
				y_vp_coords <= wfixed_t_to_fixed_t(viewport_ymult) + viewport_y;
				z_vp_coords <= wfixed_t_to_fixed_t(viewport_zmult) + z_sum_div_2;
				state <= VERTEX_WRITE;
				
			when VERTEX_WRITE =>
				if (M_AXIS_TREADY = '1') then
					state <= WAIT_FOR_VERTEX;
				end if;

            when others =>          
				state <= WAIT_FOR_VERTEX;

        end case;
      end if;
    end if;
   end process;
end architecture behavioral;
