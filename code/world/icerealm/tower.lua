foyer_ = "Enter foyer"
foyer_ = "Enter the foyer"
function foyer()
	p[[
        Inside the foyer, dust is 
        strewn about everywhere in the poorly-lit lobby. A rusty 10-candle chandelier 
        hangs swaying, secured to the ancient ceiling by only a frayed strand of old 
        rope. Cobwebs and their artisans--black spiders with hairy, orange legs--
        litters the nooks and crannies. Several doors extend from this room, each leading 
        into a maze of rooms and studies. One door in particular catches your eye. 
        This door, nestled awkwardly into a corner is barred tightly from the outside. 
        It is easy enough to unlatch, but it was likely barricaded this way for a reason. 
        Finally, a set of staircases lies across from you, ascending into a fog of 
        blackness.
	]]

	choose({"unbardoor"})
end

unbardoor_ = "Unbar the door"
function unbardoor()
    p [[
        You approach the barred door with quick strides and carefully remove the 
        heavy iron bar holding the door shut. Now that you are this close, you notice 
        rather large scratch marks plastered all over the wood. This may not be the 
        smartest idea...
    ]]

    choose({
        "enterunbarreddoor",
        "bardoor"
    })
end

bardoor_ = "Bar the door"
function bardoor()
    message("You reassure yourself that nothing good can come from this and replace the iron bar before backing away.")
    switchto("foyer")
end

enterunbarreddoor_ = "Enter the unbarred door"
function enterunbarreddoor()
    p [[
        You shake any cowardice you have and reason that there is no risk without 
        reward. In a burst of bravado, you swing open the door and descend the small 
        flight of stairs. At the bottom of the stairs, you find yourself in a long, damp hallway 
        lined with torches. A reinforced iron door rests at the end. Silence lingers 
        uncomfortably. It is too quiet.
    ]]

    choose({"approachirondoor", "ascendtofoyer"})
end

ascendtofoyer_ = "Return to foyer"
function ascendtofoyer()
    message("The unnatural environment causes your bravery to wane. Keeping your eyes ahead, you step backwards a few strides before wheeling around completely to climb the stairs.")
    switchto("bardoor")
end