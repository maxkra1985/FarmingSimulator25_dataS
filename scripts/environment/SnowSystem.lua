-- Local values: SnowSystem_mt
SnowSystem = {}
SnowSystem.MAX_HEIGHT = 0.5
SnowSystem.MIN_LAYER_HEIGHT = 0.06
SnowSystem.MAX_MS_PER_FRAME = 1
SnowSystem.MAX_MS_PER_FRAME_SLEEPING = 3
SnowSystem.DELTA_REMOVE_ALL = -100
local SnowSystem_mt = Class(SnowSystem)

-- Upvalues: SnowSystem_mt
-- Local values: self
function SnowSystem.new(mission, isServer, customMt)
	-- upvalues: (copy) SnowSystem_mt
	local v5_ = customMt or SnowSystem_mt
	local v6_ = setmetatable({}, v5_)
	v6_.mission = mission
	v6_.isServer = isServer
	v6_.updater = nil
	v6_.updateQueue = {}
	v6_.height = 0
	v6_.exactHeight = 0
	v6_.snowShaderValue = 0
	v6_.vehicleWakeUpIndex = 0
	v6_.vehicleWakeUpDelay = 500
	v6_.vehicleWakeUpTimer = 0
	v6_.itemWakeUpIndex = 0
	v6_.itemWakeUpDelay = 100
	v6_.itemWakeUpTimer = 0
	setSharedShaderParameter(Shader.PARAM_SHARED_SNOW, 0)
	if v6_.isServer then
		g_messageCenter:subscribe(MessageType.SLEEPING, v6_.onSleepChanged, v6_)
	end
	return v6_
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

-- Local values: xmlFile, _, key, delta
function SnowSystem:loadFromXMLFile(filename)
	local v12_ = XMLFile.load("environment", filename)
	if v12_ ~= nil then
		self.height = v12_:getFloat("environment.snow#physicalHeight", self.height)
		self.exactHeight = v12_:getFloat("environment.snow#height", self.exactHeight)
		for _, v13_ in v12_:iterator("environment.snow.queue.delta") do
			local v14_ = v12_:getFloat(v13_)
			local v15_ = self.updateQueue
			table.insert(v15_, v14_)
		end
		if self.currentApplyingDelta == nil and #self.updateQueue > 0 then
			self.startPendingQueueTask = true
		end
		self.currentApplyingDelta = v12_:getFloat("environment.snow.queue#current")
		v12_:delete()
	end
	if g_currentMission.environment.weather.snowHeight == 0 and self.exactHeight ~= 0 then
		Logging.info("Weather indicates there must be no snow, snow system disagrees. Resetting snow.")
		self:setSnowHeight(0)
	end
	self:updateSnowShader()
end

-- Local values: xmlFile
function SnowSystem:saveToXMLFile(file, key)
	local v_u_19_ = XMLFile.wrap(file)
	v_u_19_:setFloat(key .. "#physicalHeight", self.height)
	v_u_19_:setFloat(key .. "#height", self.exactHeight)
	if self.currentApplyingDelta ~= nil then
		v_u_19_:setFloat(key .. ".queue#current", self.currentApplyingDelta)
	end
	v_u_19_:setSortedTable("environment.snow.queue.delta", self.updateQueue, function(p20_, p21_)
		-- upvalues: (copy) v_u_19_
		v_u_19_:setFloat(p20_, p21_)
	end)
	v_u_19_:delete()
end

function SnowSystem:saveState(directory)
	saveDensityMapHeightUpdaterStateToFile(self.updater, directory .. "/snow_state.xml")
end

-- Local values: terrainDetailHeightId, modifiers, sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, blockMaskId, blockMaskFirstChannel, blockMaskNumChannels, dir, success, delta
function SnowSystem:onTerrainLoad(terrainRootNode)
	local v25_ = self.mission.terrainDetailHeightId
	self.snowHeightTypeIndex = g_densityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeIndex(FillType.SNOW)
	local v26_ = {
		["height"] = {}
	}
	v26_.height.modifierHeight = DensityMapModifier.new(v25_, getDensityMapHeightFirstChannel(v25_), getDensityMapHeightNumChannels(v25_))
	v26_.height.filterHeight = DensityMapFilter.new(v26_.height.modifierHeight)
	v26_.height.filterType = DensityMapFilter.new(v25_, g_densityMapHeightManager.heightTypeFirstChannel, g_densityMapHeightManager.heightTypeNumChannels)
	v26_.height.filterSnowType = DensityMapFilter.new(v25_, g_densityMapHeightManager.heightTypeFirstChannel, g_densityMapHeightManager.heightTypeNumChannels)
	v26_.height.filterSnowType:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
	v26_.fillType = {}
	v26_.fillType.modifierType = DensityMapModifier.new(v25_, g_densityMapHeightManager.heightTypeFirstChannel, g_densityMapHeightManager.heightTypeNumChannels)
	v26_.fillType.filterHeight = DensityMapFilter.new(v25_, getDensityMapHeightFirstChannel(v25_), getDensityMapHeightNumChannels(v25_))
	v26_.fillType.filterType = DensityMapFilter.new(v26_.fillType.modifierType)
	local v27_, v28_, v29_ = self.mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
	v26_.sprayLevel = {}
	v26_.sprayLevel.modifier = DensityMapModifier.new(v27_, v28_, v29_, g_terrainNode)
	self.modifiers = v26_
	self.layerHeight = 1 / g_densityMapHeightManager.heightToDensityValue
	if self.isServer then
		self.updater = g_densityMapHeightManager.terrainDetailHeightUpdater
		setDensityMapHeightUpdateType(self.updater, self.snowHeightTypeIndex)
		setDensityMapHeightUpdateApplyMaxTimePerFrame(self.updater, SnowSystem.MAX_MS_PER_FRAME)
		if self.indoorMask:hasMask() then
			local v30_, v31_, v32_ = self.indoorMask:getDensityMapData()
			setDensityMapHeightUpdateApplyBlockMask(self.updater, v30_, v31_, v32_)
		end
		if self.missionInfo.isValid and self.missionInfo.densityMapRevision == g_densityMapRevision then
			local v33_ = self.missionInfo.savegameDirectory
			local v34_, v35_ = loadDensityMapHeightUpdaterStateFromFile(self.updater, v33_ .. "/snow_state.xml")
			if v34_ and v35_ > -1 then
				self.currentApplyingDelta = v35_
			end
		end
		setDensityMapHeightUpdateApplyFinishedCallback(self.updater, "onApplicationFinished", self)
	end
end

-- Local values: delta, vehicle, item
function SnowSystem:update(dt)
	if self.isServer and self.startPendingQueueTask then
		local v38_ = table.remove(self.updateQueue, 1)
		if v38_ ~= nil then
			self:startApplication(v38_)
		end
		self.startPendingQueueTask = nil
	end
	if self.vehicleWakeUpIndex > 0 then
		self.vehicleWakeUpTimer = self.vehicleWakeUpTimer + dt
		if self.vehicleWakeUpTimer > self.vehicleWakeUpDelay then
			local v39_ = self.mission.vehicleSystem.vehicles[self.vehicleWakeUpIndex]
			if v39_ == nil then
				self.vehicleWakeUpIndex = 0
			else
				v39_:wakeUp()
				self.vehicleWakeUpIndex = self.vehicleWakeUpIndex + 1
			end
			self.vehicleWakeUpTimer = 0
		end
	end
	if self.itemWakeUpIndex > 0 then
		self.itemWakeUpTimer = self.itemWakeUpTimer + dt
		if self.itemWakeUpTimer > self.itemWakeUpDelay then
			local v40_ = self.mission.itemSystem.sortedItemsToSave[self.itemWakeUpIndex]
			if v40_ == nil then
				self.itemWakeUpIndex = 0
			else
				if v40_.item.wakeUp ~= nil then
					v40_.item:wakeUp()
				end
				self.itemWakeUpIndex = self.itemWakeUpIndex + 1
			end
			self.itemWakeUpTimer = 0
		end
	end
end

-- Local values: folded, lastItemDelta
function SnowSystem:applySnow(delta)
	if self.isServer then
		if self.currentApplyingDelta == nil then
			self:startApplication(delta)
		else
			local v43_ = false
			if #self.updateQueue > 0 then
				local v44_ = self.updateQueue[#self.updateQueue]
				if v44_ <= SnowSystem.DELTA_REMOVE_ALL then
					v43_ = delta < 0 and true or v43_
				else
					self.updateQueue[#self.updateQueue] = v44_ + delta
					v43_ = true
				end
			end
			if not v43_ then
				self.updateQueue[#self.updateQueue + 1] = delta
				return
			end
		end
	end
end

-- Local values: blockMaskId, blockMaskFirstChannel, blockMaskNumChannels, heightLimit, useCollisionMap
function SnowSystem:startApplication(delta)
	local v47_, v48_, v49_ = self.indoorMask:getDensityMapData()
	local v50_ = SnowSystem.MAX_HEIGHT
	local v51_ = delta < 0 and 0 or v50_
	self.currentApplyingDelta = delta
	local v52_ = delta < 0 and 0 or v47_
	applyDensityMapHeightUpdate(self.updater, self.snowHeightTypeIndex, delta, v51_, false, false, v52_, v48_, v49_, "onApplicationFinished", self, self:getMaxUpdateTime(), g_currentMission.tireTrackSystem.tireTrackSystemId)
end

-- Local values: currentDelta, delta
function SnowSystem:onApplicationFinished()
	local v54_ = self.currentApplyingDelta
	self.currentApplyingDelta = nil
	if v54_ > 0 then
		self:removeSnowUnderObjects(v54_)
	else
		self:onHeightChanged(v54_)
	end
	if #self.updateQueue > 0 then
		local v55_ = self.updateQueue[1]
		table.remove(self.updateQueue, 1)
		self:startApplication(v55_)
	end
end

function SnowSystem:onHeightChanged(delta)
	self.vehicleWakeUpIndex = 1
	self.itemWakeUpIndex = 1
	local v57_ = g_messageCenter
	local v58_ = MessageType.SNOW_HEIGHT_CHANGED
	local v59_ = self.height / SnowSystem.MAX_HEIGHT
	local v60_ = math.max(v59_, 0)
	local v61_ = self.height
	v57_:publish(v58_, v60_, (math.max(v61_, 0)))
end

-- Local values: _, object, _, vehicle, _, wheel, width, length, x, _, z, x0, _, z0, x1, _, z1, x2, _, z2
function SnowSystem:removeSnowUnderObjects(delta)
	for _, v64_ in pairs(self.mission.itemSystem.itemsToSave) do
		if v64_.item.doDensityMapItemAreaUpdate ~= nil then
			v64_.item:doDensityMapItemAreaUpdate(self.removeSnow, self, delta / self.layerHeight)
		end
	end
	for _, v65_ in pairs(self.mission.vehicleSystem.vehicles) do
		if v65_.spec_wheels ~= nil then
			for _, v66_ in pairs(v65_.spec_wheels.wheels) do
				local v67_ = 0.5 * v66_.physics.width
				local v68_ = 0.5 * v66_.physics.width
				local v69_ = math.min(0.5, v68_)
				local v70_, _, v71_ = localToLocal(v66_.driveNode, v66_.repr, 0, 0, 0)
				local v72_, _, v73_ = localToWorld(v66_.repr, v70_ + v67_, 0, v71_ - v69_)
				local v74_, _, v75_ = localToWorld(v66_.repr, v70_ - v67_, 0, v71_ - v69_)
				local v76_, _, v77_ = localToWorld(v66_.repr, v70_ + v67_, 0, v71_ + v69_)
				self:removeSnow(v72_, v73_, v74_, v75_, v76_, v77_, delta / self.layerHeight)
			end
		end
	end
	self:onHeightChanged(delta)
end

-- Local values: modifiers, modifier, filter1, filter2, density, area, totalArea
function SnowSystem:saltArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v85_ = self.modifiers.height
	local v86_ = v85_.modifierHeight
	local v87_ = v85_.filterType
	local v88_ = v85_.filterHeight
	v86_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v87_:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
	v88_:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
	FSDensityMapUtil.resetDisplacementArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	FSDensityMapUtil.eraseTireTrack(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v89_, v90_, v91_ = v86_:executeSetWithStats(0, v87_, v88_)
	local v92_ = self.modifiers.sprayLevel.modifier
	v92_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v92_:executeSet(0)
	if v89_ ~= 0 then
		local v93_ = self.modifiers.fillType.modifierType
		v93_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v88_:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		v93_:executeSet(0, v88_)
	end
	return v90_, v91_
end

-- Local values: modifiers, modifier, filter, density, area, _
function SnowSystem:getSnowHeightAtArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local v101_ = self.modifiers.height
	local v102_ = v101_.modifierHeight
	local v103_ = v101_.filterType
	v102_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v103_:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
	local v104_, v105_, _ = v102_:executeGet(v103_)
	return v105_ == 0 and 0 or v104_ / v105_ * self.layerHeight
end

-- Local values: layers, modifiers, modifier, filter, modifiers, modifier, filter
function SnowSystem:setSnowHeightAtArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, height)
	local v114_ = height / self.layerHeight
	local v115_ = math.floor(v114_)
	if v115_ > 0 then
		local v116_ = self.modifiers.fillType
		local v117_ = v116_.modifierType
		local v118_ = v116_.filterHeight
		v117_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v118_:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		v117_:executeSet(self.snowHeightTypeIndex, v118_)
	end
	local v119_ = self.modifiers.height
	local v120_ = v119_.modifierHeight
	local v121_ = v119_.filterType
	v120_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v121_:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
	v120_:executeSet(v115_, v121_)
	if v115_ == 0 then
		local v122_ = self.modifiers.fillType
		local v123_ = v122_.modifierType
		local v124_ = v122_.filterHeight
		v123_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v124_:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		v123_:executeSet(0, v124_)
	end
end

-- Local values: modifiers, modifier, filter, density
function SnowSystem:removeSnow(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, layers)
	local v133_ = self.modifiers.height
	local v134_ = v133_.modifierHeight
	local v135_ = v133_.filterType
	v134_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	v135_:setValueCompareParams(DensityValueCompareType.EQUAL, self.snowHeightTypeIndex)
	if v134_:executeAddWithStats(-layers, v135_) ~= 0 then
		local v136_ = self.modifiers.fillType
		local v137_ = v136_.modifierType
		local v138_ = v136_.filterHeight
		v137_:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		v138_:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
		v137_:executeSet(0, v138_)
	end
end

-- Local values: deltaHeight
function SnowSystem:setSnowHeight(height)
	local v141_ = SnowSystem.MAX_HEIGHT
	local v142_ = math.clamp(height, -4.02, v141_)
	self.exactHeight = math.max(v142_, 0)
	self:updateSnowShader()
	if self.height ~= v142_ then
		if self.height > 0 and v142_ <= 0 then
			self:removeAll()
		end
		if self.height < 0 and v142_ > 0 then
			self.height = 0
		elseif self.height < 0 and self.height < v142_ then
			self.height = v142_
		end
		if self.isServer then
			if self.layerHeight == nil then
				return
			end
			local v143_ = v142_ - self.height
			if math.abs(v143_) >= self.layerHeight then
				local v144_ = v142_ - self.height
				self:applySnow(v144_)
				self.height = self.height + v144_
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
	if self.height > 0 or (self.exactHeight > 0 or force) then
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

-- Local values: height
function SnowSystem:consoleCommandAddSnow(layers)
	if layers == nil or tonumber(layers) == nil then
		return "Usage: gsSnowAdd layers"
	end
	local v153_ = tonumber(layers)
	local v154_ = self.height + v153_ * self.layerHeight
	self:setSnowHeight(v154_)
	return string.format("New height is %.3f", v154_)
end

function SnowSystem:consoleCommandSetSnow(height)
	if height == nil or tonumber(height) == nil then
		return "Usage: gsSnowSet height"
	end
	local v157_ = tonumber(height)
	self:setSnowHeight(v157_)
	return string.format("New height is %.3f", v157_)
end

function SnowSystem:consoleCommandResetSnow()
	self:removeAll()
end

-- Local values: returnStr
function SnowSystem:consoleCommandSetSnowShader(snowShaderValue)
	self.debug_forcedSnowShaderValue = tonumber(snowShaderValue)
	self:updateSnowShader()
	local v161_ = self.debug_forcedSnowShaderValue
	local v162_ = "forcedSnowShaderValue=" .. tostring(v161_)
	if self.debug_forcedSnowShaderValue == nil then
		return v162_ .. "\nUsing value from weather simulation"
	else
		return v162_ .. "\nUse gsSnowShaderSet without parameter to use weather again"
	end
end

-- Local values: x, _, z, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ
function SnowSystem:consoleCommandSalt(radius)
	local v165_ = tonumber(radius) or 5
	local v166_, _, v167_ = getWorldTranslation(g_cameraManager:getActiveCamera())
	self:saltArea(v166_ - v165_, v167_ - v165_, v166_ + v165_, v167_ - v165_, v166_ - v165_, v167_ + v165_)
end
