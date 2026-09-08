PlaceableSolarPanels = {}

function PlaceableSolarPanels.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PlaceableIncomePerHour, specializations)
end
function PlaceableSolarPanels.initSpecialization()
	g_placeableConfigurationManager:addConfigurationType("solarPanels", g_i18n:getText("configuration_solarPanel"), "solarPanels", PlaceableConfigurationItem)
end

function PlaceableSolarPanels.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getIncomePerHour", PlaceableSolarPanels.getIncomePerHour)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedHourChanged", PlaceableSolarPanels.getNeedHourChanged)
end

function PlaceableSolarPanels.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateHeadRotation", PlaceableSolarPanels.updateHeadRotation)
end

function PlaceableSolarPanels.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableSolarPanels)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableSolarPanels)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableSolarPanels)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableSolarPanels)
	SpecializationUtil.registerEventListener(placeableType, "onHourChanged", PlaceableSolarPanels)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableSolarPanels)
end

function PlaceableSolarPanels.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("SolarPanels")
	local v7_ = basePath .. ".solarPanels.solarPanelsConfigurations.solarPanelsConfiguration(?)"
	schema:register(XMLValueType.NODE_INDEX, v7_ .. "#headNode", "Head Node")
	schema:register(XMLValueType.ANGLE, v7_ .. "#randomHeadOffsetRange", "Range of random offset", 15)
	schema:register(XMLValueType.ANGLE, v7_ .. "#rotationSpeed", "Rotation Speed (deg/sec)", 5)
	schema:register(XMLValueType.BOOL, v7_ .. "#isActive", "If solar panels are available", false)
	schema:register(XMLValueType.FLOAT, v7_ .. "#incomePerHour", "Income per hour")
	schema:setXMLSpecializationType()
end

function PlaceableSolarPanels.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("SolarPanels")
	schema:register(XMLValueType.FLOAT, basePath .. "#headRotationRandom", "Head random rotation")
	schema:setXMLSpecializationType()
end

-- Local values: spec, xmlFile, solarPanelsConfigurationId, configKey, hasSolarPanels, rotVariation
function PlaceableSolarPanels:onLoad(savegame)
	local v11_ = self.spec_solarPanels
	local v12_ = self.xmlFile
	local v13_ = Utils.getNoNil(self.configurations.solarPanels, 1)
	local v14_ = string.format("placeable.solarPanels.solarPanelsConfigurations.solarPanelsConfiguration(%d)", v13_ - 1)
	local v15_ = v12_:getValue(v14_ .. "#isActive", false)
	v11_.headNode = v12_:getValue(v14_ .. "#headNode", nil, self.components, self.i3dMappings)
	if v11_.headNode ~= nil then
		v11_.randomHeadOffsetRange = v12_:getValue(v14_ .. "#randomHeadOffsetRange", 15)
		v11_.rotationSpeed = v12_:getValue(v14_ .. "#rotationSpeed", 5) / 1000
		local v16_ = v11_.randomHeadOffsetRange * 0.5
		v11_.headRotationRandom = math.random(-1, 1) * v16_
		v11_.currentRotation = v11_.headRotationRandom
		v11_.targetRotation = v11_.headRotationRandom
		v15_ = true
	end
	v11_.incomePerHour = v12_:getValue(v14_ .. "#incomePerHour", 0)
	v11_.hasSolarPanels = v15_
	if not v15_ then
		SpecializationUtil.removeEventListener(self, "onFinalizePlacement", PlaceableSolarPanels)
		SpecializationUtil.removeEventListener(self, "onReadStream", Cover)
		SpecializationUtil.removeEventListener(self, "onWriteStream", Cover)
		SpecializationUtil.removeEventListener(self, "onUpdate", Cover)
		SpecializationUtil.removeEventListener(self, "onHourChanged", Cover)
	end
end

function PlaceableSolarPanels:onFinalizePlacement()
	self:updateHeadRotation()
end

-- Local values: spec, headRotationRandom
function PlaceableSolarPanels:loadFromXMLFile(xmlFile, key)
	local v21_ = self.spec_solarPanels
	local v22_ = xmlFile:getValue(key .. "#headRotationRandom")
	if v22_ == nil then
		v21_.headRotationRandom = v22_
	end
end

-- Local values: spec
function PlaceableSolarPanels:saveToXMLFile(xmlFile, key, usedModNames)
	local v26_ = self.spec_solarPanels
	if v26_.headNode ~= nil then
		xmlFile:setValue(key .. "#headRotationRandom", v26_.headRotationRandom)
	end
end

-- Local values: spec
function PlaceableSolarPanels:onReadStream(streamId, connection)
	local v29_ = self.spec_solarPanels
	if v29_.headNode ~= nil then
		v29_.headRotationRandom = NetworkUtil.readCompressedAngle(streamId)
	end
end

-- Local values: spec
function PlaceableSolarPanels:onWriteStream(streamId, connection)
	local v32_ = self.spec_solarPanels
	if v32_.headNode ~= nil then
		NetworkUtil.writeCompressedAngle(streamId, v32_.headRotationRandom)
	end
end

-- Local values: spec, limitFunc, direction, dx, _, dz
function PlaceableSolarPanels:onUpdate(dt)
	local v35_ = self.spec_solarPanels
	if v35_.targetRotation ~= v35_.currentRotation then
		local v36_ = math.min
		local v37_
		if v35_.targetRotation < v35_.currentRotation then
			v36_ = math.max
			v37_ = -1
		else
			v37_ = 1
		end
		v35_.currentRotation = v36_(v35_.currentRotation + v35_.rotationSpeed * dt * v37_, v35_.targetRotation)
		local v38_ = worldDirectionToLocal
		local v39_ = getParent(v35_.headNode)
		local v40_ = v35_.currentRotation
		local v41_ = math.sin(v40_)
		local v42_ = v35_.currentRotation
		local v43_, _, v44_ = v38_(v39_, v41_, 0, (math.cos(v42_)))
		setDirection(v35_.headNode, v43_, 0, v44_, 0, 1, 0)
		if v35_.targetRotation ~= v35_.currentRotation then
			self:raiseActive()
		end
	end
end

function PlaceableSolarPanels:onHourChanged()
	self:updateHeadRotation()
end

-- Local values: spec, sunLight, dx, _, dz, headRotation
function PlaceableSolarPanels:updateHeadRotation()
	local v47_ = self.spec_solarPanels
	if v47_.headNode ~= nil and (g_currentMission ~= nil and g_currentMission.environment ~= nil) then
		local v48_ = g_currentMission.environment.lighting.sunLightId
		if v48_ ~= nil then
			local v49_, _, v50_ = localDirectionToWorld(v48_, 0, 0, 1)
			local v51_ = math.atan2(v49_, v50_)
			if math.abs(v49_) > 0.3 then
				v47_.targetRotation = v51_ + v47_.headRotationRandom
				self:raiseActive()
			end
		end
	end
end

-- Local values: spec, incomePerHour, factor, environment
function PlaceableSolarPanels:getIncomePerHour(superFunc)
	local v54_ = self.spec_solarPanels
	local v55_ = superFunc(self)
	if v54_.hasSolarPanels then
		local v56_ = g_currentMission.environment
		local v57_ = v56_.isSunOn and 1 or 0
		if v56_.currentSeason == Season.WINTER then
			v57_ = v57_ * 0.75
		end
		if v56_.weather:getIsRaining() then
			v57_ = v57_ * 0.1
		end
		v55_ = v55_ + v54_.incomePerHour * v57_
	end
	return v55_
end

function PlaceableSolarPanels:getNeedHourChanged(superFunc)
	return self.spec_solarPanels.hasSolarPanels
end
