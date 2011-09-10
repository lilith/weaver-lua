
module("weaver", package.seeall)

choice_id_prefix = "choice_"

function play(web, id)
	print ("Processing request " ..web.method)
	
	web:set_cookie("username", id)
	
	local choice_id = nil
	for k,v in pairs(web.POST) do
		print (k.. "=".. v)
		if type(k) == 'string' and k:find("^choice") ~= nil then
			choice_id = k:sub(#choice_id_prefix + 1)
			print ("User chose " .. choice_id)
		end
	end
	return resume_game(web,{id = id, branch= "master", response = choice_id})
end

function viewstate(web, id)
	info = wdebug.getstate(id,"master")
	return play_layout(web,args, "", "", info)
	
	
end

function write_choices(choices, args, err)
	if (choices == nil) then return "" end
	local inputs = {}
	for _,v in pairs(choices) do
		if v.id == nil or v.text == nil then
			err("Invalid choice " .. table.show(v,"choice"))
		else
			inputs[#inputs + 1] = input {type="submit", name=choice_id_prefix..v.id, class = "button orange", value=v.text}
		end
		-- todo add support for v.shortcut via javascript
	end
	return form{
		method = "post",
		action = "/user/"..args.id .."/play/",
		div(inputs)
	}
end


function resume_game(web, args)
	
	local log = ""
	
	local function err(message)
		log = log .. message .. "\n"
		print(message)
	end
	
	display = resume(args.id,args.branch,args.response,err)
	
	if display.module_path ~= nil then
		args.edit_link = "https://github.com/nathanaeljones/weaver-lua/edit/"..args.branch.."/code/" .. display.module_path
		args.edit_name = display.module_name
	end

	return play_layout(web,args, markdown(display.out), write_choices(display.menu,args,err), log)

end

orbit.htmlify(weaver, "resume_game", "write_choices")
