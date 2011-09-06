


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


	-- Handle code failures
	if sucess == false then 
		err ("Failed to exeucte" .. code.name.. "  ".. outflow)
		err ("Starting over at safe point")
		-- Go to a safe point in the game
		code = get_default_code_state()
		-- Strip user response, ignore whatever state changes might have happend
		inflow.response = nil
	else 
		if coroutine.status(code.co) == 'dead' and (outflow == nil or outflow.type ~= 'goto') then
			if code.name == last_error then
				err ("Failure in " .. code.name .. ", Starting over at a safe point")
				-- It's happened twice, restart game
				code = get_default_code_state()
				-- Strip user response, ignore whatever state changes might have happend
				inflow.response = nil
			else
			  -- Handle dead modules who haven't specified a succesor by... restarting them?
				local temp = build_coroutine(code.name,err)-- TODO: Handle (rare) missing module exception (only happens when deleted out from under..)
				if temp == nil then
					-- We couldn't restart it. TODO: fall back to a previous checkpoint instead.
					
				else
					code = temp
					last_error = code.name
				end
				-- Strip user response, ignore whatever state changes might have happend
				inflow.response = nil
			end
		-- Handle success
		else 
			if outflow.type == 'goto' then
				-- If the new name doesn't have a '.', assume it is in the same file as the last code run.
				local new_name = outflow.name
				if (new_name:match("^[^%.]+$") ~= nil) then
					new_name = code.name:gsub("[^%.]+$","",1) .. outflow.name
				end
				code = build_coroutine(new_name,err) -- TODO: Handle missing module exception.
			else if outflow.type == 'prompt' then
				waiting_on_user = true
			end
			-- We need to move outflow state into inflow state for the next round
			inflow = {args=outflow.args, world=outflow.world, user=outflow.user, display = outflow.display}
		
		end