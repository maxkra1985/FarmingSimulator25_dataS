-- Local values: CloudUpdater_mt
CloudUpdater = {}
local CloudUpdater_mt = Class(CloudUpdater)

-- Upvalues: CloudUpdater_mt
-- Local values: self
function CloudUpdater.new(customMt)
	-- upvalues: (copy) CloudUpdater_mt
	local v3_ = customMt or CloudUpdater_mt
	local v4_ = setmetatable({}, v3_)
	v4_.presets = {}
	v4_.lastClouds = CloudSettings.new()
	v4_.currentClouds = CloudSettings.new()
	v4_.targetClouds = CloudSettings.new()
	v4_.windDirX = 1
	v4_.windDirZ = 0
	v4_.windVelocity = 1
	v4_.cirrusCloudSpeedFactor = 1
	v4_.speedScale = 1
	v4_.alpha = 1
	v4_.duration = 1
	v4_.isDirty = true
	return v4_
end

function CloudUpdater:load(xmlFile, key, baseDirectory)
	self.presets = {}
	return self:loadPresets(xmlFile, key)
end

function CloudUpdater:delete()
	self.presets = {}
end

-- Local values: alpha
function CloudUpdater:update(scaledDt)
	if self.alpha ~= 1 or self.isDirty then
		local v11_ = self.alpha + scaledDt / self.duration
		self:setAlpha((math.min(v11_, 1)))
		self.isDirty = false
	end
end

-- Local values: lastClouds, targetClouds, combinedNoiseEdge0, combinedNoiseEdge1, noise0Weight, noise0Edge0, noise0Edge1, noise1Weight, noise1Edge0, noise1Edge1, noise2Weight, noise2Edge0, noise2Edge1, erosionWeight, precipitation, baseShapeTiling, erosionTiling, curlNoiseTiling, curlNoiseHeightFractionModifier, curlNoiseModifier, densityScale, cloudGroundAlbedoR, cloudGroundAlbedoG, cloudGroundAlbedoB, weight, cirrusCoverage
function CloudUpdater:setAlpha(alpha)
	self.alpha = alpha
	local v14_ = self.lastClouds
	local v15_ = self.targetClouds
	local v16_ = MathUtil.lerp(v14_.combinedNoiseEdge0, v15_.combinedNoiseEdge0, alpha)
	local v17_ = MathUtil.lerp(v14_.combinedNoiseEdge1, v15_.combinedNoiseEdge1, alpha)
	local v18_ = MathUtil.lerp(v14_.noise0Weight, v15_.noise0Weight, alpha)
	local v19_ = MathUtil.lerp(v14_.noise0Edge0, v15_.noise0Edge0, alpha)
	local v20_ = MathUtil.lerp(v14_.noise0Edge1, v15_.noise0Edge1, alpha)
	local v21_ = MathUtil.lerp(v14_.noise1Weight, v15_.noise1Weight, alpha)
	local v22_ = MathUtil.lerp(v14_.noise1Edge0, v15_.noise1Edge0, alpha)
	local v23_ = MathUtil.lerp(v14_.noise1Edge1, v15_.noise1Edge1, alpha)
	local v24_ = MathUtil.lerp(v14_.noise2Weight, v15_.noise2Weight, alpha)
	local v25_ = MathUtil.lerp(v14_.noise2Edge0, v15_.noise2Edge0, alpha)
	local v26_ = MathUtil.lerp(v14_.noise2Edge1, v15_.noise2Edge1, alpha)
	local v27_ = MathUtil.lerp(v14_.erosionWeight, v15_.erosionWeight, alpha)
	local v28_ = MathUtil.lerp(v14_.precipitation, v15_.precipitation, alpha)
	local v29_ = MathUtil.lerp(v14_.baseShapeTiling, v15_.baseShapeTiling, alpha)
	local v30_ = MathUtil.lerp(v14_.erosionTiling, v15_.erosionTiling, alpha)
	local v31_ = MathUtil.lerp(v14_.curlNoiseTiling, v15_.curlNoiseTiling, alpha)
	local v32_ = MathUtil.lerp(v14_.curlNoiseHeightFractionModifier, v15_.curlNoiseHeightFractionModifier, alpha)
	local v33_ = MathUtil.lerp(v14_.curlNoiseModifier, v15_.curlNoiseModifier, alpha)
	local v34_ = MathUtil.lerp(v14_.densityScale, v15_.densityScale, alpha)
	local v35_ = MathUtil.lerp(v14_.groundAlbedo[1], v15_.groundAlbedo[1], alpha)
	local v36_ = MathUtil.lerp(v14_.groundAlbedo[2], v15_.groundAlbedo[2], alpha)
	local v37_ = MathUtil.lerp(v14_.groundAlbedo[3], v15_.groundAlbedo[3], alpha)
	if v17_ < v16_ then
		local v38_ = v17_
		v17_ = v16_
		v16_ = v38_
	end
	if v20_ >= v19_ then
		local v39_ = v20_
		v20_ = v19_
		v19_ = v39_
	end
	if v23_ >= v22_ then
		local v40_ = v23_
		v23_ = v22_
		v22_ = v40_
	end
	if v26_ >= v25_ then
		local v41_ = v25_
		v25_ = v26_
		v26_ = v41_
	end
	local v42_ = v18_ + v21_ + v24_
	local v43_ = v18_ / v42_
	local v44_ = v21_ / v42_
	local v45_ = v24_ / v42_
	setGlobalCloudCoverage(v16_, v17_, v43_, v20_, v19_, v44_, v23_, v22_, v45_, v26_, v25_)
	setCloudCurlNoiseProperties(v31_, v32_, v33_)
	local v46_ = MathUtil.lerp(v14_.cirrusCoverage, v15_.cirrusCoverage, alpha)
	setCirrusCloudCoverage(v46_)
	setCloudType(v14_.type, v15_.type, alpha, v29_, v30_, v27_)
	setCloudPrecipitation(v28_)
	setCloudGroundAlbedo(v35_, v36_, v37_)
	setCloudDensityScaling(v34_)
	self.currentClouds.type = MathUtil.lerp(v14_.type, v15_.type, alpha)
	self.currentClouds.densityScale = v34_
	self.currentClouds.precipitation = v28_
	self.currentClouds.baseShapeTiling = v29_
	self.currentClouds.erosionTiling = v30_
	self.currentClouds.combinedNoiseEdge0 = v16_
	self.currentClouds.combinedNoiseEdge1 = v17_
	self.currentClouds.noise0Weight = v43_
	self.currentClouds.noise0Edge0 = v20_
	self.currentClouds.noise0Edge1 = v19_
	self.currentClouds.noise1Weight = v44_
	self.currentClouds.noise1Edge0 = v23_
	self.currentClouds.noise1Edge1 = v22_
	self.currentClouds.noise2Weight = v45_
	self.currentClouds.noise2Edge0 = v26_
	self.currentClouds.noise2Edge1 = v25_
	self.currentClouds.erosionWeight = v27_
	self.currentClouds.cirrusCoverage = v46_
	self.currentClouds.groundAlbedo[1] = v35_
	self.currentClouds.groundAlbedo[2] = v36_
	self.currentClouds.groundAlbedo[3] = v37_
	self.currentClouds.envMapCloudProbeIndex = v14_.envMapCloudProbeIndex
	self.currentClouds.curlNoiseTiling = v31_
	self.currentClouds.curlNoiseHeightFractionModifier = v32_
	self.currentClouds.curlNoiseModifier = v33_
end

function CloudUpdater:setTargetClouds(clouds, duration)
	self.alpha = 0
	self.duration = math.max(1, duration)
	self.lastClouds = self.targetClouds
	self.targetClouds = clouds
end

function CloudUpdater:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
	self.windDirX = windDirX
	self.windDirZ = windDirZ
	self.windVelocity = windVelocity
	self.cirrusCloudSpeedFactor = cirrusCloudSpeedFactor
	self:updateCloudWind()
end

-- Local values: windDirX, windDirZ, cirrusCloudSpeedFactor, windVelocity
function CloudUpdater:updateCloudWind()
	local v56_ = self.windDirX
	local v57_ = self.windDirZ
	local v58_ = self.cirrusCloudSpeedFactor
	local v59_ = self.windVelocity * self.speedScale
	if self.slowModeEnabled then
		v59_ = v59_ / 100
	end
	setCloudWind(-v56_, v57_, v59_, -v56_, -v57_, v59_ * v58_)
end

function CloudUpdater:setTimeScale(scale)
	self.speedScale = scale
	self.isDirty = true
	self:updateCloudWind()
end

function CloudUpdater:setSlowModeEnabled(enabled)
	self.slowModeEnabled = enabled
end

function CloudUpdater:getCurrentValues()
	return self.currentClouds
end

-- Local values: cloudEnvMapIndex1, cloudEnvMapIndex2, alpha
function CloudUpdater:getEnvMapInfo()
	return self.lastClouds.envMapCloudProbeIndex, self.targetClouds.envMapCloudProbeIndex, self.alpha
end

-- Local values: preset
function CloudUpdater:createCloudSettingsFromPreset(presetId)
	local v68_ = self:getPreset(presetId)
	if v68_ == nil then
		return nil
	else
		return v68_:clone()
	end
end

function CloudUpdater:getPresets()
	return self.presets
end

-- Local values: upperPresetId
function CloudUpdater:getPreset(presetId)
	local v72_ = string.upper(presetId)
	return self.presets[v72_]
end

-- Local values: numPresets, _, presetKey, id, preset
function CloudUpdater:loadPresets(xmlFile, key)
	local v76_ = 0
	for _, v77_ in xmlFile:iterator(key .. ".presets.preset") do
		local v78_ = xmlFile:getString(v77_ .. "#id")
		if v78_ == nil then
			Logging.xmlWarning(xmlFile, "Missing cloud preset id for \'%s\'", v77_)
			break
		end
		local v79_ = string.upper(v78_)
		if self.presets[v79_] ~= nil then
			Logging.xmlWarning(xmlFile, "Cloud preset id \'%s\' already exists for \'%s\'", v79_, v77_)
			break
		end
		local v80_ = CloudSettings.new()
		if v80_:load(xmlFile, v77_) then
			v80_.id = v79_
		end
		self.presets[v79_] = v80_
		v76_ = v76_ + 1
	end
	return v76_ > 0
end

-- Local values: _, presetKey, id, preset
function CloudUpdater:savePresets(xmlFile, key, presetId)
	for _, v85_ in xmlFile:iterator(key .. ".presets.preset") do
		local v86_ = string.upper(xmlFile:getString(v85_ .. "#id"))
		if presetId == nil or v86_ == presetId then
			local v87_ = self.presets[v86_]
			if v87_ ~= nil then
				v87_:save(xmlFile, v85_)
			end
		end
	end
end

-- Local values: cloudData
function CloudUpdater:addDebugValues(data)
	local v90_ = self.currentClouds
	table.insert(data, {
		["name"] = "CLOUDS",
		["value"] = ""
	})
	local v91_ = {
		["name"] = "Type",
		["value"] = string.format("%.2f", v90_.type)
	}
	table.insert(data, v91_)
	local v92_ = {
		["name"] = "DensityScale",
		["value"] = string.format("%.2f", v90_.densityScale)
	}
	table.insert(data, v92_)
	local v93_ = {
		["name"] = "Precipitation",
		["value"] = string.format("%.3f", v90_.precipitation)
	}
	table.insert(data, v93_)
	local v94_ = {
		["name"] = "BaseShapeTiling",
		["value"] = string.format("%.3f", v90_.baseShapeTiling)
	}
	table.insert(data, v94_)
	local v95_ = {
		["name"] = "ErosionTiling",
		["value"] = string.format("%.3f", v90_.erosionTiling)
	}
	table.insert(data, v95_)
	local v96_ = {
		["name"] = "CombinedNoiseEdge0",
		["value"] = string.format("%.3f", v90_.combinedNoiseEdge0)
	}
	table.insert(data, v96_)
	local v97_ = {
		["name"] = "CombinedNoiseEdge1",
		["value"] = string.format("%.3f", v90_.combinedNoiseEdge1)
	}
	table.insert(data, v97_)
	local v98_ = {
		["name"] = "Noise0Weight",
		["value"] = string.format("%.3f", v90_.noise0Weight)
	}
	table.insert(data, v98_)
	local v99_ = {
		["name"] = "Noise0Edge0",
		["value"] = string.format("%.3f", v90_.noise0Edge0)
	}
	table.insert(data, v99_)
	local v100_ = {
		["name"] = "Noise0Edge1",
		["value"] = string.format("%.3f", v90_.noise0Edge1)
	}
	table.insert(data, v100_)
	local v101_ = {
		["name"] = "Noise1Weight",
		["value"] = string.format("%.3f", v90_.noise1Weight)
	}
	table.insert(data, v101_)
	local v102_ = {
		["name"] = "Noise1Edge0",
		["value"] = string.format("%.3f", v90_.noise1Edge0)
	}
	table.insert(data, v102_)
	local v103_ = {
		["name"] = "Noise1Edge1",
		["value"] = string.format("%.3f", v90_.noise1Edge1)
	}
	table.insert(data, v103_)
	local v104_ = {
		["name"] = "Noise2Weight",
		["value"] = string.format("%.3f", v90_.noise2Weight)
	}
	table.insert(data, v104_)
	local v105_ = {
		["name"] = "Noise2Edge0",
		["value"] = string.format("%.3f", v90_.noise2Edge0)
	}
	table.insert(data, v105_)
	local v106_ = {
		["name"] = "Noise2Edge1",
		["value"] = string.format("%.3f", v90_.noise2Edge1)
	}
	table.insert(data, v106_)
	local v107_ = {
		["name"] = "ErosionWeight",
		["value"] = string.format("%.3f", v90_.erosionWeight)
	}
	table.insert(data, v107_)
	local v108_ = {
		["name"] = "CirrusCoverage",
		["value"] = string.format("%.3f", v90_.cirrusCoverage)
	}
	table.insert(data, v108_)
	local v109_ = {
		["name"] = "EnvMapIndex",
		["value"] = string.format("%d", v90_.envMapCloudProbeIndex)
	}
	table.insert(data, v109_)
	local v110_ = {
		["name"] = "GroundAlbedo",
		["value"] = string.format("%.3f %.3f %.3f", v90_.groundAlbedo[1], v90_.groundAlbedo[2], v90_.groundAlbedo[3])
	}
	table.insert(data, v110_)
end
