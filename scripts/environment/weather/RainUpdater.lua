RainUpdater = {}
RainUpdater.WEATHER_TYPE_TO_RAIN_SIM_WEATHER_TYPE = { [WeatherType.RAIN] = RainSimWeatherType.RAIN, [WeatherType.SNOW] = RainSimWeatherType.SNOW, [WeatherType.HAIL] = RainSimWeatherType.HAIL }
local RainUpdater_mt = Class(RainUpdater)
function RainUpdater.new(customMt)
	local self = setmetatable({}, customMt or RainUpdater_mt)
	self.presets = {}
	self.types = {}
	self.windDirX = 1
	self.windDirZ = 0
	self.alpha = 0
	self.duration = 1
	self.isDirty = true
	self.isVisible = true
	self.rainfallScale = 0
	self.snowfallScale = 0
	self.hailfallScale = 0
	return self
end
function RainUpdater:load(xmlFile, key, baseDirectory)
	local numTypes = 0
	for _, rainTypeKey in xmlFile:iterator(key .. ".types.type") do
		local id = xmlFile:getString(rainTypeKey .. "#id")
		local filename = xmlFile:getString(rainTypeKey .. "#filename")
		if id == nil then
			Logging.xmlWarning(xmlFile, "Missing id for rain type in '%s'", key)
		elseif filename == nil then
			Logging.xmlWarning(xmlFile, "Missing filename for rain type in '%s'", key)
		else
			local idUpper = string.upper(id)
			if self.types[idUpper] ~= nil then
				Logging.xmlWarning(xmlFile, "RainType '%s' already defined in '%s'", id, key)
			else
				filename = Utils.getFilename(filename, baseDirectory)
				local spawnBoxWidth = xmlFile:getFloat(rainTypeKey .. ".settings#spawnBoxWidth", 50)
				local spawnBoxDepth = xmlFile:getFloat(rainTypeKey .. ".settings#spawnBoxDepth", 50)
				local spawnBoxHeight = xmlFile:getFloat(rainTypeKey .. ".settings#spawnBoxHeight", 60)
				local cameraVelocityMultiplier = xmlFile:getFloat(rainTypeKey .. ".settings#cameraVelocityMultiplier", 1)
				local settings = RainSettings.new()
				settings.dropsMultiplier = 0
				local rainType = { typeId = idUpper, rootNode = nil, node = nil, loadRequestId = nil, values = settings, spawnBoxWidth = spawnBoxWidth, spawnBoxDepth = spawnBoxDepth, spawnBoxHeight = spawnBoxHeight, cameraVelocityMultiplier = cameraVelocityMultiplier, loadRequestId = g_i3DManager:loadI3DFileAsync(filename, false, false, self.onRainI3DLoaded, self, rainType) }
				self.types[idUpper] = rainType
				numTypes = numTypes + 1
			end
		end
	end
	if 0 < numTypes then
		self:loadPresets(xmlFile, key)
	end
	return false
end
function RainUpdater:onRainI3DLoaded(i3dNode, failedReason, rainType)
	rainType.loadRequestId = nil
	if i3dNode ~= nil and i3dNode ~= 0 then
		local rainShape = getChildAt(i3dNode, 0)
		local rainNode = getGeometry(rainShape)
		link(getRootNode(), i3dNode)
		setCullOverride(i3dNode, true)
		setVisibility(i3dNode, false)
		rainType.rootNode = i3dNode
		rainType.node = rainNode
		setRainSpawnBoxParameters(rainNode, rainType.spawnBoxHeight, rainType.spawnBoxWidth, rainType.spawnBoxDepth)
		setRainCameraVelocityMultiplier(rainNode, rainType.cameraVelocityMultiplier)
		local weatherType = WeatherType.getByName(rainType.typeId)
		if weatherType ~= nil then
			local rainSimWeatherType = RainUpdater.WEATHER_TYPE_TO_RAIN_SIM_WEATHER_TYPE[weatherType] or RainSimWeatherType.DEFAULT
			setRainWeatherType(rainNode, rainSimWeatherType)
			return
		end
	end
	Logging.warning("Failed to load rain i3d file!'")
end
function RainUpdater:delete()
	self:reset()
end
function RainUpdater:reset()
	for _, rainType in pairs(self.types) do
		if rainType.loadRequestId ~= nil then
			g_i3DManager:cancelStreamI3DFile(rainType.loadRequestId)
			rainType.loadRequestId = nil
		end
		if rainType.rootNode == nil then
			continue
		end
		delete(rainType.rootNode)
	end
	self.presets = {}
	self.types = {}
	self.windDirX = 1
	self.windDirZ = 0
	self.alpha = 0
	self.duration = 1
	self.isDirty = true
	self.isVisible = true
end
function RainUpdater:update(scaledDt)
	if self.alpha ~= 1 or self.isDirty then
		local alpha = math.min(self.alpha + scaledDt / self.duration, 1)
		self:setAlpha(alpha)
		self.isDirty = false
	end
	setSharedShaderParameter(Shader.PARAM_SHARED_RAIN_SCALE, self.rainfallScale)
end
function RainUpdater:setVisible(isVisible)
	self.isVisible = isVisible
	for _, rainType in pairs(self.types) do
		local values = rainType.values
		local rainNode = rainType.node
		local rainRootNode = rainType.rootNode
		if rainNode == nil then
			continue
		end
		setVisibility(rainRootNode, self.isVisible and 0 < values.dropsMultiplier)
	end
end
function RainUpdater:setAlpha(alpha)
	self.alpha = alpha
	local lastRain = self.lastRain
	local targetRain = self.targetRain
	if lastRain ~= nil and targetRain ~= nil then
		if lastRain.typeId == targetRain.typeId then
			local rainType = self.types[lastRain.typeId]
			local values = rainType.values
			values.dropsMultiplier = MathUtil.lerp(lastRain.dropsMultiplier, targetRain.dropsMultiplier, alpha)
			values.maxDropsMultiplier = MathUtil.lerp(lastRain.maxDropsMultiplier, targetRain.maxDropsMultiplier, alpha)
			values.turbulence = MathUtil.lerp(lastRain.turbulence, targetRain.turbulence, alpha)
			values.turbulenceTimeScale = MathUtil.lerp(lastRain.turbulenceTimeScale, targetRain.turbulenceTimeScale, alpha)
			values.turbulencePulseDuration = MathUtil.lerp(lastRain.turbulencePulseDuration, targetRain.turbulencePulseDuration, alpha)
			values.spawnVelocityX = MathUtil.lerp(lastRain.spawnVelocityX, targetRain.spawnVelocityX, alpha)
			values.spawnVelocityY = MathUtil.lerp(lastRain.spawnVelocityY, targetRain.spawnVelocityY, alpha)
			values.spawnVelocityZ = MathUtil.lerp(lastRain.spawnVelocityZ, targetRain.spawnVelocityZ, alpha)
			values.turbulenceFrequency = MathUtil.lerp(lastRain.turbulenceFrequency, targetRain.turbulenceFrequency, alpha)
			values.rainfallScale = MathUtil.lerp(lastRain.rainfallScale, targetRain.rainfallScale, alpha)
			values.snowfallScale = MathUtil.lerp(lastRain.snowfallScale, targetRain.snowfallScale, alpha)
			values.hailfallScale = MathUtil.lerp(lastRain.hailfallScale, targetRain.hailfallScale, alpha)
			values.bounceRandomFactor = MathUtil.lerp(lastRain.bounceRandomFactor, targetRain.bounceRandomFactor, alpha)
			values.bounceRestitution = MathUtil.lerp(lastRain.bounceRestitution, targetRain.bounceRestitution, alpha)
			if 1 <= alpha then
				values.maxBounces = targetRain.maxBounces
			end
		else
			if lastRain ~= nil then
				local rainType = self.types[lastRain.typeId]
				local values = rainType.values
				values.dropsMultiplier = MathUtil.lerp(lastRain.dropsMultiplier, 0, alpha)
				values.rainfallScale = MathUtil.lerp(lastRain.rainfallScale, 0, alpha)
				values.snowfallScale = MathUtil.lerp(lastRain.snowfallScale, 0, alpha)
				values.hailfallScale = MathUtil.lerp(lastRain.hailfallScale, 0, alpha)
			end
			if targetRain ~= nil then
				local rainType = self.types[targetRain.typeId]
				local values = rainType.values
				values.dropsMultiplier = MathUtil.lerp(0, targetRain.dropsMultiplier, alpha)
				values.rainfallScale = MathUtil.lerp(0, targetRain.rainfallScale, alpha)
				values.snowfallScale = MathUtil.lerp(0, targetRain.snowfallScale, alpha)
				values.hailfallScale = MathUtil.lerp(0, targetRain.hailfallScale, alpha)
			end
		end
	end
	local rainfallScale = 0
	local snowfallScale = 0
	local hailfallScale = 0
	for _, rainType in pairs(self.types) do
		local values = rainType.values
		local rainNode = rainType.node
		local rainRootNode = rainType.rootNode
		local isLastRain = self.lastRain ~= nil and self.lastRain.typeId == rainType.typeId
		local isTargetRain = self.targetRain ~= nil and self.targetRain.typeId == rainType.typeId
		if isLastRain or isTargetRain then
			rainfallScale = math.max(values.rainfallScale, rainfallScale)
			snowfallScale = math.max(values.snowfallScale, snowfallScale)
			hailfallScale = math.max(values.hailfallScale, hailfallScale)
		end
		if rainNode == nil then
			continue
		end
		setRainWindForce(rainNode, 0, 0)
		setRainActiveDropsMultiplier(rainNode, values.dropsMultiplier * values.maxDropsMultiplier)
		setRainTurbulenceParameters(rainNode, values.turbulence, values.turbulenceTimeScale, values.turbulencePulseDuration, values.turbulenceFrequency)
		setRainMaxBounces(rainNode, math.floor(values.maxBounces))
		setRainBounceRandomFactor(rainNode, values.bounceRandomFactor)
		setRainBounceRestitution(rainNode, values.bounceRestitution)
		setVisibility(rainRootNode, self.isVisible and 0 < values.dropsMultiplier)
		self:setCombinedSpawnVelocity(self.windDirX, self.windDirZ, rainNode, values)
	end
	self.rainfallScale = rainfallScale
	self.snowfallScale = snowfallScale
	self.hailfallScale = hailfallScale
end
function RainUpdater:setTargetRain(targetRain, duration)
	self.alpha = 0
	self.duration = math.max(1, duration)
	self.lastRain = self.targetRain
	self.targetRain = targetRain
	for _, rainType in pairs(self.types) do
		local isLastRain = self.lastRain ~= nil and self.lastRain.typeId == rainType.typeId
		local isTargetRain = targetRain ~= nil and targetRain.typeId == rainType.typeId
		local isVisible = isLastRain or isTargetRain
		if isTargetRain then
			if self.lastRain == nil or not isLastRain then
				rainType.values:copyAttributes(targetRain)
			end
		elseif isLastRain then
			if targetRain == nil then
				rainType.values:copyAttributes(self.lastRain)
			end
		end
		if isVisible then
			continue
		end
		rainType.values.dropsMultiplier = 0
	end
end
function RainUpdater:setValues(rainTypeId, rainSettings)
	local rainType = self.types[rainTypeId]
	rainType.values:copyAttributes(rainSettings)
end
function RainUpdater:setCombinedSpawnVelocity(windDirX, windDirZ, rainNode, rainValues)
	local ySpeed = rainValues.spawnVelocityY
	local xSpeed = (rainValues.spawnVelocityX + windDirX) / 2
	local zSpeed = (rainValues.spawnVelocityZ + windDirZ) / 2
	local presetLength = MathUtil.vector3Length(rainValues.spawnVelocityX, rainValues.spawnVelocityY, rainValues.spawnVelocityZ)
	local averagedLength = MathUtil.vector3Length(xSpeed, ySpeed, zSpeed)
	local newXSpeed = xSpeed * presetLength / averagedLength
	local newZSpeed = zSpeed * presetLength / averagedLength
	if rainNode ~= nil then
		setRainSpawnVelocity(rainNode, newXSpeed, ySpeed, newZSpeed)
	end
end
function RainUpdater:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
	self.windDirX = windDirX * windVelocity / 4
	self.windDirZ = windDirZ * windVelocity / 4
	for _, rainType in pairs(self.types) do
		local rainNode = rainType.node
		self:setCombinedSpawnVelocity(self.windDirX, self.windDirZ, rainNode, rainType.values)
	end
end
function RainUpdater:setShallowWaterSimulation(shallowWaterSimulation)
	if shallowWaterSimulation == nil then
		shallowWaterSimulation = 0
	end
	for _, rainType in pairs(self.types) do
		local rainNode = rainType.node
		if rainNode == nil then
			continue
		end
		setRainShallowWaterSimulation(rainNode, shallowWaterSimulation)
	end
end
function RainUpdater:getHailFallScale()
	return self.hailfallScale
end
function RainUpdater:getRainFallScale()
	return self.rainfallScale
end
function RainUpdater:getSnowFallScale()
	return self.snowfallScale
end
function RainUpdater:createRainSettingsFromPreset(presetId)
	local preset = self:getPreset(presetId)
	if preset == nil then
		return nil
	else
		return preset:clone()
	end
end
function RainUpdater:getPresets()
	return self.presets
end
function RainUpdater:getPreset(presetId)
	local upperPresetId = string.upper(presetId)
	return self.presets[upperPresetId]
end
function RainUpdater:loadPresets(xmlFile, key)
	local numPresets = 0
	for _, presetKey in xmlFile:iterator(key .. ".presets.preset") do
		local id = xmlFile:getString(presetKey .. "#id")
		if id == nil then
			Logging.xmlWarning(xmlFile, "Missing rain preset id for '%s'", presetKey)
			break
		end
		local idUpper = string.upper(id)
		if self.presets[idUpper] ~= nil then
			Logging.xmlWarning(xmlFile, "Rain preset id '%s' already exists for '%s'", id, presetKey)
			break
		end
		local rainTypeId = xmlFile:getString(presetKey .. "#typeId")
		if rainTypeId == nil then
			Logging.xmlWarning(xmlFile, "Missing rain preset type for '%s'", presetKey)
			break
		end
		local rainTypeIdUpper = string.upper(rainTypeId)
		if self.types[rainTypeIdUpper] == nil then
			Logging.xmlWarning(xmlFile, "Rain type '%s' is not defined for '%s'", rainTypeId, presetKey)
			break
		end
		local preset = RainSettings.new()
		if preset:load(xmlFile, presetKey) then
			preset.presetId = idUpper
			preset.typeId = rainTypeIdUpper
		end
		self.presets[idUpper] = preset
		numPresets = numPresets + 1
	end
	return 0 < numPresets
end
function RainUpdater:savePresets(xmlFile, key, presetId)
	for _, presetKey in xmlFile:iterator(key .. ".presets.preset") do
		local id = string.upper(xmlFile:getString(presetKey .. "#id"))
		if presetId == nil or id == presetId then
			local preset = self.presets[id]
			if preset == nil then
				continue
			end
			preset:save(xmlFile, presetKey)
		end
	end
end
function RainUpdater:addDebugValues(data)
	table.insert(data, { name = "Type", value = "" })
	table.insert(data, { name = "DropsMultiplier", value = "" })
	table.insert(data, { name = "MaxDropsMultiplier", value = "" })
	table.insert(data, { name = "turbulence", value = "" })
	table.insert(data, { name = "turbulenceTimeScale", value = "" })
	table.insert(data, { name = "turbulencePulseDuration", value = "" })
	table.insert(data, { name = "turbulenceFrequency", value = "" })
	table.insert(data, { name = "spawnVelocityX", value = "" })
	table.insert(data, { name = "spawnVelocityY", value = "" })
	table.insert(data, { name = "spawnVelocityZ", value = "" })
	table.insert(data, { name = "maxBounces", value = "" })
	table.insert(data, { name = "bounceRandomFactor", value = "" })
	table.insert(data, { name = "bounceRestitution", value = "" })
	table.insert(data, { name = "bounceRestitution", value = "" })
	table.insert(data, { name = "", value = "" })
	table.insert(data, { name = "", value = "" })
	table.insert(data, { name = "RainfallScale", value = string.format("%.3f", self.rainfallScale) })
	table.insert(data, { name = "HailfallScale", value = string.format("%.3f", self.hailfallScale) })
	table.insert(data, { name = "SnowfallScale", value = string.format("%.3f", self.snowfallScale) })
	table.insert(data, { name = "", value = "", columnOffset = 0.005 })
	for _, typeData in pairs(self.types) do
		table.insert(data, { name = "", value = string.format("%s", typeData.typeId) })
		table.insert(data, { name = "", value = string.format("%.2f", typeData.values.dropsMultiplier) })
		table.insert(data, { name = "", value = string.format("%.3f", typeData.values.maxDropsMultiplier) })
		table.insert(data, { name = "", value = string.format("%.2f", typeData.values.turbulence) })
		table.insert(data, { name = "", value = string.format("%.2f", typeData.values.turbulenceTimeScale) })
		table.insert(data, { name = "", value = string.format("%.2f", typeData.values.turbulencePulseDuration) })
		table.insert(data, { name = "", value = string.format("%.2f", typeData.values.turbulenceFrequency) })
		table.insert(data, { name = "", value = string.format("%.2f", typeData.values.spawnVelocityX) })
		table.insert(data, { name = "", value = string.format("%.2f", typeData.values.spawnVelocityY) })
		table.insert(data, { name = "", value = string.format("%.2f", typeData.values.spawnVelocityZ) })
		table.insert(data, { name = "", value = string.format("%.2f", typeData.values.maxBounces) })
		table.insert(data, { name = "", value = string.format("%.2f", typeData.values.bounceRandomFactor) })
		table.insert(data, { name = "", value = string.format("%.2f", typeData.values.bounceRestitution) })
		table.insert(data, { name = "", value = "", columnOffset = 0.03 })
	end
end
