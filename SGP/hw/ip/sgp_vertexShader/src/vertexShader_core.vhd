-------------------------------------------------------------------------
-- Joseph Zambreno
-- Steve Brooks
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------

-- vertexShader_core.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains a vertexShader core that executes
-- compiled GLSL shader code on input vertices.
--
-- NOTES:
-- 1/18/21 by JAZ::Design created.
-------------------------------------------------------------------------
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use WORK.sgp_types.all;

entity vertexShader_core is
	port
	(
        ACLK	: in	std_logic;
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
        imem_rdy         : in std_logic;
        imem_rd_req      : out std_logic;
        imem_req_done    : in std_logic
        );
		
end vertexShader_core;

architecture behavioral of vertexShader_core is
    type state_type is (WAIT_TO_START, FETCH, FETCH2, DECODE, EXECUTE, LD2, LD3, ST2);
    type register_file_t is array (0 to 255) of unsigned(127 downto 0);
    
    signal state : state_type;
    signal pc : unsigned(31 downto 0);
    signal ir : unsigned(31 downto 0);
    signal writeback : std_logic;
    signal v : register_file_T;
    signal a : unsigned(127 downto 0);
    signal b : unsigned(127 downto 0);
    signal c : unsigned(127 downto 0);

    signal op : unsigned(7 downto 0);
    signal rd : unsigned(7 downto 0);
    signal ra : unsigned(7 downto 0);
    signal rb : unsigned(7 downto 0);

    signal ww : unsigned(1 downto 0);
    signal zz : unsigned(1 downto 0);
    signal yy : unsigned(1 downto 0);
    signal xx : unsigned(1 downto 0);

    -- don't subscript aliases unless you know what you are doing!  I don't.
    alias a3 is a(127 downto 96); alias a2 is a( 95 downto 64); alias a1 is a( 63 downto 32); alias a0 is a( 31 downto  0);
    alias b3 is b(127 downto 96); alias b2 is b( 95 downto 64); alias b1 is b( 63 downto 32); alias b0 is b( 31 downto  0);
    alias c3 is c(127 downto 96); alias c2 is c( 95 downto 64); alias c1 is c( 63 downto 32); alias c0 is c( 31 downto  0);

    constant NOP        : unsigned(7 downto 0) := "00000000";   -- could use x"00"
    constant SWIZZLE    : unsigned(7 downto 0) := "00000001";
    constant LDILO      : unsigned(7 downto 0) := "00000010";
    constant LDIHI      : unsigned(7 downto 0) := "00000011";

    constant LD         : unsigned(7 downto 0) := "00000100";
    constant ST         : unsigned(7 downto 0) := "00000101";
    constant INFIFO     : unsigned(7 downto 0) := "00000110";
    constant OUTFIFO    : unsigned(7 downto 0) := "00000111";

    constant INSERT0    : unsigned(7 downto 0) := "00001000";
    constant INSERT1    : unsigned(7 downto 0) := "00001001";
    constant INSERT2    : unsigned(7 downto 0) := "00001010";
    constant INSERT3    : unsigned(7 downto 0) := "00001011";

    constant ADD        : unsigned(7 downto 0) := "00010000";
    constant SUB        : unsigned(7 downto 0) := "00010001";

    constant AAND       : unsigned(7 downto 0) := "00011000";
    constant OOR        : unsigned(7 downto 0) := "00011001";
    constant XXOR       : unsigned(7 downto 0) := "00011010";

    constant DONE       : unsigned(7 downto 0) := "11111111";

begin
    op <= ir(31 downto 24);
    rd <= ir(23 downto 16);
    ra <= ir(15 downto  8);
    rb <= ir( 7 downto  0);
    
    ww <= rb(7 downto 6);
    zz <= rb(5 downto 4);
    yy <= rb(3 downto 2);
    xx <= rb(1 downto 0);

    imem_addr <= std_logic_vector(pc);
    dmem_addr <= std_logic_vector(c0);
    dmem_wdata <= std_logic_vector(b0); 


    -- Set output to input for passthrough mode. Remove this. 
    outputVertex <= inputVertex;

    process(ACLK)
    begin
        if rising_edge(ACLK) then
            if ARESETN = '0' then
                state <= WAIT_TO_START;
                ir <= x"0000_0000";
                writeback <= '0';
                imem_rd_req <= '0';
                dmem_rd_req <= '0';
                dmem_wr_req <= '0';
                vertexDone <= '0';
            else
                case state is
                    when WAIT_TO_START =>
                        vertexDone <= '0';
                        if vertexStart = '1' then
                            pc <= startPC;
                            state <= FETCH;
                        end if;

                    -- Update to implement fetch / decode / execute logic
                    when FETCH =>
                        vertexDone <= '1';
                        state <= WAIT_TO_START;
                    when others =>
                        state <= WAIT_TO_START;
                end case;
            end if;
        end if;         
    end process;
end architecture behavioral;
