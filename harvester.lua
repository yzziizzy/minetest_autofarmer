
-- EDITED BY HarrierJack
-- fixed syntax + spelling errors
-- fixed old texture references



-- borrowed function from technic
local S = technic.getter


local harvester_length = 30 -- How long the row will be
local harvester_row_width      = 1 -- how many blocks each way from the center. 1 = 3 block width, 2 = 5 block width.

-- TEST
local harvester_dig_above_nodes = 15
local harvester_max_depth = 0


local function get_label(meta)
	if meta:get_int("enabled") == 1 then
		return "Disable"
	else return "Enable" end
end


local function get_harvester_formspec(size, label)
	return "size[3,1.5]"..
		"field[1,0.5;2,1;size;Radius;"..size.."]"..
		"button[0,1;3,1;toggle;"..label.."]"
end

local function harvester_receive_fields(pos, formname, fields, sender)
	if fields.quit then return end
	
	local meta = minetest.get_meta(pos)
	--local size = tonumber(fields.size)

	if fields.toggle then
		if meta:get_int("enabled") == 0 then
			meta:set_int("enabled", 1)
		else
			meta:set_int("enabled", 0)
		end
	end

	
	if string.find(fields.size, "^[0-9]+$") then
		local size = tonumber(fields.size)

		if size < 100 then	
			-- Smallest size is 2. Anything less is asking for trouble.
			-- Largest is 8. It is a matter of pratical node handling.
		--	size = math.max(size, 2)
		--	size = math.min(size, 8)

			if meta:get_int("size") ~= size then
				meta:set_int("size", size)
				meta:set_string("formspec", get_harvester_formspec(size, get_label(meta)))
			end
			
			meta:set_string("formspec", get_harvester_formspec(size, get_label(meta)))
		end	

	end
	
	
	
	
end

local function get_harvester_center(pos, size)
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
	-- local c_air = minetest.get_content_id("air")
	-- local c_test = minetest.get_content_id("farming:wheat_1")

	for y = center.y + harvester_dig_above_nodes, dig_y - 1, -1 do
	for z = center.z - size, center.z + size do
	for x = center.x - size, center.x + size do
				
		-- check if node on pos(x,y,z) is allowed for diggin e.a. in harvester_dig_node
		local nname = minetest.get_name_from_content_id(data[area:index(x, y, z)])				
		if autofarmer.harvester_dig_nodes[nname] then
				-- harvest allowed
				return vector.new(x, y, z)
		end
				
				-- TODO DELETE old lines, did not discriminate and only checked for air
		-- if data[area:index(x, y, z)] ~= c_air and data[area:index(x, y, z)] ~= c_test then
			-- return vector.new(x, y, z)
		--end
				
				
	end
	end
	end
end

local function harvester_dig(pos, center)
	local meta = minetest.get_meta(pos)
	local drops = {}
	local dig_y = meta:get_int("dig_y")
	local owner = meta:get_int("owner")
	local size = meta:get_int("size")
	
	
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
		
		-- TODO probably check since it will be turned on again after power check / or do nothing?
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
		-- local tube_item = tube_item(vector.new(pos), item)
		-- tube_item:get_luaentity().start_pos = vector.new(pos)
		-- tube_item:setvelocity(vector.new(0, 1, 0))
		-- tube_item:setacceleration({x=0, y=0, z=0})
		
		technic.tube_inject_item(pos, pos, vector.new(0, 1, 0), item)
		
		
	end
end


local function set_harvester_demand(meta)
	local prefix = meta:get_string("power_flag")
	local machine_name = S("%s Harvester"):format(prefix)
	local harvester_demand
	
	-- get the right values for the right current
	if prefix == "LV" then harvester_demand = autofarmer.LV_harvester_demand end
	if prefix == "MV" then harvester_demand = autofarmer.MV_harvester_demand end
	if prefix == "HV" then harvester_demand = autofarmer.HV_harvester_demand end
	
	if meta:get_int("enabled") == 0 then
		meta:set_int(prefix.."_EU_demand", 0)
		meta:set_string("infotext", S("%s Disabled"):format(machine_name))
	else
		meta:set_int(prefix.."_EU_demand", harvester_demand)
		meta:set_string("infotext", S(meta:get_int(prefix.."_EU_input") >= harvester_demand and "%s Active" or "%s Unpowered"):format(machine_name))
	end
	
end


-- function called by technic mod
local function harvester_run(pos, node)
	local meta = minetest.get_meta(pos)	
	local prefix = meta:get_string("power_flag")
	
	-- create delay/chance so not every second something is harvested
	if math.random(4) == 1 then	
		if meta:get_int("enabled") == 1 and meta:get_int(prefix.."_EU_input") >= meta:get_int(prefix.."_EU_demand") then
			-- do harvesting work	
			local drops = harvester_dig(pos, get_harvester_center(pos, meta:get_string("size")))	
			send_items(drops, pos, node)
		end
	
	end	
		
	set_harvester_demand(meta)
end
	

local function autofarmer_delay()
	
	return math.random(nr)
	
end



minetest.register_node("autofarmer:harvester", {
	description = "MV Harvester",
	tiles = {"moreores_tin_block.png", "moreores_tin_block.png",
	         "moreores_tin_block.png", "moreores_tin_block.png",
	         "moreores_tin_block.png^farming_tool_steelhoe.png", "moreores_tin_block.png"},
	paramtype2 = "facedir",
	groups = {cracky=2, tubedevice=1, technic_machine=1, technic_mv=1},
	connect_sides = {"bottom", "front", "left", "right"},
	tube = {
		connect_sides = {top = 1, front = 1},
	},
	on_construct = function(pos)
		local size = 4
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Harvester")
		meta:set_string("formspec", get_harvester_formspec(size, get_label(meta)))
		meta:set_int("size", size)
		meta:set_int("dig_y", pos.y)
		meta:set_string("power_flag", "MV")
	end,
	after_place_node = function(pos, placer, itemstack)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		pipeworks.scan_for_tube_objects(pos)
	end,
	after_dig_node = pipeworks.scan_for_tube_objects,
	on_receive_fields = harvester_receive_fields,
	technic_run = harvester_run,
		
		-- old test function
	on_punch = function(pos) 
		-- toggle on/off
		local meta = minetest.get_meta(pos)
		if meta:get_int("enabled") == 1 then
			meta:set_int("enabled", 0)
		else
			meta:set_int("enabled", 1)
		end
	end,
		
})



technic.register_machine("MV", "autofarmer:harvester", technic.receiver)

