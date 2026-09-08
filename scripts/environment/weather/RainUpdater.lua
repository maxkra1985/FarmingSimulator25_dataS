-- Local values: RainUpdater_mt
RainUpdater = {}
local RainUpdater_mt = Class(RainUpdater)

-- Upvalues: RainUpdater_mt
-- Local values: self
function RainUpdater.new(customMt)
	-- upvalues: (copy) RainUpdater_mt
	local v3_ = customMt or RainUpdater_mt
	local v4_ = setmetatable({}, v3_)
	v4_.presets = {}
	v4_.types = {}
	v4_.windDirX = 1
	v4_.windDirZ = 0
	v4_.alpha = 0
	v4_.duration = 1
	v4_.isDirty = true
	v4_.isVisible = true
	v4_.rainfallScale = 0
	v4_.snowfallScale = 0
	v4_.hailfallScale = 0
	return v4_
end

-- Local values: numTypes, _, rainTypeKey, id, filename, idUpper, spawnBoxWidth, spawnBoxDepth, spawnBoxHeight, behindCameraBuffer, cameraVelocityMultiplier, settings, rainType
function RainUpdater:load(xmlFile, key, baseDirectory)
	local v9_ = 0
	for _, v10_ in xmlFile:iterator(key .. ".types.type") do
		local v11_ = xmlFile:getString(v10_ .. "#id")
		local v12_ = xmlFile:getString(v10_ .. "#filename")
		if v11_ == nil then
			Logging.xmlWarning(xmlFile, "Missing id for rain type in \'%s\'", key)
		elseif v12_ == nil then
			Logging.xmlWarning(xmlFile, "Missing filename for rain type in \'%s\'", key)
		else
			local v13_ = string.upper(v11_)
			if self.types[v13_] == nil then
				local v14_ = Utils.getFilename(v12_, baseDirectory)
				local v15_ = xmlFile:getFloat(v10_ .. ".settings#spawnBoxWidth", 30)
				local v16_ = xmlFile:getFloat(v10_ .. ".settings#spawnBoxDepth", 50)
				local v17_ = xmlFile:getFloat(v10_ .. ".settings#spawnBoxHeight", 30)
				local v18_ = xmlFile:getFloat(v10_ .. ".settings#behindCameraBuffer", 0.1)
				local v19_ = xmlFile:getFloat(v10_ .. ".settings#cameraVelocityMultiplier", 1)
				local v20_ = RainSettings.new()
				v20_.dropsMultiplier = 0
				local v21_ = {
					["typeId"] = v13_,
					["rootNode"] = nil,
					["node"] = nil,
					["loadRequestId"] = nil,
					["values"] = v20_,
					["spawnBoxWidth"] = v15_,
					["spawnBoxDepth"] = v16_,
					["spawnBoxHeight"] = v17_,
					["behindCameraBuffer"] = v18_,
					["cameraVelocityMultiplier"] = v19_
				}
				self.types[v13_] = v21_
				v21_.loadRequestId = g_i3DManager:loadI3DFileAsync(v14_, false, false, self.onRainI3DLoaded, self, v21_)
				v9_ = v9_ + 1
			else
				Logging.xmlWarning(xmlFile, "RainType \'%s\' already defined in \'%s\'", v11_, key)
			end
		end
	end
	local v22_
	if v9_ > 0 then
		v22_ = self:loadPresets(xmlFile, key)
	else
		v22_ = false
	end
	return v22_
end

-- Local values: rainRootNode, rainShape, rainNode
function RainUpdater:onRainI3DLoaded(i3dNode, failedReason, rainType)
	rainType.loadRequestId = nil
	if i3dNode == nil or i3dNode == 0 then
		Logging.warning("Failed to load rain i3d file!\'")
	else
		local v25_ = getChildAt(i3dNode, 0)
		local v26_ = getGeometry(v25_)
		link(getRootNode(), i3dNode)
		setCullOverride(i3dNode, true)
		setVisibility(i3dNode, false)
		rainType.rootNode = i3dNode
		rainType.node = v26_
		setRainSpawnBoxParameters(v26_, rainType.spawnBoxWidth, rainType.spawnBoxDepth, rainType.spawnBoxHeight)
		setRainBehindCameraBufferForMirrors(v26_, rainType.behindCameraBuffer)
		setRainCameraVelocityMultiplier(v26_, rainType.cameraVelocityMultiplier)
	end
end

function RainUpdater:delete()
	self:reset()
end

-- Local values: _, rainType
function RainUpdater:reset()
	for _, v29_ in pairs(self.types) do
		if v29_.loadRequestId ~= nil then
			g_i3DManager:cancelStreamI3DFile(v29_.loadRequestId)
			v29_.loadRequestId = nil
		end
		if v29_.rootNode ~= nil then
			delete(v29_.rootNode)
		end
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

-- Local values: alpha
function RainUpdater:update(scaledDt)
	if self.alpha ~= 1 or self.isDirty then
		local v32_ = self.alpha + scaledDt / self.duration
		self:setAlpha((math.min(v32_, 1)))
		self.isDirty = false
	end
	setSharedShaderParameter(Shader.PARAM_SHARED_RAIN_SCALE, self.rainfallScale)
end

-- Local values: _, rainType, values, rainNode, rainRootNode
function RainUpdater:setVisible(isVisible)
	self.isVisible = isVisible
	for _, v35_ in pairs(self.types) do
		local v36_ = v35_.values
		local v37_ = v35_.node
		local v38_ = v35_.rootNode
		if v37_ ~= nil then
			local v39_ = setVisibility
			local v40_ = self.isVisible
			if v40_ then
				v40_ = v36_.dropsMultiplier > 0
			end
			v39_(v38_, v40_)
		end
	end
end

-- Local values: lastRain, targetRain, rainType, values, rainType, values, rainType, values, rainfallScale, snowfallScale, hailfallScale, _, rainType, values, rainNode, rainRootNode, isLastRain, isTargetRain
function RainUpdater:setAlpha(alpha)
	self.alpha = alpha
	local v43_ = self.lastRain
	local v44_ = self.targetRain
	if v43_ == nil or (v44_ == nil or v43_.typeId ~= v44_.typeId) then
		if v43_ ~= nil then
			local v45_ = self.types[v43_.typeId].values
			v45_.dropsMultiplier = MathUtil.lerp(v43_.dropsMultiplier, 0, alpha)
			v45_.rainfallScale = MathUtil.lerp(v43_.rainfallScale, 0, alpha)
			v45_.snowfallScale = MathUtil.lerp(v43_.snowfallScale, 0, alpha)
			v45_.hailfallScale = MathUtil.lerp(v43_.hailfallScale, 0, alpha)
		end
		if v44_ ~= nil then
			local v46_ = self.types[v44_.typeId].values
			v46_.dropsMultiplier = MathUtil.lerp(0, v44_.dropsMultiplier, alpha)
			v46_.rainfallScale = MathUtil.lerp(0, v44_.rainfallScale, alpha)
			v46_.snowfallScale = MathUtil.lerp(0, v44_.snowfallScale, alpha)
			v46_.hailfallScale = MathUtil.lerp(0, v44_.hailfallScale, alpha)
		end
	else
		local v47_ = self.types[v43_.typeId].values
		v47_.dropsMultiplier = MathUtil.lerp(v43_.dropsMultiplier, v44_.dropsMultiplier, alpha)
		v47_.maxDropsMultiplier = MathUtil.lerp(v43_.maxDropsMultiplier, v44_.maxDropsMultiplier, alpha)
		v47_.turbulence = MathUtil.lerp(v43_.turbulence, v44_.turbulence, alpha)
		v47_.turbulenceTimeScale = MathUtil.lerp(v43_.turbulenceTimeScale, v44_.turbulenceTimeScale, alpha)
		v47_.turbulencePulseDuration = MathUtil.lerp(v43_.turbulencePulseDuration, v44_.turbulencePulseDuration, alpha)
		v47_.spawnVelocityX = MathUtil.lerp(v43_.spawnVelocityX, v44_.spawnVelocityX, alpha)
		v47_.spawnVelocityY = MathUtil.lerp(v43_.spawnVelocityY, v44_.spawnVelocityY, alpha)
		v47_.spawnVelocityZ = MathUtil.lerp(v43_.spawnVelocityZ, v44_.spawnVelocityZ, alpha)
		v47_.mostConcentratedDistance = MathUtil.lerp(v43_.mostConcentratedDistance, v44_.mostConcentratedDistance, alpha)
		v47_.distributionPower = MathUtil.lerp(v43_.distributionPower, v44_.distributionPower, alpha)
		v47_.turbulenceFrequency = MathUtil.lerp(v43_.turbulenceFrequency, v44_.turbulenceFrequency, alpha)
		v47_.rainfallScale = MathUtil.lerp(v43_.rainfallScale, v44_.rainfallScale, alpha)
		v47_.snowfallScale = MathUtil.lerp(v43_.snowfallScale, v44_.snowfallScale, alpha)
		v47_.hailfallScale = MathUtil.lerp(v43_.hailfallScale, v44_.hailfallScale, alpha)
		v47_.bounceRandomFactor = MathUtil.lerp(v43_.bounceRandomFactor, v44_.bounceRandomFactor, alpha)
		v47_.bounceRestitution = MathUtil.lerp(v43_.bounceRestitution, v44_.bounceRestitution, alpha)
		if alpha >= 1 then
			v47_.maxBounces = v44_.maxBounces
		end
	end
	local v48_ = 0
	local v49_ = 0
	local v50_ = 0
	for _, v51_ in pairs(self.types) do
		local v52_ = v51_.values
		local v53_ = v51_.node
		local v54_ = v51_.rootNode
		local v55_
		if self.lastRain == nil then
			v55_ = false
		else
			v55_ = self.lastRain.typeId == v51_.typeId
		end
		local v56_
		if self.targetRain == nil then
			v56_ = false
		else
			v56_ = self.targetRain.typeId == v51_.typeId
		end
		if v55_ or v56_ then
			local v57_ = v52_.rainfallScale
			v49_ = math.max(v57_, v49_)
			local v58_ = v52_.snowfallScale
			v50_ = math.max(v58_, v50_)
			local v59_ = v52_.hailfallScale
			v48_ = math.max(v59_, v48_)
		end
		if v53_ ~= nil then
			setRainWindForce(v53_, 0, 0)
			setRainActiveDropsMultiplier(v53_, v52_.dropsMultiplier * v52_.maxDropsMultiplier)
			setRainTurbulenceParameters(v53_, v52_.turbulence, v52_.turbulenceTimeScale, v52_.turbulencePulseDuration, v52_.turbulenceFrequency)
			setRainMostConcentratedDistance(v53_, v52_.mostConcentratedDistance)
			setRainDistributionPower(v53_, 1)
			local v60_ = setRainMaxBounces
			local v61_ = v52_.maxBounces
			v60_(v53_, (math.floor(v61_)))
			setRainBounceRandomFactor(v53_, v52_.bounceRandomFactor)
			setRainBounceRestitution(v53_, v52_.bounceRestitution)
			local v62_ = setVisibility
			local v63_ = self.isVisible
			if v63_ then
				v63_ = v52_.dropsMultiplier > 0
			end
			v62_(v54_, v63_)
			self:setCombinedSpawnVelocity(self.windDirX, self.windDirZ, v53_, v52_)
		end
	end
	self.rainfallScale = v49_
	self.snowfallScale = v50_
	self.hailfallScale = v48_
end

-- Local values: _, rainType, isLastRain, isTargetRain, isVisible
function RainUpdater:setTargetRain(targetRain, duration)
	self.alpha = 0
	self.duration = math.max(1, duration)
	self.lastRain = self.targetRain
	self.targetRain = targetRain
	for _, v67_ in pairs(self.types) do
		local v68_
		if self.lastRain == nil then
			v68_ = false
		else
			v68_ = self.lastRain.typeId == v67_.typeId
		end
		local v69_
		if targetRain == nil then
			v69_ = false
		else
			v69_ = targetRain.typeId == v67_.typeId
		end
		local v70_ = v68_ or v69_
		if v69_ then
			if self.lastRain == nil or not v68_ then
				v67_.values:copyAttributes(targetRain)
			end
		elseif v68_ and targetRain == nil then
			v67_.values:copyAttributes(self.lastRain)
		end
		if not v70_ then
			v67_.values.dropsMultiplier = 0
		end
	end
end

-- Local values: rainType
function RainUpdater:setValues(rainTypeId, rainSettings)
	self.types[rainTypeId].values:copyAttributes(rainSettings)
end

-- Local values: ySpeed, xSpeed, zSpeed, presetLength, averagedLength, newXSpeed, newYSpeed, newZSpeed
function RainUpdater:setCombinedSpawnVelocity(windDirX, windDirZ, rainNode, rainValues)
	local v78_ = rainValues.spawnVelocityY
	local v79_ = (rainValues.spawnVelocityX + windDirX) / 2
	local v80_ = (rainValues.spawnVelocityZ + windDirZ) / 2
	local v81_ = MathUtil.vector3Length(rainValues.spawnVelocityX, rainValues.spawnVelocityY, rainValues.spawnVelocityZ)
	local v82_ = MathUtil.vector3Length(v79_, v78_, v80_)
	local v83_ = v79_ * v81_ / v82_
	local v84_ = v80_ * v81_ / v82_
	if rainNode ~= nil then
		setRainSpawnVelocity(rainNode, v83_, v78_, v84_)
	end
end

-- Local values: _, rainType, rainNode
function RainUpdater:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
	self.windDirX = windDirX * windVelocity / 4
	self.windDirZ = windDirZ * windVelocity / 4
	for _, v89_ in pairs(self.types) do
		local v90_ = v89_.node
		self:setCombinedSpawnVelocity(self.windDirX, self.windDirZ, v90_, v89_.values)
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

-- Local values: preset
function RainUpdater:createRainSettingsFromPreset(presetId)
	local v96_ = self:getPreset(presetId)
	if v96_ == nil then
		return nil
	else
		return v96_:clone()
	end
end

function RainUpdater:getPresets()
	return self.presets
end

-- Local values: upperPresetId
function RainUpdater:getPreset(presetId)
	local v100_ = string.upper(presetId)
	return self.presets[v100_]
end

-- Local values: numPresets, _, presetKey, id, idUpper, rainTypeId, rainTypeIdUpper, preset
function RainUpdater:loadPresets(xmlFile, key)
	local v104_ = 0
	for _, v105_ in xmlFile:iterator(key .. ".presets.preset") do
		local v106_ = xmlFile:getString(v105_ .. "#id")
		if v106_ == nil then
			Logging.xmlWarning(xmlFile, "Missing rain preset id for \'%s\'", v105_)
			break
		end
		local v107_ = string.upper(v106_)
		if self.presets[v107_] ~= nil then
			Logging.xmlWarning(xmlFile, "Rain preset id \'%s\' already exists for \'%s\'", v106_, v105_)
			break
		end
		local v108_ = xmlFile:getString(v105_ .. "#typeId")
		if v108_ == nil then
			Logging.xmlWarning(xmlFile, "Missing rain preset type for \'%s\'", v105_)
			break
		end
		local v109_ = string.upper(v108_)
		if self.types[v109_] == nil then
			Logging.xmlWarning(xmlFile, "Rain type \'%s\' is not defined for \'%s\'", v108_, v105_)
			break
		end
		local v110_ = RainSettings.new()
		if v110_:load(xmlFile, v105_) then
			v110_.presetId = v107_
			v110_.typeId = v109_
		end
		self.presets[v107_] = v110_
		v104_ = v104_ + 1
	end
	return v104_ > 0
end

-- Local values: _, presetKey, id, preset
function RainUpdater:savePresets(xmlFile, key, presetId)
	for _, v115_ in xmlFile:iterator(key .. ".presets.preset") do
		local v116_ = string.upper(xmlFile:getString(v115_ .. "#id"))
		if presetId == nil or v116_ == presetId then
			local v117_ = self.presets[v116_]
			if v117_ ~= nil then
				v117_:save(xmlFile, v115_)
			end
		end
	end
end

-- Local values: _, typeData
function RainUpdater:addDebugValues(data)
	table.insert(data, {
		["name"] = "Type",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "DropsMultiplier",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "MaxDropsMultiplier",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "turbulence",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "turbulenceTimeScale",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "turbulencePulseDuration",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "turbulenceFrequency",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "spawnVelocityX",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "spawnVelocityY",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "spawnVelocityZ",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "mostConcentratedDistance",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "distributionPower",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "maxBounces",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "bounceRandomFactor",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "bounceRestitution",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "bounceRestitution",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "",
		["value"] = ""
	})
	table.insert(data, {
		["name"] = "",
		["value"] = ""
	})
	local v120_ = {
		["name"] = "RainfallScale",
		["value"] = string.format("%.3f", self.rainfallScale)
	}
	table.insert(data, v120_)
	local v121_ = {
		["name"] = "HailfallScale",
		["value"] = string.format("%.3f", self.hailfallScale)
	}
	table.insert(data, v121_)
	local v122_ = {
		["name"] = "SnowfallScale",
		["value"] = string.format("%.3f", self.snowfallScale)
	}
	table.insert(data, v122_)
	table.insert(data, {
		["name"] = "",
		["value"] = "",
		["columnOffset"] = 0.005
	})
	for _, v123_ in pairs(self.types) do
		local v124_ = {
			["name"] = "",
			["value"] = string.format("%s", v123_.typeId)
		}
		table.insert(data, v124_)
		local v125_ = {
			["name"] = "",
			["value"] = string.format("%.2f", v123_.values.dropsMultiplier)
		}
		table.insert(data, v125_)
		local v126_ = {
			["name"] = "",
			["value"] = string.format("%.3f", v123_.values.maxDropsMultiplier)
		}
		table.insert(data, v126_)
		local v127_ = {
			["name"] = "",
			["value"] = string.format("%.2f", v123_.values.turbulence)
		}
		table.insert(data, v127_)
		local v128_ = {
			["name"] = "",
			["value"] = string.format("%.2f", v123_.values.turbulenceTimeScale)
		}
		table.insert(data, v128_)
		local v129_ = {
			["name"] = "",
			["value"] = string.format("%.2f", v123_.values.turbulencePulseDuration)
		}
		table.insert(data, v129_)
		local v130_ = {
			["name"] = "",
			["value"] = string.format("%.2f", v123_.values.turbulenceFrequency)
		}
		table.insert(data, v130_)
		local v131_ = {
			["name"] = "",
			["value"] = string.format("%.2f", v123_.values.spawnVelocityX)
		}
		table.insert(data, v131_)
		local v132_ = {
			["name"] = "",
			["value"] = string.format("%.2f", v123_.values.spawnVelocityY)
		}
		table.insert(data, v132_)
		local v133_ = {
			["name"] = "",
			["value"] = string.format("%.2f", v123_.values.spawnVelocityZ)
		}
		table.insert(data, v133_)
		local v134_ = {
			["name"] = "",
			["value"] = string.format("%.2f", v123_.values.mostConcentratedDistance)
		}
		table.insert(data, v134_)
		local v135_ = {
			["name"] = "",
			["value"] = string.format("%.2f", v123_.values.distributionPower)
		}
		table.insert(data, v135_)
		local v136_ = {
			["name"] = "",
			["value"] = string.format("%.2f", v123_.values.maxBounces)
		}
		table.insert(data, v136_)
		local v137_ = {
			["name"] = "",
			["value"] = string.format("%.2f", v123_.values.bounceRandomFactor)
		}
		table.insert(data, v137_)
		local v138_ = {
			["name"] = "",
			["value"] = string.format("%.2f", v123_.values.bounceRestitution)
		}
		table.insert(data, v138_)
		table.insert(data, {
			["name"] = "",
			["value"] = "",
			["columnOffset"] = 0.03
		})
	end
end
