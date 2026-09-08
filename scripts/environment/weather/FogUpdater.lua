-- Local values: FogUpdater_mt
FogUpdater = {}
local FogUpdater_mt = Class(FogUpdater)

-- Upvalues: FogUpdater_mt
-- Local values: self
function FogUpdater.new(customMt)
	-- upvalues: (copy) FogUpdater_mt
	local v3_ = customMt or FogUpdater_mt
	local v4_ = setmetatable({}, v3_)
	v4_.isDebugEnabled = false
	v4_.isDirty = false
	v4_.alpha = 1
	v4_.visibilityAlpha = 1
	v4_.duration = 1
	v4_.lastFog = FogSettings.new()
	v4_.targetFog = FogSettings.new()
	v4_.currentFog = FogSettings.new()
	v4_.fadeDuration = 1800000
	if not g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission:getIsServer() then
		addConsoleCommand("gsWeatherSetFog", "Sets fog values", "consoleCommandWeatherSetFog", v4_, "enabled;coverageEdge0;coverageEdge1;groundFogLevelDensity;groundFogExtraHeight;groundFogMinVallyDepth;heightFogMaxHeight;heightFogLevelDensity")
	end
	setGroundFogWind(0, 1, 0)
	setGroundFogVolumeNoiseWind(0, 0, 1, 0)
	return v4_
end

function FogUpdater:delete()
	removeConsoleCommand("gsWeatherSetFog")
end

-- Local values: alpha, currentFog, lastFog, targetFog, isFogPossible, needChange, fadeDir, currentFog, coverageEdge0, coverageEdge1
function FogUpdater:update(scaledDt)
	if not self.isDebugEnabled then
		if self.alpha ~= 1 then
			local v7_ = self.alpha + scaledDt / self.duration
			self.alpha = math.min(v7_, 1)
			local v8_ = self.alpha
			local v9_ = self.currentFog
			local v10_ = self.lastFog
			local v11_ = self.targetFog
			v9_.groundFogCoverageEdge0 = MathUtil.lerp(v10_.groundFogCoverageEdge0, v11_.groundFogCoverageEdge0, v8_)
			v9_.groundFogCoverageEdge1 = MathUtil.lerp(v10_.groundFogCoverageEdge1, v11_.groundFogCoverageEdge1, v8_)
			v9_.groundFogExtraHeight = MathUtil.lerp(v10_.groundFogExtraHeight, v11_.groundFogExtraHeight, v8_)
			v9_.groundFogGroundLevelDensity = MathUtil.lerp(v10_.groundFogGroundLevelDensity, v11_.groundFogGroundLevelDensity, v8_)
			v9_.groundFogMinValleyDepth = MathUtil.lerp(v10_.groundFogMinValleyDepth, v11_.groundFogMinValleyDepth, v8_)
			v9_.heightFogMaxHeight = MathUtil.lerp(v10_.heightFogMaxHeight, v11_.heightFogMaxHeight, v8_)
			v9_.heightFogGroundLevelDensity = MathUtil.lerp(v10_.heightFogGroundLevelDensity, v11_.heightFogGroundLevelDensity, v8_)
			self.isDirty = true
		end
		local v12_ = self:getIsFogPossible()
		local v13_ = false
		local v14_ = 1
		if v12_ and self.visibilityAlpha < 1 then
			v13_ = true
			v14_ = 1
		elseif not v12_ and self.visibilityAlpha > 0 then
			v13_ = true
			v14_ = -1
		end
		if v13_ then
			local v15_ = self.visibilityAlpha + v14_ * scaledDt / self.fadeDuration
			self.visibilityAlpha = math.clamp(v15_, 0, 1)
			self.isDirty = true
		end
		if self.isDirty then
			local v16_ = self.currentFog
			local v17_ = MathUtil.lerp(1, v16_.groundFogCoverageEdge0, self.visibilityAlpha)
			local v18_ = MathUtil.lerp(1, v16_.groundFogCoverageEdge1, self.visibilityAlpha)
			setGroundFogGlobalCoverage(v17_, v18_)
			setGroundFogHeight(v16_.groundFogExtraHeight)
			setGroundFogGroundLevelDensity(v16_.groundFogGroundLevelDensity)
			setGroundFogMinimumValleyDepth(v16_.groundFogMinValleyDepth)
			setHeightFogGroundLevelDensity(v16_.heightFogGroundLevelDensity)
			setHeightFogMaxHeight(v16_.heightFogMaxHeight)
			self.isDirty = false
		end
	end
end

-- Local values: currentFog, environment, weather, weatherType, dayTime
function FogUpdater:getIsFogPossible()
	local v20_ = self.currentFog
	local v21_ = g_currentMission.environment
	if v21_ == nil then
		return false
	end
	local v22_ = v21_.weather:getCurrentWeatherType()
	if v20_.groundFogWeatherTypes[v22_] == nil then
		return false
	end
	local v23_ = v21_.dayTime / 1000 / 60
	return not MathUtil.getIsOutOfBounds(v23_, v20_.groundFogStartDayTimeMinutes, v20_.groundFogEndDayTimeMinutes)
end

function FogUpdater:saveToXMLFile(xmlFile, key)
	self.targetFog:saveToXMLFile(xmlFile, key .. ".target")
	self.lastFog:saveToXMLFile(xmlFile, key .. ".last")
	xmlFile:setFloat(key .. "#alpha", self.alpha)
	xmlFile:setFloat(key .. "#visibilityAlpha", self.visibilityAlpha)
	xmlFile:setFloat(key .. "#duration", self.duration)
end

function FogUpdater:loadFromXMLFile(xmlFile, key)
	self.alpha = xmlFile:getFloat(key .. "#alpha") or self.alpha
	self.visibilityAlpha = xmlFile:getFloat(key .. "#visibilityAlpha") or self.visibilityAlpha
	self.duration = xmlFile:getFloat(key .. "#duration") or self.duration
	self.targetFog:loadFromXMLFile(xmlFile, key .. ".target")
	self.lastFog:loadFromXMLFile(xmlFile, key .. ".last")
	if self.alpha == 1 then
		self.currentFog = self.targetFog:clone()
	else
		self.currentFog = self.lastFog:clone()
	end
	self.currentFog.groundFogWeatherTypes = table.clone(self.targetFog.groundFogWeatherTypes)
	self.isDirty = true
end

function FogUpdater:setTargetFog(fog, duration)
	self.alpha = 0
	self.duration = math.max(1, duration)
	self.lastFog = self.targetFog
	if fog == nil then
		fog = self.lastFog:clone()
		fog:disableGroundFog()
	end
	self.targetFog = fog
	self.currentFog.groundFogWeatherTypes = table.clone(fog.groundFogWeatherTypes)
end

-- Local values: currentFog
function FogUpdater:addDebugValues(data)
	local v35_ = self.currentFog
	table.insert(data, {
		["name"] = "FOG - Ground",
		["value"] = ""
	})
	local v36_ = {
		["name"] = "Coverage Edge0",
		["value"] = string.format("%.2f", v35_.groundFogCoverageEdge0)
	}
	table.insert(data, v36_)
	local v37_ = {
		["name"] = "Coverage Edge1",
		["value"] = string.format("%.2f", v35_.groundFogCoverageEdge1)
	}
	table.insert(data, v37_)
	local v38_ = {
		["name"] = "Height",
		["value"] = string.format("%.2f", v35_.groundFogExtraHeight)
	}
	table.insert(data, v38_)
	local v39_ = {
		["name"] = "GroundLevelDensity",
		["value"] = string.format("%.2f", v35_.groundFogGroundLevelDensity)
	}
	table.insert(data, v39_)
	local v40_ = {
		["name"] = "MinimumValleyDepth",
		["value"] = string.format("%.2f", v35_.groundFogMinValleyDepth)
	}
	table.insert(data, v40_)
	table.insert(data, {
		["name"] = "",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "FOG - Height",
		["value"] = ""
	})
	local v41_ = {
		["name"] = "GroundLevelDensity",
		["value"] = string.format("%.2f", v35_.heightFogGroundLevelDensity)
	}
	table.insert(data, v41_)
	local v42_ = {
		["name"] = "MaxHeight",
		["value"] = string.format("%.2f", v35_.heightFogMaxHeight)
	}
	table.insert(data, v42_)
end

-- Local values: isEnabled, stateText, currentFog
function FogUpdater:consoleCommandWeatherSetFog(enabled, coverageEdge0, coverageEdge1, groundFogLevelDensity, groundFogExtraHeight, groundFogMinVallyDepth, heightFogMaxHeight, heightFogLevelDensity)
	local v52_ = string.lower(enabled or "true") == "true"
	self.isDebugEnabled = v52_
	local v53_ = tonumber(coverageEdge0) or 0.15
	local v54_ = tonumber(coverageEdge1) or 1
	if v54_ < v53_ then
		local v55_ = v54_
		v54_ = v53_
		v53_ = v55_
	end
	local v56_ = tonumber(groundFogLevelDensity) or 0.25
	local v57_ = tonumber(groundFogExtraHeight) or 20
	local v58_ = tonumber(groundFogMinVallyDepth) or 1.5
	local v59_ = tonumber(heightFogMaxHeight) or 550
	local v60_ = tonumber(heightFogLevelDensity) or 0.6
	local v61_
	if v52_ then
		v61_ = "Updated Values"
	else
		local v62_ = self.currentFog
		v53_ = v62_.groundFogCoverageEdge0
		v54_ = v62_.groundFogCoverageEdge1
		v56_ = v62_.groundFogGroundLevelDensity
		v57_ = v62_.groundFogExtraHeight
		v58_ = v62_.groundFogMinValleyDepth
		v59_ = v62_.heightFogMaxHeight
		v60_ = v62_.heightFogGroundLevelDensity
		v61_ = "Reset Values"
	end
	setGroundFogGlobalCoverage(v53_, v54_)
	setGroundFogGroundLevelDensity(v56_)
	setGroundFogHeight(v57_)
	setGroundFogMinimumValleyDepth(v58_)
	setHeightFogMaxHeight(v59_)
	setHeightFogGroundLevelDensity(v60_)
	return string.format("Fog - %s - GroundFog: Coverage %.3f %.3f | Density %.3f | ExtraHeight %.3f | MinVallyDepth %.3f - HeightFog: MaxHeight %.3f | Density %.3f", v61_, v53_, v54_, v56_, v57_, v58_, v59_, v60_)
end
