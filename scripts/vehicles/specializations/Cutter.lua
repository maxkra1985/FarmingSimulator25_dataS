Cutter = {}
Cutter.AUTO_TILT_COLLISION_MASK = CollisionFlag.TERRAIN + CollisionFlag.TERRAIN_DELTA + CollisionFlag.STATIC_OBJECT
Cutter.CUTTER_TILT_XML_KEY = "vehicle.cutter.automaticTilt"
Cutter.CLIENT_DM_UPDATE_RADIUS = 50
function Cutter.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("cutter", false, true, true)
	g_workAreaTypeManager:addWorkAreaType("haulmDrop", false, false, false)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("Cutter")
	v1_:register(XMLValueType.STRING, "vehicle.cutter#fruitTypes", "List with supported fruit types")
	v1_:register(XMLValueType.STRING, "vehicle.cutter#fruitTypeCategories", "List with supported fruit types categories")
	v1_:register(XMLValueType.STRING, "vehicle.cutter#fruitTypeConverter", "Name of fruit type converter")
	v1_:register(XMLValueType.STRING, "vehicle.cutter#fillTypeConverter", "Name of fill type converter (defines the supported fill types for pickup headers)")
	v1_:register(XMLValueType.BOOL, "vehicle.cutter#supportsPickupAI", "AI works for pickup from the ground as well", false)
	AnimationManager.registerAnimationNodesXMLPaths(v1_, "vehicle.cutter.animationNodes")
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.cutter.effect")
	EffectManager.registerEffectXMLPaths(v1_, "vehicle.cutter.fillEffect")
	v1_:register(XMLValueType.NODE_INDEX, Cutter.CUTTER_TILT_XML_KEY .. ".automaticTiltNode(?)#node", "Automatic tilt node")
	v1_:register(XMLValueType.ANGLE, Cutter.CUTTER_TILT_XML_KEY .. ".automaticTiltNode(?)#minAngle", "Min. angle", -5)
	v1_:register(XMLValueType.ANGLE, Cutter.CUTTER_TILT_XML_KEY .. ".automaticTiltNode(?)#maxAngle", "Max. angle", 5)
	v1_:register(XMLValueType.ANGLE, Cutter.CUTTER_TILT_XML_KEY .. ".automaticTiltNode(?)#maxSpeed", "Max. angle change per second", 1)
	v1_:register(XMLValueType.NODE_INDEX, Cutter.CUTTER_TILT_XML_KEY .. "#raycastNode1", "Raycast node 1")
	v1_:register(XMLValueType.NODE_INDEX, Cutter.CUTTER_TILT_XML_KEY .. "#raycastNode2", "Raycast node 2")
	v1_:register(XMLValueType.BOOL, "vehicle.cutter#allowsForageGrowthState", "Allows forage growth state", false)
	v1_:register(XMLValueType.BOOL, "vehicle.cutter#allowCuttingWhileRaised", "Allow cutting while raised", false)
	v1_:register(XMLValueType.INT, "vehicle.cutter#movingDirection", "Moving direction", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.cutter#strawRatio", "Straw ratio", 1)
	v1_:register(XMLValueType.TIME, "vehicle.cutter.haulmDrop#delay", "Delay between pickup and haulm drop", 0)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.cutter.spikedDrums.spikedDrum(?)#node", "Spiked drum node (Needs to rotate on X axis)")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.cutter.spikedDrums.spikedDrum(?)#spline", "Reference spline")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.cutter.spikedDrums.spikedDrum(?).spike(?)#node", "Spike that is translated on Y axis depending on spline")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.cutter.sounds", "cut")
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. ".chopperArea#index", "Chopper area index")
	v1_:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".chopperArea#index", "Chopper area index")
	v1_:register(XMLValueType.BOOL, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#moveOnlyIfCut", "Move only if cutters cuts something", false)
	v1_:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#rotateIfTurnedOn", "Rotate only if turned on", false)
	v1_:register(XMLValueType.BOOL, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. "#useFruitCutHeight", "The lower distance to ground is used from the cutHeight defined in the current fruit type", true)
	v1_:register(XMLValueType.BOOL, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. "#useFruitCutHeight", "The lower distance to ground is used from the cutHeight defined in the current fruit type", true)
	v1_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).cutter#cutHeight", "Last used cut height")
end

function Cutter.prerequisitesPresent(specializations)
	local v3_ = SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TestAreas, specializations)
	if v3_ then
		v3_ = SpecializationUtil.hasSpecialization(FruitExtraObjects, specializations)
	end
	return v3_
end

function Cutter.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "readCutterFromStream", Cutter.readCutterFromStream)
	SpecializationUtil.registerFunction(vehicleType, "writeCutterToStream", Cutter.writeCutterToStream)
	SpecializationUtil.registerFunction(vehicleType, "getCombine", Cutter.getCombine)
	SpecializationUtil.registerFunction(vehicleType, "getAllowCutterAIFruitRequirements", Cutter.getAllowCutterAIFruitRequirements)
	SpecializationUtil.registerFunction(vehicleType, "processCutterArea", Cutter.processCutterArea)
	SpecializationUtil.registerFunction(vehicleType, "processPickupCutterArea", Cutter.processPickupCutterArea)
	SpecializationUtil.registerFunction(vehicleType, "processHaulmDropArea", Cutter.processHaulmDropArea)
	SpecializationUtil.registerFunction(vehicleType, "getCutterLoad", Cutter.getCutterLoad)
	SpecializationUtil.registerFunction(vehicleType, "getCutterStoneMultiplier", Cutter.getCutterStoneMultiplier)
	SpecializationUtil.registerFunction(vehicleType, "loadCutterTiltFromXML", Cutter.loadCutterTiltFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getCutterTiltIsAvailable", Cutter.getCutterTiltIsAvailable)
	SpecializationUtil.registerFunction(vehicleType, "getCutterTiltIsActive", Cutter.getCutterTiltIsActive)
	SpecializationUtil.registerFunction(vehicleType, "getCutterTiltDelta", Cutter.getCutterTiltDelta)
	SpecializationUtil.registerFunction(vehicleType, "tiltRaycastDetectionCallbackLeft", Cutter.tiltRaycastDetectionCallbackLeft)
	SpecializationUtil.registerFunction(vehicleType, "tiltRaycastDetectionCallbackRight", Cutter.tiltRaycastDetectionCallbackRight)
	SpecializationUtil.registerFunction(vehicleType, "setCutterCutHeight", Cutter.setCutterCutHeight)
end

function Cutter.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Cutter.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Cutter.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadRandomlyMovingPartFromXML", Cutter.loadRandomlyMovingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsRandomlyMovingPartActive", Cutter.getIsRandomlyMovingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Cutter.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Cutter.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Cutter.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Cutter.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Cutter.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isAttachAllowed", Cutter.isAttachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", Cutter.getConsumingLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsGroundReferenceNodeThreshold", Cutter.getIsGroundReferenceNodeThreshold)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDefaultAllowComponentMassReduction", Cutter.getDefaultAllowComponentMassReduction)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadInputAttacherJoint", Cutter.loadInputAttacherJoint)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFruitExtraObjectTypeData", Cutter.getFruitExtraObjectTypeData)
end

function Cutter.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldCourseSettingsInitialized", Cutter)
end

-- Local values: spec, fruitTypeIndices, fruitTypeNames, fruitTypeCategories, category, data, input, converter, _, fruitTypeIndex, cutHeight, _, fruitTypeIndex, fillTypeIndex, fillTypeConverterName, fillTypeConverter, _, outputData, inputFillTypeIndex, _
function Cutter:onLoad(savegame)
	local v_u_9_ = self.spec_cutter
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.cutter.animationNodes.animationNode", "cutter")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnScrollers", "vehicle.cutter.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.turnedOnScrollers", "vehicle.cutter.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.reelspikes", "vehicle.cutter.rotationNodes.rotationNode or vehicle.turnOnVehicle.turnedOnAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.threshingParticleSystems.threshingParticleSystem", "vehicle.cutter.fillEffect.effectNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.threshingParticleSystems.emitterShape", "vehicle.cutter.fillEffect.effectNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter#convertedFillTypeCategories", "vehicle.cutter#fruitTypeConverter")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter#startAnimationName", "vehicle.turnOnVehicle.turnOnAnimation#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.testAreas", "vehicle.workAreas.workArea.testAreas")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter#useWindrowed", "Windrows are now picked up if a fillTypeConverter is defined and the work area uses \'processPickupCutterArea\'")
	local v10_ = nil
	local v11_ = self.xmlFile:getValue("vehicle.cutter#fruitTypes")
	local v12_ = self.xmlFile:getValue("vehicle.cutter#fruitTypeCategories")
	if v12_ == nil or v11_ ~= nil then
		if v12_ == nil and v11_ ~= nil then
			v10_ = g_fruitTypeManager:getFruitTypeIndicesByNames(v11_, "Warning: Cutter has invalid fruitType \'%s\' in \'" .. self.configFileName .. "\'")
		end
	else
		v10_ = g_fruitTypeManager:getFruitTypeIndicesByCategoryNames(v12_, "Warning: Cutter has invalid fruitTypeCategory \'%s\' in \'" .. self.configFileName .. "\'")
	end
	v_u_9_.currentCutHeight = 0
	v_u_9_.outputFillTypes = {}
	v_u_9_.fruitTypeConverters = {}
	local v13_ = self.xmlFile:getValue("vehicle.cutter#fruitTypeConverter")
	if v13_ ~= nil then
		local v14_ = g_fruitTypeManager:getConverterDataByName(v13_)
		if v14_ == nil then
			Logging.xmlWarning(self.xmlFile, "Cutter has invalid fruitTypeConverter \'%s\'", v13_)
		else
			for v15_, v16_ in pairs(v14_) do
				v_u_9_.fruitTypeConverters[v15_] = v16_
			end
		end
	end
	if v10_ ~= nil then
		v_u_9_.fruitTypeIndices = {}
		for _, v17_ in pairs(v10_) do
			local v18_ = v_u_9_.fruitTypeIndices
			table.insert(v18_, v17_)
			if #v_u_9_.fruitTypeIndices == 1 then
				self:setCutterCutHeight((g_fruitTypeManager:getCutHeightByFruitTypeIndex(v17_, v_u_9_.allowsForageGrowthState)))
			end
		end
		for _, v19_ in ipairs(v_u_9_.fruitTypeIndices) do
			if v_u_9_.fruitTypeConverters[v19_] == nil then
				local v20_ = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v19_)
				if v20_ ~= nil then
					local v21_ = v_u_9_.outputFillTypes
					table.insert(v21_, v20_)
				end
			else
				local v22_ = v_u_9_.outputFillTypes
				local v23_ = v_u_9_.fruitTypeConverters[v19_].fillTypeIndex
				table.insert(v22_, v23_)
			end
		end
	end
	v_u_9_.fillTypeConverter = nil
	local v24_ = self.xmlFile:getValue("vehicle.cutter#fillTypeConverter")
	if v24_ ~= nil then
		local v25_ = g_fillTypeManager:getConverterDataByName(v24_)
		if v25_ == nil then
			Logging.xmlWarning(self.xmlFile, "Cutter has invalid fillTypeConverter \'%s\'", v24_)
		else
			v_u_9_.fillTypeConverter = v25_
			for _, v26_ in pairs(v25_) do
				local v27_ = v_u_9_.outputFillTypes
				local v28_ = v26_.targetFillTypeIndex
				table.insert(v27_, v28_)
			end
		end
	end
	if #v_u_9_.outputFillTypes == 0 then
		Logging.xmlWarning(self.xmlFile, "Cutter has no valid fruit/fill type definition (requires either fruitTypes/fruitTypeCategories or fillTypeConverter attribute)")
	end
	if self.isClient then
		v_u_9_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.cutter.animationNodes", self.components, self, self.i3dMappings)
		v_u_9_.spikedDrums = {}
		self.xmlFile:iterate("vehicle.cutter.spikedDrums.spikedDrum", function(_, p29_)
			-- upvalues: (copy) self, (copy) v_u_9_
			local v_u_30_ = {
				["node"] = self.xmlFile:getValue(p29_ .. "#node", nil, self.components, self.i3dMappings)
			}
			if v_u_30_.node == nil then
				Logging.xmlWarning(self.xmlFile, "No drum node defined for spiked drum \'%s\'", p29_)
				return
			else
				v_u_30_.spline = self.xmlFile:getValue(p29_ .. "#spline", nil, self.components, self.i3dMappings)
				if v_u_30_.spline == nil then
					Logging.xmlWarning(self.xmlFile, "No spline defined for spiked drum \'%s\'", p29_)
					return
				else
					setVisibility(v_u_30_.spline, false)
					v_u_30_.spikes = {}
					self.xmlFile:iterate(p29_ .. ".spike", function(_, p31_)
						-- upvalues: (ref) self, (copy) v_u_30_
						local v32_ = {
							["node"] = self.xmlFile:getValue(p31_ .. "#node", nil, self.components, self.i3dMappings)
						}
						if v32_.node ~= nil then
							local v33_ = createTransformGroup(getName(v32_.node) .. "Parent")
							link(getParent(v32_.node), v33_, getChildIndex(v32_.node))
							setTranslation(v33_, getTranslation(v32_.node))
							setRotation(v33_, getRotation(v32_.node))
							link(v33_, v32_.node)
							setTranslation(v32_.node, 0, 0, 0)
							setRotation(v32_.node, 0, 0, 0)
							local _, v34_, v35_ = localToLocal(v32_.node, v_u_30_.node, 0, 0, 0)
							local v36_ = -MathUtil.getYRotationFromDirection(v34_, v35_) / 6.283185307179586
							if v36_ < 0 then
								v36_ = v36_ + 1
							end
							v32_.initalTime = v36_
							local v37_ = v_u_30_.spikes
							table.insert(v37_, v32_)
						end
					end)
					local v38_ = {}
					for v39_ = 0, 1, 0.01 do
						local v40_, v41_, v42_ = getSplinePosition(v_u_30_.spline, v39_)
						local _, v43_, v44_ = worldToLocal(v_u_30_.node, v40_, v41_, v42_)
						local v45_ = -MathUtil.getYRotationFromDirection(v43_, v44_) / 6.283185307179586
						if v45_ < 0 then
							v45_ = v45_ + 1
						end
						table.insert(v38_, {
							["alpha"] = v45_,
							["time"] = v39_
						})
					end
					local v46_ = {
						["alpha"] = v38_[1].alpha - 1e-6,
						["time"] = 1
					}
					table.insert(v38_, v46_)
					table.sort(v38_, function(p47_, p48_)
						return p47_.alpha < p48_.alpha
					end)
					v_u_30_.splineCurve = AnimCurve.new(linearInterpolator1)
					for v49_ = 1, #v38_ do
						v_u_30_.splineCurve:addKeyframe({
							v38_[v49_].time,
							["time"] = v38_[v49_].alpha
						})
					end
					for v50_ = 1, #v_u_9_.animationNodes do
						local v51_ = v_u_9_.animationNodes[v50_]
						if v51_.rootNode == v_u_30_.node then
							v_u_30_.animationNode = v51_
						end
					end
					if v_u_30_.animationNode == nil then
						Logging.xmlWarning(self.xmlFile, "Could not find animation node for spikedDrum \'%s\'", getName(v_u_30_.node))
					else
						local v52_ = v_u_9_.spikedDrums
						table.insert(v52_, v_u_30_)
					end
				end
			end
		end)
		v_u_9_.cutterEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.cutter.effect", self.components, self, self.i3dMappings)
		v_u_9_.fillEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.cutter.fillEffect", self.components, self, self.i3dMappings)
		v_u_9_.samples = {}
		v_u_9_.samples.cut = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.cutter.sounds", "cut", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v_u_9_.lastAutomaticTiltRaycastPosition = { 0, 0, 0 }
	v_u_9_.automaticTilt = {}
	v_u_9_.automaticTilt.isAvailable = false
	v_u_9_.automaticTilt.hasNodes = false
	if self:loadCutterTiltFromXML(self.xmlFile, Cutter.CUTTER_TILT_XML_KEY, v_u_9_.automaticTilt) then
		v_u_9_.automaticTilt.currentDelta = 0
		v_u_9_.automaticTilt.lastHit1 = { 0, 0, 0 }
		v_u_9_.automaticTilt.lastHit2 = { 0, 0, 0 }
		v_u_9_.automaticTilt.raycastHit = true
		v_u_9_.automaticTilt.isAvailable = true
		v_u_9_.automaticTilt.hasNodes = #v_u_9_.automaticTilt.nodes > 0
	end
	if not Platform.gameplay.allowAutomaticHeaderTilt and v_u_9_.automaticTilt.hasNodes then
		Logging.xmlWarning(self.xmlFile, "Automatic header tilt is not allowed on this platform!")
		v_u_9_.automaticTilt.hasNodes = false
	end
	v_u_9_.allowsForageGrowthState = self.xmlFile:getValue("vehicle.cutter#allowsForageGrowthState", false)
	v_u_9_.allowCuttingWhileRaised = self.xmlFile:getValue("vehicle.cutter#allowCuttingWhileRaised", false)
	local v53_ = self.xmlFile:getValue("vehicle.cutter#movingDirection", 1)
	v_u_9_.movingDirection = math.sign(v53_)
	v_u_9_.strawRatio = self.xmlFile:getValue("vehicle.cutter#strawRatio", 1)
	v_u_9_.delay = self.xmlFile:getValue("vehicle.cutter.haulmDrop#delay", 0)
	if v_u_9_.delay ~= 0 then
		v_u_9_.valueDelay = ValueDelay.new(v_u_9_.delay)
	end
	v_u_9_.useWindrow = false
	v_u_9_.currentInputFillType = FillType.UNKNOWN
	v_u_9_.currentInputFillTypeSent = FillType.UNKNOWN
	v_u_9_.currentInputFruitType = FruitType.UNKNOWN
	v_u_9_.currentInputFruitTypeAI = FruitType.UNKNOWN
	v_u_9_.lastValidInputFruitType = FruitType.UNKNOWN
	v_u_9_.currentInputFruitTypeSent = FruitType.UNKNOWN
	v_u_9_.currentOutputFillType = FillType.UNKNOWN
	v_u_9_.currentConversionFactor = 1
	v_u_9_.currentGrowthStateTime = 0
	v_u_9_.currentGrowthStateTimer = 0
	v_u_9_.currentGrowthState = 0
	v_u_9_.lastAreaBiggerZero = false
	v_u_9_.lastAreaBiggerZeroSent = false
	v_u_9_.lastAreaBiggerZeroTime = -1
	v_u_9_.workAreaParameters = {}
	v_u_9_.workAreaParameters.lastLiters = 0
	v_u_9_.workAreaParameters.lastArea = 0
	v_u_9_.workAreaParameters.lastMultiplierArea = 0
	v_u_9_.workAreaParameters.fruitTypeIndicesToUse = {}
	v_u_9_.workAreaParameters.lastFruitTypeToUse = {}
	v_u_9_.workAreaParameters.lastOutputFillType = nil
	v_u_9_.lastOutputFillTypes = {}
	v_u_9_.lastPrioritizedOutputType = FillType.UNKNOWN
	v_u_9_.lastOutputTime = 0
	v_u_9_.cutterLoad = 0
	v_u_9_.isWorking = false
	v_u_9_.stoneLastState = 0
	v_u_9_.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("CUTTER")
	v_u_9_.workAreaParameters.countArea = true
	if self.xmlFile:getValue("vehicle.cutter#supportsPickupAI", false) and self.addAIDensityHeightTypeRequirement ~= nil then
		for v54_, _ in pairs(v_u_9_.fillTypeConverter) do
			self:addAIDensityHeightTypeRequirement(v54_)
		end
	end
	if savegame ~= nil and not savegame.resetVehicles then
		v_u_9_.currentCutHeight = savegame.xmlFile:getValue(savegame.key .. ".cutter#cutHeight", v_u_9_.currentCutHeight)
	end
	v_u_9_.dirtyFlag = self:getNextDirtyFlag()
	v_u_9_.effectDirtyFlag = self:getNextDirtyFlag()
end

function Cutter:onPostLoad(savegame)
	if self.addCutterToCombine ~= nil then
		self:addCutterToCombine(self)
	end
	self:setCutterCutHeight(self.spec_cutter.currentCutHeight)
end

-- Local values: spec
function Cutter:onDelete()
	local v57_ = self.spec_cutter
	g_effectManager:deleteEffects(v57_.cutterEffects)
	g_effectManager:deleteEffects(v57_.fillEffects)
	g_animationManager:deleteAnimations(v57_.animationNodes)
	g_soundManager:deleteSamples(v57_.samples)
end

-- Local values: spec
function Cutter:onReadStream(streamId, connection)
	self:readCutterFromStream(streamId, connection)
	local v61_ = self.spec_cutter
	v61_.lastAreaBiggerZero = streamReadBool(streamId)
	if v61_.lastAreaBiggerZero then
		v61_.lastAreaBiggerZeroTime = g_currentMission.time
	end
	self:setTestAreaRequirements(v61_.currentInputFruitType, nil, v61_.allowsForageGrowthState)
end

-- Local values: spec
function Cutter:onWriteStream(streamId, connection)
	self:writeCutterToStream(streamId, connection)
	local v65_ = self.spec_cutter
	streamWriteBool(streamId, v65_.lastAreaBiggerZeroSent)
end

-- Local values: spec
function Cutter:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v69_ = self.spec_cutter
		if streamReadBool(streamId) then
			self:readCutterFromStream(streamId, connection)
		end
		v69_.lastAreaBiggerZero = streamReadBool(streamId)
		if v69_.lastAreaBiggerZero then
			v69_.lastAreaBiggerZeroTime = g_currentMission.time
		end
		self:setTestAreaRequirements(v69_.currentInputFruitType, nil, v69_.allowsForageGrowthState)
	end
end

-- Local values: spec
function Cutter:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v74_ = self.spec_cutter
		local v75_ = streamWriteBool
		local v76_ = v74_.effectDirtyFlag
		if v75_(streamId, bit32.band(dirtyMask, v76_) ~= 0) then
			self:writeCutterToStream(streamId, connection)
		end
		streamWriteBool(streamId, v74_.lastAreaBiggerZeroSent)
	end
end

-- Local values: spec
function Cutter:readCutterFromStream(streamId, connection)
	local v79_ = self.spec_cutter
	v79_.currentGrowthState = streamReadUIntN(streamId, 4)
	v79_.currentInputFruitType = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
	if streamReadBool(streamId) then
		v79_.lastValidInputFruitType = v79_.currentInputFruitType
	else
		v79_.currentInputFruitType = FruitType.UNKNOWN
	end
	v79_.currentOutputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v79_.currentInputFruitType)
	if v79_.fruitTypeConverters[v79_.currentInputFruitType] ~= nil then
		v79_.currentOutputFillType = v79_.fruitTypeConverters[v79_.currentInputFruitType].fillTypeIndex
		v79_.currentConversionFactor = v79_.fruitTypeConverters[v79_.currentInputFruitType].conversionFactor
	end
	v79_.useWindrow = streamReadBool(streamId)
	if v79_.useWindrow then
		v79_.currentInputFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
	else
		v79_.currentInputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v79_.currentInputFruitType)
	end
end

-- Local values: spec
function Cutter:writeCutterToStream(streamId, connection)
	local v82_ = self.spec_cutter
	streamWriteUIntN(streamId, v82_.currentGrowthState, 4)
	streamWriteUIntN(streamId, v82_.currentInputFruitType, FruitTypeManager.SEND_NUM_BITS)
	streamWriteBool(streamId, v82_.currentInputFruitType == v82_.lastValidInputFruitType)
	if streamWriteBool(streamId, v82_.useWindrow) then
		streamWriteUIntN(streamId, v82_.currentInputFillType, FillTypeManager.SEND_NUM_BITS)
	end
end

-- Local values: spec
function Cutter:saveToXMLFile(xmlFile, key, usedModNames)
	local v86_ = self.spec_cutter
	xmlFile:setValue(key .. "#cutHeight", v86_.currentCutHeight)
end

-- Local values: spec, currentDelta, isActive, doReset, i, automaticTiltNode, _, _, curZ, speedScale, rotSpeed, newRotZ, i, spikedDrum, rot, _, _, alpha, numSpikes, j, spike, splineTime, x, y, z, _, spikeY, _
function Cutter:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v89_ = self.spec_cutter
	if v89_.automaticTilt.hasNodes then
		local v90_, v91_, v92_ = self:getCutterTiltDelta()
		local v93_ = -v90_
		if self.isActive then
			for v94_ = 1, #v89_.automaticTilt.nodes do
				local v95_ = v89_.automaticTilt.nodes[v94_]
				local _, _, v96_ = getRotation(v95_.node)
				if not v91_ and v92_ then
					v93_ = -v96_
				end
				if math.abs(v93_) > 0.00001 then
					local v97_ = math.abs(v93_) / 0.01745
					local v98_ = math.pow(v97_, 2)
					local v99_ = v96_ + math.min(v98_, 1) * math.sign(v93_) * v95_.maxSpeed * dt
					local v100_ = v95_.minAngle
					local v101_ = v95_.maxAngle
					local v102_ = math.clamp(v99_, v100_, v101_)
					setRotation(v95_.node, 0, 0, v102_)
					if self.setMovingToolDirty ~= nil then
						self:setMovingToolDirty(v95_.node)
					end
				end
			end
		end
	end
	if self.isClient then
		for v103_ = 1, #v89_.spikedDrums do
			local v104_ = v89_.spikedDrums[v103_]
			if v104_.animationNode.state ~= RotationAnimation.STATE_OFF then
				local v105_, _, _ = getRotation(v104_.node)
				if v105_ < 0 then
					v105_ = v105_ + 6.283185307179586
				end
				local v106_ = v105_ / 6.283185307179586
				for v107_ = 1, #v104_.spikes do
					local v108_ = v104_.spikes[v107_]
					local v109_ = v104_.splineCurve:get((v106_ + v108_.initalTime) % 1)
					local v110_, v111_, v112_ = getSplinePosition(v104_.spline, v109_)
					local _, v113_, _ = worldToLocal(getParent(v108_.node), v110_, v111_, v112_)
					setTranslation(v108_.node, 0, v113_, 0)
				end
			end
		end
	end
end

-- Local values: spec, isTurnedOn, isEffectActive, currentTestAreaMinX, currentTestAreaMaxX, testAreaMinX, testAreaMaxX, isValid, testAreaCharge, reset, t, testAreaMinAlpha, testAreaMaxAlpha, inputFruitType, isCollecting, fillType, cutSoundActive, max, i, _, automaticTilt, isActive, _, rx, ry, rz, rDirX, rDirY, rDirZ
function Cutter:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v116_ = self.spec_cutter
	local v117_ = self:getIsTurnedOn() and (self.movingDirection == v116_.movingDirection and self:getLastSpeed() > 0.5 and (v116_.allowCuttingWhileRaised or self:getIsLowered(true)))
	if v117_ then
		v117_ = v116_.workAreaParameters.combineVehicle ~= nil
	end
	if v117_ then
		local v118_, v119_, v120_, v121_, v122_ = self:getTestAreaWidthByWorkAreaIndex(1)
		local v123_ = self:getTestAreaChargeByWorkAreaIndex(1)
		if not v116_.useWindrow then
			v116_.cutterLoad = v116_.cutterLoad * 0.95 + v123_ * 0.05
		end
		local v124_ = false
		if v118_ == -math.huge and v119_ == math.huge then
			v118_ = 0
			v119_ = 0
			v124_ = true
		elseif not v122_ and v116_.lastAreaBiggerZeroTime + 300 < g_currentMission.time then
			v118_ = 0
			v119_ = 0
			v124_ = true
		end
		local v125_
		if v116_.movingDirection > 0 then
			v125_ = v118_ * -1
			v118_ = v119_ * -1
			if v118_ >= v125_ then
				local v126_ = v125_
				v125_ = v118_
				v118_ = v126_
			end
		else
			v125_ = v119_
		end
		local v127_ = v120_ == 0 and 0 or v118_ / v120_
		local v128_ = v121_ == 0 and 0 or v125_ / v121_
		local v129_ = v116_.currentInputFruitType
		if v129_ ~= v116_.lastValidInputFruitType then
			v129_ = nil
		end
		if v129_ ~= nil then
			self:updateFruitExtraObjects()
		end
		local v130_ = v116_.lastAreaBiggerZeroTime + 300 > g_currentMission.time
		local v131_ = v116_.currentInputFillType
		if v116_.useWindrow then
			if v130_ then
				v116_.cutterLoad = v116_.cutterLoad * 0.95 + 0.05
			else
				v116_.cutterLoad = v116_.cutterLoad * 0.9
			end
		end
		if self.isClient then
			local v132_ = false
			if v131_ == nil or (v131_ == FillType.UNKNOWN or not v130_) then
				g_effectManager:stopEffects(v116_.fillEffects)
			else
				g_effectManager:setEffectTypeInfo(v116_.fillEffects, v131_)
				g_effectManager:setMinMaxWidth(v116_.fillEffects, v118_, v125_, v127_, v128_, v124_)
				g_effectManager:startEffects(v116_.fillEffects)
				v132_ = true
			end
			if v129_ == nil or (v129_ == FruitType.UNKNOWN or v124_) then
				g_effectManager:stopEffects(v116_.cutterEffects)
			else
				g_effectManager:setEffectTypeInfo(v116_.cutterEffects, v131_, v129_, v116_.currentGrowthState)
				g_effectManager:setMinMaxWidth(v116_.cutterEffects, v118_, v125_, v127_, v128_, v124_)
				g_effectManager:startEffects(v116_.cutterEffects)
				v132_ = true
			end
			if v132_ then
				if not g_soundManager:getIsSamplePlaying(v116_.samples.cut) then
					g_soundManager:playSample(v116_.samples.cut)
				end
			elseif g_soundManager:getIsSamplePlaying(v116_.samples.cut) then
				g_soundManager:stopSample(v116_.samples.cut)
			end
		end
	else
		if self.isClient then
			g_effectManager:stopEffects(v116_.cutterEffects)
			g_effectManager:stopEffects(v116_.fillEffects)
			g_soundManager:stopSample(v116_.samples.cut)
		end
		v116_.cutterLoad = v116_.cutterLoad * 0.9
	end
	v116_.lastOutputTime = v116_.lastOutputTime + dt
	if v116_.lastOutputTime > 500 then
		v116_.lastPrioritizedOutputType = FillType.UNKNOWN
		local v133_ = 0
		for v134_, _ in pairs(v116_.lastOutputFillTypes) do
			if v133_ < v116_.lastOutputFillTypes[v134_] then
				v116_.lastPrioritizedOutputType = v134_
				v133_ = v116_.lastOutputFillTypes[v134_]
			end
			v116_.lastOutputFillTypes[v134_] = 0
		end
		v116_.lastOutputTime = 0
	end
	local v135_ = v116_.automaticTilt
	local v136_, _ = self:getCutterTiltIsActive(v135_)
	if v136_ and (v135_ ~= nil and (v135_.raycastNode1 ~= nil and v135_.raycastNode2 ~= nil)) then
		v135_.currentDelta = 0
		local v137_ = v135_.lastHit1
		local v138_ = v135_.lastHit1
		local v139_ = v135_.lastHit1
		local v140_, v141_, v142_ = localToWorld(v135_.raycastNode1, 0, -1, 0)
		v137_[1] = v140_
		v138_[2] = v141_
		v139_[3] = v142_
		local v143_ = v135_.lastHit2
		local v144_ = v135_.lastHit2
		local v145_ = v135_.lastHit2
		local v146_, v147_, v148_ = localToWorld(v135_.raycastNode2, 0, -1, 0)
		v143_[1] = v146_
		v144_[2] = v147_
		v145_[3] = v148_
		local v149_, v150_, v151_ = localToWorld(v135_.raycastNode1, 0, 1, 0)
		local v152_, v153_, v154_ = localDirectionToWorld(v135_.raycastNode1, 0, -1, 0)
		raycastAllAsync(v149_, v150_, v151_, v152_, v153_, v154_, 2, "tiltRaycastDetectionCallbackLeft", self, Cutter.AUTO_TILT_COLLISION_MASK)
		local v155_, v156_, v157_ = localToWorld(v135_.raycastNode2, 0, 1, 0)
		local v158_, v159_, v160_ = localDirectionToWorld(v135_.raycastNode2, 0, -1, 0)
		raycastAllAsync(v155_, v156_, v157_, v158_, v159_, v160_, 2, "tiltRaycastDetectionCallbackRight", self, Cutter.AUTO_TILT_COLLISION_MASK)
	end
end

-- Local values: spec, attacherVehicle
function Cutter:getCombine(fruitTypeIndex, outputFillTypeIndex)
	local v164_ = self.spec_cutter
	if self.verifyCombine ~= nil then
		return self:verifyCombine(fruitTypeIndex or v164_.currentInputFruitType, outputFillTypeIndex or v164_.currentOutputFillType)
	end
	if self.getAttacherVehicle ~= nil then
		local v165_ = self:getAttacherVehicle()
		if v165_ ~= nil and v165_.verifyCombine ~= nil then
			return v165_:verifyCombine(fruitTypeIndex or v164_.currentInputFruitType, outputFillTypeIndex or v164_.currentOutputFillType)
		end
	end
	return nil
end

function Cutter:getAllowCutterAIFruitRequirements()
	return true
end

-- Local values: spec, fieldGroundSystem, xs, _, zs, xw, _, zw, xh, _, zh, lastArea, lastMultiplierArea, lastTotalArea, _, fruitTypeIndex, fruitTypeDesc, excludedSprayType, area, totalArea, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPerc, growthState, _, terrainDetailPixelsSum, cutHeight, multiplier, chopperWorkArea, fruitTypeDesc, strawGroundType, area
function Cutter:processCutterArea(workArea, dt)
	local v169_ = self.spec_cutter
	if not self.isServer and self.currentUpdateDistance > Cutter.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	if v169_.workAreaParameters.combineVehicle == nil then
		return 0, 0
	end
	local v170_ = g_currentMission.fieldGroundSystem
	local v171_, _, v172_ = getWorldTranslation(workArea.start)
	local v173_, _, v174_ = getWorldTranslation(workArea.width)
	local v175_, _, v176_ = getWorldTranslation(workArea.height)
	local v177_ = 0
	local v178_ = 0
	local v179_ = 0
	for _, v180_ in ipairs(v169_.workAreaParameters.fruitTypeIndicesToUse) do
		local v181_ = v170_:getChopperTypeValue(g_fruitTypeManager:getFruitTypeByIndex(v180_).chopperType)
		local v182_, v183_, v184_, v185_, v186_, v187_, v188_, v189_, v190_, v191_, _, v192_ = FSDensityMapUtil.cutFruitArea(v180_, v171_, v172_, v173_, v174_, v175_, v176_, true, v169_.allowsForageGrowthState, v181_)
		if v182_ > 0 then
			v177_ = v177_ + v183_
			if self.isServer then
				if v191_ == v169_.currentGrowthState then
					v169_.currentGrowthStateTimer = 0
					v169_.currentGrowthStateTime = g_time
				else
					v169_.currentGrowthStateTimer = v169_.currentGrowthStateTimer + dt
					if v169_.currentGrowthStateTimer > 500 or v169_.currentGrowthStateTime + 1000 < g_time then
						v169_.currentGrowthState = v191_
						v169_.currentGrowthStateTimer = 0
					end
				end
				if v180_ ~= v169_.currentInputFruitType then
					v169_.currentInputFruitType = v180_
					v169_.currentGrowthState = v191_
					v169_.currentOutputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v169_.currentInputFruitType)
					if v169_.fruitTypeConverters[v169_.currentInputFruitType] ~= nil then
						v169_.currentOutputFillType = v169_.fruitTypeConverters[v169_.currentInputFruitType].fillTypeIndex
						v169_.currentConversionFactor = v169_.fruitTypeConverters[v169_.currentInputFruitType].conversionFactor
					end
					self:setCutterCutHeight((g_fruitTypeManager:getCutHeightByFruitTypeIndex(v180_, v169_.allowsForageGrowthState)))
				end
				self:setTestAreaRequirements(v180_, nil, v169_.allowsForageGrowthState)
				if v192_ > 0 then
					v169_.currentInputFruitTypeAI = v180_
				end
				v169_.currentInputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v180_)
				v169_.useWindrow = false
			end
			v179_ = v182_ * g_currentMission:getHarvestScaleMultiplier(v180_, v184_, v185_, v186_, v187_, v188_, v189_, v190_)
			v169_.workAreaParameters.lastFruitType = v180_
			v178_ = v182_
			break
		end
	end
	if v178_ > 0 then
		if workArea.chopperAreaIndex ~= nil and v169_.workAreaParameters.lastFruitType ~= nil then
			local v193_ = self:getWorkAreaByIndex(workArea.chopperAreaIndex)
			if v193_ == nil then
				Logging.xmlWarning(self.xmlFile, "Invalid chopperAreaIndex \'%d\' for workArea \'%d\'!", workArea.chopperAreaIndex, workArea.index)
				workArea.chopperAreaIndex = nil
			else
				local v194_
				v171_, v194_, v172_ = getWorldTranslation(v193_.start)
				local v195_
				v173_, v195_, v174_ = getWorldTranslation(v193_.width)
				local v196_
				v175_, v196_, v176_ = getWorldTranslation(v193_.height)
				local v197_ = g_fruitTypeManager:getFruitTypeByIndex(v169_.workAreaParameters.lastFruitType)
				if v197_.chopperType == nil then
					if v197_.chopperUseHaulm and FSDensityMapUtil.updateFruitHaulmArea(v169_.workAreaParameters.lastFruitType, v171_, v172_, v173_, v174_, v175_, v176_) > 0 then
						FSDensityMapUtil.eraseTireTrack(v171_, v172_, v173_, v174_, v175_, v176_)
					end
				else
					local v198_ = FieldChopperType.getValueByType(v197_.chopperType)
					if v198_ ~= nil then
						FSDensityMapUtil.setGroundTypeLayerArea(v171_, v172_, v173_, v174_, v175_, v176_, v198_)
					end
				end
			end
		end
		v169_.stoneLastState = FSDensityMapUtil.getStoneArea(v171_, v172_, v173_, v174_, v175_, v176_)
		v169_.isWorking = true
	end
	v169_.workAreaParameters.lastArea = v169_.workAreaParameters.lastArea + v178_
	v169_.workAreaParameters.lastMultiplierArea = v169_.workAreaParameters.lastMultiplierArea + v179_
	return v169_.workAreaParameters.lastArea, v177_
end

-- Local values: spec, hasPickedUp, sx, sy, sz, wx, wy, wz, hx, hy, hz, lsx, lsy, lsz, lex, ley, lez, lineRadius, inputFillTypeIndex, outputData, pickedUpLiters
function Cutter:processPickupCutterArea(workArea, dt)
	local v201_ = self.spec_cutter
	if not self.isServer and self.currentUpdateDistance > Cutter.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	if v201_.workAreaParameters.combineVehicle ~= nil then
		local v202_, v203_, v204_ = getWorldTranslation(workArea.start)
		local v205_, v206_, v207_ = getWorldTranslation(workArea.width)
		local v208_, v209_, v210_ = getWorldTranslation(workArea.height)
		local v211_, v212_, v213_, v214_, v215_, v216_, v217_ = DensityMapHeightUtil.getLineByAreaDimensions(v202_, v203_, v204_, v205_, v206_, v207_, v208_, v209_, v210_)
		local v218_ = false
		for v219_, v220_ in pairs(v201_.fillTypeConverter) do
			if v201_.workAreaParameters.lastOutputFillType == nil or v220_.targetFillTypeIndex == v201_.workAreaParameters.lastOutputFillType then
				local v221_ = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, v219_, v211_, v212_, v213_, v214_, v215_, v216_, v217_, nil, nil, false, nil)
				if self.isServer and v221_ > 0 then
					v201_.currentOutputFillType = v220_.targetFillTypeIndex
					v201_.currentConversionFactor = v220_.conversionFactor
					v201_.useWindrow = true
					v201_.currentInputFillType = v219_
					local v222_ = g_fruitTypeManager:getCutWindrowHarvestFillLevel(v219_, v221_)
					v201_.workAreaParameters.lastLiters = v222_
					v201_.workAreaParameters.lastOutputFillType = v220_.targetFillTypeIndex
					v201_.stoneLastState = FSDensityMapUtil.getStoneArea(v202_, v204_, v205_, v207_, v208_, v210_)
					v201_.isWorking = true
					self:setTestAreaRequirements(nil, v219_, nil)
					v218_ = true
					break
				end
			end
		end
		if not self.isServer and v201_.lastAreaBiggerZeroTime + 300 > g_currentMission.time and true or v218_ then
			return 1, 1
		end
		v201_.workAreaParameters.lastOutputFillType = nil
	end
	return 0, 0
end

-- Local values: spec, isCutting, value, fruitType, sx, _, sz, wx, _, wz, hx, _, hz, area
function Cutter:processHaulmDropArea(workArea, dt)
	local v226_ = self.spec_cutter
	if not self.isServer and self.currentUpdateDistance > Cutter.CLIENT_DM_UPDATE_RADIUS then
		return 0, 0
	end
	if v226_.valueDelay ~= nil then
		local v227_ = v226_.lastAreaBiggerZeroTime >= g_currentMission.time - 150
		if v226_.valueDelay:add(v227_ and 1 or 0, dt) == 0 then
			return 0, 0
		end
	end
	local v228_ = v226_.currentInputFruitType
	if v228_ == nil or v228_ == FruitType.UNKNOWN then
		return 0, 0
	end
	local v229_, _, v230_ = getWorldTranslation(workArea.start)
	local v231_, _, v232_ = getWorldTranslation(workArea.width)
	local v233_, _, v234_ = getWorldTranslation(workArea.height)
	local v235_ = FSDensityMapUtil.updateFruitHaulmArea(v228_, v229_, v230_, v231_, v232_, v233_, v234_)
	if v235_ > 0 then
		FSDensityMapUtil.eraseTireTrack(v229_, v230_, v231_, v232_, v233_, v234_)
	end
	return v235_, v235_
end

-- Local values: spec, combineVehicle, alternativeCombine, requiredFillType, i, i, fruitType, inputFruitType, fruitTypeConverter
function Cutter:onStartWorkAreaProcessing(dt)
	local v237_ = self.spec_cutter
	local v239_, v239_, v240_ = self:getCombine()
	if v239_ == nil then
		local _ = v240_ == nil
	end
	v237_.workAreaParameters.combineVehicle = v239_
	v237_.workAreaParameters.lastLiters = 0
	v237_.workAreaParameters.lastArea = 0
	v237_.workAreaParameters.lastMultiplierArea = 0
	if v237_.workAreaParameters.lastFruitType == nil then
		v237_.workAreaParameters.fruitTypeIndicesToUse = v237_.fruitTypeIndices
	else
		for v241_ = 1, #v237_.workAreaParameters.lastFruitTypeToUse do
			v237_.workAreaParameters.lastFruitTypeToUse[v241_] = nil
		end
		v237_.workAreaParameters.lastFruitTypeToUse[1] = v237_.workAreaParameters.lastFruitType
		v237_.workAreaParameters.fruitTypeIndicesToUse = v237_.workAreaParameters.lastFruitTypeToUse
	end
	if v240_ ~= nil then
		for v242_ = 1, #v237_.workAreaParameters.lastFruitTypeToUse do
			v237_.workAreaParameters.lastFruitTypeToUse[v242_] = nil
		end
		local v243_ = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(v240_)
		for v244_, v245_ in pairs(v237_.fruitTypeConverters) do
			if v245_.fillTypeIndex == v240_ then
				local v246_ = v237_.workAreaParameters.lastFruitTypeToUse
				table.insert(v246_, v244_)
				v243_ = nil
			end
		end
		if v243_ ~= nil then
			local v247_ = v237_.workAreaParameters.lastFruitTypeToUse
			table.insert(v247_, v243_)
		end
		v237_.workAreaParameters.fruitTypeIndicesToUse = v237_.workAreaParameters.lastFruitTypeToUse
	end
	v237_.workAreaParameters.lastFruitType = nil
	v237_.isWorking = false
end

-- Local values: spec, lastArea, lastLiters, inputFruitType, requirements, requirement, liters, outputFillType, targetOutputFillType, conversionFactor, farmId, appliedDelta, ha, requirements, requirement, fruitType, minState
function Cutter:onEndWorkAreaProcessing(dt, hasProcessed)
	if self.isServer then
		local v249_ = self.spec_cutter
		local v250_ = v249_.workAreaParameters.lastArea
		local v251_ = v249_.workAreaParameters.lastLiters
		v249_.lastAreaBiggerZero = false
		if v250_ > 0 or v251_ > 0 then
			if v249_.workAreaParameters.combineVehicle ~= nil then
				local v252_ = v249_.workAreaParameters.lastFruitType
				if self:getIsAIActive() then
					local v253_ = self:getAIFruitRequirements()
					local v254_ = v253_[1]
					if #v253_ == 1 and (v254_ ~= nil and v254_.fruitType ~= FruitType.UNKNOWN) then
						v252_ = v254_.fruitType
					end
				end
				local v255_ = g_fruitTypeManager:getFruitTypeAreaLiters(v252_, v249_.workAreaParameters.lastMultiplierArea, false) + v251_
				local v256_ = v249_.currentOutputFillType
				if v249_.lastOutputFillTypes[v256_] == nil then
					v249_.lastOutputFillTypes[v256_] = v250_
				else
					v249_.lastOutputFillTypes[v256_] = v249_.lastOutputFillTypes[v256_] + v250_
				end
				local v257_
				if v249_.lastPrioritizedOutputType == FillType.UNKNOWN then
					v257_ = v256_
				else
					v257_ = v249_.lastPrioritizedOutputType
				end
				local v258_ = v249_.currentConversionFactor or 1
				local v259_ = v255_ * v258_
				local v260_ = self:getLastTouchedFarmlandFarmId()
				if v249_.workAreaParameters.combineVehicle:addCutterArea(v250_, v259_, v252_, v257_, v249_.strawRatio * (1 / v258_), v260_, self:getCutterLoad()) > 0 and v257_ == v256_ then
					v249_.lastValidInputFruitType = v252_
				end
			end
			local v261_ = MathUtil.areaToHa(v250_, g_currentMission:getFruitPixelsToSqm())
			g_farmManager:updateFarmStats(self:getLastTouchedFarmlandFarmId(), "threshedHectares", v261_)
			self:updateLastWorkedArea(v250_)
			v249_.lastAreaBiggerZero = v250_ > 0 and true or v251_ > 0
			if v249_.currentInputFruitType ~= v249_.currentInputFruitTypeSent then
				self:raiseDirtyFlags(v249_.effectDirtyFlag)
				v249_.currentInputFruitTypeSent = v249_.currentInputFruitType
			end
			if v249_.currentInputFillType ~= v249_.currentInputFillTypeSent then
				self:raiseDirtyFlags(v249_.effectDirtyFlag)
				v249_.currentInputFillTypeSent = v249_.currentInputFillType
			end
			if self:getAllowCutterAIFruitRequirements() and (self.setAIFruitRequirements ~= nil and not v249_.useWindrow) then
				local v262_ = self:getAIFruitRequirements()
				local v263_ = v262_[1]
				if #v262_ > 1 or (v263_ == nil or v263_.fruitType == FruitType.UNKNOWN) then
					local v264_ = g_fruitTypeManager:getFruitTypeByIndex(v249_.currentInputFruitTypeAI)
					if v264_ ~= nil then
						local v265_ = v249_.allowsForageGrowthState and v264_.minForageGrowthState or v264_.minHarvestingGrowthState
						self:setAIFruitRequirements(v249_.currentInputFruitTypeAI, v265_, v264_.maxHarvestingGrowthState)
					end
				end
			end
		end
		if v249_.lastAreaBiggerZero then
			v249_.lastAreaBiggerZeroTime = g_currentMission.time
		end
		if v249_.lastAreaBiggerZero ~= v249_.lastAreaBiggerZeroSent then
			self:raiseDirtyFlags(v249_.dirtyFlag)
			v249_.lastAreaBiggerZeroSent = v249_.lastAreaBiggerZero
		end
	end
end

-- Local values: speedLimitFactor
function Cutter:getCutterLoad()
	local v267_ = self:getLastSpeed() / self.speedLimit
	local v268_ = math.clamp(v267_, 0, 1) * 0.75 + 0.25
	return self.spec_cutter.cutterLoad * v268_
end

-- Local values: spec
function Cutter:getCutterStoneMultiplier()
	local v270_ = self.spec_cutter
	return (v270_.stoneLastState == 0 or v270_.stoneWearMultiplierData == nil) and 1 or (v270_.stoneWearMultiplierData[v270_.stoneLastState] or 1)
end

-- Local values: x1, _, _, x2, _, _, raycastNode1
function Cutter:loadCutterTiltFromXML(xmlFile, key, target)
	target.nodes = {}
	xmlFile:iterate(key .. ".automaticTiltNode", function(_, p275_)
		-- upvalues: (copy) xmlFile, (copy) self, (copy) target
		local v276_ = {
			["node"] = xmlFile:getValue(p275_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v276_.node ~= nil then
			v276_.minAngle = xmlFile:getValue(p275_ .. "#minAngle", -5)
			v276_.maxAngle = xmlFile:getValue(p275_ .. "#maxAngle", 5)
			v276_.maxSpeed = xmlFile:getValue(p275_ .. "#maxSpeed", 2) / 1000
			local v277_ = target.nodes
			table.insert(v277_, v276_)
		end
	end)
	target.raycastNode1 = xmlFile:getValue(key .. "#raycastNode1", nil, self.components, self.i3dMappings)
	target.raycastNode2 = xmlFile:getValue(key .. "#raycastNode2", nil, self.components, self.i3dMappings)
	if target.raycastNode1 == nil or target.raycastNode2 == nil then
		return false
	end
	local v278_, _, _ = localToLocal(target.raycastNode1, self.rootNode, 0, 0, 0)
	local v279_, _, _ = localToLocal(target.raycastNode2, self.rootNode, 0, 0, 0)
	if v278_ < v279_ then
		local v280_ = target.raycastNode1
		target.raycastNode1 = target.raycastNode2
		target.raycastNode2 = v280_
	end
	return true
end

function Cutter:getCutterTiltIsAvailable()
	return self.spec_cutter.automaticTilt.isAvailable
end

function Cutter:getCutterTiltIsActive(automaticTilt)
	if automaticTilt.isAvailable and self.isActive then
		if self:getIsLowered(true) and (self.getAttacherVehicle == nil or self:getAttacherVehicle() ~= nil) then
			return true, false
		else
			return false, true
		end
	else
		return false, false
	end
end

-- Local values: spec, isActive, doReset
function Cutter:getCutterTiltDelta()
	local v285_ = self.spec_cutter
	local v286_, v287_ = self:getCutterTiltIsActive(v285_.automaticTilt)
	return v286_ and v285_.automaticTilt.currentDelta or 0, v286_, v287_
end

-- Local values: automaticTilt
function Cutter:tiltRaycastDetectionCallbackLeft(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, hitShapeId, isLast)
	if hitObjectId == 0 or getRigidBodyType(hitObjectId) ~= RigidBodyType.STATIC then
		return true
	end
	local v293_ = self.spec_cutter.automaticTilt
	v293_.lastHit1[1] = x
	v293_.lastHit1[2] = y
	v293_.lastHit1[3] = z
	return false
end

-- Local values: automaticTilt, rDirX, rDirY, rDirZ, hit1X, hit1Y, hit1Z, node1X, node1Y, node1Z, hit2X, hit2Y, hit2Z, node2X, node2Y, node2Z, gHeight, gRefX, gRefY, gRefZ, gDistance, gDirection, gAngle, cHeight, cDistance, cDirection, cAngle
function Cutter:tiltRaycastDetectionCallbackRight(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, hitShapeId, isLast)
	if not (self.isDeleted or self.isDeleting) then
		local v300_ = self.spec_cutter.automaticTilt
		if hitObjectId ~= 0 and getRigidBodyType(hitObjectId) == RigidBodyType.STATIC then
			v300_.lastHit2[1] = x
			v300_.lastHit2[2] = y
			v300_.lastHit2[3] = z
		end
		if isLast then
			local v301_, v302_, v303_ = localDirectionToWorld(v300_.raycastNode1, 0, -1, 0)
			local v304_ = v300_.lastHit1[1]
			local v305_ = v300_.lastHit1[2]
			local v306_ = v300_.lastHit1[3]
			local v307_, v308_, v309_ = getWorldTranslation(v300_.raycastNode1)
			local v310_ = v300_.lastHit2[1]
			local v311_ = v300_.lastHit2[2]
			local v312_ = v300_.lastHit2[3]
			local v313_, v314_, v315_ = getWorldTranslation(v300_.raycastNode2)
			local v316_ = v305_ - v311_
			local v317_ = v310_ + v301_ * v316_
			local v318_ = v311_ + v302_ * v316_
			local v319_ = v312_ + v303_ * v316_
			local v320_ = MathUtil.vector3Length(v304_ - v317_, v305_ - v318_, v306_ - v319_)
			local v321_ = v305_ < v311_ and -1 or 1
			local v322_ = math.abs(v316_) / v320_
			local v323_ = math.atan(v322_) * v321_
			local v324_ = v314_ - v308_
			local v325_ = MathUtil.vector3Length(v307_ - v313_, v308_ - v314_, v309_ - v315_)
			local v326_ = v308_ < v314_ and -1 or 1
			local v327_ = math.abs(v324_) / v325_
			local v328_ = math.atan(v327_) * v326_
			if not (MathUtil.isNan(v323_) or MathUtil.isNan(v328_)) then
				v300_.currentDelta = v323_ - v328_
			end
		end
	end
end

-- Local values: inputAttacherJoint, inputAttacherJoints, i
function Cutter:setCutterCutHeight(cutHeight)
	if cutHeight ~= nil then
		self.spec_cutter.currentCutHeight = cutHeight
		if self.spec_attachable ~= nil then
			local v331_ = self:getActiveInputAttacherJoint()
			if v331_ == nil or not v331_.useFruitCutHeight then
				local v332_ = self:getInputAttacherJoints()
				for v333_ = 1, #v332_ do
					local v334_ = v332_[v333_]
					if v334_.useFruitCutHeight and (v334_.jointType == AttacherJoints.JOINTTYPE_CUTTER or v334_.jointType == AttacherJoints.JOINTTYPE_CUTTERHARVESTER) then
						v334_.lowerDistanceToGround = cutHeight
					end
				end
			elseif v331_.jointType == AttacherJoints.JOINTTYPE_CUTTER or v331_.jointType == AttacherJoints.JOINTTYPE_CUTTERHARVESTER then
				v331_.lowerDistanceToGround = cutHeight
				return
			end
		end
	end
end

function Cutter:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end
	speedRotatingPart.rotateIfTurnedOn = xmlFile:getValue(key .. "#rotateIfTurnedOn", false)
	return true
end

function Cutter:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	if speedRotatingPart.rotateIfTurnedOn and not self:getIsTurnedOn() then
		return false
	else
		return superFunc(self, speedRotatingPart)
	end
end

-- Local values: retValue
function Cutter:loadRandomlyMovingPartFromXML(superFunc, part, xmlFile, key)
	local v348_ = superFunc(self, part, xmlFile, key)
	part.moveOnlyIfCut = xmlFile:getValue(key .. "#moveOnlyIfCut", false)
	return v348_
end

-- Local values: retValue
function Cutter:getIsRandomlyMovingPartActive(superFunc, part)
	local v352_ = superFunc(self, part)
	if part.moveOnlyIfCut then
		if v352_ then
			v352_ = self.spec_cutter.lastAreaBiggerZeroTime >= g_currentMission.time - 150
		end
	end
	return v352_
end

-- Local values: spec
function Cutter:getIsWorkAreaActive(superFunc, workArea)
	if workArea.type == WorkAreaType.CUTTER then
		local v356_ = self.spec_cutter
		if (self.getAllowsLowering == nil or self:getAllowsLowering()) and not (v356_.allowCuttingWhileRaised or self:getIsLowered(true)) then
			return false
		end
	end
	return superFunc(self, workArea)
end

function Cutter:doCheckSpeedLimit(superFunc)
	local v359_ = not superFunc(self) and self:getIsTurnedOn()
	if v359_ then
		v359_ = self.getIsLowered == nil and true or self:getIsLowered()
	end
	return v359_
end

-- Local values: retValue
function Cutter:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local v365_ = superFunc(self, workArea, xmlFile, key)
	workArea.chopperAreaIndex = xmlFile:getValue(key .. ".chopperArea#index")
	return v365_
end

-- Local values: spec
function Cutter:getDirtMultiplier(superFunc)
	if self.spec_cutter.isWorking then
		return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	else
		return superFunc(self)
	end
end

-- Local values: spec, stoneMultiplier
function Cutter:getWearMultiplier(superFunc)
	local v370_ = self.spec_cutter
	if not v370_.isWorking then
		return superFunc(self)
	end
	local v371_ = (v370_.stoneLastState == 0 or v370_.stoneWearMultiplierData == nil) and 1 or (v370_.stoneWearMultiplierData[v370_.stoneLastState] or 1)
	return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * v371_
end

-- Local values: spec
function Cutter:isAttachAllowed(superFunc, farmId, attacherVehicle)
	local v376_ = self.spec_cutter
	if attacherVehicle.spec_combine == nil or attacherVehicle:getIsCutterCompatible(v376_.outputFillTypes) then
		return superFunc(self, farmId, attacherVehicle)
	else
		return false, g_i18n:getText("warning_cutterNotCompatible")
	end
end

-- Local values: value, count, loadPercentage
function Cutter:getConsumingLoad(superFunc)
	local v379_, v380_ = superFunc(self)
	return v379_ + self:getCutterLoad(), v380_ + 1
end

-- Local values: threshold
function Cutter:getIsGroundReferenceNodeThreshold(superFunc, groundReferenceNode)
	return superFunc(self, groundReferenceNode) + self.spec_cutter.currentCutHeight
end

function Cutter:getDefaultAllowComponentMassReduction()
	return true
end

function Cutter:loadInputAttacherJoint(superFunc, xmlFile, key, inputAttacherJoint, i)
	if not superFunc(self, xmlFile, key, inputAttacherJoint, i) then
		return false
	end
	inputAttacherJoint.useFruitCutHeight = xmlFile:getValue(key .. "#useFruitCutHeight", true)
	return true
end

function Cutter:getFruitExtraObjectTypeData(superFunc)
	return self.spec_cutter.lastValidInputFruitType, nil
end

-- Local values: spec
function Cutter:onTurnedOn()
	if self.isClient then
		local v392_ = self.spec_cutter
		g_animationManager:startAnimations(v392_.animationNodes)
	end
end

-- Local values: spec
function Cutter:onTurnedOff()
	local v394_ = self.spec_cutter
	if self.isClient then
		g_animationManager:stopAnimations(v394_.animationNodes)
	end
	v394_.currentInputFruitType = FruitType.UNKNOWN
	v394_.currentInputFruitTypeSent = FruitType.UNKNOWN
	v394_.currentInputFruitTypeAI = FruitType.UNKNOWN
	v394_.currentInputFillType = FillType.UNKNOWN
	v394_.currentOutputFillType = FillType.UNKNOWN
end

-- Local values: spec, _, fruitTypeIndex, fruitType, outputFillType, minState
function Cutter:onAIImplementStart()
	if self:getAllowCutterAIFruitRequirements() then
		self:clearAIFruitRequirements()
		local v396_ = self.spec_cutter
		for _, v397_ in ipairs(v396_.fruitTypeIndices) do
			local v398_ = g_fruitTypeManager:getFruitTypeByIndex(v397_)
			if v398_ ~= nil then
				local v399_ = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(v397_)
				if v396_.fruitTypeConverters[v397_] ~= nil then
					v399_ = v396_.fruitTypeConverters[v397_].fillTypeIndex
				end
				if self:getCombine(v397_, v399_) ~= nil then
					local v400_ = v396_.allowsForageGrowthState and v398_.minForageGrowthState or v398_.minHarvestingGrowthState
					self:addAIFruitRequirement(v398_.index, v400_, v398_.maxHarvestingGrowthState)
				end
			end
		end
	end
end

function Cutter:onAIFieldCourseSettingsInitialized(fieldCourseSettings)
	fieldCourseSettings.headlandsFirst = true
	fieldCourseSettings.workInitialSegment = true
	fieldCourseSettings.cornerCutOutSupported = true
end
function Cutter.getDefaultSpeedLimit()
	return 10
end

-- Local values: spec, sum, fillType, value, fillType, value
function Cutter:updateDebugValues(values)
	local v404_ = self.spec_cutter
	local v405_ = {
		["name"] = "lastPrioritizedOutputType",
		["value"] = string.format("%s", g_fillTypeManager:getFillTypeNameByIndex(v404_.lastPrioritizedOutputType))
	}
	table.insert(values, v405_)
	local v406_ = {
		["name"] = "currentCutHeight",
		["value"] = string.format("%.2f", v404_.currentCutHeight)
	}
	table.insert(values, v406_)
	local v407_ = 0
	for _, v408_ in pairs(v404_.lastOutputFillTypes) do
		v407_ = v407_ + v408_
	end
	for v409_, v410_ in pairs(v404_.lastOutputFillTypes) do
		local v411_ = {
			["name"] = string.format("buffer (%s)", g_fillTypeManager:getFillTypeNameByIndex(v409_)),
			["value"] = string.format("%.0f%%", v410_ / math.max(v407_, 0.01) * 100)
		}
		table.insert(values, v411_)
	end
end
