-- Local values: WeatherObjectHail_mt
WeatherObjectHail = {}
local WeatherObjectHail_mt = Class(WeatherObjectHail, WeatherObject)

-- Upvalues: WeatherObjectHail_mt
-- Local values: self
function WeatherObjectHail.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, rainUpdater, customMt)
	-- upvalues: (copy) WeatherObjectHail_mt
	local v8_ = WeatherObject.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, rainUpdater, customMt or WeatherObjectHail_mt)
	v8_.destructionArea = DensityMapCircle.new()
	v8_.perlinPercentage = nil
	v8_.spotRadius = nil
	v8_.nextDestructionTime = nil
	v8_.destructionDuration = nil
	return v8_
end

function WeatherObjectHail:getIsAvailable()
	return g_currentMission.missionInfo.disasterDestructionState ~= DisasterDestructionState.DISABLED
end

-- Local values: variation
function WeatherObjectHail:loadVariation(xmlFile, key, cloudPresets, baseDirectory)
	local v14_ = WeatherObjectHail:superClass().loadVariation(self, xmlFile, key, cloudPresets, baseDirectory)
	v14_.numDestructionsPerHour = xmlFile:getInt(key .. ".hail#numDestructionsPerHour", 150)
	v14_.minPerlinPercentage = xmlFile:getInt(key .. ".hail#minPerlinPercentage", 4500)
	v14_.maxPerlinPercentage = xmlFile:getInt(key .. ".hail#maxPerlinPercentage", 7000)
	v14_.spotRadius = xmlFile:getInt(key .. ".hail#spotRadius", 7)
	return v14_
end

-- Local values: terrainSizeHalf, x, z, radius, numSegments
function WeatherObjectHail:update(scaledDt)
	WeatherObjectHail:superClass().update(self, scaledDt)
	if self.nextDestructionTime == nil then
		return
	elseif g_currentMission.missionInfo.disasterDestructionState == DisasterDestructionState.ENABLED then
		self.nextDestructionTime = self.nextDestructionTime - scaledDt
		while self.nextDestructionTime < 0 do
			local v17_ = g_currentMission.terrainSize * 0.5
			local v18_ = math.random(-v17_, v17_)
			local v19_ = math.round(v18_)
			local v20_ = math.random(-v17_, v17_)
			local v21_ = math.round(v20_)
			local v22_ = self.spotRadius
			self.destructionArea:updateFromWorldPosition(v19_, v21_, v22_, 6)
			FSDensityMapUtil.updateDisasterArea(self.destructionArea, self.perlinPercentage)
			self.nextDestructionTime = self.nextDestructionTime + self.destructionDuration
		end
	end
end

-- Local values: variationIndex, variation
function WeatherObjectHail:activate(weatherInstance, blendDuration, isSavegameInit)
	WeatherObjectHail:superClass().activate(self, weatherInstance, blendDuration)
	if g_server == nil then
		return
	elseif g_currentMission.missionInfo.disasterDestructionState ~= DisasterDestructionState.DISABLED then
		local v26_ = weatherInstance.variationIndex
		local v27_ = self.variations[v26_]
		self.perlinPercentage = weatherInstance.perlinPercentage
		local v28_ = 3600000 / v27_.numDestructionsPerHour
		self.destructionDuration = math.ceil(v28_)
		self.spotRadius = v27_.spotRadius
		self.nextDestructionTime = blendDuration
	end
end

function WeatherObjectHail:deactivate(blendDuration)
	WeatherObjectHail:superClass().deactivate(self, blendDuration)
	if g_server ~= nil then
		self.nextDestructionTime = nil
	end
end

-- Local values: variationIndex, variation
function WeatherObjectHail.initInstanceData(weatherObject, instance)
	local v33_ = instance.variationIndex
	local v34_ = weatherObject.variations[v33_]
	instance.perlinPercentage = math.random(v34_.minPerlinPercentage, v34_.maxPerlinPercentage)
end

function WeatherObjectHail.saveInstanceDataToXMLFile(xmlFile, key, instance)
	xmlFile:setInt(key .. ".hail#perlinPercentage", instance.perlinPercentage or 1500)
end

function WeatherObjectHail.loadInstanceDataFromXMLFile(xmlFile, key, instance)
	instance.perlinPercentage = xmlFile:getInt(key .. ".hail#perlinPercentage", 1500)
	return true
end
