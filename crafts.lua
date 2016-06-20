-- crafts for autofarmer mod
<<<<<<< HEAD


-- TODO LV MV HV versions 
-- HV 22 kEU HV 10kEU LV 6kEU?




minetest.register_craft({
	recipe = {
		{"technic:brass_ingot", "pipeworks:one_way_tube",    "technic:brass_ingot"},
		{"technic:brass_ingot", "default:diamond",     "technic:brass_ingot"},
		{"technic:brass_ingot", "default:steel_ingot", "technic:brass_ingot"}},
	output = "autofarmer:planter",
})


minetest.register_craft({
	recipe = {
		{"default:dirt", "default:dirt",           "default:dirt"},
		{"moreores:tin_block", "technic:motor",    "moreores:tin_block"},
=======
-- feel free to edit


-- LV planter
minetest.register_craft({
	recipe = {
		{"default:copper_ingot", "pipeworks:one_way_tube", "default:copper_ingot"},
		{"moreores:tin_ingot", "mesecons_detector:node_detector_off", "moreores:tin_ingot"},
		{"default:copper_ingot", "moreores:tin_ingot", "default:copper_ingot"}},
	output = "autofarmer:lv_planter",
})



-- MV planter
minetest.register_craft({
	recipe = {
		{"default:bronze_ingot", "pipeworks:one_way_tube",    "default:bronze_ingot"},
		{"technic:brass_ingot", "mesecons_detector:node_detector_off",     "technic:brass_ingot"},
		{"default:bronze_ingot", "technic:brass_ingot", "default:bronze_ingot"}},
	output = "autofarmer:mv_planter",
})


-- HV planter
minetest.register_craft({
	recipe = {
		{"technic:stainless_steel_ingot", "pipeworks:one_way_tube",    "technic:stainless_steel_ingot"},
		{"technic:cast_iron_ingot", "mesecons_detector:node_detector_off",     "technic:cast_iron_ingot"},
		{"technic:stainless_steel_ingot", "technic:cast_iron_ingot", "technic:stainless_steel_ingot"}},
	output = "autofarmer:hv_planter",
})

-- TODO
minetest.register_craft({
	recipe = {
		{"default:dirt", "default:dirt", "default:dirt"},
		{"moreores:tin_block", "technic:motor", "moreores:tin_block"},
>>>>>>> 283629fde2971e8da1fc10873f64ff531e5319cb
		{"technic:MV_cable", "moreores:tin_block", "pipeworks:pipe_1_empty"}},
	output = "autofarmer:harvester",
})

<<<<<<< HEAD
-- minetest.register_craft({
-- 	recipe = {
-- 		{"default:dirt", "default:sapling",           "default:dirt"},
-- 		{"default:bronzeblock", "technic:motor",    "default:bronzeblock"},
-- 		{"default:bronzeblock", "technic:MV_cable", "default:bronzeblock"}},
-- 	output = "autofarmer:planter",
-- })
=======

>>>>>>> 283629fde2971e8da1fc10873f64ff531e5319cb
