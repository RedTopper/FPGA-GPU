-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- sgp_types.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains some enumerated data and
-- type declarations for the graphics pipeline. 
--
-- NOTES:
-- 12/06/20 by JAZ::Design created.
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- SGP pipeline configuration information

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.all;

package sgp_types is

	subtype primtype_t is integer range 0 to 15;

	-- OpenGL primitive types. Needs to be consistent with driver
	constant SGP_GL_POINTS				: primtype_t := 0;
	constant SGP_GL_LINES				: primtype_t := 1;
	constant SGP_GL_LINE_LOOP			: primtype_t := 2;
	constant SGP_GL_LINE_STRIP			: primtype_t := 3;
	constant SGP_GL_TRIANGLES			: primtype_t := 4;
	constant SGP_GL_TRIANGLE_STRIP		: primtype_t := 5;
	constant SGP_GL_TRIANGLE_FAN		: primtype_t := 6;	

    -- Basic vertex attribute structures
    -- Constant limit of 4 attributes per vertex, 4 dimensions per attribute
    constant C_SGP_NUM_VERTEX_ATTRIB    : integer := 4;
    constant C_SGP_VERTEX_ATTRIB_SIZE   : integer := 4;

    -- Q16.16 fixed-point data type
    constant C_SGP_INTEGER_BITS         : integer := 16;
    constant C_SGP_FIXED_BITS           : integer := 16;
    subtype fixed_t is signed(C_SGP_INTEGER_BITS+C_SGP_FIXED_BITS-1 downto 0);
    constant fixed_t_zero : fixed_t := (others => '0');    
    constant fixed_t_one  : fixed_t  := x"00010000";
    
    -- Q32.32 for wide fixed-point data (e.g. for after multiplication)
    subtype wfixed_t is signed((fixed_t'length*2)-1 downto 0);
    constant wfixed_t_zero : wfixed_t := (others => '0');
    
    -- Q64.64 for very wide fixed-point data
    subtype wwfixed_t is signed((fixed_t'length*4)-1 downto 0);
    constant wwfixed_t_zero : wwfixed_t := (others => '0');

    function wfixed_t_to_fixed_t (i_wfixed : in wfixed_t) return fixed_t;
    function fixed_t_to_wfixed_t (i_fixed : in fixed_t) return wfixed_t;
    function wwfixed_t_to_wfixed_t (i_wwfixed : in wwfixed_t) return wfixed_t;
    function wwfixed_t_to_fixed_t (i_wwfixed : in wwfixed_t) return fixed_t;


    -- These types are equivalent in terms of total bits / storage, use whatever is most
    -- convenient and apply conversion functions (which will not infer any logic)
    subtype attributeVector_t is signed((C_SGP_VERTEX_ATTRIB_SIZE*fixed_t'length)-1 downto 0);
    constant attributeVector_t_zero : attributeVector_t := (others => '0');

    type attributeArray_t is array (C_SGP_VERTEX_ATTRIB_SIZE-1 downto 0) of fixed_t;
    constant attributeArray_t_zero : attributeArray_t := (others => fixed_t_zero);

    type attributeRecord_t is 
        record
            x : fixed_t;  -- Dimension 0 (e.g 'x')
            y : fixed_t;  -- Dimension 1 (e.g. 'y')
            z : fixed_t;  -- Dimension 2 (e.g. 'z')
            w : fixed_t;  -- Dimension 3 (e.g. 'w')
        end record;
    constant attributeRecord_t_zero : attributeRecord_t := (x => fixed_t_zero, y => fixed_t_zero, z => fixed_t_zero, w => fixed_t_zero);

    function to_attributeVector_t (i_attributeArray : in attributeArray_t) return attributeVector_t;
    function to_attributeVector_t (i_attributeRecord : in attributeRecord_t) return attributeVector_t;
    function to_attributeArray_t (i_attributeVector : in attributeVector_t) return attributeArray_t;
    function to_attributeArray_t (i_attributeRecord : in attributeRecord_t) return attributeArray_t;
    function to_attributeRecord_t (i_attributeVector : in attributeVector_t) return attributeRecord_t;
    function to_attributeRecord_t (i_attributeArray : in attributeArray_t) return attributeRecord_t;


    subtype vertexVector_t is signed((C_SGP_NUM_VERTEX_ATTRIB*attributeVector_t'length)-1 downto 0);
    constant vertexVector_t_zero : vertexVector_t := (others => '0');

    type vertexArray_t is array (C_SGP_NUM_VERTEX_ATTRIB-1 downto 0) of attributeArray_t;
    constant vertexArray_t_zero : vertexArray_t := (others => attributeArray_t_zero);

    type vertexRecord_t is
        record
            att0 : attributeRecord_t;  -- Attribute 0 (e.g. 'position')
            att1 : attributeRecord_t;  -- Attribute 1 (e.g. 'color')
            att2 : attributeRecord_t;  -- Attribute 2 (e.g. 'normal')
            att3 : attributeRecord_t;  -- Attribute 3 (e.g. 'texCoord')
        end record;
    constant vertexRecord_t_zero : vertexRecord_t := (att0 => attributeRecord_t_zero, att1 => attributeRecord_t_zero, att2 => attributeRecord_t_zero, att3 => attributeRecord_t_zero);

    function to_vertexVector_t (i_vertexArray : in vertexArray_t) return vertexVector_t;
    function to_vertexVector_t (i_vertexRecord : in vertexRecord_t) return vertexVector_t;
    function to_vertexArray_t (i_vertexVector : in vertexVector_t) return vertexArray_t;
    function to_vertexArray_t (i_vertexRecord : in vertexRecord_t) return vertexArray_t;
    function to_vertexRecord_t (i_vertexVector : in vertexVector_t) return vertexRecord_t;
    function to_vertexRecord_t (i_vertexArray : in vertexArray_t) return vertexRecord_t;

    -- Triangle data type. There is less need for any conversion function(s) for this
    type triangleArray_t is array(2 downto 0) of vertexVector_t;
    constant triangleArray_t_zero : triangleArray_t := (others => vertexVector_t_zero);

    -- Bounding box data type. Helpful for cleaning up the interfaces
    type boundingboxRecord_t is
        record
            xmin : fixed_t;  -- Leftmost vertex x-pos
            xmax : fixed_t;  -- Rightmost vertex x-pos
            ymin : fixed_t;  -- Topmost vertex y-pos (top and bottom can flip after viewPort)
            ymax : fixed_t;  -- Bottommost vertex x-pos
        end record;
    constant boundingboxRecord_t_zero : boundingboxRecord_t := (xmin => fixed_t_zero, xmax => fixed_t_zero, ymin => fixed_t_zero, ymax => fixed_t_zero);
   
	-- Triangle traversal commands
	type traversal_cmds_t is (CMD_NONE, START_CMD, POP_MOVE_LEFT_CMD, POP_MOVE_RIGHT_CMD,  MOVE_RIGHT_CMD, MOVE_LEFT_CMD, PUSH_MOVE_DOWN_CMD, DONE_CMD, NO_MOVE, PUSH_MOVE_RIGHT_CMD, PUSH_MOVE_LEFT_CMD);
	
	-- It's easy to forget which is clockwise, which is counter-clockwise. Same for in/out tests, directions, etc. Could also create enumerated types 
	constant direction_cw   : std_logic    := '1';
	constant direction_ccw  : std_logic    := '0';	
    constant testresult_in  : std_logic    := '1';
    constant testresult_out : std_logic    := '0';
    constant direction_left  : std_logic   := '0';
    constant direction_right : std_logic   := '1';
	constant status_idle     : std_logic   := '0';
	constant status_busy     : std_logic   := '1';
	
	
end sgp_types;


package body sgp_types is
 
    -- Helper function: truncates 32.32 value to 16.16
    function wfixed_t_to_fixed_t (i_wfixed : in wfixed_t) return fixed_t is
    begin
        return (i_wfixed(47 downto 16));
    end;

    -- Helper function: expands 16.16 value to 32.32
    function fixed_t_to_wfixed_t (i_fixed : in fixed_t) return wfixed_t is
    variable tmpValue : wfixed_t;
    begin
        for i in 63 downto 48 loop
            tmpValue(i) := i_fixed(31);        
        end loop;
        tmpValue(47 downto 0) := i_fixed & x"0000";
        return (tmpValue);
    end;

    -- Helper function: truncates 64.64 value to 32.32
    function wwfixed_t_to_wfixed_t (i_wwfixed : in wwfixed_t) return wfixed_t is
    variable tmpValue : wfixed_t;
    begin
        tmpValue := i_wwfixed(95 downto 32);
        return (tmpValue);
    end;

    -- Helper function: truncates 64.64 value to 16.16
    function wwfixed_t_to_fixed_t (i_wwfixed : in wwfixed_t) return fixed_t is
    variable tmpValue : fixed_t; 
    begin
        tmpValue := i_wwfixed(79 downto 48);
        return (tmpValue);
    end;
 
    -- Helper function: converts an attribute array to a vector
    function to_attributeVector_t (i_attributeArray : in attributeArray_t) return attributeVector_t is 
    variable tmpVector : attributeVector_t;
    begin
        for i in C_SGP_VERTEX_ATTRIB_SIZE-1 downto 0 loop
            tmpVector((fixed_t'length*(i+1))-1 downto (fixed_t'length*i)) := i_attributeArray(i);
        end loop;    
        return tmpVector;
    end;

    -- Helper function: converts an attribute record to a vector
    function to_attributeVector_t (i_attributeRecord : in attributeRecord_t) return attributeVector_t is 
    variable tmpVector : attributeVector_t;
    begin
        tmpVector((fixed_t'length*(4))-1 downto (fixed_t'length*3)) := i_attributeRecord.w;
        tmpVector((fixed_t'length*(3))-1 downto (fixed_t'length*2)) := i_attributeRecord.z;
        tmpVector((fixed_t'length*(2))-1 downto (fixed_t'length*1)) := i_attributeRecord.y;
        tmpVector((fixed_t'length*(1))-1 downto (fixed_t'length*0)) := i_attributeRecord.x;        
        return tmpVector;
    end;

    -- Helper function: converts an attribute vector to an array
    function to_attributeArray_t (i_attributeVector : in attributeVector_t) return attributeArray_t is 
    variable tmpArray : attributeArray_t;
    begin
        for i in C_SGP_VERTEX_ATTRIB_SIZE-1 downto 0 loop
            tmpArray(i) := i_attributeVector((fixed_t'length*(i+1))-1 downto (fixed_t'length*i));
        end loop;    
        return tmpArray;
    end;

    -- Helper function: converts an attribute record to an array
    function to_attributeArray_t (i_attributeRecord : in attributeRecord_t) return attributeArray_t is 
    variable tmpArray : attributeArray_t;
    begin
        tmpArray(3) := i_attributeRecord.w;
        tmpArray(2) := i_attributeRecord.z;
        tmpArray(1) := i_attributeRecord.y;
        tmpArray(0) := i_attributeRecord.x;
        return tmpArray;
    end;

    -- Helper function: converts an attribute vector to a record
    function to_attributeRecord_t (i_attributeVector : in attributeVector_t) return attributeRecord_t is 
    variable tmpRecord : attributeRecord_t;
    begin
        tmpRecord.w := i_attributeVector((fixed_t'length*(4))-1 downto (fixed_t'length*3));
        tmpRecord.z := i_attributeVector((fixed_t'length*(3))-1 downto (fixed_t'length*2));
        tmpRecord.y := i_attributeVector((fixed_t'length*(2))-1 downto (fixed_t'length*1));
        tmpRecord.x := i_attributeVector((fixed_t'length*(1))-1 downto (fixed_t'length*0));
        return tmpRecord;
    end;

    -- Helper function: converts an attribute array to a record
    function to_attributeRecord_t (i_attributeArray : in attributeArray_t) return attributeRecord_t is 
    variable tmpRecord : attributeRecord_t;
    begin
        tmpRecord.w := i_attributeArray(3);
        tmpRecord.z := i_attributeArray(2);
        tmpRecord.y := i_attributeArray(1);
        tmpRecord.x := i_attributeArray(0);
        return tmpRecord;
    end;

    -- Helper function: converts a vertex array to a vector
    function to_vertexVector_t (i_vertexArray : in vertexArray_t) return vertexVector_t is 
    variable tmpVector : vertexVector_t;
    begin
        for i in C_SGP_NUM_VERTEX_ATTRIB-1 downto 0 loop
            tmpVector((attributeVector_t'length*(i+1))-1 downto (attributeVector_t'length*i)) := to_attributeVector_t(i_vertexArray(i));
        end loop;            
        return tmpVector;
    end;

    -- Helper function: converts a vertex record to a vector    
    function to_vertexVector_t (i_vertexRecord : in vertexRecord_t) return vertexVector_t is 
    variable tmpVector : vertexVector_t;
    begin
        tmpVector((attributeVector_t'length*(4))-1 downto (attributeVector_t'length*3)) := to_attributeVector_t(i_vertexRecord.att3);        
        tmpVector((attributeVector_t'length*(3))-1 downto (attributeVector_t'length*2)) := to_attributeVector_t(i_vertexRecord.att2);        
        tmpVector((attributeVector_t'length*(2))-1 downto (attributeVector_t'length*1)) := to_attributeVector_t(i_vertexRecord.att1);        
        tmpVector((attributeVector_t'length*(1))-1 downto (attributeVector_t'length*0)) := to_attributeVector_t(i_vertexRecord.att0);        
        return tmpVector;
    end;

    -- Helper function: converts a vertex vector to an array    
    function to_vertexArray_t (i_vertexVector : in vertexVector_t) return vertexArray_t is 
    variable tmpArray : vertexArray_t;
    begin
        for i in C_SGP_NUM_VERTEX_ATTRIB-1 downto 0 loop
            tmpArray(i) := to_attributeArray_t(i_vertexVector((attributeVector_t'length*(i+1))-1 downto (attributeVector_t'length*i)));
        end loop;            
        return tmpArray;
    end;

    -- Helper function: converts a vertex record to an array            
    function to_vertexArray_t (i_vertexRecord : in vertexRecord_t) return vertexArray_t is 
    variable tmpArray : vertexArray_t;
    begin
        tmpArray(3) := to_attributeArray_t(i_vertexRecord.att3);
        tmpArray(2) := to_attributeArray_t(i_vertexRecord.att2);
        tmpArray(1) := to_attributeArray_t(i_vertexRecord.att1);
        tmpArray(0) := to_attributeArray_t(i_vertexRecord.att0);
        return tmpArray;
    end;
 
     -- Helper function: converts a vertex vector to a record       
    function to_vertexRecord_t (i_vertexVector : in vertexVector_t) return vertexRecord_t is 
    variable tmpRecord : vertexRecord_t;
    begin
        tmpRecord.att3 := to_attributeRecord_t(i_vertexVector((attributeVector_t'length*(4))-1 downto (attributeVector_t'length*3)));
        tmpRecord.att2 := to_attributeRecord_t(i_vertexVector((attributeVector_t'length*(3))-1 downto (attributeVector_t'length*2)));
        tmpRecord.att1 := to_attributeRecord_t(i_vertexVector((attributeVector_t'length*(2))-1 downto (attributeVector_t'length*1)));
        tmpRecord.att0 := to_attributeRecord_t(i_vertexVector((attributeVector_t'length*(1))-1 downto (attributeVector_t'length*0)));
        return tmpRecord;
    end;

     -- Helper function: converts a vertex array to a record           
    function to_vertexRecord_t (i_vertexArray : in vertexArray_t) return vertexRecord_t is 
    variable tmpRecord : vertexRecord_t;
    begin
        tmpRecord.att3 := to_attributeRecord_t(i_vertexArray(3));
        tmpRecord.att2 := to_attributeRecord_t(i_vertexArray(2));
        tmpRecord.att1 := to_attributeRecord_t(i_vertexArray(1));
        tmpRecord.att0 := to_attributeRecord_t(i_vertexArray(0));
        return tmpRecord;
    end;
 
end package body sgp_types;