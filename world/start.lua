function start()
	-- We load the latest 
	p "Started..."
	menu = {
		 "world.town.center",
		["Go to the Forest (f)"] = function() switchto("world.forest.entrance")  end
 	}
	choose( menu, "Where would you like to go?")
	
end