-- spv_to_sgp.lua
-- Convert disassembled (text) SPIR-V to SGP shader code
-- Refer to https://www.khronos.org/registry/spir-v/specs/1.0/SPIRV.html
--          https://www.khronos.org/registry/spir-v/specs/1.0/GLSL.std.450.html


-- this function stolen from lua-users.org
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t, cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end


if not source then
	-- if there is no source (i.e., not being called from the libSGP driver), use command-line arguments
    local sourceFile = io.open(arg[1])
    source = sourceFile:read("*all")
    sourceFile:close()
end

sourceLines = split(source, "[\r?\n]+")


local op_nop		= 0
local op_swizzle	= 1
local op_ldilo		= 2
local op_ldihi		= 3
local op_ld 		= 4
local op_st	    	= 5
local op_infifo   	= 6
local op_outfifo   	= 7

local op_insert 	= 8
-- local op_insert	= 9
-- local op_insert	= 10
-- local op_insert	= 11
local op_interleavelo	= 12
local op_interleavehi	= 13
local op_interleavelopairs	= 14
local op_interleavehipairs	= 15

local op_add		= 16
local op_sub		= 17

local op_and		= 24
local op_or			= 25
local op_xor	 	= 26

local op_shl		= 28
local op_shr		= 29
local op_sar		= 30

local op_fadd		= 32
local op_fsub		= 33
local op_fmul		= 34
local op_fdiv		= 35
local op_fneg		= 36
local op_fsqrt    	= 37
local op_fmax		= 38

local op_fpow		= 40

local op_done		= 255


binary = {}
assembly = {}

function AvengeBinary(op, rd, ra, rb)
    local s = string.char(rb, ra, rd, op)
    table.insert(binary, s)
end

function AvengeComment(comment)
    table.insert(assembly, "        ; " .. comment .. "\n")
end

function AvengeAssembler(mnemonic, operands)
    local mnemonicFieldWidth = 20
    
    operands = operands or ""
    table.insert(assembly, "        " .. mnemonic .. string.rep(" ", mnemonicFieldWidth - #mnemonic) .. operands .. "\n")
end

function AvengeAssembler3op(mnemonic, rd, ra, rb)
    rd = "v" .. rd
    ra = "v" .. ra
    rb = "v" .. rb
    AvengeAssembler(mnemonic, "" .. rd .. ", " .. ra .. ", " .. rb)
end

function AvengeAssembler2op(mnemonic, rd, ra)
    rd = "v" .. rd
    ra = "v" .. ra
    AvengeAssembler(mnemonic, "" .. rd .. ", " .. ra)
end

function Avenge_nop()
    AvengeBinary(op_nop, 0, 0, 0)
    AvengeAssembler("nop")
end

function SwizzleByte(x, y, z, w)
    x = x & 0x3
    y = y & 0x3
    z = z & 0x3
    w = w & 0x3

    return x + y*4 + z*16 + w*64
end

local swizzleLetters = {[0]="x", "y", "z", "w"}

function Avenge_swizzle(rd, ra, rb)
    AvengeBinary(op_swizzle, rd, ra, rb)

    rd = "v" .. rd
    ra = "v" .. ra
    local rbs = ""
    rbs = rbs .. swizzleLetters[(rb >> 0) & 0x3]
    rbs = rbs .. swizzleLetters[(rb >> 2) & 0x3]
    rbs = rbs .. swizzleLetters[(rb >> 4) & 0x3]
    rbs = rbs .. swizzleLetters[(rb >> 6) & 0x3]
    AvengeAssembler("swizzle", "" .. rd .. ", " .. ra .. ", " .. rbs)
end

function Avenge_ldilo(rd, value)
    AvengeBinary(op_ldilo, rd, (value >> 8) & 0xFF, value & 0xFF)

    rd = "v" .. rd
    AvengeAssembler("ldilo", "" .. rd .. ", " .. string.format("0x%04x", value))
end

function Avenge_ldihi(rd, value)
    AvengeBinary(op_ldihi, rd, (value >> 8) & 0xFF, value & 0xFF)

    rd = "v" .. rd
    AvengeAssembler("ldihi", "" .. rd .. ", " .. string.format("0x%04x", value))
end

function Avenge_ld(rd, ra, rb)
    AvengeBinary(op_ld, rd, ra, rb)

    rd = "v" .. rd
    ra = "v" .. ra
    AvengeAssembler("ld", "" .. rd .. ", [" .. ra .. " + " .. rb .. "]")
end        

function Avenge_st(rd, ra, rb)
    AvengeBinary(op_st, rd, ra, rb)

    ra = "v" .. ra
    rb = "v" .. rb
    AvengeAssembler("st", "[" .. ra .. " + " .. rd .. "], " .. rb)
end        

function Avenge_infifo(rd, location)
    AvengeBinary(op_infifo, rd, 0, location)

    rd = "v" .. rd
    AvengeAssembler("infifo", "" .. rd .. ", " .. location)
end

function Avenge_outfifo(location, rb)
    AvengeBinary(op_outfifo, location, 0, rb)

    rb = "v" .. rb
    AvengeAssembler("outfifo", "" .. location .. ", " .. rb)
end

function Avenge_insert(rd, ra, rb, i)
    AvengeBinary(op_insert + i, rd, ra, rb)

    rd = "v" .. rd
    ra = "v" .. ra
    rb = "v" .. rb
    i = swizzleLetters[i]
    AvengeAssembler("insert", "" .. rd .. ", " .. ra .. ", " .. rb .. ", " .. i)
end

function Avenge_interleavelo(rd, ra, rb)
    AvengeBinary(op_interleavelo, rd, ra, rb)
    AvengeAssembler3op("interleavelo", rd, ra, rb)
end

function Avenge_interleavehi(rd, ra, rb)
    AvengeBinary(op_interleavehi, rd, ra, rb)
    AvengeAssembler3op("interleavehi", rd, ra, rb)
end

function Avenge_interleavelopairs(rd, ra, rb)
    AvengeBinary(op_interleavelopairs, rd, ra, rb)
    AvengeAssembler3op("interleavelopairs", rd, ra, rb)
end

function Avenge_interleavehipairs(rd, ra, rb)
    AvengeBinary(op_interleavehipairs, rd, ra, rb)
    AvengeAssembler3op("interleavehipairs", rd, ra, rb)
end

function Avenge_add(rd, ra, rb)
    AvengeBinary(op_add, rd, ra, rb)
    AvengeAssembler3op("add", rd, ra, rb)
end

function Avenge_sub(rd, ra, rb)
    AvengeBinary(op_sub, rd, ra, rb)
    AvengeAssembler3op("sub", rd, ra, rb)
end

function Avenge_and(rd, ra, rb)
    AvengeBinary(op_and, rd, ra, rb)
    AvengeAssembler3op("and", rd, ra, rb)
end

function Avenge_or(rd, ra, rb)
    AvengeBinary(op_or, rd, ra, rb)
    AvengeAssembler3op("or", rd, ra, rb)
end

function Avenge_xor(rd, ra, rb)
    AvengeBinary(op_xor, rd, ra, rb)
    AvengeAssembler3op("xor", rd, ra, rb)
end

function Avenge_fadd(rd, ra, rb)
    AvengeBinary(op_fadd, rd, ra, rb)
    AvengeAssembler3op("fadd", rd, ra, rb)
end

function Avenge_fsub(rd, ra, rb)
    AvengeBinary(op_fsub, rd, ra, rb)
    AvengeAssembler3op("fsub", rd, ra, rb)
end

function Avenge_fmul(rd, ra, rb)
    AvengeBinary(op_fmul, rd, ra, rb)
    AvengeAssembler3op("fmul", rd, ra, rb)
end

function Avenge_fdiv(rd, ra, rb)
    AvengeBinary(op_fdiv, rd, ra, rb)
    AvengeAssembler3op("fdiv", rd, ra, rb)
end

function Avenge_fneg(rd, ra)
    AvengeBinary(op_fneg, rd, ra, 0)
    AvengeAssembler2op("fneg", rd, ra)
end

function Avenge_fsqrt(rd, ra)
    AvengeBinary(op_fsqrt, rd, ra, 0)
    AvengeAssembler2op("fsqrt", rd, ra)
end

function Avenge_fmax(rd, ra, rb)
    AvengeBinary(op_fmax, rd, ra, rb)
    AvengeAssembler3op("fmax", rd, ra, rb)
end

function Avenge_fpow(rd, ra, rb)
    AvengeBinary(op_fpow, rd, ra, rb)
    AvengeAssembler3op("fpow", rd, ra, rb)
end

function Avenge_done()
    AvengeBinary(op_done, 0, 0, 0)
    AvengeAssembler("done")
end


lineNumber = 1

function SourceError(s)
    error(s .. ". (line " .. lineNumber .. ")")
end


-- the first four vector registers are used to shadow the output FIFO because shaders are allowed to read "out" variables
vectorRegister = 4

function AllocateRegister(n)
    n = n or 1
    local result = vectorRegister
    vectorRegister = vectorRegister + n
    return result
end


memoryBase = memoryBase or 0xF0000000

function AllocateMemory(n)
    n = n or 1
    local result = memoryBase
    memoryBase = memoryBase + n * 4
    return result
end


uniformBase = uniformBase or 0xE0000000
uniformOffset = 0
uniforms = {}

function AllocateUniform(name, size)
    if uniforms[name] then 
        return uniforms[name].location
    else
        size = size * 4
        local newUniformOffset = uniformOffset + size

        if newUniformOffset > 1024 then
            SourceError(string.format("libSGP: Not enough uniform space left for %s", name))
        end

        local location = uniformBase + uniformOffset
        local entry = {name = name, location = location, size = size}
        uniforms[name] = entry
        table.insert(uniforms, entry)

        uniformOffset = newUniformOffset
        return location
    end
end


outs =
{
    {name = "gl_PerVertex.gl_Position", location = 0},
}
outLocation = 1

function AllocateOutLocation(name)
    if outs[name] then
        return outs[name].location
    else
        if outLocation == 4 then
            SourceError("libSGB:  No more 'out' variable locations available for " .. name)
        end

        local entry = {name = name, location = outLocation}
        outs[name] = entry
        table.insert(outs, entry)

        local result = outLocation
        outLocation = outLocation + 1
        return result
    end
end


ids = {}

function GetId(id)
    if not ids[id] then
        ids[id] = {}
        ids[id].alias = id
        ids[#ids + 1] = ids[id]
    end

    return ids[id]
end


handlers = {}

handlers.OpCapability = function()
    -- do nothing
end

handlers.OpExtInstImport = function()
    -- do nothing
end

handlers.OpMemoryModel = function()
    -- do nothing
end

handlers.OpEntryPoint = function()
    -- do nothing
end

handlers.OpSource = function()
    -- do nothing
end

handlers.OpFunction = function(words)
    -- do nothing
end

handlers.OpLabel = function(words)
    -- do nothing
end

handlers.OpReturn = function(words)
    -- do nothing
end

handlers.OpFunctionEnd = function(words)
    -- do nothing
end

handlers.OpSourceExtension = function(words)
    -- do nothing
end

handlers.OpExecutionMode = function(words)
    -- do nothing
end


names = {}

handlers.OpName = function(words)
    local id = words[2]
    local name = words[3]:match("\"(.+)\"")

    names[id] = name
end

memberNames = {}

handlers.OpMemberName = function(words)
    local id = words[2]
    local index = tonumber(words[3])
    local name = words[4]:match("\"(.+)\"")

    if not memberNames[id] then
        memberNames[id] = {}
    end

    memberNames[id][index] = name
end


decorations = {}

handlers.OpDecorate = function(words)
    local id = words[2]
    local decoration = words[3]
    local value = words[4] or true

    if not decorations[id] then
        decorations[id] = {}
    end

    decorations[id][decoration] = value
end

memberDecorations = {}

handlers.OpMemberDecorate = function(words)
    local id = words[2]
    local index = tonumber(words[3])
    local decoration = words[4]
    local value = words[5] or true

    if not memberDecorations[id] then
        memberDecorations[id] = {}
    end

    if not memberDecorations[id][index] then
        memberDecorations[id][index] = {}
    end

    memberDecorations[id][index][decoration] = value
end


typeHandlers = {}

typeHandlers.Void = function(words)
    local id = words[1]
    
    local node = GetId(id)
    node.op = "OpTypeVoid"
end

typeHandlers.Bool = function(words)
    local id = words[1]
    
    local node = GetId(id)
    node.op = "OpTypeBool"
end

typeHandlers.Int = function(words)
    local id = words[1]
    local width = words[4]
    local signedness = tonumber(words[5])
    
    local node = GetId(id)
    node.op = "OpTypeInt"
    node.width = width
    node.signedness = signedness
end

typeHandlers.Float = function(words)
    local id = words[1]
    local width = words[4]

    local node = GetId(id)
    node.op = "OpTypeFloat"
    node.width = width
end

typeHandlers.Vector = function(words)
    local id = words[1]
    local componentType = words[4]
    local componentCount = tonumber(words[5])

    local node = GetId(id)
    node.op = "OpTypeVector"
    node.componentType = componentType
    node.componentCount = componentCount
end

typeHandlers.Function = function(words)
    local id = words[1]
    local returnType = words[4]
    
    local node = GetId(id)
    node.op = "OpTypeFunction"
    node.returnType = returnType
    -- todo:  handle parameter list
end

typeHandlers.Array = function(words)
    local id = words[1]
    local elementType = words[4]
    local length = words[5]

    local node = GetId(id)
    node.op = "OpTypeArray"
    node.elementType = elementType
    node.length = length
end

typeHandlers.Struct = function(words)
    local id = words[1]
    
    local node = GetId(id)
    node.op = "OpTypeStruct"

    local i = 0;
    while words[i+4] do
        local memberType = words[i+4]
        node[i] = memberType
        i = i + 1
    end
end

typeHandlers.Matrix = function(words)
    local id = words[1]
    local columnType = words[4]
    local columnCount = tonumber(words[5])
    
    node = GetId(id)
    node.op = "OpTypeMatrix"
    node.columnType = columnType
    node.columnCount = columnCount
end

typeHandlers.Pointer = function(words)
    local id = words[1]
    local storageClass = words[4]
    local t = words[5]

    node = GetId(id)
    node.op = "OpTypePointer"
    node.storageClass = storageClass
    node.type = t
end

handlers.OpType = function(words, t)
    if typeHandlers[t] then
        typeHandlers[t](words)
    end
end


handlers.OpConstant = function(words)
    local id = words[1]
    local resultType = words[4]
    local value = tonumber(words[5])

    local node = GetId(id)
    node.op = "OpConstant"
    node.resultType = resultType
    node.value = value
    -- todo: handle values spanning more than one SPIR-V "word"

    -- generate asm
    local resultTypeNode = GetId(resultType)

    if resultTypeNode.op == "OpTypeInt" then
        local dest = AllocateRegister()
        local temp = dest + 1;
        local lo = value & 0xFFFF
        local hi = (value >> 16) & 0xFFFF

        AvengeComment("load int constant " .. value)
        Avenge_ldilo(dest, lo)
        Avenge_ldihi(temp, hi)
        Avenge_or(dest, dest, temp)

        node.register = dest
    elseif resultTypeNode.op == "OpTypeFloat" then
        local dest = AllocateRegister()
        local temp = dest + 1;
        
        if value >= 65536 then
            SourceError("OpConstant:  Cannot represent " .. value .. " in 16.16 fixed-point format; it's too large")
        end

        local fixed = math.floor(value * 65536)
        local lo = fixed & 0xFFFF
        local hi = (fixed >> 16) & 0xFFFF

        AvengeComment("load fixed-point constant " .. value)
        Avenge_ldilo(dest, lo)
        Avenge_ldihi(temp, hi)
        Avenge_or(dest, dest, temp)

        node.register = dest
    end
end

handlers.OpConstantComposite = function(words)
    local id = words[1]
    local resultType = words[4]

    local node = GetId(id)
    node.op = "OpConstantComposite"
    node.resultType = resultType
    
    local i = 0
    while words[i+5] do
        local constituent = words[i+5]
        node[i] = constituent
        i = i + 1
    end

    -- generate asm
    local resultTypeNode = GetId(resultType)

    if resultTypeNode.op == "OpTypeStruct" then
        SourceError("OpConstantComposite: Unhandled constant composite type: struct")
    elseif resultTypeNode.op == "OpTypeArray" then
        SourceError("OpConstantComposite: Unhandled constant composite type: array")
    elseif resultTypeNode.op == "OpTypeVector" then
        if i > 4 then
            SourceError("OpConstantComposite: Unhandled constant composite vector size: " .. i)
        end

        local componentCount = resultTypeNode.componentCount
        local componentTypeNode = GetId(resultTypeNode.componentType)

        if componentTypeNode.op == "OpTypeFloat" then
            AvengeComment("load fixed-point vec" .. componentCount .. " constant")

            local dest = AllocateRegister()
            local temp0 = dest + 1;
            local temp1 = dest + 2;

            for i = 0, componentCount - 1 do
                local value = GetId(node[i]).value

                if value >= 65536 then
                    SourceError("OpConstantComposite: Cannot represent " .. value .. " in 16.16 fixed-point format; it's too large")
                end

                local fixed = math.floor(value * 65536)
                local lo = fixed & 0xFFFF
                local hi = (fixed >> 16) & 0xFFFF

                Avenge_ldilo(temp0, lo)
                Avenge_ldihi(temp1, hi)
                Avenge_or(temp0, temp0, temp1)
                Avenge_insert(dest, dest, temp0, i)
            end

            node.register = dest
        elseif componentTypeNode.op == "OpTypeInt" then
            SourceError("OpConstantComposite: Unhandled constant composite type: int vector")
        end
    elseif resultTypeNode.op == "OpTypeMatrix" then
        SourceError("OpConstantComposite: Unhandled constant composite type: matrix")
    end
end

function ComputeSize(id)
    -- id should be from an OpType* opcode

    local node = GetId(id)

    if node.op == "OpTypeInt" then
        return 1
    elseif node.op == "OpTypeFloat" then
        return 1
    elseif node.op == "OpTypeVector" then
        return 4
    elseif node.op == "OpTypeMatrix" then
        return 4 * node.columnCount
    elseif node.op == "OpTypeArray" then
        local lengthNode = GetId(node.length)
        local length = lengthNode.value
        return length * ComputeSize(node.elementType)
    elseif node.op == "OpTypeStruct" then
        local size = 0
        local i = 0
        while node[i] do
            size = size + ComputeSize(node[i])
            i = i + 1
        end
        return size
    end
end

handlers.OpVariable = function(words)
    local id = words[1]
    local resultType = words[4]
    local storageClass = words[5]
    local initializer = words[6]

    local node = GetId(id)
    node.op = "OpVariable"
    node.resultType = resultType
    node.storageClass = storageClass
    node.initializer = initializer

    if initializer then
        -- todo
        SourceError("OpVariable: Initializers not currently supported")
    end

    -- generate asm

    if storageClass == "Input" then
        -- do nothing, OpLoad handles it
    elseif storageClass == "Output" then
        -- do nothing, OpLoad/OpStore handle it
    else
        local resultTypeNode = GetId(resultType)
        local size = ComputeSize(resultTypeNode.type)
        local name = node.alias
        
        local address
        local uniformQualifier

        if storageClass == "UniformConstant" then
            local realName = names[id]
            address = AllocateUniform(realName, size)
            uniformQualifier = "uniform"
        else
            address = AllocateMemory(size)
            uniformQualifier = ""
        end

        local dest = AllocateRegister()
        local temp = dest + 1
        local lo = address & 0xFFFF
        local hi = (address >> 16) & 0xFFFF

        local typeNode = GetId(resultTypeNode.type)
        local typeName = names[resultTypeNode.type] or typeNode.alias

        AvengeComment("load pointer to address " .. string.format("0x%08x: %s a %s %s (%d words)", address, name, uniformQualifier, typeName, size))
        Avenge_ldilo(dest, lo)
        Avenge_ldihi(temp, hi)
        Avenge_or(dest, dest, temp)
        
        node.register = dest
    end
end

handlers.OpAccessChain = function(words)
    local id = words[1]
    local resultType = words[4]
    local base = words[5]

    local node = GetId(id)
    node.op = "OpAccessChain"
    node.resultType = resultType
    node.base = base

    local i = 0
    while words[i+6] do
        local index = words[i+6]
        node[i] = index
        i = i + 1
    end

    if i > 1 then
        SourceError("OpAccessChain: Only one index is supported")
    end

    -- generate asm

    local baseNode = GetId(base)
    local pointerNode = GetId(baseNode.resultType)
    local storageClass = pointerNode.storageClass

    if storageClass == "Input" then
        -- do nothing, OpLoad handles it
    elseif storageClass == "Output" then
        -- do nothing, OpLoad/OpStore handle it
    else
        local typeNode = GetId(pointerNode.type)
        if typeNode.op == "OpTypeArray" then
            SourceError("OpAccessChain: Array type is not supported")
        elseif typeNode.op == "OpTypeMatrix" then
            SourceError("OpAccessChain: Matrix type is not supported")
        elseif typeNode.op == "OpTypeVector" then
            local dest = AllocateRegister()
            local temp = vectorRegister

            local source = baseNode.register
            local name = baseNode.alias

            local indexNode = GetId(node[0])
            local index = indexNode.value

            AvengeComment("access position " .. index .. " of " .. name)
            Avenge_ldilo(temp, index * 4)
            Avenge_add(dest, source, temp)

            node.register = dest
        end
    end
end

handlers.OpLoad = function(words)
    local id = words[1]
    local resultType = words[4]
    local pointer = words[5]
    local memoryAccess = words[6] or "None"

    local node = GetId(id)
    node.op = "OpLoad"
    node.resultType = resultType
    node.pointer = pointer
    node.memoryAccess = memoryAccess

    -- generate asm
    local pointerNode = GetId(pointer)
    local resultTypeNode = GetId(pointerNode.resultType)
    local typeNode = GetId(resultTypeNode.type)

    local name = pointerNode.alias
    local storageClass = pointerNode.storageClass

    if typeNode.op == "OpTypeInt" or typeNode.op == "OpTypeFloat" then
        local dest = AllocateRegister()

        if storageClass == "Input" then
            SourceError("OpLoad: Loading int or float 'in' variables not currently supported")
        elseif storageClass == "Output" then
            SourceError("OpLoad: Loading int or float 'out' variables not currently supported")
        else
            local p = pointerNode.register
            AvengeComment("load variable " .. name)
            Avenge_ld(dest, p, 0)
        end

        node.register = dest
    elseif typeNode.op == "OpTypeVector" then
        local dest = AllocateRegister()

        if storageClass == "Input" then
            local componentCount = typeNode.componentCount
            local temp = dest + 1
            local location = decorations[pointer]["Location"]
            AvengeComment("read 'in' variable " .. name .. " at location " .. location)
            for i = 0, componentCount - 1 do
                Avenge_infifo(temp, location*4 + i)
                Avenge_insert(dest, dest, temp, i)
            end
        elseif storageClass == "Output" then
            location = AllocateOutLocation(realName)
            AvengeComment("read 'out' variable " .. name .. " from shadow register " .. location)
            -- use swizzle as move
            Avenge_swizzle(dest, location, SwizzleByte(0, 1, 2, 3))
        else
            local componentCount = typeNode.componentCount
            local p = pointerNode.register
            local temp = dest + 1
            
            AvengeComment("load variable " .. name)

            for i = 0, componentCount - 1 do
                Avenge_ld(temp, p, i*4)
                Avenge_insert(dest, dest, temp, i)
            end
        end

        node.register = dest
    elseif typeNode.op == "OpTypeMatrix" then
        node.register = vectorRegister

        if storageClass == "Input" then
            SourceError("OpLoad: 'in' variables of type matrix are not supported")
        elseif storageClass == "Output" then
            SourceError("OpLoad: 'out' variables of type matrix are not supported")
        else
            local p = pointerNode.register
            local columnCount = typeNode.columnCount
            local columnTypeNode = GetId(typeNode.columnType)
            local componentCount = columnTypeNode.componentCount

            AvengeComment("load variable " .. name)
            
            for j = 0, columnCount - 1 do
                local dest = AllocateRegister()
                local temp = dest + 1

                for i = 0, componentCount - 1 do
                    local offset = i + j * 4
                    Avenge_ld(temp, p, offset*4)
                    Avenge_insert(dest, dest, temp, i)
                end
            end
        end
    end
end

handlers.OpStore = function(words)
    local pointer = words[2]
    local object = words[3]
    local memoryAccess = words[4] or "None"

    -- generate asm
    local pointerNode = GetId(pointer)
    local objectNode = GetId(object)
    
    local resultTypeNode = GetId(pointerNode.resultType)
    local typeNode = GetId(resultTypeNode.type)

    local name = objectNode.alias
    local storageClass = resultTypeNode.storageClass

    if typeNode.op == "OpTypeInt" or typeNode.op == "OpTypeFloat" then
        if storageClass == "Input" then
            SourceError("OpStore: Storing to an 'in' variable not supported")
        elseif storageClass == "Output" then
            local realName = names[pointer]
            location = AllocateOutLocation(realName)
            
            local source = objectNode.register
            local temp = vectorRegister

            AvengeComment("write variable " .. name .. " to shadow output location " .. location)
            Avenge_insert(location, location, source, 0) -- the source should already be in lane 0
        else
            local p = pointerNode.register
            local source = objectNode.register

            AvengeComment("store variable " .. name)
            Avenge_st(0, p, source)
        end
    elseif typeNode.op == "OpTypeVector" then
        if storageClass == "Input" then
            SourceError("OpStore: Storing to an 'in' variable not supported")
        elseif storageClass == "Output" then
            local location = -1

            if pointerNode.base then
                local baseNode = GetId(pointerNode.base)
                local baseResultTypeNode = GetId(baseNode.resultType)
                if names[baseResultTypeNode.type] == "gl_PerVertex" then
                    location = 0
                end
            end

            if location == -1 then
                local realName = names[pointer]
                location = AllocateOutLocation(realName)
            end
            
            local source = objectNode.register

            AvengeComment("write variable " .. name .. " to shadow output location " .. location)
            Avenge_swizzle(location, source, SwizzleByte(0, 1, 2, 3))
        else
            local p = pointerNode.register
            local componentCount = typeNode.componentCount
            local source = objectNode.register
            local temp = vectorRegister
            
            AvengeComment("store variable " .. name)
            for i = 0, componentCount - 1 do
                Avenge_swizzle(temp, source, SwizzleByte(i, i, i, i))
                Avenge_st(i*4, p, temp)
            end
        end
    elseif typeNode.op == "OpTypeMatrix" then
        if storageClass == "Input" then
            SourceError("OpStore: Storing to an 'in' variable not supported")
        elseif storageClass == "Output" then
            SourceError("OpStore: Storing a matrix to an 'out' variable not supported")
        else
            local p = pointerNode.register
            local columnCount = typeNode.columnCount
            local columnTypeNode = GetId(typeNode.columnType)
            local componentCount = columnTypeNode.componentCount

            AvengeComment("store variable " .. name)
            for j = 0, columnCount - 1 do
                local source = objectNode.register + j
                local temp = vectorRegister

                for i = 0, componentCount - 1 do
                    local offset = i + j * 4
                    Avenge_swizzle(temp, source, SwizzleByte(i, i, i, i))
                    Avenge_st(offset*4, p, temp)
                end
            end
        end
    end
end

handlers.OpCompositeExtract = function(words)
    local id = words[1]
    local resultType = words[4]
    local composite = words[5]

    local node = GetId(id)
    node.op = "OpCompositeExtract"
    node.resultType = resultType
    node.composite = composite

    local i = 0
    while words[i+6] do
        local index = tonumber(words[i+6])
        node[i] = index
        i = i + 1
    end

    if i > 1 then
        SourceError("OpCompositeExtract: Can only handle one index")
    end

    -- generate asm
    local compositeNode = GetId(composite)
    local source = compositeNode.register
    local dest = AllocateRegister()
    local i = node[0]

    AvengeComment("extract element from composite")
    Avenge_swizzle(dest, source, SwizzleByte(i, i, i, i))

    node.register = dest
end

handlers.OpCompositeConstruct = function(words)
    local id = words[1]
    local resultType = words[4]

    local node = GetId(id)
    node.op = "OpCompositeConstruct"
    node.resultType = resultType

    local i = 0
    while words[i+5] do
        local constituent = words[i+5]
        node[i] = constituent
        i = i + 1
    end

    -- generate asm
    local resultTypeNode = GetId(resultType)
    
    if resultTypeNode.op == "OpTypeVector" then
        local dest = AllocateRegister()

        AvengeComment("construct composite vector from elements")
        for j = 0, i - 1 do
            local sourceNode = GetId(node[j])
            local source = sourceNode.register
            Avenge_insert(dest, dest, source, j)
        end
        
        node.register = dest
    elseif resultTypeNode.op == "OpTypeMatrix" then
        node.register = vectorRegister

        AvengeComment("construct composite matrix from vectors")
        for j = 0, i - 1 do
            local sourceNode = GetId(node[j])
            local dest = AllocateRegister()
            local source = sourceNode.register
            -- use swizzle as a move instruction
            Avenge_swizzle(dest, source, SwizzleByte(0, 1, 2, 3))
        end
    elseif resultTypeNode.op == "OpTypeArray" then
        SourceError("OpCompositeConstruct: Array type not supported")
    elseif resultTypeNode.op == "OpTypeStruct" then
        SourceError("OpCompositeConstruct: Struct type not supported")
    end
end

handlers.OpVectorTimesScalar = function(words)
    local id = words[1]
    local resultType = words[4]
    local vector = words[5]
    local scalar = words[6]

    local node = GetId(id)
    node.op = "OpVectorTimesScalar"
    node.resultType = resultType
    node.vector = vector
    node.scalar = scalar

    -- generate asm
    local vectorNode = GetId(vector)
    local vectorSource = vectorNode.register

    local scalarNode = GetId(scalar)
    local scalarSource = scalarNode.register

    local dest = AllocateRegister()

    AvengeComment("multiply vector times scalar")
    Avenge_swizzle(dest, scalarSource, SwizzleByte(0, 0, 0, 0))
    Avenge_fmul(dest, dest, vectorSource)

    node.register = dest
end

handlers.OpMatrixTimesVector = function(words)
    local id = words[1]
    local resultType = words[4]
    local matrix = words[5]
    local vector = words[6]

    local node = GetId(id)
    node.op = "OpMatrixTimesVector"
    node.resultType = resultType
    node.matrix = matrix
    node.vector = vector

    -- generate asm
    local matrixNode = GetId(matrix)
    local matrixSourceRegister = matrixNode.register
    local matrixTypeNode = GetId(matrixNode.resultType)
    local columnCount = matrixTypeNode.columnCount

    local vectorNode = GetId(vector)
    local vectorSource = vectorNode.register

    local dest = AllocateRegister()
    local temp = dest + 1

    AvengeComment("multiply matrix times vector")
    Avenge_ldilo(dest, 0)
    
    for i = 0, columnCount - 1 do
        local matrixSource = matrixSourceRegister + i
        
        Avenge_swizzle(temp, vectorSource, SwizzleByte(i, i, i, i))
        Avenge_fmul(temp, temp, matrixSource)
        Avenge_fadd(dest, dest, temp)
    end

    node.register = dest
end

handlers.OpMatrixTimesMatrix = function(words)
    local id = words[1]
    local resultType = words[4]
    local leftMatrix = words[5]
    local rightMatrix = words[6]

    local node = GetId(id)
    node.op = "OpMatrixTimesMatrix"
    node.resultType = resultType
    node.leftMatrix = leftMatrix
    node.rightMatrix = rightMatrix

    -- generate asm
    -- ASSUMES SQUARE MATRICES

    local leftMatrixNode = GetId(leftMatrix)
    local leftMatrixSource = leftMatrixNode.register
    local leftMatrixTypeNode = GetId(leftMatrixNode.resultType)
    local columnCount = leftMatrixTypeNode.columnCount

    local rightMatrixNode = GetId(rightMatrix)
    local rightMatrixSource = rightMatrixNode.register

    AvengeComment("multiply matrix times matrix")

    node.register = vectorRegister

    for j = 0, columnCount - 1 do
        local dest = AllocateRegister()
        local temp = dest + 1

        local rightSource = rightMatrixSource + j

        Avenge_ldilo(dest, 0)

        for i = 0, columnCount - 1 do
            local leftSource = leftMatrixSource + i

            Avenge_swizzle(temp, rightSource, SwizzleByte(i, i, i, i))
            Avenge_fmul(temp, temp, leftSource)
            Avenge_fadd(dest, dest, temp)
        end
    end
end

handlers.OpTranspose = function(words)
    local id = words[1]
    local resultType = words[4]
    local matrix = words[5]

    local node = GetId(id)
    node.op = "OpTranspose"
    node.resultType = resultType
    node.matrix = matrix

    -- generate asm
    local matrixNode = GetId(matrix)
    local sourceRegister = matrixNode.register
    local typeNode = GetId(matrixNode.resultType)
    local columnCount = typeNode.columnCount

    if columnCount == 2 then
        SourceError("OpTranspose: Cannot handle 2x2 matrices")
    elseif columnCount == 3 then
        local dest0 = AllocateRegister(3)
        local dest1 = dest0 + 1
        local dest2 = dest0 + 2

        local source0 = sourceRegister
        local source1 = sourceRegister + 1
        local source2 = sourceRegister + 2
        local source3 = sourceRegister + 3

        local temp0 = vectorRegister
        local temp1 = vectorRegister + 1
        local temp2 = vectorRegister + 2
        local temp3 = vectorRegister + 3

        AvengeComment("matrix transpose 3x3")
        Avenge_interleavelo(temp0, source0, source1)
        Avenge_interleavehi(temp1, source0, source1)
        Avenge_interleavelo(temp2, source2, source3)
        Avenge_interleavehi(temp3, source2, source3)
        Avenge_interleavelopairs(dest0, temp0, temp2)
        Avenge_interleavehipairs(dest1, temp0, temp2)
        Avenge_interleavelopairs(dest2, temp1, temp3)

        node.register = dest0
    elseif columnCount == 4 then
        local dest0 = AllocateRegister(4)
        local dest1 = dest0 + 1
        local dest2 = dest0 + 2
        local dest3 = dest0 + 3

        local source0 = sourceRegister
        local source1 = sourceRegister + 1
        local source2 = sourceRegister + 2
        local source3 = sourceRegister + 3

        local temp0 = vectorRegister
        local temp1 = vectorRegister + 1
        local temp2 = vectorRegister + 2
        local temp3 = vectorRegister + 3

        AvengeComment("matrix transpose 4x4")
        Avenge_interleavelo(temp0, source0, source1)
        Avenge_interleavehi(temp1, source0, source1)
        Avenge_interleavelo(temp2, source2, source3)
        Avenge_interleavehi(temp3, source2, source3)
        Avenge_interleavelopairs(dest0, temp0, temp2)
        Avenge_interleavehipairs(dest1, temp0, temp2)
        Avenge_interleavelopairs(dest2, temp1, temp3)
        Avenge_interleavehipairs(dest3, temp1, temp3)

        node.register = dest
    end
end

function GenericRegisterOp(words, op, comment, instruction)
    local id = words[1]
    local resultType = words[4]
    local operand1 = words[5]
    local operand2 = words[6]

    local node = GetId(id)
    node.op = op
    node.resultType = resultType
    node.operand1 = operand1
    node.operand2 = operand2

    -- generate asm
    local operand1Node = GetId(operand1)
    local operand1Source = operand1Node.register

    local operand2Node = GetId(operand2)
    local operand2Source = operand2Node.register
    
    local dest = AllocateRegister()

    AvengeComment(comment)
    instruction(dest, operand1Source, operand2Source)
    
    node.register = dest
end

handlers.OpFAdd = function(words)
    GenericRegisterOp(words, "OpFAdd", "fixed-point add", Avenge_fadd)
end

handlers.OpFSub = function(words)
    GenericRegisterOp(words, "OpFSub", "fixed-point subtract", Avenge_fsub)
end

handlers.OpFMul = function(words)
    GenericRegisterOp(words, "OpFMul", "fixed-point multiply", Avenge_fmul)
end

handlers.OpFDiv = function(words)
    GenericRegisterOp(words, "OpFDiv", "fixed-point divide", Avenge_fdiv)
end

handlers.OpFNegate = function(words)
    local id = words[1]
    local resultType = words[4]
    local operand = words[5]

    local node = GetId(id)
    node.op = "OpFNegate"
    node.resultType = resultType
    node.operand = operand

    -- generate asm
    local operandNode = GetId(operand)
    local operandSource = operandNode.register

    local dest = AllocateRegister()

    AvengeComment("fixed-point negate")
    Avenge_fneg(dest, operandSource)

    node.register = dest
end

handlers.OpVectorShuffle = function(words)
    local id = words[1]
    local resultType = words[4]
    local vector1 = words[5]
    local vector2 = words[6]

    local node = GetId(id)
    node.op = "OpVectorShuffle"
    node.resultType = resultType
    node.vector1 = vector1
    node.vector2 = vector2

    local i = 0
    while words[i+7] do
        local component = tonumber(words[i+7])
        node[i] = component
        i = i + 1
    end

    if vector1 ~= vector2 then
        SourceError("OpVectorShuffle: Can not currently shuffle across two vectors")
    end

    -- generate asm
    local vector1Node = GetId(vector1)
    local source = vector1Node.register
    
    local dest = AllocateRegister()

    AvengeComment("vector shuffle (swizzle)")
    Avenge_swizzle(dest, source, SwizzleByte(node[0] or 0, node[1] or 0, node[2] or 0, node[3] or 0))

    node.register = dest
end

handlers.OpDot = function(words)
    local id = words[1]
    local resultType = words[4]
    local vector1 = words[5]
    local vector2 = words[6]

    local node = GetId(id)
    node.op = "OpDot"
    node.resultType = resultType
    node.vector1 = vector1
    node.vector2 = vector2

    -- generate asm
    local vector1Node = GetId(vector1)
    local vector1Source = vector1Node.register

    local vector2Node = GetId(vector2)
    local vector2Source = vector2Node.register
    
    local dest = AllocateRegister()
    local temp = dest + 1

    local componentCountNode = GetId(vector1Node.resultType)
    local componentCount = componentCountNode.componentCount

    AvengeComment("" .. componentCount .. "-component dot product (fixed-point)")
    Avenge_fmul(dest, vector1Source, vector2Source)

    for i = 1, componentCount - 1 do
        Avenge_swizzle(temp, dest, SwizzleByte(i, i, i, i))
        Avenge_fadd(dest, dest, temp)
    end
    
    node.register = dest
end

handlers.OpExtInst = function(words)
    local id = words[1]
    local resultType = words[4]
    local set = words[5]
    local instruction = words[6]

    local node = GetId(id)
    node.op = "OpExtInst"
    node.resultType = resultType
    node.set = set
    node.instruction = instruction

    local i = 0
    while words[i+7] do
        local operand = words[i+7]
        node[i] = operand
        i = i + 1
    end

    if instruction == "Normalize" then
        local operandNode = GetId(node[0])
        local operandResultTypeNode = GetId(operandNode.resultType)
        local componentCount = operandResultTypeNode.componentCount
        local source = operandNode.register
        
        local dest = AllocateRegister()
        local temp = dest + 1

        AvengeComment("normalize vector")
        Avenge_fmul(dest, source, source)

        for i = 1, componentCount - 1 do
            Avenge_swizzle(temp, dest, SwizzleByte(i, i, i, i))
            Avenge_fadd(dest, dest, temp)
        end

        Avenge_swizzle(dest, dest, 0)
        Avenge_fsqrt(dest, dest)
        Avenge_fdiv(dest, source, dest)

        node.register = dest
    elseif instruction == "FMax" then
        local operand1Node = GetId(node[0])
        local operand2Node = GetId(node[1])

        local source1 = operand1Node.register
        local source2 = operand2Node.register

        local dest = AllocateRegister()

        AvengeComment("fixed-point maximum")
        Avenge_fmax(dest, source1, source2)

        node.register = dest
    elseif instruction == "Pow" then
        local operand1Node = GetId(node[0])
        local operand2Node = GetId(node[1])

        local source1 = operand1Node.register
        local source2 = operand2Node.register

        local dest = AllocateRegister()

        AvengeComment("fixed-point pow (a^b)")
        Avenge_fpow(dest, source1, source2)

        node.register = dest
    end
end


for i = 1, #sourceLines do
    lineNumber = i
    local line = sourceLines[i]
    local words = {}
    for word in line:gmatch("%S+") do
        table.insert(words, word)
    end

    if words[1]:sub(1, 1) == ";" then
        -- it's a comment, I guess
    elseif words[1]:sub(1, 1) == "%" then
        -- handle assignment ops (of the form %whatever = OpWhatever ...)
        local t = words[3]:match("OpType(.+)")
        if t then
            handlers.OpType(words, t)
        else
            if handlers[words[3]] then
                handlers[words[3]](words)
            else
                SourceError("spv_to_sgp: " .. words[3] .. " not currently supported")
            end
        end
    else
        -- handle non-assignment ops
        if handlers[words[1]] then
            handlers[words[1]](words)
        else
            SourceError("spv_to_sgp: " .. words[1] .. " not currently supported")
        end
    end
end

AvengeComment("write the outfifo shadow registers")
Avenge_outfifo(0, 0)
Avenge_swizzle(5, 0, SwizzleByte(1, 1, 1, 1))
Avenge_outfifo(1, 5)
Avenge_swizzle(5, 0, SwizzleByte(2, 2, 2, 2))
Avenge_outfifo(2, 5)
Avenge_swizzle(5, 0, SwizzleByte(3, 3, 3, 3))
Avenge_outfifo(3, 5)

Avenge_outfifo(4, 1)
Avenge_swizzle(5, 1, SwizzleByte(1, 1, 1, 1))
Avenge_outfifo(5, 5)
Avenge_swizzle(5, 1, SwizzleByte(2, 2, 2, 2))
Avenge_outfifo(6, 5)
Avenge_swizzle(5, 1, SwizzleByte(3, 3, 3, 3))
Avenge_outfifo(7, 5)

Avenge_outfifo(8, 2)
Avenge_swizzle(5, 2, SwizzleByte(1, 1, 1, 1))
Avenge_outfifo(9, 5)
Avenge_swizzle(5, 2, SwizzleByte(2, 2, 2, 2))
Avenge_outfifo(10, 5)
Avenge_swizzle(5, 2, SwizzleByte(3, 3, 3, 3))
Avenge_outfifo(11, 5)

Avenge_outfifo(12, 3)
Avenge_swizzle(5, 3, SwizzleByte(1, 1, 1, 1))
Avenge_outfifo(13, 5)
Avenge_swizzle(5, 3, SwizzleByte(2, 2, 2, 2))
Avenge_outfifo(14, 5)
Avenge_swizzle(5, 3, SwizzleByte(3, 3, 3, 3))
Avenge_outfifo(15, 5)

AvengeComment("end the program")
Avenge_done()


-- start precan

-- binary = {}
-- assembly = {}
-- 
-- Avenge_infifo(0x0, 0x0)
-- Avenge_infifo(0x1, 0x1)
-- Avenge_infifo(0x2, 0x2)
-- Avenge_infifo(0x3, 0x3)
-- Avenge_infifo(0x4, 0x4)
-- Avenge_infifo(0x5, 0x5)
-- Avenge_infifo(0x6, 0x6)
-- Avenge_infifo(0x7, 0x7)
-- Avenge_infifo(0x8, 0x8)
-- Avenge_infifo(0x9, 0x9)
-- Avenge_infifo(0xA, 0xA)
-- Avenge_infifo(0xB, 0xB)
-- Avenge_infifo(0xC, 0xC)
-- Avenge_infifo(0xD, 0xD)
-- Avenge_infifo(0xE, 0xE)
-- Avenge_infifo(0xF, 0xF)
-- 
-- Avenge_outfifo(0x0, 0x0)
-- Avenge_outfifo(0x1, 0x1)
-- Avenge_outfifo(0x2, 0x2)
-- Avenge_outfifo(0x3, 0x3)
-- Avenge_outfifo(0x4, 0x4)
-- Avenge_outfifo(0x5, 0x5)
-- Avenge_outfifo(0x6, 0x6)
-- Avenge_outfifo(0x7, 0x7)
-- Avenge_outfifo(0x8, 0x8)
-- Avenge_outfifo(0x9, 0x9)
-- Avenge_outfifo(0xA, 0xA)
-- Avenge_outfifo(0xB, 0xB)
-- Avenge_outfifo(0xC, 0xC)
-- Avenge_outfifo(0xD, 0xD)
-- Avenge_outfifo(0xE, 0xE)
-- Avenge_outfifo(0xF, 0xF)
-- 
-- Avenge_done()

-- end precan


binary = table.concat(binary)
assemblyText = table.concat(assembly)


-- debug stuff

-- print(assemblyText)

-- f = io.open(arg[1] .. ".bin", "wb")
-- f:write(binary)
-- io.close(f)


-- for i = 1, #outs do
--     print(string.format("%s @ location %d", outs[i].name, outs[i].location))
-- end

-- for i = 1, #uniforms do
--     print(string.format("%s @ location %d, %d bytes", uniforms[i].name, uniforms[i].location, uniforms[i].size))
-- end
