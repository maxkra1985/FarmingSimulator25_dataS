-- Local values: AnimalNameSystem_mt
AnimalNameSystem = {}
local AnimalNameSystem_mt = Class(AnimalNameSystem)

-- Upvalues: AnimalNameSystem_mt
-- Local values: self
function AnimalNameSystem.new(mission, customMt)
	-- upvalues: (copy) AnimalNameSystem_mt
	local v4_ = customMt or AnimalNameSystem_mt
	local v5_ = setmetatable({}, v4_)
	v5_.mission = mission
	v5_.names = {}
	return v5_
end

function AnimalNameSystem:delete() end

-- Local values: filename, xmlFileNames
function AnimalNameSystem:loadMapData(xmlFile, missionInfo)
	local v9_ = getXMLString(xmlFile, "map.animals.names#filename")
	if v9_ == nil or v9_ == "" then
		Logging.xmlInfo(xmlFile, "No animals names xml given at \'map.animals.names#filename\'")
		return false
	end
	local v10_ = Utils.getFilename(v9_, self.mission.baseDirectory)
	local v_u_11_ = XMLFile.load("animalNames", v10_)
	if v_u_11_ == nil then
		return false
	end
	v_u_11_:iterate("animalNames.name", function(_, p12_)
		-- upvalues: (copy) v_u_11_, (copy) missionInfo, (copy) self
		local v13_ = v_u_11_:getString(p12_ .. "#value")
		if v13_ == nil then
			Logging.xmlError(v_u_11_, "Missing name for \'%s\'", p12_)
			return false
		end
		local v14_ = g_i18n:convertText(v13_, missionInfo.customEnvironment)
		local v15_ = self.names
		table.insert(v15_, v14_)
	end)
	v_u_11_:delete()
	return #self.names > 0
end

-- Local values: numNames, index
function AnimalNameSystem:getRandomName()
	local v17_ = #self.names
	if v17_ == 0 then
		return ""
	end
	local v18_ = math.random(1, v17_)
	return self.names[v18_]
end
