ManureSensor = {}
ManureSensor.SPEC_NAME = g_currentModName .. ".manureSensor"
ManureSensor.SPEC_TABLE_NAME = "spec_" .. g_currentModName .. ".manureSensor"
ManureSensor.MAX_NITROGEN_OFFSET_PCT = 0.4
ManureSensor.CHANGE_TIME = 120000

function ManureSensor.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Sprayer, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(PrecisionFarmingStatistic, specializations)
	end
	return v2_
end
function ManureSensor.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("manureSensor", g_i18n:getText("configuration_manureSensor"), "manureSensor", VehicleConfigurationItem)
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("ManureSensor")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.manureSensor.manureSensorConfigurations.manureSensorConfiguration(?).linkNode#node", "Sensor Link Node")
	v3_:register(XMLValueType.STRING, "vehicle.manureSensor.manureSensorConfigurations.manureSensorConfiguration(?).linkNode#type", "Sensor Type (DEFAULT, LARGE, SMALL or STANDALONE)")
	v3_:setXMLSpecializationType()
end

function ManureSensor.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "linkManureSensor", ManureSensor.linkManureSensor)
	SpecializationUtil.registerFunction(vehicleType, "getManureSensorNitrogenOffset", ManureSensor.getManureSensorNitrogenOffset)
end

function ManureSensor.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCurrentNitrogenLevelOffset", ManureSensor.getCurrentNitrogenLevelOffset)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCurrentNitrogenUsageLevelOffset", ManureSensor.getCurrentNitrogenUsageLevelOffset)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsUsingExactNitrogenAmount", ManureSensor.getIsUsingExactNitrogenAmount)
end

function ManureSensor.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ManureSensor)
end

-- Local values: spec, fillUnits, i, configIndex, configKey, linkNode, typeName, linkData, linkData
function ManureSensor:onLoad(savegame)
	local v8_ = self[ManureSensor.SPEC_TABLE_NAME]
	v8_.currentCurveOffset = math.random()
	v8_.sensorRequired = false
	for v9_ = 1, #self:getFillUnits() do
		v8_.sensorRequired = v8_.sensorRequired or (self:getFillUnitAllowsFillType(v9_, FillType.LIQUIDMANURE) or self:getFillUnitAllowsFillType(v9_, FillType.DIGESTATE))
	end
	v8_.sensorAvailable = false
	local v10_ = self.configurations.manureSensor
	if v10_ ~= nil then
		local v11_ = string.format("vehicle.manureSensor.manureSensorConfigurations.manureSensorConfiguration(%d)", v10_ - 1)
		local v12_ = self.xmlFile:getValue(v11_ .. ".linkNode#node", nil, self.components, self.i3dMappings)
		if v12_ ~= nil then
			local v13_ = {
				["linkNodes"] = {}
			}
			local v14_ = {
				["linkNode"] = v12_,
				["typeName"] = self.xmlFile:getValue(v11_ .. ".linkNode#type", "DEFAULT")
			}
			v13_.linkNodes[1] = v14_
			self:linkManureSensor(v13_)
		end
		if v10_ > 1 and g_precisionFarming ~= nil then
			local v15_ = g_precisionFarming:getManureSensorLinkageData(self.configFileName)
			if v15_ ~= nil then
				self:linkManureSensor(v15_)
			end
		end
	end
end

-- Local values: i, linkNodeData, linkNode, sensorData
function ManureSensor:linkManureSensor(linkData)
	for v18_ = 1, #linkData.linkNodes do
		local v19_ = linkData.linkNodes[v18_]
		local v20_ = v19_.linkNode
		if v20_ == nil and (v19_.nodeName ~= nil and self.i3dMappings[v19_.nodeName] ~= nil) then
			v20_ = self.i3dMappings[v19_.nodeName].nodeId
		end
		if v20_ ~= nil then
			local v21_ = g_precisionFarming:getClonedManureSensorNode(v19_.typeName)
			if v21_ ~= nil then
				link(v20_, v21_.node)
				if v19_.translation ~= nil then
					setTranslation(v21_.node, v19_.translation[1], v19_.translation[2], v19_.translation[3])
				end
				if v19_.rotation ~= nil then
					setRotation(v21_.node, v19_.rotation[1], v19_.rotation[2], v19_.rotation[3])
				end
				if v19_.scale ~= nil then
					setScale(v21_.node, v19_.scale[1], v19_.scale[2], v19_.scale[3])
				end
			end
		end
	end
	self[ManureSensor.SPEC_TABLE_NAME].sensorAvailable = true
end

-- Local values: spec, curve, offset, stepOffset, direction
function ManureSensor:getManureSensorNitrogenOffset(lastChangeLevels)
	local v24_ = self[ManureSensor.SPEC_TABLE_NAME]
	local v25_ = g_time % ManureSensor.CHANGE_TIME / ManureSensor.CHANGE_TIME + v24_.currentCurveOffset
	local v26_ = v25_ * 3.141592653589793 * 2
	local v27_ = math.sin(v26_) * 0.75
	local v28_ = v25_ * 3.141592653589793 * 10
	local v29_ = v27_ + math.sin(v28_) * 0.15
	local v30_ = v25_ * 3.141592653589793 * 20
	local v31_ = (v29_ + math.sin(v30_) * 0.15) * (lastChangeLevels * ManureSensor.MAX_NITROGEN_OFFSET_PCT)
	local v32_ = math.sign(v31_)
	return MathUtil.round((math.abs(v31_))) * v32_
end

-- Local values: spec
function ManureSensor:getCurrentNitrogenLevelOffset(superFunc, lastChangeLevels)
	local v36_ = self[ManureSensor.SPEC_TABLE_NAME]
	if v36_.sensorRequired then
		return v36_.sensorAvailable and 0 or self:getManureSensorNitrogenOffset(lastChangeLevels)
	else
		return superFunc(self)
	end
end

-- Local values: spec
function ManureSensor:getCurrentNitrogenUsageLevelOffset(superFunc, lastChangeLevels)
	local v40_ = self[ManureSensor.SPEC_TABLE_NAME]
	if v40_.sensorRequired then
		return not v40_.sensorAvailable and 0 or self:getManureSensorNitrogenOffset(lastChangeLevels)
	else
		return superFunc(self)
	end
end

-- Local values: spec
function ManureSensor:getIsUsingExactNitrogenAmount(superFunc)
	local v43_ = self[ManureSensor.SPEC_TABLE_NAME]
	if v43_.sensorRequired then
		return v43_.sensorAvailable
	else
		return superFunc(self)
	end
end
