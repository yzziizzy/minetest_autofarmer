
-- see if a water embedded tube is possible...


pipeworks.register_tube("pipeworks:watery_tube", {
			description = "High Priority Tube Segment",
			inventory_image = "pipeworks_tube_inv.png^[colorize:" .. color,
			plain = { "pipeworks_tube_plain.png^[colorize:" .. color },
			noctr = { "pipeworks_tube_noctr.png^[colorize:" .. color },
			ends = { "pipeworks_tube_end.png^[colorize:" .. color },
			short = "pipeworks_tube_short.png^[colorize:" .. color,
			node_def = {
				tube = { priority = 150 } -- higher than tubedevices (100)
			},
	})