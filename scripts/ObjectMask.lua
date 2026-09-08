-- Local values: USED_BITS, DATA, DATA_MAPPING, registerFlag
ObjectMask = {}
local USED_BITS = {}
local DATA = {}
local DATA_MAPPING = {}
local function v10_(p4_, p5_, p6_)
	-- upvalues: (copy) USED_BITS, (copy) DATA_MAPPING, (copy) DATA
	if USED_BITS[p4_] ~= nil then
		Logging.error("ObjectMask.registerFlag: Given bit \'%d\' is already in use.", p4_)
		return nil
	end
	local v7_ = string.upper(p5_)
	if ObjectMask[v7_] ~= nil then
		Logging.error("ObjectMask.registerFlag: Given  name \'%s\' is already in use", v7_)
		return nil
	end
	local v8_ = {
		["name"] = v7_,
		["description"] = p6_ or "",
		["bit"] = p4_,
		["flag"] = 2 ^ p4_
	}
	USED_BITS[p4_] = true
	ObjectMask[v7_] = v8_.flag
	DATA_MAPPING[v8_.flag] = v8_
	local v9_ = DATA
	table.insert(v9_, v8_)
	return v8_.flag
end

-- Upvalues: DATA_MAPPING
-- Local values: data
function ObjectMask.getBitAndName(flag)
	-- upvalues: (copy) DATA_MAPPING
	local v12_ = DATA_MAPPING[flag]
	if v12_ ~= nil then
		return string.format("bit %d (%s)", v12_.bit, v12_.name)
	end
	printCallstack()
	return string.format("<no ObjectMask flag for \'0x%x\'>", flag)
end

-- Upvalues: DATA_MAPPING
-- Local values: flagNames, _, bit, flagMask, data
function ObjectMask.getFlagsFromMask(mask)
	-- upvalues: (copy) DATA_MAPPING
	local v14_ = {}
	for _, v15_ in ipairs(MathUtil.numberToSetBits(mask)) do
		local v16_ = DATA_MAPPING[2 ^ v15_]
		if v16_ ~= nil then
			local v17_ = v16_.name
			table.insert(v14_, v17_)
		end
	end
	return table.concat(v14_, " ")
end
ObjectMask.SHAPE_VIS_MIRROR = v10_(7, "SHAPE_VIS_MIRROR")
ObjectMask.SHAPE_VIS_WATER_REFL_VERYHIGH = v10_(8, "SHAPE_VIS_WATER_REFL_VERYHIGH")
ObjectMask.SHAPE_VIS_WATER_REFL = v10_(9, "SHAPE_VIS_WATER_REFL")
ObjectMask.SHAPE_VIS_MIRROR_ONLY = v10_(15, "SHAPE_VIS_MIRROR_ONLY", "shape only visible in mirror but not main view")
ObjectMask.LIGHT_VIS_WATER_REFL_VERYHIGH = v10_(24, "LIGHT_VIS_WATER_REFL_VERYHIGH")
ObjectMask.LIGHT_VIS_WATER_REFL = v10_(25, "LIGHT_VIS_WATER_REFL")
ObjectMask.LIGHT_VIS_MIRROR = v10_(31, "LIGHT_VIS_MIRROR")
ObjectMask.SHAPE_DEFAULT = 255
ObjectMask.LIGHT_DEFAULT = 16711680
function ObjectMask.iteratorFlags()
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
function ObjectMask.init()
	if g_isDevelopmentVersion then
		function ObjectMask.exportToXML()
			local v21_ = XMLFile.create("ObjectMaskFlags", "", "objectMaskFlags")
			v21_:addComment("objectMaskFlags", "Warning: This file is exported from script and should not be edited manually")
			local v22_ = 0
			for v23_, v24_, _, v25_ in ObjectMask.iteratorFlags() do
				local v26_ = string.format("objectMaskFlags.flag(%d)", v22_)
				v21_:setInt(v26_ .. "#bit", v24_)
				v21_:setString(v26_ .. "#name", v23_)
				v21_:setString(v26_ .. "#desc", v25_.description)
				v22_ = v22_ + 1
			end
			v21_:addComment("objectMaskFlags", "Warning: This file is exported from script and should not be edited manually")
			v21_:saveTo("shared/objectMaskFlags.xml", true)
			v21_:saveTo("../tools/editor/shared/objectMaskFlags.xml", true)
			v21_:delete()
		end
		addConsoleCommand("gsObjectMaskPresetsExport", "Export all object mask presets to xml files", "exportToXML", ObjectMask)
	end
end
