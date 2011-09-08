kitchen_ = "Visit the kitchen"
function kitchen()
	p[[
		You stand at the door, and survey the mess.]]
	
	local unwashed = this.disheswashed ~= null or this.disheswashed < os.time() - time.one_day 
	
	local choices = {"hallway"}
	
	if unwashed then 
		p[[	Unwashed dishes rise in a precarious tower from the sink, and a trail of ants marks the location of a honey jar]]
		choices["Wash dishes"]= function()
			message("You scrub dishes for hours, and finally finish the last utensil. Your fingers are raw from scubbing fossilized food remains.")
			this.disheswashed = os.time
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
	p[[
		You stand outside the house, contemplating how much it will cost to fix the roof.
	]]
	
	choose({["Go inside"]="hallway", 
				"world.forest.entrance",
				"world.town.center"
				})
end