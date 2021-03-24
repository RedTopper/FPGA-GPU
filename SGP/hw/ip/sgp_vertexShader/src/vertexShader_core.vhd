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

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE WORK.sgp_types.ALL;

ENTITY vertexShader_core IS
    PORT (
        ACLK : IN STD_LOGIC;
        ARESETN : IN STD_LOGIC;

        startPC : IN unsigned(31 DOWNTO 0);
        inputVertex : IN vertexArray_t;
        outputVertex : OUT vertexArray_t;
        vertexStart : IN STD_LOGIC;
        vertexDone : OUT STD_LOGIC;

        dmem_addr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        dmem_wdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        dmem_rdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        dmem_rd_req : OUT STD_LOGIC;
        dmem_wr_req : OUT STD_LOGIC;
        dmem_rdy : IN STD_LOGIC;
        dmem_req_done : IN STD_LOGIC;

        imem_addr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        imem_rdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        imem_rdy : IN STD_LOGIC;
        imem_rd_req : OUT STD_LOGIC;
        imem_req_done : IN STD_LOGIC
    );

END vertexShader_core;

ARCHITECTURE behavioral OF vertexShader_core IS
    TYPE state_type IS (WAIT_TO_START, FETCH, FETCH2, DECODE, EXECUTE, LD2, LD3, ST2);
    TYPE register_file_t IS ARRAY (0 TO 255) OF unsigned(127 DOWNTO 0);

    SIGNAL state : state_type;
    SIGNAL pc : unsigned(31 DOWNTO 0);
    SIGNAL ir : unsigned(31 DOWNTO 0);
    SIGNAL writeback : STD_LOGIC;
    SIGNAL v : register_file_T;
    SIGNAL a : unsigned(127 DOWNTO 0);
    SIGNAL b : unsigned(127 DOWNTO 0);
    SIGNAL c : unsigned(127 DOWNTO 0);

    SIGNAL op : unsigned(7 DOWNTO 0);
    SIGNAL rd : unsigned(7 DOWNTO 0);
    SIGNAL ra : unsigned(7 DOWNTO 0);
    SIGNAL rb : unsigned(7 DOWNTO 0);

    SIGNAL ww : unsigned(1 DOWNTO 0);
    SIGNAL zz : unsigned(1 DOWNTO 0);
    SIGNAL yy : unsigned(1 DOWNTO 0);
    SIGNAL xx : unsigned(1 DOWNTO 0);

    --used to make two's complement a one cycle occurence
    SIGNAL negateTemp0, negateTemp1, negateTemp2, negateTemp3 : unsigned(31 DOWNTO 0);
    --dictates which SIMD vector we are on
    SIGNAL processed : STD_LOGIC_VECTOR(2 DOWNTO 0);
    --Indicates that we should block while doing serialized instructions
    SIGNAL blocking : STD_LOGIC := '0';
    SIGNAL testSig : INTEGER;
    SIGNAL multResa,multResb,multResc,multResd : std_logic_vector(63 downto 0); 

    -- don't subscript aliases unless you know what you are doing!  I don't.
    ALIAS a3 IS a(127 DOWNTO 96);
    ALIAS a2 IS a(95 DOWNTO 64);
    ALIAS a1 IS a(63 DOWNTO 32);
    ALIAS a0 IS a(31 DOWNTO 0);
    ALIAS b3 IS b(127 DOWNTO 96);
    ALIAS b2 IS b(95 DOWNTO 64);
    ALIAS b1 IS b(63 DOWNTO 32);
    ALIAS b0 IS b(31 DOWNTO 0);
    ALIAS c3 IS c(127 DOWNTO 96);
    ALIAS c2 IS c(95 DOWNTO 64);
    ALIAS c1 IS c(63 DOWNTO 32);
    ALIAS c0 IS c(31 DOWNTO 0);

    CONSTANT NOP : unsigned(7 DOWNTO 0) := "00000000"; -- could use x"00"
    CONSTANT SWIZZLE : unsigned(7 DOWNTO 0) := "00000001";
    CONSTANT LDILO : unsigned(7 DOWNTO 0) := "00000010";
    CONSTANT LDIHI : unsigned(7 DOWNTO 0) := "00000011";

    CONSTANT LD : unsigned(7 DOWNTO 0) := "00000100";
    CONSTANT ST : unsigned(7 DOWNTO 0) := "00000101";
    CONSTANT INFIFO : unsigned(7 DOWNTO 0) := "00000110";
    CONSTANT OUTFIFO : unsigned(7 DOWNTO 0) := "00000111";

    CONSTANT INSERT0 : unsigned(7 DOWNTO 0) := "00001000";
    CONSTANT INSERT1 : unsigned(7 DOWNTO 0) := "00001001";
    CONSTANT INSERT2 : unsigned(7 DOWNTO 0) := "00001010";
    CONSTANT INSERT3 : unsigned(7 DOWNTO 0) := "00001011";

    CONSTANT ADD : unsigned(7 DOWNTO 0) := "00010000";
    CONSTANT SUB : unsigned(7 DOWNTO 0) := "00010001";

    CONSTANT AAND : unsigned(7 DOWNTO 0) := "00011000";
    CONSTANT OOR : unsigned(7 DOWNTO 0) := "00011001";
    CONSTANT XXOR : unsigned(7 DOWNTO 0) := "00011010";

    CONSTANT INTERLEAVELO : unsigned(7 DOWNTO 0) := "00001100";
    CONSTANT INTERLEAVEHI : unsigned(7 DOWNTO 0) := "00001101";
    CONSTANT INTERLEAVELOPAIRS : unsigned(7 DOWNTO 0) := "00001110";
    CONSTANT INTERLEAVEHIPAIRS : unsigned(7 DOWNTO 0) := "00001111";

    CONSTANT SHL : unsigned(7 DOWNTO 0) := "00011100";
    CONSTANT SHR : unsigned(7 DOWNTO 0) := "00011101";
    CONSTANT SAR : unsigned(7 DOWNTO 0) := "00011110";

    CONSTANT FADD : unsigned(7 DOWNTO 0) := "00100000";
    CONSTANT FSUB : unsigned(7 DOWNTO 0) := "00100001";
    CONSTANT FMUL : unsigned(7 DOWNTO 0) := "00100010";
    CONSTANT FDIV : unsigned(7 DOWNTO 0) := "00100011";

    CONSTANT FNEG : unsigned(7 DOWNTO 0) := "00100100";
    CONSTANT FSQRT : unsigned(7 DOWNTO 0) := "00100101";
    CONSTANT FMAX : unsigned(7 DOWNTO 0) := "00100110";
    CONSTANT FPOW : unsigned(7 DOWNTO 0) := "00101000";

    CONSTANT DONE : unsigned(7 DOWNTO 0) := "11111111";

BEGIN
    op <= ir(31 DOWNTO 24);
    rd <= ir(23 DOWNTO 16);
    ra <= ir(15 DOWNTO 8);
    rb <= ir(7 DOWNTO 0);

    ww <= rb(7 DOWNTO 6);
    zz <= rb(5 DOWNTO 4);
    yy <= rb(3 DOWNTO 2);
    xx <= rb(1 DOWNTO 0);

    imem_addr <= STD_LOGIC_VECTOR(pc);
    dmem_addr <= STD_LOGIC_VECTOR(c0);
    dmem_wdata <= STD_LOGIC_VECTOR(b0);

    negateTemp0 <= NOT a0;
    negateTemp1 <= NOT a1;
    negateTemp2 <= NOT a2;
    negateTemp3 <= NOT a3;

    PROCESS (ACLK)
    BEGIN
        IF rising_edge(ACLK) THEN
            IF ARESETN = '0' THEN
                state <= WAIT_TO_START;
                ir <= x"0000_0000";
                writeback <= '0';
                imem_rd_req <= '0';
                dmem_rd_req <= '0';
                dmem_wr_req <= '0';
                vertexDone <= '0';
                processed <= "000";
            ELSE
                CASE state IS
                    WHEN WAIT_TO_START =>
                        vertexDone <= '0';
                        IF vertexStart = '1' THEN
                            pc <= startPC;
                            state <= FETCH;
                        END IF;

                        -- Update to implement fetch / decode / execute logic
                        --Wait to fetch until the icache is ready
                        --set address to pc, and set the read flag high.
                    WHEN FETCH =>
                        IF imem_rdy = '1' THEN
                            -- imem_addr <= std_logic_vector(pc); -- This is already done above
                            imem_rd_req <= '1';
                            state <= FETCH2;
                        END IF;

                        IF (op /= ST AND op /= DONE AND op /= NOP AND op /= OUTFIFO) THEN
                            v(to_integer(rd)) <= c;
                        END IF;

                        --wait until icache is done,
                        --set read req low,
                        --store fetched instruction in ir
                    WHEN FETCH2 =>
                        IF (imem_req_done = '1') THEN
                            imem_rd_req <= '0';
                            ir <= unsigned(imem_rdata);
                            state <= DECODE;
                            pc <= pc + 4;
                        END IF;

                    WHEN DECODE =>
                        --don't set rd,rb,ra etc as they are done above
                        a <= v(to_integer(ra));
                        b <= v(to_integer(rb));
                        if (op = FMUL) then
                            blocking <= '1';
                        end if;
                        state <= EXECUTE;
                    WHEN EXECUTE =>
                        CASE op IS
                                --Gross instructions go here because yeah. 
                            WHEN FSQRT =>
                                --blocking <='1';
                            WHEN FDIV =>
                                --blocking <='1';
                            WHEN FMUL =>
                                if(processed = "000")then
                                   multResa <= std_logic_vector(a0 * b0);
                                   processed <= "001";
                                elsif(processed = "001")then
                                   c0 <= unsigned(multResa(47 downto 16));
                                   multResa <= std_logic_vector(a1 * b1);
                                   processed <= "010";
                                elsif(processed = "010")then
                                   c1 <= unsigned(multResa(47 downto 16));
                                   multResa <= std_logic_vector(a2 * b2);
                                   processed <= "011";
                                elsif(processed = "011")then
                                   c2 <= unsigned(multResa(47 downto 16));
                                   multResa <= std_logic_vector(a3 * b3);
                                   processed <= "100";
                                   blocking <= '0';
                                elsif(processed = "100")then
                                    c3 <= unsigned(multResa(47 downto 16));
                                    processed <="000";
                                end if;
                            WHEN FPOW =>
                                --blocking <='1';
                            WHEN NOP =>
                            WHEN SWIZZLE =>
                                CASE xx IS
                                    WHEN "00" =>
                                        c0 <= a(31 DOWNTO 0);
                                    WHEN "01" =>
                                        c0 <= a(63 DOWNTO 32);
                                    WHEN "10" =>
                                        c0 <= a(95 DOWNTO 64);
                                    WHEN "11" =>
                                        c0 <= a(127 DOWNTO 96);
                                    WHEN others =>
                                END CASE;
                                CASE yy IS
                                    WHEN "00" =>
                                        c1 <= a(31 DOWNTO 0);
                                    WHEN "01" =>
                                        c1 <= a(63 DOWNTO 32);
                                    WHEN "10" =>
                                        c1 <= a(95 DOWNTO 64);
                                    WHEN "11" =>
                                        c1 <= a(127 DOWNTO 96);
                                    WHEN others =>
                                END CASE;
                                CASE zz IS
                                    WHEN "00" =>
                                        c2 <= a(31 DOWNTO 0);
                                    WHEN "01" =>
                                        c2 <= a(63 DOWNTO 32);
                                    WHEN "10" =>
                                        c2 <= a(95 DOWNTO 64);
                                    WHEN "11" =>
                                        c2 <= a(127 DOWNTO 96);
                                    WHEN others =>
                                END CASE;
                                CASE ww IS
                                    WHEN "00" =>
                                        c3 <= a(31 DOWNTO 0);
                                    WHEN "01" =>
                                        c3 <= a(63 DOWNTO 32);
                                    WHEN "10" =>
                                        c3 <= a(95 DOWNTO 64);
                                    WHEN "11" =>
                                        c3 <= a(127 DOWNTO 96);
                                    WHEN others =>
                                END CASE;
                            WHEN LDILO =>
                                c0 <= resize(unsigned(ir(15 DOWNTO 0)), 32);
                                c1 <= resize(unsigned(ir(15 DOWNTO 0)), 32);
                                c2 <= resize(unsigned(ir(15 DOWNTO 0)), 32);
                                c3 <= resize(unsigned(ir(15 DOWNTO 0)), 32);
                                -- c0 <= "00" && ir(15 downto 0);
                                -- c1 <= "00" && ir(15 downto 0);
                                -- c2 <= "00" && ir(15 downto 0);
                                -- c3 <= "00" && ir(15 downto 0);
                            WHEN LDIHI =>
                                c0 <= ir(15 DOWNTO 0) & x"0000";
                                c1 <= ir(15 DOWNTO 0) & x"0000";
                                c2 <= ir(15 DOWNTO 0) & x"0000";
                                c3 <= ir(15 DOWNTO 0) & x"0000";
                            WHEN LD =>
                                c0 <= a0 + rb;
                                IF (dmem_rdy = '1') THEN
                                    dmem_rd_req <= '1';
                                    state <= LD2;
                                END IF;
                            WHEN ST =>
                                c0 <= a0 + rd;
                                IF (dmem_rdy = '1') THEN
                                    dmem_wr_req <= '1';
                                    state <= ST2;
                                END IF;
                            WHEN INFIFO =>
                                c0 <= unsigned(inputvertex(to_integer(rb(7 DOWNTO 2)))(to_integer(rb(1 DOWNTO 0))));
                                c(127 DOWNTO 32) <= (OTHERS => '0');
                            WHEN OUTFIFO =>
                                outputvertex(to_integer(rd(7 DOWNTO 2)))(to_integer(rd(1 DOWNTO 0))) <= signed(b0);
                            WHEN INSERT0 =>
                                c0 <= b0;
                                c1 <= a1;
                                c2 <= a2;
                                c3 <= a3;
                            WHEN INSERT1 =>
                                c0 <= a0;
                                c1 <= b0;
                                c2 <= a2;
                                c3 <= a3;
                            WHEN INSERT2 =>
                                c0 <= a0;
                                c1 <= a1;
                                c2 <= b0;
                                c3 <= a3;
                            WHEN INSERT3 =>
                                c0 <= a0;
                                c1 <= a1;
                                c2 <= a2;
                                c3 <= b0;
                            WHEN ADD =>
                                c0 <= a0 + b0;
                                c1 <= a1 + b1;
                                c2 <= a2 + b2;
                                c3 <= a3 + b3;
                            WHEN SUB =>
                                c0 <= a0 - b0;
                                c1 <= a1 - b1;
                                c2 <= a2 - b2;
                                c3 <= a3 - b3;
                            WHEN AAND =>
                                c0 <= a0 AND b0;
                                c1 <= a1 AND b1;
                                c2 <= a2 AND b2;
                                c3 <= a3 AND b3;
                            WHEN OOR =>
                                c0 <= a0 OR b0;
                                c1 <= a1 OR b1;
                                c2 <= a2 OR b2;
                                c3 <= a3 OR b3;
                            WHEN XXOR =>
                                c0 <= a0 XOR b0;
                                c1 <= a1 XOR b1;
                                c2 <= a2 XOR b2;
                                c3 <= a3 XOR b3;
                            WHEN INTERLEAVELO =>
                                c0 <= a0;
                                c1 <= b0;
                                c2 <= a1;
                                c3 <= b1;
                            WHEN INTERLEAVEHI =>
                                c0 <= a2;
                                c1 <= b2;
                                c2 <= a3;
                                c3 <= b3;
                            WHEN INTERLEAVELOPAIRS =>
                                c0 <= a0;
                                c1 <= a1;
                                c2 <= b0;
                                c3 <= b1;
                            WHEN INTERLEAVEHIPAIRS =>
                                c0 <= a2;
                                c1 <= a3;
                                c2 <= b2;
                                c3 <= b3;
                            WHEN SHL =>
                                c0 <= shift_left(a0, to_integer(b0));
                                c1 <= shift_left(a1, to_integer(b1));
                                c2 <= shift_left(a2, to_integer(b2));
                                c3 <= shift_left(a3, to_integer(b3));
                            WHEN SHR =>
                                c0 <= shift_right(a0, to_integer(b0));
                                c1 <= shift_right(a1, to_integer(b1));
                                c2 <= shift_right(a2, to_integer(b2));
                                c3 <= shift_right(a3, to_integer(b3));
                            WHEN SAR =>
                                -- I was looking up and arithmetic shift but all I could find
                                -- was to input a signed value instead of unsigned
                                -- doing this caused a syntax error on vivado so :shrug:
                            WHEN FADD =>
                                c0 <= a0 + b0;
                                c1 <= a1 + b1;
                                c2 <= a2 + b2;
                                c3 <= a3 + b3;
                            WHEN FSUB =>
                                c0 <= a0 - b0;
                                c1 <= a1 - b1;
                                c2 <= a2 - b2;
                                c3 <= a3 - b3;
                            WHEN FNEG =>
                                c0 <= unsigned(negateTemp0 + 1);
                                c1 <= unsigned(negateTemp1 + 1);
                                c2 <= unsigned(negateTemp2 + 1);
                                c3 <= unsigned(negateTemp3 + 1);
                            WHEN FMAX =>
                                IF (a0 >= b0) THEN
                                    c0 <= a0;
                                ELSE
                                    c0 <= b0;
                                END IF;
                                IF (a1 >= b1) THEN
                                    c1 <= a1;
                                ELSE
                                    c1 <= b1;
                                END IF;
                                IF (a2 >= b2) THEN
                                    c2 <= a2;
                                ELSE
                                    c2 <= b2;
                                END IF;
                                IF (a3 >= b3) THEN
                                    c3 <= a3;
                                ELSE
                                    c3 <= b3;
                                END IF;
                            WHEN DONE =>
                                state <= WAIT_TO_START;
                                vertexDone <= '1';
                            WHEN OTHERS =>
                        END CASE;

                        IF (op /= ST AND op /= LD AND op /= DONE AND blocking /= '1') THEN
                            state <= FETCH;
                        END IF;

                    WHEN ST2 =>
                        dmem_wr_req <= '0';
                        IF (dmem_req_done = '1') THEN -- Waits for DCache to finish writing and that's all
                            state <= FETCH;
                        END IF;
                    WHEN LD2 =>
                        dmem_rd_req <= '0';
                        IF (dmem_req_done = '1') THEN
                            c <= ((127 DOWNTO 32 => '0') & unsigned(dmem_rdata));
                            state <= FETCH;
                        END IF;
                    WHEN OTHERS =>
                        state <= WAIT_TO_START;
                END CASE;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE behavioral;
