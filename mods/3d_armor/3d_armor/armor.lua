local armors_no_shields = { ["3d_armor:helmet_hardenedleather"] = true,["3d_armor:chestplate_hardenedleather"] = true,
							["3d_armor:leggings_hardenedleather"] = true,["3d_armor:boots_hardenedleather"] = true,
							["3d_armor:helmet_reinforcedleather"] = true,["3d_armor:chestplate_reinforcedleather"] = true,
							["3d_armor:leggings_reinforcedleather"] = true,["3d_armor:boots_reinforcedleather"] = true,
} -- modif MFF (crabman/24/06/2015)


ARMOR_INIT_DELAY = 1
ARMOR_INIT_TIMES = 1
ARMOR_BONES_DELAY = 1
ARMOR_UPDATE_TIME = 1
ARMOR_DROP = minetest.get_modpath("bones") ~= nil
ARMOR_DESTROY = false
ARMOR_LEVEL_MULTIPLIER = 1
ARMOR_HEAL_MULTIPLIER = 1
ARMOR_RADIATION_MULTIPLIER = 1
ARMOR_MATERIALS = {
	wood = "group:wood",
	cactus = "default:cactus",
	steel = "default:steel_ingot",
	bronze = "default:bronze_ingot",
	diamond = "default:diamond",
	gold = "default:gold_ingot",
	mithril = "default:mithril_ingot",
	crystal = "ethereal:crystal_ingot",
	-- Hunter armors (A déc-ommenter quand activation de l'armure au total)
	hardenedleather = "3d_armor:hardenedleather",
	reinforcedleather = "3d_armor:reinforcedleather",
	-- Warrior armors
	blackmithril = "3d_armor:blackmithril_ingot"
	-- Wizard armors
	--armor = "xxx",
	--armor = "xxx",
}
ARMOR_FIRE_PROTECT = minetest.get_modpath("ethereal") ~= nil
ARMOR_FIRE_NODES = {
	{"default:lava_source",     5, 8},
	{"default:lava_flowing",    5, 8},
	{"fire:basic_flame",        3, 4},
	{"fire:permanent_flame",    3, 4},
	{"ethereal:crystal_spike",  2, 1},
	{"ethereal:fire_flower",    2, 1},
	{"default:torch",           1, 1},
}

local skin_mod = nil
local inv_mod = nil

local modpath = minetest.get_modpath(ARMOR_MOD_NAME)
local worldpath = minetest.get_worldpath()
local input = io.open(modpath.."/armor.conf", "r")
if input then
	dofile(modpath.."/armor.conf")
	input:close()
	input = nil
end
input = io.open(worldpath.."/armor.conf", "r")
if input then
	dofile(worldpath.."/armor.conf")
	input:close()
	input = nil
end
if not minetest.get_modpath("ethereal") then
	ARMOR_MATERIALS.crystal = nil
end

armor = {
	timer = 0,
	elements = {"head", "torso", "legs", "feet"},
	physics = {"jump","speed","gravity"},
	formspec = "size[8,8.5]image[2,0.75;2,4;armor_preview]"
		.."list[current_player;main;0,4.5;8,4;]"
		.."list[current_player;craft;4,1;3,3;]"
		.."list[current_player;craftpreview;7,2;1,1;]"
		.."listring[current_player;main]"
		.."listring[current_player;craft]",
	textures = {},
	default_skin = "character",
	version = "0.4.5",
}

if minetest.get_modpath("inventory_plus") then
	inv_mod = "inventory_plus"
	armor.formspec = "size[8,8.5]button[0,0;2,0.5;main;Back]"
		.."image[2.5,0.75;2,4;armor_preview]"
		.."label[5,1;Level: armor_level]"
		.."label[5,1.5;Heal:  armor_heal]"
		.."label[5,2;Fire:  armor_fire]"
		.."label[5,2.5;Radiation:  armor_radiation]"
		.."list[current_player;main;0,4.5;8,4;]"
	if minetest.get_modpath("crafting") then
		inventory_plus.get_formspec = function(player, page)
		end
	end
elseif minetest.get_modpath("unified_inventory") then
	inv_mod = "unified_inventory"
	unified_inventory.register_button("armor", {
		type = "image",
		image = "inventory_plus_armor.png",
		tooltip = "Armor inventory",
		show_with = false, --Modif MFF (Crabman 30/06/2015)
	})
	unified_inventory.register_page("armor", {
		get_formspec = function(player, perplayer_formspec)
			local fy = perplayer_formspec.formspec_y
			local name = player:get_player_name()
			local formspec = "background[0.06,"..fy..";7.92,7.52;3d_armor_ui_form.png]"
				.."label[0,0;Armor]"
				.."list[detached:"..name.."_armor;armor;0,"..fy..";2,3;]"
				.."image[2.5,"..(fy - 0.25)..";2,4;"..armor.textures[name].preview.."]"
				.."label[5.0,"..(fy + 0.0)..";Level: "..armor.def[name].level.."]"
				.."label[5.0,"..(fy + 0.4)..";Heal:  "..armor.def[name].heal.."]"
				.."label[5.0,"..(fy + 0.8)..";Fire:  "..armor.def[name].fire.."]"
				.."label[5.0,"..(fy + 1.2)..";Radiation:  "..armor.def[name].radiation.."]"
				.."label[5.0,"..(fy + 1.6)..";Speed:  "..armor.def[name].speed.."]"
				.."label[5.0,"..(fy + 2)..";Jump:  "..armor.def[name].jump.."]"
				.."label[5.0,"..(fy + 2.4)..";Gravity:  "..armor.def[name].gravity.."]"
				.."listring[current_player;main]"
				.."listring[detached:"..name.."_armor;armor]"
			return {formspec=formspec}
		end,
	})
elseif minetest.get_modpath("inventory_enhanced") then
	inv_mod = "inventory_enhanced"
end

if minetest.get_modpath("skins") then
	skin_mod = "skins"
elseif minetest.get_modpath("simple_skins") then
	skin_mod = "simple_skins"
elseif minetest.get_modpath("u_skins") then
	skin_mod = "u_skins"
elseif minetest.get_modpath("wardrobe") then
	skin_mod = "wardrobe"
end

armor.def = {
	state = 0,
	count = 0,
}

armor.update_player_visuals = function(self, player)
	if not player then
		return
	end
	local name = player:get_player_name()
	if self.textures[name] then
		default.player_set_textures(player, {
			self.textures[name].skin,
			self.textures[name].armor,
			self.textures[name].wielditem,
		})
	end
end

armor.set_player_armor = function(self, player)
	local name, player_inv = armor:get_valid_player(player, "[set_player_armor]")
	if not name then
		return
	end
	local armor_texture = "3d_armor_trans.png"
	local armor_level = 0
	local armor_heal = 0
	local armor_fire = 0
	local armor_water = 0
	local armor_radiation = 0
	local state = 0
	local items = 0
	local elements = {}
	local textures = {}
	local physics_o = {speed=1,gravity=1,jump=1}
	local material = {type=nil, count=1}
	local preview = ""
	for _,v in ipairs(self.elements) do
		elements[v] = false
	end
	for i=1, 6 do
		local stack = player_inv:get_stack("armor", i)
		local item = stack:get_name()
		if stack:get_count() == 1 then
			local def = stack:get_definition()
			for k, v in pairs(elements) do
				if v == false then
					local level = def.groups["armor_"..k]
					if level then
						local texture = item:gsub("%:", "_")
						if texture:find("enchanted") then --MFF xdecor enchanting preview fix
							texture = texture:gsub("_enchanted", "")
							texture = texture:gsub("_strong", "")
							texture = texture:gsub("_speed", "")
						end
						table.insert(textures, texture..".png")
						if preview == "" then
							preview = texture .. "_preview.png"
						elseif stack:get_name():find("shield") then -- //MFF(Mg|09/05/15)
							preview = preview.. "^" .. texture.."_preview.png"
						else
							preview = texture .. "_preview.png^" .. preview
						end
						armor_level = armor_level + level
						state = state + stack:get_wear()
						items = items + 1
						armor_heal = armor_heal + (def.groups["armor_heal"] or 0)
						armor_fire = armor_fire + (def.groups["armor_fire"] or 0)
						armor_water = armor_water + (def.groups["armor_water"] or 0)
						armor_radiation = armor_radiation + (def.groups["armor_radiation"] or 0)
						for kk,vv in ipairs(self.physics) do
							local o_value = def.groups["physics_"..vv]
							if o_value then
								physics_o[vv] = physics_o[vv] + o_value
							end
						end
						local mat = string.match(item, "%:.+_(.+)$")
						if material.type then
							if material.type == mat then
								material.count = material.count + 1
							end
						else
							material.type = mat
						end
						elements[k] = true
					end
				end
			end
		end
	end
	if preview ~= "" then
		preview = "^" .. preview
	end
	preview = armor:get_preview(name) .. preview -- //MFF(Mg|09/05/15)
	if minetest.get_modpath("shields") then
		armor_level = armor_level * 0.9
	end
	if material.type and material.count == #self.elements then
		armor_level = armor_level * 1.1
	end
	armor_level = armor_level * ARMOR_LEVEL_MULTIPLIER
	armor_heal = armor_heal * ARMOR_HEAL_MULTIPLIER
	armor_radiation = armor_radiation * ARMOR_RADIATION_MULTIPLIER
	if #textures > 0 then
		armor_texture = table.concat(textures, "^")
	end
	local armor_groups = {fleshy=100}
	if armor_level > 0 then
		armor_groups.level = math.floor(armor_level / 20)
		armor_groups.fleshy = 100 - armor_level
		armor_groups.radiation = 100 - armor_radiation
	end
	player:set_armor_groups(armor_groups)
	--player:set_physics_override(physics_o)
	player_physics.set_stats(player, "3d_armor", {speed=physics_o.speed-1, jump=physics_o.jump-1, gravity=physics_o.gravity-1})
	pclasses.api.util.on_update(name)
	self.textures[name].armor = armor_texture
	self.textures[name].preview = preview
	self.def[name].state = state
	self.def[name].count = items
	self.def[name].level = armor_level
	self.def[name].heal = armor_heal
	self.def[name].jump = physics_o.jump
	self.def[name].speed = physics_o.speed
	self.def[name].gravity = physics_o.gravity
	self.def[name].fire = armor_fire
	self.def[name].water = armor_water
	self.def[name].radiation = armor_radiation
	self:update_player_visuals(player)
end

armor.update_armor = function(self, player)
	-- Legacy support: Called when armor levels are changed
	-- Other mods can hook on to this function, see hud mod for example 
end

armor.get_player_skin = function(self, name)
	local skin = nil
	if skin_mod == "skins" or skin_mod == "simple_skins" then
		skin = skins.skins[name]
	elseif skin_mod == "u_skins" then
		skin = u_skins.u_skins[name]
	elseif skin_mod == "wardrobe" then
		skin = string.gsub(wardrobe.playerSkins[name], "%.png$","")
	end
	return skin or armor.default_skin
end

armor.get_preview = function(self, name)
	if skin_mod == "skins" then
		return armor:get_player_skin(name).."_preview.png"
	elseif skin_mod == "u_skins"then
		return string.gsub(armor.textures[name].skin, ".png", "_preview.png")
	end
	return "character_preview.png"
end

armor.get_armor_formspec = function(self, name)
	if not armor.textures[name] then
		minetest.log("error", "3d_armor: Player texture["..name.."] is nil [get_armor_formspec]")
		return ""
	end
	if not armor.def[name] then
		minetest.log("error", "3d_armor: Armor def["..name.."] is nil [get_armor_formspec]")
		return ""
	end
	local formspec = armor.formspec.."list[detached:"..name.."_armor;armor;0,1;2,3;]"
	formspec = formspec:gsub("armor_preview", armor.textures[name].preview)
	formspec = formspec:gsub("armor_level", armor.def[name].level)
	formspec = formspec:gsub("armor_heal", armor.def[name].heal)
	formspec = formspec:gsub("armor_fire", armor.def[name].fire)
	formspec = formspec:gsub("armor_radiation", armor.def[name].radiation)
	formspec = formspec:gsub("armor_speed", armor.def[name].speed)
	formspec = formspec:gsub("armor_jump", armor.def[name].jump)
	formspec = formspec:gsub("armor_gravity", armor.def[name].gravity)
	return formspec
end

armor.update_inventory = function(self, player)
	local name = armor:get_valid_player(player, "[set_player_armor]")
	if not name or inv_mod == "inventory_enhanced" then
		return
	end
	if inv_mod == "unified_inventory" then
		if unified_inventory.current_page[name] == "armor" then
			unified_inventory.set_inventory_formspec(player, "armor")
		end
	else
		local formspec = armor:get_armor_formspec(name)
		if inv_mod == "inventory_plus" then
			formspec = formspec.."listring[current_player;main]"
				.."listring[detached:"..name.."_armor;armor]"
			local page = player:get_inventory_formspec()
			if page:find("detached:"..name.."_armor") then
				inventory_plus.set_inventory_formspec(player, formspec)
			end
		else
			player:set_inventory_formspec(formspec)
		end
	end
end

armor.get_valid_player = function(self, player, msg)
	msg = msg or ""
	if not player then
		minetest.log("error", "3d_armor: Player reference is nil "..msg)
		return
	end
	local name = player:get_player_name()
	if not name then
		minetest.log("error", "3d_armor: Player name is nil "..msg)
		return
	end
	local pos = player:getpos()
	local player_inv = player:get_inventory()
	local armor_inv = minetest.get_inventory({type="detached", name=name.."_armor"})
	if not pos then
		minetest.log("error", "3d_armor: Player position is nil "..msg)
		return
	elseif not player_inv then
		minetest.log("error", "3d_armor: Player inventory is nil "..msg)
		return
	elseif not armor_inv then
		minetest.log("error", "3d_armor: Detached armor inventory is nil "..msg)
		return
	end
	return name, player_inv, armor_inv, pos
end

-- Register Player Model

default.player_register_model("3d_armor_character.b3d", {
	animation_speed = 30,
	textures = {
		armor.default_skin..".png",
		"3d_armor_trans.png",
		"3d_armor_trans.png",
	},
	animations = {
		stand = {x=0, y=79},
		lay = {x=162, y=166},
		walk = {x=168, y=187},
		mine = {x=189, y=198},
		walk_mine = {x=200, y=219},
		sit = {x=81, y=160},
	},
})

-- Register Callbacks

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = armor:get_valid_player(player, "[on_player_receive_fields]")
	if not name or inv_mod == "inventory_enhanced" then
		return
	end
	if inv_mod == "inventory_plus" and fields.armor then
		local formspec = armor:get_armor_formspec(name)
		inventory_plus.set_inventory_formspec(player, formspec)
		return
	end
	for field, _ in pairs(fields) do
		if string.find(field, "skins_set") then
			minetest.after(0, function(player)
				local skin = armor:get_player_skin(name)
				armor.textures[name].skin = skin..".png"
				armor:set_player_armor(player)
			end, player)
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	default.player_set_model(player, "3d_armor_character.b3d")
	local name = player:get_player_name()
	local player_inv = player:get_inventory()
	local armor_inv = minetest.create_detached_inventory(name.."_armor", {
		on_put = function(inv, listname, index, stack, player)
			player:get_inventory():set_stack(listname, index, stack)
			armor:set_player_armor(player)
			armor:update_inventory(player)
		end,
		on_take = function(inv, listname, index, stack, player)
			player:get_inventory():set_stack(listname, index, nil)
			armor:set_player_armor(player)
			armor:update_inventory(player)
		end,
		on_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			local plaver_inv = player:get_inventory()
			local old_stack = inv:get_stack(from_list, from_index)
			local stack = inv:get_stack(to_list, to_index)
			player_inv:set_stack(to_list, to_index, stack)
			player_inv:set_stack(from_list, from_index, old_stack)
			armor:set_player_armor(player)
			armor:update_inventory(player)
		end,
		allow_put = function(inv, listname, index, stack, player)
			--DEBUT modif MFF (crabman/24/06/2015)
			local name = stack:get_name()
			local player_inv = player:get_inventory()
			local size = player_inv:get_size(listname)
			if not ( (name:split(":")[1] == "3d_armor" and stack:get_definition().groups["armor_heal"]) or name:split(":")[1] == "shields") then
				return 0
			end

			-- if player class != item class
			if not pclasses.api.util.can_have_item(player:get_player_name(), name) then
				return 0
			end

			--MFF (crabman/27/11/2015) no same item type. *helmet*
			local ptype = name:split(":")[2]:split("_")[1]
			if ptype == "enchanted" then
			   ptype = name:split(":")[2]:split("_")[2]
			end
			for i=1, size do
				local stack = player_inv:get_stack(listname, i)
				if stack:get_count() > 0 then
					if stack:get_name():find(ptype) then
						return 0
					end
				end
			end

			if name:find("shield") then
				for i=1, size do
					local stack = player_inv:get_stack(listname, i)
					if stack:get_count() > 0 then
						if armors_no_shields[stack:get_name()] ~= nil then
							return 0
						end
					end
				end
			else
				if armors_no_shields[name] ~= nil then
					for i=1, size do
						local stack = player_inv:get_stack(listname, i)
						if stack:get_count() > 0 then
							if stack:get_name():find("shields:") then
								return 0
							end
						end
					end
				end
			end
			--FIN modif MFF (crabman/24/06/2015)
			return 1
		end,
		allow_take = function(inv, listname, index, stack, player)
			return stack:get_count()
		end,
		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			return count
		end,
	})
	if inv_mod == "inventory_plus" then
		inventory_plus.register_button(player,"armor", "Armor")
	end
	armor_inv:set_size("armor", 6)
	player_inv:set_size("armor", 6)
	for i=1, 6 do
		local stack = player_inv:get_stack("armor", i)
		armor_inv:set_stack("armor", i, stack)
	end	
	armor.def[name] = {
		state = 0,
		count = 0,
		level = 0,
		heal = 0,
		jump = 1,
		speed = 1,
		gravity = 1,
		fire = 0,
		water = 0,
		radiation = 0,
	}
	armor.textures[name] = {
		skin = armor.default_skin..".png",
		armor = "3d_armor_trans.png",
		wielditem = "3d_armor_trans.png",
		preview = armor.default_skin.."_preview.png",
	}
	if skin_mod == "skins" then
		local skin = skins.skins[name]
		if skin and skins.get_type(skin) == skins.type.MODEL then
			armor.textures[name].skin = skin..".png"
		end
	elseif skin_mod == "simple_skins" then
		local skin = skins.skins[name]
		if skin then
			armor.textures[name].skin = skin..".png"
		end
	elseif skin_mod == "u_skins" then
		local skin = u_skins.u_skins[name]
		if skin and u_skins.get_type(skin) == u_skins.type.MODEL then
			armor.textures[name].skin = skin..".png"
		end
	elseif skin_mod == "wardrobe" then
		local skin = wardrobe.playerSkins[name]
		if skin then
			armor.textures[name].skin = skin
		end
	end
	if minetest.get_modpath("player_textures") then
		local filename = minetest.get_modpath("player_textures").."/textures/player_"..name
		local f = io.open(filename..".png")
		if f then
			f:close()
			armor.textures[name].skin = "player_"..name..".png"
		end
	end
	for i=1, ARMOR_INIT_TIMES do
		minetest.after(ARMOR_INIT_DELAY * i, function(player)
			armor:set_player_armor(player)
			if not inv_mod then
				armor:update_inventory(player)
			end
		end, player)
	end
end)
--[[
if ARMOR_DROP == true or ARMOR_DESTROY == true then
	armor.drop_armor = function(pos, stack)
		local obj = minetest.add_item(pos, stack)
		if obj then
			obj:setvelocity({x=math.random(-1, 1), y=5, z=math.random(-1, 1)})
		end
	end
	minetest.register_on_dieplayer(function(player)
		local name, player_inv, armor_inv, pos = armor:get_valid_player(player, "[on_dieplayer]")
		if not name then
			return
		end
		local drop = {}
		for i=1, player_inv:get_size("armor") do
			local stack = armor_inv:get_stack("armor", i)
			-- Modification for MFF
			if stack:get_count() > 0 and (not pclasses.data.reserved_items[armor_inv:get_stack("armor", i):get_name()] or
	            not pclasses.api.util.can_have_item(name, armor_inv:get_stack("armor", i):get_name())) then
				table.insert(drop, stack)
				armor_inv:set_stack("armor", i, nil)
				player_inv:set_stack("armor", i, nil)
			end
		end
		armor:set_player_armor(player)
		if inv_mod == "unified_inventory" then
			unified_inventory.set_inventory_formspec(player, "craft")
		elseif inv_mod == "inventory_plus" then
			local formspec = inventory_plus.get_formspec(player,"main")
			inventory_plus.set_inventory_formspec(player, formspec)
		else
			armor:update_inventory(player)
		end
		if ARMOR_DESTROY == false then
			minetest.after(ARMOR_BONES_DELAY, function()
				local node = minetest.get_node(vector.round(pos))
				-- Modification for MFF
				if node and node.name == "bones:bones" then
					local meta = minetest.get_meta(vector.round(pos))
					local owner = meta:get_string("owner")
					local inv = meta:get_inventory()
					for _,stack in ipairs(drop) do
						if name == owner and inv:room_for_item("main", stack) then
							inv:add_item("main", stack)
						else
							armor.drop_armor(pos, stack)
						end
					end
				else
					for _,stack in ipairs(drop) do
						armor.drop_armor(pos, stack)
					end
				end
			end)
		end
	end)
end
--]]

minetest.register_on_player_hpchange(function(player, hp_change)
	local name, player_inv, armor_inv = armor:get_valid_player(player, "[on_hpchange]")
	if name and hp_change < 0 then

		-- used for insta kill tools/commands like /kill (doesnt damage armor)
		if hp_change < -100 then
			return hp_change
		end

		local heal_max = 0
		local state = 0
		local items = 0
		for i=1, 6 do
			local stack = player_inv:get_stack("armor", i)
			if stack:get_count() > 0 then
				local use = stack:get_definition().groups["armor_use"] or 0
				local heal = stack:get_definition().groups["armor_heal"] or 0
				local item = stack:get_name()
				stack:add_wear(use)
				armor_inv:set_stack("armor", i, stack)
				player_inv:set_stack("armor", i, stack)
				state = state + stack:get_wear()
				items = items + 1
				if stack:get_count() == 0 then
					local desc = minetest.registered_items[item].description
					if desc then
						minetest.chat_send_player(name, "Your "..desc.." got destroyed!")
					end
					armor:set_player_armor(player)
					armor:update_inventory(player)
				end
				heal_max = heal_max + heal
			end
		end
		armor.def[name].state = state
		armor.def[name].count = items
		heal_max = heal_max * ARMOR_HEAL_MULTIPLIER
		if heal_max > math.random(100) then
			hp_change = 0
		end
		armor:update_armor(player)
	end
	return hp_change
end, true)

-- Fire Protection and water breating, added by TenPlus1

if ARMOR_FIRE_PROTECT == true then
	-- override hot nodes so they do not hurt player anywhere but mod
	for _, row in pairs(ARMOR_FIRE_NODES) do
		if minetest.registered_nodes[row[1]] then
			minetest.override_item(row[1], {damage_per_second = 0})
		end
	end
else
	minetest.log("info", "[3d_armor] Fire Nodes disabled")
end

function armor_step()
	for _,player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pos = player:getpos()
		local hp = player:get_hp()
		-- water breathing
		if name and armor.def[name].water > 0 then
			if player:get_breath() < 10 then
				player:set_breath(10)
			end
		end
		-- fire protection
		if ARMOR_FIRE_PROTECT == true
		and name and pos and hp then
			pos.y = pos.y + 1.4 -- head level
			local node_head = minetest.get_node(pos).name
			pos.y = pos.y - 1.2 -- feet level
			local node_feet = minetest.get_node(pos).name
			-- is player inside a hot node?
			for _, row in pairs(ARMOR_FIRE_NODES) do
				-- check fire protection, if not enough then get hurt
				if row[1] == node_head or row[1] == node_feet then
					if hp > 0 and armor.def[name].fire < row[2] then
						hp = hp - row[3] * ARMOR_UPDATE_TIME
						player:set_hp(hp)
						break
					end
				end
			end
		end
	end
	minetest.after(ARMOR_UPDATE_TIME, armor_step)
end

-- Launch once started
minetest.after(0, armor_step)


-- kill player when command issued
minetest.register_chatcommand("kill", {
	params = "<name>",
	description = "Kills player instantly",
	func = function(name, param)
		local player = minetest.get_player_by_name(name)
		if player then
			player:set_hp(-1001)
		end
	end,
})
