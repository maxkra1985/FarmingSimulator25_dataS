SnowSystem = {}
SnowSystem.MAX_HEIGHT = 0.5
SnowSystem.MIN_LAYER_HEIGHT = 0.06
SnowSystem.MAX_MS_PER_FRAME = 1
SnowSystem.MAX_MS_PER_FRAME_SLEEPING = 3
SnowSystem.DELTA_REMOVE_ALL = -100
local SnowSystem_mt = Class(SnowSystem)
function SnowSystem.new(mission, isServer, customMt)
	local self = setmetatable({}, customMt or SnowSystem_mt)
	self.mission = mission
	self.isServer = isServer
	self.updater = nil
	self.updateQueue = {}
	self.height = 0
	self.exactHeight = 0
	self.snowShaderValue = 0
	self.vehicleWakeUpIndex = 0
	self.vehicleWakeUpDelay = 500
	self.vehicleWakeUpTimer = 0
	self.itemWakeUpIndex = 0
	self.itemWakeUpDelay = 100
	self.itemWakeUpTimer = 0
	setSharedShaderParameter(Shader.PARAM_SHARED_SNOW, 0)
	if self.isServer then
		g_messageCenter:subscribe(MessageType.SLEEPING, self.onSleepChanged, self)
	end
	return self
end
function SnowSystem:delete()
	g_messageCenter:unsubscribeAll(self)
	if g_addCheatCommands then
		removeConsoleCommand("gsSnowAdd")
		removeConsoleCommand("gsSnowSet")
		removeConsoleCommand("gsSnowReset")
		removeConsoleCommand("gsSnowShaderSet")
		removeConsoleCommand("gsSnowAddSalt")
	end
end
function SnowSystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.missionInfo = missionInfo
	self.environment = self.mission.environment
	self.indoorMask = self.mission.indoorMask
	if g_addCheatCommands and g_currentMission:getIsServer() then
		addConsoleCommand("gsSnowAdd", "Add snow", "consoleCommandAddSnow", self)
		addConsoleCommand("gsSnowSet", "Set snow", "consoleCommandSetSnow", self)
		addConsoleCommand("gsSnowReset", "Reset snow", "consoleCommandResetSnow", self)
		addConsoleCommand("gsSnowShaderSet", "Force snow shader value for map objects", "consoleCommandSetSnowShader", self)
		addConsoleCommand("gsSnowAddSalt", "Salt around player", "consoleCommandSalt", self)
	end
end
function SnowSystem:loadFromXMLFile(filename)
	local xmlFile = XMLFile.load("environment", filename)
	if xmlFile ~= nil then
		self.height = xmlFile:getFloat("environment.snow#physicalHeight", self.height)
		self.exactHeight = xmlFile:getFloat("environment.snow#height", self.exactHeight)
		for _, key in xmlFile:iterator("environment.snow.queue.delta") do
			local delta = xmlFile:getFloat(key)
			table.insert(self.updateQueue, delta)
		end
		if self.currentApplyingDelta == nil and 0 < #self.updateQueue then
			self.startPendingQueueTask = true
		end
		self.currentApplyingDelta = xmlFile:getFloat("environment.snow.queue#current")
		xmlFile:delete()
	end
	if g_currentMission.environment.weather.snowHeight == 0 and self.exactHeight ~= 0 then
		Logging.info("Weather indicates there must be no snow, snow system disagrees. Resetting snow.")
		self:setSnowHeight(0)
	end
	self:updateSnowShader()
end
function SnowSystem:saveToXMLFile(file, key)
	local xmlFile = XMLFile.wrap(file)
	xmlFile:setFloat(key .. "#physicalHeight", self.height)
	xmlFile:setFloat(key .. "#height", self.exactHeight)
	if self.currentApplyingDelta ~= nil then
		xmlFile:setFloat(key .. ".queue#current", self.currentApplyingDelta)
	end
	xmlFile:setSortedTable("environment.snow.queue.delta", self.updateQueue, function(keyQueueDelta, value)
		xmlFile:setFloat(keyQueueDelta, value)
	end)
	xmlFile:delete()
end
function SnowSystem:saveState(directory)
	saveDensityMapHeightUpdaterStateToFile(self.updater, directory .. "/snow_state.xml")
end
function SnowSystem:onTerrainLoad(terrainRootNode)
	local terrainDetailHeightId = self.mission.terrainDetailHeightId
	self.snowHeightTypeIndex = g_densityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeIndex(FillType.SNOW)
	local modifiers = {}
	modifiers.height = {}
	modifiers.height.modifierHeight = DensityMapModifier.new(terrainDetailHeightId, getDensityMapHeightFirstChannel(terrainDetailHeightId), getDensityMapHeightNumChannels(terrainDetailHeightId))
	modifiers.height.filterHeight = DensityMapFilter.new(modifiers.height.modifierHeight)
	modifiers.height.filterType = DensityMapFilter.new(terrainDetailHeightId, g_densityMapHeightManager.heightTypeFirstChannel, g_densityMapHeightManager.heightTypeNumChannels)
	modifiers.height.filterSnowType = DensityMapFilter.new(terrainDetailHeightId, g_densityMapHeightManager.heightTypeFirstChannel, g_densityMapHeightManager.heightTypeNumChannels)
	modifiers.height.filterSnowType:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
	modifiers.fillType = {}
	modifiers.fillType.modifierType = DensityMapModifier.new(terrainDetailHeightId, g_densityMapHeightManager.heightTypeFirstChannel, g_densityMapHeightManager.heightTypeNumChannels)
	modifiers.fillType.filterHeight = DensityMapFilter.new(terrainDetailHeightId, getDensityMapHeightFirstChannel(terrainDetailHeightId), getDensityMapHeightNumChannels(terrainDetailHeightId))
	modifiers.fillType.filterType = DensityMapFilter.new(modifiers.fillType.modifierType)
	local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = self.mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
	modifiers.sprayLevel = {}
	modifiers.sprayLevel.modifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, g_terrainNode)
	self.modifiers = modifiers
	self.layerHeight = 1 / g_densityMapHeightManager.heightToDensityValue
	if self.isServer then
		self.updater = g_densityMapHeightManager.terrainDetailHeightUpdater
		setDensityMapHeightUpdateType(self.updater, self.snowHeightTypeIndex)
		setDensityMapHeightUpdateApplyMaxTimePerFrame(self.updater, SnowSystem.MAX_MS_PER_FRAME)
		if self.indoorMask:hasMask() then
			local blockMaskId, blockMaskFirstChannel, blockMaskNumChannels = self.indoorMask:getDensityMapData()
			setDensityMapHeightUpdateApplyBlockMask(self.updater, blockMaskId, blockMaskFirstChannel, blockMaskNumChannels)
		end
		if self.missionInfo.isValid and self.missionInfo.densityMapRevision == g_densityMapRevision then
			local dir = self.missionInfo.savegameDirectory
			local success, delta = loadDensityMapHeightUpdaterStateFromFile(self.updater, dir .. "/snow_state.xml")
			if success and -1 < delta then
				self.currentApplyingDelta = delta
			end
		end
		setDensityMapHeightUpdateApplyFinishedCallback(self.updater, "onApplicationFinished", self)
	end
end
function SnowSystem:update(dt)
	if self.isServer and self.startPendingQueueTask then
		local delta = table.remove(self.updateQueue, 1)
		if delta ~= nil then
			self:startApplication(delta)
		end
		self.startPendingQueueTask = nil
	end
	if 0 < self.vehicleWakeUpIndex then
		self.vehicleWakeUpTimer = self.vehicleWakeUpTimer + dt
		if self.vehicleWakeUpDelay < self.vehicleWakeUpTimer then
			local vehicle = self.mission.vehicleSystem.vehicles[self.vehicleWakeUpIndex]
			if vehicle == nil then
				self.vehicleWakeUpIndex = 0
			else
				vehicle:wakeUp()
				self.vehicleWakeUpIndex = self.vehicleWakeUpIndex + 1
			end
			self.vehicleWakeUpTimer = 0
		end
	end
	if 0 < self.itemWakeUpIndex then
		self.itemWakeUpTimer = self.itemWakeUpTimer + dt
		if self.itemWakeUpDelay < self.itemWakeUpTimer then
			local item = self.mission.itemSystem.sortedItemsToSave[self.itemWakeUpIndex]
			if item == nil then
				self.itemWakeUpIndex = 0
			else
				if item.item.wakeUp ~= nil then
					item.item:wakeUp()
				end
				self.itemWakeUpIndex = self.itemWakeUpIndex + 1
			end
			self.itemWakeUpTimer = 0
		end
	end
end
function SnowSystem:applySnow(delta)
	if not self.isServer then
		return
	else
		if self.currentApplyingDelta ~= nil then
			local folded = false
			if 0 < #self.updateQueue then
				local lastItemDelta = self.updateQueue[#self.updateQueue]
				if lastItemDelta <= SnowSystem.DELTA_REMOVE_ALL then
					if delta < 0 then
						folded = true
					end
				else
					self.updateQueue[#self.updateQueue] = lastItemDelta + delta
					folded = true
				end
			end
			if not folded then
				self.updateQueue[#self.updateQueue + 1] = delta
			end
		else
			self:startApplication(delta)
		end
	end
end
function SnowSystem:startApplication(delta)
	local blockMaskId, blockMaskFirstChannel, blockMaskNumChannels = self.indoorMask:getDensityMapData()
	local heightLimit = SnowSystem.MAX_HEIGHT
	if delta < 0 then
		heightLimit = 0
	end
	self.currentApplyingDelta = delta
	if delta < 0 then
		blockMaskId = 0
	end
	local useCollisionMap = false
	applyDensityMapHeightUpdate(self.updater, self.snowHeightTypeIndex, delta, heightLimit, false, false, blockMaskId, blockMaskFirstChannel, blockMaskNumChannels, "onApplicationFinished", self, self:getMaxUpdateTime(), g_currentMission.tireTrackSystem.tireTrackSystemId)
end
function SnowSystem:onApplicationFinished()
	local currentDelta = self.currentApplyingDelta
	self.currentApplyingDelta = nil
	if 0 < currentDelta then
		self:removeSnowUnderObjects(currentDelta)
	else
		self:onHeightChanged(currentDelta)
	end
	if 0 < #self.updateQueue then
		local delta = self.updateQueue[1]
		table.remove(self.updateQueue, 1)
		self:startApplication(delta)
	end
end
function SnowSystem:onHeightChanged(delta)
	self.vehicleWakeUpIndex = 1
	self.itemWakeUpIndex = 1
	g_messageCenter:publish(MessageType.SNOW_HEIGHT_CHANGED, math.max(self.height / SnowSystem.MAX_HEIGHT, 0), math.max(self.height, 0))
end
function SnowSystem:removeSnowUnderObjects(delta)
	for _, object in pairs(self.mission.itemSystem.itemsToSave) do
		if object.item.doDensityMapItemAreaUpdate == nil then
			continue
		end
		object.item:doDensityMapItemAreaUpdate(self.removeSnow, self, delta / self.layerHeight)
	end
	for _, vehicle in pairs(self.mission.vehicleSystem.vehicles) do
		if vehicle.spec_wheels == nil then
			continue
		end
		for _, wheel in pairs(vehicle.spec_wheels.wheels) do
			local width = 0.5 * wheel.physics.width
			local length = math.min(0.5, 0.5 * wheel.physics.width)
			local x, _, z = localToLocal(wheel.driveNode, wheel.repr, 0, 0, 0)
			local x0, _, z0 = localToWorld(wheel.repr, x + width, 0, z - length)
			local x1, _, z1 = localToWorld(wheel.repr, x - width, 0, z - length)
			local x2, _, z2 = localToWorld(wheel.repr, x + width, 0, z + length)
			self:removeSnow(x0, z0, x1, z1, x2, z2, delta / self.layerHeight)
		end
	end
	self:onHeightChanged(delta)
end
function SnowSystem:saltArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local modifiers = self.modifiers.height
	local modifier = modifiers.modifierHeight
	local filter1 = modifiers.filterType
	local filter2 = modifiers.filterHeight
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	filter1:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
	filter2:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
	FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	FSDensityMapUtil.eraseTireTrack(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local density, area, totalArea = modifier:executeSetWithStats(0, filter1, filter2)
	modifiers = self.modifiers.sprayLevel
	modifier = modifiers.modifier
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifier:executeSet(0)
	if density ~= 0 then
		modifiers = self.modifiers.fillType
		modifier = modifiers.modifierType
		modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		filter2:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		modifier:executeSet(0, filter2)
	end
	return area, totalArea
end
function SnowSystem:getSnowHeightAtArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local modifiers = self.modifiers.height
	local modifier = modifiers.modifierHeight
	local filter = modifiers.filterType
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	filter:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
	local density, area, _ = modifier:executeGet(filter)
	if area == 0 then
		return 0
	else
		return density / area * self.layerHeight
	end
end
function SnowSystem:setSnowHeightAtArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, height)
	local layers = math.floor(height / self.layerHeight)
	if 0 < layers then
		local modifiers = self.modifiers.fillType
		local modifier = modifiers.modifierType
		local filter = modifiers.filterHeight
		modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		filter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		modifier:executeSet(self.snowHeightTypeIndex, filter)
	end
	local modifiers = self.modifiers.height
	local modifier = modifiers.modifierHeight
	local filter = modifiers.filterType
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	filter:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
	modifier:executeSet(layers, filter)
	if layers == 0 then
		modifiers = self.modifiers.fillType
		modifier = modifiers.modifierType
		filter = modifiers.filterHeight
		modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		filter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		modifier:executeSet(0, filter)
	end
end
function SnowSystem:removeSnow(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
	local modifiers = self.modifiers.height
	local modifier = modifiers.modifierHeight
	local filter = modifiers.filterType
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	filter:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
	local density = modifier:executeAddWithStats(-layers, filter)
	if density ~= 0 then
		modifiers = self.modifiers.fillType
		modifier = modifiers.modifierType
		filter = modifiers.filterHeight
		modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		filter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		modifier:executeSet(0, filter)
	end
end
function SnowSystem:setSnowHeight(height)
	height = math.clamp(height, -4.02, SnowSystem.MAX_HEIGHT)
	self.exactHeight = math.max(height, 0)
	self:updateSnowShader()
	if self.height == height then
		return
	else
		if 0 < self.height and height <= 0 then
			self:removeAll()
		end
		if self.height < 0 then
			if 0 < height then
				self.height = 0
			elseif self.height < 0 then
				if self.height < height then
					self.height = height
				end
			end
		end
		if self.isServer then
			if self.layerHeight == nil then
				return
			end
			if self.layerHeight <= math.abs(height - self.height) then
				local deltaHeight = height - self.height
				self:applySnow(deltaHeight)
				self.height = self.height + deltaHeight
			end
		end
	end
end
function SnowSystem:updateSnowShader()
	self.snowShaderValue = 0
	if self.layerHeight ~= nil then
		self.snowShaderValue = self.exactHeight / self.layerHeight
	end
	setSharedShaderParameter(Shader.PARAM_SHARED_SNOW, self.debug_forcedSnowShaderValue or self.snowShaderValue)
end
function SnowSystem:getSnowShaderValue()
	return self.debug_forcedSnowShaderValue or self.snowShaderValue
end
function SnowSystem:removeAll(force)
	if 0 < self.height or 0 < self.exactHeight or force then
		self:applySnow(SnowSystem.DELTA_REMOVE_ALL)
		self.height = 0
		self.exactHeight = 0
		self:updateSnowShader()
	end
end
function SnowSystem:getHeight()
	return self.height
end
function SnowSystem:getMaxUpdateTime()
	if g_sleepManager.isSleeping then
		return SnowSystem.MAX_MS_PER_FRAME_SLEEPING
	else
		return SnowSystem.MAX_MS_PER_FRAME
	end
end
function SnowSystem:onSleepChanged(isSleeping)
	setDensityMapHeightUpdateApplyMaxTimePerFrame(self.updater, self:getMaxUpdateTime())
end
function SnowSystem:consoleCommandAddSnow(layers)
	if layers == nil or tonumber(layers) == nil then
		return "Usage: gsSnowAdd layers"
	end
	layers = tonumber(layers)
	local height = self.height + layers * self.layerHeight
	self:setSnowHeight(height)
	return string.format("New height is %.3f", height)
end
function SnowSystem:consoleCommandSetSnow(height)
	if height == nil or tonumber(height) == nil then
		return "Usage: gsSnowSet height"
	end
	height = tonumber(height)
	self:setSnowHeight(height)
	return string.format("New height is %.3f", height)
end
function SnowSystem:consoleCommandResetSnow()
	self:removeAll()
end
function SnowSystem:consoleCommandSetSnowShader(snowShaderValue)
	self.debug_forcedSnowShaderValue = tonumber(snowShaderValue)
	self:updateSnowShader()
	local returnStr = "forcedSnowShaderValue=" .. tostring(self.debug_forcedSnowShaderValue)
	if self.debug_forcedSnowShaderValue ~= nil then
		returnStr = returnStr .. "\nUse gsSnowShaderSet without parameter to use weather again"
		return returnStr
	else
		returnStr = returnStr .. "\nUsing value from weather simulation"
		return returnStr
	end
end
function SnowSystem:consoleCommandSalt(radius)
	radius = tonumber(radius) or 5
	local x, _, z = getWorldTranslation(g_cameraManager:getActiveCamera())
	local startWorldX = x - radius
	local startWorldZ = z - radius
	local widthWorldX = x + radius
	local widthWorldZ = z - radius
	local heightWorldX = x - radius
	local heightWorldZ = z + radius
	self:saltArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
end
