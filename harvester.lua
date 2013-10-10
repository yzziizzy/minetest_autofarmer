 

minetest.register_craft({
	recipe = {
		{"default:dirt", "default:sapling",           "default:dirt"},
		{"default:tinblock", "technic:motor",    "default:tinblock"},
		{"technic:MV_cable", "default:tinblock", "pipeworks:tube"}},
	output = "autofarmer:harvester",
})
-- minetest.register_craft({
-- 	recipe = {
-- 		{"default:dirt", "default:sapling",           "default:dirt"},
-- 		{"default:bronzeblock", "technic:motor",    "default:bronzeblock"},
-- 		{"default:bronzeblock", "technic:MV_cable", "default:bronzeblock"}},
-- 	output = "autofarmer:planter",
-- })

local harvester_length = 30 -- How long the row will be
local harvester_row_width      = 1 -- how many blocks each way from the center. 1 = 3 block width, 2 = 5 block width.

local harvester_dig_nodes = {
	{"farming:weed" = true },
	{"farming:cotton_8" = true },
	{"farming:cheat_8" = true },
	{"farming:carrot" = true },
	{"farming:rhubarb" = true },
	{"farming:potatoe" = true },
	{"farming:tomato" = true },
	{"farming:strawberry" = true },
	{"farming:potatoe" = true },
	


local function get_harvester_formspec(size)
	return "size[3,1.5]"..
		"field[1,0.5;2,1;size;Radius;"..size.."]"..
		"button[0,1;3,1;toggle;Enable/Disable]"
end

local function harvester_receive_fields(pos, formname, fields, sender)
	local meta = minetest.get_meta(pos)
	local size = tonumber(fields.size)

	if fields.toggle then
		if meta:get_int("enabled") == 0 then
			meta:set_int("enabled", 1)
		else
			meta:set_int("enabled", 0)
		end
	end

	-- Smallest size is 2. Anything less is asking for trouble.
	-- Largest is 8. It is a matter of pratical node handling.
	size = math.max(size, 2)
	size = math.min(size, 8)

	if meta:get_int("size") ~= size then
		meta:set_int("size", size)
		meta:set_string("formspec", get_harvester_formspec(size))
	end
end

local function get_harvester_start(pos, size)
	local node     = minetest.get_node(pos)
	local back_dir = minetest.facedir_to_dir(node.param2)
	local relative_center = vector.multiply(back_dir, size + 1)
	local center = vector.add(pos, relative_center)
	return center
end

local function gen_next_digpos(center, digpos, size)
	digpos.x = digpos.x + 1
	if digpos.x > center.x + size then
		digpos.x = center.x - size
		digpos.z = digpos.z + 1
	end
	if digpos.z > center.z + size then
		digpos.x = center.x - size
		digpos.z = center.z - size
		digpos.y = digpos.y - 1
	end
end

local function find_next_digpos(data, area, center, dig_y, size)
	local c_air = minetest.get_content_id("air")

	for y = center.y + harvester_dig_above_nodes, dig_y - 1, -1 do
	for z = center.z - size, center.z + size do
	for x = center.x - size, center.x + size do
		if data[area:index(x, y, z)] ~= c_air then
			return vector.new(x, y, z)
		end
	end
	end
	end
end

local function harvester_dig(pos, center, size)
	local meta = minetest.get_meta(pos)
	local drops = {}
	local dig_y = meta:get_int("dig_y")
	local owner = meta:get_int("owner")

	local vm = VoxelManip()
	local p1 = vector.new(
			center.x - size,
			center.y + harvester_dig_above_nodes,
			center.z - size)
	local p2 = vector.new(
			center.x + size,
			dig_y - 1, -- One node lower in case we have finished the current layer
			center.z + size)
	local e1, e2 = vm:read_from_map(p1, p2)
	local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
	local data = vm:get_data()

	local digpos = find_next_digpos(data, area, center, dig_y, size)

	if digpos then
		if digpos.y < pos.y - harvester_max_depth then
			meta:set_int("dig_y", digpos.y)
			return drops
		end
		if minetest.is_protected and minetest.is_protected(digpos, owner) then
			meta:set_int("enabled", 0)
			return
		end
		dig_y = digpos.y
		local node = minetest.get_node(digpos)
		drops = minetest.get_node_drops(node.name, "")
		minetest.dig_node(digpos)
		if minetest.get_node(digpos).name == node.name then
			-- We tried to dig something undigable like a
			-- filled chest. Notice that we check for a node
			-- change, not for air. This is so that we get drops
			-- from things like concrete posts with platforms,
			-- which turn into regular concrete posts when dug.
			drops = {}
		end
	elseif not (dig_y < pos.y - harvester_max_depth) then
		dig_y = dig_y - 16
	end

	meta:set_int("dig_y", dig_y)
	return drops
end

local function send_items(items, pos, node)
	for _, item in pairs(items) do
		local tube_item = tube_item(vector.new(pos), item)
		tube_item:get_luaentity().start_pos = vector.new(pos)
		tube_item:setvelocity(vector.new(0, 1, 0))
		tube_item:setacceleration({x=0, y=0, z=0})
	end
end

minetest.register_node("technic:harvester", {
	description = "Quarry",
	tiles = {"default_tin_block.png", "default_tin_block.png",
	         "default_tin_block.png", "default_tin_block.png",
	         "default_tin_block.png^default_tool_steelhoe.png", "default_tin_block.png"},
	paramtype2 = "facedir",
	groups = {cracky=2, tubedevice=1},
	tube = {
		connect_sides = {top = 1},
	},
	on_construct = function(pos)
		local size = 4
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Harvester")
		meta:set_string("formspec", get_harvester_formspec(4))
		meta:set_int("size", size)
		meta:set_int("dig_y", pos.y)
	end,
	after_place_node = function(pos, placer, itemstack)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		tube_scanforobjects(pos)
	end,
	after_dig_node = tube_scanforobjects,
	on_receive_fields = harvester_receive_fields,
})

minetest.register_abm({
	nodenames = {"autofarmer:harvester"},
	interval = 1,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.get_meta(pos)
		local size = meta:get_int("size")
		local eu_input = meta:get_int("MV_EU_input")
		local demand = 1000
		local center = get_harvester_center(pos, size)
		local dig_y = meta:get_int("dig_y")

		technic.switching_station_timeout_count(pos, "MV")

		if meta:get_int("enabled") == 0 then
			meta:set_string("infotext", "Harvester Disabled")
			meta:set_int("MV_EU_demand", 0)
			return
		end

		if eu_input < demand then
			meta:set_string("infotext", "Harvester Unpowered")
		elseif eu_input >= demand then
			meta:set_string("infotext", "Harvester Active")

			local items = harvester_dig(pos, center, size)
			send_items(items, pos, node)

			if dig_y < pos.y - harvester_max_depth then
				meta:set_string("infotext", "Harvester Finished")
			end
		end
		meta:set_int("MV_EU_demand", demand)
	end
})

technic.register_machine("MV", "autofarmer:harvester", technic.receiver)

