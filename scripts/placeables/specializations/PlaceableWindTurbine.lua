PlaceableWindTurbine = {}

function PlaceableWindTurbine.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(PlaceableIncomePerHour, specializations)
end

function PlaceableWindTurbine.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateHeadRotation", PlaceableWindTurbine.updateHeadRotation)
	SpecializationUtil.registerFunction(placeableType, "updateRotorRotSpeed", PlaceableWindTurbine.updateRotorRotSpeed)
	SpecializationUtil.registerFunction(placeableType, "setWindValues", PlaceableWindTurbine.setWindValues)
	SpecializationUtil.registerFunction(placeableType, "getWindTurbineLoad", PlaceableWindTurbine.getWindTurbineLoad)
	SpecializationUtil.registerFunction(placeableType, "startWindTurbine", PlaceableWindTurbine.startWindTurbine)
end

function PlaceableWindTurbine.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getIncomePerHour", PlaceableWindTurbine.getIncomePerHour)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "finalizeConstruction", PlaceableWindTurbine.finalizeConstruction)
end

function PlaceableWindTurbine.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableWindTurbine)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWindTurbine)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableWindTurbine)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableWindTurbine)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableWindTurbine)
end

function PlaceableWindTurbine.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("WindTurbine")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".windTurbine#headNode", "Head node")
	schema:register(XMLValueType.BOOL, basePath .. ".windTurbine#headAdjustToWind", "Adjust head node to current wind direction")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".windTurbine#rotationNode", "Rotor rotation node, rotated on z-axis")
	schema:register(XMLValueType.FLOAT, basePath .. ".windTurbine#optimalWindSpeed", "Wind speed in m/s at which rotor reaches max rpm")
	schema:register(XMLValueType.FLOAT, basePath .. ".windTurbine#incomePerHour", "Income per hour")
	schema:register(XMLValueType.BOOL, basePath .. ".windTurbine#isFinalized", "If the wind turbine is finalized and ready on start. E.g. constructible")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".windTurbine.sounds", "idle")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".windTurbine.animationNodes")
	schema:setXMLSpecializationType()
end

function PlaceableWindTurbine.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("WindTurbine")
	schema:register(XMLValueType.ANGLE, basePath .. "#headRotation", "Current head rotation")
	schema:setXMLSpecializationType()
end

-- Local values: spec, headNode, _, anim
function PlaceableWindTurbine:onLoad(savegame)
	local v_u_10_ = self.spec_windTurbine
	local v11_ = self.xmlFile:getValue("placeable.windTurbine#headNode", nil, self.components, self.i3dMappings)
	if v11_ ~= nil then
		v_u_10_.headNode = v11_
		v_u_10_.headAdjustToWind = self.xmlFile:getValue("placeable.windTurbine#headAdjustToWind", false)
		v_u_10_.headRotation = 0
	end
	local v12_ = self.xmlFile:getValue("placeable.windTurbine#optimalWindSpeed", 15)
	v_u_10_.rotorOptimalWindSpeed = math.clamp(v12_, 1, 200)
	v_u_10_.rotSpeedFactor = 1
	v_u_10_.incomePerHour = self.xmlFile:getValue("placeable.windTurbine#incomePerHour", 0)
	v_u_10_.isFinalized = self.xmlFile:getBool("placeable.windTurbine#isFinalized", true)
	if self.isClient then
		v_u_10_.samples = {}
		v_u_10_.samples.idle = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.windTurbine.sounds", "idle", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
		v_u_10_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "placeable.windTurbine.animationNodes", self.components, self, self.i3dMappings)
		for _, v13_ in ipairs(v_u_10_.animationNodes) do
			function v13_.speedFunc()
				-- upvalues: (copy) v_u_10_
				return v_u_10_.rotSpeedFactor
			end
		end
	end
end

-- Local values: spec
function PlaceableWindTurbine:onDelete()
	g_currentMission.environment.weather.windUpdater:removeWindChangedListener(self)
	local v15_ = self.spec_windTurbine
	g_soundManager:deleteSamples(v15_.samples)
	g_animationManager:deleteAnimations(v15_.animationNodes)
end

-- Local values: spec
function PlaceableWindTurbine:onFinalizePlacement()
	if self.spec_windTurbine.isFinalized then
		self:startWindTurbine()
	end
end

-- Local values: spec
function PlaceableWindTurbine:onReadStream(streamId, connection)
	local v19_ = self.spec_windTurbine
	if v19_.headNode ~= nil then
		v19_.headRotation = NetworkUtil.readCompressedAngle(streamId)
	end
end

-- Local values: spec
function PlaceableWindTurbine:onWriteStream(streamId, connection)
	local v22_ = self.spec_windTurbine
	if v22_.headNode ~= nil then
		NetworkUtil.writeCompressedAngle(streamId, v22_.headRotation)
	end
end

-- Local values: spec
function PlaceableWindTurbine:loadFromXMLFile(xmlFile, key)
	local v26_ = self.spec_windTurbine
	if v26_.headNode ~= nil then
		v26_.headRotation = xmlFile:getValue(key .. "#headRotation", 0)
		self:updateHeadRotation()
	end
end

-- Local values: spec
function PlaceableWindTurbine:saveToXMLFile(xmlFile, key, usedModNames)
	local v30_ = self.spec_windTurbine
	if v30_.headNode ~= nil then
		xmlFile:setValue(key .. "#headRotation", v30_.headRotation)
	end
end

-- Local values: spec, windUpdater, windDirX, windDirZ, windVelocity, rotVariation
function PlaceableWindTurbine:startWindTurbine()
	local v32_ = self.spec_windTurbine
	local v33_ = g_currentMission.environment.weather.windUpdater
	v33_:addWindChangedListener(self)
	local v34_, v35_, v36_ = v33_:getCurrentValues()
	if v32_.headNode ~= nil then
		v32_.headRotation = MathUtil.getYRotationFromDirection(-v34_, -v35_)
		if not v32_.headAdjustToWind then
			v32_.headRotation = 0.7 + math.random() * 2 * 0.2 - 0.2
		end
		self:updateHeadRotation()
	end
	self:updateRotorRotSpeed(v36_)
	g_animationManager:startAnimations(v32_.animationNodes)
end

-- Local values: spec
function PlaceableWindTurbine:finalizeConstruction(superFunc)
	superFunc(self)
	self.spec_windTurbine.isFinalized = true
	self:startWindTurbine()
end

-- Local values: spec
function PlaceableWindTurbine:updateHeadRotation()
	local v40_ = self.spec_windTurbine
	if v40_.headNode ~= nil then
		setWorldRotation(v40_.headNode, 0, v40_.headRotation, 0)
	end
end

-- Local values: spec
function PlaceableWindTurbine:updateRotorRotSpeed(windVelocity)
	local v43_ = self.spec_windTurbine
	local v44_ = windVelocity / v43_.rotorOptimalWindSpeed
	v43_.rotSpeedFactor = math.clamp(v44_, 0, 1)
	if self.isClient then
		if v43_.rotSpeedFactor > 0 then
			if not g_soundManager:getIsSamplePlaying(v43_.samples.idle) then
				g_soundManager:playSample(v43_.samples.idle, 0)
				return
			end
		elseif g_soundManager:getIsSamplePlaying(v43_.samples.idle) then
			g_soundManager:stopSample(v43_.samples.idle)
		end
	end
end

-- Local values: spec
function PlaceableWindTurbine:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
	local v49_ = self.spec_windTurbine
	if v49_.headAdjustToWind and v49_.headNode ~= nil then
		v49_.headRotation = MathUtil.getYRotationFromDirection(-windDirX, -windDirZ)
		self:updateHeadRotation()
	end
	self:updateRotorRotSpeed(windVelocity)
end

-- Local values: spec
function PlaceableWindTurbine:getWindTurbineLoad()
	return self.spec_windTurbine.rotSpeedFactor
end
g_soundManager:registerModifierType("WIND_TURBINE_LOAD", PlaceableWindTurbine.getWindTurbineLoad)

-- Local values: spec, incomePerHour
function PlaceableWindTurbine:getIncomePerHour(superFunc)
	local v53_ = self.spec_windTurbine
	return superFunc(self) + v53_.incomePerHour * v53_.rotSpeedFactor
end
