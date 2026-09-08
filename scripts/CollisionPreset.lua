-- Local values: presets, presetsOrdered, DEFAULT_MASK, DEFAULT_MASK_STATIC, registerPreset
CollisionPreset = {}
if CollisionFlag == nil then
	printError("Cannot source \'CollisionPreset\' without \'CollisionFlag\'")
else
	local v_u_1_ = {}
	local v_u_2_ = {}
	local v3_ = CollisionFlag.CAMERA_BLOCKING
	local v4_ = CollisionFlag.GROUND_TIP_BLOCKING
	local v5_ = CollisionFlag.PLACEMENT_BLOCKING
	local v6_ = CollisionFlag.AI_BLOCKING
	local v7_ = CollisionFlag.PRECIPITATION_BLOCKING
	local v8_ = CollisionFlag.TERRAIN_DISPLACEMENT
	local v9_ = CollisionFlag.ANIMAL_POSITIONING
	local v10_ = CollisionFlag.ANIMAL_NAV_MESH_BLOCKING
	local v11_ = CollisionFlag.TRAFFIC_VEHICLE_BLOCKING
	local v_u_12_ = 4294967295 - bit32.bor(v3_, v4_, v5_, v6_, v7_, v8_, v9_, v10_, v11_)
	local v13_ = CollisionFlag.TERRAIN_DISPLACEMENT
	local v14_ = 4294967295 - bit32.bor(v13_)
	local function v23_(p15_, p16_, p17_, p18_)
		-- upvalues: (copy) v_u_1_, (copy) v_u_2_
		if string.upper(p15_) == p15_ then
			if v_u_1_[p15_] == nil then
				for v19_, v20_ in pairs(v_u_1_) do
					if v20_.group == p16_ and v20_.mask == p17_ then
						Logging.error("Collision Preset %q is identical to %q", p15_, v19_)
						return
					end
				end
				local v21_ = {
					["name"] = p15_,
					["group"] = p16_,
					["mask"] = p17_,
					["desc"] = p18_
				}
				v_u_1_[p15_] = v21_
				local v22_ = v_u_2_
				table.insert(v22_, v21_)
				return v_u_1_[p15_]
			end
			Logging.error("Collision Preset name %q already defined", p15_)
		else
			Logging.error("Collision Preset name needs to be all uppercase: %q", p15_)
		end
	end
	CollisionPreset.VEHICLE = v23_("VEHICLE", CollisionFlag.VEHICLE + CollisionFlag.CAMERA_BLOCKING, v_u_12_, "Vehicle main collisions")
	local v24_ = CollisionPreset
	local v25_ = CollisionFlag.VEHICLE + CollisionFlag.CAMERA_BLOCKING
	local v26_ = CollisionFlag.TERRAIN_DELTA
	v24_.VEHICLE_NO_TIP_ANY = v23_("VEHICLE_NO_TIP_ANY", v25_, bit32.bxor(v_u_12_, v26_), "Vehicle collision not colliding with terrain delta/tipany")
	CollisionPreset.EXACT_FILL_ROOT_NODE = v23_("EXACT_FILL_ROOT_NODE", CollisionFlag.FILLABLE, CollisionFlag.TRIGGER, "target shape for fill triggers and raycasts")
	CollisionPreset.FILL_TRIGGER = v23_("FILL_TRIGGER", CollisionFlag.TRIGGER, CollisionFlag.FILLABLE, "trigger for shapes using the FILLABLE-flag in their collision group")
	CollisionPreset.VEHICLE_TRIGGER = v23_("VEHICLE_TRIGGER", CollisionFlag.TRIGGER, CollisionFlag.VEHICLE, "trigger for shapes using the VEHICLE-flag in their collision group")
	CollisionPreset.DYN_OBJECT_TRIGGER = v23_("DYN_OBJECT_TRIGGER", CollisionFlag.TRIGGER, CollisionFlag.DYNAMIC_OBJECT, "trigger for shapes using the DYNAMIC_OBJECT-flag in their collision group")
	CollisionPreset.PLAYER_TRIGGER = v23_("PLAYER_TRIGGER", CollisionFlag.TRIGGER, CollisionFlag.PLAYER, "trigger for player characters")
	CollisionPreset.PLAYER_VEHICLE_TRIGGER = v23_("PLAYER_VEHICLE_TRIGGER", CollisionFlag.TRIGGER, CollisionFlag.PLAYER + CollisionFlag.VEHICLE, "trigger for players and vehicles")
	CollisionPreset.WOOD_TRIGGER = v23_("WOOD_TRIGGER", CollisionFlag.TRIGGER, CollisionFlag.TREE, "trigger for trees/logs")
	CollisionPreset.TREE = v23_("TREE", CollisionFlag.TREE + CollisionFlag.PLACEMENT_BLOCKING + CollisionFlag.AI_BLOCKING, v_u_12_)
	CollisionPreset.FORK = v23_("FORK", CollisionFlag.VEHICLE_FORK, v_u_12_)
	local v27_ = CollisionPreset
	local v28_ = CollisionFlag.VEHICLE
	local v29_ = CollisionFlag.VEHICLE_FORK
	v27_.PALLET_FLOOR = v23_("PALLET_FLOOR", v28_, (bit32.bxor(v_u_12_, v29_)))
	local v30_ = CollisionPreset
	local v31_ = CollisionFlag.DYNAMIC_OBJECT
	local v32_ = CollisionFlag.VEHICLE_FORK
	v30_.BALE = v23_("BALE", v31_, (bit32.bxor(v_u_12_, v32_)))
	local v33_ = CollisionPreset
	local v34_ = CollisionFlag.TRAFFIC_VEHICLE + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.AI_BLOCKING
	local v35_ = CollisionFlag.TREE
	local v36_ = CollisionFlag.VEHICLE
	local v37_ = CollisionFlag.VEHICLE_FORK
	local v38_ = CollisionFlag.DYNAMIC_OBJECT
	local v39_ = CollisionFlag.PLAYER
	local v40_ = CollisionFlag.ANIMAL
	v33_.TRAFFIC_VEHICLE = v23_("TRAFFIC_VEHICLE", v34_, (bit32.bor(v35_, v36_, v37_, v38_, v39_, v40_)))
	CollisionPreset.BUILDING = v23_("BUILDING", CollisionFlag.BUILDING + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.AI_BLOCKING + CollisionFlag.PLACEMENT_BLOCKING + CollisionFlag.GROUND_TIP_BLOCKING, v14_)
	CollisionPreset.PLACEABLE_BUILDING = v23_("PLACEABLE_BUILDING", CollisionFlag.BUILDING + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.AI_BLOCKING + CollisionFlag.PLACEMENT_BLOCKING, v14_)
	CollisionPreset.ROAD = v23_("ROAD", CollisionFlag.ROAD + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.PLACEMENT_BLOCKING + CollisionFlag.GROUND_TIP_BLOCKING + CollisionFlag.AI_DRIVABLE, v14_)
	CollisionPreset.ROAD_BRIDGE = v23_("ROAD_BRIDGE", CollisionFlag.ROAD + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.PLACEMENT_BLOCKING + CollisionFlag.GROUND_TIP_BLOCKING + CollisionFlag.AI_BLOCKING + CollisionFlag.PRECIPITATION_BLOCKING, v14_)
	CollisionPreset.WATER = v23_("WATER", CollisionFlag.WATER, 1, "Collision used by water planes to make it interact with players and vehicles")
	CollisionPreset.STATIC_OBJECT = v23_("STATIC_OBJECT", CollisionFlag.STATIC_OBJECT + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.AI_BLOCKING + CollisionFlag.PLACEMENT_BLOCKING + CollisionFlag.GROUND_TIP_BLOCKING, v14_)
	CollisionPreset.DYNAMIC_OBJECT = v23_("DYNAMIC_OBJECT", CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.AI_BLOCKING + CollisionFlag.PLACEMENT_BLOCKING + CollisionFlag.GROUND_TIP_BLOCKING, v_u_12_)
	CollisionPreset.TIP_BLOCKING_COL = v23_("TIP_BLOCKING_COL", CollisionFlag.GROUND_TIP_BLOCKING, 1)
	CollisionPreset.PLACEMENT_BLOCKING_COL = v23_("PLACEMENT_BLOCKING_COL", CollisionFlag.PLACEMENT_BLOCKING, 1)
	CollisionPreset.ANIMAL_POSITIONING_COL = v23_("ANIMAL_POSITIONING_COL", CollisionFlag.ANIMAL_POSITIONING, 1, "Collision used by animals in nav meshes to determine their y position/height")
	CollisionPreset.DEFAULT = v23_("DEFAULT", 0, v_u_12_)
	function CollisionPreset.init()
		-- upvalues: (copy) v_u_12_, (copy) v_u_2_
		if g_isDevelopmentVersion then
			local function v56_(_)
				-- upvalues: (ref) v_u_12_, (ref) v_u_2_
				local v41_ = XMLFile.create("CollisionMaskFlags", "", "collisionMaskFlags")
				v41_:addComment("collisionMaskFlags", "Warning: This file is exported from script and should not be edited manually")
				local v42_ = 0
				for v43_, v44_, _, v45_ in CollisionFlag.iteratorFlags() do
					local v46_ = string.format("collisionMaskFlags.flag(%d)", v42_)
					v41_:setInt(v46_ .. "#bit", v44_)
					v41_:setString(v46_ .. "#name", v43_)
					v41_:setString(v46_ .. "#desc", v45_.description)
					v42_ = v42_ + 1
				end
				v41_:addComment("collisionMaskFlags", "Warning: This file is exported from script and should not be edited manually")
				v41_:setString("collisionMaskFlags.defaultMask", string.format("0x%x", v_u_12_))
				local v47_ = 0
				for _, v48_ in ipairs(v_u_2_) do
					local v49_ = string.format("collisionMaskFlags.preset(%d)", v47_)
					v41_:setString(v49_ .. "#name", v48_.name)
					if v48_.desc ~= nil then
						v41_:setString(v49_ .. "#desc", v48_.desc)
					end
					local v50_ = CollisionFlag.getFlagsFromMask(v48_.group)
					local v51_ = 0
					for _, v52_ in pairs(v50_) do
						v41_:setString(v49_ .. string.format(".group.flag(%d)#name", v51_), v52_.name)
						v51_ = v51_ + 1
					end
					local v53_, _ = CollisionFlag.getFlagsFromMask(v48_.mask)
					if #v53_ < 10 then
						local v54_ = 0
						for _, v55_ in pairs(v53_) do
							v41_:setString(v49_ .. string.format(".mask.flag(%d)#name", v54_), v55_.name)
							v54_ = v54_ + 1
						end
					else
						v41_:addComment(v49_, CollisionFlag.getFlagsStringFromMask(v48_.mask, true))
						v41_:setString(v49_ .. ".mask#value", string.format("0x%x", v48_.mask))
					end
					v47_ = v47_ + 1
				end
				v41_:addComment("collisionMaskFlags", "Warning: This file is exported from script and should not be edited manually")
				v41_:saveTo("shared/collisionMaskFlags.xml", true)
				v41_:saveTo("../tools/editor/shared/collisionMaskFlags.xml", true)
				v41_:saveTo("../tools/exporter/maya/collisionMaskFlags.xml", true)
				v41_:saveTo("../tools/exporter/blender/exporter/io_export_i3d/collisionMaskFlags.xml", true)
				v41_:delete()
			end
			CollisionPreset.exportToXML = v56_
			addConsoleCommand("gsCollisionPresetsExport", "Export all collision presets to xml files", "exportToXML", CollisionPreset)
		end
	end
end
