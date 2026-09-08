WeedSpotSpray = {}
WeedSpotSpray.SPEC_NAME = g_currentModName .. ".weedSpotSpray"
WeedSpotSpray.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".weedSpotSpray"
WeedSpotSpray.NOZZLE_UPDATES_PER_FRAME = 10

function WeedSpotSpray.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Sprayer, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
	end
	return v2_
end
function WeedSpotSpray.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("weedSpotSpray", g_i18n:getText("configuration_weedSpotSpray"), "weedSpotSpray", VehicleConfigurationItem)
end

function WeedSpotSpray.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getIsSpotSprayEnabled", WeedSpotSpray.getIsSpotSprayEnabled)
	SpecializationUtil.registerFunction(vehicleType, "addWeedSpotSpraySensorNodes", WeedSpotSpray.addWeedSpotSpraySensorNodes)
end

function WeedSpotSpray.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSprayerUsage", WeedSpotSpray.getSprayerUsage)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addExtendedSprayerNozzleEffect", WeedSpotSpray.addExtendedSprayerNozzleEffect)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtendedSprayerNozzleEffectState", WeedSpotSpray.updateExtendedSprayerNozzleEffectState)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", WeedSpotSpray.loadWorkAreaFromXML)
end

function WeedSpotSpray.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", WeedSpotSpray)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WeedSpotSpray)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", WeedSpotSpray)
end

-- Local values: spec
function WeedSpotSpray:onPreLoad(savegame)
	self[WeedSpotSpray.SPEC_TABLE_NAME].isEnabled = (self.configurations.weedSpotSpray or 1) > 1
end

-- Local values: spec, weedSystem, replacementData, sourceState, targetState, linkData, _
function WeedSpotSpray:onLoad(savegame)
	local v8_ = self[WeedSpotSpray.SPEC_TABLE_NAME]
	v8_.lastRegularUsage = 0
	v8_.weedDetectionStates = {}
	local v9_ = g_currentMission.weedSystem:getHerbicideReplacements()
	if v9_.weed ~= nil then
		for v10_, v11_ in pairs(v9_.weed.replacements) do
			if v11_ ~= 0 then
				v8_.weedDetectionStates[v10_] = true
			end
		end
	end
	if v8_.isEnabled and g_precisionFarming ~= nil then
		local v12_, _ = g_precisionFarming:getSprayerNodeData(self.configFileName, self.configurations)
		if v12_ ~= nil then
			self:addWeedSpotSpraySensorNodes(v12_)
		end
	end
	local v13_, v14_, v15_ = g_currentMission.weedSystem:getDensityMapData()
	v8_.weedMapId = v13_
	v8_.weedFirstChannel = v14_
	v8_.weedNumChannels = v15_
	local v16_, v17_, v18_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	v8_.groundTypeMapId = v16_
	v8_.groundTypeFirstChannel = v17_
	v8_.groundTypeNumChannels = v18_
	local v19_, v20_, v21_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
	v8_.sprayTypeMapId = v19_
	v8_.sprayTypeFirstChannel = v20_
	v8_.sprayTypeNumChannels = v21_
end

-- Local values: spec, specSprayer, sprayFillType, sprayVehicle, usage
function WeedSpotSpray:onEndWorkAreaProcessing(dt)
	local v23_ = self[WeedSpotSpray.SPEC_TABLE_NAME]
	if self:getLastSpeed() > 0.5 then
		local v24_ = self.spec_sprayer
		if self.isServer and (v24_.workAreaParameters.isActive and v24_.workAreaParameters.sprayFillType == FillType.HERBICIDE) then
			local v25_ = v24_.workAreaParameters.sprayVehicle
			local v26_ = v24_.workAreaParameters.usage
			if v25_ ~= nil or self:getIsAIActive() then
				self:updatePFStatistic("usedHerbicide", v26_)
				self:updatePFStatistic("usedHerbicideRegular", v23_.lastRegularUsage)
			end
		end
	end
end

function WeedSpotSpray:getIsSpotSprayEnabled()
	return self[WeedSpotSpray.SPEC_TABLE_NAME].isEnabled
end

-- Local values: _, sensorNodeData, linkNode, sensorNode, hasBracket
function WeedSpotSpray:addWeedSpotSpraySensorNodes(linkData)
	for _, v30_ in pairs(linkData.sensorNodes) do
		local v31_
		if v30_.nodeName == nil or self.i3dMappings[v30_.nodeName] == nil then
			v31_ = nil
		else
			v31_ = self.i3dMappings[v30_.nodeName].nodeId
		end
		if v31_ ~= nil then
			local v32_, v33_ = g_precisionFarming:getClonedSprayerWeedSensorNode(v30_.id)
			if v32_ ~= nil then
				link(v31_, v32_)
				setTranslation(v32_, v30_.translation[1], v30_.translation[2], v30_.translation[3])
				setRotation(v32_, v30_.rotation[1], v30_.rotation[2], v30_.rotation[3])
				if v33_ and v30_.bracketSize ~= 1 then
					setScale(getChildAt(v32_, 0), 1, v30_.bracketSize, v30_.bracketSize)
				end
			end
		end
	end
end

-- Local values: spec, usage, _, alpha
function WeedSpotSpray:getSprayerUsage(superFunc, fillType, dt)
	local v38_ = self[WeedSpotSpray.SPEC_TABLE_NAME]
	local v39_ = superFunc(self, fillType, dt)
	v38_.lastRegularUsage = v39_
	if self.getNumExtendedSprayerNozzleEffectsActive ~= nil then
		local _, v40_ = self:getNumExtendedSprayerNozzleEffectsActive()
		v39_ = v39_ * v40_
	end
	return v39_
end

function WeedSpotSpray:addExtendedSprayerNozzleEffect(superFunc, effectData, effectNode, linkNode, linkNodeData)
	return superFunc(self, effectData, effectNode, linkNode, linkNodeData) and true or false
end

-- Local values: isActive, amountScale, spec, sprayFillType, x, y, z, densityBits, weedState, x, y, z, densityBitsGround, groundTypeValue, groundType, x, y, z, densityBitsGround, groundTypeValue, groundType, densityBitsSpray, sprayValue, sprayType
function WeedSpotSpray:updateExtendedSprayerNozzleEffectState(superFunc, effectData, dt, isTurnedOn, lastSpeed)
	local v53_, v54_ = superFunc(self, effectData, dt, isTurnedOn, lastSpeed)
	local v55_ = self[WeedSpotSpray.SPEC_TABLE_NAME]
	if v53_ and (v55_.isEnabled and (self.movingDirection < 0 or (lastSpeed or 0) < 0.25)) then
		v53_ = false
	end
	if v53_ then
		local v56_ = self.spec_sprayer.workAreaParameters.sprayFillType
		if v56_ == FillType.HERBICIDE then
			if v55_.isEnabled then
				local v57_, v58_, v59_ = localToWorld(effectData.effectNode, 0, 0, 1)
				local v60_ = getDensityAtWorldPos(v55_.weedMapId, v57_, v58_, v59_)
				local v61_ = v55_.weedFirstChannel
				local v62_ = bit32.rshift(v60_, v61_)
				local v63_ = 2 ^ v55_.weedNumChannels - 1
				local v64_ = bit32.band(v62_, v63_)
				if not v55_.weedDetectionStates[v64_] then
					return false, v54_
				end
			else
				local v65_, v66_, v67_ = localToWorld(effectData.effectNode, 0, 0, 1)
				local v68_ = getDensityAtWorldPos(v55_.groundTypeMapId, v65_, v66_, v67_)
				local v69_ = v55_.groundTypeFirstChannel
				local v70_ = bit32.rshift(v68_, v69_)
				local v71_ = 2 ^ v55_.groundTypeNumChannels - 1
				local v72_ = bit32.band(v70_, v71_)
				if FieldGroundType.getTypeByValue(v72_) == FieldGroundType.NONE then
					return false, v54_
				end
			end
		elseif v56_ == FillType.LIQUIDFERTILIZER then
			local v73_, v74_, v75_ = localToWorld(effectData.effectNode, 0, 0, 1.5)
			local v76_ = getDensityAtWorldPos(v55_.groundTypeMapId, v73_, v74_, v75_)
			local v77_ = v55_.groundTypeFirstChannel
			local v78_ = bit32.rshift(v76_, v77_)
			local v79_ = 2 ^ v55_.groundTypeNumChannels - 1
			local v80_ = bit32.band(v78_, v79_)
			if FieldGroundType.getTypeByValue(v80_) == FieldGroundType.NONE then
				v53_ = false
			end
			if v53_ then
				if v55_.sprayTypeMapId ~= v55_.groundTypeMapId then
					v76_ = getDensityAtWorldPos(v55_.sprayTypeMapId, v73_, v74_, v75_)
				end
				local v81_ = v55_.sprayTypeFirstChannel
				local v82_ = bit32.rshift(v76_, v81_)
				local v83_ = 2 ^ v55_.sprayTypeNumChannels - 1
				local v84_ = bit32.band(v82_, v83_)
				if FieldSprayType.getTypeByValue(v84_) == FieldSprayType.FERTILIZER then
					v53_ = false
				end
			end
		end
	end
	return v53_, v54_
end

function WeedSpotSpray:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	if not superFunc(self, workArea, xmlFile, key) then
		return false
	end
	if self[WeedSpotSpray.SPEC_TABLE_NAME].isEnabled then
		workArea.disableBackwards = true
	end
	return true
end
