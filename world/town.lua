function center(inflow)
	update(inflow)
  p "You are standing in the center of a busy town. Smells of rotten fruit attack your nostrils."
  var("user.town.center.visits",0)
printlocals()

	user.town.center.visits = user.town.center.visits + 1
	p ("You have been here " .. user.town.center.visits .. " times.")
	menu = {
		["Go to the Town center (t)"] =  "world.town.center",
		["Go to the Forest (f)"] = "world.forest.entrance"
 	}
	choose("Where would you like to go?", menu)
	
end