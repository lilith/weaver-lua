center_ = "Go to the Town Center (c)"
function center()
  p "You are standing in the center of a busy town. Smells of rotten fruit attack your nostrils."
 	
	p ("You have been here " .. inc("user.town.center.visits",1) .. " times.")
	
	choose({
		"market", 
		"world.house.outside",
        "world.test.rabbithole.rabbithole",
		"world.forest.entrance"
 	})
	
end

market_ = "Go to the market (m)"
function market()
	
	p "You are standing in the center of a busy market."
	
	choose({
		"center",
		"world.house.outside"
 	})
end

home_ = "Go to your home (h)"
function home()
	
	p"You can see your little old wood house standing at the gate, you walk towards the door, turn the key in the lock and step in."
	
	p("You have been here"..inc("user.home.visit",1).."times")
	
	choose({
		"bedroom",
		"kitchen",
		"center"
	})
end

function bedroom()
	
	p"You open the door and you realize something feels wrong"
	
	choose({
		"center",
		["Go back to the hallway"] = "home",
		"kitchen",
		["check your cash stash under your pillow"]= function()
		if (not get_var("user.home.cash", false)) then
			p"You don't find your cash anywhere."
		else
			p"You find your cash, but you look around, and see that you lamp is broken."
		end
	end
	})
end
	
	-- TODO: Add clear(), yesno(), 
	