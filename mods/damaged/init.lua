--------------------------------------------------------------------------------------------
----------------------------------- Damage ver: 1.0 :D -------------------------------------
--------------------------------------------------------------------------------------------
--Mod by Pinkysnowman                                                                     --
--©2015 GNU LGPL v2.1                                                                     --
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

if minetest.get_modpath("game") then --Loads the epicnode game version of this code if available.
	print("[MOD] \"damaged\" will not be loaded, EpicNode game detected!")
	return
end

game = {}

local function number_to_texturestring(num,color)
	if not color then
		color = "#ffffff:255"
	end
	num = tostring(math.floor(num))
	local split={}
	for i in num:gmatch('%d') do
    	split[#split+1]=i
	end
	for i = 1, #split do
		split[i] = ((18*i)-18)..",0=game_num_"..split[i]..".png:"
	end
	return "([combine:"..(18*(#split)).."x24:"..table.concat(split)..")^[makealpha:0,0,0^[colorize:"..color
end

function game.hp_loss(pos, damage, color)
	if damage > 0 then
		color = color or "#00bb00:200"
	else
		color = color or "#bb0000:200"
	end
	pos.y = pos.y + 2
	minetest.add_particlespawner({
		amount = 1,
		time = 1,
		minpos = pos,
		maxpos = pos,
		minvel = {x = 0, y = 1, z = 0},
		maxvel = {x = 0,  y = 1,  z = 0},
		minacc = {x = 0, y = 0, z = 0},
		maxacc = {x = 0, y = 0, z = 0},
		minexptime = 1,
		maxexptime = 1,
		minsize = 5,
		maxsize = 5,
		texture = number_to_texturestring(damage, color)
	})
end

minetest.after(1,function()
	minetest.register_on_player_hpchange(function(player, hp_change)
		local pos =  player:getpos()
		game.hp_loss(pos, hp_change)
		return 0
	end)
	--minetest.register_on_player
end)

print("[MOD] \"damaged\" is loaded! ©2016 Pinkysnowman")
