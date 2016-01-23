--------------------------------------------------------------------------------------------
----------------------------------- Damage ver: 1.0 :D -------------------------------------
--------------------------------------------------------------------------------------------
--Mod by Pinkysnowman                                                                     --
--©2015 GNU LGPL v2.1                                                                     --
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

This mod adds a visiable temporary number above the player, entity or pos Upon damage.
Code automaticly adds this feature for players but it can be adde for any node or entity.

API

game.hp_loss(pos, damage, color)
	*pos: A standard minetest table style pos
	 ex => {x=1, y=1, z=1}
	*damage: The number of HP lost
	 ex => unsigned interger 0-29999
	*color: Standard minetest colorize string
	 ex => "#ff00ff:180" 
	 	!!! must be in quotes
	 	!!! optional

textures: CC BY-SA 3.0 Pinkysnowman