-- Local values: ActionIngameMap_mt
ActionIngameMap = {}
ActionIngameMap.NAME = "ingameMap"
local ActionIngameMap_mt = Class(ActionIngameMap)

function ActionIngameMap.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#state", "Name of the state", nil, true)
end

-- Upvalues: ActionIngameMap_mt
-- Local values: self
function ActionIngameMap.new(ingameMapState, customMt)
	-- upvalues: (copy) ActionIngameMap_mt
	local v6_ = customMt or ActionIngameMap_mt
	local v7_ = setmetatable({}, v6_)
	v7_.ingameMapState = ingameMapState
	return v7_
end

-- Local values: ingameMap
function ActionIngameMap:run(tour, step)
	g_currentMission.hud:getIngameMap():toggleSize(self.ingameMapState, true)
	return true
end

-- Local values: stateName, ingameMapState
function ActionIngameMap.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v11_ = xmlFile:getValue(key .. "#state")
	local v12_ = IngameMapState.getByName(v11_)
	if v12_ == nil then
		return nil
	else
		return ActionIngameMap.new(v12_)
	end
end
g_guidedTourManager:registerActionClass(ActionIngameMap.NAME, ActionIngameMap)
