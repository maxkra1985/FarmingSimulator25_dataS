Wipers = {}
Wipers.forcedState = -1

function Wipers.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Enterable, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end
	return v2_
end
function Wipers.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("Wipers")
	v3_:register(XMLValueType.STRING, "vehicle.wipers.wiper(?)#animName", "Animation name")
	v3_:register(XMLValueType.FLOAT, "vehicle.wipers.wiper(?).state(?)#animSpeed", "Animation speed")
	v3_:register(XMLValueType.FLOAT, "vehicle.wipers.wiper(?).state(?)#animPause", "Animation pause time (sec.)")
	Dashboard.registerDashboardXMLPaths(v3_, "vehicle.wipers.dashboards", { "state" })
	v3_:setXMLSpecializationType()
end

function Wipers.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadWiperFromXML", Wipers.loadWiperFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForWipers", Wipers.getIsActiveForWipers)
end

function Wipers.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Wipers)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Wipers)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Wipers)
	SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", Wipers)
end

-- Local values: spec, i, key, wiper, maxNumWiperStates, _, wiper, numStates
function Wipers:onLoad(savegame)
	local v7_ = self.spec_wipers
	v7_.wipers = {}
	local v8_ = 0
	while true do
		local v9_ = string.format("vehicle.wipers.wiper(%d)", v8_)
		if not self.xmlFile:hasProperty(v9_) then
			break
		end
		local v10_ = {}
		if self:loadWiperFromXML(self.xmlFile, v9_, v10_) then
			v10_.lastValidState = 1
			v10_.lastState = 0
			local v11_ = v7_.wipers
			table.insert(v11_, v10_)
		end
		v8_ = v8_ + 1
	end
	v7_.hasWipers = #v7_.wipers > 0
	v7_.lastRainScale = 0
	v7_.maxStateWiper = nil
	local v12_ = 0
	for _, v13_ in ipairs(v7_.wipers) do
		local v14_ = #v13_.states
		if v12_ < v14_ then
			v7_.maxStateWiper = v13_
			v12_ = v14_
		end
	end
	if not v7_.hasWipers then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", Wipers)
	end
end

-- Local values: spec, state
function Wipers:onRegisterDashboardValueTypes()
	local v16_ = self.spec_wipers
	if v16_.maxStateWiper ~= nil then
		local v17_ = DashboardValueType.new("wipers", "state")
		v17_:setValue(v16_.maxStateWiper, "lastState")
		v17_:setPollUpdate(false)
		self:registerDashboardValueType(v17_)
	end
end

-- Local values: spec, _, wiper, stateIdToUse, stateIndex, state, currentState
function Wipers:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v19_ = self.spec_wipers
	if self:getIsControlled() then
		v19_.lastRainScale = g_currentMission.environment.weather:getRainFallScale()
		for _, v20_ in pairs(v19_.wipers) do
			local v21_ = 0
			if self:getIsActiveForWipers() and v19_.lastRainScale > 0.01 then
				for v22_, v23_ in ipairs(v20_.states) do
					if v19_.lastRainScale <= v23_.maxRainValue then
						v21_ = v22_
						break
					end
				end
			end
			if Wipers.forcedState ~= -1 then
				local v24_ = Wipers.forcedState
				local v25_ = #v20_.states
				v21_ = math.clamp(v24_, 0, v25_)
			end
			if v21_ > 0 then
				local v26_ = v20_.states[v21_]
				if (v20_.nextStartTime == nil or v20_.nextStartTime < g_currentMission.time) and not self:getIsAnimationPlaying(v20_.animName) then
					self:playAnimation(v20_.animName, v26_.animSpeed, 0, true)
					v20_.nextStartTime = nil
				end
				if v20_.nextStartTime == nil then
					v20_.nextStartTime = g_currentMission.time + v20_.animDuration / v26_.animSpeed * 2 + v26_.animPause
				end
				v20_.lastValidState = v21_
			end
			if v21_ ~= v20_.lastState then
				v20_.lastState = v21_
				if self.isClient and self.updateDashboardValueType ~= nil then
					self:updateDashboardValueType("wipers.state")
				end
			end
		end
	end
end

-- Local values: spec, _, wiper, lastValidState
function Wipers:onFinishAnimation(name)
	local v29_ = self.spec_wipers
	for _, v30_ in pairs(v29_.wipers) do
		if v30_.animName == name and self:getAnimationTime(v30_.animName) == 1 then
			local v31_ = v30_.states[v30_.lastValidState]
			self:playAnimation(v30_.animName, -v31_.animSpeed, 1, true)
		end
	end
end

-- Local values: animName, j, stateKey, state, numStates, stepSize, curMax, _, state
function Wipers:loadWiperFromXML(xmlFile, key, wiper)
	local v36_ = xmlFile:getValue(key .. "#animName")
	if v36_ == nil then
		Logging.xmlWarning(self.xmlFile, "Missing animation for wiper \'%s\'!", key)
		return false
	end
	if not self:getAnimationExists(v36_) then
		Logging.xmlWarning(self.xmlFile, "Animation \'%s\' not defined for wiper \'%s\'!", v36_, key)
		return false
	end
	wiper.animName = v36_
	wiper.animDuration = self:getAnimationDuration(v36_)
	wiper.states = {}
	local v37_ = 0
	while true do
		local v38_ = string.format("%s.state(%d)", key, v37_)
		if not xmlFile:hasProperty(v38_) then
			break
		end
		local v39_ = {
			["animSpeed"] = xmlFile:getValue(v38_ .. "#animSpeed"),
			["animPause"] = xmlFile:getValue(v38_ .. "#animPause")
		}
		if v39_.animSpeed ~= nil and v39_.animPause ~= nil then
			v39_.animPause = v39_.animPause * 1000
			local v40_ = wiper.states
			table.insert(v40_, v39_)
		end
		v37_ = v37_ + 1
	end
	local v41_ = #wiper.states
	if v41_ <= 0 then
		Logging.xmlWarning(self.xmlFile, "No states defined for wiper \'%s\'!", key)
		return false
	end
	local v42_ = 1 / v41_
	local v43_ = v42_
	for _, v44_ in ipairs(wiper.states) do
		v44_.maxRainValue = v42_
		v42_ = v42_ + v43_
	end
	wiper.nextStartTime = nil
	return true
end

function Wipers:getIsActiveForWipers()
	return true
end

-- Local values: usage
function Wipers:consoleSetWiperState(state)
	if state == nil then
		return "Error: No arguments given! Usage: gsWiperStateSet <state> (-1 = use state from weather; 0..n = force specific wiper state)"
	end
	local v46_ = tonumber(state)
	if v46_ == nil then
		return "Error: Argument is not a number! Usage: gsWiperStateSet <state> (-1 = use state from weather; 0..n = force specific wiper state)"
	end
	Wipers.forcedState = math.clamp(v46_, -1, 999)
	return Wipers.forcedState == -1 and " Reset global wiper state, now using weather state" or string.format("Set global wiper states to %d.", Wipers.forcedState)
end
addConsoleCommand("gsWiperStateSet", "Sets the given wiper state for all vehicles", "consoleSetWiperState", Wipers)
