-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- axis_tx_tagger.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an AXIS passthrough device that 
-- generates AXIS user signalling as needed to connect from an AXI 
-- MM2S_Mapper slave to the axis_udp_ethernet core. 
--
-- NOTES:
-- 11/07/20 by JAZ::Design created.
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity axis_tx_tagger is
	port (ACLK	: in	std_logic;
		ARESETN	: in	std_logic;
		S_AXIS_TREADY	: out	std_logic;
		S_AXIS_TDATA	: in	std_logic_vector(7 downto 0);
		S_AXIS_TLAST	: in	std_logic;
		S_AXIS_TVALID	: in	std_logic;
		S_AXIS_TID 		: in 	std_logic_vector(2 downto 0);
		M_AXIS_TVALID	: out	std_logic;
		M_AXIS_TDATA	: out	std_logic_vector(7 downto 0);
		M_AXIS_TLAST	: out	std_logic;
		M_AXIS_TREADY	: in	std_logic;
		M_AXIS_TID 		: out 	std_logic_vector(2 downto 0));

attribute SIGIS : string; 
attribute SIGIS of ACLK : signal is "Clk"; 

end axis_tx_tagger;


architecture behavioral of axis_tx_tagger is


  type STATE_TYPE is (WAIT_FOR_MULTIBYTE_PACKET, WAIT_FOR_VALID_TLAST);
  signal state        : STATE_TYPE;
   
  -- The RRESP byte that contains control information will indicate TLAST in bit position 2
  constant tlast_bitpos : integer range 0 to 7 := 2;
  signal tlast_gate : std_logic;
  signal valid_last_packet : std_logic;

begin

  -- Generally this is a passthrough device, except for the TLAST signal
  S_AXIS_TREADY <= M_AXIS_TREADY;
  M_AXIS_TVALID <= S_AXIS_TVALID;
  M_AXIS_TDATA <= S_AXIS_TDATA;
  M_AXIS_TID <= S_AXIS_TID;

  M_AXIS_TLAST <= S_AXIS_TLAST and tlast_gate; 
  tlast_gate <= '1' when (state = WAIT_FOR_MULTIBYTE_PACKET) else valid_last_packet;
  valid_last_packet <= S_AXIS_TVALID and M_AXIS_TREADY and S_AXIS_TLAST and S_AXIS_TDATA(tlast_bitpos);


  -- A 2-state FSM, where we forward on valid signals until we see that we are sending a multi-byte
  -- burst. For that multi-byte burst, we should only set TLAST when we know the UDP packet is actually complete. 
   process (ACLK, valid_last_packet) is
   begin 
    if rising_edge(ACLK) then  
      if ARESETN = '0' then    
        state        <= WAIT_FOR_MULTIBYTE_PACKET;

      else
        case state is
          
          when WAIT_FOR_MULTIBYTE_PACKET =>
            -- We've forwarded a byte. If it's not also a TLAST byte, that means we're about to have a multi-byte packet
            if (S_AXIS_TVALID = '1' and M_AXIS_TREADY = '1' and S_AXIS_TLAST = '0') then 
              state <= WAIT_FOR_VALID_TLAST;
            end if;

          when WAIT_FOR_VALID_TLAST =>
            -- We can set the tlast_gate based on the incoming data. It will only mattter when there is actually a valid TLAST
            -- signal. If we do have that condition, we are done waiting for now
            if (valid_last_packet = '1') then 
                state <= WAIT_FOR_MULTIBYTE_PACKET;
            end if;

        end case;
      end if;
    end if;
   end process;
end architecture behavioral;
