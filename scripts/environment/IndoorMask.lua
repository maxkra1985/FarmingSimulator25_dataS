IndoorMask = {}
IndoorMask.NUM_CHANNELS = 1
IndoorMask.FIRST_CHANNEL = 0
IndoorMask.INDOOR = 1
IndoorMask.OUTDOOR = 0
IndoorMask.COLORS = { [IndoorMask.INDOOR] = Color.new(1, 0, 0, 0.15), [IndoorMask.OUTDOOR] = Color.new(0, 1, 0, 0.15) }
local IndoorMask_mt = Class(IndoorMask)
function IndoorMask.new(mission, isServer, customMt)
	local self = setmetatable({}, customMt or IndoorMask_mt)
	self.mission = mission
	self.isServer = isServer
	self.visualizeMask = false
	self.handle = nil
	self.layerName = "indoorMask"
	if g_addCheatCommands then
		addConsoleCommand("gsIndoorMaskToggle", "Toggle indoor mask visualization", "consoleCommandToggleMask", self)
	end
	return self
end
function IndoorMask:delete()
	g_messageCenter:unsubscribeAll(self)
	if g_addCheatCommands then
		removeConsoleCommand("gsIndoorMaskToggle")
	end
end
function IndoorMask:loadMapData(xmlFile, missionInfo, baseDirectory) end
function IndoorMask:onTerrainLoad(terrainRootNode)
	self.handle = getInfoLayerFromTerrain(terrainRootNode, self.layerName)
	if self.handle == nil or self.handle == 0 then
		self.handle = 0
		Logging.error("Layer '%s' is missing for current map!", self.layerName)
	end
	self.terrainSize = self.mission.terrainSize
	self.terrainSizeHalf = self.terrainSize / 2
	if self.handle ~= nil then
		self.maskSize = getBitVectorMapSize(self.handle)
		self.modifierValue = DensityMapModifier.new(self.handle, IndoorMask.FIRST_CHANNEL, IndoorMask.NUM_CHANNELS)
		self.filter = DensityMapFilter.new(self.modifierValue)
		self.worldToDensityMap = self.maskSize / self.terrainSize
		self.densityToWorldMap = self.terrainSize / self.maskSize
	end
end
function IndoorMask:drawDebug()
	if g_gui:getIsGuiVisible() and g_gui.currentGuiName ~= "ConstructionScreen" then
		return
	end
	if self.handle ~= nil then
		local terrainSizeHalf = self.terrainSizeHalf
		local worldToDensityMap = self.worldToDensityMap
		local densityToWorldMap = self.densityToWorldMap
		local sizePixelsHalf = 20
		local x, _, z = getWorldTranslation(g_cameraManager:getActiveCamera())
		local vehicle = g_localPlayer:getCurrentVehicle()
		if vehicle ~= nil then
			if vehicle.selectedImplement ~= nil then
				vehicle = vehicle.selectedImplement.object
			end
			x, _, z = getWorldTranslation(vehicle.components[1].node)
		end
		local xI = math.floor((x + terrainSizeHalf) * worldToDensityMap)
		local zI = math.floor((z + terrainSizeHalf) * worldToDensityMap)
		local minXi = math.max(xI - 20, 0)
		local minZi = math.max(zI - 20, 0)
		local maxXi = math.min(xI + 20, self.maskSize - 1)
		local maxZi = math.min(zI + 20, self.maskSize - 1)
		local areaSize = self.terrainSize / self.maskSize
		for zi = minZi, maxZi do
			for xi = minXi, maxXi do
				local v = getBitVectorMapPoint(self.handle, xi, zi, IndoorMask.FIRST_CHANNEL, IndoorMask.NUM_CHANNELS)
				local color = IndoorMask.COLORS[v]
				local xt = xi * densityToWorldMap - terrainSizeHalf
				local zt = zi * densityToWorldMap - terrainSizeHalf
				DebugPlane.renderWithPositions(xt, 0, zt, xt, 0, zt + areaSize, xt + areaSize, 0, zt, color, true, true)
			end
		end
	end
end
function IndoorMask:hasMask()
	return self.handle ~= nil
end
function IndoorMask:getFilter(indoorOutdoor)
	if self.handle ~= nil then
		self.filter:setValueCompareParams(DensityValueCompareType.EQUAL, indoorOutdoor)
		return self.filter
	else
		return nil
	end
end
function IndoorMask:getIsIndoorAtWorldPosition(wx, wz)
	if self.handle ~= nil then
		local x = math.floor((wx + self.terrainSizeHalf) * self.worldToDensityMap)
		local z = math.floor((wz + self.terrainSizeHalf) * self.worldToDensityMap)
		local value = getBitVectorMapPoint(self.handle, x, z, IndoorMask.FIRST_CHANNEL, IndoorMask.NUM_CHANNELS)
		return value == IndoorMask.INDOOR
	else
		return false
	end
end
function IndoorMask:setStateByArea(area, indoor)
	if self.handle == nil then
		return
	else
		local x, _, z = getWorldTranslation(area.start)
		local x1, _, z1 = getWorldTranslation(area.width)
		local x2, _, z2 = getWorldTranslation(area.height)
		self:setParallelogramUVCoords(self.modifierValue, x, z, x1, z1, x2, z2)
		self.modifierValue:executeSet(indoor)
	end
end
function IndoorMask:setParallelogramUVCoords(modifier, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local terrainSize = self.terrainSize
	modifier:setParallelogramUVCoords(startWorldX / terrainSize + 0.5, startWorldZ / terrainSize + 0.5, widthWorldX / terrainSize + 0.5, widthWorldZ / terrainSize + 0.5, heightWorldX / terrainSize + 0.5, heightWorldZ / terrainSize + 0.5, DensityCoordType.POINT_POINT_POINT)
end
function IndoorMask:getDensityMapData()
	return self.handle, IndoorMask.FIRST_CHANNEL, IndoorMask.NUM_CHANNELS
end
function IndoorMask:consoleCommandToggleMask()
	self.visualizeMask = not self.visualizeMask
	if self.visualizeMask then
		g_debugManager:addDrawable(self)
	else
		g_debugManager:removeDrawable(self)
	end
	return "visualizeMask=" .. tostring(self.visualizeMask)
end
