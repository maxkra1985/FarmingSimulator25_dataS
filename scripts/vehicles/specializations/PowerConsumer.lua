PowerConsumer = {}
function PowerConsumer.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("powerConsumer", g_i18n:getText("configuration_powerConsumer"), "powerConsumer", VehicleConfigurationItem)
	g_storeManager:addSpecType("neededPower", "shopListAttributeIconPowerReq", PowerConsumer.loadSpecValueNeededPower, PowerConsumer.getSpecValueNeededPower, StoreSpecies.VEHICLE)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("PowerConsumer")
	PowerConsumer.registerPowerConsumerXMLPaths(v1_, "vehicle.powerConsumer")
	PowerConsumer.registerPowerConsumerXMLPaths(v1_, "vehicle.powerConsumer.powerConsumerConfigurations.powerConsumerConfiguration(?)")
	v1_:register(XMLValueType.INT, "vehicle.storeData.specs.neededPower", "Needed power")
	v1_:register(XMLValueType.INT, "vehicle.storeData.specs.neededPower#maxPower", "Max. recommended power")
	v1_:register(XMLValueType.INT, "vehicle.powerConsumer.powerConsumerConfigurations.powerConsumerConfiguration(?)#neededPower", "Needed power")
	v1_:addDelayedRegistrationFunc("WorkMode:workMode", function(p2_, p3_)
		p2_:register(XMLValueType.FLOAT, p3_ .. "#forceScale", "Scale the powerConsumer force up or down", 1)
		p2_:register(XMLValueType.FLOAT, p3_ .. "#ptoPowerScale", "Scale the powerConsumer pto power up or down", 1)
	end)
	v1_:setXMLSpecializationType()
end

function PowerConsumer.registerPowerConsumerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#forceNode", "Force node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#forceDirNode", "Force node", "Force node")
	schema:register(XMLValueType.FLOAT, basePath .. "#forceFactor", "Force factor", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxForce", "Max. force (kN)", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#forceDir", "Force direction", 1)
	schema:register(XMLValueType.BOOL, basePath .. "#useTurnOnState", "While vehicle is turned on the vehicle consumes the pto power", true)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnPeakPowerMultiplier", "While turning the tool on a short peak power with this multiplier is consumed", 3)
	schema:register(XMLValueType.TIME, basePath .. "#turnOnPeakPowerDuration", "Duration for peak power while turning on (sec)", 2)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#turnOnNotAllowedWarning", "Turn on not allowed text", "warning_insufficientPowerOutput")
	schema:register(XMLValueType.FLOAT, basePath .. "#neededMaxPtoPower", "Needed max. pto power", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#neededMinPtoPower", "Needed min. pto power", "neededMaxPtoPower")
	schema:register(XMLValueType.FLOAT, basePath .. "#ptoRpm", "Pto rpm", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#virtualPowerMultiplicator", "Virtual multiplicator for pto power to increased the motor load without reducing the available power for driving", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".speedLimitModifier(?)#offset", "Speed limit offset to apply")
	schema:register(XMLValueType.FLOAT, basePath .. ".speedLimitModifier(?)#minPowerHp", "Min. power in HP of root motor", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".speedLimitModifier(?)#maxPowerHp", "Max. power in HP of root motor", 0)
end

function PowerConsumer.prerequisitesPresent(self)
	return true
end

function PowerConsumer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadPowerSetup", PowerConsumer.loadPowerSetup)
	SpecializationUtil.registerFunction(vehicleType, "getPtoRpm", PowerConsumer.getPtoRpm)
	SpecializationUtil.registerFunction(vehicleType, "getDoConsumePtoPower", PowerConsumer.getDoConsumePtoPower)
	SpecializationUtil.registerFunction(vehicleType, "getPowerMultiplier", PowerConsumer.getPowerMultiplier)
	SpecializationUtil.registerFunction(vehicleType, "getConsumedPtoTorque", PowerConsumer.getConsumedPtoTorque)
	SpecializationUtil.registerFunction(vehicleType, "getConsumingLoad", PowerConsumer.getConsumingLoad)
end

function PowerConsumer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", PowerConsumer.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOnAll", PowerConsumer.getCanBeTurnedOnAll)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", PowerConsumer.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRawSpeedLimit", PowerConsumer.getRawSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkModeFromXML", PowerConsumer.loadWorkModeFromXML)
end

function PowerConsumer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", PowerConsumer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", PowerConsumer)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", PowerConsumer)
	SpecializationUtil.registerEventListener(vehicleType, "onWorkModeChanged", PowerConsumer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", PowerConsumer)
end

-- Local values: spec, foldingConfigurationId, configKey
function PowerConsumer:onLoad(savegame)
	local v_u_10_ = self.spec_powerConsumer
	local v11_ = Utils.getNoNil(self.configurations.powerConsumer, 1)
	local v12_ = string.format("vehicle.powerConsumer.powerConsumerConfigurations.powerConsumerConfiguration(%d)", v11_ - 1)
	local v13_ = not self.xmlFile:hasProperty(v12_) and "vehicle.powerConsumer" or v12_
	v_u_10_.forceNode = self.xmlFile:getValue(v13_ .. "#forceNode", nil, self.components, self.i3dMappings)
	v_u_10_.forceDirNode = self.xmlFile:getValue(v13_ .. "#forceDirNode", v_u_10_.forceNode, self.components, self.i3dMappings)
	v_u_10_.forceFactor = self.xmlFile:getValue(v13_ .. "#forceFactor", 1)
	v_u_10_.maxForce = self.xmlFile:getValue(v13_ .. "#maxForce", 0)
	v_u_10_.forceDir = self.xmlFile:getValue(v13_ .. "#forceDir", 1)
	v_u_10_.useTurnOnState = self.xmlFile:getValue(v13_ .. "#useTurnOnState", true)
	v_u_10_.turnOnNotAllowedWarning = string.format(self.xmlFile:getValue(v13_ .. "#turnOnNotAllowedWarning", "warning_insufficientPowerOutput", self.customEnvironment), self.typeDesc)
	self:loadPowerSetup(self.xmlFile, v13_)
	v_u_10_.speedLimitModifier = {}
	v_u_10_.sourceMotorPeakPower = math.huge
	v_u_10_.turnOnPeakPowerMultiplier = self.xmlFile:getValue(v13_ .. "#turnOnPeakPowerMultiplier", 3)
	v_u_10_.turnOnPeakPowerDuration = self.xmlFile:getValue(v13_ .. "#turnOnPeakPowerDuration", 2.5)
	v_u_10_.turnOnPeakPowerTimer = -1
	self.xmlFile:iterate(v13_ .. ".speedLimitModifier", function(_, p14_)
		-- upvalues: (copy) self, (copy) v_u_10_
		local v15_ = {
			["offset"] = self.xmlFile:getValue(p14_ .. "#offset")
		}
		if v15_.offset == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid offset found for \'%s\'", p14_)
		else
			v15_.minPowerKw = self.xmlFile:getValue(p14_ .. "#minPowerHp", 0) * 0.735499
			v15_.maxPowerKw = self.xmlFile:getValue(p14_ .. "#maxPowerHp", 0) * 0.735499
			local v16_ = v_u_10_.speedLimitModifier
			table.insert(v16_, v15_)
		end
	end)
	if #v_u_10_.speedLimitModifier == 0 then
		SpecializationUtil.removeEventListener(self, "onPostDetach", PowerConsumer)
	end
end

-- Local values: spec, multiplier, frictionForce, force, dx, dy, dz, px, py, pz, str
function PowerConsumer:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isActive then
		local v19_ = self.spec_powerConsumer
		if v19_.forceNode ~= nil and (self.movingDirection == v19_.forceDir and self.lastSpeedReal > 0.0001) then
			local v20_ = self:getPowerMultiplier()
			if v20_ ~= 0 then
				local v21_ = v19_.forceFactor * self.lastSpeedReal * 1000 * self:getTotalMass(false) / (dt / 1000)
				local v22_ = v19_.maxForce
				local v23_ = -math.min(v21_, v22_) * self.movingDirection * v20_
				local v24_, v25_, v26_ = localDirectionToWorld(v19_.forceDirNode, 0, 0, v23_)
				local v27_, v28_, v29_ = getCenterOfMass(v19_.forceNode)
				addForce(v19_.forceNode, v24_, v25_, v26_, v27_, v28_, v29_, true)
				if (VehicleDebug.state == VehicleDebug.DEBUG_PHYSICS or VehicleDebug.state == VehicleDebug.DEBUG_TUNING) and self.isActiveForInputIgnoreSelectionIgnoreAI then
					local v30_ = string.format("frictionForce=%.2f maxForce=%.2f -> force=%.2f", v21_, v19_.maxForce, v23_)
					renderText(0.7, 0.85, getCorrectTextSize(0.02), v30_)
				end
			end
		end
		if v19_.turnOnPeakPowerTimer > 0 then
			v19_.turnOnPeakPowerTimer = v19_.turnOnPeakPowerTimer - dt
		end
	end
end

-- Local values: spec
function PowerConsumer:loadPowerSetup(xmlFile, baseKey)
	local v34_ = self.spec_powerConsumer
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseKey .. "#neededPtoPower", string.format("%s#neededMinPtoPower and %s#neededMaxPtoPower", baseKey, baseKey))
	v34_.neededMaxPtoPower = xmlFile:getValue(baseKey .. "#neededMaxPtoPower", 0)
	v34_.neededMinPtoPower = xmlFile:getValue(baseKey .. "#neededMinPtoPower", v34_.neededMaxPtoPower)
	if v34_.neededMaxPtoPower < v34_.neededMinPtoPower then
		Logging.xmlWarning(self.xmlFile, "\'%s#neededMaxPtoPower\' is smaller than \'%s#neededMinPtoPower\'", baseKey, baseKey)
	end
	v34_.ptoRpm = xmlFile:getValue(baseKey .. "#ptoRpm", 0)
	v34_.virtualPowerMultiplicator = xmlFile:getValue(baseKey .. "#virtualPowerMultiplicator", 1)
end

function PowerConsumer:getPtoRpm()
	return not self:getDoConsumePtoPower() and 0 or self.spec_powerConsumer.ptoRpm
end

function PowerConsumer:getDoConsumePtoPower()
	local v37_ = self.spec_powerConsumer.useTurnOnState
	if v37_ then
		if self.getIsTurnedOn == nil then
			v37_ = false
		else
			v37_ = self:getIsTurnedOn()
		end
	end
	return v37_
end

function PowerConsumer.getPowerMultiplier(self)
	return 1
end

-- Local values: spec, rpm, consumingLoad, count, turnOnPeakPowerMultiplier, neededPtoPower
function PowerConsumer:getConsumedPtoTorque(expected, ignoreTurnOnPeak)
	if self:getDoConsumePtoPower() or expected ~= nil and expected then
		local v41_ = self.spec_powerConsumer
		local v42_ = v41_.ptoRpm
		if v42_ > 0.001 then
			local v43_, v44_ = self:getConsumingLoad()
			local v45_ = v44_ <= 0 and 1 or v43_ / v44_
			local v46_ = v41_.turnOnPeakPowerTimer / v41_.turnOnPeakPowerDuration
			local v47_ = math.min(v46_, 1)
			local v48_ = math.max(v47_, 0) * v41_.turnOnPeakPowerMultiplier
			local v49_ = math.max(v48_, 1)
			local v50_ = ignoreTurnOnPeak == true and 1 or v49_
			return (v41_.neededMinPtoPower + v45_ * (v41_.neededMaxPtoPower - v41_.neededMinPtoPower)) / (v42_ * 3.141592653589793 / 30), v41_.virtualPowerMultiplicator * v50_
		end
	end
	return 0, 1
end

function PowerConsumer:getConsumingLoad()
	return 0, 0
end

-- Local values: rootVehicle, rootMotor, torqueRequested, _, totalTorque, _
function PowerConsumer:getCanBeTurnedOn(superFunc)
	local v53_ = self.rootVehicle
	if v53_ ~= nil and v53_.getMotor ~= nil then
		local v54_ = v53_:getMotor()
		local v55_, _ = self:getConsumedPtoTorque(true)
		local v56_, _ = PowerConsumer.getTotalConsumedPtoTorque(v53_, self)
		local v57_ = (v55_ + v56_) / v54_:getPtoMotorRpmRatio()
		if v57_ > 0 and (0.9 * v54_:getPeakTorque() < v57_ and not self:getIsTurnedOn()) then
			return false, true
		end
	end
	if superFunc == nil then
		return true, false
	else
		return superFunc(self)
	end
end

-- Local values: rootVehicle, rootMotor, torqueRequested, _
function PowerConsumer:getCanBeTurnedOnAll(superFunc)
	if not superFunc(self) then
		return false
	end
	local v60_ = self.rootVehicle
	if v60_ ~= nil and v60_.getMotor ~= nil then
		local v61_ = v60_:getMotor()
		local v62_, _ = PowerConsumer.getTotalConsumedPtoTorque(v60_, nil, true)
		local v63_ = v62_ / v61_:getPtoMotorRpmRatio()
		if v63_ > 0 and (0.9 * v61_:getPeakTorque() < v63_ and not self:getIsTurnedOn()) then
			return false, self.spec_powerConsumer.turnOnNotAllowedWarning
		end
	end
	return true, false
end

-- Local values: spec, _, notEnoughPower
function PowerConsumer:getTurnedOnNotAllowedWarning(superFunc)
	local v66_ = self.spec_powerConsumer
	local _, v67_ = PowerConsumer.getCanBeTurnedOn(self)
	if v67_ then
		return v66_.turnOnNotAllowedWarning
	else
		return superFunc(self)
	end
end

-- Local values: rawSpeedLimit, spec, i, modifier
function PowerConsumer:getRawSpeedLimit(superFunc)
	local v70_ = superFunc(self)
	local v71_ = self.spec_powerConsumer
	for v72_ = #v71_.speedLimitModifier, 1, -1 do
		local v73_ = v71_.speedLimitModifier[v72_]
		if v71_.sourceMotorPeakPower >= v73_.minPowerKw and v71_.sourceMotorPeakPower <= v73_.maxPowerKw then
			return v70_ + v73_.offset
		end
	end
	return v70_
end

function PowerConsumer:loadWorkModeFromXML(superFunc, xmlFile, key, workMode)
	if not superFunc(self, xmlFile, key, workMode) then
		return false
	end
	workMode.forceScale = xmlFile:getValue(key .. "#forceScale", 1)
	workMode.ptoPowerScale = xmlFile:getValue(key .. "#ptoPowerScale", 1)
	return true
end

-- Local values: spec, rootVehicle, rootMotor
function PowerConsumer:onStateChange(state, data)
	if state == VehicleStateChange.ATTACH or state == VehicleStateChange.DETACH then
		local v81_ = self.spec_powerConsumer
		local v82_ = self.rootVehicle
		if v82_ ~= nil and v82_.getMotor ~= nil then
			v81_.sourceMotorPeakPower = v82_:getMotor().peakMotorPower
			return
		end
		v81_.sourceMotorPeakPower = math.huge
	end
end

-- Local values: spec
function PowerConsumer:onWorkModeChanged(workMode, oldWorkMode)
	if workMode.forceScale ~= nil then
		local v85_ = self.spec_powerConsumer
		if v85_.maxForceOrig == nil then
			v85_.maxForceOrig = v85_.maxForce
			v85_.neededMinPtoPowerOrig = v85_.neededMinPtoPower
			v85_.neededMaxPtoPowerOrig = v85_.neededMaxPtoPower
		end
		v85_.maxForce = v85_.maxForceOrig * workMode.forceScale
		v85_.neededMinPtoPower = v85_.neededMinPtoPowerOrig * workMode.forceScale
		v85_.neededMaxPtoPower = v85_.neededMaxPtoPowerOrig * workMode.forceScale
	end
end

function PowerConsumer:onTurnedOn()
	self.spec_powerConsumer.turnOnPeakPowerTimer = self.spec_powerConsumer.turnOnPeakPowerDuration * 1.5
end

-- Local values: torque, virtualMultiplicator, attachedImplements, _, implement, implementTorque, implementMultiplicator, ratio
function PowerConsumer:getTotalConsumedPtoTorque(excludeVehicle, expected, ignoreTurnOnPeak)
	local v91_, v92_
	if self == excludeVehicle or self.getConsumedPtoTorque == nil then
		v91_ = 0
		v92_ = 1
	else
		v91_, v92_ = self:getConsumedPtoTorque(expected, ignoreTurnOnPeak)
	end
	if self.getAttachedImplements ~= nil then
		local v93_ = self:getAttachedImplements()
		for _, v94_ in pairs(v93_) do
			local v95_, v96_ = PowerConsumer.getTotalConsumedPtoTorque(v94_.object, excludeVehicle, expected, ignoreTurnOnPeak)
			v91_ = v91_ + v95_
			if v91_ == 0 then
				v92_ = v96_
			else
				local v97_ = v95_ / v91_
				v92_ = v92_ * (1 - v97_) + v96_ * v97_
			end
		end
	end
	return v91_, v92_
end

-- Local values: rpm, attachedImplements, _, implement
function PowerConsumer:getMaxPtoRpm()
	local v99_ = self.getPtoRpm == nil and 0 or self:getPtoRpm()
	if self.getAttachedImplements ~= nil then
		local v100_ = self:getAttachedImplements()
		for _, v101_ in pairs(v100_) do
			local v102_ = PowerConsumer.getMaxPtoRpm
			local v103_ = v101_.object
			v99_ = math.max(v99_, v102_(v103_))
		end
	end
	return v99_
end

-- Local values: object, _, veh
function PowerConsumer:consoleSetPowerConsumer(neededMinPtoPower, neededMaxPtoPower, forceFactor, maxForce, forceDir, ptoRpm)
	if neededMinPtoPower == nil then
		return "No arguments given! Usage: gsPowerConsumerSet <neededMinPtoPower> <neededMaxPtoPower> <forceFactor> <maxForce> <forceDir> <ptoRpm>"
	end
	local v110_
	if g_currentMission == nil or (g_localPlayer:getCurrentVehicle() == nil or (g_localPlayer:getCurrentVehicle():getSelectedImplement() == nil or g_localPlayer:getCurrentVehicle():getSelectedImplement().object.spec_powerConsumer == nil)) then
		v110_ = nil
	else
		v110_ = g_localPlayer:getCurrentVehicle():getSelectedImplement().object
	end
	if v110_ == nil then
		return "No vehicle with powerConsumer specialization selected"
	end
	v110_.spec_powerConsumer.neededMinPtoPower = Utils.getNoNil(neededMinPtoPower, v110_.spec_powerConsumer.neededMinPtoPower)
	v110_.spec_powerConsumer.neededMaxPtoPower = Utils.getNoNil(neededMaxPtoPower, v110_.spec_powerConsumer.neededMaxPtoPower)
	v110_.spec_powerConsumer.forceFactor = Utils.getNoNil(forceFactor, v110_.spec_powerConsumer.forceFactor)
	v110_.spec_powerConsumer.maxForce = Utils.getNoNil(maxForce, v110_.spec_powerConsumer.maxForce)
	v110_.spec_powerConsumer.forceDir = Utils.getNoNil(forceDir, v110_.spec_powerConsumer.forceDir)
	v110_.spec_powerConsumer.ptoRpm = Utils.getNoNil(ptoRpm, v110_.spec_powerConsumer.ptoRpm)
	for _, v111_ in pairs(g_currentMission.vehicleSystem.vehicles) do
		if v111_.configFileName == v110_.configFileName then
			v111_.spec_powerConsumer.neededMinPtoPower = v110_.spec_powerConsumer.neededMinPtoPower
			v111_.spec_powerConsumer.neededMaxPtoPower = v110_.spec_powerConsumer.neededMaxPtoPower
			v111_.spec_powerConsumer.forceFactor = v110_.spec_powerConsumer.forceFactor
			v111_.spec_powerConsumer.maxForce = v110_.spec_powerConsumer.maxForce
			v111_.spec_powerConsumer.forceDir = v110_.spec_powerConsumer.forceDir
			v111_.spec_powerConsumer.ptoRpm = v110_.spec_powerConsumer.ptoRpm
		end
	end
	return string.format("Updated power consumer for \'%s\'", v110_.configFileName)
end
addConsoleCommand("gsPowerConsumerSet", "Sets properties of the powerConsumer specialization", "consoleSetPowerConsumer", PowerConsumer)

-- Local values: neededPower, i, baseKey
function PowerConsumer.loadSpecValueNeededPower(xmlFile, customEnvironment, baseDir)
	local v113_ = {
		["base"] = xmlFile:getValue("vehicle.storeData.specs.neededPower"),
		["maxPower"] = xmlFile:getValue("vehicle.storeData.specs.neededPower#maxPower"),
		["config"] = {}
	}
	local v114_ = 0
	while true do
		local v115_ = string.format("vehicle.powerConsumer.powerConsumerConfigurations.powerConsumerConfiguration(%d)", v114_)
		if not xmlFile:hasProperty(v115_) then
			break
		end
		v113_.config[v114_ + 1] = xmlFile:getValue(v115_ .. "#neededPower")
		v114_ = v114_ + 1
	end
	return v113_
end

-- Local values: minPower, maxPower, _, value, hp, kw, minHP, _, maxHP, _
function PowerConsumer.getSpecValueNeededPower(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.neededPower == nil then
		return nil
	end
	local v117_ = math.huge
	local v118_ = -math.huge
	for _, v119_ in pairs(storeItem.specs.neededPower.config) do
		v117_ = math.min(v117_, v119_)
		v118_ = math.max(v118_, v119_)
	end
	if v117_ == math.huge then
		v117_ = storeItem.specs.neededPower.base or 0
		v118_ = storeItem.specs.neededPower.maxPower
	end
	if v117_ == 0 then
		return nil
	end
	if v118_ == nil or v117_ == v118_ then
		local v120_, v121_ = g_i18n:getPower(v117_)
		return string.format(g_i18n:getText("shop_neededPowerValue"), MathUtil.round(v121_), MathUtil.round(v120_))
	end
	local v122_, _ = g_i18n:getPower(v117_)
	local v123_, _ = g_i18n:getPower(v118_)
	return string.format(g_i18n:getText("shop_neededPowerValueMinMax"), MathUtil.round(v122_), MathUtil.round(v123_))
end
