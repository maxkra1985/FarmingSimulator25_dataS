-- Local values: TensionBeltsActivatable_mt
source("dataS/scripts/vehicles/specializations/events/TensionBeltsEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TensionBeltsRefreshEvent.lua")
TensionBelts = {}
TensionBelts.debugRendering = false
TensionBelts.NUM_SEND_BITS = 5

function TensionBelts.prerequisitesPresent(unusedSelf)
	return true
end
function TensionBelts.initSpecialization()
	g_vehicleConfigurationManager:addConfigurationType("tensionBelts", g_i18n:getText("configuration_tensionBelts"), "tensionBelts", VehicleConfigurationItem)
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("TensionBelts")
	v1_:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#totalInteractionRadius", "Total interaction radius", 6)
	v1_:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#interactionRadius", "Interaction radius", 1)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#interactionBaseNode", "Interaction base node", "Vehicle root node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#activationTrigger", "Activation trigger")
	v1_:register(XMLValueType.STRING, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#tensionBeltType", "Supports tension belts", "basic")
	v1_:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#width", "Belt width", "Used from belt definitions")
	v1_:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#ratchetPosition", "Ratchet position")
	v1_:register(XMLValueType.BOOL, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#useHooks", "Use hooks", true)
	v1_:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#maxEdgeLength", "Max. edge length", 0.1)
	v1_:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#geometryBias", "Geometry bias", 0.01)
	v1_:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#defaultOffsetSide", "Default offset side", 0.1)
	v1_:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#defaultOffset", "Default offset", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#defaultHeight", "Default height", 5)
	v1_:register(XMLValueType.BOOL, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#allowFoldingWhileFasten", "Folding is allowed while tension belts are fasten", true)
	v1_:register(XMLValueType.BOOL, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#allowDischargeWhileFasten", "Discharging is allowed while tension belts are fasten", true)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#linkNode", "Link node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#rootNode", "Root node", "Root component")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts#jointNode", "Joint node", "rootNode")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#startNode", "Start node")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#endNode", "End node")
	v1_:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#offsetLeft", "Offset left")
	v1_:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#offsetRight", "Offset right")
	v1_:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#offset", "Offset")
	v1_:register(XMLValueType.FLOAT, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#height", "Height")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#linkNode", "Custom link node for visual tension belts")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)#jointNode", "Custom joint node for to mount the objects to")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?).intersectionNode(?)#node", "Intersection node")
	ObjectChangeUtil.registerObjectChangeXMLPaths(v1_, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.tensionBelt(?)")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.sounds", "toggleBelt")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.sounds", "addBelt")
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(?).tensionBelts.sounds", "removeBelt")
	v1_:addDelayedRegistrationFunc("Cylindered:movingTool", function(p2_, p3_)
		p2_:register(XMLValueType.BOOL, p3_ .. ".tensionBelts#allowedMounted", "Allow moving tool movement while something is mounted", true)
	end)
	v1_:setXMLSpecializationType()
	Vehicle.xmlSchemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).tensionBelts.belt(?)#isActive", "Belt is active", false)
end

function TensionBelts.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "createTensionBelt", TensionBelts.createTensionBelt)
	SpecializationUtil.registerFunction(vehicleType, "removeTensionBelt", TensionBelts.removeTensionBelt)
	SpecializationUtil.registerFunction(vehicleType, "setTensionBeltsActive", TensionBelts.setTensionBeltsActive)
	SpecializationUtil.registerFunction(vehicleType, "setAllTensionBeltsActive", TensionBelts.setAllTensionBeltsActive)
	SpecializationUtil.registerFunction(vehicleType, "objectOverlapCallback", TensionBelts.objectOverlapCallback)
	SpecializationUtil.registerFunction(vehicleType, "getTensionBeltObjectCanBeMounted", TensionBelts.getTensionBeltObjectCanBeMounted)
	SpecializationUtil.registerFunction(vehicleType, "getObjectToMount", TensionBelts.getObjectToMount)
	SpecializationUtil.registerFunction(vehicleType, "getObjectsToUnmount", TensionBelts.getObjectsToUnmount)
	SpecializationUtil.registerFunction(vehicleType, "updateFastenState", TensionBelts.updateFastenState)
	SpecializationUtil.registerFunction(vehicleType, "refreshTensionBelts", TensionBelts.refreshTensionBelts)
	SpecializationUtil.registerFunction(vehicleType, "freeTensionBeltObject", TensionBelts.freeTensionBeltObject)
	SpecializationUtil.registerFunction(vehicleType, "lockTensionBeltObject", TensionBelts.lockTensionBeltObject)
	SpecializationUtil.registerFunction(vehicleType, "getIsPlayerInTensionBeltsRange", TensionBelts.getIsPlayerInTensionBeltsRange)
	SpecializationUtil.registerFunction(vehicleType, "getIsDynamicallyMountedNode", TensionBelts.getIsDynamicallyMountedNode)
	SpecializationUtil.registerFunction(vehicleType, "tensionBeltActivationTriggerCallback", TensionBelts.tensionBeltActivationTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "onTensionBeltTreeShapeCut", TensionBelts.onTensionBeltTreeShapeCut)
end

function TensionBelts.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", TensionBelts.getIsReadyForAutomatedTrainTravel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", TensionBelts.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", TensionBelts.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingToolFromXML", TensionBelts.loadMovingToolFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", TensionBelts.getIsMovingToolActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToGround", TensionBelts.getCanDischargeToGround)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanDischargeToObject", TensionBelts.getCanDischargeToObject)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", TensionBelts.getFillLevelInformation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getHasObjectMounted", TensionBelts.getHasObjectMounted)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", TensionBelts.getAdditionalComponentMass)
end

function TensionBelts.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDelete", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", TensionBelts)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", TensionBelts)
end

-- Local values: spec, tensionBeltConfigurationId, configKey, activationTrigger, tensionBeltType, beltData, rigidBodyType, x, y, z, rx, ry, rz, i, key, startNode, endNode, endX, endY, _, offsetLeft, offsetRight, offset, height, intersectionNodes, j, intersectionKey, node, linkNode, jointNode, changeObjects, belt, minX, minZ, maxX, maxZ, _, belt, sx, _, sz, ex, _, ez, _, belt, sx, _, sz, sl, el
function TensionBelts:onLoad(savegame)
	local v8_ = self.spec_tensionBelts
	local v9_ = Utils.getNoNil(self.configurations.tensionBelts, 1)
	local v10_ = string.format("vehicle.tensionBelts.tensionBeltsConfigurations.tensionBeltsConfiguration(%d).tensionBelts", v9_ - 1)
	v8_.hasTensionBelts = true
	if not self.xmlFile:hasProperty(v10_) then
		v8_.hasTensionBelts = false
		SpecializationUtil.removeEventListener(self, "onPostLoad", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onDelete", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onPreDelete", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onReadStream", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onWriteStream", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onUpdate", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onDraw", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", TensionBelts)
		return
	end
	v8_.belts = {}
	v8_.tensionBelts = {}
	v8_.singleBelts = {}
	v8_.sortedBelts = {}
	v8_.activatable = TensionBeltsActivatable.new(self)
	v8_.totalInteractionRadius = self.xmlFile:getValue(v10_ .. "#totalInteractionRadius", 6)
	v8_.interactionRadius = self.xmlFile:getValue(v10_ .. "#interactionRadius", 1)
	v8_.interactionBaseNode = self.xmlFile:getValue(v10_ .. "#interactionBaseNode", self.rootNode, self.components, self.i3dMappings)
	local v11_ = self.xmlFile:getValue(v10_ .. "#activationTrigger", nil, self.components, self.i3dMappings)
	if v11_ ~= nil then
		if getCollisionFilterGroup(v11_) == CollisionFlag.TRIGGER then
			if getCollisionFilterMask(v11_) == CollisionFlag.PLAYER then
				addTrigger(v11_, "tensionBeltActivationTriggerCallback", self)
				v8_.activationTrigger = v11_
			else
				Logging.xmlError(self.xmlFile, "Wrong collision filter mask for tension belt activation trigger \'%s\'. Should only have %s", getName(v11_), CollisionFlag.getBitAndName(CollisionFlag.PLAYER))
			end
		else
			Logging.xmlError(self.xmlFile, "Wrong collision filter group set for tension belt activation trigger \'%s\'. Should only have %s", getName(v11_), CollisionFlag.getBitAndName(CollisionFlag.TRIGGER))
		end
	end
	v8_.allowFoldingWhileFasten = self.xmlFile:getValue(v10_ .. "#allowFoldingWhileFasten", true)
	v8_.allowDischargeWhileFasten = self.xmlFile:getValue(v10_ .. "#allowDischargeWhileFasten", true)
	v8_.isPlayerInTrigger = false
	v8_.checkSizeOffsets = { 0, 2.5, 1.5 }
	v8_.objectsInTensionBeltRange = {}
	v8_.numObjectsIntensionBeltRange = 0
	local v12_ = self.xmlFile:getValue(v10_ .. "#tensionBeltType", "basic")
	local v13_ = g_tensionBeltManager:getBeltData(v12_)
	if v13_ == nil then
		Logging.xmlWarning(self.xmlFile, "No belt data found for tension belt type %s", v12_)
	else
		v8_.width = self.xmlFile:getValue(v10_ .. "#width")
		v8_.ratchetPosition = self.xmlFile:getValue(v10_ .. "#ratchetPosition")
		v8_.useHooks = self.xmlFile:getValue(v10_ .. "#useHooks", true)
		v8_.maxEdgeLength = self.xmlFile:getValue(v10_ .. "#maxEdgeLength", 0.1)
		v8_.geometryBias = self.xmlFile:getValue(v10_ .. "#geometryBias", 0.01)
		v8_.defaultOffsetSide = self.xmlFile:getValue(v10_ .. "#defaultOffsetSide", 0.1)
		v8_.defaultOffset = self.xmlFile:getValue(v10_ .. "#defaultOffset", 0)
		v8_.defaultHeight = self.xmlFile:getValue(v10_ .. "#defaultHeight", 5)
		v8_.beltData = v13_
		v8_.linkNode = self.xmlFile:getValue(v10_ .. "#linkNode", nil, self.components, self.i3dMappings)
		v8_.rootNode = self.xmlFile:getValue(v10_ .. "#rootNode", self.components[1].node, self.components, self.i3dMappings)
		v8_.jointNode = self.xmlFile:getValue(v10_ .. "#jointNode", v8_.rootNode, self.components, self.i3dMappings)
		v8_.checkTimerDuration = 500
		v8_.checkTimer = v8_.checkTimerDuration
		if v8_.linkNode == nil then
			Logging.xmlError(self.xmlFile, "No tension belts link node given at %s%s", v10_, "#linkNode")
			self:setLoadingState(VehicleLoadingState.ERROR)
			return
		end
		if getRigidBodyType(v8_.jointNode) ~= RigidBodyType.DYNAMIC and getRigidBodyType(v8_.jointNode) ~= RigidBodyType.KINEMATIC then
			Logging.xmlError(self.xmlFile, "Given jointNode \'" .. getName(v8_.jointNode) .. "\' has invalid rigidBodyType. Have to be \'Dynamic\' or \'Kinematic\'! Using \'" .. getName(self.components[1].node) .. "\' instead!")
			v8_.jointNode = self.components[1].node
		end
		v8_.isDynamic = getRigidBodyType(v8_.jointNode) == RigidBodyType.DYNAMIC
		local v14_, v15_, v16_ = localToLocal(v8_.linkNode, v8_.jointNode, 0, 0, 0)
		local v17_, v18_, v19_ = localRotationToLocal(v8_.linkNode, v8_.jointNode, 0, 0, 0)
		v8_.linkNodePosition = { v14_, v15_, v16_ }
		v8_.linkNodeRotation = { v17_, v18_, v19_ }
		v8_.jointComponent = self:getParentComponent(v8_.jointNode)
		local v20_ = 0
		while true do
			local v21_ = string.format(v10_ .. ".tensionBelt(%d)", v20_)
			if not self.xmlFile:hasProperty(v21_) then
				break
			end
			if #v8_.sortedBelts == 2 ^ TensionBelts.NUM_SEND_BITS then
				Logging.xmlWarning(self.xmlFile, "Max number of tension belts is " .. 2 ^ TensionBelts.NUM_SEND_BITS .. "!")
				break
			end
			local v22_ = self.xmlFile:getValue(v21_ .. "#startNode", nil, self.components, self.i3dMappings)
			local v23_ = self.xmlFile:getValue(v21_ .. "#endNode", nil, self.components, self.i3dMappings)
			if v22_ ~= nil and v23_ ~= nil then
				local v24_, v25_, _ = getTranslation(v23_)
				if math.abs(v24_) < 0.0001 and math.abs(v25_) < 0.0001 then
					if v8_.linkNode == nil then
						v8_.linkNode = getParent(v22_)
					end
					if v8_.startNode == nil then
						v8_.startNode = v22_
					end
					v8_.endNode = v23_
					local v26_ = self.xmlFile:getValue(v21_ .. "#offsetLeft")
					local v27_ = self.xmlFile:getValue(v21_ .. "#offsetRight")
					local v28_ = self.xmlFile:getValue(v21_ .. "#offset")
					local v29_ = self.xmlFile:getValue(v21_ .. "#height")
					local v30_ = 0
					local v31_ = {}
					while true do
						local v32_ = string.format(v21_ .. ".intersectionNode(%d)", v30_)
						if not self.xmlFile:hasProperty(v32_) then
							break
						end
						local v33_ = self.xmlFile:getValue(v32_ .. "#node", nil, self.components, self.i3dMappings)
						if v33_ ~= nil then
							table.insert(v31_, v33_)
						end
						v30_ = v30_ + 1
					end
					local v34_ = self.xmlFile:getValue(v21_ .. "#linkNode", nil, self.components, self.i3dMappings)
					local v35_ = self.xmlFile:getValue(v21_ .. "#jointNode", nil, self.components, self.i3dMappings)
					local v36_ = {}
					ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, v21_, v36_, self.components, self)
					ObjectChangeUtil.setObjectChanges(v36_, false, self, self.setMovingToolDirty)
					local v37_ = {
						["id"] = v20_ + 1,
						["startNode"] = v22_,
						["endNode"] = v23_,
						["offsetLeft"] = v26_,
						["offsetRight"] = v27_,
						["offset"] = v28_,
						["height"] = v29_,
						["mesh"] = nil,
						["intersectionNodes"] = v31_,
						["changeObjects"] = v36_,
						["linkNode"] = v34_,
						["jointNode"] = v35_,
						["dummy"] = nil,
						["objectsToMount"] = nil
					}
					v8_.singleBelts[v37_] = v37_
					local v38_ = v8_.sortedBelts
					table.insert(v38_, v37_)
				else
					Logging.xmlWarning(self.xmlFile, "x and y position of endNode need to be 0 for tension belt \'" .. v21_ .. "\'")
				end
			end
			v20_ = v20_ + 1
		end
		local v39_ = math.huge
		local v40_ = math.huge
		local v41_ = -math.huge
		local v42_ = -math.huge
		for _, v43_ in pairs(v8_.singleBelts) do
			local v44_, _, v45_ = localToLocal(v43_.startNode, v8_.interactionBaseNode, 0, 0, 0)
			local v46_, _, v47_ = localToLocal(v43_.endNode, v8_.interactionBaseNode, 0, 0, 0)
			v39_ = math.min(v39_, v44_, v46_)
			v40_ = math.min(v40_, v45_, v47_)
			v41_ = math.max(v41_, v44_, v46_)
			v42_ = math.max(v42_, v45_, v47_)
		end
		v8_.interactionBasePointX = (v41_ + v39_) / 2
		v8_.interactionBasePointZ = (v42_ + v40_) / 2
		for _, v48_ in pairs(v8_.singleBelts) do
			local v49_, _, v50_ = localToLocal(v48_.startNode, v8_.interactionBaseNode, 0, 0, 0)
			local v51_ = MathUtil.vector2Length(v8_.interactionBasePointX - v49_, v8_.interactionBasePointZ - v50_) + 1
			local v52_ = MathUtil.vector2Length(v8_.interactionBasePointX - v49_, v8_.interactionBasePointZ - v50_) + 1
			local v53_ = v8_.totalInteractionRadius
			v8_.totalInteractionRadius = math.max(v53_, v51_, v52_)
		end
	end
	v8_.hasTensionBelts = #v8_.sortedBelts > 0
	v8_.checkBoxes = {}
	v8_.objectsToJoint = {}
	v8_.isPlayerInRange = false
	v8_.currentBelt = nil
	v8_.areAllBeltsFastened = false
	v8_.fastenedAllBeltsIndex = -1
	v8_.fastenedAllBeltsState = true
	if self.isClient then
		v8_.samples = {}
		v8_.samples.toggleBelt = g_soundManager:loadSampleFromXML(self.xmlFile, v10_ .. ".sounds", "toggleBelt", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v8_.samples.addBelt = g_soundManager:loadSampleFromXML(self.xmlFile, v10_ .. ".sounds", "addBelt", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v8_.samples.removeBelt = g_soundManager:loadSampleFromXML(self.xmlFile, v10_ .. ".sounds", "removeBelt", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v8_.texts = {}
	v8_.texts.warningFoldingTensionBelts = g_i18n:getText("warning_foldingNotWhileTensionBeltsFasten")
	if v8_.hasTensionBelts then
		g_messageCenter:subscribe(MessageType.TREE_SHAPE_CUT, self.onTensionBeltTreeShapeCut, self)
	else
		SpecializationUtil.removeEventListener(self, "onPostLoad", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onDelete", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onPreDelete", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onReadStream", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onWriteStream", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onUpdate", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onDraw", TensionBelts)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", TensionBelts)
		if v8_.activationTrigger ~= nil then
			removeTrigger(v8_.activationTrigger)
			v8_.activationTrigger = nil
			return
		end
	end
end

-- Local values: spec, i, key
function TensionBelts:onPostLoad(savegame)
	if savegame ~= nil then
		local v56_ = self.spec_tensionBelts
		v56_.beltsToLoad = {}
		local v57_ = 0
		while true do
			local v58_ = string.format("%s.tensionBelts.belt(%d)", savegame.key, v57_)
			if not savegame.xmlFile:hasProperty(v58_) then
				break
			end
			if savegame.xmlFile:getValue(v58_ .. "#isActive") then
				local v59_ = v56_.beltsToLoad
				local v60_ = v57_ + 1
				table.insert(v59_, v60_)
			end
			v57_ = v57_ + 1
		end
	end
end

-- Local values: spec, i, belt, beltKey
function TensionBelts:saveToXMLFile(xmlFile, key, usedModNames)
	local v64_ = self.spec_tensionBelts
	if v64_.hasTensionBelts then
		for v65_, v66_ in ipairs(v64_.sortedBelts) do
			xmlFile:setValue(string.format("%s.belt(%d)", key, v65_ - 1) .. "#isActive", v66_.mesh ~= nil)
		end
	end
end

-- Local values: _, belt, objects, _, id, _
function TensionBelts:onPreDelete()
	if self.spec_tensionBelts.sortedBelts ~= nil then
		for _, v68_ in pairs(self.spec_tensionBelts.sortedBelts) do
			local v69_, _ = self:getObjectToMount(v68_)
			for v70_, _ in pairs(v69_) do
				I3DUtil.wakeUpObject(v70_)
			end
		end
	end
end

-- Local values: spec
function TensionBelts:onDelete()
	local v72_ = self.spec_tensionBelts
	v72_.isPlayerInRange = false
	g_currentMission.activatableObjectsSystem:removeActivatable(v72_.activatable)
	self:setTensionBeltsActive(false, nil, true, false)
	if v72_.activationTrigger ~= nil then
		removeTrigger(v72_.activationTrigger)
		v72_.activationTrigger = nil
	end
	g_soundManager:deleteSamples(v72_.samples)
end

-- Local values: spec, k, _, beltActive
function TensionBelts:onReadStream(streamId, connection)
	local v75_ = self.spec_tensionBelts
	if v75_.tensionBelts ~= nil then
		v75_.beltsToLoad = {}
		for v76_, _ in ipairs(v75_.sortedBelts) do
			if streamReadBool(streamId) then
				local v77_ = v75_.beltsToLoad
				table.insert(v77_, v76_)
			end
		end
	end
end

-- Local values: spec, _, belt
function TensionBelts:onWriteStream(streamId, connection)
	local v80_ = self.spec_tensionBelts
	if v80_.tensionBelts ~= nil then
		for _, v81_ in ipairs(v80_.sortedBelts) do
			streamWriteBool(streamId, v81_.mesh ~= nil)
		end
	end
end

-- Local values: spec, beltIndex, noEventSend, x, y, z, rx, ry, rz, isDirty, _, joint, belt, belt, _, i, _, box, p, c, wx, wy, wz, i, x, y, z, _, belt, currentBelt, wasInRange, objects, _
function TensionBelts:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v83_ = self.spec_tensionBelts
	if v83_.beltsToLoad ~= nil then
		if #v83_.beltsToLoad > 0 then
			local v84_ = v83_.beltsToLoad[#v83_.beltsToLoad]
			local v85_ = not self.isServer
			self:setTensionBeltsActive(true, v83_.sortedBelts[v84_].id, v85_, false)
			table.remove(v83_.beltsToLoad, #v83_.beltsToLoad)
		else
			v83_.beltsToLoad = nil
		end
	end
	if self.isServer and v83_.isDynamic then
		local v86_, v87_, v88_ = localToLocal(v83_.linkNode, v83_.jointNode, 0, 0, 0)
		local v89_, v90_, v91_ = localRotationToLocal(v83_.linkNode, v83_.jointNode, 0, 0, 0)
		local v92_ = false
		local v93_ = v86_ - v83_.linkNodePosition[1]
		local v94_
		if math.abs(v93_) > 0.001 then
			v94_ = true
		else
			local v95_ = v87_ - v83_.linkNodePosition[2]
			if math.abs(v95_) > 0.001 then
				v94_ = true
			else
				local v96_ = v88_ - v83_.linkNodePosition[3]
				if math.abs(v96_) > 0.001 then
					v94_ = true
				else
					local v97_ = v89_ - v83_.linkNodeRotation[1]
					if math.abs(v97_) > 0.001 then
						v94_ = true
					else
						local v98_ = v90_ - v83_.linkNodeRotation[2]
						if math.abs(v98_) > 0.001 then
							v94_ = true
						else
							local v99_ = v91_ - v83_.linkNodeRotation[3]
							v94_ = math.abs(v99_) > 0.001 and true or v92_
						end
					end
				end
			end
		end
		if v94_ then
			local v100_ = v83_.linkNodePosition
			local v101_ = v83_.linkNodePosition
			local v102_ = v83_.linkNodePosition
			v100_[1] = v86_
			v101_[2] = v87_
			v102_[3] = v88_
			local v103_ = v83_.linkNodeRotation
			local v104_ = v83_.linkNodeRotation
			local v105_ = v83_.linkNodeRotation
			v103_[1] = v89_
			v104_[2] = v90_
			v105_[3] = v91_
			for _, v106_ in pairs(v83_.objectsToJoint) do
				setJointFrame(v106_.jointIndex, 0, v106_.jointTransform)
			end
		end
	end
	if self.isClient and v83_.fastenedAllBeltsIndex > 0 then
		local v107_ = v83_.sortedBelts[v83_.fastenedAllBeltsIndex]
		if v107_ ~= nil then
			self:setTensionBeltsActive(v83_.fastenedAllBeltsState, v107_.id, false)
		end
		v83_.fastenedAllBeltsIndex = v83_.fastenedAllBeltsIndex + 1
		if v83_.fastenedAllBeltsIndex > #v83_.sortedBelts then
			v83_.fastenedAllBeltsIndex = -1
		end
	end
	if TensionBelts.debugRendering then
		for v108_, _ in pairs(v83_.belts) do
			DebugGizmo.renderAtNode(v108_, v108_.id, false, 0.5)
			for v109_ = 0, getNumOfChildren(v108_) - 1 do
				DebugGizmo.renderAtNode(getChildAt(v108_, v109_), string.format("%s-%d", v108_.id, v109_), false, 0.2)
			end
		end
		if v83_.checkBoxes ~= nil then
			for _, v110_ in pairs(v83_.checkBoxes) do
				local v111_ = v110_.points
				local v112_ = v110_.color
				drawDebugLine(v111_[1][1], v111_[1][2], v111_[1][3], v112_[1], v112_[2], v112_[3], v111_[2][1], v111_[2][2], v111_[2][3], v112_[1], v112_[2], v112_[3])
				drawDebugLine(v111_[2][1], v111_[2][2], v111_[2][3], v112_[1], v112_[2], v112_[3], v111_[3][1], v111_[3][2], v111_[3][3], v112_[1], v112_[2], v112_[3])
				drawDebugLine(v111_[3][1], v111_[3][2], v111_[3][3], v112_[1], v112_[2], v112_[3], v111_[4][1], v111_[4][2], v111_[4][3], v112_[1], v112_[2], v112_[3])
				drawDebugLine(v111_[4][1], v111_[4][2], v111_[4][3], v112_[1], v112_[2], v112_[3], v111_[1][1], v111_[1][2], v111_[1][3], v112_[1], v112_[2], v112_[3])
				drawDebugLine(v111_[5][1], v111_[5][2], v111_[5][3], v112_[1], v112_[2], v112_[3], v111_[6][1], v111_[6][2], v111_[6][3], v112_[1], v112_[2], v112_[3])
				drawDebugLine(v111_[6][1], v111_[6][2], v111_[6][3], v112_[1], v112_[2], v112_[3], v111_[7][1], v111_[7][2], v111_[7][3], v112_[1], v112_[2], v112_[3])
				drawDebugLine(v111_[7][1], v111_[7][2], v111_[7][3], v112_[1], v112_[2], v112_[3], v111_[8][1], v111_[8][2], v111_[8][3], v112_[1], v112_[2], v112_[3])
				drawDebugLine(v111_[8][1], v111_[8][2], v111_[8][3], v112_[1], v112_[2], v112_[3], v111_[5][1], v111_[5][2], v111_[5][3], v112_[1], v112_[2], v112_[3])
				drawDebugLine(v111_[1][1], v111_[1][2], v111_[1][3], v112_[1], v112_[2], v112_[3], v111_[5][1], v111_[5][2], v111_[5][3], v112_[1], v112_[2], v112_[3])
				drawDebugLine(v111_[4][1], v111_[4][2], v111_[4][3], v112_[1], v112_[2], v112_[3], v111_[8][1], v111_[8][2], v111_[8][3], v112_[1], v112_[2], v112_[3])
				drawDebugLine(v111_[2][1], v111_[2][2], v111_[2][3], v112_[1], v112_[2], v112_[3], v111_[6][1], v111_[6][2], v111_[6][3], v112_[1], v112_[2], v112_[3])
				drawDebugLine(v111_[3][1], v111_[3][2], v111_[3][3], v112_[1], v112_[2], v112_[3], v111_[7][1], v111_[7][2], v111_[7][3], v112_[1], v112_[2], v112_[3])
				drawDebugPoint(v111_[9][1], v111_[9][2], v111_[9][3], 1, 1, 1, 1)
			end
		end
		local v113_, v114_, v115_ = localToWorld(v83_.interactionBaseNode, v83_.interactionBasePointX, 0, v83_.interactionBasePointZ)
		drawDebugPoint(v113_, v114_, v115_, 0, 0, 1, 1, false)
		for v116_ = 0, 350, 10 do
			local v117_ = localToWorld
			local v118_ = v83_.interactionBaseNode
			local v119_ = v83_.interactionBasePointX
			local v120_ = math.rad(v116_)
			local v121_ = v119_ + math.cos(v120_) * v83_.totalInteractionRadius
			local v122_ = v83_.interactionBasePointZ
			local v123_ = math.rad(v116_)
			local v124_, v125_, v126_ = v117_(v118_, v121_, 0, v122_ + math.sin(v123_) * v83_.totalInteractionRadius)
			drawDebugPoint(v124_, v125_, v126_, 1, 1, 1, 1)
			for _, v127_ in pairs(v83_.singleBelts) do
				local v128_ = localToWorld
				local v129_ = v127_.startNode
				local v130_ = math.rad(v116_)
				local v131_ = math.cos(v130_) * v83_.interactionRadius
				local v132_ = math.rad(v116_)
				local v133_, v134_, v135_ = v128_(v129_, v131_, 0, math.sin(v132_) * v83_.interactionRadius)
				drawDebugPoint(v133_, v134_, v135_, 0, 1, 0, 1)
				local v136_ = localToWorld
				local v137_ = v127_.endNode
				local v138_ = math.rad(v116_)
				local v139_ = math.cos(v138_) * v83_.interactionRadius
				local v140_ = math.rad(v116_)
				local v141_, v142_, v143_ = v136_(v137_, v139_, 0, math.sin(v140_) * v83_.interactionRadius)
				drawDebugPoint(v141_, v142_, v143_, 1, 0, 0, 1)
			end
		end
	end
	if v83_.isPlayerInTrigger or v83_.isPlayerInRange then
		self:raiseActive()
	end
	local v144_ = v83_.isPlayerInRange
	local v145_, v146_ = self:getIsPlayerInTensionBeltsRange()
	v83_.isPlayerInRange = v145_
	if v83_.isPlayerInRange then
		if v146_ ~= v83_.currentBelt then
			if v83_.currentBelt ~= nil and v83_.currentBelt.dummy ~= nil then
				delete(v83_.currentBelt.dummy)
				v83_.currentBelt.dummy = nil
			end
			v83_.currentBelt = v146_
			if v83_.currentBelt ~= nil and v83_.currentBelt.mesh == nil then
				local v147_, _ = self:getObjectToMount(v83_.currentBelt)
				self:createTensionBelt(v83_.currentBelt, true, v147_)
			end
		end
		g_currentMission.activatableObjectsSystem:addActivatable(v83_.activatable)
		v83_.activatable:updateActivateText()
	elseif v144_ then
		g_currentMission.activatableObjectsSystem:removeActivatable(v83_.activatable)
		if v83_.currentBelt ~= nil and v83_.currentBelt.dummy ~= nil then
			delete(v83_.currentBelt.dummy)
			v83_.currentBelt.dummy = nil
			v83_.currentBelt = nil
		end
	end
end

-- Local values: spec, needUpdate, phyiscObject, _
function TensionBelts:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v150_ = self.spec_tensionBelts
	if not v150_.hasTensionBelts then
		return
	end
	if self.isServer and v150_.tensionBelts ~= nil then
		v150_.checkTimer = v150_.checkTimer - dt
		if v150_.checkTimer < 0 then
			local v151_ = false
			for v152_, _ in pairs(v150_.objectsToJoint) do
				if not entityExists(v152_) then
					v150_.objectsToJoint[v152_] = nil
					v151_ = true
					break
				end
			end
			if v151_ then
				self:refreshTensionBelts()
			end
			v150_.checkTimer = v150_.checkTimerDuration
		end
	end
end

-- Local values: spec
function TensionBelts:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v156_ = self.spec_tensionBelts
	if v156_.hasTensionBelts then
		if isActiveForInputIgnoreSelection and isSelected then
			if v156_.areAllBeltsFastened then
				g_inputBinding:setActionEventText(self.toggleTensionBeltActionEvent, g_i18n:getText("action_unfastenTensionBelts"))
				return
			end
			g_inputBinding:setActionEventText(self.toggleTensionBeltActionEvent, g_i18n:getText("action_fastenTensionBelts"))
		end
	end
end

-- Local values: _, belt, objects, _
function TensionBelts:refreshTensionBelts()
	if self.isServer and g_server ~= nil then
		g_server:broadcastEvent(TensionBeltsRefreshEvent.new(self), nil, nil, self)
	end
	for _, v158_ in pairs(self.spec_tensionBelts.sortedBelts) do
		if v158_.mesh ~= nil then
			self:removeTensionBelt(v158_)
			local v159_, _ = self:getObjectToMount(v158_)
			self:createTensionBelt(v158_, false, v159_)
		end
	end
end

-- Local values: jointData, parentNode, x, y, z, rx, ry, rz
function TensionBelts:freeTensionBeltObject(objectId, objectsToJointTable, isDynamic, object)
	if entityExists(objectId) then
		local v164_ = objectsToJointTable[objectId]
		if v164_.jointIndex == nil then
			local v165_
			if v164_ == nil then
				v165_ = nil
			else
				v165_ = v164_.parent
			end
			if v165_ == nil or entityExists(v165_) then
				if v165_ == nil then
					v165_ = getRootNode()
				end
				local v166_, v167_, v168_ = getWorldTranslation(objectId)
				local v169_, v170_, v171_ = getWorldRotation(objectId)
				if object == nil or object.unmountKinematic == nil then
					if self.isServer then
						link(v165_, objectId)
						setWorldTranslation(objectId, v166_, v167_, v168_)
						setWorldRotation(objectId, v169_, v170_, v171_)
						setRigidBodyType(objectId, RigidBodyType.DYNAMIC)
					end
				else
					object:unmountKinematic()
				end
			else
				delete(objectId)
			end
		elseif self.isServer and v164_ ~= nil then
			removeJoint(v164_.jointIndex)
			delete(v164_.jointTransform)
			if getSplitType(objectId) ~= 0 then
				setInertiaScale(objectId, 1, 1, 1)
			end
			if v164_.objectMass ~= nil then
				setMass(objectId, v164_.objectMass)
				self:setMassDirty()
			end
			if object ~= nil then
				if object.setReducedComponentMass ~= nil then
					object:setReducedComponentMass(false)
					self:setMassDirty()
				end
				if object.setCanBeSold ~= nil then
					object:setCanBeSold(true)
				end
				if object.setDynamicMountType ~= nil then
					object:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE, nil)
				end
			end
		end
		if getSplitType(objectId) ~= 0 then
			setUserAttribute(objectId, "isTensionBeltMounted", UserAttributeType.BOOLEAN, false)
		end
	end
	objectsToJointTable[objectId] = nil
end

-- Local values: useDynamicMount, useKinematicMount, useSplitShapeMount, constr, jointTransform, x, y, z, springForce, springDamping, jointIndex, objectMass, parentNode, x, y, z, rx, ry, rz
function TensionBelts:lockTensionBeltObject(objectId, objectsToJointTable, isDynamic, jointNode, object)
	if objectsToJointTable[objectId] == nil then
		local v178_, v179_
		if isDynamic or getSplitType(objectId) == 0 then
			v178_ = true
			v179_ = false
		else
			v178_ = false
			v179_ = true
		end
		if v178_ then
			if self.isServer then
				local v180_ = JointConstructor.new()
				v180_:setActors(jointNode, objectId)
				local v181_ = createTransformGroup("tensionBeltJoint")
				link(jointNode, v181_)
				local v182_, v183_, v184_ = localToWorld(objectId, getCenterOfMass(objectId))
				setWorldTranslation(v181_, v182_, v183_, v184_)
				v180_:setJointTransforms(v181_, v181_)
				v180_:setEnableCollision(true)
				v180_:setRotationLimit(0, 0, 0)
				v180_:setRotationLimit(1, 0, 0)
				v180_:setRotationLimit(2, 0, 0)
				v180_:setRotationLimitSpring(1000, 10, 1000, 10, 1000, 10)
				v180_:setTranslationLimitSpring(1000, 10, 1000, 10, 1000, 10)
				local v185_ = v180_:finalize()
				local v186_ = nil
				if object == nil then
					v186_ = getMass(objectId)
					if v186_ > 0.01 then
						setMass(objectId, 0.01)
						self:setMassDirty()
					else
						v186_ = nil
					end
				else
					if object.setReducedComponentMass ~= nil and object:getAllowComponentMassReduction() then
						object:setReducedComponentMass(true)
						self:setMassDirty()
					end
					if object.setCanBeSold ~= nil then
						object:setCanBeSold(false)
					end
					if object.setDynamicMountType ~= nil then
						object:setDynamicMountType(MountableObject.MOUNT_TYPE_DYNAMIC, self)
					end
				end
				if getSplitType(objectId) ~= 0 then
					setInertiaScale(objectId, 20, 20, 20)
				end
				objectsToJointTable[objectId] = {
					["jointIndex"] = v185_,
					["jointTransform"] = v181_,
					["object"] = object,
					["objectMass"] = v186_
				}
			else
				objectsToJointTable[objectId] = {
					["jointIndex"] = 0,
					["object"] = object
				}
			end
		elseif v179_ and self.isServer then
			local v187_ = getParent(objectId)
			local v188_, v189_, v190_ = localToLocal(objectId, jointNode, 0, 0, 0)
			local v191_, v192_, v193_ = localRotationToLocal(objectId, jointNode, 0, 0, 0)
			setRigidBodyType(objectId, RigidBodyType.KINEMATIC)
			link(jointNode, objectId)
			setTranslation(objectId, v188_, v189_, v190_)
			setRotation(objectId, v191_, v192_, v193_)
			objectsToJointTable[objectId] = {
				["parent"] = v187_,
				["object"] = object
			}
		end
		if getSplitType(objectId) ~= 0 then
			setUserAttribute(objectId, "isTensionBeltMounted", UserAttributeType.BOOLEAN, true)
			g_messageCenter:publish(MessageType.TREE_SHAPE_MOUNTED, objectId, self)
		end
	end
end

-- Local values: spec, belt, objects, _, _, singleBelt, _, data, _, singleBelt, objectIds, _, objectId, objectData
function TensionBelts:setTensionBeltsActive(isActive, beltId, noEventSend, playSound)
	local v199_ = self.spec_tensionBelts
	if v199_.tensionBelts ~= nil then
		TensionBeltsEvent.sendEvent(self, isActive, beltId, noEventSend)
		local v200_
		if beltId == nil then
			v200_ = nil
		else
			v200_ = v199_.sortedBelts[beltId]
		end
		if isActive then
			local v201_, _ = self:getObjectToMount(v200_)
			if v200_ == nil then
				for _, v202_ in pairs(v199_.singleBelts) do
					if v202_.mesh == nil then
						self:createTensionBelt(v202_, false, v201_, playSound)
					end
				end
			elseif v200_.mesh == nil then
				self:createTensionBelt(v200_, false, v201_, playSound)
			end
			for _, v203_ in pairs(v201_) do
				self:lockTensionBeltObject(v203_.physics, v199_.objectsToJoint, v199_.isDynamic, v200_.jointNode or v199_.jointNode, v203_.object)
				if v203_.object ~= nil then
					v203_.object.tensionMountObject = self
				end
			end
		else
			if v200_ == nil then
				for _, v204_ in pairs(v199_.singleBelts) do
					self:removeTensionBelt(v204_, playSound)
				end
			else
				self:removeTensionBelt(v200_, playSound)
			end
			local v205_, _ = self:getObjectsToUnmount(v200_)
			for v206_, v207_ in pairs(v205_) do
				self:freeTensionBeltObject(v206_, v199_.objectsToJoint, v199_.isDynamic, v207_.object)
				if v207_.object ~= nil then
					v207_.object.tensionMountObject = nil
				end
			end
		end
		if v200_ ~= nil then
			ObjectChangeUtil.setObjectChanges(v200_.changeObjects, isActive, self, self.setMovingToolDirty)
		end
		self:updateFastenState()
	end
end

-- Local values: spec, _, belt
function TensionBelts:setAllTensionBeltsActive(isActive, noEventSend)
	local v211_ = self.spec_tensionBelts
	if v211_.hasTensionBelts then
		local v212_ = Utils.getNoNil(isActive, not v211_.areAllBeltsFastened)
		for _, v213_ in pairs(v211_.sortedBelts) do
			self:setTensionBeltsActive(v212_, v213_.id, noEventSend)
		end
	end
end

-- Local values: spec, hasUnfastenedBelts, _, belt
function TensionBelts:updateFastenState()
	local v215_ = self.spec_tensionBelts
	local v216_ = false
	for _, v217_ in pairs(v215_.singleBelts) do
		if v217_.mesh == nil then
			v216_ = true
			break
		end
	end
	v215_.areAllBeltsFastened = not v216_
end

-- Local values: spec, tensionBelt, beltData, width, ratchetStart, ratchetEnd, hookLength1, hookLength2, _, pointNode, x, y, z, dirX, dirY, dirZ, _, object, _, node, beltShape, _, beltLength, currentIndex, scale, ratched, scale, hookStart, yOffset, wx1, wy1, wz1, wx2, wy2, wz2, dx, dy, dz, upX, upY, upZ, hook2, hookEnd
function TensionBelts:createTensionBelt(belt, isDummy, objects, playSound)
	local v223_ = self.spec_tensionBelts
	local v224_ = TensionBeltGeometryConstructor.new()
	local v225_ = v223_.beltData
	local v226_ = v223_.width or v225_.width
	v224_:setWidth(v226_)
	v224_:setMaxEdgeLength(v223_.maxEdgeLength)
	if isDummy then
		v224_:setMaterial(v225_.dummyMaterial.materialId)
		v224_:setUVscale(v225_.dummyMaterial.uvScale)
	else
		v224_:setMaterial(v225_.material.materialId)
		v224_:setUVscale(v225_.material.uvScale)
	end
	local v227_, v228_
	if v223_.ratchetPosition == nil or v225_.ratchet == nil then
		v227_ = 0
		v228_ = 0
	else
		v227_ = v223_.ratchetPosition
		v228_ = v223_.ratchetPosition + v225_.ratchet.sizeRatio * v226_
		v224_:addAttachment(0, v223_.ratchetPosition, v225_.ratchet.sizeRatio * v226_)
	end
	local v229_, v230_
	if v223_.useHooks and v225_.hook ~= nil then
		v229_ = v225_.hook.sizeRatio * v226_
		v224_:addAttachment(0, v229_, 0)
		v230_ = (v225_.hook2 or v225_.hook).sizeRatio * v226_
		v224_:addAttachment(1, -v230_, 0)
	else
		v230_ = 0
		v229_ = 0
	end
	v224_:setFixedPoints(belt.startNode, belt.endNode)
	v224_:setGeometryBias(v223_.geometryBias)
	v224_:setLinkNode(belt.linkNode or v223_.linkNode)
	for _, v231_ in pairs(belt.intersectionNodes) do
		local v232_, v233_, v234_ = getWorldTranslation(v231_)
		local v235_, v236_, v237_ = localDirectionToWorld(v231_, 1, 0, 0)
		v224_:addIntersectionPoint(v232_, v233_, v234_, v235_, v236_, v237_)
	end
	for _, v238_ in pairs(objects) do
		for _, v239_ in pairs(v238_.visuals) do
			if getSplitType(v239_) == 0 then
				v224_:addShape(v239_, 0, 10, 0, 10)
			else
				v224_:addShape(v239_, -100, 100, -100, 100)
			end
		end
	end
	local v240_, _, v241_ = v224_:finalize()
	if v240_ == 0 then
		return nil
	end
	if isDummy then
		belt.dummy = v240_
		return v240_
	end
	local v242_ = 0
	if v223_.ratchetPosition ~= nil and (v225_.ratchet ~= nil and v242_ < getNumOfChildren(v240_)) then
		local v243_ = clone(v225_.ratchet.node, false, false, false)
		link(getChildAt(v240_, 0), v243_)
		setTranslation(v243_, 0, v223_.geometryBias, 0)
		setScale(v243_, v226_, v226_, v226_)
		v242_ = v242_ + 1
	end
	if v223_.useHooks and (v225_.hook ~= nil and getNumOfChildren(v240_) > v242_ + 1) then
		local v244_ = clone(v225_.hook.node, false, false, false)
		link(getChildAt(v240_, v242_), v244_)
		local v245_ = v223_.geometryBias
		local v246_ = v229_ / v223_.maxEdgeLength
		local v247_ = v245_ * math.min(v246_, 1)
		setTranslation(v244_, 0, v247_, 0)
		local v248_, v249_, v250_ = getWorldTranslation(belt.startNode)
		local v251_, v252_, v253_ = getWorldTranslation(v244_)
		local v254_, v255_, v256_ = worldDirectionToLocal(getParent(v244_), v248_ - v251_, v249_ - v252_, v250_ - v253_)
		local v257_, v258_, v259_ = localDirectionToLocal(v244_, getParent(v244_), 0, 1, 0)
		setDirection(v244_, v254_, v255_, v256_, v257_, v258_, v259_)
		setScale(v244_, v226_, v226_, v226_)
		local v260_ = v225_.hook2 or v225_.hook
		local v261_ = clone(v260_.node, false, false, false)
		link(getChildAt(v240_, v242_ + 1), v261_)
		local v262_ = v223_.geometryBias
		local v263_ = v230_ / v223_.maxEdgeLength
		local v264_ = v262_ * math.min(v263_, 1)
		setTranslation(v261_, 0, v264_, 0)
		local v265_, v266_, v267_ = getWorldTranslation(belt.endNode)
		local v268_, v269_, v270_ = getWorldTranslation(v261_)
		local v271_, v272_, v273_ = worldDirectionToLocal(getParent(v261_), v265_ - v268_, v266_ - v269_, v267_ - v270_)
		local v274_, v275_, v276_ = localDirectionToLocal(v261_, getParent(v261_), 0, 1, 0)
		setDirection(v261_, v271_, v272_, v273_, v274_, v275_, v276_)
		setScale(v261_, v226_, v226_, v226_)
	end
	setShaderParameter(v240_, "beltClipOffsets", v229_, v227_, v228_, v241_ - v230_, false)
	belt.mesh = v240_
	v223_.belts[v240_] = v240_
	if belt.dummy ~= nil then
		delete(belt.dummy)
		belt.dummy = nil
	end
	if playSound ~= false and self.isClient then
		g_soundManager:playSample(v223_.samples.toggleBelt)
		g_soundManager:playSample(v223_.samples.addBelt)
	end
	return v240_
end

-- Local values: spec
function TensionBelts:removeTensionBelt(belt, playSound)
	if belt.mesh ~= nil then
		local v280_ = self.spec_tensionBelts
		v280_.belts[belt.mesh] = nil
		delete(belt.mesh)
		belt.mesh = nil
		if v280_.currentBelt == belt then
			v280_.currentBelt = nil
		end
		if belt.dummy == nil and (playSound ~= false and self.isClient) then
			g_soundManager:playSample(v280_.samples.toggleBelt)
			g_soundManager:playSample(v280_.samples.removeBelt)
		end
	end
end

-- Local values: spec, markerStart, markerEnd, offsetLeft, offsetRight, offset, height, x, _, _, x, _, _, sizeX, sizeY, _, _, width, sizeZ, centerX, centerY, centerZ, x, y, z, box, colorR, colorG, colorB, blx, bly, blz, brx, bry, brz, flx, fly, flz, frx, fry, frz, tblx, tbly, tblz, tbrx, tbry, tbrz, tflx, tfly, tflz, tfrx, tfry, tfrz, rx, ry, rz
function TensionBelts:getObjectToMount(belt)
	local v283_ = self.spec_tensionBelts
	local v284_ = v283_.startNode
	local v285_ = v283_.endNode
	local v286_, v287_, v288_, v289_
	if belt == nil then
		v286_ = nil
		v287_ = nil
		v288_ = nil
		v289_ = nil
	else
		v284_ = belt.startNode
		v285_ = belt.endNode
		v286_ = belt.offsetLeft
		v287_ = belt.offsetRight
		v288_ = belt.offset
		v289_ = belt.height
		if v286_ == nil and (v283_.sortedBelts[belt.id - 1] ~= nil and v283_.sortedBelts[belt.id - 1].mesh ~= nil) then
			local v290_, _, _ = localToLocal(v284_, v283_.sortedBelts[belt.id - 1].startNode, 0, 0, 0)
			v286_ = math.abs(v290_)
		end
		if v287_ == nil and (v283_.sortedBelts[belt.id + 1] ~= nil and v283_.sortedBelts[belt.id + 1].mesh ~= nil) then
			local v291_, _, _ = localToLocal(v284_, v283_.sortedBelts[belt.id + 1].startNode, 0, 0, 0)
			v287_ = math.abs(v291_)
		end
	end
	if v286_ == nil then
		v286_ = v283_.defaultOffsetSide
	end
	if v287_ == nil then
		v287_ = v283_.defaultOffsetSide
	end
	if v288_ == nil then
		v288_ = v283_.defaultOffset
	end
	if v289_ == nil then
		v289_ = v283_.defaultHeight
	end
	local v292_ = (v286_ + v287_) * 0.5
	local v293_ = v289_ * 0.5
	local _, _, v294_ = localToLocal(v285_, v284_, 0, 0, 0)
	local v295_ = v294_ * 0.5 - 2 * v288_
	local v296_ = (v286_ - v287_) * 0.5
	local v297_ = v289_ * 0.5
	local v298_ = v294_ * 0.5
	local v299_, v300_, v301_ = localToWorld(v284_, v296_, v297_, v298_)
	if TensionBelts.debugRendering then
		local v302_ = {
			["points"] = {},
			["color"] = { math.random(0, 1), math.random(0, 1), (math.random(0, 1)) }
		}
		local v303_, v304_, v305_ = localToWorld(v284_, v296_ - v292_, v297_ - v293_, v298_ - v295_)
		local v306_, v307_, v308_ = localToWorld(v284_, v296_ + v292_, v297_ - v293_, v298_ - v295_)
		local v309_, v310_, v311_ = localToWorld(v284_, v296_ - v292_, v297_ - v293_, v298_ + v295_)
		local v312_, v313_, v314_ = localToWorld(v284_, v296_ + v292_, v297_ - v293_, v298_ + v295_)
		local v315_, v316_, v317_ = localToWorld(v284_, v296_ - v292_, v297_ + v293_, v298_ - v295_)
		local v318_, v319_, v320_ = localToWorld(v284_, v296_ + v292_, v297_ + v293_, v298_ - v295_)
		local v321_, v322_, v323_ = localToWorld(v284_, v296_ - v292_, v297_ + v293_, v298_ + v295_)
		local v324_, v325_, v326_ = localToWorld(v284_, v296_ + v292_, v297_ + v293_, v298_ + v295_)
		local v327_ = v302_.points
		table.insert(v327_, { v303_, v304_, v305_ })
		local v328_ = v302_.points
		table.insert(v328_, { v306_, v307_, v308_ })
		local v329_ = v302_.points
		table.insert(v329_, { v312_, v313_, v314_ })
		local v330_ = v302_.points
		table.insert(v330_, { v309_, v310_, v311_ })
		local v331_ = v302_.points
		table.insert(v331_, { v315_, v316_, v317_ })
		local v332_ = v302_.points
		table.insert(v332_, { v318_, v319_, v320_ })
		local v333_ = v302_.points
		table.insert(v333_, { v324_, v325_, v326_ })
		local v334_ = v302_.points
		table.insert(v334_, { v321_, v322_, v323_ })
		local v335_ = v302_.points
		table.insert(v335_, { v299_, v300_, v301_ })
		v283_.checkBoxes[v284_] = v302_
	end
	local v336_, v337_, v338_ = getWorldRotation(v284_)
	table.clear(v283_.objectsInTensionBeltRange)
	v283_.numObjectsIntensionBeltRange = 0
	overlapBox(v299_, v300_, v301_, v336_, v337_, v338_, v292_, v293_, v295_, "objectOverlapCallback", self, CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.TREE, true, true, false, true)
	return v283_.objectsInTensionBeltRange, v283_.numObjectsIntensionBeltRange
end

-- Local values: spec, objectIdsToUnmount, numObjects, objectId, data, _, otherBelt, objectToMount, _, _, object
function TensionBelts:getObjectsToUnmount(belt)
	local v341_ = self.spec_tensionBelts
	local v342_ = {}
	local v343_ = 0
	for v344_, v345_ in pairs(v341_.objectsToJoint) do
		v342_[v344_] = {
			["objectId"] = v344_,
			["object"] = v345_.object
		}
		v343_ = v343_ + 1
	end
	for _, v346_ in pairs(v341_.singleBelts) do
		if v346_.mesh ~= nil and v346_ ~= belt then
			local v347_, _ = self:getObjectToMount(v346_)
			for _, v348_ in pairs(v347_) do
				if v342_[v348_.physics] ~= nil then
					v342_[v348_.physics] = nil
					v343_ = v343_ - 1
				end
			end
		end
	end
	return v342_, v343_
end

-- Local values: spec, object, nodeId, nodes, rigidBodyType
function TensionBelts:objectOverlapCallback(transformId)
	if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) then
		local v351_ = self.spec_tensionBelts
		local v352_ = g_currentMission:getNodeObject(transformId)
		if v352_ == nil then
			if getSplitType(transformId) ~= 0 then
				local v353_ = getRigidBodyType(transformId)
				if (v353_ == RigidBodyType.DYNAMIC or v353_ == RigidBodyType.KINEMATIC) and v351_.objectsInTensionBeltRange[transformId] == nil then
					v351_.objectsInTensionBeltRange[transformId] = {
						["physics"] = transformId,
						["visuals"] = { transformId }
					}
					v351_.numObjectsIntensionBeltRange = v351_.numObjectsIntensionBeltRange + 1
				end
			end
		elseif self:getTensionBeltObjectCanBeMounted(v352_) then
			local v354_ = v352_:getTensionBeltNodeId()
			if v351_.objectsInTensionBeltRange[v354_] == nil then
				local v355_ = v352_:getMeshNodes()
				if v355_ ~= nil then
					v351_.objectsInTensionBeltRange[v354_] = {
						["physics"] = v354_,
						["visuals"] = v355_,
						["object"] = v352_
					}
					v351_.numObjectsIntensionBeltRange = v351_.numObjectsIntensionBeltRange + 1
				end
			end
		end
	end
	return true
end

-- Local values: hasObjectMounted, spec, _, objectData
function TensionBelts:getTensionBeltObjectCanBeMounted(object)
	if object == self then
		return false
	end
	if object.rootVehicle == self.rootVehicle then
		return false
	end
	if object.getSupportsTensionBelts == nil or not object:getSupportsTensionBelts() then
		return false
	end
	if object.getMeshNodes == nil then
		return false
	end
	if object.dynamicMountObject ~= nil then
		return false
	end
	local v358_ = self.spec_tensionBelts
	local v359_ = false
	for _, v360_ in pairs(v358_.objectsToJoint) do
		if v360_.object ~= nil and v360_.object == object then
			v359_ = true
		end
	end
	if not v359_ then
		if object.rootVehicle ~= nil and object.rootVehicle:getHasObjectMounted(self) then
			return false
		end
		if self.rootVehicle:getHasObjectMounted(object) then
			return false
		end
	end
	return true
end

-- Local values: spec, px, py, pz, vx, vy, vz, currentBelt, distance, _, belt, sx, _, sz, ex, _, ez, sDistance, eDistance
function TensionBelts:getIsPlayerInTensionBeltsRange()
	if g_localPlayer == nil then
		return false, nil
	end
	if not g_currentMission.accessHandler:canPlayerAccess(self) then
		return false, nil
	end
	local v362_ = self.spec_tensionBelts
	if v362_.beltData ~= nil then
		local v363_, v364_, v365_ = getWorldTranslation(g_localPlayer.rootNode)
		local v366_, v367_, v368_ = localToWorld(v362_.interactionBaseNode, v362_.interactionBasePointX, 0, v362_.interactionBasePointZ)
		local v369_ = nil
		local v370_ = math.huge
		if MathUtil.vector3Length(v363_ - v366_, v364_ - v367_, v365_ - v368_) < v362_.totalInteractionRadius then
			if v362_.tensionBelts ~= nil then
				for _, v371_ in pairs(v362_.singleBelts) do
					local v372_, _, v373_ = getWorldTranslation(v371_.startNode)
					local v374_, _, v375_ = getWorldTranslation(v371_.endNode)
					local v376_ = MathUtil.vector2Length(v363_ - v372_, v365_ - v373_)
					local v377_ = MathUtil.vector2Length(v363_ - v374_, v365_ - v375_)
					if v376_ < v370_ and v376_ < v362_.interactionRadius or v377_ < v370_ and v377_ < v362_.interactionRadius then
						v370_ = math.min(v376_, v377_)
						v369_ = v371_
					end
				end
			end
			if v370_ < v362_.interactionRadius then
				return true, v369_
			end
		end
	end
	return false, nil
end

-- Local values: spec, object, _
function TensionBelts:getIsDynamicallyMountedNode(node)
	local v380_ = self.spec_tensionBelts
	if v380_.objectsToJoint ~= nil then
		for v381_, _ in pairs(v380_.objectsToJoint) do
			if v381_ == node then
				return true
			end
		end
	end
	return false
end

-- Local values: spec
function TensionBelts:getIsReadyForAutomatedTrainTravel(superFunc)
	local v384_ = self.spec_tensionBelts
	if v384_.hasTensionBelts and v384_.numObjectsIntensionBeltRange > 0 then
		return false
	else
		return superFunc(self)
	end
end

function TensionBelts:getCanBeSelected(superFunc)
	return true
end

-- Local values: spec
function TensionBelts:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local v389_ = self.spec_tensionBelts
	if v389_.hasTensionBelts and (not v389_.allowFoldingWhileFasten and ((direction or 1) >= 0 and v389_.areAllBeltsFastened)) then
		return false, v389_.texts.warningFoldingTensionBelts
	else
		return superFunc(self, direction, onAiTurnOn)
	end
end

function TensionBelts:loadMovingToolFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end
	entry.tensionBeltsAllowedMounted = xmlFile:getValue(key .. ".tensionBelts#allowedMounted", true)
	return true
end

-- Local values: spec
function TensionBelts:getIsMovingToolActive(superFunc, movingTool)
	if not movingTool.tensionBeltsAllowedMounted then
		local v398_ = self.spec_tensionBelts
		if v398_.hasTensionBelts and v398_.areAllBeltsFastened then
			return false
		end
	end
	return superFunc(self, movingTool)
end

-- Local values: spec
function TensionBelts:getCanDischargeToGround(superFunc, dischargeNode)
	local v402_ = self.spec_tensionBelts
	if v402_.hasTensionBelts and (not v402_.allowDischargeWhileFasten and v402_.areAllBeltsFastened) then
		return false
	else
		return superFunc(self, dischargeNode)
	end
end

-- Local values: spec
function TensionBelts:getCanDischargeToObject(superFunc, dischargeNode)
	local v406_ = self.spec_tensionBelts
	if v406_.hasTensionBelts and (not v406_.allowDischargeWhileFasten and v406_.areAllBeltsFastened) then
		return false
	else
		return superFunc(self, dischargeNode)
	end
end

-- Local values: spec, _, objectData, object, fillType, fillLevel, capacity
function TensionBelts:getFillLevelInformation(superFunc, display)
	superFunc(self, display)
	local v410_ = self.spec_tensionBelts
	if v410_.hasTensionBelts then
		for _, v411_ in pairs(v410_.objectsToJoint) do
			local v412_ = v411_.object
			if v412_ ~= nil then
				if v412_.getFillLevelInformation == nil then
					if v412_.getFillLevel ~= nil and v412_.getFillType ~= nil then
						local v413_ = v412_:getFillType()
						local v414_ = v412_:getFillLevel()
						local v415_
						if v412_.getCapacity == nil then
							v415_ = v414_
						else
							v415_ = v412_:getCapacity()
						end
						display:addFillLevel(v413_, v414_, v415_)
					end
				else
					v412_:getFillLevelInformation(display)
				end
			end
		end
	end
end

-- Local values: spec, _, objectData
function TensionBelts:getHasObjectMounted(superFunc, object)
	if superFunc(self, object) then
		return true
	end
	local v419_ = self.spec_tensionBelts
	if v419_.hasTensionBelts then
		for _, v420_ in pairs(v419_.objectsToJoint) do
			if v420_.object ~= nil then
				if v420_.object == object then
					return true
				end
				if v420_.object.getHasObjectMounted ~= nil and v420_.object:getHasObjectMounted(object) then
					return true
				end
			end
		end
	end
	return false
end

-- Local values: additionalMass, spec, _, objectData, object
function TensionBelts:getAdditionalComponentMass(superFunc, component)
	local v424_ = superFunc(self, component)
	local v425_ = self.spec_tensionBelts
	if v425_.hasTensionBelts and v425_.jointComponent == component.node then
		for _, v426_ in pairs(v425_.objectsToJoint) do
			local v427_ = v426_.object
			if v427_ ~= nil and (v427_.getAllowComponentMassReduction ~= nil and v427_:getAllowComponentMassReduction()) then
				local v428_ = v427_:getDefaultMass() - 0.1
				v424_ = v424_ + math.max(v428_, 0)
			end
			if v426_.objectMass ~= nil then
				v424_ = v424_ + (v426_.objectMass - 0.01)
			end
		end
	end
	return v424_
end

-- Local values: spec, _, actionEventId
function TensionBelts:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	local v431_ = self.spec_tensionBelts
	if self.isClient and v431_.hasTensionBelts then
		self:clearActionEventsTable(v431_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v432_ = self:addActionEvent(v431_.actionEvents, InputAction.TOGGLE_TENSION_BELTS, self, TensionBelts.actionEventToggleTensionBelts, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v432_, GS_PRIO_NORMAL)
			self.toggleTensionBeltActionEvent = v432_
		end
	end
end

-- Local values: spec
function TensionBelts:tensionBeltActivationTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local v437_ = self.spec_tensionBelts
	if self.isClient and (v437_.hasTensionBelts and (onEnter or onLeave)) and (g_localPlayer ~= nil and otherActorId == g_localPlayer.rootNode) then
		if onEnter then
			self:raiseActive()
			v437_.isPlayerInTrigger = true
			return
		end
		v437_.isPlayerInTrigger = false
	end
end

-- Local values: spec, objectId, data
function TensionBelts:onTensionBeltTreeShapeCut(oldShape, shape)
	if self.isServer then
		local v440_ = self.spec_tensionBelts
		for v441_, _ in pairs(v440_.objectsToJoint) do
			if v441_ == oldShape then
				self:setAllTensionBeltsActive(false)
			end
		end
	end
end
TensionBeltsActivatable = {}
local v_u_442_ = Class(TensionBeltsActivatable)

-- Upvalues: TensionBeltsActivatable_mt
-- Local values: self
function TensionBeltsActivatable.new(object)
	-- upvalues: (copy) v_u_442_
	local v444_ = v_u_442_
	local v445_ = setmetatable({}, v444_)
	v445_.object = object
	v445_.spec = object.spec_tensionBelts
	v445_.activateText = g_i18n:getText("action_fastenTensionBelt")
	return v445_
end

function TensionBeltsActivatable:getIsActivatable()
	return self.spec.isPlayerInRange
end

-- Local values: belt
function TensionBeltsActivatable:getDistance(posX, posY, posZ)
	return self.spec.currentBelt == nil and math.huge or 0
end

function TensionBeltsActivatable:run()
	if self.spec.currentBelt ~= nil then
		if self.spec.currentBelt.mesh == nil then
			self.object:setTensionBeltsActive(true, self.spec.currentBelt.id, false)
		else
			self.object:setTensionBeltsActive(false, self.spec.currentBelt.id, false)
		end
	end
	self:updateActivateText()
end

function TensionBeltsActivatable:updateActivateText()
	if self.spec.currentBelt == nil or self.spec.currentBelt.mesh == nil then
		self.activateText = g_i18n:getText("action_fastenTensionBelt")
	else
		self.activateText = g_i18n:getText("action_unfastenTensionBelt")
	end
end

-- Local values: spec
function TensionBelts:actionEventToggleTensionBelts(actionName, inputValue, callbackState, isAnalog)
	local v451_ = self.spec_tensionBelts
	v451_.fastenedAllBeltsIndex = 1
	v451_.fastenedAllBeltsState = not v451_.areAllBeltsFastened
end

function TensionBelts.consoleCommandToggleTensionBeltDebugRendering(unusedSelf)
	TensionBelts.debugRendering = not TensionBelts.debugRendering
	local v452_ = TensionBelts.debugRendering
	return "TensionBeltsDebugRendering = " .. tostring(v452_)
end
addConsoleCommand("gsTensionBeltDebug", "Toggles the debug tension belt rendering of the vehicle", "TensionBelts.consoleCommandToggleTensionBeltDebugRendering", nil)
