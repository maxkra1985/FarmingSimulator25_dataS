ActionIngameMap = {}
ActionIngameMap.NAME = "ingameMap"
local ActionIngameMap_mt = Class(ActionIngameMap)
function ActionIngameMap.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#state", "Name of the state", nil, true)
end
function ActionIngameMap.new(ingameMapState, customMt)
	local self = setmetatable({}, customMt or ActionIngameMap_mt)
	self.ingameMapState = ingameMapState
	return self
end
function ActionIngameMap:run(tour, step)
	local ingameMap = g_currentMission.hud:getIngameMap()
	ingameMap:toggleSize(self.ingameMapState, true)
	return true
end
function ActionIngameMap.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local stateName = xmlFile:getValue(key .. "#state")
	local ingameMapState = IngameMapState.getByName(stateName)
	if ingameMapState ~= nil then
		return ActionIngameMap.new(ingameMapState)
	else
		return nil
	end
end
g_guidedTourManager:registerActionClass(ActionIngameMap.NAME, ActionIngameMap)
