-- Local values: USED_BITS, DATA, DATA_MAPPING, FULL_MASK, ACTIVE_MASK, registerFlag
CollisionFlag = {}
local USED_BITS = {}
local DATA = {}
local DATA_MAPPING = {}
local FULL_MASK = 255
local ACTIVE_MASK = 0
local function v17_(p6_, p7_, p8_, p9_)
	-- upvalues: (copy) USED_BITS, (ref) ACTIVE_MASK, (ref) FULL_MASK, (copy) DATA_MAPPING, (copy) DATA
	if USED_BITS[p6_] ~= nil then
		Logging.error("CollisionFlag.registerFlag: Given bit \'%d\' is already in use.", p6_)
		return nil
	end
	local v10_ = string.upper(p7_)
	if CollisionFlag[v10_] ~= nil then
		Logging.error("CollisionFlag.registerFlag: Given  name \'%s\' is already in use", v10_)
		return nil
	end
	local v11_ = {
		["name"] = v10_,
		["description"] = p8_ or "",
		["bit"] = p6_,
		["flag"] = 2 ^ p6_,
		["isActive"] = p9_ or p6_ < 8,
		["isDeprecated"] = not p9_
	}
	if v11_.isActive then
		local v12_ = ACTIVE_MASK
		local v13_ = v11_.flag
		ACTIVE_MASK = bit32.bor(v12_, v13_)
	end
	local v14_ = FULL_MASK
	local v15_ = v11_.flag
	FULL_MASK = bit32.bor(v14_, v15_)
	USED_BITS[p6_] = true
	CollisionFlag[v10_] = v11_.flag
	DATA_MAPPING[v11_.flag] = v11_
	local v16_ = DATA
	table.insert(v16_, v11_)
	return v11_.flag
end
function CollisionFlag.iteratorFlags()
	-- upvalues: (copy) DATA_MAPPING
	local v_u_18_ = 0
	local v_u_19_ = 31
	return function()
		-- upvalues: (ref) v_u_18_, (ref) DATA_MAPPING, (copy) v_u_19_
		if v_u_18_ > 31 then
			return nil
		end
		v_u_18_ = v_u_18_ + 1
		while DATA_MAPPING[2 ^ (v_u_18_ - 1)] == nil do
			v_u_18_ = v_u_18_ + 1
		end
		local v20_ = DATA_MAPPING[2 ^ (v_u_18_ - 1)]
		return v20_.name, v20_.bit, v20_.flag, v20_
	end
end

-- Local values: collisionMask
function CollisionFlag.getHasMaskFlagSet(node, flag)
	local v23_ = getCollisionFilterMask(node)
	return bit32.btest(v23_, flag)
end

-- Local values: collisionMask
function CollisionFlag.getHasGroupFlagSet(node, flag)
	local v26_ = getCollisionFilterGroup(node)
	return bit32.btest(v26_, flag)
end

-- Local values: collisionMask, newCollisionMask
function CollisionFlag.setMaskFlag(node, flag)
	local v29_ = getCollisionFilterMask(node)
	local v30_ = bit32.bor(v29_, flag)
	setCollisionFilterMask(node, v30_)
end

-- Local values: collisionGroup, newCollisionGroup
function CollisionFlag.setGroupFlag(node, flag)
	local v33_ = getCollisionFilterGroup(node)
	local v34_ = bit32.bor(v33_, flag)
	setCollisionFilterGroup(node, v34_)
end

-- Upvalues: DATA_MAPPING
-- Local values: data
function CollisionFlag.getBit(flag)
	-- upvalues: (copy) DATA_MAPPING
	local v36_ = DATA_MAPPING[flag]
	if v36_ == nil then
		printCallstack()
	end
	return v36_.bit
end

-- Upvalues: DATA_MAPPING
-- Local values: data
function CollisionFlag.getBitAndName(flag)
	-- upvalues: (copy) DATA_MAPPING
	local v38_ = DATA_MAPPING[flag]
	if v38_ == nil then
		printCallstack()
	end
	return string.format("bit %d (%s)", v38_.bit, v38_.name)
end

-- Upvalues: DATA_MAPPING
-- Local values: flags, flagInverse, bit, flagMask, data
function CollisionFlag.getFlagsFromMask(mask)
	-- upvalues: (copy) DATA_MAPPING
	local v40_ = {}
	local v41_ = {}
	for v42_ = 0, 31 do
		local v43_ = 2 ^ v42_
		local v44_ = DATA_MAPPING[v43_]
		if v44_ ~= nil then
			if bit32.btest(v43_, mask) then
				table.insert(v40_, v44_)
			else
				table.insert(v41_, v44_)
			end
		end
	end
	return v40_, v41_
end

-- Upvalues: USED_BITS, DATA_MAPPING
-- Local values: flagNames, isInverse, numSetBits, _, bit, flagMask, data
function CollisionFlag.getFlagsStringFromMask(mask, allowInverse)
	-- upvalues: (copy) USED_BITS, (copy) DATA_MAPPING
	local v47_ = {}
	local v48_ = MathUtil.getNumOfSetBits(mask)
	local v49_
	if allowInverse and table.size(USED_BITS) * 0.5 < v48_ then
		mask = bit32.bnot(mask)
		v49_ = true
	else
		v49_ = false
	end
	for _, v50_ in ipairs(MathUtil.numberToSetBits(mask)) do
		local v51_ = DATA_MAPPING[2 ^ v50_]
		if v51_ ~= nil then
			local v52_ = v51_.name
			table.insert(v47_, v52_)
		end
	end
	if allowInverse and v48_ == table.size(USED_BITS) then
		return "ALL registered Bits"
	elseif v49_ then
		return "ALL except " .. table.concat(v47_, ", ")
	else
		return table.concat(v47_, ", ")
	end
end
local function v64_(p53_)
	-- upvalues: (ref) FULL_MASK, (ref) ACTIVE_MASK
	local v54_ = false
	if getHasClassId(p53_, ClassIds.SHAPE) then
		local v55_ = getCollisionFilterMask(p53_)
		if v55_ > 0 and v55_ ~= 255 then
			local v56_ = FULL_MASK
			local v57_ = bit32.bnot(v56_)
			local v58_ = bit32.band(v55_, v57_)
			if v58_ ~= 0 then
				local v59_ = MathUtil.numberToSetBitsStr(v58_)
				print(string.format("    CollisionFlag-Check: Node \'%s\' uses undefined bits \'%s\'!", I3DUtil.getNodePath(p53_), v59_))
				v54_ = true
			end
			local v60_ = ACTIVE_MASK
			local v61_ = bit32.bnot(v60_)
			local v62_ = bit32.band(v55_, v61_)
			if v62_ ~= 0 then
				local v63_ = MathUtil.numberToSetBitsStr(v62_)
				print(string.format("    CollisionFlag-Check: Node \'%s\' uses deprecated bits \'%s\'!", I3DUtil.getNodePath(p53_), v63_))
				v54_ = true
			end
		end
	end
	return v54_
end
CollisionFlag.checkCollisionMask = v64_

-- Local values: matches, i
function CollisionFlag.checkCollisionMaskRec(node)
	local v66_ = false
	if node ~= nil and node ~= 0 then
		v66_ = v66_ or CollisionFlag.checkCollisionMask(node)
		for v67_ = 0, getNumOfChildren(node) - 1 do
			v66_ = v66_ or CollisionFlag.checkCollisionMaskRec(getChildAt(node, v67_))
		end
	end
	return v66_
end
addConsoleCommand("gsCollisionFlagShowAll", "Shows all available collision flags", "consoleCommandShowAll", CollisionFlag)
function CollisionFlag.consoleCommandShowAll()
	-- upvalues: (copy) DATA
	table.sort(DATA, function(p68_, p69_)
		if p68_.isDeprecated and p69_.isDeprecated or not (p68_.isDeprecated or p69_.isDeprecated) then
			return p68_.bit < p69_.bit
		else
			return not p68_.isDeprecated
		end
	end)
	print("Defined collision flags:")
	local v70_ = false
	for _, v71_ in ipairs(DATA) do
		if v71_.isDeprecated and not v70_ then
			print("\nDeprecated:")
			v70_ = true
		end
		print(string.format("Bit %02d: %s - %s", v71_.bit, v71_.name, v71_.description))
	end
	print("\n\nPredefined collision masks:")
	for v72_, v73_ in pairs(CollisionMask) do
		print(string.format("Mask %010d: %s", v73_, v72_))
	end
end
CollisionFlag.DEFAULT = v17_(0, "DEFAULT", "The default bit", true)
CollisionFlag.STATIC_OBJECT = v17_(1, "STATIC_OBJECT", "Static object", true)
CollisionFlag.CAMERA_BLOCKING = v17_(2, "CAMERA_BLOCKING", "Blocks the player camera from being inside", true)
CollisionFlag.GROUND_TIP_BLOCKING = v17_(3, "GROUND_TIP_BLOCKING", "Blocks tipping on the ground beneath/above", true)
CollisionFlag.PLACEMENT_BLOCKING = v17_(4, "PLACEMENT_BLOCKING", "Blocks placing objects via construction", true)
CollisionFlag.AI_BLOCKING = v17_(5, "AI_BLOCKING", "Blocks vehicle navigation map beneath/above", true)
CollisionFlag.PRECIPITATION_BLOCKING = v17_(6, "PRECIPITATION_BLOCKING", "Masks all precipitation inside and below the collision", true)
CollisionFlag.TERRAIN = v17_(8, "TERRAIN", "Terrain without tip any or displacement", true)
CollisionFlag.TERRAIN_DELTA = v17_(9, "TERRAIN_DELTA", "Tip anything", true)
CollisionFlag.TERRAIN_DISPLACEMENT = v17_(10, "TERRAIN_DISPLACEMENT", "Terrain displacement (tiretrack deformation)", true)
CollisionFlag.TREE = v17_(11, "TREE", "A tree", true)
CollisionFlag.BUILDING = v17_(12, "BUILDING", "A building", true)
CollisionFlag.ROAD = v17_(13, "ROAD", "A road", true)
CollisionFlag.AI_DRIVABLE = v17_(14, "AI_DRIVABLE", "Blocks vehicle navigation map at the vertical faces of the mesh if they are above the terrain", true)
CollisionFlag.VEHICLE = v17_(16, "VEHICLE", "A vehicle", true)
CollisionFlag.VEHICLE_FORK = v17_(17, "VEHICLE_FORK", "A vehicle fork tip for pallets or bales", true)
CollisionFlag.DYNAMIC_OBJECT = v17_(18, "DYNAMIC_OBJECT", "A dynamic object", true)
CollisionFlag.TRAFFIC_VEHICLE = v17_(19, "TRAFFIC_VEHICLE", "A AI traffic vehicle", true)
CollisionFlag.PLAYER = v17_(20, "PLAYER", "A player", true)
CollisionFlag.ANIMAL = v17_(21, "ANIMAL", "An Animal", true)
CollisionFlag.ANIMAL_POSITIONING = v17_(22, "ANIMAL_POSITIONING", "For animal to walk on (position is raycast from above)", true)
CollisionFlag.ANIMAL_NAV_MESH_BLOCKING = v17_(23, "ANIMAL_NAV_MESH_BLOCKING", "Area of the collision is excluded from generated nav meshes", true)
CollisionFlag.TRAFFIC_VEHICLE_BLOCKING = v17_(24, "TRAFFIC_VEHICLE_BLOCKING", "Blocks AI traffic vehicles", true)
CollisionFlag.INTERACTABLE_TARGET = v17_(28, "INTERACTABLE_TARGET", "An interactable trigger that the player can target", true)
CollisionFlag.TRIGGER = v17_(29, "TRIGGER", "A trigger", true)
CollisionFlag.FILLABLE = v17_(30, "FILLABLE", "A fillable node. For trailer fillNodes and unload triggers", true)
CollisionFlag.WATER = v17_(31, "WATER", "A water plane", true)
function CollisionFlag.consoleCommandReloadCollisionMaskMapping()
	CollisionFlag.loadCollisionMaskMapping()
	CollisionFlag.printMapping()
	return "reloaded mapping"
end
function CollisionFlag.consoleCommandToggleVerbose()
	CollisionFlag.colMaskMappingVerbose = not CollisionFlag.colMaskMappingVerbose
	local v74_ = CollisionFlag.colMaskMappingVerbose
	return "CollisionFlag.colMaskMappingVerbose=" .. tostring(v74_)
end
function CollisionFlag.loadCollisionMaskMapping()
	local v_u_75_ = XMLFile.load("collisionMaskConversionRules", "shared/collisionMaskConversionRules.xml")
	if v_u_75_ ~= nil then
		Logging.info("Loading collision mask conversion rules from %q", v_u_75_:getFilename())
		colMaskMapping = {}
		colMaskPresets = {}
		local function v91_(p76_, p77_)
			-- upvalues: (copy) v_u_75_
			local v78_ = v_u_75_:getString(p76_ .. "#value")
			local v79_
			if v78_ == nil then
				v79_ = p77_ or 0
			else
				local v80_ = string.gsub(v78_, "_", "")
				v79_ = tonumber(v80_)
				if v79_ == nil then
					Logging.xmlError(v_u_75_, "Unable to parse %q as a number for %q", v80_, p76_ .. "#value")
					return nil
				end
			end
			for _, v81_ in v_u_75_:iterator(p76_ .. ".flag") do
				local v82_ = v_u_75_:getString(v81_ .. "#name")
				if v82_ == nil then
					local v83_ = v_u_75_:getInt(v81_ .. "#bit")
					if v83_ ~= nil then
						if v83_ < 0 or v83_ > 31 then
							Logging.xmlError(v_u_75_, "Invalid bit number %q at %q, needs to be between 0 and 31", v83_, v81_)
						else
							local v84_ = 2 ^ v83_
							v79_ = bit32.bor(v79_, v84_)
						end
					end
				else
					local v85_ = CollisionFlag[v82_]
					if v85_ == nil then
						Logging.xmlError(v_u_75_, "Unable to find CollisionFlag %q for %q", v82_, v81_)
					else
						v79_ = bit32.bor(v79_, v85_)
					end
				end
			end
			for _, v86_ in v_u_75_:iterator(p76_ .. ".withoutFlag") do
				local v87_ = v_u_75_:getString(v86_ .. "#name")
				if v87_ == nil then
					local v88_ = v_u_75_:getInt(v86_ .. "#bit")
					if v88_ ~= nil then
						if v88_ < 0 or v88_ > 31 then
							Logging.xmlError(v_u_75_, "Invalid bit number %q at %q, needs to be between 0 and 31", v88_, v86_)
						else
							local v89_ = 2 ^ v88_
							v79_ = bit32.bxor(v79_, v89_)
						end
					end
				else
					local v90_ = CollisionFlag[v87_]
					if v90_ == nil then
						Logging.xmlError(v_u_75_, "Unable to find CollisionFlag %q for %q", v87_, v86_)
					else
						v79_ = bit32.bxor(v79_, v90_)
					end
				end
			end
			return v79_
		end
		for _, v92_ in v_u_75_:iterator("collisionMaskUpdater.presets.preset") do
			local v93_ = v_u_75_:getString(v92_ .. "#name")
			if colMaskPresets[v93_] == nil then
				local v94_ = {
					["group"] = v91_(v92_ .. ".group"),
					["mask"] = v91_(v92_ .. ".mask")
				}
				colMaskPresets[v93_] = v94_
			else
				Logging.xmlError(v_u_75_, "Preset name %q at %q already in use", v93_, v92_)
			end
		end
		for _, v95_ in v_u_75_:iterator("collisionMaskUpdater.conversionRules.rule") do
			local v96_ = v95_ .. "#maskOld"
			local v97_ = tonumber(v_u_75_:getString(v96_))
			if colMaskMapping[v97_] == nil then
				for _, v98_ in v_u_75_:iterator(v95_ .. ".output") do
					local v99_ = nil
					local v100_ = nil
					local v101_ = v_u_75_:getString(v98_ .. "#preset")
					if v101_ ~= nil then
						local v102_ = CollisionPreset[v101_] or colMaskPresets[v101_]
						if v102_ == nil then
							Logging.xmlError(v_u_75_, "Unknown preset %q in %q", v101_, v98_)
						else
							v99_ = v102_.group
							v100_ = v102_.mask
						end
					end
					local v103_ = v91_(v98_ .. ".group", v99_)
					local v104_ = v91_(v98_ .. ".mask", v100_)
					if v103_ == 0 then
						Logging.xmlError(v_u_75_, "Incomplete conversion rule for old mask %q at %q, no new group filter defined", v97_, v98_)
					elseif v104_ == 0 then
						Logging.xmlError(v_u_75_, "Incomplete conversion rule for old mask %q at %q, no new mask defined", v97_, v98_)
					else
						colMaskMapping[v97_] = colMaskMapping[v97_] or {}
						local v105_ = colMaskMapping[v97_]
						local v106_ = {
							["group"] = v103_,
							["mask"] = v104_,
							["isTrigger"] = v_u_75_:getBool(v98_ .. "#isTrigger")
						}
						table.insert(v105_, v106_)
					end
				end
			else
				Logging.warning("duplicate mask %q", v97_)
			end
		end
		v_u_75_:delete()
	end
end
function CollisionFlag.printMapping()
	setFileLogPrefixTimestamp(false)
	print("Presets")
	for v107_, v108_ in pairs(colMaskPresets) do
		print(string.format("    %s", v107_))
		print(string.format("        => group: Dec:%s  Hex:%x  Flags:%s", v108_.group, v108_.group, CollisionFlag.getFlagsStringFromMask(v108_.group)))
		print(string.format("        => mask: Dec:%s  Hex:%x  Flags:%s", v108_.mask, v108_.mask, CollisionFlag.getFlagsStringFromMask(v108_.mask, true)))
	end
	print("\nRules")
	for v109_, v110_ in pairs(colMaskMapping) do
		print(string.format("Old: Dec:%s Hex:%x Bits:%s", v109_, v109_, MathUtil.numberToSetBitsStr(v109_)))
		for v111_, v112_ in ipairs(v110_) do
			if #v110_ > 1 then
				print(string.format("    output %d - isTrigger=%s", v111_, v112_.isTrigger))
			end
			print(string.format("        => group: Dec:%s  Hex:%x  Flags:%s", v112_.group, v112_.group, CollisionFlag.getFlagsStringFromMask(v112_.group)))
			print(string.format("        => mask: Dec:%s  Hex:%x  Flags:%s", v112_.mask, v112_.mask, CollisionFlag.getFlagsStringFromMask(v112_.mask, true)))
		end
	end
	setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
end
if I3DManager ~= nil then
	I3DManager.addDebugLoadingCheck("check col group / mask", function(_, p113_)
		local v114_ = false
		if getHasClassId(p113_, ClassIds.SHAPE) or getHasClassId(p113_, ClassIds.TERRAIN_TRANSFORM_GROUP) then
			local v115_ = getCollisionFilterMask(p113_)
			if v115_ == 0 then
				return
			end
			if v115_ ~= getCollisionFilterGroup(p113_) then
				return
			end
			if CollisionFlag.colMaskMappingVerbose then
				printWarning(string.format("Warning: outdated mask for %q Dec:%s Hex:%x Bits: %s", I3DUtil.getNodePath(p113_), v115_, v115_, v115_ == 4294967295 and "ALL" or MathUtil.numberToSetBitsStr(v115_)))
			end
		end
		return v114_
	end)
end
