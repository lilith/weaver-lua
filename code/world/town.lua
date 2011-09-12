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
        "merchant",
		"world.house.outside"
 	})
end

-- Ice Realm arc ---------------------------------------------------
merchant_ = "Inspect the hooded merchant"
function merchant()
    p [[
        You approach the odd merchant and examine each trinket individually. A
        finely-crafted snowglobe catches your eye.
    ]]

    choose({
        "inspectsnowglobe",
        "leave"
    })
end

leave_ = "Leave"
function leave()
    message("You politely nod your head as you leave the man\'s booth. His one visible glass eye follows your movement until you disappear back into the crowd.")
    
    switchto("market")
end

inspectsnowglobe_ = "Inspect the snowglobe"
function inspectsnowglobe()
    p [[
        Curious, you pick up the snowglobe, handling it with care. In a low,
        muffled voice, the merchant says, "That there is a magical artifact.
        I'm told if you shake it, something...special may happen." As you begin
        to rattle the item, the merchant grabs your wrists, stopping you. 
        "500 coins."
    ]]

    choose({
        "paymerchant",
        "leave"
    })
end

paymerchant_ = "Pay the merchant"
function paymerchant()
    p [[
        Reaching in your pant's pocket, you take out your money and place it on 
        the table. The merchant's fingers quickly parse the change, counting 
        every last coin. As he greedily thumbs through your money, you gaze 
        into the snowglobe. 

        Peering closely into it, you can see a tower, a boat, a cave, and an oasis--
        quite odd items to be found inside a snowglobe.
    ]]

    choose({
        "shakesnowglobe"
    })
end

shakesnowglobe_ = "Shake the snowglobe"
function shakesnowglobe()
    message("Without hesitation, you shake the snowglobe and begin to feel lightheaded. Suddenly, you fall in a heap on the ground, forced into a dream-state. You awake, with no possessions, in any icy tundra.")

    switchto("world.icerealm.chasm.snowdunes")
end
-- ---------------------------------------------------------

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
	