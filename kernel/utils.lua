local dir = require("pl.dir")-- This file defines 

-- table.show, table.invert, table.flatten_to_functions_array
-- read_file(path), write_file(path,data)
-- deepcopy(object)

function read_file(filename)
	--Returns nil if data is missing, otherwise returns a string
	local inp = io.open(filename, "rb")
	if (inp == nil) then 
		return nil
	else
  	local data = inp:read("*all")
	  assert(inp:close())
		return data
	end 
end
function write_file(filename, data)
	--Saves the specified string data 
	dir.makepath(path.getparent(filename))
	local out = assert(io.open(filename, "wb"))
	out:write(data)
	assert(out:close())
end



--This function returns a deep copy of a given table. The function below also copies the metatable to the new table 
-- if there is one, so the behaviour of the copied table is the same as the original. But the 2 tables share the 
-- same metatable, you can avoid this by changing this 'getmetatable(object)' to '_copy( getmetatable(object) )'.
function deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end


if path == nil then path = {} end

function path.slash()
	return "/"
end

function path.getparent(filename)
	return filename:gsub("[/\\]([^\/\\]-)[/\\]?$","",1)
end
function path.join(...)
  local s = path.slash()
  local p = ""
  for _, v in ipairs({...}) do
    if (#p == 0) then 
      p = v
    else
      p = p:gsub(path.slash() .."$","") .. s .. v:gsub("^" ..path.slash(),"")
    end
  end
  return p
end

-- Flattens nested tables into a single array of values, dropping any values present in the excluded_values dict.
-- Calls 'err' with a message whenever a value isn't a function. (the value isn't added)
function table.flatten_to_functions_array(tab, excluded_values, err)
	local arr = {}
	for k,v in pairs(tab) do
		
		if (type(v) == 'table' ) then
			-- No immediate cyclic refs, like _G. 
			if (v ~= tab) then
				local child = table.flatten_to_functions_array(v,excluded_values,err)
				for _,cv in ipairs(child) do
					if excluded_values[cv] == nil then
						table.insert(arr,cv)
					end
				end
			end
		else
			if excluded_values[v] == nil then
				if (type(v) ~= 'function') then
					err("Found value " .. v .. " when flatting to array")
				else
					table.insert(arr,v)
				end
			end
		end
	end
	return arr;
end


function file_exists(n)
		local f=io.open(n)
		if f == nil then return false
		else 
			io.close(f) 
			return true
			end
	end


-- Returns an inverted table where the values are the keys and vice versa. Only safe with arrays, dicts may lose data on duplicate values
function table.invert(tab)
	local t = {}
	for k,v in pairs(tab) do
		t[v] = k
	end
	return t
end


-- Code by David Kastrup
require "lfs"

function dirtree(dir, childrenfirst)
  assert(dir and dir ~= "", "directory parameter is missing or empty")
  if string.sub(dir, -1) == "/" then
    dir=string.sub(dir, 1, -2)
  end

  local function yieldtree(dir)
    for entry in lfs.dir(dir) do
      if entry ~= "." and entry ~= ".." then
        entry=dir.."/"..entry
					local attr=lfs.attributes(entry)
					if childrenfirst then coroutine.yield(entry,attr) end
					if attr.mode == "directory" then
					  yieldtree(entry)
					end
					if not childrenfirst then coroutine.yield(entry,attr) end
      end
    end
  end
  return coroutine.wrap(function() yieldtree(dir) end)
end


function deltree(dir)
	for filename, attr in dirtree(dir,true) do
		if attr.mode == "directory" then
			lfs.rmdir(filename)
		else
			os.remove(filename)
		end
	end
end

--[[
   Author: Julio Manuel Fernandez-Diaz
   Date:   January 12, 2007
   (For Lua 5.1)
   
   Modified slightly by RiciLake to avoid the unnecessary table traversal in tablecount()

   Formats tables with cycles recursively to any depth.
   The output is returned as a string.
   References to other tables are shown as values.
   Self references are indicated.

   The string returned is "Lua code", which can be procesed
   (in the case in which indent is composed by spaces or "--").
   Userdata and function keys and values are shown as strings,
   which logically are exactly not equivalent to the original code.

   This routine can serve for pretty formating tables with
   proper indentations, apart from printing them:

      print(table.show(t, "t"))   -- a typical use
   
   Heavily based on "Saving tables with cycles", PIL2, p. 113.

   Arguments:
      t is the table.
      name is the name of the table (optional)
      indent is a first indentation (optional).
--]]
function table.show(t, name, indent)
   local cart     -- a container
   local autoref  -- for self references

   --[[ counts the number of elements in a table
   local function tablecount(t)
      local n = 0
      for _, _ in pairs(t) do n = n+1 end
      return n
   end
   ]]
   -- (RiciLake) returns true if the table is empty
   local function isemptytable(t) return next(t) == nil end

   local function basicSerialize (o)
      local so = tostring(o)
      if type(o) == "function" then
				 if (debug == nil or debug.getinfo == nil) then
					return string.format("%q", so)
				 else
	         local info = debug.getinfo(o, "S")
	         -- info.name is nil because o is not a calling level
	         if info.what == "C" then
	            return string.format("%q", so .. ", C function")
	         else 
	            -- the information is defined through lines
	            return string.format("%q", so .. ", defined in (" ..
	                info.linedefined .. "-" .. info.lastlinedefined ..
	                ")" .. info.source)
	         end
				end
      elseif type(o) == "number" or type(o) == "boolean" then
         return so
      else
         return string.format("%q", so)
      end
   end

   local function addtocart (value, name, indent, saved, field)
      indent = indent or ""
      saved = saved or {}
      field = field or name

      cart = cart .. indent .. field

      if type(value) ~= "table" then
         cart = cart .. " = " .. basicSerialize(value) .. ";\n"
      else
         if saved[value] then
            cart = cart .. " = {}; -- " .. saved[value] 
                        .. " (self reference)\n"
            autoref = autoref ..  name .. " = " .. saved[value] .. ";\n"
         else
            saved[value] = name
            --if tablecount(value) == 0 then
            if isemptytable(value) then
               cart = cart .. " = {};\n"
            else
               cart = cart .. " = {\n"
               for k, v in pairs(value) do
                  k = basicSerialize(k)
                  local fname = string.format("%s[%s]", name, k)
                  field = string.format("[%s]", k)
                  -- three spaces between levels
                  addtocart(v, fname, indent .. "   ", saved, field)
               end
               cart = cart .. indent .. "};\n"
            end
         end
      end
   end

   name = name or "__unnamed__"
   if type(t) ~= "table" then
      return name .. " = " .. basicSerialize(t)
   end
   cart, autoref = "", ""
   addtocart(t, name, indent)
   return cart .. autoref
end