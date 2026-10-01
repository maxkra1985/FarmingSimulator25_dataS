WeatherObjectHail = {}
local WeatherObjectHail_mt = Class(WeatherObjectHail, WeatherObject)
function WeatherObjectHail.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, rainUpdater, customMt)
	local self = WeatherObject.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, rainUpdater, customMt or WeatherObjectHail_mt)
	self.destructionArea = DensityMapCircle.new()
	self.perlinPercentage = nil
	self.spotRadius = nil
	self.nextDestructionTime = nil
	self.destructionDuration = nil
	return self
end
function WeatherObjectHail:getIsAvailable()
	if g_currentMission.missionInfo.disasterDestructionState == DisasterDestructionState.DISABLED then
		return false
	else
		return true
	end
end
function WeatherObjectHail:loadVariation(xmlFile, key, cloudPresets, baseDirectory)
	local variation = WeatherObjectHail:superClass().loadVariation(self, xmlFile, key, cloudPresets, baseDirectory)
	variation.numDestructionsPerHour = xmlFile:getInt(key .. ".hail#numDestructionsPerHour", 150)
	variation.minPerlinPercentage = xmlFile:getInt(key .. ".hail#minPerlinPercentage", 4500)
	variation.maxPerlinPercentage = xmlFile:getInt(key .. ".hail#maxPerlinPercentage", 7000)
	variation.spotRadius = xmlFile:getInt(key .. ".hail#spotRadius", 7)
	return variation
end
function WeatherObjectHail:update(scaledDt)
	WeatherObjectHail:superClass().update(self, scaledDt)
	if self.nextDestructionTime == nil then
		return
	end
	if g_currentMission.missionInfo.disasterDestructionState ~= DisasterDestructionState.ENABLED then
		return
	end
	self.nextDestructionTime = self.nextDestructionTime - scaledDt
	while self.nextDestructionTime < 0 do
		local terrainSizeHalf = g_currentMission.terrainSize * 0.5
		local x = math.round(math.random(-terrainSizeHalf, terrainSizeHalf))
		local z = math.round(math.random(-terrainSizeHalf, terrainSizeHalf))
		local radius = self.spotRadius
		local numSegments = 6
		self.destructionArea:updateFromWorldPosition(x, z, radius, 6)
		FSDensityMapUtil.updateDisasterArea(self.destructionArea, self.perlinPercentage)
		self.nextDestructionTime = self.nextDestructionTime + self.destructionDuration
	end
end
function WeatherObjectHail:activate(weatherInstance, blendDuration, isSavegameInit)
	WeatherObjectHail:superClass().activate(self, weatherInstance, blendDuration)
	if g_server == nil then
		return
	end
	if g_currentMission.missionInfo.disasterDestructionState ~= DisasterDestructionState.DISABLED then
		local variationIndex = weatherInstance.variationIndex
		local variation = self.variations[variationIndex]
		self.perlinPercentage = weatherInstance.perlinPercentage
		self.destructionDuration = math.ceil(3600000 / variation.numDestructionsPerHour)
		self.spotRadius = variation.spotRadius
		self.nextDestructionTime = blendDuration
	end
end
function WeatherObjectHail:deactivate(blendDuration)
	WeatherObjectHail:superClass().deactivate(self, blendDuration)
	if g_server == nil then
		return
	else
		self.nextDestructionTime = nil
	end
end
function WeatherObjectHail.initInstanceData(weatherObject, instance)
	local variationIndex = instance.variationIndex
	local variation = weatherObject.variations[variationIndex]
	instance.perlinPercentage = math.random(variation.minPerlinPercentage, variation.maxPerlinPercentage)
end
function WeatherObjectHail.saveInstanceDataToXMLFile(xmlFile, key, instance)
	xmlFile:setInt(key .. ".hail#perlinPercentage", instance.perlinPercentage or 1500)
end
function WeatherObjectHail.loadInstanceDataFromXMLFile(xmlFile, key, instance)
	instance.perlinPercentage = xmlFile:getInt(key .. ".hail#perlinPercentage", 1500)
	return true
end
