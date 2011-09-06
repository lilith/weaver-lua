
module("weaver", package.seeall)

choice_id_prefix = "choice_"

function play(web, id)
	print ("Processing request " ..web.method)
	
	local choice_id = nil
	for k,v in pairs(web.POST) do
		print (k.. "=".. v)
		if type(k) == 'string' and k:find("^choice") ~= nil then
			choice_id = k:sub(#choice_id_prefix + 1)
			print ("User chose " .. choice_id)
		end
	end
	return resume_game(web,{id = id, response = choice_id})
end


function layout(web, args, inner_html, choices_html,log)
   return html{
      head{
     title{app_title},
     meta{ ["http-equiv"] = "Content-Type",
        content = "text/html; charset=utf-8" },
     link{ rel = 'stylesheet', type = 'text/css', 
        href = web:static_link('/css/style.css'), media = 'screen' }
      },
      body{
     div{ class = "container",
        div{ class = "header", title = "sitename" },
        div{ class = "menu",
           a{href="/admin/cleardata", "Clear all data"}
        },  
        div{ class = "contents", inner_html },
				div{ class = "choices", choices_html },
				pre{ class = "log", log },
        div{ class = "footer", copyright_notice }
     }
      }
   } 
end




function write_choices(choices)
	if (choices == nil) then return "" end
	local inputs = {}
	for _,v in pairs(choices) do
		inputs[#inputs + 1] = input {type="submit", name=choice_id_prefix..v.id, value=v.text}
		-- todo add support for v.shortcut via javascript
	end
	return form{
		method = "post",
		action = "/user/ndj/play/",
		div(inputs)
	}
end


function resume_game(web, args)
	
	local log = ""
	
	local function err(message)
		log = log .. message .. "\n"
	end
	
	display = resume("ndj",args.response,err)
	
	
	
	return layout(web,args, markdown(display.out), write_choices(display.menu), log)

end

orbit.htmlify(weaver, "resume_game", "layout", "write_choices")
