snowdunes_ = "Snow dunes"
function snowdunes()
	p[[
		Hills of snow roll for miles in every direction as a fierce blizzard rips at your
        skin. In this weather, visibility is near-zero. Which way should you go? ]]

	-- Let them go back to the hallway
	local choices = {"north"}
	
	choose(choices)
end

north_ = "Head north"
function north()
    p [[
        Hours of endless trekking through the dunes yield no signs of civilization.
        Just when you think of turning around, you see a massive stone tower. Though
        barely, you can make out small light sources coming from the tower's apex.
    ]]

    choose({"world.icerealm.tower.foyer"})
end
