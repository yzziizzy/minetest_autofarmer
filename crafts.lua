-- crafts for autofarmer mod


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
		{"technic:MV_cable", "moreores:tin_block", "pipeworks:pipe_1_empty"}},
	output = "autofarmer:harvester",
})

-- minetest.register_craft({
-- 	recipe = {
-- 		{"default:dirt", "default:sapling",           "default:dirt"},
-- 		{"default:bronzeblock", "technic:motor",    "default:bronzeblock"},
-- 		{"default:bronzeblock", "technic:MV_cable", "default:bronzeblock"}},
-- 	output = "autofarmer:planter",
-- })