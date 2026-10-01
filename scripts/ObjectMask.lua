ObjectMask = {}
local USED_BITS = {}
local DATA = {}
local DATA_MAPPING = {}
local registerFlag = function(bit, name, description)
	if USED_BITS[bit] ~= nil then
		Logging.error("ObjectMask.registerFlag: Given bit '%d' is already in use.", bit)
		return nil
	end
	name = string.upper(name)
	if ObjectMask[name] ~= nil then
		Logging.error("ObjectMask.registerFlag: Given  name '%s' is already in use", name)
		return nil
	else
		local data = {}
		data.name = name
		data.description = description or ""
		data.bit = bit
		data.flag = 2 ^ bit
		USED_BITS[bit] = true
		ObjectMask[name] = data.flag
		DATA_MAPPING[data.flag] = data
		table.insert(DATA, data)
		return data.flag
	end
end
function ObjectMask.getBitAndName(flag)
	local data = DATA_MAPPING[flag]
	if data == nil then
		printCallstack()
		return string.format("<no ObjectMask flag for '0x%x'>", flag)
	else
		return string.format("bit %d (%s)", data.bit, data.name)
	end
end
function ObjectMask.getFlagsFromMask(mask)
	local flagNames = {}
	for _, bit in ipairs(MathUtil.numberToSetBits(mask)) do
		local flagMask = 2 ^ bit
		local data = DATA_MAPPING[flagMask]
		if data == nil then
			continue
		end
		table.insert(flagNames, data.name)
	end
	return table.concat(flagNames, " ")
end
ObjectMask.SHAPE_VIS_MIRROR = registerFlag(7, "SHAPE_VIS_MIRROR")
ObjectMask.SHAPE_VIS_WATER_REFL_VERYHIGH = registerFlag(8, "SHAPE_VIS_WATER_REFL_VERYHIGH")
ObjectMask.SHAPE_VIS_WATER_REFL = registerFlag(9, "SHAPE_VIS_WATER_REFL")
ObjectMask.SHAPE_VIS_MIRROR_ONLY = registerFlag(15, "SHAPE_VIS_MIRROR_ONLY", "shape only visible in mirror but not main view")
ObjectMask.LIGHT_VIS_WATER_REFL_VERYHIGH = registerFlag(24, "LIGHT_VIS_WATER_REFL_VERYHIGH")
ObjectMask.LIGHT_VIS_WATER_REFL = registerFlag(25, "LIGHT_VIS_WATER_REFL")
ObjectMask.LIGHT_VIS_MIRROR = registerFlag(31, "LIGHT_VIS_MIRROR")
ObjectMask.SHAPE_DEFAULT = 255
ObjectMask.LIGHT_DEFAULT = 16711680
function ObjectMask.iteratorFlags()
	local currentIndex = 0
	local endIndex = 31
	local iterator = function()
		if 31 < currentIndex then
			return nil
		else
			currentIndex = currentIndex + 1
			while DATA_MAPPING[2 ^ (currentIndex - 1)] == nil do
				currentIndex = currentIndex + 1
			end
			local data = DATA_MAPPING[2 ^ (currentIndex - 1)]
			return data.name, data.bit, data.flag, data
		end
	end
	return iterator
end
function ObjectMask.init()
	if not g_isDevelopmentVersion then
		return
	else
		function ObjectMask.exportToXML()
			local xmlFile = XMLFile.create("ObjectMaskFlags", "", "objectMaskFlags")
			local warningComment = "Warning: This file is exported from script and should not be edited manually"
			xmlFile:addComment("objectMaskFlags", "Warning: This file is exported from script and should not be edited manually")
			local flagIndex = 0
			for name, bit, flag, data in ObjectMask.iteratorFlags() do
				local element = string.format("objectMaskFlags.flag(%d)", flagIndex)
				xmlFile:setInt(element .. "#bit", bit)
				xmlFile:setString(element .. "#name", name)
				xmlFile:setString(element .. "#desc", data.description)
				flagIndex = flagIndex + 1
			end
			xmlFile:addComment("objectMaskFlags", "Warning: This file is exported from script and should not be edited manually")
			xmlFile:saveTo("shared/objectMaskFlags.xml", true)
			xmlFile:saveTo("../tools/editor/shared/objectMaskFlags.xml", true)
			xmlFile:delete()
		end
		addConsoleCommand("gsObjectMaskPresetsExport", "Export all object mask presets to xml files", "exportToXML", ObjectMask)
	end
end
