function start(inflow)
	update(inflow)
	p ("hi")
	-- We load the latest 
	p "Started..."
	menu = {
		["Go to the Town center (t)"] =  "world.town.center",
		["Go to the Forest (f)"] = function() switchto("world.forest.entrance")  end
 	}
	repeat
 		choose("Where would you like to go?", menu)
	until true==false
end