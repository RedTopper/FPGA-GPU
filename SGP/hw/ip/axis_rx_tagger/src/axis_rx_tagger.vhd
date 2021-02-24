-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- axis_rx_tagger.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an AXIS passthrough device that 
-- generates AXIS user signalling as needed to connect to an AXI 
-- MM2S_Mapper slave. 
--
-- NOTES:
-- 10/23/20 by JAZ::Design created.
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity axis_rx_tagger is
	port (ACLK	: in	std_logic;
		ARESETN	: in	std_logic;
		S_AXIS_TREADY	: out	std_logic;
		S_AXIS_TDATA	: in	std_logic_vector(7 downto 0);
		S_AXIS_TLAST	: in	std_logic;
		S_AXIS_TVALID	: in	std_logic;
		M_AXIS_TVALID	: out	std_logic;
		M_AXIS_TDATA	: out	std_logic_vector(7 downto 0);
		M_AXIS_TLAST	: out	std_logic;
		M_AXIS_TREADY	: in	std_logic;

		M_AXIS_TID 		: out 	std_logic_vector(2 downto 0));

attribute SIGIS : string; 
attribute SIGIS of ACLK : signal is "Clk"; 

end axis_rx_tagger;


architecture behavioral of axis_rx_tagger is

	-- Total number of header bytes
	constant NUMBER_OF_HEADER_BYTES : natural := 2;

  -- Width of packet length field
  constant PACKET_LENGTH_FIELD : natural := 15;

  -- Flag for read vs write transaction ('0' for read, '1' for write)
  signal trans_type : std_logic;

  -- Counter to store the number of bytes (after the first NUMBER_OF_HEADER_BYTES) forwarded
  signal trans_length, byte_count : unsigned(PACKET_LENGTH_FIELD-1 downto 0);

  -- We have to separately keep track of the bytes sent in WRITE_DATA to toggle TLAST correctly
  signal write_data_byte_count : unsigned(2 downto 0);

  -- Signal to hold the header
  signal header_bytes : std_logic_vector(8*NUMBER_OF_HEADER_BYTES-1 downto 0);


  type STATE_TYPE is (INIT_HEADER_1, INIT_HEADER_2, READ_ADDR, WRITE_ADDR, WRITE_DATA);
  signal state        : STATE_TYPE;
   

begin

  -- The first bit we receive in the header is always the type, the remainder of the bits are 
  -- specifying the length
  trans_type <= header_bytes(header_bytes'left);
  trans_length <= unsigned(header_bytes(header_bytes'left-1 downto 0));
  
  
  M_AXIS_TVALID <= '0' when state = INIT_HEADER_1 else
                   '0' when state = INIT_HEADER_2 else
                    S_AXIS_TVALID;

  M_AXIS_TDATA <= (others => '0') when state = INIT_HEADER_1 else
                  (others => '0') when state = INIT_HEADER_2 else 
                  S_AXIS_TDATA;
                  
                  
  M_AXIS_TID <= "000" when state = INIT_HEADER_1 else                
                "000" when state = INIT_HEADER_2 else
                "010" when state = READ_ADDR else
                "001" when state = WRITE_ADDR else
                "100" when state = WRITE_DATA else
                "000";

  S_AXIS_TREADY <= '1' when state = INIT_HEADER_1 else
                   '1' when state = INIT_HEADER_2 else
                   M_AXIS_TREADY;             


  M_AXIS_TLAST <= '1' when byte_count = trans_length-1 else
                  '1' when byte_count = 8-1 else
                  '1' when write_data_byte_count = 4 else
                  '0';

  -- A 5-state FSM, where we read two header bytes (INIT_HEADER_1 and INIT_HEADER 2), and
  -- then forward on the data as needed in the format that the AXI_MM2S_mapper is expecting
   process (ACLK) is
   begin 
    if rising_edge(ACLK) then  
      if ARESETN = '0' then    

        -- Start at INIT_HEADER_1, initialize all other registers. trans_length and trans_type are just
        -- relabelled wires from the header (this is hard-coded for now)
        state        <= INIT_HEADER_1;
        header_bytes <= (others => '0');
        byte_count   <= (others => '0');
        write_data_byte_count <= (others => '0');

      else
        case state is
          when INIT_HEADER_1 =>
            -- We are ready to receive data but will not be sending any in this state.
            byte_count   <= (others => '0');

            -- Is there valid data? That is our first header byte
            if (S_AXIS_TVALID = '1') then
              header_bytes(8*NUMBER_OF_HEADER_BYTES-1 downto 8*(NUMBER_OF_HEADER_BYTES-1)) <= S_AXIS_TDATA;
              state <= INIT_HEADER_2;
            end if;

          when INIT_HEADER_2 =>
            -- We are ready to receive data but will not be sending any in this state.
            -- Is there valid data? That is our second header byte. We should now know if this is a READ or WRITE transaction
            if (S_AXIS_TVALID = '1') then
              header_bytes(8*(NUMBER_OF_HEADER_BYTES-1)-1 downto 8*(NUMBER_OF_HEADER_BYTES-2)) <= S_AXIS_TDATA;
              if (trans_type = '0') then
                state <= READ_ADDR;
              else
                state <= WRITE_ADDR;
                end if;
            end if;

          -- We need to forward on the next trans_length bytes, with TID and TLAST signaling as specified by the spec
          -- This forwarding could be done outside of the FSM, but logic usage should be roughly the same. 
          when READ_ADDR =>

            -- We've received a byte (only if ready to transmit), update our counter and check if we're done. 
            if (S_AXIS_TVALID = '1' and M_AXIS_TREADY = '1') then
              byte_count <= byte_count + 1;

              if (byte_count = trans_length-1) then
                state <= INIT_HEADER_1;
              end if;
            end if;

          -- Similar to READ_ADDR, except that we are expecting 8 bytes (or technically trans_length-8)
          when WRITE_ADDR =>

            -- We've received a byte (only if ready to transmit), update our counter and check if we can now transition to WRITE_DATA. 
            if (S_AXIS_TVALID = '1' and M_AXIS_TREADY = '1') then
              byte_count <= byte_count + 1;
              if (byte_count = 8-1) then
                state <= WRITE_DATA;
              end if;
            end if;

          -- Similar to READ_ADDR
          when WRITE_DATA =>

            -- We've received a byte (only if ready to transmit), update our counter and check if we can now transition to WRITE_DATA. 
            if (S_AXIS_TVALID = '1' and M_AXIS_TREADY = '1') then
              byte_count <= byte_count + 1;

              if (write_data_byte_count = 4) then
                write_data_byte_count <= (others => '0');
              else 
                write_data_byte_count <= write_data_byte_count + 1;
              end if;

              if (byte_count = trans_length-1) then
                state <= INIT_HEADER_1;
              end if;
            end if;



        end case;
      end if;
    end if;
   end process;
end architecture behavioral;
