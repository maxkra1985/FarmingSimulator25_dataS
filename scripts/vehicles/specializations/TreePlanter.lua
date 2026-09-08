-- Local values: TreePlanterActivatable_mt
source("dataS/scripts/vehicles/specializations/events/TreePlanterCreateTreeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TreePlanterLoadPalletEvent.lua")
source("dataS/scripts/vehicles/specializations/events/TreePlanterTreeTypeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/PlantLimitToFieldEvent.lua")
TreePlanter = {}
TreePlanter.AI_REQUIRED_GROUND_TYPES = {
	FieldGroundType.STUBBLE_TILLAGE,
	FieldGroundType.CULTIVATED,
	FieldGroundType.SEEDBED,
	FieldGroundType.PLOWED,
	FieldGroundType.ROLLED_SEEDBED,
	FieldGroundType.RIDGE,
	FieldGroundType.SOWN,
	FieldGroundType.DIRECT_SOWN,
	FieldGroundType.PLANTED,
	FieldGroundType.RIDGE_SOWN,
	FieldGroundType.ROLLER_LINES,
	FieldGroundType.HARVEST_READY,
	FieldGroundType.HARVEST_READY_OTHER,
	FieldGroundType.GRASS,
	FieldGroundType.GRASS_CUT
}

function TreePlanter.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations) and SpecializationUtil.hasSpecialization(FillUnit, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(GroundReference, specializations)
	end
	return v2_
end
function TreePlanter.initSpecialization()
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("TreePlanter")
	v3_:register(XMLValueType.STRING, "vehicle.treePlanter#inputAction", "Name of the input action to plant a tree manually (If set, the trees are planted manual only)")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.treePlanter#node", "Node index")
	v3_:register(XMLValueType.FLOAT, "vehicle.treePlanter#minDistance", "Min. distance between trees", 20)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.treePlanter#palletTrigger", "Pallet trigger")
	v3_:register(XMLValueType.INT, "vehicle.treePlanter#refNodeIndex", "Ground reference node index", 1)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.treePlanter#saplingPalletGrabNode", "Sapling pallet grab node")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.treePlanter#saplingPalletMountNode", "Sapling pallet mount node")
	v3_:register(XMLValueType.INT, "vehicle.treePlanter#fillUnitIndex", "Fill unit index")
	v3_:register(XMLValueType.FLOAT, "vehicle.treePlanter#palletMountingRange", "Min. distance from saplingPalletGrabNode to pallet to mount it", 6)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.treePlanter.saplingNodes.saplingNode(?)#node", "Link node for tree sapling (will be hidden based on fill level)")
	v3_:register(XMLValueType.STRING, "vehicle.treePlanter.plantAnimation#name", "Name of plant animation")
	v3_:register(XMLValueType.FLOAT, "vehicle.treePlanter.plantAnimation#speedScale", "Speed scale of animation", 1)
	v3_:register(XMLValueType.STRING, "vehicle.treePlanter.magazineAnimation#name", "Name of magazine animation (updated based on fill level)")
	v3_:register(XMLValueType.FLOAT, "vehicle.treePlanter.magazineAnimation#speedScale", "Speed scale of animation", 1)
	v3_:register(XMLValueType.INT, "vehicle.treePlanter.magazineAnimation#numRows", "Number of rows on the magazine", 1)
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.treePlanter.sounds", "work")
	AnimationManager.registerAnimationNodesXMLPaths(v3_, "vehicle.treePlanter.animationNodes")
	v3_:setXMLSpecializationType()
	local v4_ = Vehicle.xmlSchemaSavegame
	v4_:register(XMLValueType.VECTOR_TRANS, "vehicles.vehicle(?).treePlanter#lastTreePos", "Position of last tree")
	v4_:register(XMLValueType.BOOL, "vehicles.vehicle(?).treePlanter#palletHadBeenMounted", "Pallet is mounted")
	v4_:register(XMLValueType.STRING, "vehicles.vehicle(?).treePlanter#currentTreeType", "Name of currently loaded tree type")
	v4_:register(XMLValueType.STRING, "vehicles.vehicle(?).treePlanter#currentTreeVariation", "Name of currently loaded tree stage variation")
end

function TreePlanter.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "removeMountedObject", TreePlanter.removeMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "setPlantLimitToField", TreePlanter.setPlantLimitToField)
	SpecializationUtil.registerFunction(vehicleType, "createTree", TreePlanter.createTree)
	SpecializationUtil.registerFunction(vehicleType, "loadPallet", TreePlanter.loadPallet)
	SpecializationUtil.registerFunction(vehicleType, "palletTriggerCallback", TreePlanter.palletTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "onDeleteTreePlanterObject", TreePlanter.onDeleteTreePlanterObject)
	SpecializationUtil.registerFunction(vehicleType, "getCanPlantOutsideSeason", TreePlanter.getCanPlantOutsideSeason)
	SpecializationUtil.registerFunction(vehicleType, "setTreePlanterTreeTypeIndex", TreePlanter.setTreePlanterTreeTypeIndex)
	SpecializationUtil.registerFunction(vehicleType, "onTreePlanterSaplingLoaded", TreePlanter.onTreePlanterSaplingLoaded)
	SpecializationUtil.registerFunction(vehicleType, "updateTreePlanterFillLevel", TreePlanter.updateTreePlanterFillLevel)
end

function TreePlanter.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", TreePlanter.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", TreePlanter.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", TreePlanter.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", TreePlanter.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", TreePlanter.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", TreePlanter.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsOnField", TreePlanter.getIsOnField)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", TreePlanter.addFillUnitFillLevel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFillLevel", TreePlanter.getFillUnitFillLevel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFillLevelPercentage", TreePlanter.getFillUnitFillLevelPercentage)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFillType", TreePlanter.getFillUnitFillType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitCapacity", TreePlanter.getFillUnitCapacity)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitAllowsFillType", TreePlanter.getFillUnitAllowsFillType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFreeCapacity", TreePlanter.getFillUnitFreeCapacity)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", TreePlanter.getFillLevelInformation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getHasObjectMounted", TreePlanter.getHasObjectMounted)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitHasMountedPalletsToUnload", TreePlanter.getFillUnitHasMountedPalletsToUnload)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitUnloadPalletFilename", TreePlanter.getFillUnitUnloadPalletFilename)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitMountedPalletsToUnload", TreePlanter.getFillUnitMountedPalletsToUnload)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getImplementAllowAutomaticSteering", TreePlanter.getImplementAllowAutomaticSteering)
end

function TreePlanter.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", TreePlanter)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", TreePlanter)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", TreePlanter)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", TreePlanter)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", TreePlanter)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", TreePlanter)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TreePlanter)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", TreePlanter)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", TreePlanter)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", TreePlanter)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", TreePlanter)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", TreePlanter)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitIsFillingStateChanged", TreePlanter)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", TreePlanter)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitUnloadPallet", TreePlanter)
end

-- Local values: spec, baseKey, refNodeIndex, treeTypeName, variationName, treeTypeIndex, variationIndex
function TreePlanter:onLoad(savegame)
	local v_u_10_ = self.spec_treePlanter
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.treePlanterSound", "vehicle.treePlanter.sounds.work")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode(0)", "vehicle.treePlanter.animationNodes.animationNode")
	if self.isClient then
		v_u_10_.samples = {}
		v_u_10_.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.treePlanter.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_10_.isWorkSamplePlaying = false
		v_u_10_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.treePlanter.animationNodes", self.components, self, self.i3dMappings)
	end
	v_u_10_.inputAction = InputAction[self.xmlFile:getValue("vehicle.treePlanter#inputAction")]
	v_u_10_.node = self.xmlFile:getValue("vehicle.treePlanter#node", nil, self.components, self.i3dMappings)
	v_u_10_.minDistance = self.xmlFile:getValue("vehicle.treePlanter#minDistance", 20)
	v_u_10_.palletTrigger = self.xmlFile:getValue("vehicle.treePlanter#palletTrigger", nil, self.components, self.i3dMappings)
	if v_u_10_.palletTrigger == nil then
		Logging.xmlWarning(self.xmlFile, "TreePlanter requires a palletTrigger!")
	else
		addTrigger(v_u_10_.palletTrigger, "palletTriggerCallback", self)
		g_currentMission:addNodeObject(v_u_10_.palletTrigger, self)
	end
	v_u_10_.palletsInTrigger = {}
	v_u_10_.groundReferenceNode = self:getGroundReferenceNodeFromIndex((self.xmlFile:getValue("vehicle.treePlanter#refNodeIndex", 1)))
	if v_u_10_.groundReferenceNode == nil then
		Logging.xmlWarning(self.xmlFile, "No groundReferenceNode specified or invalid groundReferenceNode index in \'%s\'", "vehicle.treePlanter#refNodeIndex")
	end
	v_u_10_.currentTreeTypeIndex = nil
	v_u_10_.currentTreeVariationIndex = nil
	v_u_10_.saplingNodes = {}
	self.xmlFile:iterate("vehicle.treePlanter.saplingNodes.saplingNode", function(_, p11_)
		-- upvalues: (copy) self, (copy) v_u_10_
		local v12_ = self.xmlFile:getValue(p11_ .. "#node", nil, self.components, self.i3dMappings)
		if v12_ ~= nil then
			local v13_ = v_u_10_.saplingNodes
			table.insert(v13_, v12_)
		end
	end)
	v_u_10_.plantAnimation = {}
	v_u_10_.plantAnimation.name = self.xmlFile:getValue("vehicle.treePlanter.plantAnimation#name")
	v_u_10_.plantAnimation.speedScale = self.xmlFile:getValue("vehicle.treePlanter.plantAnimation#speedScale", 1)
	v_u_10_.magazineAnimation = {}
	v_u_10_.magazineAnimation.name = self.xmlFile:getValue("vehicle.treePlanter.magazineAnimation#name")
	v_u_10_.magazineAnimation.speedScale = self.xmlFile:getValue("vehicle.treePlanter.magazineAnimation#speedScale", 1)
	v_u_10_.magazineAnimation.numRows = self.xmlFile:getValue("vehicle.treePlanter.magazineAnimation#numRows", 1)
	v_u_10_.activatable = TreePlanterActivatable.new(self)
	v_u_10_.saplingPalletGrabNode = self.xmlFile:getValue("vehicle.treePlanter#saplingPalletGrabNode", self.rootNode, self.components, self.i3dMappings)
	v_u_10_.saplingPalletMountNode = self.xmlFile:getValue("vehicle.treePlanter#saplingPalletMountNode", self.rootNode, self.components, self.i3dMappings)
	v_u_10_.mountedSaplingPallet = nil
	v_u_10_.fillUnitIndex = self.xmlFile:getValue("vehicle.treePlanter#fillUnitIndex", 1)
	v_u_10_.nearestPalletDistance = self.xmlFile:getValue("vehicle.treePlanter#palletMountingRange", 6)
	v_u_10_.currentTree = 1
	v_u_10_.lastTreePos = nil
	v_u_10_.showFieldNotOwnedWarning = false
	v_u_10_.showRestrictedZoneWarning = false
	v_u_10_.showTooManyTreesWarning = false
	v_u_10_.hasGroundContact = false
	v_u_10_.showWrongPlantingTimeWarning = false
	v_u_10_.limitToField = true
	v_u_10_.forceLimitToField = false
	if self.addAIGroundTypeRequirements ~= nil then
		self:addAIGroundTypeRequirements(TreePlanter.AI_REQUIRED_GROUND_TYPES)
		if self.setAIFruitProhibitions ~= nil then
			self:setAIFruitProhibitions(FruitType.POPLAR, 1, 5)
		end
	end
	v_u_10_.dirtyFlag = self:getNextDirtyFlag()
	if savegame ~= nil and not savegame.resetVehicles then
		v_u_10_.lastTreePos = savegame.xmlFile:getValue(savegame.key .. ".treePlanter#lastTreePos", nil, true)
		v_u_10_.palletHadBeenMounted = savegame.xmlFile:getValue(savegame.key .. ".treePlanter#palletHadBeenMounted")
		local v14_ = savegame.xmlFile:getValue(savegame.key .. ".treePlanter#currentTreeType")
		local v15_ = savegame.xmlFile:getValue(savegame.key .. ".treePlanter#currentTreeVariation")
		if v14_ ~= nil then
			local v16_, v17_ = g_treePlantManager:getTreeTypeIndexAndVariationFromName(v14_, 1, v15_)
			self:setTreePlanterTreeTypeIndex(v16_, v17_, true)
		end
	end
end

-- Local values: spec
function TreePlanter:onDelete()
	local v19_ = self.spec_treePlanter
	g_soundManager:deleteSamples(v19_.samples)
	g_animationManager:deleteAnimations(v19_.animationNodes)
	if v19_.activatable ~= nil then
		g_currentMission.activatableObjectsSystem:removeActivatable(v19_.activatable)
	end
	if v19_.mountedSaplingPallet ~= nil then
		v19_.mountedSaplingPallet:unmount(true)
		v19_.mountedSaplingPallet = nil
	end
	if v19_.palletTrigger ~= nil then
		removeTrigger(v19_.palletTrigger)
		g_currentMission:removeNodeObject(v19_.palletTrigger)
	end
	if v19_.saplingSharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(v19_.saplingSharedLoadRequestId)
		v19_.saplingSharedLoadRequestId = nil
	end
end

-- Local values: spec, treeTypeName, variationName
function TreePlanter:saveToXMLFile(xmlFile, key, usedModNames)
	local v23_ = self.spec_treePlanter
	if v23_.lastTreePos ~= nil then
		local v24_ = key .. "#lastTreePos"
		local v25_ = v23_.lastTreePos
		xmlFile:setValue(v24_, unpack(v25_))
	end
	if v23_.mountedSaplingPallet ~= nil then
		xmlFile:setValue(key .. "#palletHadBeenMounted", true)
	end
	if v23_.currentTreeTypeIndex ~= nil then
		local v26_, v27_ = g_treePlantManager:getTreeTypeNameAndVariationByIndex(v23_.currentTreeTypeIndex, 1, v23_.currentTreeVariationIndex)
		if v26_ ~= nil then
			xmlFile:setValue(key .. "#currentTreeType", v26_)
		end
		if v27_ ~= nil then
			xmlFile:setValue(key .. "#currentTreeVariation", v27_)
		end
	end
end

-- Local values: spec
function TreePlanter:removeMountedObject(object, isDeleting)
	local v30_ = self.spec_treePlanter
	if v30_.mountedSaplingPallet == object then
		v30_.mountedSaplingPallet:unmount()
		v30_.mountedSaplingPallet = nil
	end
end

-- Local values: spec, treeTypeIndex, variationIndex, paramsXZ, paramsY, x, y, z
function TreePlanter:onReadStream(streamId, connection)
	local v33_ = self.spec_treePlanter
	if streamReadBool(streamId) then
		v33_.palletIdToMount = NetworkUtil.readNodeObjectId(streamId)
	end
	if streamReadBool(streamId) then
		self:setTreePlanterTreeTypeIndex(streamReadUInt32(streamId), streamReadUIntN(streamId, TreePlantManager.VARIATION_NUM_BITS), true)
	end
	if streamReadBool(streamId) then
		local v34_ = g_currentMission.vehicleXZPosCompressionParams
		local v35_ = g_currentMission.vehicleYPosCompressionParams
		v33_.lastTreePos = { NetworkUtil.readCompressedWorldPosition(streamId, v34_), NetworkUtil.readCompressedWorldPosition(streamId, v35_), (NetworkUtil.readCompressedWorldPosition(streamId, v34_)) }
	end
end

-- Local values: spec, palletId, paramsXZ, paramsY
function TreePlanter:onWriteStream(streamId, connection)
	local v38_ = self.spec_treePlanter
	streamWriteBool(streamId, v38_.mountedSaplingPallet ~= nil)
	if v38_.mountedSaplingPallet ~= nil then
		local v39_ = NetworkUtil.getObjectId(v38_.mountedSaplingPallet)
		NetworkUtil.writeNodeObjectId(streamId, v39_)
	end
	if streamWriteBool(streamId, v38_.currentTreeTypeIndex ~= nil) then
		streamWriteUInt32(streamId, v38_.currentTreeTypeIndex)
		streamWriteUIntN(streamId, v38_.currentTreeVariationIndex or 1, TreePlantManager.VARIATION_NUM_BITS)
	end
	if streamWriteBool(streamId, v38_.lastTreePos ~= nil) then
		local v40_ = g_currentMission.vehicleXZPosCompressionParams
		local v41_ = g_currentMission.vehicleYPosCompressionParams
		NetworkUtil.writeCompressedWorldPosition(streamId, v38_.lastTreePos[1], v40_)
		NetworkUtil.writeCompressedWorldPosition(streamId, v38_.lastTreePos[2], v41_)
		NetworkUtil.writeCompressedWorldPosition(streamId, v38_.lastTreePos[3], v40_)
	end
end

-- Local values: spec
function TreePlanter:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v45_ = self.spec_treePlanter
		if streamReadBool(streamId) then
			v45_.hasGroundContact = streamReadBool(streamId)
			v45_.showFieldNotOwnedWarning = streamReadBool(streamId)
			v45_.showRestrictedZoneWarning = streamReadBool(streamId)
		end
	end
end

-- Local values: spec
function TreePlanter:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v50_ = self.spec_treePlanter
		local v51_ = streamWriteBool
		local v52_ = v50_.dirtyFlag
		if v51_(streamId, bit32.band(dirtyMask, v52_) ~= 0) then
			streamWriteBool(streamId, v50_.hasGroundContact)
			streamWriteBool(streamId, v50_.showFieldNotOwnedWarning)
			streamWriteBool(streamId, v50_.showRestrictedZoneWarning)
		end
	end
end

-- Local values: spec, pallet, treeTypeName, variationName, treeTypeIndex, variationIndex, nearestSaplingPallet
function TreePlanter:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v54_ = self.spec_treePlanter
	if self.finishedFirstUpdate then
		local v55_ = nil
		if v54_.palletIdToMount == nil then
			if v54_.palletHadBeenMounted then
				v54_.palletHadBeenMounted = nil
				v55_ = TreePlanter.getSaplingPalletInRange(self, v54_.saplingPalletMountNode, v54_.palletsInTrigger)
			end
		else
			v55_ = NetworkUtil.getObject(v54_.palletIdToMount)
		end
		if v55_ ~= nil and v55_:getIsSynchronized() then
			v55_:mount(self, v54_.saplingPalletMountNode, 0, 0, 0, 0, 0, 0)
			v54_.mountedSaplingPallet = v55_
			g_currentMission.activatableObjectsSystem:removeActivatable(v54_.activatable)
			v54_.palletIdToMount = nil
			if self.isServer and v55_.getTreeSaplingPalletType ~= nil then
				local v56_, v57_ = v55_:getTreeSaplingPalletType()
				local v58_, v59_ = g_treePlantManager:getTreeTypeIndexAndVariationFromName(v56_, 1, v57_)
				self:setTreePlanterTreeTypeIndex(v58_, v59_)
			end
			FillUnit.updateUnloadActionDisplay(self)
		end
	end
	if self.isClient then
		local v60_
		if v54_.mountedSaplingPallet == nil then
			v60_ = TreePlanter.getSaplingPalletInRange(self, v54_.saplingPalletGrabNode, v54_.palletsInTrigger)
		else
			v60_ = nil
		end
		if v54_.nearestSaplingPallet ~= v60_ then
			v54_.nearestSaplingPallet = v60_
			if v60_ == nil then
				g_currentMission.activatableObjectsSystem:removeActivatable(v54_.activatable)
			else
				g_currentMission.activatableObjectsSystem:addActivatable(v54_.activatable)
			end
		end
	end
	if v54_.mountedSaplingPallet ~= nil then
		if v54_.mountedSaplingPallet.isDeleted then
			v54_.palletsInTrigger[v54_.mountedSaplingPallet] = nil
			v54_.mountedSaplingPallet = nil
			return
		end
		v54_.mountedSaplingPallet:raiseActive()
	end
end

-- Local values: spec, showFieldNotOwnedWarning, showRestrictedZoneWarning, hasGroundContact, rootVehicle, isPlantingSeason, fillType, fruitTypeDesc, fillLevel, fillType, x, y, z, distance, x, _, z, width, sx, _, sz, wx, _, wz, hx, _, hz, fruitType, fruitDesc, dx, _, dz, angleRad, angle, limitToField, limitFruitDestructionToField, sowingValue, area, _, usage, farmId, price, lastHa, actionEvent, showAction, fillType, actionEvent, isActive, x, y, z, distance
function TreePlanter:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v64_ = self.spec_treePlanter
	v64_.showTooManyTreesWarning = false
	local v65_ = false
	local v66_ = false
	if self.isServer then
		local v67_
		if v64_.groundReferenceNode == nil then
			v67_ = false
		else
			v67_ = self:getIsGroundReferenceNodeActive(v64_.groundReferenceNode)
		end
		if v64_.hasGroundContact ~= v67_ then
			self:raiseDirtyFlags(v64_.dirtyFlag)
			v64_.hasGroundContact = v67_
		end
	end
	if self:getIsAIActive() and (not g_currentMission.missionInfo.helperBuySeeds and v64_.mountedSaplingPallet == nil) then
		self.rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())
	end
	v64_.showWrongPlantingTimeWarning = false
	if v64_.hasGroundContact and self:getIsTurnedOn() then
		local v68_
		if self:getCanPlantOutsideSeason() then
			v68_ = true
		else
			local v69_ = self:getFillUnitFillType(v64_.fillUnitIndex)
			local v70_ = g_fruitTypeManager:getFruitTypeByFillTypeIndex(v69_)
			v68_ = v70_ == nil and true or v70_:getIsPlantableInPeriod(g_currentMission.missionInfo.growthMode, g_currentMission.environment.currentPeriod)
		end
		v64_.showWrongPlantingTimeWarning = not v68_
		if self.isServer and v68_ then
			local v71_ = self:getFillUnitFillLevel(v64_.fillUnitIndex)
			local v72_ = self:getFillUnitFillType(v64_.fillUnitIndex)
			if g_currentMission.missionInfo.helperBuySeeds and self:getIsAIActive() then
				if v64_.mountedSaplingPallet == nil then
					v72_ = FillType.POPLAR
				else
					v72_ = v64_.mountedSaplingPallet:getFillUnitFillType(1)
				end
			end
			if v71_ == 0 and not (self:getIsAIActive() and g_currentMission.missionInfo.helperBuySeeds) then
				v72_ = FillType.UNKNOWN
			end
			if v72_ == FillType.TREESAPLINGS then
				if self:getLastSpeed() > 1 then
					local v73_, v74_, v75_ = getWorldTranslation(v64_.node)
					if g_currentMission.accessHandler:canFarmAccessLand(self:getActiveFarm(), v73_, v75_) then
						if PlacementUtil.isInsideRestrictedZone(g_currentMission.restrictedZones, v73_, v74_, v75_, true) then
							v66_ = true
						elseif v64_.lastTreePos == nil then
							self:createTree()
						elseif MathUtil.vector3Length(v73_ - v64_.lastTreePos[1], v74_ - v64_.lastTreePos[2], v75_ - v64_.lastTreePos[3]) > v64_.minDistance then
							self:createTree()
						end
					else
						v65_ = true
					end
				end
			elseif v72_ ~= FillType.UNKNOWN then
				local v76_, _, v77_ = getWorldTranslation(v64_.node)
				if g_currentMission.accessHandler:canFarmAccessLand(self:getActiveFarm(), v76_, v77_) then
					local v78_ = g_currentMission:getFruitPixelsToSqm()
					local v79_ = math.sqrt(v78_) * 0.5
					local v80_, _, v81_ = localToWorld(v64_.node, -v79_, 0, v79_)
					local v82_, _, v83_ = localToWorld(v64_.node, v79_, 0, v79_)
					local v84_, _, v85_ = localToWorld(v64_.node, -v79_, 0, 3 * v79_)
					local v86_ = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(v72_)
					local v87_ = g_fruitTypeManager:getFruitTypeByIndex(v86_)
					local v88_, _, v89_ = localDirectionToWorld(v64_.node, 0, 0, 1)
					local v90_ = MathUtil.getYRotationFromDirection(v88_, v89_)
					if v87_ ~= nil and v87_.directionSnapAngle ~= 0 then
						local v91_ = v90_ / v87_.directionSnapAngle + 0.5
						v90_ = math.floor(v91_) * v87_.directionSnapAngle
					end
					local v92_ = FSDensityMapUtil.convertToDensityMapAngle(v90_, g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
					local v93_ = v64_.limitToField or v64_.forceLimitToField
					local v94_ = v64_.limitToField or v64_.forceLimitToField
					FSDensityMapUtil.updateCultivatorArea(v80_, v81_, v82_, v83_, v84_, v85_, not v93_, v94_, v92_, nil)
					FSDensityMapUtil.eraseTireTrack(v80_, v81_, v82_, v83_, v84_, v85_)
					local v95_, _, v96_ = localToWorld(v64_.node, -v79_, 0, -3 * v79_)
					local v97_, _, v98_ = localToWorld(v64_.node, v79_, 0, -3 * v79_)
					local v99_, _, v100_ = localToWorld(v64_.node, -v79_, 0, -v79_)
					local v101_ = FieldGroundType.getValueByType(FieldGroundType.SOWN)
					local v102_, _ = FSDensityMapUtil.updateSowingArea(v86_, v95_, v96_, v97_, v98_, v99_, v100_, v101_, false, v92_, 2)
					local v103_ = v87_.seedUsagePerSqm * v102_
					local v104_ = self:getActiveFarm()
					if self:getIsAIActive() and g_currentMission.missionInfo.helperBuySeeds then
						local v105_ = v103_ * g_currentMission.economyManager:getCostPerLiter(FillType.SEEDS, false) * 1.5
						g_farmManager:updateFarmStats(v104_, "expenses", v105_)
						g_currentMission:addMoney(-v105_, self:getActiveFarm(), MoneyType.PURCHASE_SEEDS)
					else
						self:addFillUnitFillLevel(self:getOwnerFarmId(), v64_.fillUnitIndex, -v103_, v72_, ToolType.UNDEFINED)
					end
					local v106_ = MathUtil.areaToHa(v102_, g_currentMission:getFruitPixelsToSqm())
					g_farmManager:updateFarmStats(v104_, "seedUsage", v103_)
					g_farmManager:updateFarmStats(v104_, "sownHectares", v106_)
					g_farmManager:updateFarmStats(v104_, "sownTime", dt / 60000)
					self:updateLastWorkedArea(v102_)
				else
					v65_ = true
				end
			end
		end
	end
	if self.isServer and (v64_.showFieldNotOwnedWarning ~= v65_ or v64_.showRestrictedZoneWarning ~= v66_) then
		v64_.showFieldNotOwnedWarning = v65_
		v64_.showRestrictedZoneWarning = v66_
		self:raiseDirtyFlags(v64_.dirtyFlag)
	end
	if self.isClient then
		if self:getIsTurnedOn() and (v64_.hasGroundContact and self:getLastSpeed() > 1) then
			if not v64_.isWorkSamplePlaying then
				g_soundManager:playSample(v64_.samples.work)
				v64_.isWorkSamplePlaying = true
			end
		elseif v64_.isWorkSamplePlaying then
			g_soundManager:stopSample(v64_.samples.work)
			v64_.isWorkSamplePlaying = false
		end
		local v107_ = v64_.actionEvents[InputAction.IMPLEMENT_EXTRA3]
		if v107_ ~= nil then
			local v108_ = false
			if isActiveForInputIgnoreSelection then
				local v109_ = self:getFillUnitFillType(v64_.fillUnitIndex)
				v108_ = v109_ ~= FillType.UNKNOWN and (v109_ ~= FillType.TREESAPLINGS and (g_currentMission:getHasPlayerPermission("createFields", self:getOwnerConnection()) and not v64_.forceLimitToField)) and true or v108_
				if v108_ then
					if v64_.limitToField then
						g_inputBinding:setActionEventText(v107_.actionEventId, g_i18n:getText("action_allowCreateFields"))
					else
						g_inputBinding:setActionEventText(v107_.actionEventId, g_i18n:getText("action_limitToFields"))
					end
				end
			end
			g_inputBinding:setActionEventActive(v107_.actionEventId, v108_)
		end
		if v64_.inputAction ~= nil then
			local v110_ = v64_.actionEvents[v64_.inputAction]
			if v110_ ~= nil then
				local v111_
				if v64_.lastTreePos == nil then
					v111_ = true
				else
					local v112_, v113_, v114_ = getWorldTranslation(v64_.node)
					v111_ = MathUtil.vector3Length(v112_ - v64_.lastTreePos[1], v113_ - v64_.lastTreePos[2], v114_ - v64_.lastTreePos[3]) > v64_.minDistance
				end
				local v115_ = g_inputBinding
				local v116_ = v110_.actionEventId
				if v111_ then
					v111_ = self:getFillUnitFillLevel(v64_.fillUnitIndex) > 0
				end
				v115_:setActionEventActive(v116_, v111_)
			end
		end
	end
end

-- Local values: spec
function TreePlanter:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v119_ = self.spec_treePlanter
	if isActiveForInputIgnoreSelection then
		if self:getFillUnitFillLevel(v119_.fillUnitIndex) <= 0 then
			g_currentMission:addExtraPrintText(g_i18n:getText("info_firstFillTheTool"))
		end
		if v119_.currentTreeTypeIndex ~= nil and (self:getFillUnitFillLevel(v119_.fillUnitIndex) > 0 and v119_.treeTypeExtraPrintText ~= nil) then
			g_currentMission:addExtraPrintText(v119_.treeTypeExtraPrintText)
		end
	end
	if v119_.showFieldNotOwnedWarning then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"))
	end
	if v119_.showRestrictedZoneWarning then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_actionNotAllowedHere"))
	end
	if v119_.showTooManyTreesWarning then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_tooManyTrees"))
	end
	if v119_.showWrongPlantingTimeWarning then
		g_currentMission:showBlinkingWarning(string.format(g_i18n:getText("warning_theSelectedFruitTypeCantBePlantedInThisPeriod"), g_i18n:formatPeriod()), 100)
	end
end

-- Local values: spec
function TreePlanter:onTurnedOn()
	if self.isClient then
		local v121_ = self.spec_treePlanter
		g_animationManager:startAnimations(v121_.animationNodes)
	end
end

-- Local values: spec
function TreePlanter:onTurnedOff()
	if self.isClient then
		local v123_ = self.spec_treePlanter
		g_animationManager:stopAnimations(v123_.animationNodes)
		g_soundManager:stopSamples(v123_.samples)
		v123_.isWorkSamplePlaying = false
	end
end

-- Local values: trigger, treeTypeName, variationName, treeTypeIndex, variationIndex
function TreePlanter:onFillUnitIsFillingStateChanged(isFilling)
	if self.isServer and isFilling then
		local v126_ = self.spec_fillUnit.fillTrigger.currentTrigger
		if v126_ ~= nil and (v126_.sourceObject ~= nil and v126_.sourceObject.getTreeSaplingPalletType ~= nil) then
			local v127_, v128_ = v126_.sourceObject:getTreeSaplingPalletType()
			local v129_, v130_ = g_treePlantManager:getTreeTypeIndexAndVariationFromName(v127_, 1, v128_)
			self:setTreePlanterTreeTypeIndex(v129_, v130_)
		end
	end
end

function TreePlanter:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	if fillUnitIndex == self.spec_treePlanter.fillUnitIndex then
		self:updateTreePlanterFillLevel()
	end
end

-- Local values: spec, treeTypeName, variationName
function TreePlanter:onFillUnitUnloadPallet(pallet)
	local v135_ = self.spec_treePlanter
	if pallet.setTreeSaplingPalletType ~= nil then
		local v136_, v137_ = g_treePlantManager:getTreeTypeNameAndVariationByIndex(v135_.currentTreeTypeIndex, 1, v135_.currentTreeVariationIndex)
		pallet:setTreeSaplingPalletType(v136_, v137_)
	end
	if v135_.mountedSaplingPallet == pallet then
		v135_.mountedSaplingPallet = nil
	end
end

-- Local values: spec, pallet, fillUnits, palletFillUnitIndex, _
function TreePlanter:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	local v146_ = self.spec_treePlanter
	if fillUnitIndex == v146_.fillUnitIndex then
		local v147_ = v146_.mountedSaplingPallet
		if v147_ ~= nil then
			local v148_ = v147_:getFillUnits()
			for v149_, _ in pairs(v148_) do
				if v147_:getFillUnitFillType(fillUnitIndex) == fillTypeIndex then
					return v147_:addFillUnitFillLevel(self:getOwnerFarmId(), v149_, fillLevelDelta, fillTypeIndex, ToolType.UNDEFINED)
				end
			end
		end
	end
	return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
end

-- Local values: spec, pallet, fillLevel, fillUnits, palletFillUnitIndex, _
function TreePlanter:getFillUnitFillLevel(superFunc, fillUnitIndex)
	local v153_ = self.spec_treePlanter
	if fillUnitIndex == v153_.fillUnitIndex then
		local v154_ = v153_.mountedSaplingPallet
		if v154_ ~= nil then
			local v155_ = v154_:getFillUnits()
			local v156_ = 0
			for v157_, _ in pairs(v155_) do
				v156_ = v156_ + v154_:getFillUnitFillLevel(v157_)
			end
			return v156_
		end
	end
	return superFunc(self, fillUnitIndex)
end

-- Local values: spec, pallet, capacity, fillLevel
function TreePlanter:getFillUnitFillLevelPercentage(superFunc, fillUnitIndex)
	local v161_ = self.spec_treePlanter
	if fillUnitIndex == v161_.fillUnitIndex and v161_.mountedSaplingPallet ~= nil then
		local v162_ = self:getFillUnitCapacity(fillUnitIndex)
		local v163_ = self:getFillUnitFillLevel(fillUnitIndex)
		if v162_ > 0 then
			return v163_ / v162_
		end
	end
	return superFunc(self, fillUnitIndex)
end

-- Local values: spec, pallet, fillUnits, palletFillUnitIndex, _
function TreePlanter:getFillUnitFillType(superFunc, fillUnitIndex)
	local v167_ = self.spec_treePlanter
	if fillUnitIndex == v167_.fillUnitIndex then
		local v168_ = v167_.mountedSaplingPallet
		if v168_ ~= nil then
			local v169_ = v168_:getFillUnits()
			for v170_, _ in pairs(v169_) do
				if v168_:getFillUnitFillLevel(v170_) > 0 then
					return v168_:getFillUnitFillType(v170_)
				end
			end
		end
	end
	return superFunc(self, fillUnitIndex)
end

-- Local values: spec, pallet, capacity, fillUnits, palletFillUnitIndex, _
function TreePlanter:getFillUnitCapacity(superFunc, fillUnitIndex)
	local v174_ = self.spec_treePlanter
	if fillUnitIndex == v174_.fillUnitIndex then
		local v175_ = v174_.mountedSaplingPallet
		if v175_ ~= nil then
			local v176_ = v175_:getFillUnits()
			local v177_ = 0
			for v178_, _ in pairs(v176_) do
				v177_ = v177_ + v175_:getFillUnitCapacity(v178_)
			end
			return v177_
		end
	end
	return superFunc(self, fillUnitIndex)
end

-- Local values: spec, pallet
function TreePlanter:getFillUnitAllowsFillType(superFunc, fillUnitIndex, fillType)
	local v183_ = self.spec_treePlanter
	if fillUnitIndex == v183_.fillUnitIndex and v183_.mountedSaplingPallet ~= nil then
		return false
	else
		return superFunc(self, fillUnitIndex, fillType)
	end
end

-- Local values: spec, pallet
function TreePlanter:getFillUnitFreeCapacity(superFunc, fillUnitIndex, fillTypeIndex, farmId)
	local v189_ = self.spec_treePlanter
	return fillUnitIndex == v189_.fillUnitIndex and v189_.mountedSaplingPallet ~= nil and 0 or superFunc(self, fillUnitIndex, fillTypeIndex, farmId)
end

-- Local values: spec, pallet, capacity, fillLevel, fillType
function TreePlanter:getFillLevelInformation(superFunc, display)
	local v193_ = self.spec_treePlanter
	if v193_.mountedSaplingPallet ~= nil then
		local v194_ = self:getFillUnitCapacity(v193_.fillUnitIndex)
		local v195_ = self:getFillUnitFillLevel(v193_.fillUnitIndex)
		display:addFillLevel(self:getFillUnitFillType(v193_.fillUnitIndex), v195_, v194_)
	end
	superFunc(self, display)
end

-- Local values: pallet
function TreePlanter:getHasObjectMounted(superFunc, object)
	if superFunc(self, object) then
		return true
	end
	local v199_ = self.spec_treePlanter.mountedSaplingPallet
	if v199_ ~= nil then
		if v199_ == object then
			return true
		end
		if v199_.getHasObjectMounted ~= nil and v199_:getHasObjectMounted(object) then
			return true
		end
	end
	return false
end

-- Local values: spec
function TreePlanter:getFillUnitUnloadPalletFilename(superFunc, fillUnitIndex)
	local v201_ = self.spec_treePlanter
	if v201_.mountedSaplingPallet == nil and v201_.currentTreeTypeIndex ~= nil then
		return g_treePlantManager:getPalletStoreItemFilenameByIndex(v201_.currentTreeTypeIndex, 1, v201_.currentTreeVariationIndex)
	end
end

function TreePlanter:getFillUnitHasMountedPalletsToUnload(superFunc)
	return self.spec_treePlanter.mountedSaplingPallet ~= nil
end

function TreePlanter:getFillUnitMountedPalletsToUnload(superFunc)
	return { self.spec_treePlanter.mountedSaplingPallet }
end

function TreePlanter:getImplementAllowAutomaticSteering(superFunc)
	return true
end

function TreePlanter:getCanPlantOutsideSeason()
	return false
end

-- Local values: spec, treeTypeDesc, treeSaplingFilename, variations, variation
function TreePlanter:setTreePlanterTreeTypeIndex(treeTypeIndex, treeVariationIndex, noEventSend)
	local v208_ = self.spec_treePlanter
	if treeTypeIndex ~= v208_.currentTreeTypeIndex or treeVariationIndex ~= v208_.currentTreeVariationIndex then
		v208_.currentTreeTypeIndex = treeTypeIndex
		v208_.currentTreeVariationIndex = treeVariationIndex
		local v209_ = g_treePlantManager:getTreeTypeDescFromIndex(v208_.currentTreeTypeIndex)
		if v209_ ~= nil then
			v208_.treeTypeExtraPrintText = string.format("%s: %s", g_i18n:getText("configuration_treeType"), v209_.title)
		end
		if #v208_.saplingNodes > 0 then
			if v208_.saplingSharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(v208_.saplingSharedLoadRequestId)
				v208_.saplingSharedLoadRequestId = nil
			end
			local v210_ = nil
			if v209_ ~= nil then
				local v211_ = v209_.stages[1]
				if v211_ ~= nil then
					local v212_ = v211_[treeVariationIndex]
					if v212_ ~= nil then
						v210_ = v212_.planterFilename or v212_.filename
					end
				end
			end
			if v210_ ~= nil then
				v208_.saplingSharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(v210_, false, false, self.onTreePlanterSaplingLoaded, self)
			end
		end
		TreePlanterTreeTypeEvent.sendEvent(self, treeTypeIndex, treeVariationIndex, noEventSend)
	end
end

-- Local values: sourceSapling, spec, i, sapling
function TreePlanter:onTreePlanterSaplingLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		local v215_ = getChildAt(i3dNode, 0)
		local v216_ = self.spec_treePlanter
		for v217_ = 1, #v216_.saplingNodes do
			local v218_ = clone(v215_, false, false, false)
			link(v216_.saplingNodes[v217_], v218_)
		end
		self:updateTreePlanterFillLevel(true)
		delete(i3dNode)
	end
end

-- Local values: spec, fillLevel, capacity, i, node, targetAnimationTime, animationTime
function TreePlanter:updateTreePlanterFillLevel(onLoad)
	local v221_ = self.spec_treePlanter
	local v222_ = self:getFillUnitFillLevel(v221_.fillUnitIndex)
	local v223_ = self:getFillUnitCapacity(v221_.fillUnitIndex)
	for v224_ = 1, #v221_.saplingNodes do
		local v225_ = v221_.saplingNodes[v224_]
		setVisibility(v225_, v224_ <= MathUtil.round(v222_))
		I3DUtil.setShaderParameterRec(v225_, "hideByIndex", v223_ - v222_, 0, 0, 0)
	end
	if v221_.magazineAnimation.name ~= nil then
		local v226_ = (v222_ - 1) / v223_ * v221_.magazineAnimation.numRows
		local v227_ = math.ceil(v226_) / v221_.magazineAnimation.numRows
		local v228_ = self:getAnimationTime(v221_.magazineAnimation.name)
		if v227_ ~= v228_ then
			self:setAnimationStopTime(v221_.magazineAnimation.name, v227_)
			local v229_ = v221_.magazineAnimation.name
			local v230_ = v221_.magazineAnimation.speedScale
			local v231_ = v227_ - v228_
			self:playAnimation(v229_, v230_ * math.sign(v231_), v228_, true)
			if onLoad then
				AnimatedVehicle.updateAnimationByName(self, v221_.magazineAnimation.name, 999999, true)
			end
		end
	end
	if v221_.unloadActionEventId ~= nil then
		g_inputBinding:setActionEventActive(v221_.unloadActionEventId, v222_ > 0)
	end
end

-- Local values: spec
function TreePlanter:setPlantLimitToField(plantLimitToField, noEventSend)
	local v235_ = self.spec_treePlanter
	if v235_.limitToField ~= plantLimitToField then
		v235_.limitToField = plantLimitToField
		PlantLimitToFieldEvent.sendEvent(self, plantLimitToField, noEventSend)
	end
end

-- Local values: spec, x, y, z, yRot, treeTypeIndex, variationIndex, farmId, pallet, storeItem, pricePerSapling, fillLevelChange, x, y, z
function TreePlanter:createTree(noEventSend)
	local v238_ = self.spec_treePlanter
	if g_treePlantManager:canPlantTree() then
		if self.isServer then
			local v239_, v240_, v241_ = getWorldTranslation(v238_.node)
			local v242_ = math.random() * 2 * 3.141592653589793
			local v243_ = v238_.currentTreeTypeIndex
			local v244_ = v238_.currentTreeVariationIndex
			if v243_ == nil or v244_ == nil then
				Logging.error("Failed to plant tree. Tree type not found. (treeType %s, variation %s)", v243_, v244_)
				return
			end
			g_treePlantManager:plantTree(v243_, v239_, v240_, v241_, 0, v242_, 0, 1, v244_)
			if v238_.lastTreePos == nil then
				v238_.lastTreePos = { v239_, v240_, v241_ }
			else
				local v245_ = v238_.lastTreePos
				local v246_ = v238_.lastTreePos
				local v247_ = v238_.lastTreePos
				v245_[1] = v239_
				v246_[2] = v240_
				v247_[3] = v241_
			end
			local v248_ = self:getActiveFarm()
			if g_currentMission.missionInfo.helperBuySeeds and self:getIsAIActive() then
				local v249_ = v238_.mountedSaplingPallet
				if v249_ ~= nil then
					local v250_ = 1.5 * (g_storeManager:getItemByXMLFilename(v249_.configFileName).price / v249_:getFillUnitCapacity(1))
					g_farmManager:updateFarmStats(v248_, "expenses", v250_)
					g_currentMission:addMoney(-v250_, self:getActiveFarm(), MoneyType.PURCHASE_SEEDS)
				end
			else
				local v251_ = self:getFillUnitFillLevel(v238_.fillUnitIndex) < 1.5 and -math.huge or -0.9999
				self:addFillUnitFillLevel(self:getOwnerFarmId(), v238_.fillUnitIndex, v251_, self:getFillUnitFillType(v238_.fillUnitIndex), ToolType.UNDEFINED)
			end
			g_farmManager:updateFarmStats(v248_, "plantedTreeCount", 1)
		else
			local v252_, v253_, v254_ = getWorldTranslation(v238_.node)
			if v238_.lastTreePos == nil then
				v238_.lastTreePos = { v252_, v253_, v254_ }
			else
				local v255_ = v238_.lastTreePos
				local v256_ = v238_.lastTreePos
				local v257_ = v238_.lastTreePos
				v255_[1] = v252_
				v256_[2] = v253_
				v257_[3] = v254_
			end
		end
		if self.isClient and v238_.plantAnimation.name ~= nil then
			self:setAnimationTime(v238_.plantAnimation.name, 0, true)
			self:playAnimation(v238_.plantAnimation.name, v238_.plantAnimation.speedScale, 0, true)
		end
		TreePlanterCreateTreeEvent.sendEvent(self, noEventSend)
	else
		v238_.showTooManyTreesWarning = true
	end
end

-- Local values: spec
function TreePlanter:loadPallet(palletObjectId, noEventSend)
	local v261_ = self.spec_treePlanter
	TreePlanterLoadPalletEvent.sendEvent(self, palletObjectId, noEventSend)
	v261_.palletIdToMount = palletObjectId
end

-- Local values: multiplier, spec
function TreePlanter:getDirtMultiplier(superFunc)
	local v264_ = superFunc(self)
	if self.spec_treePlanter.hasGroundContact then
		v264_ = v264_ + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end
	return v264_
end

-- Local values: multiplier, spec
function TreePlanter:getWearMultiplier(superFunc)
	local v267_ = superFunc(self)
	if self.spec_treePlanter.hasGroundContact then
		v267_ = v267_ + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	end
	return v267_
end

-- Local values: spec
function TreePlanter:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	if self.spec_treePlanter.hasGroundContact then
		return superFunc(self, speedRotatingPart)
	else
		return false
	end
end

-- Local values: spec, isActive
function TreePlanter:getIsWorkAreaActive(superFunc, workArea)
	local v274_ = self.spec_treePlanter
	local v275_ = superFunc(self, workArea)
	if workArea.groundReferenceNode == v274_.groundReferenceNode and not self:getIsTurnedOn() then
		v275_ = false
	end
	return v275_
end

function TreePlanter:doCheckSpeedLimit(superFunc)
	local v278_ = not superFunc(self) and self:getIsTurnedOn()
	if v278_ then
		v278_ = self:getIsImplementChainLowered()
	end
	return v278_
end

function TreePlanter:getCanBeSelected(superFunc)
	return true
end

-- Local values: spec
function TreePlanter:onDeleteTreePlanterObject(object)
	local v281_ = self.spec_treePlanter
	if v281_.mountedSaplingPallet == object then
		v281_.mountedSaplingPallet = nil
	end
	v281_.palletsInTrigger[object] = nil
end

function TreePlanter:getIsOnField(superFunc)
	return superFunc(self) and true or (self.spec_treePlanter.hasGroundContact and true or false)
end

-- Local values: spec, object, currentValue
function TreePlanter:palletTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	local v288_ = self.spec_treePlanter
	if otherId ~= 0 then
		local v289_ = g_currentMission:getNodeObject(otherId)
		if v289_ ~= nil and (v289_.isa ~= nil and (v289_:isa(Vehicle) and (v289_.isPallet and g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), v289_)))) then
			local v290_ = Utils.getNoNil(v288_.palletsInTrigger[v289_], 0)
			if onEnter then
				v288_.palletsInTrigger[v289_] = v290_ + 1
				if v290_ == 0 and v289_.addDeleteListener ~= nil then
					v289_:addDeleteListener(self, "onDeleteTreePlanterObject")
				end
			elseif onLeave then
				local v291_ = v288_.palletsInTrigger
				local v292_ = v290_ - 1
				v291_[v289_] = math.max(v292_, 0)
			end
			if v288_.palletsInTrigger[v289_] == 0 then
				v288_.palletsInTrigger[v289_] = nil
			end
		end
	end
end

-- Local values: spec, _, actionEventId, _, actionEventId
function TreePlanter:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v295_ = self.spec_treePlanter
		self:clearActionEventsTable(v295_.actionEvents)
		if isActiveForInputIgnoreSelection then
			if not v295_.forceLimitToField then
				local _, v296_ = self:addActionEvent(v295_.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, TreePlanter.actionEventToggleTreePlanterFieldLimitation, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v296_, GS_PRIO_NORMAL)
			end
			if v295_.inputAction ~= nil then
				local _, v297_ = self:addPoweredActionEvent(v295_.actionEvents, v295_.inputAction, self, TreePlanter.actionEventPlant, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v297_, GS_PRIO_HIGH)
				g_inputBinding:setActionEventText(v297_, g_i18n:getText("action_plantTree"))
			end
		end
	end
end

function TreePlanter:actionEventToggleTreePlanterFieldLimitation(actionName, inputValue, callbackState, isAnalog)
	self:setPlantLimitToField(not self.spec_treePlanter.limitToField)
end

-- Local values: spec, x, y, z
function TreePlanter:actionEventPlant(actionName, inputValue, callbackState, isAnalog)
	local v300_ = self.spec_treePlanter
	if v300_.hasGroundContact then
		if g_treePlantManager:canPlantTree() then
			local v301_, v302_, v303_ = getWorldTranslation(v300_.node)
			if g_currentMission.accessHandler:canFarmAccessLand(self:getActiveFarm(), v301_, v303_) then
				if PlacementUtil.isInsideRestrictedZone(g_currentMission.restrictedZones, v301_, v302_, v303_, true) then
					g_currentMission:showBlinkingWarning(g_i18n:getText("warning_actionNotAllowedHere"))
				else
					self:createTree()
				end
			else
				g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"))
				return
			end
		else
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_tooManyTrees"))
			return
		end
	else
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_treePlanterNoGroundContact"))
		return
	end
end
function TreePlanter.getDefaultSpeedLimit()
	return 5
end

-- Local values: spec, nearestDistance, nearestSaplingPallet, object, state, distance, validPallet, fillUnits, fillUnitIndex, _, filltype
function TreePlanter:getSaplingPalletInRange(refNode, palletsInTrigger)
	local v307_ = self.spec_treePlanter
	local v308_ = v307_.nearestPalletDistance
	local v309_ = nil
	for v310_, v311_ in pairs(palletsInTrigger) do
		if v311_ ~= nil and (v311_ > 0 and (v310_ ~= v307_.mountedSaplingPallet and calcDistanceFrom(refNode, v310_.rootNode) < v308_)) then
			local v312_ = v310_:getFillUnits()
			local v313_ = false
			for v314_, _ in pairs(v312_) do
				local v315_ = v310_:getFillUnitFillType(v314_)
				if v315_ ~= FillType.UNKNOWN and (self:getFillUnitSupportsFillType(v307_.fillUnitIndex, v315_) and v310_:getFillUnitFillLevel(v314_) > 0) then
					v313_ = true
					break
				end
			end
			if v313_ then
				v309_ = v310_
			end
		end
	end
	return v309_
end
TreePlanterActivatable = {}
local v_u_316_ = Class(TreePlanterActivatable)

-- Upvalues: TreePlanterActivatable_mt
-- Local values: self
function TreePlanterActivatable.new(treePlanterVehicle)
	-- upvalues: (copy) v_u_316_
	local v318_ = v_u_316_
	local v319_ = setmetatable({}, v318_)
	v319_.treePlanterVehicle = treePlanterVehicle
	v319_.activateText = string.format(g_i18n:getText("action_refillOBJECT"), v319_.treePlanterVehicle.typeDesc)
	return v319_
end

function TreePlanterActivatable:getIsActivatable()
	if self.treePlanterVehicle.rootVehicle == g_localPlayer:getCurrentVehicle() then
		return self.treePlanterVehicle.spec_treePlanter.mountedSaplingPallet == nil and self.treePlanterVehicle.spec_treePlanter.nearestSaplingPallet ~= nil
	else
		return false
	end
end

function TreePlanterActivatable:run()
	self.treePlanterVehicle:loadPallet(NetworkUtil.getObjectId(self.treePlanterVehicle.spec_treePlanter.nearestSaplingPallet))
end
