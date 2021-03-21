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

    --used to make two's complement a one cycle occurence
    signal negateTemp0, negateTemp1, negateTemp2, negateTemp3 : unsigned(31 downto 0);
    --dictates which SIMD vector we are on
    signal processed : std_logic_vector(1 downto 0);
    --Indicates that we should block while doing serialized instructions
    signal blocking : std_logic := '0';
    signal testSig : integer;

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
    
    constant INTERLEAVELO       : unsigned(7 downto 0) := "00001100";
    constant INTERLEAVEHI       : unsigned(7 downto 0) := "00001101";
    constant INTERLEAVELOPAIRS  : unsigned(7 downto 0) := "00001110";
    constant INTERLEAVEHIPAIRS  : unsigned(7 downto 0) := "00001111";

    constant SHL        : unsigned(7 downto 0) := "00011100";
    constant SHR        : unsigned(7 downto 0) := "00011101";
    constant SAR        : unsigned(7 downto 0) := "00011110";

    constant FADD       : unsigned(7 downto 0) :=  "00100000";
    constant FSUB       : unsigned(7 downto 0) :=  "00100001"; 
    constant FMUL       : unsigned(7 downto 0) :=  "00100010";
    constant FDIV       : unsigned(7 downto 0) :=  "00100011";

    constant FNEG       : unsigned(7 downto 0) :=  "00100100";
    constant FSQRT      : unsigned(7 downto 0) :=  "00100101"; 
    constant FMAX       : unsigned(7 downto 0) :=  "00100110";
    constant FPOW       : unsigned(7 downto 0) :=  "00101000";



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

    negateTemp0 <= NOT a0;
    negateTemp1 <= NOT a1;
    negateTemp2 <= NOT a2;
    negateTemp3 <= NOT a3;

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
                processed <= "00";
            else
                case state is
                    when WAIT_TO_START =>
                        vertexDone <= '0';
                        if vertexStart = '1' then
                            pc <= startPC;
                            state <= FETCH;
                        end if;

                    -- Update to implement fetch / decode / execute logic


                    --Wait to fetch until the icache is ready
                             --set address to pc, and set the read flag high.
                    when FETCH =>
                        if imem_rdy = '1' then
                            -- imem_addr <= std_logic_vector(pc); -- This is already done above
                            imem_rd_req <= '1';
                            state <= FETCH2;
                        end if;

                        if (op /= ST and op /= DONE and op /= NOP and op /= OUTFIFO) then
                            v(to_integer(rd)) <= c;
                        end if;

                    --wait until icache is done,
                            --set read req low,
                            --store fetched instruction in ir
                    when FETCH2 =>
                        if(imem_req_done = '1') then
                            imem_rd_req <= '0';
                            ir <= unsigned(imem_rdata);
                            state <= DECODE;
                            pc <= pc + 4;
                        end if;

                    when DECODE =>
                        --don't set rd,rb,ra etc as they are done above
                        a <= v(to_integer(ra));
                        b <= v(to_integer(rb));
                        state <= EXECUTE;
                    when EXECUTE =>      
                        case op is
                            --Gross instructions go here because yeah. 
                            when FSQRT =>
                                blocking <='1';
                            when FDIV =>
                                blocking <='1';
                            when FMUL =>
                                blocking <='1';
                                if(processed = "00")then
                                    c0 <= a0 * b0;
                                    processed <= "01";
                                elsif(processed = "01")then
                                    c1 <= a1 * b1;
                                    processed <= "10";
                                elsif(processed = "10")then
                                    c2 <= a2 * b2;
                                    processed <= "11";
                                elsif(processed = "11")then
                                    c3 <= a3 * b3;
                                    processed <= "00";
                                    blocking <= '0';
                                end if;
                            when FPOW =>
                                blocking <='1';
                            when NOP =>
                            when SWIZZLE =>
                                c0 <= a(TO_INTEGER((xx & b"00000") + 31) downto to_integer(xx & b"00000"));
                                c1 <= a(TO_INTEGER((yy & b"00000") + 31) downto to_integer(yy & b"00000"));
                                c2 <= a(TO_INTEGER((zz & b"00000") + 31) downto to_integer(zz & b"00000"));
                                c3 <= a(TO_INTEGER((ww & b"00000") + 31) downto to_integer(ww & b"00000"));
                                testSig <= TO_INTEGER((xx & b"00000") + 31);
                                --c0 <= a(to_integer(xx * 32 + 31) downto to_integer(xx * 32));
                                --c1 <= a(to_integer(yy * 32 + 31) downto to_integer(yy * 32));
                                --c2 <= a(to_integer(zz * 32 + 31) downto to_integer(zz * 32));
                                --c3 <= a(to_integer(ww * 32 + 31) downto to_integer(ww * 32));
                            when LDILO =>
                                c0 <= resize(unsigned(ir(15 downto 0)),32);
                                c1 <= resize(unsigned(ir(15 downto 0)),32);
                                c2 <= resize(unsigned(ir(15 downto 0)),32);
                                c3 <= resize(unsigned(ir(15 downto 0)),32);
                                -- c0 <= "00" && ir(15 downto 0);
                                -- c1 <= "00" && ir(15 downto 0);
                                -- c2 <= "00" && ir(15 downto 0);
                                -- c3 <= "00" && ir(15 downto 0);
                            when LDIHI =>
                                c0 <= ir(15 downto 0) & x"0000";
                                c1 <= ir(15 downto 0) & x"0000";
                                c2 <= ir(15 downto 0) & x"0000";
                                c3 <= ir(15 downto 0) & x"0000";
                            when LD =>
                                c0 <= a0 + rb;
                                if (dmem_rdy = '1') then
                                    dmem_rd_req <= '1';
                                    state <= LD2;
                                end if;
                            when ST => 
                                c0 <= a0 + rd;
                                if (dmem_rdy = '1') then
                                    dmem_wr_req <= '1';
                                    state <= ST2;
                                end if;
                            when INFIFO =>
                                c0 <= unsigned(inputvertex(to_integer(rb(7 downto 2)))(to_integer(rb(1 downto 0))));
                                c(127 downto 32) <= (others => '0');
                            when OUTFIFO =>
                                outputvertex(to_integer(rd(7 downto 2)))(to_integer(rd(1 downto 0))) <= signed(b0);
                            when INSERT0 =>
                                c0 <= b0;
                                c1 <= a1;
                                c2 <= a2;
                                c3 <= a3;
                            when INSERT1 =>
                                c0 <= a0;
                                c1 <= b0;
                                c2 <= a2;
                                c3 <= a3;
                            when INSERT2 =>
                                c0 <= a0;
                                c1 <= a1;
                                c2 <= b0;
                                c3 <= a3;
                            when INSERT3 =>
                                c0 <= a0;
                                c1 <= a1;
                                c2 <= a2;
                                c3 <= b0;
                            when ADD =>
                                c0 <= a0 + b0;
                                c1 <= a1 + b1;
                                c2 <= a2 + b2;
                                c3 <= a3 + b3;
                            when SUB =>
                                c0 <= a0 - b0;
                                c1 <= a1 - b1;
                                c2 <= a2 - b2;
                                c3 <= a3 - b3;
                            when AAND =>
                                c0 <= a0 and b0;
                                c1 <= a1 and b1;
                                c2 <= a2 and b2;
                                c3 <= a3 and b3;
                            when OOR =>
                                c0 <= a0 or b0;
                                c1 <= a1 or b1;
                                c2 <= a2 or b2;
                                c3 <= a3 or b3;
                            when XXOR =>
                                c0 <= a0 xor b0;
                                c1 <= a1 xor b1;
                                c2 <= a2 xor b2;
                                c3 <= a3 xor b3;
                            when INTERLEAVELO =>
                                c0 <= a0;
                                c1 <= b0;
                                c2 <= a1;
                                c3 <= b1;
                            when INTERLEAVEHI =>
                                c0 <= a2;
                                c1 <= b2;
                                c2 <= a3;
                                c3 <= b3;
                            when INTERLEAVELOPAIRS =>
                                c0 <= a0;
                                c1 <= a1;
                                c2 <= b0;
                                c3 <= b1;
                            when INTERLEAVEHIPAIRS =>
                                c0 <= a2;
                                c1 <= a3;
                                c2 <= b2;
                                c3 <= b3;
                            when SHL =>
                                c0 <= shift_left(a0, to_integer(b0));
                                c1 <= shift_left(a1, to_integer(b1));
                                c2 <= shift_left(a2, to_integer(b2));
                                c3 <= shift_left(a3, to_integer(b3));
                            when SHR =>
                                c0 <= shift_right(a0, to_integer(b0));
                                c1 <= shift_right(a1, to_integer(b1));
                                c2 <= shift_right(a2, to_integer(b2));
                                c3 <= shift_right(a3, to_integer(b3));
                            when SAR =>
                                -- I was looking up and arithmetic shift but all I could find
                                -- was to input a signed value instead of unsigned
                                -- doing this caused a syntax error on vivado so :shrug:
                            when FADD =>
                                c0 <= a0 + b0;
                                c1 <= a1 + b1;
                                c2 <= a2 + b2;
                                c3 <= a3 + b3;
                            when FSUB =>
                                c0 <= a0 - b0;
                                c1 <= a1 - b1;
                                c2 <= a2 - b2;
                                c3 <= a3 - b3;
                            when FNEG =>
                                c0 <= unsigned(negateTemp0 + 1);
                                c1 <= unsigned(negateTemp1 + 1);
                                c2 <= unsigned(negateTemp2 + 1);
                                c3 <= unsigned(negateTemp3 + 1);
                            when FMAX =>
                                if(a0>=b0) then
                                    c0<= a0;
                                else
                                    c0<= b0;
                                end if;
                                if(a1>=b1) then
                                    c1<=a1;
                                else
                                    c1<=b1;
                                end if;
                                if(a2>=b2) then
                                    c2<=a2;
                                else
                                    c2<=b2;
                                end if;
                                if(a3>=b3) then
                                    c3 <= a3;
                                else
                                    c3<=b3;
                                end if;
                            when DONE =>
                                state <= WAIT_TO_START;
                                vertexDone <= '1';
                            when others =>
                        end case;
                        
                        if (op /= ST and op /= LD and op /= DONE and blocking /= '1') then
                            state <= FETCH;
                        end if;

                    when ST2 =>
                        if (dmem_req_done = '1') then -- Waits for DCache to finish writing and that's all
                            state <= FETCH;
                        end if;
                    when LD2 =>
                        if (dmem_req_done = '1') then
                            dmem_rd_req <= '0';
                            c <= ((127 downto 32 => '0') & unsigned(dmem_rdata));
                            state <= FETCH;
                        end if;
                    when others =>
                        state <= WAIT_TO_START;
                end case;
            end if;
        end if;         
    end process;
end architecture behavioral;
