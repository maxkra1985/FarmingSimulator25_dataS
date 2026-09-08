StandaloneMotor = {}

function StandaloneMotor.prerequisitesPresent(self)
	return true
end
function StandaloneMotor.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("StandaloneMotor")
	v1_:register(XMLValueType.TIME, "vehicle.standaloneMotor#turnOffDelay", "Time until the motor is turned off after it is not needed anymore", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.standaloneMotor#idleLoad", "Idle load in percentage [0-1]", 0.2)
	v1_:register(XMLValueType.FLOAT, "vehicle.standaloneMotor#idleRpm", "Idle rpm in percentage [0-1]", 0.2)
	v1_:register(XMLValueType.TIME, "vehicle.standaloneMotor#motorStartDuration", "Time until motor has been started (used for ignitionState dashboard)", 1.5)
	v1_:register(XMLValueType.FLOAT, "vehicle.standaloneMotor#foldMinLimit", "Min. fold time to allow the motor to run", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.standaloneMotor#foldMaxLimit", "Max. fold time to allow the motor to run", 1)
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.standaloneMotor.sounds", "motor(?)")
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.standaloneMotor.effects")
	AnimationManager.registerAnimationNodesXMLPaths(v1_, "vehicle.standaloneMotor.animationNodes")
	Dashboard.registerDashboardXMLPaths(v1_, "vehicle.standaloneMotor.dashboards", {
		"operatingTime",
		"motorTemperature",
		"motorTemperatureWarning",
		"ignitionState"
	})
	v1_:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#isMotorRunning", "Is motor running")
	v1_:setXMLSpecializationType()
end

function StandaloneMotor.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "updateStandaloneMotorTemperature", StandaloneMotor.updateStandaloneMotorTemperature)
	SpecializationUtil.registerFunction(vehicleType, "getNeedsStandaloneMotorRunning", StandaloneMotor.getNeedsStandaloneMotorRunning)
	SpecializationUtil.registerFunction(vehicleType, "getAllowsStandaloneMotorRunning", StandaloneMotor.getAllowsStandaloneMotorRunning)
	SpecializationUtil.registerFunction(vehicleType, "getStandaloneMotorTargetRpm", StandaloneMotor.getStandaloneMotorTargetRpm)
	SpecializationUtil.registerFunction(vehicleType, "getStandaloneMotorLoad", StandaloneMotor.getStandaloneMotorLoad)
end

function StandaloneMotor.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsOperating", StandaloneMotor.getIsOperating)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", StandaloneMotor.loadDashboardGroupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", StandaloneMotor.getIsDashboardGroupActive)
end

function StandaloneMotor.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StandaloneMotor)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", StandaloneMotor)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", StandaloneMotor)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", StandaloneMotor)
end

-- Local values: spec
function StandaloneMotor:onLoad(savegame)
	local v6_ = self.spec_standaloneMotor
	v6_.turnOffDelay = self.xmlFile:getValue("vehicle.standaloneMotor#turnOffDelay", 0)
	v6_.turnOffTimer = v6_.turnOffDelay
	v6_.idleLoad = self.xmlFile:getValue("vehicle.standaloneMotor#idleLoad", 0.2)
	v6_.idleRpm = self.xmlFile:getValue("vehicle.standaloneMotor#idleRpm", 0.2)
	v6_.motorStartDuration = self.xmlFile:getValue("vehicle.standaloneMotor#motorStartDuration", 1.5)
	v6_.motorStartTime = 0
	v6_.foldMinLimit = self.xmlFile:getValue("vehicle.standaloneMotor#foldMinLimit", 0)
	v6_.foldMaxLimit = self.xmlFile:getValue("vehicle.standaloneMotor#foldMaxLimit", 1)
	v6_.isActive = false
	v6_.lastRpm = 0
	v6_.lastLoad = 0
	v6_.motorTemperature = {}
	v6_.motorTemperature.value = 20
	v6_.motorTemperature.valueSend = 20
	v6_.motorTemperature.valueMax = 120
	v6_.motorTemperature.valueMin = 20
	v6_.motorTemperature.heatingPerMS = 0.0015
	v6_.motorFan = {}
	v6_.motorFan.enabled = false
	v6_.motorFan.enableTemperature = 95
	v6_.motorFan.disableTemperature = 85
	v6_.motorFan.coolingPerMS = 0.003
	v6_.motorSamples = g_soundManager:loadSamplesFromXML(self.xmlFile, "vehicle.standaloneMotor.sounds", "motor", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	v6_.motorEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.standaloneMotor.effects", self.components, self, self.i3dMappings)
	v6_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.standaloneMotor.animationNodes", self.components, self, self.i3dMappings)
end

-- Local values: spec, operatingTime, motorTemperature, motorTemperatureWarning, ignitionState
function StandaloneMotor:onRegisterDashboardValueTypes()
	local v_u_8_ = self.spec_standaloneMotor
	local v9_ = DashboardValueType.new("standaloneMotor", "operatingTime")
	v9_:setValue(self, Enterable.getFormattedOperatingTime)
	self:registerDashboardValueType(v9_)
	local v10_ = DashboardValueType.new("standaloneMotor", "motorTemperature")
	v10_:setValue(v_u_8_.motorTemperature, "value")
	v10_:setRange("valueMin", "valueMax")
	self:registerDashboardValueType(v10_)
	local v11_ = DashboardValueType.new("standaloneMotor", "motorTemperatureWarning")
	v11_:setValue(v_u_8_.motorTemperature, function(_, p12_)
		-- upvalues: (copy) v_u_8_
		local v13_ = v_u_8_.motorTemperature.value
		local v14_
		if p12_.warningThresholdMin < v13_ then
			v14_ = v13_ < p12_.warningThresholdMax
		else
			v14_ = false
		end
		return v14_
	end)
	v11_:setAdditionalFunctions(Dashboard.warningAttributes)
	self:registerDashboardValueType(v11_)
	local v15_ = DashboardValueType.new("standaloneMotor", "ignitionState")
	v15_:setValue(self, StandaloneMotor.getMotorIgnitionState)
	v15_:setRange(0, 2)
	self:registerDashboardValueType(v15_)
end

-- Local values: spec
function StandaloneMotor:onDelete()
	local v17_ = self.spec_standaloneMotor
	g_soundManager:deleteSamples(v17_.motorSamples)
	g_effectManager:deleteEffects(v17_.motorEffects)
	g_animationManager:deleteAnimations(v17_.animationNodes)
end

-- Local values: spec, needsRunning, allowsRunning, targetRpm, loadFactorSum, numLoadFactors, loadFactor
function StandaloneMotor:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v20_ = self.spec_standaloneMotor
	local v21_ = self:getNeedsStandaloneMotorRunning()
	local v22_ = self:getAllowsStandaloneMotorRunning()
	local v23_ = v21_ and v22_
	if v20_.isActive ~= v23_ then
		if v23_ then
			v20_.isActive = true
			if not g_soundManager:getIsSamplePlaying(v20_.motorSamples[1]) then
				g_soundManager:playSamples(v20_.motorSamples)
			end
			g_effectManager:startEffects(v20_.motorEffects)
			g_animationManager:startAnimations(v20_.animationNodes)
			v20_.turnOffTimer = v20_.turnOffDelay
			v20_.motorStartTime = g_time + v20_.motorStartDuration
		else
			if v22_ then
				v20_.turnOffTimer = v20_.turnOffTimer - dt
			else
				v20_.turnOffTimer = 0
			end
			if v20_.turnOffTimer <= 0 then
				v20_.isActive = false
				v20_.turnOffTimer = 0
				v20_.lastRpm = 0
				v20_.lastLoad = 0
				g_soundManager:stopSamples(v20_.motorSamples)
				g_effectManager:stopEffects(v20_.motorEffects)
				g_animationManager:stopAnimations(v20_.animationNodes)
			end
		end
	end
	if v20_.isActive then
		local v24_ = v20_.idleRpm + self:getStandaloneMotorTargetRpm() * (1 - v20_.idleRpm)
		v20_.lastRpm = v20_.lastRpm * 0.975 + v24_ * 0.025
		local v25_, v26_ = self:getStandaloneMotorLoad()
		local v27_ = v26_ <= 0 and 0 or v25_ / v26_
		v20_.lastLoad = v20_.idleLoad + v27_ * (1 - v20_.idleLoad)
		g_soundManager:setSamplesLoopSynthesisParameters(v20_.motorSamples, v20_.lastRpm, v20_.lastLoad)
		g_effectManager:setDensity(v20_.motorEffects, v20_.lastRpm)
		self:updateStandaloneMotorTemperature(dt)
		self:raiseActive()
	end
end

function StandaloneMotor:getNeedsStandaloneMotorRunning()
	return self:getRequiresPower()
end

-- Local values: spec, time
function StandaloneMotor:getAllowsStandaloneMotorRunning()
	if self.getFoldAnimTime ~= nil then
		local v30_ = self.spec_standaloneMotor
		local v31_ = self:getFoldAnimTime()
		if v31_ < v30_.foldMinLimit or v30_.foldMaxLimit < v31_ then
			return false
		end
	end
	return true
end

function StandaloneMotor.getStandaloneMotorTargetRpm(self)
	return 0
end

function StandaloneMotor:getStandaloneMotorLoad()
	return 0, 0
end

-- Local values: spec, delta, factor
function StandaloneMotor:updateStandaloneMotorTemperature(dt)
	local v34_ = self.spec_standaloneMotor
	local v35_ = v34_.motorTemperature.heatingPerMS * dt * ((1 + 4 * v34_.lastLoad) / 5 + v34_.lastRpm)
	local v36_ = v34_.motorTemperature
	local v37_ = v34_.motorTemperature.valueMax
	local v38_ = v34_.motorTemperature.value + v35_
	v36_.value = math.min(v37_, v38_)
	if v34_.motorTemperature.value > v34_.motorFan.enableTemperature then
		v34_.motorFan.enabled = true
	end
	if v34_.motorFan.enabled and v34_.motorTemperature.value < v34_.motorFan.disableTemperature then
		v34_.motorFan.enabled = false
	end
	if v34_.motorFan.enabled then
		local v39_ = v34_.motorFan.coolingPerMS * dt
		local v40_ = v34_.motorTemperature
		local v41_ = v34_.motorTemperature.valueMin
		local v42_ = v34_.motorTemperature.value - v39_
		v40_.value = math.max(v41_, v42_)
	end
end

function StandaloneMotor:getIsOperating(superFunc)
	return superFunc(self) or self.spec_standaloneMotor.isActive
end

function StandaloneMotor:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
		return false
	end
	group.isMotorRunning = xmlFile:getValue(key .. "#isMotorRunning")
	return true
end

function StandaloneMotor:getIsDashboardGroupActive(superFunc, group)
	if group.isMotorRunning and not self.spec_standaloneMotor.isActive then
		return false
	else
		return superFunc(self, group)
	end
end

-- Local values: spec, realRpm
function StandaloneMotor:updateDebugValues(values)
	if self.isServer then
		local v55_ = self.spec_standaloneMotor
		local v56_ = (v55_.motorSamples[1] == nil or not v55_.motorSamples[1].isGlsFile) and 0 or getSampleLoopSynthesisRPM(v55_.motorSamples[1].soundSample, false)
		local v57_ = {
			["name"] = "RPM",
			["value"] = string.format("%d%% %drpm", v55_.lastRpm * 100, v56_)
		}
		table.insert(values, v57_)
		local v58_ = {
			["name"] = "Load",
			["value"] = string.format("%d%%", v55_.lastLoad * 100)
		}
		table.insert(values, v58_)
		local v59_ = {
			["name"] = "turnOffTimer",
			["value"] = string.format("%.1f sec", v55_.turnOffTimer * 0.001)
		}
		table.insert(values, v59_)
		local v60_ = {
			["name"] = "temperature",
			["value"] = string.format("%.1f \194\176C", v55_.motorTemperature.value)
		}
		table.insert(values, v60_)
	end
end

-- Local values: spec
function StandaloneMotor:getMotorIgnitionState()
	local v62_ = self.spec_standaloneMotor
	return v62_.isActive and (v62_.motorStartTime > g_time and 1 or 2) or 0
end
