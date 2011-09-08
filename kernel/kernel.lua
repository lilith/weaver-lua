require "lfs"
require "pluto"
require "utils"
require "sha2"


function path.approot()
	return path.getparent(lfs.currentdir())  
end
function path.userdata()
	return path.join(path.approot() ,"user-data")
end
function path.branchdata()
	return path.join(path.approot() ,"branch-data")
end
function path.branchcode()
	return path.join(path.approot() ,"code")
end


function get_default_code_state(err)
	if (err == nil) then err = print end
	return build_coroutine("world.start.start",err)
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

wdebug = {}
function wdebug.getstate(id,branch)
	-- User state file
	local user_file = path.join(path.userdata() , id , branch,"default.bin")
	local user_state = load_and_parse(user_file,{data = {}, flowstack={[1]=get_default_code_state(err)}})
	-- World state file
	local branch_file = path.join(path.branchdata() , branch, "default.bin")
	local branch_state = load_and_parse(branch_file,{})

	return table.show(user_state,"user_state")
		..   table.show(branch_state,"branch_state")
end
	
-- Returns a display state object
function resume(id, branch, response,err)
	-- User state file
	local user_file = path.join(path.userdata() , id , branch,"default.bin")
	local user_state = load_and_parse(user_file,{data = {}, flowstack={[1]=get_default_code_state(err)}})
	local named_state_dir = path.join(path.userdata() , id , branch,"named-states")
	
	-- If there is no response from the user, and we have an existing display state, we don't need to resume any code, just return the current response. 
	if response == nil and user_state.display ~= nil then
		return user_state.display
	end 
	
	-- World state file
	local branch_file = path.join(path.branchdata() , branch, "default.bin")
	local branch_state = load_and_parse(branch_file,{})

	-- Resume the code state, run scripts until they need user input
	user_state, branch_state = run_code_until_new_response_needed(user_state,branch_state,named_state_dir,{response = response},err)

	-- Save code and resulting state
	write_file(user_file, pluto.persist(get_persist_perms(),user_state))
	write_file(branch_file, pluto.persist(get_persist_perms(),branch_state))
	
	-- Return new display object
	return user_state.display
end 

--[[
* flow.stack.depth -- How deeply the current flow is nested. 1 means the current flow is the root flow.
* flow.getparent() - Returns the method name, flow ID, and stack depth of the parent flow. 

* flow.goto("name-of-method") -- Drops the current flow and starts a new flow in its place, with the specified method. Keeps the flow ID. Used within worlds.
* flow.nest_flow("name-of-state", "default-method", commandFilter, userdataprefix) -- If the specified flow ID is already in the flow stack, throws an error. 
    Otherwise, loads the flow from disk and pushes it onto the stack. 
    If the flow doesn't exist, a new one is created starting at 'default-method'. Useful for being transported into another world.
* flow.goto_flow("name-of-state", "default-method") -- If the current flow is named, it is saved to disk. 
    Then it is removed from the stack, and replaced with the specified flow. Like nest\_flow, but calling flow.done() in the new flow 
    won't return the user to the current flow, but the current flow's parent.
* flow.nest_temp("method", commandFilter) -- Starts an unnamed flow with the specified method and runs it until it (or commandFilter) calls done().
* flow.nest_throwaway("method", commandFilter) -- Starts an unnamed flow with the specified method and runs it until it (or commandFilter) calls done(). Changes to world and user state are discarded. 


* flow.reset_flow("name-of-state","method-name") -- Resets the specified named flow to the beginning
* flow.done() -- Ends the current flow and returns control to the parent. Saves the flow if it is named.
* flow.done(level) -- Ends the current flow and all parent flows until there are only 'level' number of flows remaining. Saves all named flows.

]]--
function run_code_until_new_response_needed(user_state, branch_state, named_state_dir, indata, err)
	local success, outdata
	local waiting_on_user = false
	local last_error = nil
	local flowstack = user_state.flowstack
	indata.user = user_state.data
	indata.branch = branch_state
	
	local loop_count = 0
	local escape_count = 0
	local top_flow
  repeat

		-- Resume running the flow at the top of the stack
		top_flow = flowstack[#flowstack]
		indata.user.flow_depth = #flowstack
		-- Build a list of all child filters in the flow stack, with the nearest parents filters listed first.
		indata.flowfilters = {}
		if #flowstack > 1 then
			local i,_, filter
			for i = #flowstack -1, 1, -1 do
				if flowstack[i].childfilters ~= nil then
					for _, filter in ipairs(flowstack[i].childfilters) do
						table.insert(indata.flowfilters,filter)
					end
				end
			end
		end
		
		local last_message = outdata and outdata.msg or nil
		-- resume scripts
		--err("Running " .. top_flow.funcname .. " [level "..#flowstack.."]")
		--err(table.show(flowstack,"stack_trace"))
		
	  --err(table.show(indata.user,"user.data"))
		success, outdata = coroutine.resume(top_flow.continuation, indata)
		
		-- Check for failure
		local failed = false
		if success == false then failed = true end -- Never started
		if (coroutine.status(top_flow.continuation) == 'dead') then failed = true end -- Runtime errors or function ended

		-- Prevent endless loops
		if loop_count > 29 then
			print ("Stopping infinite looping at 30: " .. loop_count)
			-- We've gota recursive problem.
			print(top_flow.funcname .. " executed " .. (failed and (' with errors:\n' .. outdata) or ' successfully'))
			if (not failed) then
				print(outdata.msg .. " Message arrived: " .. table.show(outdata.msg,"message"))
			else
				table.show(outdata,"output")
			end
		end

		-- Handle endless loops
		if loop_count > 30 then
			failed = true
			err ("Canceled " .. top_flow.funcname .. " due to excessive looping")
			if escape_count > 1 then
				if (outdata ~= nil and outdata.display ~= nil) then 
					user_state.display = outdata.display
				end
				return user_state,branch_state
			end
			escape_count = escape_count + 1
			loop_count = 0
		end
		loop_count = loop_count + 1
		
		-- Handle failure
		if failed then
			if (success == true and outdata == nil) then
				err ("Module " .. top_flow.funcname .. " seems to be incomplete. Remember to provide the user with choices, and make sure all those choices actually do something or go somewhere.")
				err ("Previous module sent message " .. table.show(last_message))

			end
			if (outdata ~= nil) then outdata = " with result:\n " .. outdata .."\n" else outdata = "" end
			err ("Module "..top_flow.funcname.." ended unexpectedly" ..  outdata)
			err ("Starting over at safe point")
			-- Go to a safe point in the game
			local new_flow = get_default_code_state(err)
			new_flow.id = top_flow.id -- Keep the flow ID in case it is a named flow.
			flowstack[#flowstack] = new_flow
			-- Strip user response, and also ignore whatever state changes might have happened by not copying outdata
			indata.response = nil
			--TODO: add support for looping functions.
		end
		
		
		-- Define function for popping the current flow and saving it to disk (if it has an ID)
		local function pop(flowstack)
			local popped = flowstack[#flowstack]
			flowstack:remove()
			if popped.id ~= nil then -- Save the flow if it is named. 
				write_file(path.join(named_state_dir,popped.id..".flow"), pluto.persist(get_persist_perms(),popped))
			end
			return popped
		end
		-- Define a function for loading a named flow. If default_function cannot be found, returns nil
		local function loadflow(flow_id, default_function)
			local new_flow  = nil
			if (flow_id ~= nil) then 
				new_flow =  load_and_parse(path.join(named_state_dir, flow_id..".flow"),nil)
			end
			if (new_flow == nil) then 
				new_flow = build_coroutine(default_function,err)
			end
			if new_flow ~= nil then new_flow.id = flow_id end -- Specify the flow ID
			return new_flow
		end
		-- Define a function for restarting a named flow
		local function resetflow(flow_id, default_function)
			local new_flow  = build_coroutine(default_function,err)
			if new_flow == nil then
				err("Cannot reset flow ".. flow_id .. " because function ".. default_function .." could not be found.")
				return nil
			end
			new_flow.id = flow_id
			write_file(path.join(named_state_dir,flow_id..".flow"), pluto.persist(get_persist_perms(),new_flow))
			return new_flow
		end
		
		-- Handle success, and process the message from the script
		if failed == false then 
			
			local msg = outdata.msg
			local msg_type = nil
			if msg ~= nil then msg_type = msg.type end
			
			if msg_type == 'prompt' then
				print("Waiting on user")
				waiting_on_user = true
			end

			-- If the new name doesn't have a '.', assume it is in the same file as the last code run, and resolve it to an absolute path.
			if msg ~= nil and msg.funcname ~= nil then msg.funcname = ns.resolve(msg.funcname,ns.parent(top_flow.funcname)) end
			
			print("Success: message arrived:" .. table.show(msg,"message"))
				
			if msg_type == 'goto' then
				local new_flow = build_coroutine(msg.funcname,err) 
				-- If the name doesn't exist, restart the current flow at its entry point
				if new_flow == nil then
					err("Failed to locate " .. msg.funcname .. ", falling back to " .. top_flow.funcname)
					new_flow = build_coroutine(top_flow.funcname,err) --Could fail if code is edited
				end
				-- Replace top_flow with new_flow
				new_flow.id = top_flow.id -- Keep the flow ID in case it is a named flow.
				flowstack[#flowstack] = new_flow
			end
			if msg_type == 'done' then
				-- If no level was passed, just exit the top flow
				if msg.level == nil then msg.level = #flowstack -1 end
				-- Exit flows until we are to the desired depth
				while #flowstack > msg.level do
					pop(flowstack)
				end
			end
			if msg_type == 'goto_flow' then
				local new_flow = loadflow(msg.flowname, msg.funcname)
				if new_flow == nil then
					err("Failed to switch to flow ".. msg.flowname .. "; failed to locate " .. msg.funcname)
				else
					pop(flowstack)
					flowstack[#flowstack + 1] = new_flow
				end
			end
			if msg_type == 'nest_flow' then
				local new_flow = loadflow(msg.flowname, msg.funcname)
				if new_flow == nil then
					err("Failed to switch to flow ".. msg.flowname .. "; failed to locate " .. msg.funcname)
				else
					-- add any child filters (such as for dreaming)
				  new_flow.childfilters = msg.childfilters
					flowstack[#flowstack + 1] = new_flow
				end
			end
			
			if msg_type == 'reset_flow' then
				resetflow(msg.flowname, msg.funcname)
			end
			

			-- We need to move outdata state into indata state for the next round
			indata = {args=outdata.args, branch=outdata.branch, user=outdata.user}
			
			-- Sending vars
			if msg_type == 'getvar' then
				local temp_err = err
				indata.getvar = get_var_from_file(msg.funcname,function(message)
					temp_err("Non-fatal: " .. message)
				end)
			end
		end
		
	until waiting_on_user
	
	user_state.display = outdata.display
	user_state.data = outdata.user
	branch_state = outdata.branch
	
	user_state.display.module_path = flowstack[#flowstack].funcname:gsub("%.","/"):gsub("/[^/]+$","",1) .. ".lua"
	user_state.display.module_name = flowstack[#flowstack].funcname:gsub("%.[^%.]+$","",1)
	
	return user_state, branch_state
end



function build_coroutine(name,err)
	-- Find the filename
	local filename = path.join(path.branchcode(),ns.parent(name):gsub("%.",path.slash()) .. ".lua")
	-- Create the sandboxed environment
	local env  = get_globals()
	env.loaded_funcname = name
	env.loaded_filename = ns.parent(name)
	
	-- Load the libraries
	local lib = load_in(path.join(path.branchcode(), "lib.lua"),env,err)
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
	local func_wrapper = function(indata)
		state_update(indata)
		initial_func()
	end
	setfenv(func_wrapper,env)
	local code = coroutine.create(func_wrapper)
	-- Save the name so they can be recreated
	return {continuation=code,funcname=name}
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
	local filename = path.join(path.branchcode(),ns.parent(name):gsub("%.",path.slash()) .. ".lua")
	-- Create the sandboxed environment
	local env  = get_globals() 
	-- TODO: if we eventually need to support lib calls in the file root, uncomment this
	--local lib = load_in(coderoot .. path.slash() .. "kernel" .. path.slash() .. "lib.lua",env,err)
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

-- Creates an environment by copying sandbox_env. Used for sandboxing.
function get_globals()
	local globs =  deepcopy(sandbox_env) -- {pairs = pairs,print = print, type=type, coroutine = {yield=coroutine.yield}} -- sandbox_env
	globs["_G"] = globs
	return globs
end

function get_persist_perms()
	-- TODO: add user and branch data here so we don't duplicate that data in every single flow.
	return table.invert(table.flatten_to_functions_array(sandbox_env, persistable, print))
end

function get_unpersist_perms()
	return table.flatten_to_functions_array(sandbox_env, persistable,print )
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
	deltree(path.branchdata())
	deltree(path.userdata())
end


function main()
	-- Default to the current dir
	print (path.approot())
	
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
