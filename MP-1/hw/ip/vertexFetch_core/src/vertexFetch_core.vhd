-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- vertexFetch_core.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a vertex fetching unit that
-- interfaces with an AXIS switch to assemble vertex attributes
--
-- NOTES:
-- 12/01/20 by JAZ::Design created.
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity vertexFetch_core is

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


        -- AXIS slave interfaces
		S000_AXIS_TREADY	: out	std_logic;
		S000_AXIS_TDATA	    : in	std_logic_vector(31 downto 0);
		S000_AXIS_TLAST	    : in	std_logic;
		S000_AXIS_TVALID	: in	std_logic;

		S001_AXIS_TREADY	: out	std_logic;
		S001_AXIS_TDATA	    : in	std_logic_vector(31 downto 0);
		S001_AXIS_TLAST	    : in	std_logic;
		S001_AXIS_TVALID	: in	std_logic;

		S010_AXIS_TREADY	: out	std_logic;
		S010_AXIS_TDATA	    : in	std_logic_vector(31 downto 0);
		S010_AXIS_TLAST	    : in	std_logic;
		S010_AXIS_TVALID	: in	std_logic;

		S011_AXIS_TREADY	: out	std_logic;
		S011_AXIS_TDATA	    : in	std_logic_vector(31 downto 0);
		S011_AXIS_TLAST	    : in	std_logic;
		S011_AXIS_TVALID	: in	std_logic;


        -- AXIS master interface
		M_AXIS_TVALID	: out	std_logic;
		M_AXIS_TDATA	: out	std_logic_vector(C_NUM_VERTEX_ATTRIB*128-1 downto 0);
		M_AXIS_TLAST	: out	std_logic;
		M_AXIS_TREADY	: in	std_logic);

attribute SIGIS : string; 
attribute SIGIS of ACLK : signal is "Clk"; 

end vertexFetch_core;


architecture behavioral of vertexFetch_core is


	-- component declaration
	component vertexFetch_axi_lite_regs is
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
		SGP_AXI_VERTEXFETCH_CTRL          : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        SGP_AXI_VERTEXFETCH_STATUS        : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        SGP_AXI_VERTEXFETCH_NUMVERTEX     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        SGP_AXI_VERTEXFETCH_NUMATTRIB     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        SGP_AXI_VERTEXFETCH_ATTRIB_000_SIZE : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        SGP_AXI_VERTEXFETCH_ATTRIB_001_SIZE : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        SGP_AXI_VERTEXFETCH_ATTRIB_010_SIZE : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        SGP_AXI_VERTEXFETCH_ATTRIB_011_SIZE : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0)	
		
		);
	end component vertexFetch_axi_lite_regs;


    -- User register values
    signal vertexfetch_ctrl 	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal vertexfetch_status 	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal vertexfetch_numvertex 	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal vertexfetch_numattrib 	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal vertexfetch_attrib_000_size 	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal vertexfetch_attrib_001_size 	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal vertexfetch_attrib_010_size 	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal vertexfetch_attrib_011_size 	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);



  type STATE_TYPE is (WAIT_FOR_START, ATTRIB_000_READ, ATTRIB_001_READ, ATTRIB_010_READ, ATTRIB_011_READ, VERTEX_WRITE);
  signal state        : STATE_TYPE;
   
  signal output_vertex : std_logic_vector(C_NUM_VERTEX_ATTRIB*128-1 downto 0);
  signal attrib_count : unsigned(4 downto 0);
  signal vertex_count : unsigned(31 downto 0);

begin


  -- Instantiation of Axi Bus Interface S_AXI_LITE
  vertexFetch_axi_lite_regs_inst : vertexFetch_axi_lite_regs
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
		
		SGP_AXI_VERTEXFETCH_CTRL  => vertexfetch_ctrl,
        SGP_AXI_VERTEXFETCH_STATUS => vertexfetch_status,
        SGP_AXI_VERTEXFETCH_NUMVERTEX => vertexfetch_numvertex,
        SGP_AXI_VERTEXFETCH_NUMATTRIB  => vertexfetch_numattrib,
        SGP_AXI_VERTEXFETCH_ATTRIB_000_SIZE => vertexfetch_attrib_000_size,
        SGP_AXI_VERTEXFETCH_ATTRIB_001_SIZE => vertexfetch_attrib_001_size,
        SGP_AXI_VERTEXFETCH_ATTRIB_010_SIZE => vertexfetch_attrib_010_size,
        SGP_AXI_VERTEXFETCH_ATTRIB_011_SIZE => vertexfetch_attrib_011_size 		
		
		
	);


  vertexfetch_status <= x"00000000" when state = WAIT_FOR_START else
                        x"00000001"; 
  
  M_AXIS_TVALID <= '1' when state = VERTEX_WRITE else
                   '0';

  M_AXIS_TDATA <= output_vertex when state = VERTEX_WRITE else
                  (others => '0');
                                   

  S000_AXIS_TREADY <= '1' when state = ATTRIB_000_READ else
                      '0';
  S001_AXIS_TREADY <= '1' when state = ATTRIB_001_READ else
                      '0';
  S010_AXIS_TREADY <= '1' when state = ATTRIB_010_READ else
                      '0';
  S011_AXIS_TREADY <= '1' when state = ATTRIB_011_READ else
                      '0';

  M_AXIS_TLAST <= '1' when ((state = VERTEX_WRITE) and (vertex_count = unsigned(vertexfetch_numvertex)-1)) else
                  '0';

  -- A 6-state FSM, where we copy attribute data as needed into the output vertex structure, and keep track of how many
  -- attributes per vertex and vertexes per draw call
   process (ACLK) is
   begin 
    if rising_edge(ACLK) then  
      if ARESETN = '0' then    

        -- Start at WAIT_FOR_START and initialize all other registers
        state        <= WAIT_FOR_START;
        output_vertex <= (others => '0');
        attrib_count <= (others => '0');
        vertex_count <= (others => '0');

      else
        case state is

            -- Wait here until we receive a draw call
            when WAIT_FOR_START =>
                output_vertex <= (others => '0');
                attrib_count <= (others => '0');
                vertex_count <= (others => '0');
                if (vertexfetch_ctrl(0) = '1') then
                    state <= ATTRIB_000_READ;
                end if;

            when ATTRIB_000_READ =>

                -- If we have valid data, we can update the output vertex and increment our attrib count
                if (S000_AXIS_TVALID = '1') then
                    attrib_count <= attrib_count + 1;
                    output_vertex((128*0 + 32*(to_integer(attrib_count)+1)-1) downto (128*0 + 32*to_integer(attrib_count))) <= S000_AXIS_TDATA;                

                    -- Are we done? Great, determine if we need to move on to the next attrib or are done with the vertex
                    if (attrib_count = unsigned(vertexfetch_attrib_000_size) - 1) then
                        attrib_count <= (others => '0');

                        -- We know which attribute word we are on, so can directly check if we should be done. Valid values are 1, 2, 3, 4 for numattrib
                        if (vertexfetch_numattrib(2 downto 0) = "001") then
                            state <= VERTEX_WRITE;
                        else
                            state <= ATTRIB_001_READ;
                        end if;
                    end if;
                end if;

            when ATTRIB_001_READ =>

                -- If we have valid data, we can update the output vertex and increment our attrib count
                if (S001_AXIS_TVALID = '1') then
                    attrib_count <= attrib_count + 1;
                    output_vertex((128*1 + 32*(to_integer(attrib_count)+1)-1) downto (128*1 + 32*to_integer(attrib_count))) <= S001_AXIS_TDATA;                

                    -- Are we done? Great, determine if we need to move on to the next attrib or are done with the vertex
                    if (attrib_count = unsigned(vertexfetch_attrib_001_size) - 1) then
                        attrib_count <= (others => '0');

                        -- We know which attribute word we are on, so can directly check if we should be done. Valid values are 1, 2, 3, 4 for numattrib
                        if (vertexfetch_numattrib(2 downto 0) = "010") then
                            state <= VERTEX_WRITE;
                        else
                            state <= ATTRIB_010_READ;
                        end if;
                    end if;
                end if;


            when ATTRIB_010_READ =>

                -- If we have valid data, we can update the output vertex and increment our attrib count
                if (S010_AXIS_TVALID = '1') then
                    attrib_count <= attrib_count + 1;
                    output_vertex((128*2 + 32*(to_integer(attrib_count)+1)-1) downto (128*2 + 32*to_integer(attrib_count))) <= S010_AXIS_TDATA;                

                    -- Are we done? Great, determine if we need to move on to the next attrib or are done with the vertex
                    if (attrib_count = unsigned(vertexfetch_attrib_010_size) - 1) then
                        attrib_count <= (others => '0');

                        -- We know which attribute word we are on, so can directly check if we should be done. Valid values are 1, 2, 3, 4 for numattrib
                        if (vertexfetch_numattrib(2 downto 0) = "011") then
                            state <= VERTEX_WRITE;
                        else
                            state <= ATTRIB_011_READ;
                        end if;
                    end if;
                end if;

            when ATTRIB_011_READ =>

                -- If we have valid data, we can update the output vertex and increment our attrib count
                if (S011_AXIS_TVALID = '1') then
                    attrib_count <= attrib_count + 1;
                    output_vertex((128*3 + 32*(to_integer(attrib_count)+1)-1) downto (128*3 + 32*to_integer(attrib_count))) <= S011_AXIS_TDATA;                

                    -- Are we done? Great, determine if we need to move on to the next attrib or are done with the vertex
                    if (attrib_count = unsigned(vertexfetch_attrib_011_size) - 1) then
                        attrib_count <= (others => '0');

                        -- We are limited to 4-word attributes, so we are always done with the vertex if we reach this point. 
                        state <= VERTEX_WRITE;
                    end if;
                end if;


            when VERTEX_WRITE =>
                -- Our data is ready to write on the output port, so check if the write is going to happen
                if (M_AXIS_TREADY = '1') then
                    vertex_count <= vertex_count + 1;
                    
                    -- Are we done with vertexes? Great. Otherwise we have to go back and read the first attribute again
                    if (vertex_count = unsigned(vertexfetch_numvertex) - 1) then
                        vertex_count <= (others => '0');
                        state <= WAIT_FOR_START;
                    else
                        state <= ATTRIB_000_READ;
                    end if;

                end if;
                
        end case;
      end if;
    end if;
   end process;
end architecture behavioral;
