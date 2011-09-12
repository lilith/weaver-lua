kitchen_ = "Visit the kitchen"
function kitchen()
	p[[
		You stand at the door, and survey the mess.
    ]]
	
	-- Let them go back to the hallway
	local choices = {"hallway"}
	
	-- If the dishes haven't been washed to today, let them wash the dishes
	if (this.disheswashed == null) or (this.disheswashed < (os.time() - time.one_day)) then 
		p[[	Unwashed dishes rise in a precarious tower from the sink, and a trail of ants marks the location of a honey jar]]
		choices["Wash dishes"]= function()
		  this.disheswashed = os.time() -- Set the time the dishes were washed.
			message("You scrub dishes for hours, and finally finish the last utensil. Your fingers are raw from scubbing fossilized food remains.")
			goto("kitchen")
		end
	end
	
	choose(choices)
end

hallway_ = "Go to the hall"
function hallway()
	p[[
		The cramped space makes you uneasy, as do the line of freakishly solemn portraits that line the north wall.
	]]
	
	choose({"kitchen", ["Go outside"]=outside})
end

outside_ = "Go to your house"
function outside()
	clear()
	p[[
		You stand outside the house, contemplating how much it will cost to fix the roof.
	]]
	
	choose({["Go inside"]="hallway", 
				"world.forest.entrance",
				"world.town.center"
				})
end