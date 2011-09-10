module("weaver", package.seeall)


-- Create your own branch. When you create a branch, you are given full permissions to it. 

-- How do we give a user access to a branch? 

edit = {}

function edit.listfiles(web, branch)
	local html = ""
	for filename, attr in dirtree(path.branchcode(),true) do
		if attr.mode == "file" and filename:find("%.[Ll][uU][aA]$") ~= nil then
			print (filename)
			local short_name = filename:sub(#path.branchcode() + 2)
			print (short_name)
			local edit_link = "https://github.com/nathanaeljones/weaver-lua/edit/"..branch.."/code/" .. short_name
			local edit_name = short_name:gsub("%.lua$","",1):gsub("%/",".")
			
			html = html .. "<li><a href=" .. edit_link .. ">" .. edit_name .. "</a></li>\n"
		end
	end
	
	return edit_list_layout(web, {branch = branch}, html)
	
end


function edit.newfile(web, branch)
	return edit_new_layout(web, {branch = branch}, html)
end

function edit.createnewfile(web, branch)
	if (web.POST["filename"] ~= nil and web.POST["filename"]:find("^[a-zA-Z%.]+$") ~= nil) then
		os.execute('git pull')
		local path = path.join(path.branchcode(), web.POST["filename"]:gsub("%.",path.slash()) .. ".lua")
		
		if not file_exists(path) then 
			print ("Creating " .. path)
			write_file(path," ") end
			
		local cmd = 'git commit -m "Added new file '.. web.POST["filename"] .. '" "'.. path.sub(#lfs.currentdir() + 1) ..'"'
		print(cmd)
		os.execute(cmd)
		os.execute('git push')
	else
		return web:redirect(web:link("/" .. branch .. "/edit/newfile"))
	end 
	return web:redirect(web:link("/" .. branch .. "/edit/listfiles"))
end


function edit.pull(web)
	--TODO: pipe log to file and read it.
	os.execute('git pull')
	return web:redirect(web:link("/"))
end