module("weaver", package.seeall)

function play_layout(web,args, inner_html, choices_html, log)
	return layout(web,args,
	div{ class = "choices", choices_html } ..
  div{ class = "contents", inner_html },log)
end

function edit_list_layout(web, args, inner_html)
	return layout(web,args,
	div{class="content", 
	 ul{class="files", inner_html},
	 a{href="/".. args.branch .. "/edit/newfile",  class="button", "Create a new file"}
	})
end

function edit_new_layout(web, args, inner_html)
	return layout(web,args,
	div{class="content", 
		form{
			method = "post",
			action = "/".. args.branch .. "/edit/createnewfile",
			p{"Specify the filename in the form 'world.place'"},
			label {["for"] = "filename", "Filename:"},
			input {type="text", id="filename", name="filename"},
			input {type="submit", id="create" ,name="create", value="Create file"}
		}
	})
end

function layout(web, args, inner_html,log)
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
		           a{href="/admin/cleardata", "Clear all data"},
								a{href="/admin/reboot", "Reboot"},
								a{href="/user/ndj/debug/", "View state"},
								a{href="/admin/pull", "Pull changes"},
							 a{href= (args and args.edit_link or ""), "Edit ".. (args and args.edit_name or "")}
		        },  
						div{ class = "body",
							inner_html
						},
						div {style="clear:both;height:1px"}
		     },
				pre{ class = "log", log },
				div{ class = "footer", copyright_notice }
      }
   } 
end

orbit.htmlify(weaver, "layout","play_layout","edit_list_layout", "edit_new_layout")
