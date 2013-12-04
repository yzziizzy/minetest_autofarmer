 -- [x][z] -- y assumed to be 0
local fastcross = {
	[1]={
		[0]={x=0,y=0,z=-1}},
	[-1]={
		[0]={x=0,y=0,z=1}},
	[0]={
		[1]={x=-1,y=0,z=0},
		[-1]={x=1,y=0,z=0}}
	}

local function get_planter_region(pos, size)
	local node     = minetest.get_node(pos)
	local back_dir = minetest.facedir_to_dir(node.param2)
	
	local sideways = fastcross[back_dir.x][back_dir.z]
--	for key,value in pairs(meh) do print(key,value) end
	
	local left = vector.add(pos, vector.multiply(sideways, 2))
	left = vector.add(left, back_dir)
	local far = vector.add(pos, vector.multiply(sideways, -2))
	far = vector.add(far, vector.multiply(back_dir, 20))
	far = vector.add(far, {x=0,y=-1,z=0})
	
	local minx = math.min(far.x, left.x)
	local maxx = math.max(far.x, left.x)
	local minz = math.min(far.z, left.z)
	local maxz = math.max(far.z, left.z)
	
	return 
		{x=minx,y=far.y,z=minz},
		{x=maxx,y=left.y,z=maxz}
	
end






local function find_next_plant_pos(data, area, minp, maxp)
	local c_air = minetest.get_content_id("air")
	local c_weed = minetest.get_content_id("farming:weed")
	local c_soil = minetest.get_content_id("farming:soil")
	local c_soil_wet = minetest.get_content_id("farming:soil_wet")


	for z = minp.z, maxp.z do
	for x = minp.x, maxp.x do
		local above = data[area:index(x, maxp.y, z)]
		if above == c_air or above == c_weed then
			local below = data[area:index(x, minp.y, z)]
			if below == c_soil or below == c_soil_wet then
				return vector.new(x, maxp.y, z)
			end
		end
	end
	end
end





local seeds_nodes = {
	["farming:seed_wheat"]= "farming:wheat_1",
	["farming:seed_cotton"]= "farming:cotton_1",
	["farming:pumpkin_seed"]="farming:pumpkin_1",
	["farming_plus:rhubarb_seed"]= "farming_plus:rhubarb_1",
	["farming_plus:strawberry_seed"]="farming_plus:strawberry_1",
	["farming_plus:potato_seed"]="farming_plus:potatoe_1",
	["farming_plus:tomato_seed"]="farming_plus:tomato_1",
	["farming_plus:orange_seed"]="farming_plus:orange_1",
	["farming_plus:carrot_seed"]="farming_plus:carrot_1"
}




minetest.register_abm({
	nodenames = {"autofarmer:planter_active"},
	interval = 2,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta  = minetest.get_meta(pos)
		local inv   = meta:get_inventory()
		local p1,p2 = get_planter_region(pos, size)
		
		local vm = VoxelManip()
		local e1, e2 = vm:read_from_map(p1, p2)
		local area = VoxelArea:new({MinEdge=e1, MaxEdge=e2})
		local data = vm:get_data()
		
		local plantp = find_next_plant_pos(data, area, p1, p2)
		
		if plantp == nil then
-- 			print("no planting spots available")
			-- deactivate planter
			hacky_swap_node(pos, "autofarmer:planter")
			return
		end
		
		-- get seed from inv
		local plantname = nil
		local stackindex = nil
		
		localinv = inv:get_list("src")
		if localinv ~= nil then 
			for key,value in pairs(localinv) do 
				plantname = seeds_nodes[value:get_name()]
				stackindex = key
				if plantname ~= nil then break end
			end
		else
			return
		end
		
		
		if plantname == nil then
			-- no seeds left
			return
		end
		
		-- set plant
		minetest.env:set_node(plantp, {name=plantname})
		
		-- decrement seed stack
		local src = inv:get_stack("src", stackindex)
		src:take_item()
		inv:set_stack("src", stackindex, src)
		
	end
})


minetest.register_node("autofarmer:planter", {
	description = "Auto Planter",
	tiles = {"technic_brass_block.png", "technic_brass_block.png",
	         "technic_brass_block.png", "technic_brass_block.png",
	         "technic_brass_block.png^farming_tool_steelhoe.png", "technic_brass_block.png"},
	paramtype2 = "facedir",
	groups = {cracky=2, tubedevice=1, tubedevice_receiver=1,mesecon_effector_off = 1,mesecon = 2},
	tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("src", stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("src", stack)
		end,
		connect_sides = {top = 1},
	},
	mesecons = {effector = {
		action_on = function (pos, node)
			hacky_swap_node(pos, "autofarmer:planter_active")
		end
	}},
	on_construct = function(pos)
		local size = 8
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Planter")
		meta:set_string("formspec", "invsize[8,7;]list[current_name;src;2,0;4,2;]list[current_player;main;0,3;8,4;]")
		
		
		local inv = meta:get_inventory()
		inv:set_size("src", size)
	end,
	
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if not inv:is_empty("src") then
			minetest.chat_send_player(player:get_player_name(),
					"Machine cannot be removed because it is not empty")
			return false
		else
			return true
		end
	end,
	on_punch = function(pos) 
		hacky_swap_node(pos, "autofarmer:planter_active")
	end,
	
	after_place_node = function(pos, placer, itemstack)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		tube_scanforobjects(pos)
	end,
	after_dig_node = tube_scanforobjects,
	on_receive_fields = harvester_receive_fields,
})	
	
	
	
minetest.register_node("autofarmer:planter_active", {
	description = "Auto Planter",
	tiles = {"technic_brass_block.png", "technic_brass_block.png",
	         "technic_brass_block.png", "technic_brass_block.png",
	         "technic_brass_block.png^farming_tool_bronzehoe.png", "technic_brass_block.png"},
	paramtype2 = "facedir",
	groups = {cracky=2, tubedevice=1, not_in_creative_inventory=1,tubedevice_receiver=1,mesecon = 2},
	tube = {
		insert_object = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:add_item("src", stack)
		end,
		can_insert = function(pos, node, stack, direction)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return inv:room_for_item("src", stack)
		end,
		connect_sides = {top = 1},
	},
	mesecons = {effector = {
		action_off = function (pos, node)
			hacky_swap_node(pos, "autofarmer:planter")
		end
	}},
	on_construct = function(pos)
		local size = 8
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Planter (Active)")
		meta:set_string("formspec", "invsize[8,7;]list[current_name;src;2,0;4,2;]list[current_player;main;0,3;8,4;]")
		
		
		local inv = meta:get_inventory()
		inv:set_size("src", size)
	end,
	on_punch = function(pos) 
		hacky_swap_node(pos, "autofarmer:planter")
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if not inv:is_empty("src") then
			minetest.chat_send_player(player:get_player_name(),
					"Machine cannot be removed because it is not empty")
			return false
		else
			return true
		end
	end,
	after_place_node = function(pos, placer, itemstack)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name())
		tube_scanforobjects(pos)
	end,
	after_dig_node = tube_scanforobjects,
	on_receive_fields = harvester_receive_fields,
})


minetest.register_craft({
	recipe = {
		{"technic:brass_ingot", "pipeworks:tube_000000",    "technic:brass_ingot"},
		{"technic:brass_ingot", "default:diamond",     "technic:brass_ingot"},
		{"technic:brass_ingot", "default:steel_ingot", "technic:brass_ingot"}},
	output = "autofarmer:planter",
})
