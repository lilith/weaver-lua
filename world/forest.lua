function entrance(inflow)
	update(inflow)
	-- We load the latest 
	p "You are in the forest"
	menu = {
		["Go to the Town center (t)"] =  "world.town.center",
		["Go to the Forest (f)"] = function() switchto("world.forest.entrance")  end
 	}
 	choose("Where would you like to go?", menu)
end