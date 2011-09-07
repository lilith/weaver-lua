
display={out=""}

function state_update(inflow)
	-- Display value is only passed in on occasion - if it's missing, we just use the copy we have.
	if inflow.display ~= nil then display = inflow.display end 
	user = inflow.user
	world = inflow.world
	return inflow
end


function define_var( name,defaultValue)
	local tab = get_parent_of_var(name, true)
	if (tab[name] == nil) then
		tab[name] = defaultValue;
	end
end


function get_parent_of_var(name, create_missing_levels)
	local tab = _G
	while name:find("%.") ~= nil do
		local _,_,part = name:find("^([^%.]*)%.")
		name = name:gsub("^([^%.]*)%.","")
		if (tab[part] == nil) then 
			if create_missing_levels then
				tab[part] = {}
			else
				return nil
			end
		end
		tab = tab[part]
	end
	return tab
end

function short_hash(text)
	return sha2.sha256hex(text):sub(0,8)
end

function get_var( name,defaultValue)
	local tab = get_parent_of_var(name, false)
	if (tab == nil) then return defaultValue end
	local val = tab[name]
	if (val == nil) then return defaultValue end
	return val
end

function set_var( name,value)
	local tab = get_parent_of_var(name, true)
	tab[name] = value;
	return value
end

function inc(name, offset, defaultValue)
	if offset == nil then offset = 1 end
	if defaultValue == nil then defaultValue = 0 end
	return set_var(name, get_var(name,defaultValue) + offset)
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
	return state_update(coroutine.yield(outflow(type,name)))
end
function outflow(type, name)
	return {display=display,user=user,world=world, type=type, name=name}
end

function lookup_external_var(name)
	return roundtrip("getvar",name).getvar
end

function p (message)
	display.out = display.out .. '\n\n' .. message 
end

function add_option(text, id, shortcut)
	if (display.menu == nil) then
		display.menu = {}
	end
	display.menu[#display.menu + 1] = {text = text, shortcut= shortcut, id=id}
end

function choose(options)
	-- Build a dict keyed on both caption hashes and shortcut keys
	local by_id_or_s = {}
	for key,value in pairs(options) do
		-- Allow shortcuts (non-pairs)
		if (type(key) == 'number') then
			key = _G[value .. "_"] --Try to lookup the place_ variable, first locally
			-- Then in a remote file, if a . is in the name
			if (key == nil and value:find("%.") ~= nil) then 
				key = lookup_external_var(value .. "_")
			end
			-- Fallback to autonaming
			if (key == nil) then key = "Go to " .. value end
		end
		_,_,shortcut = key:find("%((%l)%)")
		if shortcut ~= nil then  by_id_or_s[shortcut] = value end
		local id = short_hash(key)
		by_id_or_s[id] = value
		add_option(key, id, shortcut)
	end
	-- Allow either the shortcut key or the hash to be used
	local answer
	repeat
		local inflow = roundtrip('prompt')
		answer = inflow.response
	until answer ~= nil
	print ("You pressed " .. answer)
	local dest = by_id_or_s[answer]
	if type(dest) == 'string' then
		roundtrip('goto',dest)
	else
		dest()
	end
end

function message(text, button_text)
	display.out = text
	display.menu = {text=button_text, shortcut='c', id='continue'}
	roundtrip('prompt')
end

-- Returns a value between 0 and 1
function random_number()
	math.randomseed( tonumber(tostring(os.time()):reverse():sub(1,6)) )
	return math.random()
end


function random_chance_of(zerotoone)
	return random_number() < zerotoone
end

-- Randomly executes one of the specified actions (if functions). If a string is specified, it is assumed to be text.
-- Weights can be provided for any item, simply add a number before it.  In {action1, action2, 4, action5}, action5 will have a 4 times large probabibility of being selected.
function do_random(actions)
	-- Calculate the weights for each action, the sum of all weights
  -- And build a new array of weight/action pairs
	local weight = 1
	local weight_sum = 0
	local new_table = {}
	local v
	for _, v in ipairs(actions) do
		if type(v) == 'number' then
			weight = v
		else
			table.insert(new_table, {weight=weight, action = v})
			weight_sum = weight_sum + weight
			weight = 1
		end
	end

	
	local random_value = random_number() * weight_sum
	-- Go through the actions looking for the action corresponding to the random value
	local previous_weight = 0
	for _, v in ipairs(new_table) do
		if (random_value >= previous_weight and random_value <= previous_weight + v.weight) then
			local act = v.action
			if type(act) == 'string' then
				p(act)
			else if type(act) == 'function' then
					act()
				else
					--TODO: throw an error?
				end
			end
		end 
	end
	-- TODO: Throw an error
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
