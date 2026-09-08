Wheels = {}
Wheels.VRAM_PER_WHEEL = 524288
Wheels.CONFIG_XML_PATH = "vehicle.wheels.wheelConfigurations.wheelConfiguration"
Wheels.WHEELS_XML_PATH = "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).wheels"
Wheels.WHEEL_XML_PATH = "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).wheels.wheel(?)"
Wheels.xmlSchema = nil
Wheels.xmlSchemaHub = nil
Wheels.xmlSchemaConnector = nil
source("dataS/scripts/vehicles/wheels/WheelContactType.lua")
source("dataS/scripts/vehicles/wheels/Wheel.lua")
source("dataS/scripts/vehicles/wheels/WheelAxle.lua")

function Wheels.prerequisitesPresent(specializations)
	return true
end

function Wheels.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onBrake")
	SpecializationUtil.registerEvent(vehicleType, "onFinishedWheelLoading")
	SpecializationUtil.registerEvent(vehicleType, "onWheelConfigurationChanged")
end

function Wheels.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getSteeringRotTimeByCurvature", Wheels.getSteeringRotTimeByCurvature)
	SpecializationUtil.registerFunction(vehicleType, "getTurningRadiusByRotTime", Wheels.getTurningRadiusByRotTime)
	SpecializationUtil.registerFunction(vehicleType, "loadHubsFromXML", Wheels.loadHubsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadHubFromXML", Wheels.loadHubFromXML)
	SpecializationUtil.registerFunction(vehicleType, "onWheelHubI3DLoaded", Wheels.onWheelHubI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadAckermannSteeringFromXML", Wheels.loadAckermannSteeringFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelsFromXML", Wheels.loadWheelsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelFromXML", Wheels.loadWheelFromXML)
	SpecializationUtil.registerFunction(vehicleType, "onLoadWheelChockFromXML", Wheels.onLoadWheelChockFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsWheelChockAllowed", Wheels.getIsWheelChockAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsVersatileYRotActive", Wheels.getIsVersatileYRotActive)
	SpecializationUtil.registerFunction(vehicleType, "getWheelFromWheelIndex", Wheels.getWheelFromWheelIndex)
	SpecializationUtil.registerFunction(vehicleType, "getWheelByWheelNode", Wheels.getWheelByWheelNode)
	SpecializationUtil.registerFunction(vehicleType, "getWheels", Wheels.getWheels)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentSurfaceSound", Wheels.getCurrentSurfaceSound)
	SpecializationUtil.registerFunction(vehicleType, "getAreSurfaceSoundsActive", Wheels.getAreSurfaceSoundsActive)
	SpecializationUtil.registerFunction(vehicleType, "brake", Wheels.brake)
	SpecializationUtil.registerFunction(vehicleType, "getBrakeForce", Wheels.getBrakeForce)
	SpecializationUtil.registerFunction(vehicleType, "setCustomBrakeForce", Wheels.setCustomBrakeForce)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelDirtAmount", Wheels.updateWheelDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelMudAmount", Wheels.updateWheelMudAmount)
	SpecializationUtil.registerFunction(vehicleType, "forceUpdateWheelPhysics", Wheels.forceUpdateWheelPhysics)
	SpecializationUtil.registerFunction(vehicleType, "onWheelSnowHeightChanged", Wheels.onWheelSnowHeightChanged)
	SpecializationUtil.registerFunction(vehicleType, "getSteeringNodeByNode", Wheels.getSteeringNodeByNode)
	SpecializationUtil.registerFunction(vehicleType, "updateSteeringNodes", Wheels.updateSteeringNodes)
end

function Wheels.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Wheels.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Wheels.removeFromPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getComponentMass", Wheels.getComponentMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVehicleWorldXRot", Wheels.getVehicleWorldXRot)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVehicleWorldDirection", Wheels.getVehicleWorldDirection)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "validateWashableNode", Wheels.validateWashableNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIDirectionNode", Wheels.getAIDirectionNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIRootNode", Wheels.getAIRootNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSupportsMountKinematic", Wheels.getSupportsMountKinematic)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadBendingNodeFromXML", Wheels.loadBendingNodeFromXML)
end

function Wheels.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerStart", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerEnd", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementEnd", Wheels)
end
function Wheels.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("wheel", g_i18n:getText("configuration_wheelSetup"), "wheels", VehicleConfigurationItemWheel, g_i18n:getText("configuration_wheelBrand"), Wheels.getBrands, Wheels.getWheelsByBrand, 2)
	g_vehicleConfigurationManager:addConfigurationType("rimColor", g_i18n:getText("configuration_rimColor"), nil, VehicleConfigurationItemColor)
	g_storeManager:addSpecType("wheels", "shopListAttributeIconWheels", Wheels.loadSpecValueWheels, Wheels.getSpecValueWheels, StoreSpecies.VEHICLE)
	g_storeManager:addVRamUsageFunction(Wheels.getVRamUsageFromXML)
	local v5_ = Vehicle.xmlSchema
	v5_:setXMLSpecializationType("Wheels")
	v5_:register(XMLValueType.STRING, "vehicle.wheels.wheelConfigurations#tireCategories", "List of tire categories to include in the automatic wheel config generation (separated by whitespace)")
	v5_:register(XMLValueType.STRING_LIST, "vehicle.wheels.wheelConfigurations#customBrandOrder", "Custom brand order for dynamic configurations (names of the brands separated by whitespace)")
	v5_:register(XMLValueType.STRING, "vehicle.wheels.wheelConfigurations.tireCombination(?)#brand", "Brand name of the combination")
	v5_:register(XMLValueType.STRING, "vehicle.wheels.wheelConfigurations.tireCombination(?)#names", "List of tire names that are allowed to be mixed. Otherwise all mixes are allowed. Does not effect configuration with all tires from the same name. (separated by whitespace)")
	v5_:register(XMLValueType.INT, Wheels.CONFIG_XML_PATH .. "(?)#numDynamicConfigurations", "Max. number of dynamic configurations per brand", "unlimited")
	v5_:register(XMLValueType.STRING, Wheels.CONFIG_XML_PATH .. "(?)#tireCategories", "List of tire categories to include in the automatic wheel config generation (separated by whitespace)")
	v5_:register(XMLValueType.STRING, Wheels.CONFIG_XML_PATH .. "(?).tireCombination(?)#brand", "Brand name of the combination")
	v5_:register(XMLValueType.STRING, Wheels.CONFIG_XML_PATH .. "(?).tireCombination(?)#names", "List of tire names that are allowed to be mixed. Otherwise all mixes are allowed. Does not effect configuration with all tires from the same name. (separated by whitespace)")
	WheelAxle.registerXMLPaths(v5_, "vehicle.wheels.axles.axle(?)")
	WheelAxle.registerXMLPaths(v5_, Wheels.CONFIG_XML_PATH .. "(?).axle(?)")
	local v6_ = Wheels.WHEELS_XML_PATH
	v5_:register(XMLValueType.FLOAT, v6_ .. "#autoRotateBackSpeed", "Auto rotate back speed", 1)
	v5_:register(XMLValueType.BOOL, v6_ .. "#speedDependentRotateBack", "Speed dependent auto rotate back speed", true)
	v5_:register(XMLValueType.INT, v6_ .. "#differentialIndex", "Differential index")
	v5_:register(XMLValueType.INT, v6_ .. "#ackermannSteeringIndex", "Ackermann steering index")
	v5_:register(XMLValueType.FLOAT, v6_ .. "#ackermannSteeringAngle", "Ackermann steering angle to set while this config is active")
	v5_:register(XMLValueType.BOOL, v6_ .. "#isCareWheelConfiguration", "All wheels will be care wheels")
	v5_:register(XMLValueType.STRING, v6_ .. "#baseConfig", "Base for this configuration")
	v5_:register(XMLValueType.BOOL, v6_ .. "#hasSurfaceSounds", "Has surface sounds", true)
	v5_:register(XMLValueType.STRING, v6_ .. "#surfaceSoundTireType", "Tire type that is used for surface sounds", "Tire type of first wheel")
	v5_:register(XMLValueType.NODE_INDEX, v6_ .. "#surfaceSoundLinkNode", "Surface sound link node", "Root component")
	Wheel.registerXMLPaths(v5_, v6_ .. ".wheel(?)")
	VehicleMaterial.registerXMLPaths(v5_, "vehicle.wheels.rimMaterial")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.rimMaterial#useBaseColor", "Use base vehicle color", false)
	v5_:register(XMLValueType.INT, "vehicle.wheels.rimMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
	VehicleMaterial.registerXMLPaths(v5_, "vehicle.wheels.innerRimMaterial")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.innerRimMaterial#useBaseColor", "Use base vehicle color", false)
	v5_:register(XMLValueType.INT, "vehicle.wheels.innerRimMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
	VehicleMaterial.registerXMLPaths(v5_, "vehicle.wheels.outerRimMaterial")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.outerRimMaterial#useBaseColor", "Use base vehicle color", false)
	v5_:register(XMLValueType.INT, "vehicle.wheels.outerRimMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
	VehicleMaterial.registerXMLPaths(v5_, "vehicle.wheels.additionalMaterial")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.additionalMaterial#useBaseColor", "Use base vehicle color", false)
	v5_:register(XMLValueType.INT, "vehicle.wheels.additionalMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
	VehicleMaterial.registerXMLPaths(v5_, "vehicle.wheels.hubMaterial")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubMaterial#useBaseColor", "Use base vehicle color", false)
	v5_:register(XMLValueType.INT, "vehicle.wheels.hubMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubMaterial#useRimColor", "Use rim color", false)
	VehicleMaterial.registerXMLPaths(v5_, "vehicle.wheels.hubBoltMaterial")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubBoltMaterial#useBaseColor", "Use base vehicle color", false)
	v5_:register(XMLValueType.INT, "vehicle.wheels.hubBoltMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubBoltMaterial#useRimColor", "Use rim color", false)
	VehicleMaterial.registerXMLPaths(v5_, "vehicle.wheels.hubs.material")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubs.material#useBaseColor", "Use base vehicle color", false)
	v5_:register(XMLValueType.INT, "vehicle.wheels.hubs.material#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubs.material#useRimColor", "Use rim color", false)
	v5_:register(XMLValueType.NODE_INDEX, "vehicle.wheels.hubs.hub(?)#linkNode", "Link node")
	v5_:register(XMLValueType.STRING, "vehicle.wheels.hubs.hub(?)#filename", "Filename")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?)#isLeft", "Is left side", false)
	v5_:register(XMLValueType.FLOAT, "vehicle.wheels.hubs.hub(?)#offset", "X axis offset")
	v5_:register(XMLValueType.VECTOR_SCALE, "vehicle.wheels.hubs.hub(?)#scale", "Hub scale")
	VehicleMaterial.registerXMLPaths(v5_, "vehicle.wheels.hubs.hub(?).material")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).material#useBaseColor", "Use base vehicle color", false)
	v5_:register(XMLValueType.INT, "vehicle.wheels.hubs.hub(?).material#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).material#useRimColor", "Use rim color", false)
	VehicleMaterial.registerXMLPaths(v5_, "vehicle.wheels.hubs.hub(?).boltMaterial")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).boltMaterial#useBaseColor", "Use base vehicle color", false)
	v5_:register(XMLValueType.INT, "vehicle.wheels.hubs.hub(?).boltMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).boltMaterial#useRimColor", "Use rim color", false)
	VehicleMaterial.registerXMLPaths(v5_, "vehicle.wheels.hubs.hub(?).additionalMaterial")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).additionalMaterial#useBaseColor", "Use base vehicle color", false)
	v5_:register(XMLValueType.INT, "vehicle.wheels.hubs.hub(?).additionalMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).additionalMaterial#useRimColor", "Use rim color", false)
	VehicleMaterial.registerXMLPaths(v5_, "vehicle.wheels.hubs.hub(?).boltAdditionalMaterial")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).boltAdditionalMaterial#useBaseColor", "Use base vehicle color", false)
	v5_:register(XMLValueType.INT, "vehicle.wheels.hubs.hub(?).boltAdditionalMaterial#useDesignColorIndex", "Use color of the design color with the defined index (1-16)")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?).boltAdditionalMaterial#useRimColor", "Use rim color", false)
	v5_:addDelayedRegistrationFunc("AnimatedVehicle:part", function(p7_, p8_)
		p7_:register(XMLValueType.INT, p8_ .. "#wheelIndex", "Wheel index [1..n]")
		p7_:register(XMLValueType.ANGLE, p8_ .. "#startSteeringAngle", "Start steering angle")
		p7_:register(XMLValueType.ANGLE, p8_ .. "#endSteeringAngle", "End steering angle")
		p7_:register(XMLValueType.FLOAT, p8_ .. "#startBrakeFactor", "Start brake force factor")
		p7_:register(XMLValueType.FLOAT, p8_ .. "#endBrakeFactor", "End brake force factor")
		p7_:register(XMLValueType.FLOAT, p8_ .. "#startTorqueDirection", "Start torque direction")
		p7_:register(XMLValueType.FLOAT, p8_ .. "#endTorqueDirection", "End torque direction")
	end)
	v5_:register(XMLValueType.NODE_INDEX, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(?)#linkNode", "Link node")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(?)#isLeft", "Is Left", false)
	v5_:register(XMLValueType.STRING, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(?)#filename", "Filename")
	v5_:register(XMLValueType.STRING, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(?)#configId", "Wheel config id", "default")
	v5_:register(XMLValueType.BOOL, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(?)#isShallowWaterObstacle", "The dynamically loaded wheel will interact with the shallow water simulation", false)
	WheelVisual.registerXMLPaths(v5_, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(?)")
	Wheels.registerAckermannSteeringXMLPaths(v5_, "vehicle.wheels.ackermannSteeringConfigurations.ackermannSteering(?)")
	v5_:register(XMLValueType.NODE_INDEX, "vehicle.wheels.steeringNodes.steeringNode(?)#node", "Additional node that is used for steering (Same behaviour as wheels using the ackermann steering setting)")
	v5_:register(XMLValueType.FLOAT, "vehicle.wheels.steeringNodes.steeringNode(?)#rotScale", "Scale factor for rotation", 1)
	v5_:register(XMLValueType.ANGLE, "vehicle.wheels.steeringNodes.steeringNode(?)#rotChangeSpeed", "Max. rotation speed when limits change", 45)
	v5_:register(XMLValueType.VECTOR_N, FoliageBending.BENDING_NODE_XML_KEY .. "#wheelIndices", "Wheel Indices to calculate the bending node size automatically")
	Dashboard.registerDashboardXMLPaths(v5_, "vehicle.wheels.dashboards", { "brake", "steeringAngle" })
	Dashboard.addDelayedRegistrationFunc(v5_, function(p9_, p10_)
		p9_:register(XMLValueType.INT, p10_ .. "#steeringNodeIndex", "Index of steering node")
		p9_:register(XMLValueType.INT, p10_ .. "#wheelIndex", "Index of wheel")
		p9_:register(XMLValueType.VECTOR_N, p10_ .. "#wheelIndices", "List of wheel indices (separated by whitespace)")
	end)
	v5_:setXMLSpecializationType()
	Wheels.xmlSchema = XMLSchema.new("wheel")
	Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.metadata#brand", "Wheel tire brand", "LIZARD")
	Wheels.xmlSchema:registerAutoCompletionDataSource("wheel.metadata#brand", "$dataS/brands.xml", "brands.brand#name")
	Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.metadata#name", "Wheel tire name", "Tire")
	Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.metadata#category", "Wheel tire category for automatic wheel configurations")
	Wheels.xmlSchema:register(XMLValueType.BOOL, "wheel.metadata#allowMixture", "Allow mixing with other tires from the same brand", false)
	Wheels.xmlSchema:register(XMLValueType.FLOAT, "wheel.metadata#priority", "Tire priority for selection in the shop (wheels with high prio will be shown first)", 1)
	Wheel.registerXMLPaths(Wheels.xmlSchema, "wheel.default")
	Wheel.registerXMLPaths(Wheels.xmlSchema, "wheel.configurations.configuration(?)")
	Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.configurations.configuration(?)#id", "Configuration Id")
	Wheels.xmlSchemaHub = XMLSchema.new("wheelHub")
	local v11_ = Wheels.xmlSchemaHub
	v11_:register(XMLValueType.STRING, "hub.filename", "I3D filename")
	v11_:register(XMLValueType.STRING, "hub.nodes#left", "Index of left node in hub i3d file")
	v11_:register(XMLValueType.STRING, "hub.nodes#right", "Index of right node in hub i3d file")
	Wheels.xmlSchemaConnector = XMLSchema.new("wheelConnector")
	local v12_ = Wheels.xmlSchemaConnector
	v12_:register(XMLValueType.STRING, "connector.file#name", "I3D filename")
	v12_:register(XMLValueType.STRING, "connector.file#leftNode", "Index of left node in connector i3d file")
	v12_:register(XMLValueType.STRING, "connector.file#rightNode", "Index of right node in connector i3d file")
	Vehicle.xmlSchemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).wheels#lastConfigId", "Last selected wheel configuration id")
end

function Wheels.registerAckermannSteeringXMLPaths(schema, key)
	schema:register(XMLValueType.FLOAT, key .. "#rotSpeed", "Rotation speed")
	schema:register(XMLValueType.FLOAT, key .. "#rotMax", "Max. rotation")
	schema:register(XMLValueType.INT, key .. "#rotCenterWheel1", "Rotation center wheel 1")
	schema:register(XMLValueType.INT, key .. "#rotCenterWheel2", "Rotation center wheel 2")
	schema:register(XMLValueType.VECTOR_N, key .. "#rotCenterWheels", "List of wheel indices which represent the steering center")
	schema:register(XMLValueType.NODE_INDEX, key .. "#rotCenterNode", "Rotation center node (Used if rotCenterWheelX not given)")
	schema:register(XMLValueType.VECTOR_2, key .. "#rotCenter", "Center position (from root component) (Used if rotCenterWheelX not given)")
	schema:register(XMLValueType.FLOAT, key .. "#minTurningRadius", "Overwrites the automatically calculated turning radius for this config")
end

-- Local values: spec
function Wheels:onPreLoad(savegame)
	local v16_ = self.spec_wheels
	v16_.wheelConfigurationId = self.configurations.wheel or 1
	v16_.configKey = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", v16_.wheelConfigurationId - 1)
	v16_.configItem = ConfigurationUtil.getConfigItemByConfigId(self.configFileName, "wheel", v16_.wheelConfigurationId)
	if v16_.configItem ~= nil then
		v16_.configItem:applyGeneratedConfiguration(self.xmlFile)
		v16_.configKey = v16_.configItem.configKey
		v16_.lastWheelConfigSaveId = v16_.configItem.saveId
	end
end

-- Local values: spec, loadMaterial, hasSurfaceSounds, surfaceSoundLinkNode, tireTypeName, addSurfaceSound, surfaceSounds, j, surfaceSound, surfaceSound, sample, j, surfaceSound, surfaceSound, sample
function Wheels:onLoad(savegame)
	local v_u_18_ = self.spec_wheels
	v_u_18_.sharedLoadRequestIds = {}
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.driveGroundParticleSystems", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#hasParticles")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheelConfigurations.wheelConfiguration", "vehicle.wheels.wheelConfigurations.wheelConfiguration")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.rimColor", "vehicle.wheels.rimColor")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.hubColor", "vehicle.wheels.hubs.color0")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.dynamicallyLoadedWheels", "vehicle.wheels.dynamicallyLoadedWheels")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ackermannSteeringConfigurations", "vehicle.wheels.ackermannSteeringConfigurations")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheel", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheelConfigurations.wheelConfiguration.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#configIndex", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#configId")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ackermannSteering", "vehicle.wheels.ackermannSteeringConfigurations.ackermannSteering")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheel.rimColor", "vehicle.wheels.rimMaterial")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheel.hubs.rimColor.color0", "vehicle.wheels.hubMaterial")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheel.hubs.rimColor.color1", "vehicle.wheels.hubBoltMaterial")
	v_u_18_.configurationIndexToParentConfigIndex = Wheels.createConfigToParentConfigMapping(self.xmlFile)
	if v_u_18_.configItem ~= nil then
		v_u_18_.configItem:applyObjectChanges(self, v_u_18_.configurationIndexToParentConfigIndex)
	end
	local function v25_(p19_, p20_, p21_)
		-- upvalues: (copy) self, (copy) v_u_18_
		local v22_ = VehicleMaterial.new(self.baseDirectory)
		if v22_:loadFromXML(self.xmlFile, p20_, self.customEnvironment) then
			v_u_18_[p19_] = v22_
		else
			v22_ = nil
		end
		if self.xmlFile:getValue(p20_ .. "#useBaseColor") then
			v_u_18_[p19_] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(self, "baseColor") or v_u_18_[p19_]
			return
		else
			local v23_ = self.xmlFile:getValue(p20_ .. "#useDesignColorIndex")
			if v23_ == nil then
				if v22_ == nil and not p21_ or self.xmlFile:getBool(p20_ .. "#useRimColor", false) then
					v_u_18_[p19_] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(self, "rimColor") or (v_u_18_.rimMaterial or v_u_18_[p19_])
					if v_u_18_[p19_] == nil then
						v_u_18_[p19_] = VehicleMaterial.new(self.baseDirectory)
						v_u_18_[p19_]:setTemplateName("RIM_DEFAULT")
					end
				end
			else
				local v24_ = v23_ < 2 and "designColor" or string.format("designColor%d", v23_)
				v_u_18_[p19_] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(self, v24_) or v_u_18_[p19_]
			end
		end
	end
	v25_("rimMaterial", "vehicle.wheels.rimMaterial", false)
	v25_("innerRimMaterial", "vehicle.wheels.innerRimMaterial", false)
	v25_("outerRimMaterial", "vehicle.wheels.outerRimMaterial", false)
	v25_("additionalMaterial", "vehicle.wheels.additionalMaterial", false)
	v25_("hubMaterial", "vehicle.wheels.hubMaterial", true)
	v25_("hubBoltMaterial", "vehicle.wheels.hubBoltMaterial", true)
	self:loadHubsFromXML()
	self.maxRotTime = 0
	self.minRotTime = 0
	self.rotatedTimeInterpolator = InterpolatorValue.new(0)
	self.autoRotateBackSpeed = WheelXMLObject.getValueStatic(v_u_18_.wheelConfigurationId, v_u_18_.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#autoRotateBackSpeed", 1)
	self.speedDependentRotateBack = WheelXMLObject.getValueStatic(v_u_18_.wheelConfigurationId, v_u_18_.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#speedDependentRotateBack", true)
	self.differentialIndex = WheelXMLObject.getValueStatic(v_u_18_.wheelConfigurationId, v_u_18_.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#differentialIndex")
	v_u_18_.ackermannSteeringIndex = WheelXMLObject.getValueStatic(v_u_18_.wheelConfigurationId, v_u_18_.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#ackermannSteeringIndex")
	v_u_18_.ackermannSteeringAngle = WheelXMLObject.getValueStatic(v_u_18_.wheelConfigurationId, v_u_18_.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#ackermannSteeringAngle")
	v_u_18_.isCareWheelConfiguration = WheelXMLObject.getValueStatic(v_u_18_.wheelConfigurationId, v_u_18_.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#isCareWheelConfiguration")
	local v26_ = WheelXMLObject.getValueStatic(v_u_18_.wheelConfigurationId, v_u_18_.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#hasSurfaceSounds", true)
	v_u_18_.wheelSmoothAccumulation = 0
	v_u_18_.currentUpdateIndex = 1
	v_u_18_.wheels = {}
	v_u_18_.wheelsByNode = {}
	self:loadWheelsFromXML(self.xmlFile, v_u_18_.configKey, v_u_18_.wheelConfigurationId)
	if v26_ then
		local v27_ = WheelXMLObject.getValueStatic(v_u_18_.wheelConfigurationId, v_u_18_.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#surfaceSoundLinkNode", self.components[1].node, self.components, self.i3dMappings)
		local v28_ = (#v_u_18_.wheels <= 0 or v_u_18_.wheels[1].physics.tireType == nil) and "" or WheelsUtil.getTireTypeName(v_u_18_.wheels[1].physics.tireType)
		local v29_ = WheelXMLObject.getValueStatic(v_u_18_.wheelConfigurationId, v_u_18_.configurationIndexToParentConfigIndex, self.xmlFile, Wheels.CONFIG_XML_PATH, ".wheels", "#surfaceSoundTireType", v28_)
		v_u_18_.surfaceSounds = {}
		v_u_18_.surfaceIdToSound = {}
		v_u_18_.surfaceNameToSound = {}
		v_u_18_.currentSurfaceSound = nil
		local v30_ = g_currentMission.surfaceSounds
		for v31_ = 1, #v30_ do
			local v32_ = v30_[v31_]
			if string.lower(v32_.type) == "wheel_" .. string.lower(v29_) then
				local v33_ = g_soundManager:cloneSample(v32_.sample, v27_, self)
				v33_.sampleName = v32_.name
				local v34_ = v_u_18_.surfaceSounds
				table.insert(v34_, v33_)
				v_u_18_.surfaceIdToSound[v32_.materialId] = v33_
				v_u_18_.surfaceNameToSound[v32_.name] = v33_
			end
		end
		for v35_ = 1, #v30_ do
			local v36_ = v30_[v35_]
			if v_u_18_.surfaceNameToSound[v36_.name] == nil and v36_.type == "wheel" then
				local v37_ = g_soundManager:cloneSample(v36_.sample, v27_, self)
				v37_.sampleName = v36_.name
				local v38_ = v_u_18_.surfaceSounds
				table.insert(v38_, v37_)
				v_u_18_.surfaceIdToSound[v36_.materialId] = v37_
				v_u_18_.surfaceNameToSound[v36_.name] = v37_
			end
		end
	end
	v_u_18_.dynamicallyLoadedWheels = {}
	self.xmlFile:iterate("vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel", function(p39_, p40_)
		-- upvalues: (copy) self, (copy) v_u_18_
		local v41_ = self.xmlFile:getValue(p40_ .. "#linkNode", self.components[1].node, self.components, self.i3dMappings)
		local v42_ = self.xmlFile:getValue(p40_ .. "#isLeft", false)
		local v43_ = self.xmlFile:getValue(p40_ .. "#isShallowWaterObstacle", false)
		local v44_ = WheelXMLObject.new(self.xmlFile, "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel", p39_, "", {})
		local v45_ = WheelVisual.new(self, nil, v41_, v42_, 0, self.baseDirectory)
		if v45_:loadFromXML(v44_) then
			if v43_ then
				v45_:addShallowWaterObstacle()
			end
			v45_.name = v44_.externalWheelName
			local v46_ = v_u_18_.dynamicallyLoadedWheels
			table.insert(v46_, v45_)
		else
			v45_:delete()
		end
		v44_:delete()
	end)
	v_u_18_.steeringNodes = {}
	self.xmlFile:iterate("vehicle.wheels.steeringNodes.steeringNode", function(_, p47_)
		-- upvalues: (copy) self, (copy) v_u_18_
		local v48_ = self.xmlFile:getValue(p47_ .. "#node", nil, self.components, self.i3dMappings)
		if v48_ ~= nil then
			local v49_ = {
				["node"] = v48_,
				["rotScale"] = self.xmlFile:getValue(p47_ .. "#rotScale", 1),
				["rotChangeSpeed"] = self.xmlFile:getValue(p47_ .. "#rotChangeSpeed", 45)
			}
			v49_.rotScaleOrig = v49_.rotScale
			v49_.rotScaleTarget = v49_.rotScale
			v49_.rotScaleTargetSpeed = 1
			v49_.steeringAngle = 0
			v49_.offset = 0
			v49_.offsetTarget = 0
			v49_.offsetTargetSpeed = 1
			for _, v50_ in pairs(self.componentJoints) do
				if v50_.jointNode == v48_ then
					v49_.componentJoint = v50_
					break
				end
			end
			local v51_ = v_u_18_.steeringNodes
			table.insert(v51_, v49_)
		end
	end)
	v_u_18_.hasSteeringNodes = #v_u_18_.steeringNodes > 0
	v_u_18_.axles = {}
	self.xmlFile:iterate("vehicle.wheels.axles.axle", function(_, p52_)
		-- upvalues: (copy) self, (copy) v_u_18_
		local v53_ = WheelAxle.new(self)
		if v53_:loadFromXML(self.xmlFile, p52_) then
			local v54_ = v_u_18_.axles
			table.insert(v54_, v53_)
		end
	end)
	self.xmlFile:iterate(v_u_18_.configKey .. ".axle", function(_, p55_)
		-- upvalues: (copy) self, (copy) v_u_18_
		local v56_ = WheelAxle.new(self)
		if v56_:loadFromXML(self.xmlFile, p55_) then
			local v57_ = v_u_18_.axles
			table.insert(v57_, v56_)
		end
	end)
	v_u_18_.hasAxles = #v_u_18_.axles > 0
	v_u_18_.networkTimeInterpolator = InterpolationTime.new(1.2)
	self:loadAckermannSteeringFromXML(self.xmlFile, v_u_18_.ackermannSteeringIndex, v_u_18_.ackermannSteeringAngle)
	SpecializationUtil.raiseEvent(self, "onFinishedWheelLoading", self.xmlFile, v_u_18_.configKey .. ".wheels")
	v_u_18_.brakePedal = 0
	v_u_18_.dirtyFlag = self:getNextDirtyFlag()
	g_messageCenter:subscribe(MessageType.SNOW_HEIGHT_CHANGED, self.onWheelSnowHeightChanged, self)
end

-- Local values: spec, _, wheel, lastConfigId, _, wheel, washableNode, mudWashableNode, i, hub, _, wheel, _, visualWheel, _, wheel
function Wheels:onLoadFinished(savegame)
	local v60_ = self.spec_wheels
	if self.isServer then
		for _, v61_ in pairs(v60_.wheels) do
			self.defaultMass = self.defaultMass + v61_:getMass()
		end
		if savegame ~= nil and not savegame.resetVehicles then
			local v62_ = savegame.xmlFile:getValue(savegame.key .. ".wheels#lastConfigId")
			if v62_ ~= nil and (v60_.configItem ~= nil and v60_.configItem.saveId ~= v62_) then
				for _, v63_ in pairs(v60_.wheels) do
					local v64_ = self:getWashableNodeByCustomIndex(v63_)
					if v64_ ~= nil then
						self:setNodeDirtAmount(v64_, 0, true)
					end
					if v63_.wheelMudMeshes ~= nil then
						local v65_ = self:getWashableNodeByCustomIndex(v63_.wheelMudMeshes)
						if v65_ ~= nil then
							self:setNodeDirtAmount(v65_, 0, true)
						end
					end
				end
				SpecializationUtil.raiseEvent(self, "onWheelConfigurationChanged")
			end
		end
	end
	if v60_.rimMaterial ~= nil then
		v60_.rimMaterial:applyToVehicle(self, "rim_inner_mat")
		v60_.rimMaterial:applyToVehicle(self, "rim_outer_mat")
	end
	if v60_.innerRimMaterial ~= nil then
		v60_.innerRimMaterial:applyToVehicle(self, "rim_inner_mat")
	end
	if v60_.outerRimMaterial ~= nil then
		v60_.outerRimMaterial:applyToVehicle(self, "rim_outer_mat")
	end
	if v60_.additionalMaterial ~= nil then
		v60_.additionalMaterial:applyToVehicle(self, "rim_additional_mat")
	end
	if v60_.hubMaterial ~= nil then
		v60_.hubMaterial:applyToVehicle(self, "hub_main_mat")
	end
	if v60_.hubBoltMaterial ~= nil then
		v60_.hubBoltMaterial:applyToVehicle(self, "hub_bolt_mat")
	end
	for _, v66_ in ipairs(v60_.hubs) do
		if v66_.material ~= nil then
			v66_.material:apply(v66_.node, "hub_main_mat")
		end
		if v66_.boltMaterial ~= nil then
			v66_.boltMaterial:apply(v66_.node, "hub_bolt_mat")
		end
		if v66_.additionalMaterial ~= nil then
			v66_.additionalMaterial:apply(v66_.node, "hub_main_additional_mat")
		end
		if v66_.boltAdditionalMaterial ~= nil then
			v66_.boltAdditionalMaterial:apply(v66_.node, "hub_bolt_additional_mat")
		end
	end
	for _, v67_ in pairs(v60_.wheels) do
		v67_:postLoad()
	end
	for _, v68_ in pairs(v60_.dynamicallyLoadedWheels) do
		v68_:postLoad()
	end
	for _, v69_ in ipairs(v60_.wheels) do
		v69_:update(99999, v60_.currentUpdateIndex, 0, true)
	end
end

-- Local values: spec, brake, steeringAngle
function Wheels:onRegisterDashboardValueTypes()
	local v_u_71_ = self.spec_wheels
	local v72_ = DashboardValueType.new("wheels", "brake")
	v72_:setValue(v_u_71_, "brakePedal")
	v72_:setRange(0, 1)
	self:registerDashboardValueType(v72_)
	local v73_ = DashboardValueType.new("wheels", "steeringAngle")
	v73_:setRange(-180, 180)
	v73_:setValue(v_u_71_, function(_, p74_)
		-- upvalues: (copy) v_u_71_
		if p74_.steeringNodeIndex ~= nil then
			local v75_ = v_u_71_.steeringNodes[p74_.steeringNodeIndex]
			if v75_ ~= nil then
				local v76_ = v75_.steeringAngle
				return math.deg(v76_)
			end
		end
		if p74_.wheelIndex ~= nil then
			local v77_ = v_u_71_.wheels[p74_.wheelIndex]
			if v77_ ~= nil then
				local v78_ = v77_.physics.steeringAngle
				return math.deg(v78_)
			end
		end
		if p74_.wheelIndices == nil then
			return 0
		end
		local v79_ = 0
		for _, v80_ in ipairs(p74_.wheelIndices) do
			local v81_ = v_u_71_.wheels[v80_]
			if v81_ ~= nil then
				local v82_ = v81_.physics.steeringAngle
				local v83_ = math.abs(v82_)
				v79_ = math.max(v79_, v83_)
			end
		end
		return math.deg(v79_)
	end)
	v73_:setAdditionalFunctions(function(_, p84_, p85_, p86_, _)
		p86_.steeringNodeIndex = p84_:getValue(p85_ .. "#steeringNodeIndex")
		p86_.wheelIndex = p84_:getValue(p85_ .. "#wheelIndex")
		p86_.wheelIndices = p84_:getValue(p85_ .. "#wheelIndices", nil, true)
		return true
	end)
	self:registerDashboardValueType(v73_)
end

-- Local values: spec
function Wheels:saveToXMLFile(xmlFile, key, usedModNames)
	local v90_ = self.spec_wheels
	if v90_.lastWheelConfigSaveId ~= nil then
		xmlFile:setValue(key .. "#lastConfigId", v90_.lastWheelConfigSaveId)
	end
end

-- Local values: spec, _, sharedLoadRequestId, _, hub, _, wheel, _, visualWheel
function Wheels:onDelete()
	local v92_ = self.spec_wheels
	if v92_.sharedLoadRequestIds ~= nil then
		for _, v93_ in pairs(v92_.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(v93_)
		end
	end
	if v92_.hubs ~= nil then
		for _, v94_ in pairs(v92_.hubs) do
			delete(v94_.node)
		end
	end
	if v92_.wheels ~= nil then
		for _, v95_ in pairs(v92_.wheels) do
			v95_:delete()
		end
	end
	if v92_.dynamicallyLoadedWheels ~= nil then
		for _, v96_ in ipairs(v92_.dynamicallyLoadedWheels) do
			v96_:delete()
		end
	end
	g_soundManager:deleteSamples(v92_.surfaceSounds)
end

-- Local values: spec, i, wheel
function Wheels:onReadStream(streamId, connection)
	if connection.isServer then
		local v100_ = self.spec_wheels
		v100_.networkTimeInterpolator:reset()
		for v101_ = 1, #v100_.wheels do
			local v102_ = v100_.wheels[v101_]
			if v102_.physics.isSynchronized then
				v102_:readStream(streamId, true)
			end
		end
		self.rotatedTimeInterpolator:setValue(0)
	end
end

-- Local values: spec, i, wheel
function Wheels:onWriteStream(streamId, connection)
	if not connection.isServer then
		local v106_ = self.spec_wheels
		for v107_ = 1, #v106_.wheels do
			local v108_ = v106_.wheels[v107_]
			if v108_.physics.isSynchronized then
				v108_:writeStream(streamId)
			end
		end
	end
end

-- Local values: hasUpdate, spec, i, wheel, rotatedTimeRange, rotatedTime, rotatedTimeTarget
function Wheels:onReadUpdateStream(streamId, timestamp, connection)
	if connection.isServer and streamReadBool(streamId) then
		local v112_ = self.spec_wheels
		v112_.networkTimeInterpolator:startNewPhaseNetwork()
		for v113_ = 1, #v112_.wheels do
			local v114_ = v112_.wheels[v113_]
			if v114_.physics.isSynchronized then
				v114_:readStream(streamId, false)
			end
		end
		if self.maxRotTime ~= 0 and self.minRotTime ~= 0 then
			local v115_ = self.maxRotTime - self.minRotTime
			local v116_ = math.max(v115_, 0.001)
			local v117_ = streamReadUIntN(streamId, 8)
			local v118_ = self.rotatedTime
			if math.abs(v118_) < 0.001 then
				self.rotatedTime = 0
			end
			local v119_ = v117_ / 255 * v116_ + self.minRotTime
			self.rotatedTimeInterpolator:setTargetValue(v119_)
		end
	end
end

-- Local values: spec, i, wheel, rotatedTimeRange, rotatedTime
function Wheels:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer then
		local v124_ = self.spec_wheels
		local v125_ = streamWriteBool
		local v126_ = v124_.dirtyFlag
		if v125_(streamId, bit32.band(dirtyMask, v126_) ~= 0) then
			for v127_ = 1, #v124_.wheels do
				local v128_ = v124_.wheels[v127_]
				if v128_.physics.isSynchronized then
					v128_:writeStream(streamId)
				end
			end
			if self.maxRotTime ~= 0 and self.minRotTime ~= 0 then
				local v129_ = self.maxRotTime - self.minRotTime
				local v130_ = math.max(v129_, 0.001)
				local v131_ = (self.rotatedTime - self.minRotTime) / v130_ * 255
				local v132_ = math.floor(v131_)
				local v133_ = math.clamp(v132_, 0, 255)
				streamWriteUIntN(streamId, v133_, 8)
			end
		end
	end
end

-- Local values: spec, interpolationAlpha, i, wheel, groundWetness, k, wheel, allowFoliageDestruction, k, wheel, _, axle, currentSound
function Wheels:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v136_ = self.spec_wheels
	if not self.isServer and self.isClient then
		v136_.networkTimeInterpolator:update(dt)
		local v137_ = v136_.networkTimeInterpolator:getAlpha()
		self.rotatedTime = self.rotatedTimeInterpolator:getInterpolatedValue(v137_)
		for v138_ = 1, #v136_.wheels do
			v136_.wheels[v138_]:updateInterpolation(dt, v137_)
		end
		if v136_.networkTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end
	if self.finishedFirstUpdate then
		local v139_ = g_currentMission.environment.weather:getGroundWetness()
		for _, v140_ in ipairs(v136_.wheels) do
			v140_:update(dt, v136_.currentUpdateIndex, v139_)
		end
		v136_.currentUpdateIndex = v136_.currentUpdateIndex + 1
		if v136_.currentUpdateIndex > 4 then
			v136_.currentUpdateIndex = 1
		end
		if self.isActive then
			local v141_ = g_currentMission.missionInfo.fruitDestruction
			if v141_ then
				v141_ = not self:getIsAIActive()
			end
			if v141_ then
				v141_ = self.getBlockFoliageDestruction == nil and true or not self:getBlockFoliageDestruction()
			end
			for _, v142_ in ipairs(v136_.wheels) do
				v142_.destruction:update(dt, v141_)
			end
			if self.isServer and v136_.hasAxles then
				for _, v143_ in ipairs(v136_.axles) do
					v143_:update(dt)
				end
			end
		end
		if v136_.surfaceSounds ~= nil then
			if self:getAreSurfaceSoundsActive() then
				local v144_ = self:getCurrentSurfaceSound()
				if v144_ ~= v136_.currentSurfaceSound then
					if v136_.currentSurfaceSound ~= nil then
						g_soundManager:stopSample(v136_.currentSurfaceSound)
					end
					if v144_ ~= nil then
						g_soundManager:playSample(v144_)
					end
					v136_.currentSurfaceSound = v144_
				end
			elseif v136_.currentSurfaceSound ~= nil then
				g_soundManager:stopSample(v136_.currentSurfaceSound)
				v136_.currentSurfaceSound = nil
			end
		end
		if v136_.hasSteeringNodes then
			self:updateSteeringNodes(dt)
		end
	end
	if #v136_.wheels > 0 and self.isServer then
		self:raiseDirtyFlags(v136_.dirtyFlag)
	end
end

-- Local values: spec, _, wheel
function Wheels:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local v147_ = self.spec_wheels
		for _, v148_ in ipairs(v147_.wheels) do
			v148_:postUpdate(dt)
		end
	end
end

-- Local values: spec, groundWetness, _, wheel
function Wheels:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v151_ = self.spec_wheels
	local v152_ = g_currentMission.environment.weather:getGroundWetness()
	for _, v153_ in pairs(v151_.wheels) do
		v153_:updateTick(dt, v152_, self.currentUpdateDistance)
	end
end

-- Local values: spec, _, wheel
function Wheels:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local v155_ = self.spec_wheels
		for _, v156_ in pairs(v155_.wheels) do
			v156_:onUpdateEnd()
		end
		if v155_.currentSurfaceSound ~= nil then
			g_soundManager:stopSample(v155_.currentSurfaceSound)
			v155_.currentSurfaceSound = nil
		end
	end
end

-- Local values: spec
function Wheels:loadHubsFromXML()
	self.spec_wheels.hubs = {}
	self.xmlFile:iterate("vehicle.wheels.hubs.hub", function(_, p158_)
		-- upvalues: (copy) self
		self:loadHubFromXML(self.xmlFile, p158_)
	end)
end

-- Local values: material, useDesignColorIndex, configName
function Wheels.loadHubMaterial(vehicle, xmlFile, key, hub, materialName)
	local v164_ = VehicleMaterial.new(vehicle.baseDirectory)
	if v164_:loadFromXML(xmlFile, key, vehicle.customEnvironment) then
		hub[materialName] = v164_
	end
	if xmlFile:getValue(key .. "#useBaseColor", false) then
		hub[materialName] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, "baseColor") or hub[materialName]
	elseif xmlFile:getValue(key .. "#useRimColor", false) then
		hub[materialName] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, "rimColor") or (vehicle.spec_wheels.rimMaterial or hub[materialName])
		if hub[materialName] == nil then
			hub[materialName] = VehicleMaterial.new(vehicle.baseDirectory)
			hub[materialName]:setTemplateName("RIM_DEFAULT")
			return
		end
	else
		local v165_ = xmlFile:getValue(key .. "#useDesignColorIndex")
		if v165_ ~= nil then
			local v166_ = v165_ < 2 and "designColor" or string.format("designColor%d", v165_)
			hub[materialName] = VehicleConfigurationItemColor.getMaterialByColorConfiguration(vehicle, v166_) or hub[materialName]
		end
	end
end

-- Local values: spec, linkNode, hub, hubXmlFilename, xmlFileHub, i3dFilename, arguments, sharedLoadRequestId
function Wheels:loadHubFromXML(xmlFile, key)
	local v170_ = self.spec_wheels
	local v171_ = xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings)
	if v171_ ~= nil then
		local v172_ = {
			["linkNode"] = v171_,
			["isLeft"] = xmlFile:getValue(key .. "#isLeft")
		}
		local v173_ = xmlFile:getValue(key .. "#filename")
		v172_.xmlFilename = Utils.getFilename(v173_, self.baseDirectory)
		local v174_ = XMLFile.load("wheelHubXml", v172_.xmlFilename, Wheels.xmlSchemaHub)
		if v174_ ~= nil then
			local v175_ = v174_:getValue("hub.filename")
			if v175_ == nil then
				Logging.xmlError(v174_, "Unable to retrieve hub i3d filename!")
				return
			end
			v172_.i3dFilename = Utils.getFilename(v175_, self.baseDirectory)
			Wheels.loadHubMaterial(self, xmlFile, key .. ".material", v172_, "material")
			Wheels.loadHubMaterial(self, xmlFile, key .. ".boltMaterial", v172_, "boltMaterial")
			Wheels.loadHubMaterial(self, xmlFile, key .. ".additionalMaterial", v172_, "additionalMaterial")
			Wheels.loadHubMaterial(self, xmlFile, key .. ".boltAdditionalMaterial", v172_, "boltAdditionalMaterial")
			v172_.nodeStr = v174_:getValue("hub.nodes#" .. (v172_.isLeft and "left" or "right"))
			local v176_ = self:loadSubSharedI3DFile(v172_.i3dFilename, false, false, self.onWheelHubI3DLoaded, self, {
				["hub"] = v172_,
				["linkNode"] = v171_,
				["xmlFile"] = xmlFile,
				["key"] = key
			})
			local v177_ = v170_.sharedLoadRequestIds
			table.insert(v177_, v176_)
			v174_:delete()
		end
		return true
	end
	Logging.xmlError(xmlFile, "Missing link node for hub \'%s\'", key)
end

-- Local values: spec, hub, linkNode, xmlFile, key, offset, scale
function Wheels:onWheelHubI3DLoaded(i3dNode, failedReason, args)
	local v181_ = self.spec_wheels
	local v182_ = args.hub
	local v183_ = args.linkNode
	local v184_ = args.xmlFile
	local v185_ = args.key
	if i3dNode == 0 then
		if not (self.isDeleting or self.isDeleted) then
			Logging.xmlError(v184_, "Unable to load \'%s\' in hub \'%s\'", v182_.i3dFilename, v182_.xmlFilename)
		end
		return
	else
		v182_.node = I3DUtil.indexToObject(i3dNode, v182_.nodeStr, self.i3dMappings)
		if v182_.node == nil then
			Logging.xmlError(v184_, "Could not find hub node \'%s\' in \'%s\'", v182_.nodeStr, v182_.xmlFilename)
		else
			link(v183_, v182_.node)
			delete(i3dNode)
			local v186_ = v184_:getValue(v185_ .. "#offset")
			if v186_ ~= nil then
				if not v182_.isLeft then
					v186_ = v186_ * -1
				end
				setTranslation(v182_.node, v186_, 0, 0)
			end
			local v187_ = v184_:getValue(v185_ .. "#scale", nil, true)
			if v187_ ~= nil then
				setScale(v182_.node, v187_[1], v187_[2], v187_[3])
			end
			local v188_ = v181_.hubs
			table.insert(v188_, v182_)
		end
	end
end

-- Local values: diffX, _, diffZ, rotMax, rotMin, inverted
function Wheels.getAckermannSteeringAngles(steeringNode, steeringCenterNode, maxTurningRadius)
	local v192_, _, v193_ = localToLocal(steeringNode, steeringCenterNode, 0, 0, 0)
	local v194_
	if maxTurningRadius - v192_ == 0 then
		v194_ = 1.5707963267948966 * math.sign(v193_)
	else
		local v195_ = v193_ / (maxTurningRadius - v192_)
		v194_ = math.atan(v195_)
	end
	local v196_
	if maxTurningRadius + v192_ == 0 then
		v196_ = -1.5707963267948966 * math.sign(v193_)
	else
		local v197_ = v193_ / (maxTurningRadius + v192_)
		v196_ = -math.atan(v197_)
	end
	local v198_ = v194_ < v196_
	if v198_ then
		local v199_ = v194_
		v194_ = v196_
		v196_ = v199_
	end
	return v196_, v194_, v198_
end

-- Local values: spec, key, _, rotSpeed, rotMax, centerX, centerZ, rotCenterWheel1, wheel, rotCenterWheel2, wheel2, x, _, z, centerNode, _, rotCenterWheels, x, z, numWheels, i, wheel, _x, _, _z, p, maxTurningRadius, isValid, i, wheel, diffX, _, diffZ, turningRadius, _, steeringNode, diffX, _, diffZ, turningRadius, _, wheel, rotMinI, rotMaxI, inverted, _, steeringNode, rotMinI, rotMaxI, inverted, _, wheel, rotSpeedNeg, _, steeringNode, rotSpeedNeg
function Wheels:loadAckermannSteeringFromXML(xmlFile, ackermannSteeringIndex, ackermannSteeringAngle)
	local v204_ = self.spec_wheels
	local v205_, _ = ConfigurationUtil.getXMLConfigurationKey(xmlFile, ackermannSteeringIndex, "vehicle.wheels.ackermannSteeringConfigurations.ackermannSteering", nil, "ackermann")
	v204_.steeringCenterNode = nil
	if v205_ ~= nil then
		local v206_ = xmlFile:getValue(v205_ .. "#rotSpeed")
		local v207_ = ackermannSteeringAngle or xmlFile:getValue(v205_ .. "#rotMax")
		local v208_ = nil
		local v209_ = nil
		local v210_ = xmlFile:getValue(v205_ .. "#rotCenterWheel1")
		if v210_ == nil or v204_.wheels[v210_] == nil then
			local v211_, _ = xmlFile:getValue(v205_ .. "#rotCenterNode", nil, self.components, self.i3dMappings)
			if v211_ == nil then
				local v212_ = xmlFile:getValue(v205_ .. "#rotCenterWheels", nil, true)
				if v212_ == nil or #v212_ <= 0 then
					local v213_ = xmlFile:getValue(v205_ .. "#rotCenter", nil, true)
					if v213_ ~= nil then
						v208_ = v213_[1]
						v209_ = v213_[2]
					end
				else
					local v214_ = 0
					local v215_ = 0
					local v216_ = 0
					for v217_ = 1, #v212_ do
						local v218_ = v204_.wheels[v212_[v217_]]
						if v218_ ~= nil then
							local v219_, _, v220_ = localToLocal(v218_.node, self.components[1].node, v218_.physics.positionX, 0, v218_.physics.positionZ)
							v214_ = v214_ + v219_
							v215_ = v215_ + v220_
							v216_ = v216_ + 1
						end
					end
					if v216_ > 0 then
						v208_ = v214_ / v216_
						v209_ = v215_ / v216_
					end
				end
			else
				local v221_
				v208_, v221_, v209_ = localToLocal(v211_, self.components[1].node, 0, 0, 0)
				v204_.steeringCenterNode = v211_
			end
		else
			local v222_ = v204_.wheels[v210_]
			local v223_
			v208_, v223_, v209_ = localToLocal(v222_.node, self.components[1].node, v222_.physics.positionX, v222_.physics.positionY, v222_.physics.positionZ)
			local v224_ = xmlFile:getValue(v205_ .. "#rotCenterWheel2")
			if v224_ ~= nil and v204_.wheels[v224_] ~= nil then
				if v224_ == v210_ then
					Logging.xmlWarning(xmlFile, "The ackermann steering wheels are identical (both index %d). Are you sure this is correct? (%s)", v210_, v205_)
				end
				local v225_ = v204_.wheels[v224_]
				local v226_, _, v227_ = localToLocal(v225_.node, self.components[1].node, v225_.physics.positionX, v225_.physics.positionY, v225_.physics.positionZ)
				v208_ = 0.5 * (v208_ + v226_)
				v209_ = 0.5 * (v209_ + v227_)
			end
		end
		if v204_.steeringCenterNode == nil then
			v204_.steeringCenterNode = createTransformGroup("steeringCenterNode")
			link(self.components[1].node, v204_.steeringCenterNode)
			if v208_ ~= nil and v209_ ~= nil then
				setTranslation(v204_.steeringCenterNode, v208_, 0, v209_)
			end
		end
		if v206_ ~= nil and (v207_ ~= nil and v208_ ~= nil) then
			local v228_ = math.rad(v206_)
			local v229_ = math.abs(v228_)
			local v230_ = math.rad(v207_)
			local v231_ = math.abs(v230_)
			local v232_ = 0
			local v233_ = false
			for _, v234_ in ipairs(v204_.wheels) do
				if v234_.physics.rotSpeed ~= 0 then
					local v235_, _, v236_ = localToLocal(v234_.repr, v204_.steeringCenterNode, 0, 0, 0)
					local v237_ = math.abs(v236_) / math.tan(v231_) + math.abs(v235_)
					if v232_ <= v237_ then
						v232_ = v237_
						v233_ = true
					end
				end
			end
			for _, v238_ in ipairs(v204_.steeringNodes) do
				local v239_, _, v240_ = localToLocal(v238_.node, v204_.steeringCenterNode, 0, 0, 0)
				local v241_ = math.abs(v240_) / math.tan(v231_) + math.abs(v239_)
				if v232_ <= v241_ then
					v232_ = v241_
					v233_ = true
				end
			end
			local v242_ = Utils.getNoNil(self.maxRotation, 0)
			self.maxRotation = math.max(v242_, v231_)
			self.maxTurningRadius = xmlFile:getValue(v205_ .. "#minTurningRadius", v232_)
			self.wheelSteeringDuration = v231_ / v229_
			if v233_ then
				for _, v243_ in ipairs(v204_.wheels) do
					if v243_.physics.rotSpeed ~= 0 then
						local v244_, v245_, v246_ = Wheels.getAckermannSteeringAngles(v243_.repr, v204_.steeringCenterNode, v232_)
						v243_:setSteeringValues(v244_, v245_, v245_ / self.wheelSteeringDuration, -v244_ / self.wheelSteeringDuration, v246_)
					end
				end
				for _, v247_ in ipairs(v204_.steeringNodes) do
					local v248_, v249_, v250_ = Wheels.getAckermannSteeringAngles(v247_.node, v204_.steeringCenterNode, v232_)
					v247_.rotMin = v248_
					v247_.rotMax = v249_
					v247_.rotSpeed = v249_ / self.wheelSteeringDuration
					v247_.rotSpeedNeg = -v248_ / self.wheelSteeringDuration
					if v250_ then
						local v251_ = -v247_.rotSpeedNeg
						local v252_ = -v247_.rotSpeed
						v247_.rotSpeed = v251_
						v247_.rotSpeedNeg = v252_
					end
					local v253_ = v247_.rotMin
					local v254_ = v247_.rotMax
					v247_.rotMinOrig = v253_
					v247_.rotMaxOrig = v254_
					local v255_ = v247_.rotSpeed
					local v256_ = v247_.rotSpeedNeg
					v247_.rotSpeedOrig = v255_
					v247_.rotSpeedNegOrig = v256_
				end
			end
		end
	end
	for _, v257_ in ipairs(v204_.wheels) do
		if v257_.physics.rotSpeed ~= 0 then
			if v257_.physics.rotMax >= 0 == (v257_.physics.rotSpeed >= 0) then
				local v258_ = v257_.physics.rotMax / v257_.physics.rotSpeed
				local v259_ = self.maxRotTime
				self.maxRotTime = math.max(v258_, v259_)
			end
			if v257_.physics.rotMin >= 0 == (v257_.physics.rotSpeed >= 0) then
				local v260_ = v257_.physics.rotMin / v257_.physics.rotSpeed
				local v261_ = self.maxRotTime
				self.maxRotTime = math.max(v260_, v261_)
			end
			local v262_ = v257_.physics.rotSpeedNeg
			if v262_ == nil or v262_ == 0 then
				v262_ = v257_.physics.rotSpeed
			end
			if v257_.physics.rotMax >= 0 ~= (v262_ >= 0) then
				local v263_ = v257_.physics.rotMax / v262_
				local v264_ = self.minRotTime
				self.minRotTime = math.min(v263_, v264_)
			end
			if v257_.physics.rotMin >= 0 ~= (v262_ >= 0) then
				local v265_ = v257_.physics.rotMin / v262_
				local v266_ = self.minRotTime
				self.minRotTime = math.min(v265_, v266_)
			end
		end
		if v257_.physics.rotSpeedLimit ~= nil then
			v257_.physics.rotSpeedDefault = v257_.physics.rotSpeed
			v257_.physics.rotSpeedNegDefault = v257_.physics.rotSpeedNeg
			v257_.physics.currentRotSpeedAlpha = 1
		end
	end
	for _, v267_ in ipairs(v204_.steeringNodes) do
		local v268_ = v267_.rotMax / v267_.rotSpeed
		local v269_ = self.maxRotTime
		self.maxRotTime = math.max(v268_, v269_)
		local v270_ = v267_.rotSpeedNeg
		if v270_ == nil or v270_ == 0 then
			v270_ = v267_.rotSpeed
		end
		local v271_ = v267_.rotMin / v270_
		local v272_ = self.minRotTime
		self.minRotTime = math.min(v271_, v272_)
	end
end

-- Local values: spec, i, wheelKey, wheel
function Wheels:loadWheelsFromXML(xmlFile, key, wheelConfigurationId)
	local v277_ = self.spec_wheels
	local v278_ = 0
	while true do
		local v279_ = string.format(".wheels.wheel(%d)", v278_)
		if not xmlFile:hasProperty(key .. v279_) then
			break
		end
		local v280_ = Wheel.new(self, self.xmlFile, Wheels.CONFIG_XML_PATH, v279_, v278_ + 1, wheelConfigurationId, v277_.configurationIndexToParentConfigIndex, self.baseDirectory)
		if self:loadWheelFromXML(v280_) then
			v280_:finalize()
			if v277_.isCareWheelConfiguration ~= nil then
				v280_:setIsCareWheel(v277_.isCareWheelConfiguration)
			end
			local v281_ = v277_.wheels
			table.insert(v281_, v280_)
		end
		v278_ = v278_ + 1
	end
end

function Wheels:loadWheelFromXML(wheel)
	return wheel:loadFromXML()
end

function Wheels:onLoadWheelChockFromXML(wheelChock) end

function Wheels:getIsWheelChockAllowed(wheelChock)
	return true
end

-- Local values: spec, brakeForce, _, wheel
function Wheels:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end
	local v285_ = self.spec_wheels
	local v286_ = self:getBrakeForce()
	for _, v287_ in pairs(v285_.wheels) do
		v287_:addToPhysics(v286_)
	end
	if self.isServer then
		self:brake(v286_)
	end
	return true
end

-- Local values: ret, spec, _, wheel
function Wheels:removeFromPhysics(superFunc)
	local v290_ = superFunc(self)
	if self.isServer then
		local v291_ = self.spec_wheels
		for _, v292_ in pairs(v291_.wheels) do
			v292_:removeFromPhysics()
		end
	end
	return v290_
end

-- Local values: mass, spec, _, wheel
function Wheels:getComponentMass(superFunc, component)
	local v296_ = superFunc(self, component)
	local v297_ = self.spec_wheels
	for _, v298_ in pairs(v297_.wheels) do
		if v298_.node == component.node then
			v296_ = v296_ + v298_:getMass()
		end
	end
	return v296_
end

-- Local values: slopeAngle, minWheelZ, minWheelZHeight, maxWheelZ, maxWheelZHeight, spec, i, wheel, netInfo, radius, _, _, z, _, wheelY, _, y, l
function Wheels:getVehicleWorldXRot(superFunc)
	local v301_ = self.spec_wheels
	local v302_ = math.huge
	local v303_ = -math.huge
	local v304_ = 0
	local v305_ = 0
	local v306_ = 0
	for v307_ = 1, #v301_.wheels do
		local v308_ = v301_.wheels[v307_]
		if v308_.physics.hasGroundContact then
			local v309_ = v308_.physics.netInfo
			local v310_ = v308_.physics.radius
			local _, _, v311_ = localToLocal(v308_.node, self.components[1].node, 0, 0, v309_.z)
			local _, v312_, _ = localToWorld(v308_.node, v309_.x, v309_.y - v310_, v309_.z)
			if v311_ < v302_ then
				v305_ = v312_
				v302_ = v311_
			end
			if v303_ < v311_ then
				v304_ = v312_
				v303_ = v311_
			end
		end
	end
	if v302_ ~= math.huge then
		local v313_ = v304_ - v305_
		if v313_ ~= 0 then
			local v314_ = v303_ - v302_
			if v314_ < 0.25 and superFunc ~= nil then
				return superFunc(self)
			end
			local v315_ = v314_ / v313_
			v306_ = 1.5707963267948966 - math.atan(v315_)
			if v306_ > 1.5707963267948966 then
				v306_ = v306_ - 3.141592653589793
			end
		end
	end
	return v306_
end

-- Local values: avgDirX, avgDirY, avgDirZ, _, centerZ, contactedWheels, spec, i, wheel, netInfo, _, _, z, dx, dy, dz, frontCenterX, frontCenterY, frontCenterZ, frontWheelsCount, backCenterX, backCenterY, backCenterZ, backWheelsCount, i, wheel, netInfo, radius, x, y, z, dx, dy, dz, _
function Wheels:getVehicleWorldDirection(superFunc)
	local v318_ = self.spec_wheels
	local v319_ = 0
	local v320_ = 0
	local v321_ = 0
	local v322_ = 0
	local v323_ = 0
	for v324_ = 1, #v318_.wheels do
		local v325_ = v318_.wheels[v324_]
		if v325_.physics.hasGroundContact then
			local v326_ = v325_.physics.netInfo
			local _, _, v327_ = localToLocal(v325_.node, self.components[1].node, v326_.x, v326_.y, v326_.z)
			v319_ = v319_ + v327_
			local v328_, v329_, v330_ = localDirectionToWorld(v325_.node, v325_.physics.directionZ, v325_.physics.directionX, -v325_.physics.directionY)
			v320_ = v320_ + v328_
			v321_ = v321_ + v329_
			v322_ = v322_ + v330_
			v323_ = v323_ + 1
		end
	end
	if v323_ > 0 then
		v320_ = v320_ / v323_
		local _ = v321_ / v323_
		v322_ = v322_ / v323_
	end
	if v323_ <= 2 then
		return 0, 0, 0
	end
	local v331_ = v319_ / v323_
	local v332_ = 0
	local v333_ = 0
	local v334_ = 0
	local v335_ = 0
	local v336_ = 0
	local v337_ = 0
	local v338_ = 0
	local v339_ = 0
	for v340_ = 1, #v318_.wheels do
		local v341_ = v318_.wheels[v340_]
		if v341_.physics.hasGroundContact then
			local v342_ = v341_.physics.netInfo
			local v343_ = v341_.physics.radius
			local v344_, v345_, v346_ = localToLocal(v341_.node, self.components[1].node, v342_.x + v341_.physics.directionX * v343_, v342_.y + v341_.physics.directionY * v343_, v342_.z + v341_.physics.directionZ * v343_)
			if v331_ + 0.25 < v346_ then
				v334_ = v334_ + v344_
				v335_ = v335_ + v345_
				v332_ = v332_ + v346_
				v333_ = v333_ + 1
			elseif v346_ < v331_ - 0.25 then
				v336_ = v336_ + v344_
				v337_ = v337_ + v345_
				v339_ = v339_ + v346_
				v338_ = v338_ + 1
			end
		end
	end
	if v333_ <= 0 or v338_ <= 0 then
		return superFunc(self)
	end
	local v347_ = v334_ / v333_
	local v348_ = v335_ / v333_
	local v349_ = v332_ / v333_
	local v350_ = v336_ / v338_
	local v351_ = v337_ / v338_
	local v352_ = v339_ / v338_
	local v353_, v354_, v355_ = localToWorld(self.components[1].node, v347_, v348_, v349_)
	local v356_, v357_, v358_ = localToWorld(self.components[1].node, v350_, v351_, v352_)
	if VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
		DebugGizmo.renderAtPosition(v353_, v354_, v355_, 1, 0, 0, 0, 1, 0, "frontWheels")
		DebugGizmo.renderAtPosition(v356_, v357_, v358_, 1, 0, 0, 0, 1, 0, "backWheels")
	end
	local v359_ = v353_ - v356_
	local v360_ = v354_ - v357_
	local v361_ = v355_ - v358_
	local _, v362_, _ = MathUtil.vector3Normalize(v359_, v360_, v361_)
	return MathUtil.vector3Normalize(v320_, v362_, v322_)
end

-- Local values: spec, i, wheel, wheelNode, nodeData, nodeData
function Wheels:validateWashableNode(superFunc, node)
	if self.loadingStep >= SpecializationLoadStep.FINISHED then
		local v366_ = self.spec_wheels
		for v367_ = 1, #v366_.wheels do
			local v_u_368_ = v366_.wheels[v367_]
			local v369_ = v_u_368_.driveNode
			if v_u_368_.linkNode ~= v_u_368_.driveNode then
				v369_ = v_u_368_.linkNode
			end
			if v_u_368_.wheelDirtNodes == nil then
				v_u_368_.wheelDirtNodes = {}
				I3DUtil.getNodesByShaderParam(v369_, "scratches_dirt_snow_wetness", v_u_368_.wheelDirtNodes)
			end
			if v_u_368_.wheelMudMeshes == nil then
				v_u_368_.wheelMudMeshes = {}
				I3DUtil.getNodesByShaderParam(v369_, "mudAmount", v_u_368_.wheelMudMeshes)
			end
			if v_u_368_.wheelDirtNodes[node] ~= nil then
				local v_u_379_ = {
					["wheel"] = v_u_368_,
					["fieldDirtMultiplier"] = v_u_368_.physics.fieldDirtMultiplier,
					["streetDirtMultiplier"] = v_u_368_.physics.streetDirtMultiplier,
					["waterWetnessFactor"] = v_u_368_.physics.waterWetnessFactor,
					["minDirtPercentage"] = v_u_368_.physics.minDirtPercentage,
					["maxDirtOffset"] = v_u_368_.physics.maxDirtOffset,
					["dirtColorChangeSpeed"] = v_u_368_.physics.dirtColorChangeSpeed,
					["isSnowNode"] = true,
					["loadFromSavegameFunc"] = function(p370_, p371_)
						-- upvalues: (copy) v_u_379_, (copy) self, (copy) v_u_368_
						v_u_379_.wheel.physics.snowScale = p370_:getValue(p371_ .. "#snowScale", 0)
						v_u_379_.wheel.physics.lastSnowScale = v_u_379_.wheel.physics.snowScale
						local v372_, v373_ = g_currentMission.environment:getDirtColors()
						local v374_, v375_, v376_ = MathUtil.vector3ArrayLerp(v372_, v373_, v_u_379_.wheel.physics.snowScale)
						self:setNodeDirtColor(self:getWashableNodeByCustomIndex(v_u_368_), v374_, v375_, v376_, true)
					end,
					["saveToSavegameFunc"] = function(p377_, p378_)
						-- upvalues: (copy) v_u_379_
						p377_:setValue(p378_ .. "#snowScale", v_u_379_.wheel.physics.snowScale)
					end
				}
				return false, self.updateWheelDirtAmount, v_u_368_, v_u_379_
			end
			if v_u_368_.wheelMudMeshes[node] ~= nil then
				local v380_ = {
					["wheel"] = v_u_368_,
					["fieldDirtMultiplier"] = v_u_368_.physics.fieldDirtMultiplier,
					["streetDirtMultiplier"] = v_u_368_.physics.streetDirtMultiplier,
					["waterWetnessFactor"] = v_u_368_.physics.waterWetnessFactor,
					["minDirtPercentage"] = v_u_368_.physics.minDirtPercentage,
					["maxDirtOffset"] = v_u_368_.physics.maxDirtOffset,
					["dirtColorChangeSpeed"] = v_u_368_.physics.dirtColorChangeSpeed,
					["isSnowNode"] = true,
					["cleaningMultiplier"] = 4
				}
				rotateAboutLocalAxis(node, math.random() * 3.14, 1, 0, 0)
				return false, self.updateWheelMudAmount, v_u_368_.wheelMudMeshes, v380_
			end
		end
	end
	return superFunc(self, node)
end

function Wheels:getAIDirectionNode(superFunc)
	return self.spec_wheels.steeringCenterNode or superFunc(self)
end

function Wheels:getAIRootNode(superFunc)
	return self.spec_wheels.steeringCenterNode or superFunc(self)
end

function Wheels:getSupportsMountKinematic(superFunc)
	local v387_
	if #self.spec_wheels.wheels == 0 then
		v387_ = superFunc(self)
	else
		v387_ = false
	end
	return v387_
end
function Wheels.loadBendingNodeFromXML(p388_, p389_, p390_, p391_, p392_, ...)
	if not p389_(p388_, p390_, p391_, p392_, ...) then
		return false
	end
	local v393_ = p390_:getValue(p391_ .. "#wheelIndices", nil, true)
	if v393_ ~= nil and #v393_ > 0 then
		p392_.minX = math.huge
		p392_.maxX = -math.huge
		p392_.minZ = math.huge
		p392_.maxZ = -math.huge
		for _, v394_ in ipairs(v393_) do
			local v395_ = p388_:getWheelFromWheelIndex(v394_)
			if v395_ == nil then
				Logging.xmlWarning(p390_, "Unable to find wheel index \'%s\' in \'%s\'", v394_, p391_)
			else
				local v396_, _, v397_ = localToLocal(v395_.driveNode, p392_.node, v395_.physics.wheelShapeWidth * 0.5 + 0.05 + v395_.physics.wheelShapeWidthOffset, 0, v395_.physics.radius * 0.5 + 0.05)
				local v398_, _, v399_ = localToLocal(v395_.driveNode, p392_.node, -(v395_.physics.wheelShapeWidth * 0.5 + 0.05 - v395_.physics.wheelShapeWidthOffset), 0, -(v395_.physics.radius * 0.5 + 0.05))
				local v400_ = p392_.minX
				p392_.minX = math.min(v400_, v396_, v398_)
				local v401_ = p392_.maxX
				p392_.maxX = math.max(v401_, v396_, v398_)
				local v402_ = p392_.minZ
				p392_.minZ = math.min(v402_, v397_, v399_)
				local v403_ = p392_.maxZ
				p392_.maxZ = math.max(v403_, v397_, v399_)
			end
		end
		p392_.minX = p390_:getValue(p391_ .. "#minX", p392_.minX)
		p392_.maxX = p390_:getValue(p391_ .. "#maxX", p392_.maxX)
		p392_.minZ = p390_:getValue(p391_ .. "#minZ", p392_.minZ)
		p392_.maxZ = p390_:getValue(p391_ .. "#maxZ", p392_.maxZ)
	end
	return true
end

-- Local values: changeDirt, changeWetness, dirtMultiplier, allowManipulation, physics, isOnDirtField, lastSpeed, dirtFactor, globalValue, minDirtOffset, maxDirtOffset, factor, speedFactor, lastSnowScale, defaultColor, snowColor, r, g, b
function Wheels:updateWheelDirtAmount(nodeData, dt, allowsWashingByRain, rainScale, timeSinceLastRain, temperature)
	local v409_ = self.spec_washable.lastDirtMultiplier
	local v410_ = v409_ == 0 and 0 or dt * self.spec_washable.dirtDuration * v409_
	local v411_
	if nodeData.wheel == nil or (nodeData.wheel.physics.contact ~= WheelContactType.NONE or nodeData.wheel.forceWheelDirtUpdate == true) then
		local v412_ = nodeData.wheel.physics
		local v413_ = v412_:getIsOnField()
		local v414_ = self.lastSpeed * 3600
		if v413_ then
			v410_ = v410_ * nodeData.fieldDirtMultiplier
		elseif not self.isOnField and nodeData.dirtAmount > nodeData.minDirtPercentage then
			v410_ = v410_ * (v414_ / 20 * nodeData.streetDirtMultiplier * (rainScale > 0.1 and 0.15 or 1))
		end
		if nodeData.wetness < 0.25 then
			local v415_ = self.spec_washable.washableNodes[1].dirtAmount
			local v416_ = nodeData.maxDirtOffset
			local v417_ = 1 - v415_
			local v418_ = v416_ * (math.pow(v417_, 2) * 0.75 + 0.25)
			local v419_ = nodeData.maxDirtOffset
			local v420_ = 1 - v415_
			local v421_ = v419_ * (math.pow(v420_, 2) * 0.95 + 0.05)
			if v418_ < v415_ - nodeData.dirtAmount then
				v410_ = v410_ < 0 and 0 or v410_
			else
				v410_ = v415_ - nodeData.dirtAmount < -v421_ and v410_ > 0 and 0 or v410_
			end
		end
		local v422_ = v412_.hasSnowContact and (temperature or 0) < 1 and 1 or -0.25
		local v423_ = v414_ / 5
		local v424_ = math.min(v423_, 2)
		local v425_ = v412_.snowScale + v422_ * dt * nodeData.dirtColorChangeSpeed * v424_
		local v426_ = math.max(v425_, 0)
		v412_.snowScale = math.min(v426_, 1)
		if v412_.snowScale ~= v412_.lastSnowScale then
			local v427_, v428_ = g_currentMission.environment:getDirtColors()
			local v429_, v430_, v431_ = MathUtil.vector3ArrayLerp(v427_, v428_, v412_.snowScale)
			self:setNodeDirtColor(nodeData, v429_, v430_, v431_)
			v412_.lastSnowScale = v412_.snowScale
		end
		if v412_.hasWaterContact then
			local v432_ = dt * self.spec_washable.wetDuration * nodeData.waterWetnessFactor
			local v433_ = self.lastSpeed * 3600 / 10
			v411_ = v432_ * (1 + math.min(v433_, 1))
		else
			local v434_ = -dt * self.spec_washable.dryDuration
			local v435_ = self.lastSpeed * 3600 / 10
			v411_ = v434_ * (math.min(v435_, 1) * 5)
		end
		nodeData.wheel.forceWheelDirtUpdate = false
	else
		v411_ = 0
	end
	return v410_, v411_
end

-- Local values: changeDirt, changeWetness, dirtMultiplier, lastSpeed, maxAmount, wheelDirtAmount, speedFactor, colorMud, colorWheel
function Wheels:updateWheelMudAmount(nodeData, dt, allowsWashingByRain, rainScale, timeSinceLastRain, temperature)
	local v440_ = self.spec_washable.lastDirtMultiplier
	local v441_ = v440_ == 0 and 0 or dt * self.spec_washable.dirtDuration * v440_
	if nodeData.wheelDirtNode == nil then
		nodeData.wheelDirtNode = self:getWashableNodeByCustomIndex(nodeData.wheel)
		if nodeData.wheelDirtNode == nil then
			return 0, 0
		end
	end
	if nodeData.wheel ~= nil and (nodeData.wheel.physics.contact == WheelContactType.NONE and nodeData.wheel.forceWheelDirtUpdate ~= true) then
		return 0, nodeData.wheelDirtNode.wetness - nodeData.wetness
	end
	local v442_ = self.lastSpeed * 3600
	local v443_ = (WheelEffects.MAX_MUD_AMOUNT[nodeData.wheel.physics.densityType] or 0) * (rainScale > 0.1 and 1 or 0.5)
	local v444_ = nodeData.wheelDirtNode.dirtAmount
	if nodeData.dirtAmount < v443_ and v444_ > 0.75 then
		v441_ = v441_ * nodeData.fieldDirtMultiplier * 2
	elseif v443_ < nodeData.dirtAmount or v444_ < 0.75 then
		local v445_ = v442_ / 20
		v441_ = v441_ * nodeData.streetDirtMultiplier * 2 * v445_
	end
	local v446_ = nodeData.wheelDirtNode.wetness - nodeData.wetness
	local v447_ = nodeData.color
	local v448_ = nodeData.wheelDirtNode.color
	if v447_[1] ~= v448_[1] or (v447_[2] ~= v448_[2] or v447_[3] ~= v448_[3]) then
		self:setNodeDirtColor(nodeData, v448_[1], v448_[2], v448_[3])
	end
	return v441_, v446_
end

-- Local values: spec, i
function Wheels:forceUpdateWheelPhysics(dt)
	local v450_ = self.spec_wheels
	for v451_ = 1, #v450_.wheels do
		v450_.wheels[v451_]:updatePhysics(self:getBrakeForce())
	end
end

-- Local values: spec, changedSnowScale, i
function Wheels:onWheelSnowHeightChanged(heightPct, heightAbs)
	if heightPct <= 0 then
		local v454_ = self.spec_wheels
		local v455_ = false
		for v456_ = 1, #v454_.wheels do
			if v454_.wheels[v456_].physics.snowScale > 0 then
				v454_.wheels[v456_].physics.snowScale = 0
				v454_.wheels[v456_].forceWheelDirtUpdate = true
				v455_ = true
			end
		end
		if v455_ then
			self:raiseActive()
		end
	end
end

-- Local values: spec, _, steeringNode
function Wheels:getSteeringNodeByNode(node)
	local v459_ = self.spec_wheels
	for _, v460_ in ipairs(v459_.steeringNodes) do
		if v460_.node == node then
			return v460_
		end
	end
	return nil
end

-- Local values: spec, _, steeringNode, targetSteeringAngle, direction, change, limit, direction, change, limit, _, steeringAngle, _, direction, change, limit
function Wheels:updateSteeringNodes(dt)
	local v463_ = self.spec_wheels
	for _, v464_ in ipairs(v463_.steeringNodes) do
		local v465_
		if self.rotatedTime > 0 or v464_.rotSpeedNeg == nil then
			v465_ = self.rotatedTime * v464_.rotSpeed
		else
			v465_ = self.rotatedTime * v464_.rotSpeedNeg
		end
		if v464_.rotMax < v465_ then
			v465_ = v464_.rotMax
		elseif v465_ < v464_.rotMin then
			v465_ = v464_.rotMin
		end
		if v464_.rotScale ~= v464_.rotScaleTarget then
			local v466_ = v464_.rotScaleTarget - v464_.rotScale
			local v467_ = math.sign(v466_)
			local v468_ = dt * v464_.rotScaleTargetSpeed * v467_
			v464_.rotScale = (v467_ > 0 and math.min or math.max)(v464_.rotScale + v468_, v464_.rotScaleTarget)
		end
		local v469_ = v465_ * v464_.rotScale
		if v464_.offset ~= v464_.offsetTarget then
			local v470_ = v464_.offsetTarget - v464_.offset
			local v471_ = math.sign(v470_)
			local v472_ = dt * v464_.offsetTargetSpeed * v471_
			v464_.offset = (v471_ > 0 and math.min or math.max)(v464_.offset + v472_, v464_.offsetTarget)
		end
		local v473_ = v469_ + v464_.offset
		local _, v474_, _ = getRotation(v464_.node)
		local v475_ = v474_ - v473_
		if math.abs(v475_) > 0.004 then
			local v476_ = v473_ - v474_
			local v477_ = math.sign(v476_)
			local v478_ = dt * v464_.rotChangeSpeed * 0.001 * v477_
			local v479_ = (v477_ > 0 and math.min or math.max)(v474_ + v478_, v473_)
			setRotation(v464_.node, 0, v479_, 0)
			v464_.steeringAngle = v479_
			if self.isServer and v464_.componentJoint ~= nil then
				self:setComponentJointFrame(v464_.componentJoint, 0)
			end
		end
	end
end

-- Local values: spec, numWheels, i, wheel, surfaceName, surfaceId
function Wheels:getCurrentSurfaceSound()
	local v481_ = self.spec_wheels
	local v482_ = #v481_.wheels
	for v483_, v484_ in ipairs(v481_.wheels) do
		if v484_.syncContactState or v483_ == v482_ then
			local v485_, v486_ = v484_.physics:getSurfaceSoundAttributes()
			if v485_ ~= nil then
				return v481_.surfaceNameToSound[v485_]
			end
			if v486_ ~= nil then
				return v481_.surfaceIdToSound[v486_]
			end
		end
	end
	return nil
end

function Wheels:getAreSurfaceSoundsActive()
	return self.isActiveForLocalSound
end

function Wheels:getIsVersatileYRotActive(wheel)
	return true
end

function Wheels:getWheelFromWheelIndex(wheelIndex)
	return self.spec_wheels.wheels[wheelIndex]
end

-- Local values: spec, mapping, i, wheel
function Wheels:getWheelByWheelNode(wheelNode)
	local v492_ = self.spec_wheels
	if type(wheelNode) == "string" then
		local v493_ = self.i3dMappings[wheelNode]
		if v493_ ~= nil then
			wheelNode = v493_.nodeId
		end
	end
	for v494_ = 1, #v492_.wheels do
		local v495_ = v492_.wheels[v494_]
		if v495_.repr == wheelNode or (v495_.driveNode == wheelNode or v495_.linkNode == wheelNode) then
			return v495_
		end
	end
	return nil
end

function Wheels:getWheels()
	return self.spec_wheels.wheels
end

-- Local values: spec, _, wheel
function Wheels:brake(brakePedal)
	local v499_ = self.spec_wheels
	if brakePedal ~= v499_.brakePedal then
		v499_.brakePedal = brakePedal
		for _, v500_ in pairs(v499_.wheels) do
			v500_:setBrakePedal(v499_.brakePedal)
		end
		SpecializationUtil.raiseEvent(self, "onBrake", v499_.brakePedal)
	end
end

-- Local values: spec
function Wheels:setCustomBrakeForce(brakeForce)
	self.spec_wheels.customBrakeForce = brakeForce
end

-- Local values: spec
function Wheels:getBrakeForce()
	return self.spec_wheels.customBrakeForce or 0
end

-- Local values: spec, brakeForce, _, wheel
function Wheels:onLeaveVehicle()
	local v505_ = self.spec_wheels
	if self.isServer and self.isAddedToPhysics then
		local v506_ = self:getBrakeForce()
		for _, v507_ in pairs(v505_.wheels) do
			v507_:updatePhysics(v506_, 0)
		end
	end
end

-- Local values: spec, _, wheel
function Wheels:onPreAttach()
	local v509_ = self.spec_wheels
	for _, v510_ in pairs(v509_.wheels) do
		v510_:onPreAttach()
	end
end

-- Local values: spec, _, wheel
function Wheels:onPostDetach()
	local v512_ = self.spec_wheels
	for _, v513_ in pairs(v512_.wheels) do
		v513_:onPostDetach()
	end
end

-- Local values: targetRotTime, spec, i, wheel, diffX, _, diffZ, targetRot, wheelRotTime
function Wheels:getSteeringRotTimeByCurvature(curvature)
	local v516_
	if curvature == 0 then
		v516_ = 0
	else
		local v517_ = self.spec_wheels
		local v518_ = curvature > 0 and -math.huge or math.huge
		for _, v519_ in ipairs(v517_.wheels) do
			if v519_.physics.rotSpeed ~= 0 then
				local v520_, _, v521_ = localToLocal(v519_.repr, v517_.steeringCenterNode, 0, 0, 0)
				local v522_ = v521_ * math.abs(curvature) / (1 - math.abs(curvature) * math.abs(v520_))
				local v523_ = math.atan(v522_) / v519_.physics.rotSpeed
				if curvature > 0 then
					local v524_ = -v523_
					v518_ = math.max(v518_, v524_)
				else
					v518_ = math.min(v518_, v523_)
				end
			end
		end
		v516_ = v518_ * -1
	end
	return v516_
end

-- Local values: spec, maxTurningRadius, i, wheel, wheelRot, diffX, _, diffZ, turningRadius
function Wheels:getTurningRadiusByRotTime(rotTime)
	local v527_ = self.spec_wheels
	local v528_ = math.huge
	if v527_.steeringCenterNode ~= nil then
		for _, v529_ in ipairs(v527_.wheels) do
			if v529_.physics.rotSpeed ~= 0 then
				local v530_ = rotTime * v529_.physics.rotSpeed
				local v531_ = math.abs(v530_)
				if v531_ > 0 then
					local v532_, _, v533_ = localToLocal(v529_.repr, v527_.steeringCenterNode, 0, 0, 0)
					local v534_ = math.abs(v533_) / math.tan(v531_) + math.abs(v532_)
					if v534_ < v528_ then
						v528_ = v534_
					end
				end
			end
		end
	end
	return v528_
end

function Wheels:onRegisterAnimationValueTypes()
	self:registerAnimationValueType("steeringAngle", "startSteeringAngle", "endSteeringAngle", false, AnimationValueFloat, function(p536_, p537_, p538_)
		-- upvalues: (copy) self
		p536_.wheelIndex = p537_:getValue(p538_ .. "#wheelIndex")
		p536_.wheelNode = p537_:getValue(p538_ .. "#node", nil, self.components, self.i3dMappings)
		if p536_.wheelIndex == nil and not p536_.wheelNode then
			return false
		end
		if p536_.wheelIndex == nil then
			p536_:setWarningInformation("wheelNode: " .. getName(p536_.wheelNode))
			p536_:addCompareParameters("wheelNode")
		else
			p536_:setWarningInformation("wheelIndex: " .. p536_.wheelIndex)
			p536_:addCompareParameters("wheelIndex")
		end
		return true
	end, function(p539_)
		-- upvalues: (copy) self
		if p539_.wheelIndex == nil and p539_.wheelNode == nil then
			return 0
		end
		if p539_.wheel == nil and p539_.wheelIndex ~= nil then
			p539_.wheel = self:getWheelFromWheelIndex(p539_.wheelIndex)
			if p539_.wheel == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown wheel index \'%s\' for animation part.", p539_.wheelIndex)
				p539_.wheelIndex = nil
				return 0
			end
		end
		if p539_.wheel == nil and p539_.wheelNode ~= nil then
			p539_.wheel = self:getWheelByWheelNode(p539_.wheelNode)
			if p539_.wheel == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown wheel node \'%s\' for animation part.", getName(p539_.wheelNode))
				p539_.wheelNode = nil
				return 0
			end
		end
		return p539_.wheel.physics.steeringAngle
	end, function(p540_, p541_)
		if p540_.wheel ~= nil then
			p540_.wheel.physics.steeringAngle = p541_
		end
	end)
	self:registerAnimationValueType("brakeFactor", "startBrakeFactor", "endBrakeFactor", false, AnimationValueFloat, function(p542_, p543_, p544_)
		-- upvalues: (copy) self
		p542_.wheelIndex = p543_:getValue(p544_ .. "#wheelIndex")
		p542_.wheelNode = p543_:getValue(p544_ .. "#node", nil, self.components, self.i3dMappings)
		if p542_.wheelIndex == nil and not p542_.wheelNode then
			return false
		end
		if p542_.wheelIndex == nil then
			p542_:setWarningInformation("wheelNode: " .. getName(p542_.wheelNode))
			p542_:addCompareParameters("wheelNode")
		else
			p542_:setWarningInformation("wheelIndex: " .. p542_.wheelIndex)
			p542_:addCompareParameters("wheelIndex")
		end
		return true
	end, function(p545_)
		-- upvalues: (copy) self
		if p545_.wheel == nil and p545_.wheelIndex ~= nil then
			p545_.wheel = self:getWheelFromWheelIndex(p545_.wheelIndex)
			if p545_.wheel == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown wheel index \'%s\' for animation part.", p545_.wheelIndex)
				p545_.wheelIndex = nil
				return 0
			end
		end
		if p545_.wheel == nil and p545_.wheelNode ~= nil then
			p545_.wheel = self:getWheelByWheelNode(p545_.wheelNode)
			if p545_.wheel == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown wheel node \'%s\' for animation part.", getName(p545_.wheelNode))
				p545_.wheelNode = nil
				return 0
			end
		end
		return p545_.wheel.physics.brakeFactor
	end, function(p546_, p547_)
		-- upvalues: (copy) self
		if p546_.wheel ~= nil then
			p546_.wheel.physics.brakeFactor = p547_
			p546_.wheel:updatePhysics(self:getBrakeForce())
		end
	end)
	self:registerAnimationValueType("torqueDirection", "startTorqueDirection", "endTorqueDirection", false, AnimationValueFloat, function(p548_, p549_, p550_)
		-- upvalues: (copy) self
		p548_.wheelIndex = p549_:getValue(p550_ .. "#wheelIndex")
		p548_.wheelNode = p549_:getValue(p550_ .. "#node", nil, self.components, self.i3dMappings)
		if p548_.wheelIndex == nil and not p548_.wheelNode then
			return false
		end
		if p548_.wheelIndex == nil then
			p548_:setWarningInformation("wheelNode: " .. getName(p548_.wheelNode))
			p548_:addCompareParameters("wheelNode")
		else
			p548_:setWarningInformation("wheelIndex: " .. p548_.wheelIndex)
			p548_:addCompareParameters("wheelIndex")
		end
		return true
	end, function(p551_)
		-- upvalues: (copy) self
		if p551_.wheel == nil and p551_.wheelIndex ~= nil then
			p551_.wheel = self:getWheelFromWheelIndex(p551_.wheelIndex)
			if p551_.wheel == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown wheel index \'%s\' for animation part.", p551_.wheelIndex)
				p551_.wheelIndex = nil
				return 0
			end
		end
		if p551_.wheel == nil and p551_.wheelNode ~= nil then
			p551_.wheel = self:getWheelByWheelNode(p551_.wheelNode)
			if p551_.wheel == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown wheel node \'%s\' for animation part.", getName(p551_.wheelNode))
				p551_.wheelNode = nil
				return 0
			end
		end
		return p551_.wheel.physics.torqueDirection
	end, function(p552_, p553_)
		if p552_.wheel ~= nil then
			p552_.wheel.physics:setTorqueDirection(p553_)
		end
	end)
end

function Wheels:onPostAttachImplement(object, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	SpecializationUtil.raiseEvent(self, "onBrake", self.spec_wheels.brakePedal)
end

-- Local values: spec, _, wheel
function Wheels:onAIFieldWorkerStart()
	local v556_ = self.spec_wheels
	for _, v557_ in ipairs(v556_.wheels) do
		v557_.physics:setDisplacementAllowed(false)
		v557_.physics:setDisplacementCollisionEnabled(false)
	end
end

-- Local values: spec, _, wheel
function Wheels:onAIImplementStart()
	local v559_ = self.spec_wheels
	for _, v560_ in ipairs(v559_.wheels) do
		v560_.physics:setDisplacementAllowed(false)
		v560_.physics:setDisplacementCollisionEnabled(false)
	end
end

-- Local values: spec, _, wheel
function Wheels:onAIFieldWorkerEnd()
	local v562_ = self.spec_wheels
	for _, v563_ in ipairs(v562_.wheels) do
		v563_.physics:setDisplacementAllowed(true)
		v563_.physics:setDisplacementCollisionEnabled(true)
	end
end

-- Local values: spec, _, wheel
function Wheels:onAIImplementEnd()
	local v565_ = self.spec_wheels
	for _, v566_ in ipairs(v565_.wheels) do
		v566_.physics:setDisplacementAllowed(true)
		v566_.physics:setDisplacementCollisionEnabled(true)
	end
end

-- Local values: spec, numWheels, totalDelta, _, wheel, averageDelta, maxDelta, _, wheel, delta
function Wheels:getWheelSuspensionModfier()
	local v568_ = self.spec_wheels
	local v569_ = #v568_.wheels
	if v569_ <= 0 then
		return 0
	end
	local v570_ = 0
	for _, v571_ in ipairs(v568_.wheels) do
		v570_ = v570_ + (v571_.physics.deltaY - v571_.physics.netInfo.suspensionLength)
	end
	local v572_ = v570_ / v569_
	local v573_ = 0
	for _, v574_ in ipairs(v568_.wheels) do
		local v575_ = v572_ - (v574_.physics.deltaY - v574_.physics.netInfo.suspensionLength)
		local v576_ = math.abs(v575_)
		v573_ = math.max(v576_, v573_)
	end
	return v573_
end
g_soundManager:registerModifierType("WHEEL_SUSPENSION", Wheels.getWheelSuspensionModfier)

-- Local values: spec, tireNames, _, wheel, _, dynLoadedWheel
function Wheels.getTireNames(instance)
	local v578_ = instance.spec_wheels
	if v578_ == nil then
		return nil
	else
		local v579_ = {}
		for _, v580_ in ipairs(v578_.wheels) do
			if v580_.name ~= nil then
				v579_[v580_.name] = true
			end
		end
		for _, v581_ in ipairs(v578_.dynamicallyLoadedWheels) do
			if v581_.name ~= nil then
				v579_[v581_.name] = true
			end
		end
		if table.size(v579_) == 0 then
			return nil
		else
			return v579_
		end
	end
end

-- Local values: brands, addedBrands, _, item
function Wheels.getBrands(items)
	local v583_ = {}
	local v584_ = {}
	for _, v585_ in ipairs(items) do
		if v585_.isSelectable ~= false and (v585_.wheelBrandName ~= nil and v583_[v585_.wheelBrandName] == nil) then
			local v586_ = {
				["title"] = v585_.wheelBrandName,
				["icon"] = v585_.wheelBrandIconFilename
			}
			table.insert(v584_, v586_)
			v583_[v585_.wheelBrandName] = true
		end
	end
	return v584_
end

-- Local values: wheels, _, item
function Wheels.getWheelsByBrand(items, brand)
	local v589_ = {}
	for _, v590_ in ipairs(items) do
		if v590_.isSelectable ~= false and v590_.wheelBrandName == brand.title then
			table.insert(v589_, v590_)
		end
	end
	return v589_
end

-- Local values: storeItem, configItem, configItems, i, item, i, item, configMass, configurationIndexToParentConfigIndex
function Wheels.loadSpecValueWheelWeight(xmlFile, customEnvironment, baseDir)
	local v592_ = g_storeManager:getItemByXMLFilename(xmlFile.filename)
	local v_u_593_ = nil
	if v592_.configurations ~= nil then
		local v594_ = v592_.configurations.wheel
		if v594_ ~= nil then
			for _, v595_ in ipairs(v594_) do
				if v595_.isSelectable and v595_.isDefault then
					v_u_593_ = v595_
					break
				end
			end
			if v_u_593_ == nil then
				for _, v596_ in ipairs(v594_) do
					if v596_.isSelectable then
						v_u_593_ = v596_
						break
					end
				end
			end
		end
	end
	local v_u_597_ = 0
	if v_u_593_ ~= nil then
		v_u_593_:applyGeneratedConfiguration(xmlFile)
		local v_u_598_ = Wheels.createConfigToParentConfigMapping(xmlFile)
		xmlFile:iterate(v_u_593_.configKey .. ".wheels.wheel", function(p599_, _)
			-- upvalues: (copy) xmlFile, (ref) v_u_593_, (copy) v_u_598_, (ref) v_u_597_
			local v600_ = string.format(".wheels.wheel(%d)", p599_ - 1)
			local v601_ = WheelXMLObject.new(xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", v_u_593_.index, v600_, v_u_598_)
			v601_:setXMLLoadKey("")
			local v602_ = v601_:cacheWheelMass()
			v601_:delete()
			v_u_597_ = v_u_597_ + v602_
		end)
	end
	return v_u_597_
end

function Wheels.loadSpecValueWheels(xmlFile, customEnvironment, baseDir)
	return nil
end

-- Local values: tireNames
function Wheels.getSpecValueWheels(storeItem, realItem)
	if realItem == nil then
		return nil
	else
		local v604_ = Wheels.getTireNames(realItem)
		if v604_ == nil then
			return nil
		else
			return table.concatKeys(v604_, " / ")
		end
	end
end

-- Local values: defaultConfigIndex, defaultConfigKey, visualWheelCount, usedWheels
function Wheels.getVRamUsageFromXML(xmlFile)
	if not xmlFile:hasProperty("vehicle.wheels") then
		return 0, 0
	end
	local v_u_606_ = 0
	xmlFile:iterate("vehicle.wheels.wheelConfigurations.wheelConfiguration", function(p607_, p608_)
		-- upvalues: (copy) xmlFile, (ref) v_u_606_
		if xmlFile:getValue(p608_ .. "#isDefault") then
			v_u_606_ = p607_
			return false
		end
	end)
	local v609_ = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", v_u_606_)
	local v_u_610_ = 0
	local v_u_611_ = {}
	xmlFile:iterate(v609_ .. ".wheels.wheel", function(_, p612_)
		-- upvalues: (copy) xmlFile, (copy) v_u_611_, (ref) v_u_610_
		local v613_ = xmlFile:getString(p612_ .. "#filename")
		if v613_ ~= nil and v_u_611_[v613_] == nil then
			v_u_610_ = v_u_610_ + 1
			v_u_611_[v613_] = true
		end
	end)
	return v_u_610_ * Wheels.VRAM_PER_WHEEL, 0
end

-- Local values: configurationSaveIdToIndex, configurationIndexToParentConfigIndex
function Wheels.createConfigToParentConfigMapping(xmlFile)
	local v_u_615_ = {}
	local v_u_616_ = {}
	xmlFile:iterate("vehicle.wheels.wheelConfigurations.wheelConfiguration", function(p617_, p618_)
		-- upvalues: (copy) xmlFile, (copy) v_u_615_
		v_u_615_[xmlFile:getValue(p618_ .. "#saveId", (tostring(p617_)))] = p617_
	end)
	xmlFile:iterate("vehicle.wheels.wheelConfigurations.wheelConfiguration", function(p619_, p620_)
		-- upvalues: (copy) xmlFile, (copy) v_u_615_, (copy) v_u_616_
		XMLUtil.checkDeprecatedXMLElements(xmlFile, p620_ .. ".wheels.foliageBendingModifier", p620_ .. ".foliageBendingModifier")
		local v621_ = xmlFile:getValue(p620_ .. ".wheels#baseConfig")
		if v621_ ~= nil then
			local v622_ = v_u_615_[v621_]
			if p619_ == v622_ then
				Logging.xmlError(xmlFile, "Wheel configuration %s references itself as baseConfig! Ignoring this reference", p620_)
				return
			end
			v_u_616_[p619_] = v622_
		end
	end)
	return v_u_616_
end
