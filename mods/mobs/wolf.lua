-- Wolf (from Mobs_plus)

mobs:register_mob("mobs:wolf", {
	type = "monster",
	hp_min = 15,
	hp_max = 20,
	collisionbox = {-0.4, -0.01, -0.4, 0.4, 1, 0.4},
	visual = "mesh",
	mesh = "mobs_wolf.x",
	--textures = {"mobs_wolf.png"},
	available_textures = {
		total = 1,
		texture_1 = {"mobs_wolf.png"},
	},
	--visual_size = {x=1, y=1},
	makes_footstep_sound = true,
	view_range = 20,
	walk_velocity = 3,
	run_velocity = 5,
	damage = 4,
	drops = {
		{name = "mobs:meat_raw",
		chance = 1,
		min = 2,
		max = 3,},
		{name = "maptools:copper_coin",
		chance = 2,
		min = 1,
		max = 4,},
	},
	light_resistant = false,
	armor = 200,
	drawtype = "front",
	water_damage = 1,
	lava_damage = 5,
	light_damage = 2,
	on_rightclick = nil,
	attack_type = "dogfight",
	animation = {
		speed_normal = 15,
		speed_run = 15,
		stand_start = 0,
		stand_end = 14,
		walk_start = 15,
		walk_end = 38,
		run_start = 40,
		run_end = 63,
		punch_start = 40,
		punch_end = 63,
	},
	sounds = {
		random = "mobs_wolf",
	},
	jump = true,
	step = 1,
	blood_texture = "mobs_blood.png",
})
mobs:register_spawn("mobs:wolf", {"default:dirt_with_grass"}, 3, -1, 20000, 2, 31000)
