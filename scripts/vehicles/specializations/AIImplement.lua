AIImplement = {}

function AIImplement.prerequisitesPresent(self)
	return true
end
function AIImplement.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("ai", g_i18n:getText("configuration_design"), "ai", VehicleConfigurationItem)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("AIImplement")
	AIImplement.registerAIImplementXMLPaths(v1_, "vehicle.ai")
	AIImplement.registerAIImplementXMLPaths(v1_, "vehicle.ai.aiConfigurations.aiConfiguration(?)")
	v1_:setXMLSpecializationType()
end

function AIImplement.registerAIImplementXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. ".minTurningRadius#value", "Min turning radius")
	AIImplement.registerAIImplementBaseXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. ".needsLowering#value", "AI needs to lower this tool", true)
	schema:register(XMLValueType.BOOL, basePath .. ".needsLowering#lowerIfAnyIsLowered", "Lower tool of any attached ai tool is lowered", false)
	schema:register(XMLValueType.BOOL, basePath .. ".needsRootAlignment#value", "Tool needs to point in the same direction as the root while working", true)
	schema:register(XMLValueType.BOOL, basePath .. ".allowTurnBackward#value", "Worker is allowed the turn backward with this tool", true)
	schema:register(XMLValueType.FLOAT, basePath .. ".allowTurnBackward#straighteningSegmentLength", "Controls the length of the extra straightening segment after the turn to get the tool straight again")
	schema:register(XMLValueType.BOOL, basePath .. ".allowTurnBackward#straighteningAlwaysActive", "Additional straightening segment is also added when we are allowed to turn backward, to make sure we are correctly in the line", false)
	schema:register(XMLValueType.BOOL, basePath .. ".blockTurnBackward#value", "Can be used for non ai tools to block ai from driving backward", false)
	schema:register(XMLValueType.BOOL, basePath .. ".isVineyardTool#value", "Field work AI for this tool can only be used in vine yards", false)
	schema:register(XMLValueType.BOOL, basePath .. ".isVineyardTool#betweenRows", "Defines if the tool is used to work between the vine yard rows", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".toolReverserDirectionNode#node", "Reverser direction node, target node if driving backward")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".turningRadiusLimitation#rotationJointNode", "Turn radius limitation joint node")
	schema:register(XMLValueType.VECTOR_N, basePath .. ".turningRadiusLimitation#wheelIndices", "Turn radius limitation wheel indices")
	schema:register(XMLValueType.FLOAT, basePath .. ".turningRadiusLimitation#radius", "Turn radius limitation radius")
	schema:register(XMLValueType.FLOAT, basePath .. ".turningRadiusLimitation#initialTurnRadiusFactor", "Increase or decrease the turn radius while the tool is still folded (initial drive to the first segment)", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".turningRadiusLimitation#rotLimitFactor", "Changes the rot limit of attacher joint or component joint for turning radius calculation", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".lookAheadSize#value", "Look a head size to check ground in front of tool", 3)
	schema:register(XMLValueType.BOOL, basePath .. ".useAttributesOfAttachedImplement#value", "Use AI attributes (area & fruit/ground requirements) of first attached implement", false)
	schema:register(XMLValueType.BOOL, basePath .. ".hasNoFullCoverageArea#value", "Tool as a no full coverage area (e.g. plows)", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".hasNoFullCoverageArea#offset", "Non full coverage area offset", 0)
	schema:register(XMLValueType.BOOL, basePath .. ".headlandTailAvoidance#enabled", "Course generation setting to help long vehicles to stay inside field boundaries (sugarbeet harvesters for example)", false)
	schema:register(XMLValueType.INT, basePath .. ".headland#minNumHeadlands", "Try to use this amount of headlands at least")
	schema:register(XMLValueType.BOOL, basePath .. ".headland#cornerCutOutSupported", "Use corner cut out in the corners of the headland", "Defined by vehicle type")
	schema:register(XMLValueType.INT, basePath .. ".headland#forcedDirection", "Forces a fixed direction for headlands. Starting headland loop direction still depends on the vehicle orientation. (1: clockwise, -1: counter-clockwise, 0: any)", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".overlap#value", "Defines the ai line to line overlap", AIVehicleUtil.AREA_OVERLAP)
	schema:register(XMLValueType.STRING, basePath .. ".rowAlignment#fruitTypeName", "AI lines snap to the crop spacing of this type")
	schema:register(XMLValueType.FLOAT, basePath .. ".rowAlignment#spacing", "Spacing between the rows to snap to in meter (if fruitTypeName is not defined)")
	schema:register(XMLValueType.ANGLE, basePath .. ".rowAlignment#snapAngle", "Snap the lines to this angle in degrees (if fruitTypeName is not defined)")
	schema:register(XMLValueType.FLOAT, basePath .. ".rowAlignment#offset", "Side offset in the row for this tool", 0)
end

function AIImplement.registerAIImplementBaseXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".areaMarkers#leftNode", "AI area left node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".areaMarkers#rightNode", "AI area right node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".areaMarkers#backNode", "AI area back node")
	schema:register(XMLValueType.FLOAT, basePath .. ".areaMarkers#sideOffset", "Side offset of the ai markers to the center of the leading vehicle", 0)
	schema:register(XMLValueType.BOOL, basePath .. ".areaMarkers#sideOffsetHeadlandAlternate", "Alternate the side offset during headland work", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".areaMarkers#width", "Working width of the ai implement", "automatically calculated based on distance between ai markers while activating the ai")
	schema:register(XMLValueType.FLOAT, basePath .. ".areaMarkers#validityOffset", "Side offset on the validity checks of the segments", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".sizeMarkers#leftNode", "Size area left node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".sizeMarkers#rightNode", "Size area right node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".sizeMarkers#backNode", "Size area back node")
	AIImplement.registerAICollisionTriggerXMLPaths(schema, basePath)
end

function AIImplement.registerAICollisionTriggerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. ".collisionTrigger#useSize", "Use vehicle size box to calculate the ai collision box (will be placed in front of it)", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".collisionTrigger#node", "Collision trigger node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".collisionTrigger#backNode", "Collision trigger node while driving backwards (Z-Axis pointing backwards)")
	schema:register(XMLValueType.FLOAT, basePath .. ".collisionTrigger#width", "Width of ai collision trigger", 4)
	schema:register(XMLValueType.FLOAT, basePath .. ".collisionTrigger#height", "Width of ai collision trigger", 3)
	schema:register(XMLValueType.FLOAT, basePath .. ".collisionTrigger#length", "Max. length of ai collision trigger", 5)
end

function AIImplement.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementStart")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementActive")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementEnd")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementPrepareForWork")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementStartLine")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementEndLine")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementStartTurn")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementTurnProgress")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementEndTurn")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementSideOffsetChanged")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementBlock")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementContinue")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementPrepareForTransport")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementJobVehicleBlock")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementJobVehicleContinue")
end

function AIImplement.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadAICollisionTriggerFromXML", AIImplement.loadAICollisionTriggerFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadAIImplementBaseSetupFromXML", AIImplement.loadAIImplementBaseSetupFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getCustomAIImplementBaseSetup", AIImplement.getCustomAIImplementBaseSetup)
	SpecializationUtil.registerFunction(vehicleType, "getCanAIImplementContinueWork", AIImplement.getCanAIImplementContinueWork)
	SpecializationUtil.registerFunction(vehicleType, "getCanImplementBeUsedForAI", AIImplement.getCanImplementBeUsedForAI)
	SpecializationUtil.registerFunction(vehicleType, "getAIMinTurningRadius", AIImplement.getAIMinTurningRadius)
	SpecializationUtil.registerFunction(vehicleType, "getAIMarkers", AIImplement.getAIMarkers)
	SpecializationUtil.registerFunction(vehicleType, "updateAIMarkerWidth", AIImplement.updateAIMarkerWidth)
	SpecializationUtil.registerFunction(vehicleType, "setAIMarkersInverted", AIImplement.setAIMarkersInverted)
	SpecializationUtil.registerFunction(vehicleType, "calcAIMarkerAttacherJointOffset", AIImplement.calcAIMarkerAttacherJointOffset)
	SpecializationUtil.registerFunction(vehicleType, "getAIMarkerAttacherJointOffset", AIImplement.getAIMarkerAttacherJointOffset)
	SpecializationUtil.registerFunction(vehicleType, "getAIInvertMarkersOnTurn", AIImplement.getAIInvertMarkersOnTurn)
	SpecializationUtil.registerFunction(vehicleType, "getAISizeMarkers", AIImplement.getAISizeMarkers)
	SpecializationUtil.registerFunction(vehicleType, "getAILookAheadSize", AIImplement.getAILookAheadSize)
	SpecializationUtil.registerFunction(vehicleType, "getAIHasNoFullCoverageArea", AIImplement.getAIHasNoFullCoverageArea)
	SpecializationUtil.registerFunction(vehicleType, "getAIAreaOverlap", AIImplement.getAIAreaOverlap)
	SpecializationUtil.registerFunction(vehicleType, "getAIRowAlignment", AIImplement.getAIRowAlignment)
	SpecializationUtil.registerFunction(vehicleType, "getImplementAllowAutomaticSteering", AIImplement.getImplementAllowAutomaticSteering)
	SpecializationUtil.registerFunction(vehicleType, "getAIImplementCollisionTrigger", AIImplement.getAIImplementCollisionTrigger)
	SpecializationUtil.registerFunction(vehicleType, "getAIImplementCollisionTriggers", AIImplement.getAIImplementCollisionTriggers)
	SpecializationUtil.registerFunction(vehicleType, "getAINeedsLowering", AIImplement.getAINeedsLowering)
	SpecializationUtil.registerFunction(vehicleType, "getAILowerIfAnyIsLowered", AIImplement.getAILowerIfAnyIsLowered)
	SpecializationUtil.registerFunction(vehicleType, "getAINeedsRootAlignment", AIImplement.getAINeedsRootAlignment)
	SpecializationUtil.registerFunction(vehicleType, "getAIAllowTurnBackward", AIImplement.getAIAllowTurnBackward)
	SpecializationUtil.registerFunction(vehicleType, "getAIBlockTurnBackward", AIImplement.getAIBlockTurnBackward)
	SpecializationUtil.registerFunction(vehicleType, "getAIIsVineyardTool", AIImplement.getAIIsVineyardTool)
	SpecializationUtil.registerFunction(vehicleType, "getAIToolReverserDirectionNode", AIImplement.getAIToolReverserDirectionNode)
	SpecializationUtil.registerFunction(vehicleType, "getAITurnRadiusLimitation", AIImplement.getAITurnRadiusLimitation)
	SpecializationUtil.registerFunction(vehicleType, "setAIImplementVariableSideOffset", AIImplement.setAIImplementVariableSideOffset)
	SpecializationUtil.registerFunction(vehicleType, "getAIImplementSideOffset", AIImplement.getAIImplementSideOffset)
	SpecializationUtil.registerFunction(vehicleType, "setAIFruitProhibitions", AIImplement.setAIFruitProhibitions)
	SpecializationUtil.registerFunction(vehicleType, "addAIFruitProhibitions", AIImplement.addAIFruitProhibitions)
	SpecializationUtil.registerFunction(vehicleType, "clearAIFruitProhibitions", AIImplement.clearAIFruitProhibitions)
	SpecializationUtil.registerFunction(vehicleType, "getAIFruitProhibitions", AIImplement.getAIFruitProhibitions)
	SpecializationUtil.registerFunction(vehicleType, "setAIFruitRequirements", AIImplement.setAIFruitRequirements)
	SpecializationUtil.registerFunction(vehicleType, "addAIFruitRequirement", AIImplement.addAIFruitRequirement)
	SpecializationUtil.registerFunction(vehicleType, "clearAIFruitRequirements", AIImplement.clearAIFruitRequirements)
	SpecializationUtil.registerFunction(vehicleType, "getAIFruitRequirements", AIImplement.getAIFruitRequirements)
	SpecializationUtil.registerFunction(vehicleType, "setAIDensityHeightTypeRequirements", AIImplement.setAIDensityHeightTypeRequirements)
	SpecializationUtil.registerFunction(vehicleType, "addAIDensityHeightTypeRequirement", AIImplement.addAIDensityHeightTypeRequirement)
	SpecializationUtil.registerFunction(vehicleType, "clearAIDensityHeightTypeRequirements", AIImplement.clearAIDensityHeightTypeRequirements)
	SpecializationUtil.registerFunction(vehicleType, "getAIDensityHeightTypeRequirements", AIImplement.getAIDensityHeightTypeRequirements)
	SpecializationUtil.registerFunction(vehicleType, "getAIImplementUseVineSegment", AIImplement.getAIImplementUseVineSegment)
	SpecializationUtil.registerFunction(vehicleType, "addAITerrainDetailRequiredRange", AIImplement.addAITerrainDetailRequiredRange)
	SpecializationUtil.registerFunction(vehicleType, "addAIGroundTypeRequirements", AIImplement.addAIGroundTypeRequirements)
	SpecializationUtil.registerFunction(vehicleType, "clearAITerrainDetailRequiredRange", AIImplement.clearAITerrainDetailRequiredRange)
	SpecializationUtil.registerFunction(vehicleType, "getAITerrainDetailRequiredRange", AIImplement.getAITerrainDetailRequiredRange)
	SpecializationUtil.registerFunction(vehicleType, "addAITerrainDetailProhibitedRange", AIImplement.addAITerrainDetailProhibitedRange)
	SpecializationUtil.registerFunction(vehicleType, "clearAITerrainDetailProhibitedRange", AIImplement.clearAITerrainDetailProhibitedRange)
	SpecializationUtil.registerFunction(vehicleType, "getAITerrainDetailProhibitedRange", AIImplement.getAITerrainDetailProhibitedRange)
	SpecializationUtil.registerFunction(vehicleType, "getFieldCropsQuery", AIImplement.getFieldCropsQuery)
	SpecializationUtil.registerFunction(vehicleType, "updateFieldCropsQuery", AIImplement.updateFieldCropsQuery)
	SpecializationUtil.registerFunction(vehicleType, "compareFieldCropsQuery", AIImplement.compareFieldCropsQuery)
	SpecializationUtil.registerFunction(vehicleType, "createFieldCropsQuery", AIImplement.createFieldCropsQuery)
	SpecializationUtil.registerFunction(vehicleType, "getIsAIImplementInLine", AIImplement.getIsAIImplementInLine)
	SpecializationUtil.registerFunction(vehicleType, "aiImplementStartLine", AIImplement.aiImplementStartLine)
	SpecializationUtil.registerFunction(vehicleType, "aiImplementEndLine", AIImplement.aiImplementEndLine)
end

function AIImplement.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addVehicleToAIImplementList", AIImplement.addVehicleToAIImplementList)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowTireTracks", AIImplement.getAllowTireTracks)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", AIImplement.getDoConsumePtoPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "checkMovingPartDirtyUpdateNode", AIImplement.checkMovingPartDirtyUpdateNode)
end

function AIImplement.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIImplement)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIImplement)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAIFieldCourseSettingsInitialized", AIImplement)
end

-- Local values: spec, baseName, aiConfigurationId, configKey, spacing, snapAngle, foliageOffset, fruitTypeName, fruitTypeDesc, _
function AIImplement:onLoad(savegame)
	local v13_ = self.spec_aiImplement
	local v14_ = "vehicle.ai"
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v14_ .. ".areaMarkers#leftIndex", v14_ .. ".areaMarkers#leftNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v14_ .. ".areaMarkers#rightIndex", v14_ .. ".areaMarkers#rightNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v14_ .. ".areaMarkers#backIndex", v14_ .. ".areaMarkers#backNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v14_ .. ".sizeMarkers#leftIndex", v14_ .. ".sizeMarkers#leftNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v14_ .. ".sizeMarkers#rightIndex", v14_ .. ".sizeMarkers#rightNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v14_ .. ".sizeMarkers#backIndex", v14_ .. ".sizeMarkers#backNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v14_ .. ".trafficCollisionTrigger#index", v14_ .. ".collisionTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v14_ .. ".trafficCollisionTrigger#node", v14_ .. ".collisionTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v14_ .. ".collisionTrigger#index", v14_ .. ".collisionTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.aiLookAheadSize#value", v14_ .. ".lookAheadSize#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v14_ .. ".toolReverserDirectionNode#index", v14_ .. ".toolReverserDirectionNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v14_ .. ".turningRadiusLimiation", v14_ .. ".turningRadiusLimitation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v14_ .. ".forceTurnNoBackward#value", v14_ .. ".allowTurnBackward#value (inverted)")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, v14_ .. ".needsLowering#lowerIfAnyIsLowerd", v14_ .. ".allowTurnBackward#lowerIfAnyIsLowered")
	local v15_ = Utils.getNoNil(self.configurations.ai, 1)
	local v16_ = string.format("vehicle.ai.aiConfigurations.aiConfiguration(%d)", v15_ - 1)
	if self.xmlFile:hasProperty(v16_) then
		v14_ = v16_
	end
	v13_.minTurningRadius = self.xmlFile:getValue(v14_ .. ".minTurningRadius#value")
	v13_.inputAttacherJointToMarkerOffset = {}
	v13_.aiBaseSetups = {}
	self:loadAIImplementBaseSetupFromXML(self.xmlFile, v14_, nil)
	v13_.needsLowering = self.xmlFile:getValue(v14_ .. ".needsLowering#value", true)
	v13_.lowerIfAnyIsLowered = self.xmlFile:getValue(v14_ .. ".needsLowering#lowerIfAnyIsLowered", false)
	v13_.needsRootAlignment = self.xmlFile:getValue(v14_ .. ".needsRootAlignment#value", true)
	v13_.allowTurnBackward = self.xmlFile:getValue(v14_ .. ".allowTurnBackward#value", true)
	v13_.blockTurnBackward = self.xmlFile:getValue(v14_ .. ".blockTurnBackward#value", false)
	v13_.straighteningSegmentLength = self.xmlFile:getValue(v14_ .. ".allowTurnBackward#straighteningSegmentLength")
	v13_.straighteningAlwaysActive = self.xmlFile:getValue(v14_ .. ".allowTurnBackward#straighteningAlwaysActive", false)
	v13_.isVineyardTool = self.xmlFile:getValue(v14_ .. ".isVineyardTool#value", false)
	v13_.isVineyardToolBetweenRows = self.xmlFile:getValue(v14_ .. ".isVineyardTool#betweenRows", false)
	v13_.toolReverserDirectionNode = self.xmlFile:getValue(v14_ .. ".toolReverserDirectionNode#node", nil, self.components, self.i3dMappings)
	v13_.turningRadiusLimitation = {}
	v13_.turningRadiusLimitation.rotationJoint = self.xmlFile:getValue(v14_ .. ".turningRadiusLimitation#rotationJointNode", nil, self.components, self.i3dMappings)
	if v13_.turningRadiusLimitation.rotationJoint ~= nil then
		v13_.turningRadiusLimitation.wheelIndices = self.xmlFile:getValue(v14_ .. ".turningRadiusLimitation#wheelIndices", nil, true)
	end
	v13_.turningRadiusLimitation.radius = self.xmlFile:getValue(v14_ .. ".turningRadiusLimitation#radius")
	v13_.turningRadiusLimitation.initialTurnRadiusFactor = self.xmlFile:getValue(v14_ .. ".turningRadiusLimitation#initialTurnRadiusFactor")
	v13_.turningRadiusLimitation.rotLimitFactor = self.xmlFile:getValue(v14_ .. ".turningRadiusLimitation#rotLimitFactor", 1)
	v13_.lookAheadSize = self.xmlFile:getValue(v14_ .. ".lookAheadSize#value", 3)
	v13_.useAttributesOfAttachedImplement = self.xmlFile:getValue(v14_ .. ".useAttributesOfAttachedImplement#value", false)
	v13_.hasNoFullCoverageArea = self.xmlFile:getValue(v14_ .. ".hasNoFullCoverageArea#value", false)
	v13_.hasNoFullCoverageAreaOffset = self.xmlFile:getValue(v14_ .. ".hasNoFullCoverageArea#offset", 0)
	v13_.headlandTailAvoidanceEnabled = self.xmlFile:getValue(v14_ .. ".headlandTailAvoidance#enabled", false)
	v13_.minNumHeadlands = self.xmlFile:getValue(v14_ .. ".headland#minNumHeadlands")
	v13_.cornerCutOutSupported = self.xmlFile:getValue(v14_ .. ".headland#cornerCutOutSupported")
	v13_.headlandForcedDirection = self.xmlFile:getValue(v14_ .. ".headland#forcedDirection", 1)
	v13_.overlap = self.xmlFile:getValue(v14_ .. ".overlap#value")
	local v17_ = nil
	local v18_ = nil
	local v19_ = nil
	local v20_ = self.xmlFile:getValue(v14_ .. ".rowAlignment#fruitTypeName")
	if v20_ ~= nil then
		local v21_ = g_fruitTypeManager:getFruitTypeByName(v20_)
		if v21_ == nil then
			Logging.xmlWarning(self.xmlFile, "Unknown fruit type \'%s\' defined in \'%s\'", v20_, v14_ .. ".rowAlignment#fruitTypeName")
		else
			v17_ = v21_.plantSpacing
			if v21_.directionSnapAngle ~= 0 then
				v18_ = v21_.directionSnapAngle
			end
			if v21_.plantOffset ~= nil then
				v19_ = v21_.plantOffset[1]
			end
		end
	end
	local v22_ = self.xmlFile:getValue(v14_ .. ".rowAlignment#spacing", v17_)
	if v22_ ~= nil then
		v13_.rowAlignment = {}
		v13_.rowAlignment.spacing = v22_
		v13_.rowAlignment.snapAngle = self.xmlFile:getValue(v14_ .. ".rowAlignment#snapAngle") or (v18_ or 0)
		v13_.rowAlignment.offset = self.xmlFile:getValue(v14_ .. ".rowAlignment#offset", 0) + (v19_ or 0)
	end
	v13_.terrainDetailRequiredValueRanges = {}
	v13_.terrainDetailProhibitedValueRanges = {}
	v13_.requiredFruitTypes = {}
	v13_.prohibitedFruitTypes = {}
	v13_.requiredDensityHeightTypes = {}
	v13_.fieldGroundSystem = g_currentMission.fieldGroundSystem
	local _, v23_, v24_ = v13_.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	v13_.groundTypeFirstChannel = v23_
	v13_.groundTypeNumChannels = v24_
	v13_.fieldCropyQuery = nil
	v13_.fieldCropyQueryValid = false
	v13_.isLineStarted = false
end

-- Local values: spec, wheels, _, index, wheel, _, aiBaseSetup
function AIImplement:onPostLoad(savegame)
	local v26_ = self.spec_aiImplement
	if self.getWheels ~= nil and v26_.turningRadiusLimitation.wheelIndices ~= nil then
		v26_.turningRadiusLimitation.wheels = {}
		local v27_ = self:getWheels()
		for _, v28_ in ipairs(v26_.turningRadiusLimitation.wheelIndices) do
			if v27_[v28_] == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown wheel index \'%s\' defined in \'%s\'", v28_, "vehicle.ai.turningRadiusLimitation#wheelIndices")
			else
				local v29_ = v26_.turningRadiusLimitation.wheels
				local v30_ = v27_[v28_]
				table.insert(v29_, v30_)
			end
		end
	end
	if v26_.leftMarker ~= nil and v26_.backMarker ~= nil then
		self:calcAIMarkerAttacherJointOffset(v26_.leftMarker, v26_.rightMarker, v26_.backMarker)
	end
	if v26_.aiBaseSetups ~= nil then
		for _, v31_ in ipairs(v26_.aiBaseSetups) do
			if v31_.leftMarker ~= nil and v31_.backMarker ~= nil then
				self:calcAIMarkerAttacherJointOffset(v31_.leftMarker, v31_.rightMarker, v31_.backMarker)
			end
		end
	end
end

-- Local values: spec, aiSetup
function AIImplement:onPostAIFieldCourseSettingsInitialized(fieldCourseSettings)
	local v34_ = self.spec_aiImplement
	if v34_.isVineyardTool then
		fieldCourseSettings.isVineyardTool = true
	end
	if v34_.isVineyardToolBetweenRows then
		fieldCourseSettings.isVineyardRowTool = true
	end
	if v34_.headlandTailAvoidanceEnabled then
		fieldCourseSettings.headlandTailAvoidance = true
	end
	if v34_.straighteningSegmentLength ~= nil then
		fieldCourseSettings.toolStraighteningSegmentLength = v34_.straighteningSegmentLength
	end
	if v34_.straighteningAlwaysActive then
		fieldCourseSettings.toolStraighteningAlwaysActive = true
	end
	local v35_ = self:getCustomAIImplementBaseSetup()
	if v35_ == nil or v35_.sideOffsetHeadlandAlternate == nil then
		v35_ = v34_
	end
	if v35_.sideOffsetHeadlandAlternate ~= nil then
		fieldCourseSettings.sideOffsetHeadlandAlternate = v35_.sideOffsetHeadlandAlternate
	end
	if v34_.minNumHeadlands ~= nil then
		local v36_ = v34_.minNumHeadlands
		local v37_ = fieldCourseSettings.numHeadlands
		fieldCourseSettings.numHeadlands = math.max(v36_, v37_)
	end
	if v34_.cornerCutOutSupported ~= nil then
		fieldCourseSettings.cornerCutOutSupported = v34_.cornerCutOutSupported
	end
	if v34_.headlandForcedDirection ~= 0 then
		fieldCourseSettings.headlandForcedDirection = v34_.headlandForcedDirection
	end
end

-- Local values: collisionTrigger, linkNode
function AIImplement:loadAICollisionTriggerFromXML(xmlFile, key)
	local v41_ = {
		["node"] = xmlFile:getValue(key .. ".collisionTrigger#node", nil, self.components, self.i3dMappings)
	}
	if v41_.node == nil then
		if not xmlFile:getValue(key .. ".collisionTrigger#useSize", false) then
			return nil
		end
		v41_.node = createTransformGroup("aiCollisionTrigger")
		link(self.rootNode, v41_.node)
		setTranslation(v41_.node, self.size.widthOffset, 0, self.size.length * 0.5 + self.size.lengthOffset)
		v41_.width = xmlFile:getValue(key .. ".collisionTrigger#width", self.size.width)
		v41_.height = xmlFile:getValue(key .. ".collisionTrigger#height", self.size.height)
		v41_.length = xmlFile:getValue(key .. ".collisionTrigger#length", 5)
		v41_.backNode = createTransformGroup("aiCollisionNodeBack")
		link(self.rootNode, v41_.backNode)
		setTranslation(v41_.backNode, self.size.widthOffset, 0, -self.size.length * 0.5 + self.size.lengthOffset)
		setRotation(v41_.backNode, 0, 3.141592653589793, 0)
		return v41_
	else
		if getHasClassId(v41_.node, ClassIds.SHAPE) then
			Logging.xmlWarning(xmlFile, "Obsolete ai collision trigger ground. Please replace with empty transform group and add size attributes. \'%s\'", key .. ".collisionTrigger#node")
		end
		v41_.width = xmlFile:getValue(key .. ".collisionTrigger#width", 4)
		v41_.height = xmlFile:getValue(key .. ".collisionTrigger#height", 3)
		v41_.length = xmlFile:getValue(key .. ".collisionTrigger#length", 5)
		v41_.backNode = xmlFile:getValue(key .. ".collisionTrigger#backNode", nil, self.components, self.i3dMappings)
		if v41_.backNode ~= nil then
			return v41_
		end
		local v42_ = self.spec_aiImplement.backMarker or (self.spec_aiImplement.sizeBackMarker or self.rootNode)
		v41_.backNode = createTransformGroup("aiCollisionNodeBack")
		link(v42_, v41_.backNode)
		setTranslation(v41_.backNode, self.size.widthOffset, 0, -self.size.length * 0.5 + self.size.lengthOffset)
		setRotation(v41_.backNode, 0, 3.141592653589793, 0)
		return v41_
	end
end

-- Local values: target
function AIImplement:loadAIImplementBaseSetupFromXML(xmlFile, key, availableFunc)
	local v47_ = self.spec_aiImplement
	local v48_ = availableFunc ~= nil and {} or v47_
	v48_.leftMarker = xmlFile:getValue(key .. ".areaMarkers#leftNode", nil, self.components, self.i3dMappings)
	v48_.rightMarker = xmlFile:getValue(key .. ".areaMarkers#rightNode", nil, self.components, self.i3dMappings)
	v48_.backMarker = xmlFile:getValue(key .. ".areaMarkers#backNode", nil, self.components, self.i3dMappings)
	v48_.aiMarkersInverted = false
	v48_.sideOffset = xmlFile:getValue(key .. ".areaMarkers#sideOffset")
	v48_.sideOffsetHeadlandAlternate = xmlFile:getValue(key .. ".areaMarkers#sideOffsetHeadlandAlternate")
	v48_.aiMarkerWidth = xmlFile:getValue(key .. ".areaMarkers#width")
	v48_.aiMarkerValidityOffset = xmlFile:getValue(key .. ".areaMarkers#validityOffset")
	v48_.variableSideOffset = false
	if v48_.aiMarkerWidth == nil then
		if v48_.leftMarker == nil or v48_.rightMarker == nil then
			v48_.aiMarkerWidth = 0
		else
			v48_.aiMarkerWidth = calcDistanceFrom(v48_.leftMarker, v48_.rightMarker)
		end
	end
	v48_.sizeLeftMarker = xmlFile:getValue(key .. ".sizeMarkers#leftNode", nil, self.components, self.i3dMappings)
	v48_.sizeRightMarker = xmlFile:getValue(key .. ".sizeMarkers#rightNode", nil, self.components, self.i3dMappings)
	v48_.sizeBackMarker = xmlFile:getValue(key .. ".sizeMarkers#backNode", nil, self.components, self.i3dMappings)
	v48_.collisionTrigger = self:loadAICollisionTriggerFromXML(xmlFile, key)
	if availableFunc ~= nil then
		v48_.availableFunc = availableFunc
		local v49_ = self.spec_aiImplement.aiBaseSetups
		table.insert(v49_, v48_)
	end
	return true
end

-- Local values: spec, _, aiBaseSetup
function AIImplement:getCustomAIImplementBaseSetup()
	local v51_ = self.spec_aiImplement
	for _, v52_ in ipairs(v51_.aiBaseSetups) do
		if v52_.availableFunc(self) then
			return v52_
		end
	end
	return nil
end

function AIImplement:getCanAIImplementContinueWork(isTurning)
	return true, false, nil
end

-- Local values: leftMarker, rightMarker, backMarker, _, _
function AIImplement:getCanImplementBeUsedForAI()
	local v54_, v55_, v56_, _, _ = self:getAIMarkers()
	return v54_ ~= nil and (v55_ ~= nil and v56_ ~= nil)
end

function AIImplement:addVehicleToAIImplementList(superFunc, list)
	if self:getCanImplementBeUsedForAI() then
		table.insert(list, {
			["object"] = self
		})
	end
	superFunc(self, list)
end

function AIImplement:getAllowTireTracks(superFunc)
	local v62_ = superFunc(self)
	if v62_ then
		v62_ = not self:getIsAIActive()
	end
	return v62_
end

-- Local values: rootVehicle
function AIImplement:getDoConsumePtoPower(superFunc)
	local v65_ = self.rootVehicle
	if v65_.getAIFieldWorkerIsTurning == nil or not v65_:getAIFieldWorkerIsTurning() then
		return superFunc(self)
	else
		return false
	end
end

-- Local values: spec
function AIImplement:checkMovingPartDirtyUpdateNode(superFunc, node, movingPart)
	superFunc(self, node, movingPart)
	local v70_ = self.spec_aiImplement
	if node == v70_.leftMarker or (node == v70_.rightMarker or node == v70_.backMarker) then
		Logging.xmlError(self.xmlFile, "Found ai marker node \'%s\' in active dirty moving part \'%s\' with limited update distance. Remove limit or adjust hierarchy for correct function. (maxUpdateDistance=\'-\')", getName(node), getName(movingPart.node))
	end
	if node == v70_.sizeLeftMarker or (node == v70_.sizeRightMarker or node == v70_.sizeBackMarker) then
		Logging.xmlError(self.xmlFile, "Found ai size marker node \'%s\' in active dirty moving part \'%s\' with limited update distance. Remove limit or adjust hierarchy for correct function. (maxUpdateDistance=\'-\')", getName(node), getName(movingPart.node))
	end
	if v70_.collisionTrigger ~= nil and node == v70_.collisionTrigger.node then
		Logging.xmlError(self.xmlFile, "Found ai collision trigger \'%s\' in active dirty moving part \'%s\' with limited update distance. Remove limit or adjust hierarchy for correct function. (maxUpdateDistance=\'-\')", getName(node), getName(movingPart.node))
	end
end

function AIImplement:getAIMinTurningRadius()
	return self.spec_aiImplement.minTurningRadius
end

-- Local values: spec, _, implement, aiSetup
function AIImplement:getAIMarkers()
	local v73_ = self.spec_aiImplement
	if v73_.useAttributesOfAttachedImplement and self.getAttachedImplements ~= nil then
		for _, v74_ in ipairs(self:getAttachedImplements()) do
			if v74_.object.getAIMarkers ~= nil then
				return v74_.object:getAIMarkers()
			end
		end
	end
	local v75_ = self:getCustomAIImplementBaseSetup()
	if v75_ == nil or v75_.rightMarker == nil then
		v75_ = v73_
	end
	if v73_.aiMarkersInverted then
		return v75_.rightMarker, v75_.leftMarker, v75_.backMarker, true, v75_.aiMarkerWidth, v75_.aiMarkerValidityOffset
	else
		return v75_.leftMarker, v75_.rightMarker, v75_.backMarker, false, v75_.aiMarkerWidth, v75_.aiMarkerValidityOffset
	end
end

-- Local values: spec, _, aiBaseSetup
function AIImplement:updateAIMarkerWidth()
	local v77_ = self.spec_aiImplement
	if v77_.leftMarker ~= nil and (v77_.backMarker ~= nil and v77_.aiMarkerWidth == nil) then
		if v77_.leftMarker == nil or v77_.rightMarker == nil then
			v77_.aiMarkerWidth = 0
		else
			v77_.aiMarkerWidth = calcDistanceFrom(v77_.leftMarker, v77_.rightMarker)
		end
	end
	if v77_.aiBaseSetups ~= nil then
		for _, v78_ in ipairs(v77_.aiBaseSetups) do
			if v78_.aiMarkerWidth == nil then
				if v78_.leftMarker == nil or v78_.rightMarker == nil then
					v78_.aiMarkerWidth = 0
				else
					v78_.aiMarkerWidth = calcDistanceFrom(v78_.leftMarker, v78_.rightMarker)
				end
			end
		end
	end
end

-- Local values: spec
function AIImplement:setAIMarkersInverted(state)
	local v80_ = self.spec_aiImplement
	v80_.aiMarkersInverted = not v80_.aiMarkersInverted
end

-- Local values: spec, i, inputAttacherJoint, markerOffset, frontOffsetLeft, _, _, frontOffsetRight, _, _, limitFunc
function AIImplement:calcAIMarkerAttacherJointOffset(leftMarker, rightMarker, backMarker)
	local v85_ = self.spec_aiImplement
	if self.getInputAttacherJoints ~= nil then
		for v86_, v87_ in ipairs(self:getInputAttacherJoints()) do
			local v88_ = {
				["leftMarker"] = leftMarker
			}
			local v89_, _, _ = localToLocal(leftMarker, v87_.node, 0, 0, 0)
			local v90_, _, _ = localToLocal(rightMarker, v87_.node, 0, 0, 0)
			v88_.frontOffset = (v89_ > 0 and math.min or math.max)(v89_, v90_)
			local v91_, _, _ = localToLocal(backMarker, v87_.node, 0, 0, 0)
			v88_.backOffset = v91_
			if v85_.inputAttacherJointToMarkerOffset[v86_] == nil then
				v85_.inputAttacherJointToMarkerOffset[v86_] = {}
			end
			local v92_ = v85_.inputAttacherJointToMarkerOffset[v86_]
			table.insert(v92_, v88_)
		end
	end
end

-- Local values: inputAttacherJointIndex, markerOffsets, _, markerOffset
function AIImplement:getAIMarkerAttacherJointOffset(leftMarker)
	if self.getActiveInputAttacherJointDescIndex ~= nil then
		local v95_ = self:getActiveInputAttacherJointDescIndex()
		local v96_ = self.spec_aiImplement.inputAttacherJointToMarkerOffset[v95_]
		if v96_ ~= nil then
			for _, v97_ in ipairs(v96_) do
				if v97_.leftMarker == leftMarker then
					return v97_
				end
			end
		end
	end
	return nil
end

function AIImplement:getAIInvertMarkersOnTurn(turnLeft)
	return false
end

-- Local values: spec, aiSetup
function AIImplement:getAISizeMarkers()
	local v99_ = self.spec_aiImplement
	local v100_ = self:getCustomAIImplementBaseSetup()
	if v100_ ~= nil and v100_.sizeLeftMarker ~= nil then
		v99_ = v100_
	end
	return v99_.sizeLeftMarker, v99_.sizeRightMarker, v99_.sizeBackMarker
end

function AIImplement:getAILookAheadSize()
	return self.spec_aiImplement.lookAheadSize
end

function AIImplement:getAIHasNoFullCoverageArea()
	return self.spec_aiImplement.hasNoFullCoverageArea, self.spec_aiImplement.hasNoFullCoverageAreaOffset
end

function AIImplement:getAIAreaOverlap()
	return self.spec_aiImplement.overlap
end

-- Local values: spec
function AIImplement:getAIRowAlignment()
	local v105_ = self.spec_aiImplement
	if v105_.rowAlignment == nil then
		return false, 0, 0, 0
	else
		return true, v105_.rowAlignment.spacing, v105_.rowAlignment.snapAngle, v105_.rowAlignment.offset
	end
end

function AIImplement.getImplementAllowAutomaticSteering(self)
	return false
end

-- Local values: spec, aiSetup
function AIImplement:getAIImplementCollisionTrigger()
	local v107_ = self.spec_aiImplement
	local v108_ = self:getCustomAIImplementBaseSetup()
	if v108_ ~= nil and v108_.collisionTrigger ~= nil then
		v107_ = v108_
	end
	return v107_.collisionTrigger
end

-- Local values: collisionTrigger
function AIImplement:getAIImplementCollisionTriggers(collisionTriggers)
	local v111_ = self:getAIImplementCollisionTrigger()
	if v111_ ~= nil then
		collisionTriggers[self] = v111_
	end
end

function AIImplement:getAINeedsLowering()
	return self.spec_aiImplement.needsLowering
end

function AIImplement:getAILowerIfAnyIsLowered()
	return self.spec_aiImplement.lowerIfAnyIsLowered
end

function AIImplement:getAINeedsRootAlignment()
	return self.spec_aiImplement.needsRootAlignment
end

function AIImplement:getAIAllowTurnBackward()
	return self.spec_aiImplement.allowTurnBackward
end

function AIImplement:getAIBlockTurnBackward()
	return self.spec_aiImplement.blockTurnBackward
end

function AIImplement:getAIIsVineyardTool()
	return self.spec_aiImplement.isVineyardTool
end

function AIImplement:getAIToolReverserDirectionNode()
	return self.spec_aiImplement.toolReverserDirectionNode
end

-- Local values: turningRadiusLimitation
function AIImplement:getAITurnRadiusLimitation()
	local v120_ = self.spec_aiImplement.turningRadiusLimitation
	return v120_.radius, v120_.rotationJoint, v120_.wheels, v120_.rotLimitFactor, v120_.initialTurnRadiusFactor
end

function AIImplement:setAIImplementVariableSideOffset(variableSideOffset)
	self.spec_aiImplement.variableSideOffset = variableSideOffset
end

-- Local values: spec, aiSetup
function AIImplement:getAIImplementSideOffset()
	local v124_ = self.spec_aiImplement
	local v125_ = self:getCustomAIImplementBaseSetup()
	if v125_ == nil or v125_.sideOffset == nil then
		v125_ = v124_
	end
	return v125_.sideOffset or 0, v124_.variableSideOffset
end

function AIImplement:setAIFruitRequirements(fruitType, minGrowthState, maxGrowthState)
	self:clearAIFruitRequirements()
	self:addAIFruitRequirement(fruitType, minGrowthState, maxGrowthState)
end

-- Local values: spec
function AIImplement:addAIFruitRequirement(fruitType, minGrowthState, maxGrowthState, customMapId, customMapStartChannel, customMapNumChannels)
	local v137_ = self.spec_aiImplement.requiredFruitTypes
	table.insert(v137_, {
		["fruitType"] = fruitType or 0,
		["minGrowthState"] = minGrowthState or 0,
		["maxGrowthState"] = maxGrowthState or 0,
		["customMapId"] = customMapId,
		["customMapStartChannel"] = customMapStartChannel,
		["customMapNumChannels"] = customMapNumChannels
	})
	self:updateFieldCropsQuery()
end

-- Local values: spec
function AIImplement:clearAIFruitRequirements()
	local v139_ = self.spec_aiImplement
	if #v139_.requiredFruitTypes > 0 then
		v139_.requiredFruitTypes = {}
	end
	self:updateFieldCropsQuery()
end

function AIImplement:getAIFruitRequirements()
	return self.spec_aiImplement.requiredFruitTypes
end

function AIImplement:setAIDensityHeightTypeRequirements(fillType)
	self:clearAIDensityHeightTypeRequirements()
	self:addAIDensityHeightTypeRequirement(fillType)
end

-- Local values: spec
function AIImplement:addAIDensityHeightTypeRequirement(fillType)
	local v145_ = self.spec_aiImplement.requiredDensityHeightTypes
	table.insert(v145_, {
		["fillType"] = fillType or 0
	})
	self:updateFieldCropsQuery()
end

-- Local values: spec
function AIImplement:clearAIDensityHeightTypeRequirements()
	local v147_ = self.spec_aiImplement
	if #v147_.requiredDensityHeightTypes > 0 then
		v147_.requiredDensityHeightTypes = {}
	end
	self:updateFieldCropsQuery()
end

function AIImplement:getAIDensityHeightTypeRequirements()
	return self.spec_aiImplement.requiredDensityHeightTypes
end

function AIImplement:getAIImplementUseVineSegment(placeable, segment, segmentSide)
	return true
end

function AIImplement:setAIFruitProhibitions(fruitType, minGrowthState, maxGrowthState)
	self:clearAIFruitProhibitions()
	self:addAIFruitProhibitions(fruitType, minGrowthState, maxGrowthState)
end

-- Local values: spec
function AIImplement:addAIFruitProhibitions(fruitType, minGrowthState, maxGrowthState, customMapId, customMapStartChannel, customMapNumChannels)
	local v160_ = self.spec_aiImplement.prohibitedFruitTypes
	table.insert(v160_, {
		["fruitType"] = fruitType or 0,
		["minGrowthState"] = minGrowthState or 0,
		["maxGrowthState"] = maxGrowthState or 0,
		["customMapId"] = customMapId,
		["customMapStartChannel"] = customMapStartChannel,
		["customMapNumChannels"] = customMapNumChannels
	})
	self:updateFieldCropsQuery()
end

-- Local values: spec
function AIImplement:clearAIFruitProhibitions()
	local v162_ = self.spec_aiImplement
	if #v162_.prohibitedFruitTypes > 0 then
		v162_.prohibitedFruitTypes = {}
	end
	self:updateFieldCropsQuery()
end

function AIImplement:getAIFruitProhibitions()
	return self.spec_aiImplement.prohibitedFruitTypes
end

-- Local values: spec
function AIImplement:addAITerrainDetailRequiredRange(detailType1, detailType2, minState, maxState)
	local v169_ = self.spec_aiImplement
	local v170_ = v169_.terrainDetailRequiredValueRanges
	local v171_ = {
		detailType1,
		detailType2,
		minState or v169_.groundTypeFirstChannel,
		maxState or v169_.groundTypeNumChannels
	}
	table.insert(v170_, v171_)
	self:updateFieldCropsQuery()
end

-- Local values: spec, i, groundType, value
function AIImplement:addAIGroundTypeRequirements(groundTypes, excludedType1, excludedType2, excludedType3, excludedType4, excludedType5, excludedType6)
	local v180_ = self.spec_aiImplement
	for v181_ = 1, #groundTypes do
		local v182_ = groundTypes[v181_]
		if v182_ ~= excludedType1 and (v182_ ~= excludedType2 and (v182_ ~= excludedType3 and (v182_ ~= excludedType4 and (v182_ ~= excludedType5 and v182_ ~= excludedType6)))) then
			local v183_ = FieldGroundType.getValueByType(v182_)
			local v184_ = v180_.terrainDetailRequiredValueRanges
			local v185_ = {
				v183_,
				v183_,
				v180_.groundTypeFirstChannel,
				v180_.groundTypeNumChannels
			}
			table.insert(v184_, v185_)
		end
	end
	self:updateFieldCropsQuery()
end

function AIImplement:clearAITerrainDetailRequiredRange()
	self.spec_aiImplement.terrainDetailRequiredValueRanges = {}
	self:updateFieldCropsQuery()
end

-- Local values: spec, _, implement
function AIImplement:getAITerrainDetailRequiredRange()
	local v188_ = self.spec_aiImplement
	if v188_.useAttributesOfAttachedImplement and self.getAttachedImplements ~= nil then
		for _, v189_ in ipairs(self:getAttachedImplements()) do
			if v189_.object.getAITerrainDetailRequiredRange ~= nil then
				return v189_.object:getAITerrainDetailRequiredRange()
			end
		end
	end
	return v188_.terrainDetailRequiredValueRanges
end

function AIImplement:addAITerrainDetailProhibitedRange(detailType1, detailType2, minState, maxState)
	local v195_ = self.spec_aiImplement.terrainDetailProhibitedValueRanges
	table.insert(v195_, {
		detailType1,
		detailType2,
		minState,
		maxState
	})
	self:updateFieldCropsQuery()
end

function AIImplement:clearAITerrainDetailProhibitedRange()
	self.spec_aiImplement.terrainDetailProhibitedValueRanges = {}
	self:updateFieldCropsQuery()
end

-- Local values: spec, _, implement
function AIImplement:getAITerrainDetailProhibitedRange()
	local v198_ = self.spec_aiImplement
	if v198_.useAttributesOfAttachedImplement and self.getAttachedImplements ~= nil then
		for _, v199_ in ipairs(self:getAttachedImplements()) do
			if v199_.object.getAITerrainDetailProhibitedRange ~= nil then
				return v199_.object:getAITerrainDetailProhibitedRange()
			end
		end
	end
	return v198_.terrainDetailProhibitedValueRanges
end

-- Local values: spec
function AIImplement:getFieldCropsQuery()
	local v201_ = self.spec_aiImplement
	if v201_.fieldCropyQuery == nil then
		self:createFieldCropsQuery()
	end
	return v201_.fieldCropyQuery, v201_.fieldCropyQueryValid
end

-- Local values: spec
function AIImplement:updateFieldCropsQuery()
	if self.spec_aiImplement.fieldCropyQuery ~= nil then
		self:createFieldCropsQuery()
	end
end

-- Local values: fruitRequirements, otherFruitRequirements, _, fruitRequirement, found, _, otherFruitRequirement, fruitProhibitions, otherFruitProhibitions, _, fruitProhibition, found, _, otherFruitProhibition, terrainDetailRequiredValueRanges, otherTerrainDetailRequiredValueRanges, _, valueRange, found, _, otherValueRange, terrainDetailProhibitedValueRanges, otherTerrainDetailProhibitedValueRanges, _, valueRange, found, _, otherValueRange
function AIImplement:compareFieldCropsQuery(otherVehicle)
	if otherVehicle.getAIFruitRequirements == nil then
		return false
	end
	local v205_ = self:getAIFruitRequirements()
	local v206_ = otherVehicle:getAIFruitRequirements()
	for _, v207_ in ipairs(v205_) do
		local v208_ = false
		for _, v209_ in ipairs(v206_) do
			if v207_.fruitType == v209_.fruitType and (v207_.minGrowthState == v209_.minGrowthState and (v207_.maxGrowthState == v209_.maxGrowthState and (v207_.customMapId == v209_.customMapId and (v207_.customMapStartChannel == v209_.customMapStartChannel and v207_.customMapNumChannels == v209_.customMapNumChannels)))) then
				v208_ = true
				break
			end
		end
		if not v208_ then
			return false
		end
	end
	local v210_ = self:getAIFruitProhibitions()
	local v211_ = otherVehicle:getAIFruitProhibitions()
	for _, v212_ in ipairs(v210_) do
		local v213_ = false
		for _, v214_ in ipairs(v211_) do
			if v212_.fruitType == v214_.fruitType and (v212_.minGrowthState == v214_.minGrowthState and (v212_.maxGrowthState == v214_.maxGrowthState and (v212_.customMapId == v214_.customMapId and (v212_.customMapStartChannel == v214_.customMapStartChannel and v212_.customMapNumChannels == v214_.customMapNumChannels)))) then
				v213_ = true
				break
			end
		end
		if not v213_ then
			return false
		end
	end
	local v215_ = self:getAITerrainDetailRequiredRange()
	local v216_ = otherVehicle:getAITerrainDetailRequiredRange()
	for _, v217_ in ipairs(v215_) do
		local v218_ = false
		for _, v219_ in ipairs(v216_) do
			if v217_[1] == v219_[1] and (v217_[2] == v219_[2] and (v217_[3] == v219_[3] and v217_[4] == v219_[4])) then
				v218_ = true
				break
			end
		end
		if not v218_ then
			return false
		end
	end
	local v220_ = self:getAITerrainDetailProhibitedRange()
	local v221_ = otherVehicle:getAITerrainDetailProhibitedRange()
	for _, v222_ in ipairs(v220_) do
		local v223_ = false
		for _, v224_ in ipairs(v221_) do
			if v222_[1] == v224_[1] and (v222_[2] == v224_[2] and (v222_[3] == v224_[3] and v222_[4] == v224_[4])) then
				v223_ = true
				break
			end
		end
		if not v223_ then
			return false
		end
	end
	return true
end

-- Local values: mission, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, spec, query, fruitRequirements, i, fruitRequirement, desc, fruitProhibitions, i, fruitProhibition, desc, terrainDetailRequiredValueRanges, i, valueRange, terrainDetailProhibitValueRanges, i, valueRange
function AIImplement:createFieldCropsQuery()
	local v226_, v227_, v228_ = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	if v226_ ~= nil then
		local v229_ = self.spec_aiImplement
		v229_.fieldCropyQueryValid = false
		local v230_ = FieldCropsQuery.new(v226_)
		local v231_ = self:getAIFruitRequirements()
		for v232_ = 1, #v231_ do
			local v233_ = v231_[v232_]
			if v233_.customMapId == nil and v233_.fruitType ~= FruitType.UNKNOWN then
				local v234_ = g_fruitTypeManager:getFruitTypeByIndex(v233_.fruitType)
				if v234_.terrainDataPlaneId ~= nil then
					v230_:addRequiredCropType(v234_.terrainDataPlaneId, v233_.minGrowthState, v233_.maxGrowthState, v234_.startStateChannel, v234_.numStateChannels, v227_, v228_)
				end
			elseif v233_.customMapId ~= nil then
				v230_:addRequiredDensityMapValue(v233_.customMapId, v233_.minGrowthState, v233_.maxGrowthState, v233_.customMapStartChannel, v233_.customMapNumChannels)
			end
			v229_.fieldCropyQueryValid = true
		end
		local v235_ = self:getAIFruitProhibitions()
		for v236_ = 1, #v235_ do
			local v237_ = v235_[v236_]
			if v237_.customMapId == nil and v237_.fruitType ~= FruitType.UNKNOWN then
				local v238_ = g_fruitTypeManager:getFruitTypeByIndex(v237_.fruitType)
				v230_:addProhibitedCropType(v238_.terrainDataPlaneId, v237_.minGrowthState, v237_.maxGrowthState, v238_.startStateChannel, v238_.numStateChannels, v227_, v228_)
			elseif v237_.customMapId ~= nil then
				v230_:addProhibitedDensityMapValue(v237_.customMapId, v237_.minGrowthState, v237_.maxGrowthState, v237_.customMapStartChannel, v237_.customMapNumChannels)
			end
			v229_.fieldCropyQueryValid = true
		end
		local v239_ = self:getAITerrainDetailRequiredRange()
		for v240_ = 1, #v239_ do
			local v241_ = v239_[v240_]
			v230_:addRequiredGroundValue(v241_[1], v241_[2], v241_[3], v241_[4])
			v229_.fieldCropyQueryValid = true
		end
		local v242_ = self:getAITerrainDetailProhibitedRange()
		for v243_ = 1, #v242_ do
			local v244_ = v242_[v243_]
			v230_:addProhibitedGroundValue(v244_[1], v244_[2], v244_[3], v244_[4])
			v229_.fieldCropyQueryValid = true
		end
		v229_.fieldCropyQuery = v230_
	end
end

function AIImplement:getIsAIImplementInLine()
	return self.spec_aiImplement.isLineStarted
end

-- Local values: actionController
function AIImplement:aiImplementStartLine()
	self.spec_aiImplement.isLineStarted = true
	SpecializationUtil.raiseEvent(self, "onAIImplementStartLine")
	if self.rootVehicle.actionController ~= nil then
		self.rootVehicle.actionController:onAIEvent(self, "onAIImplementStartLine")
	end
end

-- Local values: actionController
function AIImplement:aiImplementEndLine()
	self.spec_aiImplement.isLineStarted = false
	SpecializationUtil.raiseEvent(self, "onAIImplementEndLine")
	if self.rootVehicle.actionController ~= nil then
		self.rootVehicle.actionController:onAIEvent(self, "onAIImplementEndLine")
	end
end
