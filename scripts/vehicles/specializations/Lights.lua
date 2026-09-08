source("dataS/scripts/vehicles/specializations/events/VehicleSetBeaconLightEvent.lua")
source("dataS/scripts/vehicles/specializations/events/VehicleSetTurnLightEvent.lua")
source("dataS/scripts/vehicles/specializations/events/VehicleSetLightEvent.lua")
source("dataS/scripts/vehicles/specializations/components/SharedLight.lua")
source("dataS/scripts/vehicles/specializations/components/BeaconLight.lua")
source("dataS/scripts/vehicles/specializations/components/StaticLight.lua")
source("dataS/scripts/vehicles/specializations/components/StaticLightCompound.lua")
source("dataS/scripts/vehicles/specializations/components/RealLight.lua")
Lights = {}
Lights.TURNLIGHT_OFF = 0
Lights.TURNLIGHT_LEFT = 1
Lights.TURNLIGHT_RIGHT = 2
Lights.TURNLIGHT_HAZARD = 3
Lights.turnLightSendNumBits = 3
Lights.LIGHT_TYPE_DEFAULT = 0
Lights.LIGHT_TYPE_WORK_BACK = 1
Lights.LIGHT_TYPE_WORK_FRONT = 2
Lights.LIGHT_TYPE_HIGHBEAM = 3
Lights.sharedLightXMLSchema = nil
Lights.beaconLightXMLSchema = nil
Lights.ADDITIONAL_LIGHT_ATTRIBUTES_KEYS = {
	"vehicle.lights.sharedLight(?)",
	"vehicle.lights.realLights.low.light(?)",
	"vehicle.lights.realLights.low.topLight(?)",
	"vehicle.lights.realLights.low.bottomLight(?)",
	"vehicle.lights.realLights.low.brakeLight(?)",
	"vehicle.lights.realLights.low.reverseLight(?)",
	"vehicle.lights.realLights.low.turnLightLeft(?)",
	"vehicle.lights.realLights.low.turnLightRight(?)",
	"vehicle.lights.realLights.low.interiorLight(?)",
	"vehicle.lights.realLights.high.light(?)",
	"vehicle.lights.realLights.high.topLight(?)",
	"vehicle.lights.realLights.high.bottomLight(?)",
	"vehicle.lights.realLights.high.brakeLight(?)",
	"vehicle.lights.realLights.high.reverseLight(?)",
	"vehicle.lights.realLights.high.turnLightLeft(?)",
	"vehicle.lights.realLights.high.turnLightRight(?)",
	"vehicle.lights.realLights.high.interiorLight(?)",
	"vehicle.lights.defaultLights.defaultLight(?)",
	"vehicle.lights.topLights.topLight(?)",
	"vehicle.lights.bottomLights.bottomLight(?)",
	"vehicle.lights.brakeLights.brakeLight(?)",
	"vehicle.lights.reverseLights.reverseLight(?)",
	"vehicle.lights.dayTimeLights.dayTimeLight(?)",
	"vehicle.lights.turnLights.turnLightLeft(?)",
	"vehicle.lights.turnLights.turnLightRight(?)",
	"vehicle.lights.staticLightCompounds.staticLightCompound(?).node(?)"
}

function Lights.prerequisitesPresent(self)
	return true
end
function Lights.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("beaconLight", g_i18n:getText("configuration_beacon"), "lights", VehicleConfigurationItem)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Lights")
	v1_:register(XMLValueType.FLOAT, "vehicle.lights#reverseLightActivationSpeed", "Speed which needs to be reached to activate reverse lights (km/h)", 1)
	v1_:register(XMLValueType.VECTOR_N, "vehicle.lights.states.state(?)#lightTypes", "Light states")
	v1_:register(XMLValueType.VECTOR_N, "vehicle.lights.states.automaticState#lightTypes", "Light states while ai is active", "0")
	v1_:register(XMLValueType.VECTOR_N, "vehicle.lights.states.automaticState#lightTypesWork", "Light states while ai is working", "0 1 2")
	SharedLight.registerXMLPaths(v1_, "vehicle.lights.sharedLight(?)")
	Lights.registerRealLightSetupXMLPath(v1_, "vehicle.lights.realLights.low")
	Lights.registerRealLightSetupXMLPath(v1_, "vehicle.lights.realLights.high")
	StaticLight.registerXMLPaths(v1_, "vehicle.lights.defaultLights.defaultLight(?)")
	StaticLight.registerXMLPaths(v1_, "vehicle.lights.topLights.topLight(?)")
	StaticLight.registerXMLPaths(v1_, "vehicle.lights.bottomLights.bottomLight(?)")
	StaticLight.registerXMLPaths(v1_, "vehicle.lights.brakeLights.brakeLight(?)")
	StaticLight.registerXMLPaths(v1_, "vehicle.lights.reverseLights.reverseLight(?)")
	StaticLight.registerXMLPaths(v1_, "vehicle.lights.dayTimeLights.dayTimeLight(?)")
	StaticLight.registerXMLPaths(v1_, "vehicle.lights.turnLights.turnLightLeft(?)")
	StaticLight.registerXMLPaths(v1_, "vehicle.lights.turnLights.turnLightRight(?)")
	StaticLightCompound.registerXMLPaths(v1_, "vehicle.lights.staticLightCompounds.staticLightCompound(?)")
	BeaconLight.registerVehicleXMLPaths(v1_, "vehicle.lights.beaconLights.beaconLight(?)")
	v1_:register(XMLValueType.BOOL, "vehicle.lights.beaconLights.beaconLight(?)#alwaysActive", "Defines if the beacon light is always active while the vehicle is entered", false)
	BeaconLight.registerVehicleXMLPaths(v1_, "vehicle.lights.beaconLightConfigurations.beaconLightConfiguration(?).beaconLight(?)")
	v1_:register(XMLValueType.BOOL, "vehicle.lights.beaconLightConfigurations.beaconLightConfiguration(?).beaconLight(?)#alwaysActive", "Defines if the beacon light is always active while the vehicle is entered", false)
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.lights.sounds", "toggleLights")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.lights.sounds", "turnLight")
	Dashboard.registerDashboardXMLPaths(v1_, "vehicle.lights.dashboards", {
		"lightState",
		"turnLightLeft",
		"turnLightRight",
		"turnLight",
		"turnLightHazard",
		"turnLightAny",
		"beaconLight"
	})
	Dashboard.addDelayedRegistrationFunc(v1_, function(p2_, p3_)
		p2_:register(XMLValueType.VECTOR_N, p3_ .. "#lightTypes", "Light types")
		p2_:register(XMLValueType.VECTOR_N, p3_ .. "#excludedLightTypes", "Excluded light types")
	end)
	for v4_ = 1, #Lights.ADDITIONAL_LIGHT_ATTRIBUTES_KEYS do
		local v5_ = Lights.ADDITIONAL_LIGHT_ATTRIBUTES_KEYS[v4_]
		v1_:register(XMLValueType.BOOL, v5_ .. "#isTopLight", "Light is only active when switched to top light mode", false)
		v1_:register(XMLValueType.BOOL, v5_ .. "#isBottomLight", "Light is only active when not switched to top light mode", false)
	end
	v1_:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#lightTypes", "Defined light types need to be enabled to activate group")
	v1_:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#excludedLightTypes", "Defined light types need to be disabled to activate group")
	v1_:setXMLSpecializationType()
end

function Lights.registerRealLightSetupXMLPath(schema, basePath)
	RealLight.registerXMLPaths(schema, basePath .. ".light(?)")
	RealLight.registerXMLPaths(schema, basePath .. ".topLight(?)")
	RealLight.registerXMLPaths(schema, basePath .. ".bottomLight(?)")
	RealLight.registerXMLPaths(schema, basePath .. ".brakeLight(?)")
	RealLight.registerXMLPaths(schema, basePath .. ".reverseLight(?)")
	RealLight.registerXMLPaths(schema, basePath .. ".dayTimeLight(?)")
	RealLight.registerXMLPaths(schema, basePath .. ".turnLightLeft(?)")
	RealLight.registerXMLPaths(schema, basePath .. ".turnLightRight(?)")
	RealLight.registerXMLPaths(schema, basePath .. ".interiorLight(?)")
end

function Lights.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onTurnLightStateChanged")
	SpecializationUtil.registerEvent(vehicleType, "onTopLightsVisibilityChanged")
	SpecializationUtil.registerEvent(vehicleType, "onBrakeLightsVisibilityChanged")
	SpecializationUtil.registerEvent(vehicleType, "onReverseLightsVisibilityChanged")
	SpecializationUtil.registerEvent(vehicleType, "onLightsTypesMaskChanged")
	SpecializationUtil.registerEvent(vehicleType, "onBeaconLightsVisibilityChanged")
end

function Lights.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadRealLightSetup", Lights.loadRealLightSetup)
	SpecializationUtil.registerFunction(vehicleType, "applyAdditionalActiveLightType", Lights.applyAdditionalActiveLightType)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForLights", Lights.getIsActiveForLights)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForInteriorLights", Lights.getIsActiveForInteriorLights)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleLight", Lights.getCanToggleLight)
	SpecializationUtil.registerFunction(vehicleType, "getUseHighProfile", Lights.getUseHighProfile)
	SpecializationUtil.registerFunction(vehicleType, "setNextLightsState", Lights.setNextLightsState)
	SpecializationUtil.registerFunction(vehicleType, "setLightsTypesMask", Lights.setLightsTypesMask)
	SpecializationUtil.registerFunction(vehicleType, "getLightsTypesMask", Lights.getLightsTypesMask)
	SpecializationUtil.registerFunction(vehicleType, "setTurnLightState", Lights.setTurnLightState)
	SpecializationUtil.registerFunction(vehicleType, "getTurnLightState", Lights.getTurnLightState)
	SpecializationUtil.registerFunction(vehicleType, "setTopLightsVisibility", Lights.setTopLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "setBrakeLightsVisibility", Lights.setBrakeLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "setBeaconLightsVisibility", Lights.setBeaconLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "getBeaconLightsVisibility", Lights.getBeaconLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "setReverseLightsVisibility", Lights.setReverseLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "setInteriorLightsVisibility", Lights.setInteriorLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "getInteriorLightBrightness", Lights.getInteriorLightBrightness)
	SpecializationUtil.registerFunction(vehicleType, "deactivateLights", Lights.deactivateLights)
	SpecializationUtil.registerFunction(vehicleType, "getDeactivateLightsOnLeave", Lights.getDeactivateLightsOnLeave)
	SpecializationUtil.registerFunction(vehicleType, "loadSharedLight", Lights.loadSharedLight)
	SpecializationUtil.registerFunction(vehicleType, "loadAdditionalLightAttributesFromXML", Lights.loadAdditionalLightAttributesFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsLightActive", Lights.getIsLightActive)
	SpecializationUtil.registerFunction(vehicleType, "getStaticLightFromNode", Lights.getStaticLightFromNode)
	SpecializationUtil.registerFunction(vehicleType, "getRealLightFromNode", Lights.getRealLightFromNode)
	SpecializationUtil.registerFunction(vehicleType, "updateAutomaticLights", Lights.updateAutomaticLights)
	SpecializationUtil.registerFunction(vehicleType, "lightsWeatherChanged", Lights.lightsWeatherChanged)
	SpecializationUtil.registerFunction(vehicleType, "onLightsProfileChanged", Lights.onLightsProfileChanged)
	SpecializationUtil.registerFunction(vehicleType, "onLightsRealBeaconLightChanged", Lights.onLightsRealBeaconLightChanged)
	SpecializationUtil.registerFunction(vehicleType, "deactivateBeaconLights", Lights.deactivateBeaconLights)
end

function Lights.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", Lights.loadDashboardGroupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", Lights.getIsDashboardGroupActive)
end

function Lights.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterExternalActionEvents", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onStartMotor", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onStopMotor", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onStartReverseDirectionChange", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAutomatedTrainTravelActive", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIDriveableActive", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIDriveableEnd", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerStart", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerActive", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIJobVehicleBlock", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIJobVehicleContinue", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerEnd", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onVehiclePhysicsUpdate", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onRequiresTopLightsChanged", Lights)
end

-- Local values: spec, registeredLightTypes, i, key, lightTypes, _, lightType, loadLightsMaskFromXML, xmlFile, lightTypes, lightsTypesMask, _, lightType, xmlFile, lightTypes, lightsTypesMask, _, lightType, _, compoundKey, staticLightCompound, _, lights, _, staticLight, _, profile, _, lights, _, realLight, configKey
function Lights:onLoad(savegame)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.low.light#decoration", "vehicle.lights.defaultLights#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.high.light#decoration", "vehicle.lights.defaultLights#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.low.light#realLight", "vehicle.lights.realLights.low.light#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.high.light#realLight", "vehicle.lights.realLights.high.light#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.brakeLights.brakeLight#realLight", "vehicle.lights.realLights.high.brakeLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.brakeLights.brakeLight#decoration", "vehicle.lights.brakeLights.brakeLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#realLight", "vehicle.lights.realLights.high.reverseLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#decoration", "vehicle.lights.reverseLights.reverseLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightLeft#realLight", "vehicle.lights.realLights.high.turnLightLeft#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightLeft#decoration", "vehicle.lights.turnLights.turnLightLeft#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightRight#realLight", "vehicle.lights.realLights.high.turnLightRight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightRight#decoration", "vehicle.lights.turnLights.turnLightRight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#realLight", "vehicle.lights.realLights.high.reverseLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#decoration", "vehicle.lights.reverseLights.reverseLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.states.aiState#lightTypes", "vehicle.lights.states.automaticState#lightTypes")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.states.aiState#lightTypesWork", "vehicle.lights.states.automaticState#lightTypesWork")
	local v_u_13_ = self.spec_lights
	v_u_13_.reverseLightActivationSpeed = self.xmlFile:getValue("vehicle.lights#reverseLightActivationSpeed", 1) / 3600
	v_u_13_.sharedLoadRequestIds = {}
	v_u_13_.xmlLoadingHandles = {}
	v_u_13_.lightsTypesMask = 0
	v_u_13_.currentLightState = 0
	v_u_13_.maxLightState = Lights.LIGHT_TYPE_HIGHBEAM
	v_u_13_.numLightTypes = 0
	v_u_13_.lightStates = {}
	v_u_13_.lastIsActiveForLights = false
	local v14_ = 0
	local v15_ = {}
	while true do
		local v16_ = string.format("vehicle.lights.states.state(%d)", v14_)
		if not self.xmlFile:hasProperty(v16_) then
			break
		end
		local v17_ = self.xmlFile:getValue(v16_ .. "#lightTypes", nil, true) or {}
		for _, v18_ in pairs(v17_) do
			if v15_[v18_] == nil then
				v15_[v18_] = v18_
				v_u_13_.numLightTypes = v_u_13_.numLightTypes + 1
				local v19_ = v_u_13_.maxLightState
				v_u_13_.maxLightState = math.max(v19_, v18_)
			end
		end
		local v20_ = v_u_13_.lightStates
		table.insert(v20_, v17_)
		v14_ = v14_ + 1
	end
	local v21_ = self.xmlFile:getValue("vehicle.lights.states.automaticState#lightTypes", "0", true)
	local v22_ = 0
	for _, v23_ in pairs(v21_) do
		local v24_ = 2 ^ v23_
		v22_ = bit32.bor(v22_, v24_)
	end
	v_u_13_.automaticLightsTypesMask = v22_
	local v25_ = self.xmlFile:getValue("vehicle.lights.states.automaticState#lightTypesWork", "0 1 2", true)
	local v26_ = 0
	for _, v27_ in pairs(v25_) do
		local v28_ = 2 ^ v27_
		v26_ = bit32.bor(v26_, v28_)
	end
	v_u_13_.automaticLightsTypesMaskWork = v26_
	v_u_13_.interiorLightsBrightness = 0
	v_u_13_.interiorLightsAvailable = false
	v_u_13_.realLights = {}
	v_u_13_.realLights.low = {}
	self:loadRealLightSetup(self.xmlFile, "vehicle.lights.realLights.low", v_u_13_.realLights.low)
	v_u_13_.realLights.high = {}
	self:loadRealLightSetup(self.xmlFile, "vehicle.lights.realLights.high", v_u_13_.realLights.high)
	v_u_13_.staticLights = {}
	v_u_13_.staticLights.defaultLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.defaultLights.defaultLight", self, self.components, self.i3dMappings, true)
	v_u_13_.staticLights.topLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.topLights.topLight", self, self.components, self.i3dMappings, false)
	v_u_13_.staticLights.bottomLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.bottomLights.bottomLight", self, self.components, self.i3dMappings, false)
	v_u_13_.staticLights.brakeLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.brakeLights.brakeLight", self, self.components, self.i3dMappings, false)
	v_u_13_.staticLights.reverseLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.reverseLights.reverseLight", self, self.components, self.i3dMappings, false)
	v_u_13_.staticLights.dayTimeLights = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.dayTimeLights.dayTimeLight", self, self.components, self.i3dMappings, false)
	v_u_13_.staticLights.turnLightsLeft = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.turnLights.turnLightLeft", self, self.components, self.i3dMappings, false)
	v_u_13_.staticLights.turnLightsRight = StaticLight.loadLightsFromXML(nil, self.xmlFile, "vehicle.lights.turnLights.turnLightRight", self, self.components, self.i3dMappings, false)
	v_u_13_.staticLightCompounds = {}
	for _, v29_ in self.xmlFile:iterator("vehicle.lights.staticLightCompounds.staticLightCompound") do
		local v30_ = StaticLightCompound.new(self)
		if v30_:loadFromXML(self.xmlFile, v29_, self.components, self.i3dMappings, self) then
			local v31_ = v_u_13_.staticLightCompounds
			table.insert(v31_, v30_)
		end
	end
	v_u_13_.sharedLights = {}
	self.xmlFile:iterate("vehicle.lights.sharedLight", function(_, p32_)
		-- upvalues: (copy) self
		self:loadSharedLight(self.xmlFile, p32_)
	end)
	for _, v33_ in pairs(v_u_13_.staticLights) do
		for _, v34_ in ipairs(v33_) do
			if v34_.lightTypes ~= nil then
				local v35_ = v_u_13_.maxLightState
				local v36_ = v34_.lightTypes
				local v37_ = unpack
				v_u_13_.maxLightState = math.max(v35_, v37_(v36_))
			end
		end
	end
	for _, v38_ in pairs(v_u_13_.realLights) do
		for _, v39_ in pairs(v38_) do
			for _, v40_ in ipairs(v39_) do
				if v40_.lightTypes ~= nil then
					local v41_ = v_u_13_.maxLightState
					local v42_ = v40_.lightTypes
					local v43_ = unpack
					v_u_13_.maxLightState = math.max(v41_, v43_(v42_))
				end
			end
		end
	end
	v_u_13_.maxLightStateMask = 2 ^ (v_u_13_.maxLightState + 1) - 1
	v_u_13_.additionalLightTypes = {}
	v_u_13_.additionalLightTypes.bottomLight = v_u_13_.maxLightState + 1
	v_u_13_.additionalLightTypes.topLight = v_u_13_.maxLightState + 2
	v_u_13_.additionalLightTypes.brakeLight = v_u_13_.maxLightState + 3
	v_u_13_.additionalLightTypes.turnLightLeft = v_u_13_.maxLightState + 4
	v_u_13_.additionalLightTypes.turnLightRight = v_u_13_.maxLightState + 5
	v_u_13_.additionalLightTypes.turnLightAny = v_u_13_.maxLightState + 6
	v_u_13_.additionalLightTypes.reverseLight = v_u_13_.maxLightState + 7
	v_u_13_.additionalLightTypes.interiorLight = v_u_13_.maxLightState + 8
	v_u_13_.totalNumLightTypes = v_u_13_.additionalLightTypes.interiorLight + 1
	if v_u_13_.totalNumLightTypes > 31 then
		Logging.xmlError(self.xmlFile, "Max. number of light types reached (31). Please reduce them.")
		v_u_13_.totalNumLightTypes = 31
	end
	v_u_13_.topLightsVisibility = false
	v_u_13_.brakeLightsVisibility = false
	v_u_13_.reverseLightsVisibility = false
	v_u_13_.turnLightState = Lights.TURNLIGHT_OFF
	v_u_13_.turnLightTriState = 0.5
	v_u_13_.turnLightRepetitionCount = nil
	v_u_13_.actionEventsActiveChange = {}
	v_u_13_.beaconLightsActive = false
	v_u_13_.beaconLights = {}
	v_u_13_.alwaysActiveBeaconLights = {}
	local v44_ = string.format("vehicle.lights.beaconLightConfigurations.beaconLightConfiguration(%d)", (self.configurations.beaconLight or 1) - 1)
	self.xmlFile:iterate(v44_ .. ".beaconLight", function(_, p45_)
		-- upvalues: (copy) self, (copy) v_u_13_
		if self.xmlFile:hasProperty(p45_ .. "#alwaysActive") then
			BeaconLight.loadFromVehicleXML(v_u_13_.alwaysActiveBeaconLights, self.xmlFile, p45_, self)
		else
			BeaconLight.loadFromVehicleXML(v_u_13_.beaconLights, self.xmlFile, p45_, self)
		end
	end)
	self.xmlFile:iterate("vehicle.lights.beaconLights.beaconLight", function(_, p46_)
		-- upvalues: (copy) self, (copy) v_u_13_
		if self.xmlFile:hasProperty(p46_ .. "#alwaysActive") then
			BeaconLight.loadFromVehicleXML(v_u_13_.alwaysActiveBeaconLights, self.xmlFile, p46_, self)
		else
			BeaconLight.loadFromVehicleXML(v_u_13_.beaconLights, self.xmlFile, p46_, self)
		end
	end)
	if self.isClient ~= nil then
		v_u_13_.samples = {}
		v_u_13_.samples.toggleLights = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.lights.sounds", "toggleLights", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_13_.samples.turnLight = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.lights.sounds", "turnLight", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		g_messageCenter:subscribe(MessageType.DAY_NIGHT_CHANGED, self.lightsWeatherChanged, self)
	end
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.LIGHTS_PROFILE], self.onLightsProfileChanged, self)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.REAL_BEACON_LIGHTS], self.onLightsRealBeaconLightChanged, self)
end

-- Local values: spec, _, profile, _, lights, _, realLight, _, staticLight
function Lights:onLoadFinished(savegame)
	local v48_ = self.spec_lights
	self:applyAdditionalActiveLightType(v48_.staticLights.topLights, v48_.additionalLightTypes.topLight)
	self:applyAdditionalActiveLightType(v48_.staticLights.bottomLights, v48_.additionalLightTypes.bottomLight)
	self:applyAdditionalActiveLightType(v48_.staticLights.brakeLights, v48_.additionalLightTypes.brakeLight)
	self:applyAdditionalActiveLightType(v48_.staticLights.reverseLights, v48_.additionalLightTypes.reverseLight)
	self:applyAdditionalActiveLightType(v48_.staticLights.turnLightsLeft, v48_.additionalLightTypes.turnLightLeft, true)
	self:applyAdditionalActiveLightType(v48_.staticLights.turnLightsLeft, v48_.additionalLightTypes.turnLightAny, true)
	self:applyAdditionalActiveLightType(v48_.staticLights.turnLightsRight, v48_.additionalLightTypes.turnLightRight, true)
	self:applyAdditionalActiveLightType(v48_.staticLights.turnLightsRight, v48_.additionalLightTypes.turnLightAny, true)
	for _, v49_ in pairs(v48_.realLights) do
		self:applyAdditionalActiveLightType(v49_.topLights, v48_.additionalLightTypes.topLight)
		self:applyAdditionalActiveLightType(v49_.bottomLights, v48_.additionalLightTypes.bottomLight)
		self:applyAdditionalActiveLightType(v49_.brakeLights, v48_.additionalLightTypes.brakeLight)
		self:applyAdditionalActiveLightType(v49_.reverseLights, v48_.additionalLightTypes.reverseLight)
		self:applyAdditionalActiveLightType(v49_.turnLightsLeft, v48_.additionalLightTypes.turnLightLeft, true)
		self:applyAdditionalActiveLightType(v49_.turnLightsLeft, v48_.additionalLightTypes.turnLightAny, true)
		self:applyAdditionalActiveLightType(v49_.turnLightsRight, v48_.additionalLightTypes.turnLightRight, true)
		self:applyAdditionalActiveLightType(v49_.turnLightsRight, v48_.additionalLightTypes.turnLightAny, true)
		self:applyAdditionalActiveLightType(v49_.interiorLights, v48_.additionalLightTypes.interiorLight)
		for _, v50_ in pairs(v49_) do
			for _, v51_ in ipairs(v50_) do
				v51_:finalize()
			end
		end
	end
	if self:getIsInShowroom() then
		for _, v52_ in ipairs(v48_.staticLights.dayTimeLights) do
			v52_:setState(true)
		end
	end
end

-- Local values: spec, lightState, turnLightLeft, turnLightRight, turnLight, turnLightHazard, turnLightAny, beaconLight
function Lights:onRegisterDashboardValueTypes()
	local v_u_54_ = self.spec_lights
	local v55_ = DashboardValueType.new("lights", "lightState")
	v55_:setValue(v_u_54_, function(_, p56_)
		-- upvalues: (copy) v_u_54_, (copy) self
		if p56_.displayTypeIndex == Dashboard.TYPES.MULTI_STATE then
			return v_u_54_.lightsTypesMask
		end
		local v57_ = false
		if p56_.lightTypes ~= nil then
			for _, v58_ in pairs(p56_.lightTypes) do
				local v59_ = v_u_54_.lightsTypesMask
				local v60_ = 2 ^ v58_
				if bit32.band(v59_, v60_) ~= 0 or v58_ == -1 and self:getIsActiveForLights(true) then
					v57_ = true
					break
				end
			end
		end
		if v57_ and p56_.excludedLightTypes ~= nil then
			for _, v61_ in pairs(p56_.excludedLightTypes) do
				local v62_ = v_u_54_.lightsTypesMask
				local v63_ = 2 ^ v61_
				if bit32.band(v62_, v63_) ~= 0 then
					v57_ = false
					break
				end
			end
		end
		return v57_ and 1 or 0
	end)
	v55_:setAdditionalFunctions(Lights.dashboardLightAttributes, Lights.dashboardLightState)
	v55_:setPollUpdate(false)
	self:registerDashboardValueType(v55_)
	local v64_ = DashboardValueType.new("lights", "turnLightLeft")
	v64_:setValue(v_u_54_, "turnLightState")
	v64_:setValueCompare(Lights.TURNLIGHT_LEFT, Lights.TURNLIGHT_HAZARD)
	v64_:setPollUpdate(false)
	self:registerDashboardValueType(v64_)
	local v65_ = DashboardValueType.new("lights", "turnLightRight")
	v65_:setValue(v_u_54_, "turnLightState")
	v65_:setValueCompare(Lights.TURNLIGHT_RIGHT, Lights.TURNLIGHT_HAZARD)
	v65_:setPollUpdate(false)
	self:registerDashboardValueType(v65_)
	local v66_ = DashboardValueType.new("lights", "turnLight")
	v66_:setValue(v_u_54_, "turnLightTriState")
	v66_:setIdleValue(0.5)
	v66_:setPollUpdate(false)
	self:registerDashboardValueType(v66_)
	local v67_ = DashboardValueType.new("lights", "turnLightHazard")
	v67_:setValue(v_u_54_, "turnLightState")
	v67_:setValueCompare(Lights.TURNLIGHT_HAZARD)
	v67_:setPollUpdate(false)
	self:registerDashboardValueType(v67_)
	local v68_ = DashboardValueType.new("lights", "turnLightAny")
	v68_:setValue(v_u_54_, "turnLightState")
	v68_:setValueCompare(Lights.TURNLIGHT_LEFT, Lights.TURNLIGHT_RIGHT, Lights.TURNLIGHT_HAZARD)
	v68_:setPollUpdate(false)
	self:registerDashboardValueType(v68_)
	local v69_ = DashboardValueType.new("lights", "beaconLight")
	v69_:setValue(v_u_54_, function(p70_)
		return p70_.beaconLightsActive and 1 or 0
	end)
	v69_:setPollUpdate(false)
	self:registerDashboardValueType(v69_)
end

-- Local values: spec, _, sharedLight, _, beaconLight, _, beaconLight, lightXMLFile, _, _, sharedLoadRequestId
function Lights:onDelete()
	local v72_ = self.spec_lights
	if v72_.sharedLights ~= nil then
		for _, v73_ in ipairs(v72_.sharedLights) do
			v73_:delete()
		end
		v72_.sharedLights = {}
	end
	if v72_.beaconLights ~= nil then
		for _, v74_ in ipairs(v72_.beaconLights) do
			v74_:delete()
		end
		v72_.beaconLights = {}
	end
	if v72_.alwaysActiveBeaconLights ~= nil then
		for _, v75_ in ipairs(v72_.alwaysActiveBeaconLights) do
			v75_:delete()
		end
		v72_.alwaysActiveBeaconLights = {}
	end
	if v72_.xmlLoadingHandles ~= nil then
		for v76_, _ in pairs(v72_.xmlLoadingHandles) do
			v76_:delete()
			v72_.xmlLoadingHandles[v76_] = nil
		end
	end
	if v72_.sharedLoadRequestIds ~= nil then
		for _, v77_ in ipairs(v72_.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(v77_)
		end
	end
	if v72_.staticLightCompounds ~= nil then
		v72_.staticLightCompounds = {}
	end
	g_soundManager:deleteSamples(v72_.samples)
end

-- Local values: spec, lightsTypesMask, beaconLightsActive
function Lights:onReadStream(streamId, connection)
	local v80_ = self.spec_lights
	self:setLightsTypesMask(streamReadUIntN(streamId, v80_.totalNumLightTypes), true, true)
	self:setBeaconLightsVisibility(streamReadBool(streamId), true, true)
end

-- Local values: spec
function Lights:onWriteStream(streamId, connection)
	local v83_ = self.spec_lights
	streamWriteUIntN(streamId, v83_.lightsTypesMask, v83_.totalNumLightTypes)
	streamWriteBool(streamId, v83_.beaconLightsActive)
end

-- Local values: spec, shaderTime, _, fracTime, alpha, _, light, _, light, turnLightRepetitionCount
function Lights:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local v86_ = self.spec_lights
		if v86_.turnLightState ~= Lights.TURNLIGHT_OFF then
			local v87_ = getShaderTimeSec()
			local _, v88_ = math.modf(v87_)
			local v89_ = v88_ - 0.5
			local v90_ = 4 * math.abs(v89_) - 0.8
			local v91_ = math.clamp(v90_, 0, 1)
			if v86_.turnLightState == Lights.TURNLIGHT_LEFT or v86_.turnLightState == Lights.TURNLIGHT_HAZARD then
				for _, v92_ in pairs(v86_.activeTurnLightSetup.turnLightsLeft) do
					v92_:setCharge(v91_)
				end
			end
			if v86_.turnLightState == Lights.TURNLIGHT_RIGHT or v86_.turnLightState == Lights.TURNLIGHT_HAZARD then
				for _, v93_ in pairs(v86_.activeTurnLightSetup.turnLightsRight) do
					v93_:setCharge(v91_)
				end
			end
			if v86_.samples.turnLight ~= nil and isActiveForInputIgnoreSelection then
				local v94_ = v87_ - 0.8
				local v95_ = math.floor(v94_)
				if v86_.turnLightRepetitionCount ~= nil and v95_ ~= v86_.turnLightRepetitionCount then
					g_soundManager:playSample(v86_.samples.turnLight)
				end
				v86_.turnLightRepetitionCount = v95_
			end
			self:raiseActive()
		end
	end
end

-- Local values: spec, isActiveForLights, _, beaconLight, _, v
function Lights:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local v97_ = self.spec_lights
		local v98_ = self:getIsActiveForLights()
		if v98_ ~= v97_.lastIsActiveForLights then
			for _, v99_ in ipairs(v97_.alwaysActiveBeaconLights) do
				v99_:setIsActive(v98_)
			end
			v97_.lastIsActiveForLights = v98_
		end
		if v97_.interiorLightsAvailable then
			self:setInteriorLightsVisibility(self:getIsActiveForInteriorLights())
		end
		for _, v100_ in ipairs(v97_.actionEventsActiveChange) do
			g_inputBinding:setActionEventActive(v100_, v98_)
		end
		g_inputBinding:setActionEventActive(v97_.actionEventIdLight, v98_)
		if Platform.gameplay.automaticLights and (self == self.rootVehicle and not self:getIsAIActive()) then
			self:updateAutomaticLights(not g_currentMission.environment.isSunOn and v98_, self.rootVehicle:getActionControllerDirection() == -1)
		end
	end
end

function Lights:getIsActiveForLights(onlyPowered)
	if onlyPowered == true and not self:getIsPowered() then
		return false
	elseif self.getIsEntered == nil or not (self:getIsEntered() and self:getCanToggleLight()) then
		if self.attacherVehicle == nil then
			return false
		else
			return self.attacherVehicle:getIsActiveForLights()
		end
	else
		return true
	end
end

function Lights.getIsActiveForInteriorLights(self)
	return false
end

-- Local values: spec
function Lights:getCanToggleLight()
	local v104_ = self.spec_lights
	if self:getIsAIActive() then
		return false
	elseif v104_.numLightTypes == 0 then
		return false
	else
		return g_localPlayer:getCurrentVehicle() == self
	end
end

-- Local values: lightsProfile
function Lights:getUseHighProfile()
	local v105_ = g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)
	return Utils.getNoNil(Platform.gameplay.lightsProfile, v105_) >= GS_PROFILE_HIGH
end

-- Local values: spec, oldLightsTypesMask, currentLightState, lightsTypesMask, _, lightType
function Lights:setNextLightsState(increment)
	local v108_ = self.spec_lights
	if v108_.lightStates ~= nil and #v108_.lightStates > 0 then
		local v109_ = v108_.lightsTypesMask
		local v110_ = v108_.maxLightStateMask
		local v111_ = bit32.band(v109_, v110_)
		local v112_ = v108_.currentLightState + increment
		local v113_ = (#v108_.lightStates < v112_ or v108_.currentLightState == 0 and v111_ > 0) and 0 or (v112_ < 0 and #v108_.lightStates or v112_)
		local v114_ = v108_.lightsTypesMask
		local v115_ = v108_.maxLightStateMask
		local v116_ = bit32.bnot(v115_)
		local v117_ = bit32.band(v114_, v116_)
		if v113_ > 0 then
			for _, v118_ in pairs(v108_.lightStates[v113_]) do
				local v119_ = 2 ^ v118_
				v117_ = bit32.bor(v117_, v119_)
			end
		end
		v108_.currentLightState = v113_
		self:setLightsTypesMask(v117_)
	end
end

-- Local values: spec, activeLightSetup, _, lights, _, staticLight, _, profile, _, lights, _, realLight, _, staticLightCompound
function Lights:setLightsTypesMask(lightsTypesMask, force, noEventSend)
	local v124_ = self.spec_lights
	local v125_
	if self.isServer then
		local v126_ = v124_.maxLightStateMask
		v125_ = bit32.band(lightsTypesMask, v126_)
		if v124_.turnLightState == Lights.TURNLIGHT_LEFT then
			local v127_ = 2 ^ v124_.additionalLightTypes.turnLightLeft
			v125_ = bit32.bor(v125_, v127_)
		end
		if v124_.turnLightState == Lights.TURNLIGHT_RIGHT then
			local v128_ = 2 ^ v124_.additionalLightTypes.turnLightRight
			v125_ = bit32.bor(v125_, v128_)
		end
		if v124_.turnLightState == Lights.TURNLIGHT_HAZARD then
			local v129_ = 2 ^ v124_.additionalLightTypes.turnLightAny
			v125_ = bit32.bor(v125_, v129_)
		end
		local v130_ = 2 ^ Lights.LIGHT_TYPE_DEFAULT
		if bit32.band(v125_, v130_) ~= 0 then
			if v124_.topLightsVisibility then
				local v131_ = 2 ^ v124_.additionalLightTypes.topLight
				v125_ = bit32.bor(v125_, v131_)
			else
				local v132_ = 2 ^ v124_.additionalLightTypes.bottomLight
				v125_ = bit32.bor(v125_, v132_)
			end
		end
		if v124_.brakeLightsVisibility then
			local v133_ = 2 ^ v124_.additionalLightTypes.brakeLight
			v125_ = bit32.bor(v125_, v133_)
		end
		if v124_.reverseLightsVisibility then
			local v134_ = 2 ^ v124_.additionalLightTypes.reverseLight
			v125_ = bit32.bor(v125_, v134_)
		end
		if v124_.interiorLightsVisibility then
			local v135_ = 2 ^ v124_.additionalLightTypes.interiorLight
			v125_ = bit32.bor(v125_, v135_)
		end
	else
		local v136_ = 2 ^ v124_.additionalLightTypes.topLight
		local v137_ = bit32.bnot(v136_)
		local v138_ = bit32.band(lightsTypesMask, v137_)
		local v139_ = 2 ^ v124_.additionalLightTypes.bottomLight
		local v140_ = bit32.bnot(v139_)
		local v141_ = bit32.band(v138_, v140_)
		local v142_ = 2 ^ Lights.LIGHT_TYPE_DEFAULT
		if bit32.band(v141_, v142_) ~= 0 then
			if v124_.topLightsVisibility then
				local v143_ = 2 ^ v124_.additionalLightTypes.topLight
				v141_ = bit32.bor(v141_, v143_)
			else
				local v144_ = 2 ^ v124_.additionalLightTypes.bottomLight
				v141_ = bit32.bor(v141_, v144_)
			end
		end
		local v145_ = 2 ^ v124_.additionalLightTypes.interiorLight
		local v146_ = bit32.bnot(v145_)
		v125_ = bit32.band(v141_, v146_)
		if v124_.interiorLightsVisibility then
			local v147_ = 2 ^ v124_.additionalLightTypes.interiorLight
			v125_ = bit32.bor(v125_, v147_)
		end
	end
	if v125_ ~= v124_.lightsTypesMask or force then
		if noEventSend == nil or noEventSend == false then
			if g_server == nil then
				g_client:getServerConnection():sendEvent(VehicleSetLightEvent.new(self, v125_, v124_.totalNumLightTypes))
			else
				g_server:broadcastEvent(VehicleSetLightEvent.new(self, v125_, v124_.totalNumLightTypes), nil, nil, self)
			end
		end
		local v148_ = v124_.maxLightStateMask
		local v149_ = bit32.band(v125_, v148_)
		local v150_ = v124_.lightsTypesMask
		local v151_ = v124_.maxLightStateMask
		if v149_ ~= bit32.band(v150_, v151_) and self.isClient then
			g_soundManager:playSample(v124_.samples.toggleLights)
		end
		local v152_ = v124_.realLights.low
		if self:getUseHighProfile() then
			v152_ = v124_.realLights.high
		end
		for _, v153_ in pairs(v124_.staticLights) do
			for _, v154_ in ipairs(v153_) do
				v154_:setLightTypesMask(v125_)
			end
		end
		for _, v155_ in pairs(v124_.realLights) do
			for _, v156_ in pairs(v155_) do
				for _, v157_ in ipairs(v156_) do
					v157_:setLightTypesMask(v155_ == v152_ and v125_ and v125_ or 0)
				end
			end
		end
		for _, v158_ in pairs(v124_.staticLightCompounds) do
			v158_:setLightTypesMask(v125_, self)
		end
		v124_.lightsTypesMask = v125_
		if self.isClient and self.updateDashboardValueType ~= nil then
			self:updateDashboardValueType("lights.lightState")
			self:updateDashboardValueType("lights.turnLightLeft")
			self:updateDashboardValueType("lights.turnLightRight")
			self:updateDashboardValueType("lights.turnLight")
			self:updateDashboardValueType("lights.turnLightHazard")
			self:updateDashboardValueType("lights.turnLightAny")
		end
		SpecializationUtil.raiseEvent(self, "onLightsTypesMaskChanged", v125_)
	end
	return true
end

function Lights:getLightsTypesMask()
	return self.spec_lights.lightsTypesMask
end

-- Local values: spec, isActiveForInput, _, beaconLight
function Lights:setBeaconLightsVisibility(visibility, force, noEventSend)
	local v164_ = self.spec_lights
	if visibility ~= v164_.beaconLightsActive or force then
		if noEventSend == nil or noEventSend == false then
			if g_server == nil then
				g_client:getServerConnection():sendEvent(VehicleSetBeaconLightEvent.new(self, visibility))
			else
				g_server:broadcastEvent(VehicleSetBeaconLightEvent.new(self, visibility), nil, nil, self)
			end
		end
		local v165_ = self:getIsActiveForInput(true)
		v164_.beaconLightsActive = visibility
		for _, v166_ in pairs(v164_.beaconLights) do
			v166_:setIsActive(visibility)
			if v165_ then
				v166_:setDeviceIsActive(visibility)
			end
		end
		if self.isClient and self.updateDashboardValueType ~= nil then
			self:updateDashboardValueType("lights.beaconLight")
		end
		SpecializationUtil.raiseEvent(self, "onBeaconLightsVisibilityChanged", visibility)
	end
	return true
end

function Lights:getBeaconLightsVisibility()
	return self.spec_lights.beaconLightsActive
end

-- Local values: spec, activeLightSetup
function Lights:setTurnLightState(state, force, noEventSend)
	local v172_ = self.spec_lights
	if state ~= v172_.turnLightState or force then
		if noEventSend == nil or noEventSend == false then
			if g_server == nil then
				g_client:getServerConnection():sendEvent(VehicleSetTurnLightEvent.new(self, state))
			else
				g_server:broadcastEvent(VehicleSetTurnLightEvent.new(self, state), nil, nil, self)
			end
		end
		local v173_ = v172_.realLights.low
		if self:getUseHighProfile() then
			v173_ = v172_.realLights.high
		end
		v172_.activeTurnLightSetup = v173_
		v172_.turnLightState = state
		v172_.turnLightTriState = v172_.turnLightState == Lights.TURNLIGHT_LEFT and 0 or (v172_.turnLightState == Lights.TURNLIGHT_RIGHT and 1 or 0.5)
		v172_.turnLightRepetitionCount = nil
		if self.isServer then
			self:setLightsTypesMask(v172_.lightsTypesMask, nil)
		end
		SpecializationUtil.raiseEvent(self, "onTurnLightStateChanged", state)
	end
	return true
end

function Lights:getTurnLightState()
	return self.spec_lights.turnLightState
end

-- Local values: spec
function Lights:setTopLightsVisibility(visibility)
	local v177_ = self.spec_lights
	if visibility ~= v177_.topLightsVisibility then
		v177_.topLightsVisibility = visibility
		self:setLightsTypesMask(v177_.lightsTypesMask, nil, true)
		SpecializationUtil.raiseEvent(self, "onTopLightsVisibilityChanged", visibility)
	end
	return true
end

-- Local values: spec
function Lights:setBrakeLightsVisibility(visibility)
	local v180_ = self.spec_lights
	if visibility ~= v180_.brakeLightsVisibility then
		v180_.brakeLightsVisibility = visibility
		self:setLightsTypesMask(v180_.lightsTypesMask)
		SpecializationUtil.raiseEvent(self, "onBrakeLightsVisibilityChanged", visibility)
	end
	return true
end

-- Local values: spec
function Lights:setReverseLightsVisibility(visibility)
	local v183_ = self.spec_lights
	if visibility ~= v183_.reverseLightsVisibility then
		v183_.reverseLightsVisibility = visibility
		self:setLightsTypesMask(v183_.lightsTypesMask)
		SpecializationUtil.raiseEvent(self, "onReverseLightsVisibilityChanged", visibility)
	end
	return true
end

-- Local values: spec, brightness, hasChanged
function Lights:setInteriorLightsVisibility(visibility)
	local v186_ = self.spec_lights
	local v187_, v188_ = self:getInteriorLightBrightness(true)
	if v187_ == 0 then
		visibility = false
	end
	if visibility ~= v186_.interiorLightsVisibility or v188_ then
		v186_.interiorLightsVisibility = visibility
		self:setLightsTypesMask(v186_.lightsTypesMask, true, true)
	end
	return true
end

-- Local values: spec, changed, brightness, hour, oldBrightness
function Lights:getInteriorLightBrightness(updateState)
	local v191_ = self.spec_lights
	local v192_
	if updateState then
		local v193_ = g_currentMission.environment.currentHour + g_currentMission.environment.currentMinute / 60
		local v194_ = v193_ >= 10 and 0 or 1 - (v193_ - 8) / 2
		if v193_ > 16 then
			v194_ = (v193_ - 16) / 2
		end
		local v195_ = v191_.interiorLightsBrightness
		v191_.interiorLightsBrightness = math.clamp(v194_, 0, 1)
		v192_ = v191_.interiorLightsBrightness ~= v195_
	else
		v192_ = false
	end
	return v191_.interiorLightsBrightness, v192_
end

-- Local values: spec
function Lights:deactivateLights(keepHazardLightsOn)
	local v198_ = self.spec_lights
	self:setLightsTypesMask(0, true, true)
	self:setBeaconLightsVisibility(false, true, true)
	if not keepHazardLightsOn or v198_.turnLightState ~= Lights.TURNLIGHT_HAZARD then
		self:setTurnLightState(Lights.TURNLIGHT_OFF, true, true)
	end
	self:setBrakeLightsVisibility(false)
	self:setReverseLightsVisibility(false)
	self:setInteriorLightsVisibility(false)
	v198_.currentLightState = 0
end

-- Local values: spec, _, beaconLight
function Lights:deactivateBeaconLights()
	local v200_ = self.spec_lights
	for _, v201_ in pairs(v200_.beaconLights) do
		v201_:setIsActive(false)
		v201_:setDeviceIsActive(false)
	end
end

function Lights:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
		return false
	end
	group.lightTypes = xmlFile:getValue(key .. "#lightTypes", nil, true)
	group.excludedLightTypes = xmlFile:getValue(key .. "#excludedLightTypes", nil, true)
	return true
end

-- Local values: spec, lightIsActive, _, lightType, _, excludedLightType
function Lights:getIsDashboardGroupActive(superFunc, group)
	if group.lightTypes ~= nil or group.excludedLightTypes ~= nil then
		local v210_ = self.spec_lights
		if group.lightTypes ~= nil then
			local v211_ = false
			for _, v212_ in pairs(group.lightTypes) do
				local v213_ = v210_.lightsTypesMask
				local v214_ = 2 ^ v212_
				if bit32.band(v213_, v214_) ~= 0 then
					v211_ = true
					break
				end
			end
			if not v211_ then
				return false
			end
		end
		if group.excludedLightTypes ~= nil then
			for _, v215_ in pairs(group.excludedLightTypes) do
				local v216_ = v210_.lightsTypesMask
				local v217_ = 2 ^ v215_
				if bit32.band(v216_, v217_) ~= 0 then
					return false
				end
			end
		end
	end
	return superFunc(self, group)
end

function Lights:getDeactivateLightsOnLeave()
	return true
end

-- Local values: spec, sharedLight
function Lights:loadSharedLight(xmlFile, key)
	local v_u_220_ = self.spec_lights
	local v_u_221_ = SharedLight.new(self, v_u_220_.staticLights)
	v_u_221_:loadFromVehicleXML(key, self.baseDirectory, function(p222_)
		-- upvalues: (copy) v_u_220_, (copy) v_u_221_
		if p222_ then
			local v223_ = v_u_220_.sharedLights
			local v224_ = v_u_221_
			table.insert(v223_, v224_)
			if v_u_221_.staticLightCompound ~= nil then
				local v225_ = v_u_220_.staticLightCompounds
				local v226_ = v_u_221_.staticLightCompound
				table.insert(v225_, v226_)
			end
		end
	end)
end

function Lights:loadAdditionalLightAttributesFromXML(xmlFile, key, light)
	light.isTopLight = xmlFile:getValue(key .. "#isTopLight", false)
	light.isBottomLight = xmlFile:getValue(key .. "#isBottomLight", false)
	return true
end

function Lights:getIsLightActive(light)
	if light.isTopLight then
		if not self.spec_lights.topLightsVisibility then
			return false
		end
	elseif light.isBottomLight and self.spec_lights.topLightsVisibility then
		return false
	end
	return true
end

-- Local values: spec, _, lights, _, staticLight
function Lights:getStaticLightFromNode(node)
	local v234_ = self.spec_lights
	for _, v235_ in pairs(v234_.staticLights) do
		for _, v236_ in ipairs(v235_) do
			if v236_.node == node then
				return v236_
			end
		end
	end
end

-- Local values: spec, _, profile, _, lights, _, realLight
function Lights:getRealLightFromNode(node)
	local v239_ = self.spec_lights
	for _, v240_ in pairs(v239_.realLights) do
		for _, v241_ in pairs(v240_) do
			for _, v242_ in ipairs(v241_) do
				if v242_.node == node then
					return v242_
				end
			end
		end
	end
end

-- Local values: spec, lightsTypesMask
function Lights:updateAutomaticLights(isTurnedOn, isWorking)
	local v246_ = self.spec_lights
	if isTurnedOn then
		local v247_ = isWorking and v246_.automaticLightsTypesMaskWork or v246_.automaticLightsTypesMask
		if v246_.lightsTypesMask ~= v247_ then
			self:setLightsTypesMask(v247_)
			return
		end
	elseif v246_.lightsTypesMask ~= 0 then
		self:setLightsTypesMask(0)
	end
end

-- Local values: spec
function Lights:lightsWeatherChanged()
	local v249_ = self.spec_lights
	g_inputBinding:setActionEventTextVisibility(v249_.actionEventIdLight, not g_currentMission.environment.isSunOn)
end

-- Local values: spec, _, profile, _, lights, _, realLight
function Lights:onLightsProfileChanged(lightsProfile)
	local v252_ = self.spec_lights
	for _, v253_ in pairs(v252_.realLights) do
		for _, v254_ in pairs(v253_) do
			for _, v255_ in ipairs(v254_) do
				v255_:onLightsProfileChanged(lightsProfile)
			end
		end
	end
	self:setLightsTypesMask(v252_.lightsTypesMask, true, true)
end

-- Local values: spec, _, beaconLight
function Lights:onLightsRealBeaconLightChanged()
	local v257_ = self.spec_lights
	for _, v258_ in pairs(v257_.beaconLights) do
		v258_:onLightsRealBeaconLightChanged()
	end
end

-- Local values: spec, _, _, actionEventIdReverse, _, actionEventIdFront, _, actionEventIdWorkBack, _, actionEventIdWorkFront, _, actionEventIdHighBeam, _, actionEventIdBeacon, _, actionEvent
function Lights:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient and (self.getIsEntered ~= nil and self:getIsEntered()) then
		local v261_ = self.spec_lights
		self:clearActionEventsTable(v261_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v262_ = self:addActionEvent(v261_.actionEvents, InputAction.TOGGLE_LIGHTS, self, Lights.actionEventToggleLights, false, true, false, true, nil)
			v261_.actionEventIdLight = v262_
			local _, v263_ = self:addActionEvent(v261_.actionEvents, InputAction.TOGGLE_LIGHTS_BACK, self, Lights.actionEventToggleLightsBack, false, true, false, true, nil)
			local _, v264_ = self:addActionEvent(v261_.actionEvents, InputAction.TOGGLE_LIGHT_FRONT, self, Lights.actionEventToggleLightFront, false, true, false, true, nil)
			local _, v265_ = self:addActionEvent(v261_.actionEvents, InputAction.TOGGLE_WORK_LIGHT_BACK, self, Lights.actionEventToggleWorkLightBack, false, true, false, true, nil)
			local _, v266_ = self:addActionEvent(v261_.actionEvents, InputAction.TOGGLE_WORK_LIGHT_FRONT, self, Lights.actionEventToggleWorkLightFront, false, true, false, true, nil)
			local _, v267_ = self:addActionEvent(v261_.actionEvents, InputAction.TOGGLE_HIGH_BEAM_LIGHT, self, Lights.actionEventToggleHighBeamLight, false, true, false, true, nil)
			self:addActionEvent(v261_.actionEvents, InputAction.TOGGLE_TURNLIGHT_HAZARD, self, Lights.actionEventToggleTurnLightHazard, false, true, false, true, nil)
			self:addActionEvent(v261_.actionEvents, InputAction.TOGGLE_TURNLIGHT_LEFT, self, Lights.actionEventToggleTurnLightLeft, false, true, false, true, nil)
			self:addActionEvent(v261_.actionEvents, InputAction.TOGGLE_TURNLIGHT_RIGHT, self, Lights.actionEventToggleTurnLightRight, false, true, false, true, nil)
			local _, v268_ = self:addActionEvent(v261_.actionEvents, InputAction.TOGGLE_BEACON_LIGHTS, self, Lights.actionEventToggleBeaconLights, false, true, false, true, nil)
			v261_.actionEventsActiveChange = {
				v264_,
				v265_,
				v266_,
				v267_,
				v268_
			}
			for _, v269_ in pairs(v261_.actionEvents) do
				if v269_.actionEventId ~= nil then
					g_inputBinding:setActionEventTextVisibility(v269_.actionEventId, false)
					g_inputBinding:setActionEventTextPriority(v269_.actionEventId, GS_PRIO_LOW)
				end
			end
			g_inputBinding:setActionEventTextVisibility(v261_.actionEventIdLight, not g_currentMission.environment.isSunOn)
			g_inputBinding:setActionEventTextVisibility(v263_, false)
		end
	end
end

-- Local values: spec
function Lights:onRegisterExternalActionEvents(trigger, name, xmlFile, key)
	if name == "lights" and #self.spec_lights.lightStates > 0 then
		self:registerExternalActionEvent(trigger, name, Lights.externalActionEventRegister, Lights.externalActionEventUpdate)
	end
end

-- Local values: spec
function Lights:onEnterVehicle(isControlling)
	local v274_ = self.spec_lights
	self:setLightsTypesMask(v274_.lightsTypesMask, true, true)
	self:setBeaconLightsVisibility(v274_.beaconLightsActive, true, true)
	self:setTurnLightState(v274_.turnLightState, true, true)
end

-- Local values: spec, _, beaconLight
function Lights:onLeaveVehicle()
	if self:getDeactivateLightsOnLeave() then
		self:deactivateLights(true)
		self:deactivateBeaconLights()
	end
	local v276_ = self.spec_lights
	for _, v277_ in pairs(v276_.beaconLights) do
		v277_:setDeviceIsActive(false)
	end
end

function Lights:onDeactivate()
	if self:getDeactivateLightsOnLeave() then
		self:deactivateBeaconLights()
	end
end

function Lights:onRequiresTopLightsChanged(requiresTopLights)
	self:setTopLightsVisibility(requiresTopLights)
end

-- Local values: spec, _, staticLight
function Lights:onStartMotor()
	local v282_ = self.spec_lights
	self:setLightsTypesMask(v282_.lightsTypesMask, true, true)
	for _, v283_ in ipairs(v282_.staticLights.dayTimeLights) do
		v283_:setState(true)
	end
end

-- Local values: spec, _, staticLight
function Lights:onStopMotor()
	local v285_ = self.spec_lights
	self:setLightsTypesMask(v285_.lightsTypesMask, true, true)
	for _, v286_ in ipairs(v285_.staticLights.dayTimeLights) do
		v286_:setState((self:getIsInShowroom()))
	end
end

-- Local values: spec
function Lights:onStartReverseDirectionChange()
	local v288_ = self.spec_lights
	if v288_.lightsTypesMask > 0 then
		self:setLightsTypesMask(v288_.lightsTypesMask, true, true)
	end
end

function Lights:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	if attacherVehicle.getLightsTypesMask ~= nil then
		self:setLightsTypesMask(attacherVehicle:getLightsTypesMask(), true, true)
		self:setBeaconLightsVisibility(attacherVehicle:getBeaconLightsVisibility(), true, true)
		self:setTurnLightState(attacherVehicle:getTurnLightState(), true, true)
	end
end

function Lights:onPostDetach()
	self:deactivateLights()
end

function Lights:onAutomatedTrainTravelActive()
	self:updateAutomaticLights(not g_currentMission.environment.isSunOn, false)
end

function Lights:onAIDriveableActive()
	self:updateAutomaticLights(not g_currentMission.environment.isSunOn, false)
end

function Lights:onAIDriveableEnd()
	if self.getIsControlled ~= nil and not self:getIsControlled() then
		self:setLightsTypesMask(0)
	end
	self:setBeaconLightsVisibility(false, true, true)
end

function Lights:onAIFieldWorkerStart()
	self:setBeaconLightsVisibility(false, true, true)
end

function Lights:onAIFieldWorkerActive()
	self:updateAutomaticLights(not g_currentMission.environment.isSunOn, true)
end

function Lights:onAIJobVehicleBlock()
	self:setBeaconLightsVisibility(true, true, true)
end

function Lights:onAIJobVehicleContinue()
	self:setBeaconLightsVisibility(false, true, true)
end

function Lights:onAIFieldWorkerEnd()
	if self.getIsControlled ~= nil and not self:getIsControlled() then
		self:setLightsTypesMask(0)
	end
	self:setBeaconLightsVisibility(false, true, true)
end

-- Local values: reverserDirection
function Lights:onVehiclePhysicsUpdate(acceleratorPedal, brakePedal, automaticBrake, currentSpeed)
	local v305_ = not automaticBrake
	if v305_ then
		v305_ = math.abs(brakePedal) > 0
	end
	self:setBrakeLightsVisibility(v305_)
	local v306_ = self.spec_drivable == nil and 1 or self.spec_drivable.reverserDirection
	local v307_
	if currentSpeed < -self.spec_lights.reverseLightActivationSpeed or acceleratorPedal < 0 then
		v307_ = v306_ == 1
	else
		v307_ = false
	end
	self:setReverseLightsVisibility(v307_)
end

-- Local values: i, light
function Lights:loadRealLightSetup(xmlFile, key, lightTable, realLightToLight)
	lightTable.defaultLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".light", self, self.components, self.i3dMappings, true)
	lightTable.topLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".topLight", self, self.components, self.i3dMappings, false)
	lightTable.bottomLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".bottomLight", self, self.components, self.i3dMappings, false)
	lightTable.brakeLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".brakeLight", self, self.components, self.i3dMappings, false)
	lightTable.reverseLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".reverseLight", self, self.components, self.i3dMappings, false)
	lightTable.turnLightsLeft = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".turnLightLeft", self, self.components, self.i3dMappings, false)
	lightTable.turnLightsRight = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".turnLightRight", self, self.components, self.i3dMappings, false)
	lightTable.interiorLights = RealLight.loadLightsFromXML(nil, xmlFile, key .. ".interiorLight", self, self.components, self.i3dMappings, false)
	for _, v312_ in ipairs(lightTable.interiorLights) do
		v312_:setChargeFunction(self.getInteriorLightBrightness, self)
		self.spec_lights.interiorLightsAvailable = true
	end
end

-- Local values: _, light
function Lights:applyAdditionalActiveLightType(lights, lightType, isBlinking)
	for _, v316_ in ipairs(lights) do
		local v317_ = v316_.lightTypes
		table.insert(v317_, lightType)
		if isBlinking then
			v316_:setIsBlinking(true)
		end
	end
end

-- Local values: spec, lightsTypesMask
function Lights:actionEventToggleLightFront(actionName, inputValue, callbackState, isAnalog)
	local v319_ = self.spec_lights
	if self:getCanToggleLight() and v319_.numLightTypes >= 1 then
		local v320_ = v319_.lightsTypesMask
		local v321_ = 2 ^ Lights.LIGHT_TYPE_DEFAULT
		self:setLightsTypesMask((bit32.bxor(v320_, v321_)))
	end
end

function Lights:actionEventToggleLights(actionName, inputValue, callbackState, isAnalog)
	if self:getCanToggleLight() then
		self:setNextLightsState(1)
	end
end

function Lights:actionEventToggleLightsBack(actionName, inputValue, callbackState, isAnalog)
	if self:getCanToggleLight() then
		self:setNextLightsState(-1)
	end
end

-- Local values: spec, lightsTypesMask
function Lights:actionEventToggleWorkLightBack(actionName, inputValue, callbackState, isAnalog)
	local v325_ = self.spec_lights
	if self:getCanToggleLight() then
		local v326_ = v325_.lightsTypesMask
		local v327_ = 2 ^ Lights.LIGHT_TYPE_WORK_BACK
		self:setLightsTypesMask((bit32.bxor(v326_, v327_)))
	end
end

-- Local values: spec, lightsTypesMask
function Lights:actionEventToggleWorkLightFront(actionName, inputValue, callbackState, isAnalog)
	local v329_ = self.spec_lights
	if self:getCanToggleLight() then
		local v330_ = v329_.lightsTypesMask
		local v331_ = 2 ^ Lights.LIGHT_TYPE_WORK_FRONT
		self:setLightsTypesMask((bit32.bxor(v330_, v331_)))
	end
end

-- Local values: spec, lightsTypesMask
function Lights:actionEventToggleHighBeamLight(actionName, inputValue, callbackState, isAnalog)
	local v333_ = self.spec_lights
	if self:getCanToggleLight() then
		local v334_ = v333_.lightsTypesMask
		local v335_ = 2 ^ Lights.LIGHT_TYPE_HIGHBEAM
		self:setLightsTypesMask((bit32.bxor(v334_, v335_)))
	end
end

-- Local values: spec, state
function Lights:actionEventToggleTurnLightHazard(actionName, inputValue, callbackState, isAnalog)
	local v337_ = self.spec_lights
	if self:getCanToggleLight() then
		local v338_ = Lights.TURNLIGHT_OFF
		if v337_.turnLightState ~= Lights.TURNLIGHT_HAZARD then
			v338_ = Lights.TURNLIGHT_HAZARD
		end
		self:setTurnLightState(v338_)
	end
end

-- Local values: spec, state
function Lights:actionEventToggleTurnLightLeft(actionName, inputValue, callbackState, isAnalog)
	local v340_ = self.spec_lights
	if self:getCanToggleLight() then
		local v341_ = Lights.TURNLIGHT_OFF
		if v340_.turnLightState ~= Lights.TURNLIGHT_LEFT then
			v341_ = Lights.TURNLIGHT_LEFT
		end
		self:setTurnLightState(v341_)
	end
end

-- Local values: spec, state
function Lights:actionEventToggleTurnLightRight(actionName, inputValue, callbackState, isAnalog)
	local v343_ = self.spec_lights
	if self:getCanToggleLight() then
		local v344_ = Lights.TURNLIGHT_OFF
		if v343_.turnLightState ~= Lights.TURNLIGHT_RIGHT then
			v344_ = Lights.TURNLIGHT_RIGHT
		end
		self:setTurnLightState(v344_)
	end
end

-- Local values: spec
function Lights:actionEventToggleBeaconLights(actionName, inputValue, callbackState, isAnalog)
	local v346_ = self.spec_lights
	if self:getCanToggleLight() then
		self:setBeaconLightsVisibility(not v346_.beaconLightsActive)
	end
end

-- Local values: actionEvent, _
function Lights.externalActionEventRegister(data, vehicle)
	local _, v349_ = g_inputBinding:registerActionEvent(InputAction.TOGGLE_LIGHTS_EXTERNAL, data, function(_, _, _, _, _)
		-- upvalues: (copy) vehicle
		vehicle:setNextLightsState(1)
	end, false, true, false, true)
	data.actionEventId = v349_
	g_inputBinding:setActionEventTextPriority(data.actionEventId, GS_PRIO_HIGH)
	g_inputBinding:setActionEventText(data.actionEventId, g_i18n:getText("input_TOGGLE_LIGHTS"))
end

function Lights.externalActionEventUpdate(data, vehicle) end

-- Local values: i
function Lights:dashboardLightAttributes(xmlFile, key, dashboard, isActive)
	dashboard.lightTypes = xmlFile:getValue(key .. "#lightTypes", nil, true)
	dashboard.excludedLightTypes = xmlFile:getValue(key .. "#excludedLightTypes", nil, true)
	dashboard.lightStates = {}
	for v354_ = 0, self.spec_lights.maxLightState do
		dashboard.lightStates[v354_] = false
	end
	return true
end

-- Local values: lightsTypesMask, anyLightActive, i
function Lights:dashboardLightState(dashboard, newValue, minValue, maxValue, isActive)
	local v361_ = self.spec_lights.lightsTypesMask
	if dashboard.displayTypeIndex == Dashboard.TYPES.MULTI_STATE then
		local v362_ = false
		for v363_ = 0, self.spec_lights.maxLightState do
			local v364_ = dashboard.lightStates
			local v365_ = 2 ^ v363_
			v364_[v363_] = bit32.band(v361_, v365_) ~= 0
			v362_ = v362_ or dashboard.lightStates[v363_]
		end
		if v362_ then
			Dashboard.defaultDashboardStateFunc(self, dashboard, dashboard.lightStates, minValue, maxValue, isActive)
		else
			Dashboard.defaultDashboardStateFunc(self, dashboard, -1, minValue, maxValue, isActive)
		end
	else
		Dashboard.defaultDashboardStateFunc(self, dashboard, newValue, minValue, maxValue, isActive)
		return
	end
end
function Lights.consoleCommandTopLights()
	local v366_ = g_localPlayer:getCurrentVehicle()
	if v366_ ~= nil and v366_.setTopLightsVisibility ~= nil then
		v366_:setTopLightsVisibility(not v366_.spec_lights.topLightsVisibility)
	end
end
addConsoleCommand("gsVehicleDebugTopLights", "Toggles between top and bottom lights", "Lights.consoleCommandTopLights", nil)
function Lights.consoleCommandProfile()
	if g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE) >= GS_PROFILE_HIGH then
		g_gameSettings:setValue(GameSettings.SETTING.LIGHTS_PROFILE, GS_PROFILE_LOW)
		Logging.info("Activated LOW light setup.")
	else
		g_gameSettings:setValue(GameSettings.SETTING.LIGHTS_PROFILE, GS_PROFILE_VERY_HIGH)
		Logging.info("Activated HIGH light setup.")
	end
end
addConsoleCommand("gsLightProfileToggle", "Toggles between high and low light profile on vehicles & placeables", "Lights.consoleCommandProfile", nil)
