-- Local values: ActionNavigationMarker_mt
ActionNavigationMarker = {}
ActionNavigationMarker.NAME = "navigationMarker"
ActionNavigationMarker.HOTSPOT = nil
local ActionNavigationMarker_mt = Class(ActionNavigationMarker)

function ActionNavigationMarker.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#isActive", "If the marker should be active", true, false)
	schema:register(XMLValueType.VECTOR_2, basePath .. "#worldPosition", "World position of the marker", nil, false)
	schema:register(XMLValueType.FLOAT, basePath .. "#terrainOffsetY", "Y terrain offset", 0, false)
end

-- Upvalues: ActionNavigationMarker_mt
-- Local values: self
function ActionNavigationMarker.new(isActive, worldPosX, worldPosZ, terrainOffsetY, customMt)
	-- upvalues: (copy) ActionNavigationMarker_mt
	local v9_ = customMt or ActionNavigationMarker_mt
	local v10_ = setmetatable({}, v9_)
	v10_.isActive = isActive
	v10_.worldPosX = worldPosX
	v10_.worldPosZ = worldPosZ
	v10_.terrainOffsetY = terrainOffsetY
	return v10_
end

-- Local values: worldPosY, hotspot, hotspot
function ActionNavigationMarker:run(tour, step)
	if self.isActive then
		local v12_ = getTerrainHeightAtWorldPos(g_terrainNode, self.worldPosX, 0, self.worldPosZ) + self.terrainOffsetY
		g_currentMission.navigationSystem:navigateTo(self.worldPosX, v12_, self.worldPosZ)
		local v13_ = ActionNavigationMarker.HOTSPOT
		if v13_ == nil then
			v13_ = TourHotspot.new()
			ActionNavigationMarker.HOTSPOT = v13_
		end
		g_currentMission:addMapHotspot(v13_)
		v13_:setWorldPosition(self.worldPosX, self.worldPosZ)
	else
		g_currentMission.navigationSystem:stop()
		local v14_ = ActionNavigationMarker.HOTSPOT
		if v14_ ~= nil then
			g_currentMission:removeMapHotspot(v14_)
			v14_:delete()
		end
	end
	return true
end

-- Local values: isActive, worldPosX, worldPosZ, terrainOffsetY
function ActionNavigationMarker.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v17_ = xmlFile:getValue(key .. "#isActive")
	if v17_ == nil then
		return nil
	end
	local v18_, v19_ = xmlFile:getValue(key .. "#worldPosition")
	if v17_ and (v18_ == nil or v19_ == nil) then
		return nil
	end
	local v20_ = xmlFile:getValue(key .. "#terrainOffsetY", 0)
	return ActionNavigationMarker.new(v17_, v18_, v19_, v20_)
end
g_guidedTourManager:registerActionClass(ActionNavigationMarker.NAME, ActionNavigationMarker)
