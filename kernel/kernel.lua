require "lfs"
require "pluto"
require "utils"
require "sha2"

function get_default_code_state(err)
	if (err == nil) then err = print end
	return build_coroutine("world.start.start",err)
end

function get_user_data_path(id, segment)
	return  getcoderoot() .. getslash() .. "users"  .. getslash() .. id .. getslash() .. segment .. ".bin"
end

function get_world_data_path(segment)
	return  getcoderoot() .. getslash() .. "world-data"  .. getslash() .. segment .. ".bin"
end


function get_parent_dir(path)
	return path:gsub("[/\\]([^\/\\]-)[/\\]?$","",1)
end


function load_and_parse(path, default_data)
	local data = read_file(path)
	if data ~= nil then
		data = pluto.unpersist(get_unpersist_perms(),data)
	else
		data = default_data
	end
	return data
end


-- Returns a display state object
function resume(id, response,err)
	
	-- If there is no response from the user, we don't need to resume any code, just return the current response. 
	if (response == nil) then
		local display  = read_file(get_user_data_path(id, "display"))
		-- Unless the user has no existing state
		if display ~= nil then 
			return pluto.unpersist(get_unpersist_perms(),display) 
		end
	end 
	
	--print(table.show(get_persist_perms(), "persist_perms"))
	--print(table.show(get_unpersist_perms(), "unpersist_perms"))
	
	-- Load the current code state (coroutine)
	-- This also includes the coroutine object
	local code = load_and_parse(get_user_data_path(id, "code"), get_default_code_state())
	local world_state = load_and_parse(get_world_data_path(id, "state"), {})
	local user_state = load_and_parse(get_user_data_path(id, "state"), {})
	
	
	-- Resume the code state
	local outflow
	code, outflow = run_code_until_new_response_needed(code,{response = response, world=world_state, user=user_state},err)
	
--[[	print "Persisting data"
	print(table.show(code, "code"))
	print(table.show(outflow.display, "display"))
	print(table.show(outflow.user, "user"))
	print(table.show(outflow.world, "world"))
		]]--
	-- Save code and resulting state
	write_file(get_user_data_path(id, "code"), pluto.persist(get_persist_perms(),code))
	write_file(get_user_data_path(id, "display"), pluto.persist(get_persist_perms(),outflow.display))
	write_file(get_user_data_path(id, "state"), pluto.persist(get_persist_perms(),outflow.user))
	write_file(get_world_data_path( "state"), pluto.persist(get_persist_perms(),outflow.world))
		
	-- Return new display object
	return outflow.display
end 

function run_code_until_new_response_needed(code, inflow, err)
	local success, outflow
	local waiting_on_user = false
	local last_error = nil
	local original_code = code
  repeat
	
		--print(table.show(code, "code"))
		success, outflow = coroutine.resume(code.co, inflow)
		
		local failed = false
		if success == false then failed = true end -- Never started
		if coroutine.status(code.co) == 'dead' and (outflow == nil or outflow.type ~= 'goto') then failed = true end -- Runtime errors or function ended
		
		if failed then
			if (success == true and outflow == nil) then
				err ("Module " .. code.name .. " seems to be incomplete. Remember to provide the user with choices, and make sure all those choices actually do something or go somewhere.")
			end
			if (outflow ~= nil) then outflow = " with result:\n " .. outflow .."\n" else outflow = "" end
			
			
			err ("Module "..code.name.." ended unexpectedly" ..  outflow)
			err ("Starting over at safe point")
			-- Go to a safe point in the game
			code = get_default_code_state()
			-- Strip user response, and also ignore whatever state changes might have happened by not copying outflow
			inflow.response = nil
			
			--TODO: add support for looping functions.
			-- Handle success
		else 
			if outflow.type == 'goto' then
				-- If the new name doesn't have a '.', assume it is in the same file as the last code run.
				local new_name = outflow.name
				if (new_name:match("^[^%.]+$") ~= nil) then
					new_name = ns.parent(code.name).. "." .. outflow.name
				end
				local new_code = build_coroutine(new_name,err) 
				if new_code ~= nil then
					code = new_code
				else
					err("Failed to locate " .. new_name .. ", falling back to " .. code.name)
					code = build_coroutine(code.name,err) --Could fail if code is edited
				end
			else if outflow.type == 'prompt' then
				waiting_on_user = true
			end 
			-- We need to move outflow state into inflow state for the next round
			inflow = {args=outflow.args, world=outflow.world, user=outflow.user, display = outflow.display}
			
			-- Sending vars
			if outflow.type == 'getvar' then
				local temp_err = err
				inflow.getvar = get_var_from_file(outflow.name,function(message)
					temp_err("Non-fatal: " .. message)
				end)
			end
		end
	end
		
	until waiting_on_user
		
	
	outflow.display.module_path = code.name:gsub("%.","/"):gsub("/[^/]+$","",1) .. ".lua"
	outflow.display.module_name = code.name:gsub("%.[^%.]+$","",1)
	
	return code, outflow
end



function build_coroutine(name,err)
	-- Find the filename
	local coderoot = getcoderoot()
	local filename = coderoot .. getslash() .. ns.parent(name):gsub("%.",getslash()) .. ".lua"
	-- Create the sandboxed environment
	local env  = get_globals()
	-- Load the libraries
	local lib = load_in(coderoot .. getslash() .. "kernel" .. getslash() .. "lib.lua",env,err)
	if (lib == nil) then return nil end
	-- Load the file from 'name'
	local mod = load_in(filename,env,err)
	if (mod == nil) then return nil end
	pcall(lib)
	-- Todo, add hook calls here
	pcall(mod)
	-- Look up the function from 'name'
	local funcname = ns.member(name)
	local initial_func = env[funcname]
	if (initial_func == nil) then
		err ("Couldn't find function " .. funcname .. " in " .. filename)
		return nil
	end
	-- We need to update the global state in the environment when the corutine is stared
	-- This function will be executed in a scope that contains the state_update function from lib.lua
	local func_wrapper = function(inflow)
		state_update(inflow)
		initial_func()
	end
	setfenv(func_wrapper,env)
	local code = coroutine.create(func_wrapper)
	-- Save the name so they can be recreated
	return {co=code,name=name}
end



-- Loads and parses the specified file into a function, then sets its environment to 'env'. Errors go to the 'err' function.
function load_in(path, env, err)
	local func, message = loadfile(path)
	if (func == nil) then
		err ("Failed to load " .. path)
		err (message)
		err ("")
	else
		setfenv(func,env)
	end
	return func
end


-- Loads a lua file to find the value of a global variable it contains. name is in the form dir.file.var. file does not cotaint the extension.
function get_var_from_file(name, err)
	-- Find the filename
	local coderoot = getcoderoot()
	local filename = coderoot .. getslash() .. ns.parent(name):gsub("%.",getslash()) .. ".lua"
	-- Create the sandboxed environment
	local env  = get_globals() 
	-- TODO: if we eventually need to support lib calls in the file root, uncomment this
	--local lib = load_in(coderoot .. getslash() .. "kernel" .. getslash() .. "lib.lua",env,err)
	--if (lib == nil) then return nil end
	-- pcall(lib)
	-- Hook files would go here
	
	-- Load the file into the sandbox and return the var value that the file added to the global environment.
	local mod = load_in(filename,env,err)
	if (mod == nil) then return nil end
	pcall(mod)
	return env[ns.member(name)]
end

if ns == nil then ns = {} end
-- Gets the parent of a namespace. "world.town.center" -> "world.town"
function ns.parent(name)
	return name:gsub("%.[^%.]+$","",1)
end
-- Gets the last segment of a namespace. "world.town.center" -> "center"
function ns.member(name)
	local _,_,membername = name:find("%.([^%.]+)$")
	return membername
end


-- Creates an environment by copying sandbox_env. Used for sandboxing.
function get_globals()
	local globs =  deepcopy(sandbox_env) -- {pairs = pairs,print = print, type=type, coroutine = {yield=coroutine.yield}} -- sandbox_env
	globs["_G"] = globs
	return globs
end

function get_persist_perms()
	return table.invert(table.flatten_to_functions_array(sandbox_env, persistable, print))
end

function get_unpersist_perms()
	return table.flatten_to_functions_array(sandbox_env, persistable,print )
end

function getcoderoot()
	return get_parent_dir(lfs.currentdir())  
end

function getslash()
	return "/"
end

-- sample sandbox environment
sandbox_env = {
  ipairs = ipairs,
  next = next,
  pairs = pairs,
  pcall = pcall,
  tonumber = tonumber,
  tostring = tostring,
  type = type,
	print = print,
  unpack = unpack,
	sha2 = {sha256hex = sha2.sha256hex},
  coroutine = { create = coroutine.create, resume = coroutine.resume, 
      running = coroutine.running, status = coroutine.status, 
      wrap = coroutine.wrap, yield = coroutine.yield },
  string = { byte = string.byte, char = string.char, find = string.find, 
      format = string.format, gmatch = string.gmatch, gsub = string.gsub, 
      len = string.len, lower = string.lower, match = string.match, 
      rep = string.rep, reverse = string.reverse, sub = string.sub, 
      upper = string.upper },
  table = { insert = table.insert, maxn = table.maxn, remove = table.remove, 
      sort = table.sort, show = table.show},
  math = { abs = math.abs, acos = math.acos, asin = math.asin, 
      atan = math.atan, atan2 = math.atan2, ceil = math.ceil, cos = math.cos, 
      cosh = math.cosh, deg = math.deg, exp = math.exp, floor = math.floor, 
      fmod = math.fmod, frexp = math.frexp, huge = math.huge, 
      ldexp = math.ldexp, log = math.log, log10 = math.log10, max = math.max, 
      min = math.min, modf = math.modf, pi = math.pi, pow = math.pow, 
      rad = math.rad, random = math.random, sin = math.sin, sinh = math.sinh, 
      sqrt = math.sqrt, tan = math.tan, tanh = math.tanh },
  os = { clock = os.clock, difftime = os.difftime, time = os.time },
	debug = {getlocal = debug.getlocal} -- REMOVE THIS
}


persistable = {[math.pi] = math.pi, [math.huge] = math.huge}



function clear_all_data()
	local function get_parent_dir(path)
		return path:gsub("[/\\]([^\/\\]-)[/\\]?$","",1)
	end

	local path = get_parent_dir(lfs.currentdir())   .."/"

	os.remove (path.. "world-data/state.bin")
	os.remove (path.. "users/ndj/code.bin")
	os.remove (path.. "users/ndj/display.bin")
	os.remove (path.. "users/ndj/state.bin")
end


function main()
	-- Default to the current dir
	print (getcoderoot())
	
	local display, response = nil
	repeat 
		display = resume("ndj",response, print)
		print (display.out)
		print( "-")
		if (display.menu ~= nil) then
			for k,v in pairs(display.menu) do
				print (v)
			end
		end
		print (">")
		response = io.read()
	until response == "q"

end
