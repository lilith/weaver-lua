#!/usr/bin/env wsapi.cgi

require "orbit"
require "orbit.cache"
require "markdown"

module("weaver", package.seeall, orbit.new)


require "config"


package.path = package.path .. ";../kernel/?.lua"
package.cpath = package.cpath .. ";../kernel/?.so"
print (package.path)
require "kernel"

require "play"

weaver:dispatch_static("/css/.+")
weaver:dispatch_static("/js/.+")
weaver:dispatch_static("/images/.+")



weaver:dispatch_post(play, "/user/([^/]+)/play/")

weaver:dispatch_get(play, "/user/([^/]+)/play/")


function cleardata(web)
	clear_all_data()
	return web:redirect(web:link("/"))
end

weaver:dispatch_get(cleardata, "/admin/cleardata")

weaver:dispatch_get(function(web)
	return web:redirect(web:link("/user/ndj/play/"))
end, "/")
