GoalNPCInRange = {}
GoalNPCInRange.NAME = "npcInRange"
local GoalNPCInRange_mt = Class(GoalNPCInRange)
function GoalNPCInRange.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#npc", "Name of the npc", nil, true)
	schema:register(XMLValueType.BOOL, basePath .. "#showMarker", "Show navigation marker", true, false)
end
function GoalNPCInRange.new(npcName, showMarker, customMt)
	local self = setmetatable({}, customMt or GoalNPCInRange_mt)
	self.npcName = npcName
	self.showMarker = showMarker
	return self
end
function GoalNPCInRange:activate(tour, step)
	self.npc = g_npcManager:getNPCByName(self.npcName)
	if self.npc ~= nil and self.showMarker then
		local x, y, z = self.npc:getPosition()
		g_currentMission.navigationSystem:navigateTo(x, y, z)
		self.mapHotspot = TourHotspot.new()
		g_currentMission:addMapHotspot(self.mapHotspot)
		self.mapHotspot:setWorldPosition(x, z)
	end
end
function GoalNPCInRange:deactivate()
	if self.showMarker then
		g_currentMission.navigationSystem:stop()
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()
	end
	self.npc = nil
end
function GoalNPCInRange:isAchieved()
	if self.npc == nil then
		return true
	else
		return self.npc:getIsPlayerInRange()
	end
end
function GoalNPCInRange.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local npcName = xmlFile:getValue(key .. "#npc")
	if npcName == nil then
		Logging.xmlWarning(xmlFile, "Missing 'npc' for '%s'", key)
		return nil
	else
		local showMarker = xmlFile:getValue(key .. "#showMarker", true)
		return GoalNPCInRange.new(npcName, showMarker)
	end
end
g_guidedTourManager:registerGoalClass(GoalNPCInRange.NAME, GoalNPCInRange)
