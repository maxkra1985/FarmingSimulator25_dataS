-- Local values: GoalNPCInRange_mt
GoalNPCInRange = {}
GoalNPCInRange.NAME = "npcInRange"
local GoalNPCInRange_mt = Class(GoalNPCInRange)

function GoalNPCInRange.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#npc", "Name of the npc", nil, true)
	schema:register(XMLValueType.BOOL, basePath .. "#showMarker", "Show navigation marker", true, false)
end

-- Upvalues: GoalNPCInRange_mt
-- Local values: self
function GoalNPCInRange.new(npcName, showMarker, customMt)
	-- upvalues: (copy) GoalNPCInRange_mt
	local v7_ = customMt or GoalNPCInRange_mt
	local v8_ = setmetatable({}, v7_)
	v8_.npcName = npcName
	v8_.showMarker = showMarker
	return v8_
end

-- Local values: x, y, z
function GoalNPCInRange:activate(tour, step)
	self.npc = g_npcManager:getNPCByName(self.npcName)
	if self.npc ~= nil and self.showMarker then
		local v10_, v11_, v12_ = self.npc:getPosition()
		g_currentMission.navigationSystem:navigateTo(v10_, v11_, v12_)
		self.mapHotspot = TourHotspot.new()
		g_currentMission:addMapHotspot(self.mapHotspot)
		self.mapHotspot:setWorldPosition(v10_, v12_)
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
	return self.npc == nil and true or self.npc:getIsPlayerInRange()
end

-- Local values: npcName, showMarker
function GoalNPCInRange.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v17_ = xmlFile:getValue(key .. "#npc")
	if v17_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'npc\' for \'%s\'", key)
		return nil
	else
		local v18_ = xmlFile:getValue(key .. "#showMarker", true)
		return GoalNPCInRange.new(v17_, v18_)
	end
end
g_guidedTourManager:registerGoalClass(GoalNPCInRange.NAME, GoalNPCInRange)
