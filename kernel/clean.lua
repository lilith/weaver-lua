require "lfs"

function get_parent_dir(path)
	return path:gsub("[/\\]([^\/\\]-)[/\\]?$","",1)
end

path = get_parent_dir(lfs.currentdir())   .."/"

os.remove (path.. "world-data/state.bin")
os.remove (path.. "users/ndj/code.bin")
os.remove (path.. "users/ndj/display.bin")
os.remove (path.. "users/ndj/state.bin")
