WoodContainer = {}
source("dataS/scripts/vehicles/specializations/events/WoodContainerWrongLengthEvent.lua")

function WoodContainer.prerequisitesPresent(specializations)
	return true
end
function WoodContainer.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("woodContainer", g_i18n:getText("shop_configuration"), "woodContainer", VehicleConfigurationItem)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("WoodContainer")
	WoodContainer.registerXMLPaths(v1_, "vehicle.woodContainer")
	WoodContainer.registerXMLPaths(v1_, "vehicle.woodContainer.woodContainerConfigurations.woodContainerConfiguration(?)")
	v1_:register(XMLValueType.INT, "vehicle.woodContainer.sounds#numLogs", "Number of logs filled in the container", 1)
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.woodContainer.sounds", "load")
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).woodContainer#woodQualityVolume", "Volume including the quality factors")
	v2_:register(XMLValueType.FLOAT, "vehicles.vehicle(?).woodContainer#woodQualityTotalVolume", "Volume excluding the quality factors")
end

function WoodContainer.registerXMLPaths(schema, baseKey)
	schema:register(XMLValueType.FLOAT, baseKey .. "#foldMinLimit", "Min. fold anim time to fill the container", 0)
	schema:register(XMLValueType.FLOAT, baseKey .. "#foldMaxLimit", "Max. fold anim time to fill the container", 1)
	schema:register(XMLValueType.INT, baseKey .. "#fillUnitIndex", "Index of fill unit", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. "#targetLength", "Optimal length of trees (has the highest value)", 12)
	schema:register(XMLValueType.NODE_INDEX, baseKey .. "#triggerNode", "Tree trigger node")
	schema:register(XMLValueType.STRING, baseKey .. ".pushAnimation#name", "Animation that is played as soon as something is loaded into the container")
	schema:register(XMLValueType.FLOAT, baseKey .. ".pushAnimation#speedScale", "Animation speed", 1)
end

function WoodContainer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getPalletUnloadTriggerExtraSellPrice", WoodContainer.getPalletUnloadTriggerExtraSellPrice)
	SpecializationUtil.registerFunction(vehicleType, "getIsWoodContainerFillingAllowed", WoodContainer.getIsWoodContainerFillingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "onWoodContainerTriggerCallback", WoodContainer.onWoodContainerTriggerCallback)
end

function WoodContainer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getInfoBoxTitle", WoodContainer.getInfoBoxTitle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", WoodContainer.addFillUnitFillLevel)
end

function WoodContainer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WoodContainer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", WoodContainer)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", WoodContainer)
end

-- Local values: spec, configurationId, configKey
function WoodContainer:onLoad(savegame)
	local v10_ = self.spec_woodContainer
	local v11_ = Utils.getNoNil(self.configurations.woodContainer, 1)
	local v12_ = string.format("vehicle.woodContainer.woodContainerConfigurations.woodContainerConfiguration(%d)", v11_ - 1)
	local v13_ = not self.xmlFile:hasProperty(v12_) and "vehicle.woodContainer" or v12_
	v10_.foldMinLimit = self.xmlFile:getValue(v13_ .. "#foldMinLimit", 0)
	v10_.foldMaxLimit = self.xmlFile:getValue(v13_ .. "#foldMaxLimit", 1)
	v10_.fillUnitIndex = self.xmlFile:getValue(v13_ .. "#fillUnitIndex", 1)
	v10_.targetLength = self.xmlFile:getValue(v13_ .. "#targetLength", 12)
	v10_.triggerNode = self.xmlFile:getValue(v13_ .. "#triggerNode", nil, self.components, self.i3dMappings)
	if self.isServer and v10_.triggerNode ~= nil then
		addTrigger(v10_.triggerNode, "onWoodContainerTriggerCallback", self)
	end
	v10_.woodQualityVolume = 0
	v10_.woodQualityTotalVolume = 0
	v10_.pushAnimation = {}
	v10_.pushAnimation.name = self.xmlFile:getValue(v13_ .. ".pushAnimation#name")
	v10_.pushAnimation.speedScale = self.xmlFile:getValue(v13_ .. ".pushAnimation#speedScale", 1)
	v10_.samples = {}
	if self.isClient then
		v10_.soundNumLogs = self.xmlFile:getValue("vehicle.woodContainer.sounds#numLogs", 1)
		v10_.soundLastNumLogs = 0
		v10_.samples.load = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.woodContainer.sounds", "load", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v10_.texts = {}
	v10_.texts.warningTransportTreesCannotBeLoaded = g_i18n:getText("warning_transportTreesCannotBeLoaded")
	v10_.texts.warningWoodContainerWrongLength = g_i18n:getText("warning_woodContainerWrongLength")
	if savegame ~= nil then
		v10_.woodQualityVolume = savegame.xmlFile:getValue(savegame.key .. ".woodContainer#woodQualityVolume", v10_.woodQualityVolume)
		v10_.woodQualityTotalVolume = savegame.xmlFile:getValue(savegame.key .. ".woodContainer#woodQualityTotalVolume", v10_.woodQualityTotalVolume)
	end
end

-- Local values: spec
function WoodContainer:onDelete()
	local v15_ = self.spec_woodContainer
	if v15_.triggerNode ~= nil then
		removeTrigger(v15_.triggerNode)
	end
	if v15_.samples ~= nil then
		g_soundManager:deleteSamples(v15_.samples)
	end
end

-- Local values: spec
function WoodContainer:saveToXMLFile(xmlFile, key, usedModNames)
	local v19_ = self.spec_woodContainer
	xmlFile:setValue(key .. "#woodQualityVolume", v19_.woodQualityVolume)
	xmlFile:setValue(key .. "#woodQualityTotalVolume", v19_.woodQualityTotalVolume)
end

-- Local values: spec, fillLevel, numLogs, fillLevel, animTime
function WoodContainer:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	local v23_ = self.spec_woodContainer
	if fillUnitIndex == v23_.fillUnitIndex then
		if self.isClient and fillLevelDelta > 0 then
			local v24_ = self:getFillUnitFillLevelPercentage(fillUnitIndex) * (v23_.soundNumLogs - 1)
			local v25_ = math.ceil(v24_)
			if v25_ ~= v23_.soundLastNumLogs then
				if not g_soundManager:getIsSamplePlaying(v23_.samples.load) then
					g_soundManager:playSample(v23_.samples.load)
				end
				v23_.soundLastNumLogs = v25_
			end
		end
		if v23_.pushAnimation.name ~= nil then
			local v26_ = self:getFillUnitFillLevelPercentage(fillUnitIndex)
			local v27_ = self:getAnimationTime(v23_.pushAnimation.name)
			if v26_ > 0 and v27_ == 0 then
				self:playAnimation(v23_.pushAnimation.name, v23_.pushAnimation.speedScale, self:getAnimationTime(v23_.pushAnimation.name), true)
				return
			end
			if v26_ == 0 and v27_ ~= 0 then
				self:playAnimation(v23_.pushAnimation.name, -v23_.pushAnimation.speedScale, self:getAnimationTime(v23_.pushAnimation.name), true)
			end
		end
	end
end

function WoodContainer:getPalletUnloadTriggerExtraSellPrice()
	return self:getPrice()
end

-- Local values: spec, foldAnimTime
function WoodContainer:getIsWoodContainerFillingAllowed()
	if self.spec_foldable ~= nil then
		local v30_ = self.spec_woodContainer
		local v31_ = self:getFoldAnimTime()
		if v31_ < v30_.foldMinLimit or v30_.foldMaxLimit < v31_ then
			return false
		end
	end
	return true
end

function WoodContainer:getInfoBoxTitle(superFunc)
	return g_i18n:getText("storeItem_shippingContainer", self.customEnvironment)
end

-- Local values: delta, spec
function WoodContainer:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	local v41_ = superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	if fillLevelDelta < 0 then
		local v42_ = self.spec_woodContainer
		if v42_.woodQualityTotalVolume > 0 then
			v41_ = v41_ * v42_.woodQualityVolume / v42_.woodQualityTotalVolume
		end
	end
	return v41_
end

-- Local values: splitType, spec, liter, qualityScale, length
function WoodContainer:onWoodContainerTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self:getIsWoodContainerFillingAllowed() and otherId ~= 0 then
		local v45_ = g_splitShapeManager:getSplitTypeByIndex(getSplitType(otherId))
		if v45_ ~= nil and v45_.pricePerLiter > 0 then
			if string.contains(v45_.name, "TRANSPORT") then
				g_currentMission:showBlinkingWarning(self.spec_woodContainer.texts.warningTransportTreesCannotBeLoaded, 2000)
			else
				local v46_ = self.spec_woodContainer
				local v47_, v48_, v49_ = WoodContainer.getSplitShapeInfo(otherId, v46_.targetLength)
				if v47_ > 0 and (v48_ > 0 and self:getFillUnitFreeCapacity(v46_.fillUnitIndex) > 0) then
					v46_.woodQualityVolume = v46_.woodQualityVolume + v47_ * v48_ * v45_.pricePerLiter
					v46_.woodQualityTotalVolume = v46_.woodQualityTotalVolume + v47_
					self:addFillUnitFillLevel(self:getOwnerFarmId(), v46_.fillUnitIndex, v47_, FillType.WOOD, ToolType.UNDEFINED, nil)
					delete(otherId)
					local v50_ = v46_.targetLength - v49_
					if math.abs(v50_) > 1 then
						g_server:broadcastEvent(WoodContainerWrongLengthEvent.new(self), true, nil, self)
						return
					end
				end
			end
		end
	end
end

-- Local values: volume, splitType, sizeX, sizeY, sizeZ, numConvexes, numAttachments, qualityScale, lengthScale, defoliageScale, maxSize, bvVolume, volumeRatio, volumeQuality, convexityQuality, minQuality, maxQuality, numDifficulties, mission, missionInfo
function WoodContainer.getSplitShapeInfo(objectId, targetLength)
	local v52_ = getVolume(objectId)
	local v53_ = g_splitShapeManager:getSplitTypeByIndex(getSplitType(objectId))
	local v54_, v55_, v56_, v57_, v58_ = getSplitShapeStats(objectId)
	local v59_, v60_, v61_, v62_
	if v54_ == nil or v52_ <= 0 then
		v59_ = 1
		v60_ = 1
		v61_ = 1
		v62_ = 0
	else
		local v63_ = (v54_ * v55_ * v56_ / v52_ - 3) / 7
		local v64_ = math.clamp(v63_, 0, 1)
		local v65_ = 1 - math.sqrt(v64_) * 0.95
		local v66_ = (v57_ - 2) / 4
		local v67_ = 1 - math.clamp(v66_, 0, 1) * 0.95
		v62_ = math.max(v54_, v55_, v56_)
		if v62_ < 11 then
			local v68_ = (v62_ - 1) / 5
			local v69_ = math.max(v68_, 0)
			v61_ = 0.6 + math.min(v69_, 1) * 0.6
		else
			local v70_ = (v62_ - 11) / 8
			local v71_ = math.max(v70_, 0)
			v61_ = 1.2 - math.min(v71_, 1) * 0.6
		end
		local v72_ = math.min(v67_, v65_)
		v59_ = v72_ + (math.max(v67_, v65_) - v72_) * 0.3
		local v73_ = v58_ / 15
		v60_ = 1 - math.min(v73_, 1) * 0.8
	end
	local v74_ = #EconomicDifficulty.getAllOrdered()
	local v75_ = g_currentMission.missionInfo
	local v76_ = MathUtil.lerp(1, v59_, v75_.economicDifficulty / v74_)
	local v77_ = MathUtil.lerp(1, v60_, v75_.economicDifficulty / v74_)
	return v52_ * v53_.volumeToLiter, v76_ * v77_ * v61_, v62_
end
