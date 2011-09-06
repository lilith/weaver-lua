
display={out=""}

function update(inflow)
	-- Display value is only passed in on occasion - if it's missing, we just use the copy we have.
	if inflow.display ~= nil then display = inflow.display end 
	user = inflow.user
	world = inflow.world
	return inflow
end

-- Can't do it this way:
function make_table_implicit(table)
	setmetatable(table, {
	      __newindex = function (op, k, v)
						rawset(op,k,v)
	      end,
	      __index = function (op, k)
						local t = {}
						rawset(op,k,t)
						return t
	      end,
	    })
	
		
			
end

function var( name,defaultValue)
	local tab = _G
	print ("Initializing var " .. name)
	while name:find("%.") ~= nil do
		local _,_,part = name:find("^([^%.]*)%.")
		name = name:gsub("^([^%.]*)%.","")
		if (tab[part] == nil) then 
			tab[part] = {}
		end
		tab = tab[part]
		print (part)
	end
	if (tab[name] == nil) then
		tab[name] = defaultValue;
	end
end

function printlocals()
	print(table.show(locals(3),"locals"))
end
	
	function locals(level)
		if (level == nil) then level = 2 end
	  local variables = {}
	  local idx = 1
	  while true do
	    local ln, lv = debug.getlocal(level, idx)
	    if ln ~= nil then
	      variables[ln] = lv
	    else
	      break
	    end
	    idx = 1 + idx
	  end
	  return variables
	end

function roundtrip(type,name)
	return update(coroutine.yield(outflow(type,name)))
end
function outflow(type, name)
	return {display=display,user=user,world=world, type=type, name=name}
end

function p (message)
	display.out = display.out .. '\n' .. message
end

function choose(message, options)
	p (message)
	local shortcuts = {}
	for key,value in pairs(options) do
		p(key)
		_,_,shortcut = key:find("%((%l)%)")
		shortcuts[shortcut] = value
	end
	local answer
	repeat
		local inflow = roundtrip('prompt')
		answer = inflow.response
	until answer ~= nil
	p ("You pressed " .. answer)
	local dest = shortcuts[answer]
	if type(dest) == 'string' then
		roundtrip('goto',dest)
	else
		dest()
	end
end



-- Ends the currently executing module, and starts the newly specified one
function switchto(name)
	roundtrip('goto',name)
end

-- Runs the specified module inside the currently executing module. Throws an exception if the module isn't marked as 'embeddable'
function run(module)
	roundtrip('exec',name)
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
