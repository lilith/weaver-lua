
display={out=""}
this = {}
shared = {}
function roundtrip(type,name)
	return state_update(coroutine.yield(outdata(type,name)))
end

function state_update(indata)
	-- Display value is only passed in on occasion - if it's missing, we just use the copy we have.
	if indata.display ~= nil then _G.display = indata.display end 
	_G.user = indata.user
	_G.branch = indata.branch
	if user[loaded_filename] == nil then user[loaded_filename] = {} end
	if branch[loaded_filename] == nil then branch[loaded_filename] = {} end
	_G.this = _G.user[loaded_filename]
	_G.shared = _G.branch[loaded_filename]
	-- Run all filters passed to us. 
	local filters = indata.childfilters
	if filters ~= nil then
		local _,filter
		for _,filter in ipairs(indata.childfilters) do
			filter(indata)
		end
	end
	return indata
end
function outdata(type, funcname)
	local d = {display=_G.display,user=_G.user,branch=_G.branch, msg  = {type=type, funcname=funcname}}
	-- Remove convenience tables unless they have data in them.
	if table.isempty(user[loaded_filename]) then user[loaded_filename] = nil end
	if table.isempty(branch[loaded_filename]) then branch[loaded_filename] = nil end
	_G.this = nil
	_G.shared = nil
	_G.user = nil -- We don't want these included in the continuation. They'll be outdated when it restarts, and will be passed back to us anyway.
	_G.branch = nil
	return d;
end

function define_var( name,defaultValue)
	local tab = get_parent_of_var(name, true)
	name = ns.member(name)
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




function lookup_external_var(name)
	return roundtrip("getvar",name).getvar
end

function p (message)
	display.out = display.out .. '\n\n' .. message:gsub("^[ \t]+",""):gsub("\n[ \t]+","\n")
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
			if (key == nil) then key = "Go to " .. ns.member(value) end
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
		local indata = roundtrip('prompt')
		answer = indata.response
	until answer ~= nil
	print ("You pressed " .. answer)
	local dest = by_id_or_s[answer]
	if dest == nil then
		-- TODO, throw error and restart loop
	end
	if type(dest) == 'string' then
		roundtrip('goto',dest)
	else
		dest()
	end
end

function message(text, button_text)
	if button_text == nill then button_text = "Continue" end
	display.out = text
	display.menu = {{text=button_text, shortcut='c', id='continue'}}
	roundtrip('prompt')
end

function clear()
	display.out = ""
	display.menu = {}
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

function table.isempty(tab)
	return next(tab) == nil
end

-- Ends the currently executing module, and starts the newly specified one
function switchto(name)
	display.menu = {}
	display.out = ""
	roundtrip('goto',name)
end

function goto(name)
	switchto(name)
end

if ns == nil then ns = {} end
-- Gets the parent of a namespace. "world.town.center" -> "world.town"
function ns.parent(name)
	return name:gsub("%.[^%.]+$","",1)
end
-- Gets the last segment of a namespace. "world.town.center" -> "center"
function ns.member(name)
	local _,_,membername = name:find("%.([^%.]+)$")
	return membername and membername or name
end
function ns.hasdot(name)
	return name:match("^[^%.]+$") == nil
end 
function ns.resolve(name, base)
	if ns.hasdot(name) then
		return name
	else
		return base .. "." .. name
	end
end

-- Define time spans
time = {
	one_year = os.time{year=1971, month=1, day=1, hour=0} - os.time{year=1970, month=1, day=1, hour=0},
	one_month = os.time{year=1970, month=5, day=1, hour=0} - os.time{year=1970, month=4, day=1, hour=0},
	one_day = os.time{year=1970, month=5, day=2, hour=0} - os.time{year=1970, month=5, day=1, hour=0},
	one_hour = os.time{year=1970, month=5, day=1, hour=1} - os.time{year=1970, month=5, day=1, hour=0},
	one_minute = os.time{year=1970, month=5, day=1, hour=1, min = 1, sec = 0} - os.time{year=1970, month=5, day=1, hour=0, min = 0, sec = 0},
	one_second = os.time{year=1970, month=5, day=1, hour=1, min = 0, sec = 1} - os.time{year=1970, month=5, day=1, hour=0, min = 0, sec = 0}
}
