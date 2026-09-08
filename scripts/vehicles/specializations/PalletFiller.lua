PalletFiller = {}
source("dataS/scripts/vehicles/specializations/enums/PalletFillerState.lua")
source("dataS/scripts/vehicles/specializations/events/PalletFillerBuyPalletEvent.lua")
source("dataS/scripts/vehicles/specializations/events/PalletFillerStateEvent.lua")

function PalletFiller.prerequisitesPresent(specializations)
	return true
end
function PalletFiller.initSpecialization()
	local v1_ = Vehicle.xmlSchema
	v1_:setXMLSpecializationType("PalletFiller")
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.palletFiller.pickupTrigger#node", "Pickup pallet trigger")
	v1_:register(XMLValueType.STRING, "vehicle.palletFiller.pallet#filename", "Filename to supported pallet xml file")
	v1_:register(XMLValueType.FLOAT, "vehicle.palletFiller.pallet#spacing", "Spacing between the pallets while they are loaded", 0.5)
	v1_:register(XMLValueType.NODE_INDEX, "vehicle.palletFiller.palletRow#node", "Pallet row node")
	v1_:register(XMLValueType.INT, "vehicle.palletFiller.palletRow#maxNumPallets", "Max. number of pallets that can be picked up", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.palletFiller.palletRow#minTransZ", "Min. translation of the row (drop off point)", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.palletFiller.palletRow#maxTransZ", "Max. translation of the row (pick up point)", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.palletFiller.palletRow#moveSpeed", "Move speed of pallet on the row (m/sec)", 1)
	v1_:register(XMLValueType.TIME, "vehicle.palletFiller.palletRow#pickupTime", "Time until the pallet is fully picked up (sec)", 2)
	v1_:register(XMLValueType.ANGLE, "vehicle.palletFiller.palletRow#yRotation", "Y Rotation of the pallet", 0)
	v1_:register(XMLValueType.TIME, "vehicle.palletFiller.palletRow#loadingDelay", "Loading delay used for combine", 0)
	v1_:register(XMLValueType.VECTOR_ROT, "vehicle.palletFiller.palletRow.rotLimit#startLimit", "Start rotation limit after pickup", "0 0 0")
	v1_:register(XMLValueType.VECTOR_ROT, "vehicle.palletFiller.palletRow.rotLimit#endLimit", "End rotation limit while fully mounted", "0 0 0")
	v1_:register(XMLValueType.VECTOR_ROT, "vehicle.palletFiller.palletRow.rotLimit#unloadLimit", "Rotation limit while unloading", "0 0 25")
	v1_:register(XMLValueType.VECTOR_TRANS, "vehicle.palletFiller.palletRow.transLimit#startLimit", "Start translation limit after pickup", "0.25 2 0.25")
	v1_:register(XMLValueType.VECTOR_TRANS, "vehicle.palletFiller.palletRow.transLimit#endLimit", "End translation limit while fully mounted", "0.05 2 0")
	v1_:register(XMLValueType.VECTOR_TRANS, "vehicle.palletFiller.palletRow.transLimit#unloadLimit", "Translation limit while unloading", "0.25 2 0")
	v1_:register(XMLValueType.FLOAT, "vehicle.palletFiller.palletRow.fillStep(?)#transZ", "Target Z translation of the pickup of pallet while filling this pallet index", 0)
	v1_:register(XMLValueType.INT, "vehicle.palletFiller.palletRow.fillStep(?)#palletIndex", "Pallet index to fill", 1)
	v1_:register(XMLValueType.INT, "vehicle.palletFiller.palletRow.fillStep(?)#dischargeNodeIndex", "Discharge Node Index (defines which discharge node is used while the defined pallet index is available & not full)", 1)
	v1_:register(XMLValueType.STRING, "vehicle.palletFiller.fillDeflectorAnimation#name", "Name of fill deflector animation (animation is played before the pallets are moving and revered after they are in the new position)")
	v1_:register(XMLValueType.FLOAT, "vehicle.palletFiller.fillDeflectorAnimation#speed", "Animation speed scale", 1)
	v1_:register(XMLValueType.STRING, "vehicle.palletFiller.platformAnimation#name", "Name of platform animation (animation to lower the tool for pallet pickup and drop -> 0=pickup, #middleTime=idle, 1=drop)")
	v1_:register(XMLValueType.FLOAT, "vehicle.palletFiller.platformAnimation#speed", "Animation speed scale", 1)
	v1_:register(XMLValueType.FLOAT, "vehicle.palletFiller.platformAnimation#middleTime", "Animation middle time", 0.5)
	v1_:register(XMLValueType.BOOL, "vehicle.palletFiller.platformAnimation#automaticLift", "Automatically lift platform after dropping or pickup", false)
	v1_:register(XMLValueType.BOOL, "vehicle.palletFiller.platformAnimation#lowerToUnload", "Tool needs to be lowered first to be unloaded", false)
	v1_:register(XMLValueType.FLOAT, "vehicle.palletFiller.foldable#minLimit", "Min. folding time for platform state change [0-1]", 0)
	v1_:register(XMLValueType.FLOAT, "vehicle.palletFiller.foldable#maxLimit", "Max. folding time for platform state change [0-1]", 1)
	SoundManager.registerSampleXMLPaths(v1_, "vehicle.palletFiller.sounds", "move")
	AnimationManager.registerAnimationNodesXMLPaths(v1_, "vehicle.palletFiller.animationNodes")
	v1_:setXMLSpecializationType()
	local v2_ = Vehicle.xmlSchemaSavegame
	PalletFillerState.registerXMLPath(v2_, "vehicles.vehicle(?).palletFiller#state", "Current vehicle state", nil, false)
	v2_:register(XMLValueType.BOOL, "vehicles.vehicle(?).palletFiller#deflectorState", "Current deflector state")
	v2_:register(XMLValueType.INT, "vehicles.vehicle(?).palletFiller.palletSlot(?)#slotIndex", "Index of slot")
	v2_:register(XMLValueType.STRING, "vehicles.vehicle(?).palletFiller.palletSlot(?)#objectUniqueId", "Unique id of the object that is loaded on this slot")
	v2_:register(XMLValueType.VECTOR_TRANS, "vehicles.vehicle(?).palletFiller.palletSlot(?)#translation", "Translation of the joint")
	v2_:register(XMLValueType.VECTOR_ROT, "vehicles.vehicle(?).palletFiller.palletSlot(?)#rotation", "Rotation of the joint")
end

function PalletFiller.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadPalletFillerPallet", PalletFiller.loadPalletFillerPallet)
	SpecializationUtil.registerFunction(vehicleType, "unloadPalletFillerPallet", PalletFiller.unloadPalletFillerPallet)
	SpecializationUtil.registerFunction(vehicleType, "buyPalletFillerPallets", PalletFiller.buyPalletFillerPallets)
	SpecializationUtil.registerFunction(vehicleType, "getCanChangePalletFillerState", PalletFiller.getCanChangePalletFillerState)
	SpecializationUtil.registerFunction(vehicleType, "getCanBuyPalletFillerPallets", PalletFiller.getCanBuyPalletFillerPallets)
	SpecializationUtil.registerFunction(vehicleType, "setPalletFillerState", PalletFiller.setPalletFillerState)
	SpecializationUtil.registerFunction(vehicleType, "setPalletFillerDeflectorState", PalletFiller.setPalletFillerDeflectorState)
	SpecializationUtil.registerFunction(vehicleType, "getPalletFillerFillStep", PalletFiller.getPalletFillerFillStep)
	SpecializationUtil.registerFunction(vehicleType, "getPalletFillerMovementDirection", PalletFiller.getPalletFillerMovementDirection)
end

function PalletFiller.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleDischargeToObject", PalletFiller.getCanToggleDischargeToObject)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleDischargeToGround", PalletFiller.getCanToggleDischargeToGround)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", PalletFiller.removeFromPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", PalletFiller.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", PalletFiller.getFillLevelInformation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getHasObjectMounted", PalletFiller.getHasObjectMounted)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", PalletFiller.getCanAIImplementContinueWork)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "verifyCombine", PalletFiller.verifyCombine)
end

function PalletFiller.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", PalletFiller)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", PalletFiller)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", PalletFiller)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", PalletFiller)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", PalletFiller)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", PalletFiller)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", PalletFiller)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", PalletFiller)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", PalletFiller)
	SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", PalletFiller)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldTimeChanged", PalletFiller)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", PalletFiller)
end

-- Local values: spec, basePath, i, palletSlot
function PalletFiller:onLoad(savegame)
	local v_u_7_ = self.spec_palletFiller
	v_u_7_.state = PalletFillerState.IDLE
	v_u_7_.pickupTrigger = {}
	v_u_7_.pickupTrigger.node = self.xmlFile:getValue("vehicle.palletFiller.pickupTrigger#node", nil, self.components, self.i3dMappings)
	if v_u_7_.pickupTrigger.node ~= nil then
		v_u_7_.pickupTrigger.triggeredObjects = {}
		function v_u_7_.pickupTrigger.pickupTriggerCallback(_, _, p8_, p9_, p10_, _, _)
			-- upvalues: (copy) v_u_7_, (copy) self
			local v11_ = g_currentMission:getNodeObject(p8_)
			if v11_ ~= nil and v11_:isa(Vehicle) then
				if p9_ then
					for _, v12_ in ipairs(v_u_7_.palletRow.palletSlots) do
						if v12_.object == v11_ then
							return
						end
					end
					if v11_.configFileName == v_u_7_.pallet.filename then
						v_u_7_.pickupTrigger.triggeredObjects[p8_] = (v_u_7_.pickupTrigger.triggeredObjects[p8_] or 0) + 1
						v11_:addDeleteListener(self, PalletFiller.onObjectDeleted)
						self:raiseActive()
						return
					end
				elseif p10_ then
					v_u_7_.pickupTrigger.triggeredObjects[p8_] = (v_u_7_.pickupTrigger.triggeredObjects[p8_] or 0) - 1
					if v_u_7_.pickupTrigger.triggeredObjects[p8_] <= 0 then
						v_u_7_.pickupTrigger.triggeredObjects[p8_] = nil
						v11_:removeDeleteListener(self, PalletFiller.onObjectDeleted)
					end
				end
			end
		end
		addTrigger(v_u_7_.pickupTrigger.node, "pickupTriggerCallback", v_u_7_.pickupTrigger)
	end
	v_u_7_.pallet = {}
	v_u_7_.pallet.filename = self.xmlFile:getValue("vehicle.palletFiller.pallet#filename")
	if v_u_7_.pallet.filename == nil then
		Logging.xmlWarning(self.xmlFile, "No pallet filename defined for \'%s\'", "vehicle.palletFiller")
	else
		v_u_7_.pallet.filename = Utils.getFilename(v_u_7_.pallet.filename, self.baseDirectory)
		v_u_7_.pallet.storeItem = g_storeManager:getItemByXMLFilename(v_u_7_.pallet.filename)
		if v_u_7_.pallet.storeItem == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid pallet filename defined for \'%s\' (%s)", "vehicle.palletFiller", v_u_7_.pallet.filename)
			v_u_7_.pallet.filename = nil
		end
	end
	v_u_7_.pallet.spacing = self.xmlFile:getValue("vehicle.palletFiller.pallet#spacing", 0.5)
	v_u_7_.palletRow = {}
	v_u_7_.palletRow.node = self.xmlFile:getValue("vehicle.palletFiller.palletRow#node", nil, self.components, self.i3dMappings)
	v_u_7_.palletRow.maxNumPallets = self.xmlFile:getValue("vehicle.palletFiller.palletRow#maxNumPallets", 1)
	v_u_7_.palletRow.minTransZ = self.xmlFile:getValue("vehicle.palletFiller.palletRow#minTransZ", 0)
	v_u_7_.palletRow.maxTransZ = self.xmlFile:getValue("vehicle.palletFiller.palletRow#maxTransZ", 0)
	v_u_7_.palletRow.moveSpeed = self.xmlFile:getValue("vehicle.palletFiller.palletRow#moveSpeed", 1) / 1000
	v_u_7_.palletRow.pickupTime = self.xmlFile:getValue("vehicle.palletFiller.palletRow#pickupTime", 2)
	v_u_7_.palletRow.yRotation = self.xmlFile:getValue("vehicle.palletFiller.palletRow#yRotation", 0)
	v_u_7_.palletRow.loadingDelay = self.xmlFile:getValue("vehicle.palletFiller.palletRow#loadingDelay", 0)
	v_u_7_.palletRow.fillSteps = {}
	self.xmlFile:iterate("vehicle.palletFiller.palletRow.fillStep", function(_, p13_)
		-- upvalues: (copy) self, (copy) v_u_7_
		local v14_ = {
			["transZ"] = self.xmlFile:getValue(p13_ .. "#transZ", 0),
			["palletIndex"] = self.xmlFile:getValue(p13_ .. "#palletIndex", 1),
			["dischargeNodeIndex"] = self.xmlFile:getValue(p13_ .. "#dischargeNodeIndex", 1),
			["index"] = #v_u_7_.palletRow.fillSteps + 1
		}
		local v15_ = v_u_7_.palletRow.fillSteps
		table.insert(v15_, v14_)
	end)
	v_u_7_.palletRow.startRotLimit = self.xmlFile:getValue("vehicle.palletFiller.palletRow.rotLimit#startLimit", "0 0 0", true)
	v_u_7_.palletRow.endRotLimit = self.xmlFile:getValue("vehicle.palletFiller.palletRow.rotLimit#endLimit", "0 0 0", true)
	v_u_7_.palletRow.unloadRotLimit = self.xmlFile:getValue("vehicle.palletFiller.palletRow.rotLimit#unloadLimit", "0 0 25", true)
	v_u_7_.palletRow.startTransLimit = self.xmlFile:getValue("vehicle.palletFiller.palletRow.transLimit#startLimit", "0.25 2 0.25", true)
	v_u_7_.palletRow.endTransLimit = self.xmlFile:getValue("vehicle.palletFiller.palletRow.transLimit#endLimit", "0 2 0", true)
	v_u_7_.palletRow.unloadTransLimit = self.xmlFile:getValue("vehicle.palletFiller.palletRow.transLimit#unloadLimit", "0.25 2 0", true)
	v_u_7_.palletRow.palletSlots = {}
	for v16_ = 1, v_u_7_.palletRow.maxNumPallets do
		local v17_ = {
			["jointNode"] = createTransformGroup("jointNode" .. v16_)
		}
		link(v_u_7_.palletRow.node, v17_.jointNode)
		setTranslation(v17_.jointNode, 0, 0, 0)
		setRotation(v17_.jointNode, 0, v_u_7_.palletRow.yRotation, 0)
		v17_.object = nil
		v17_.interpolationTimer = 0
		v17_.index = #v_u_7_.palletRow.palletSlots + 1
		local v18_ = v_u_7_.palletRow.palletSlots
		table.insert(v18_, v17_)
	end
	v_u_7_.palletRow.currentTransZ = 0
	v_u_7_.palletRow.currentDischargeNodeIndex = 1
	v_u_7_.palletRow.isMoving = false
	v_u_7_.fillDeflectorAnimation = {}
	v_u_7_.fillDeflectorAnimation.name = self.xmlFile:getValue("vehicle.palletFiller.fillDeflectorAnimation#name")
	v_u_7_.fillDeflectorAnimation.speed = self.xmlFile:getValue("vehicle.palletFiller.fillDeflectorAnimation#speed", 1)
	v_u_7_.fillDeflectorAnimation.state = false
	v_u_7_.platformAnimation = {}
	v_u_7_.platformAnimation.name = self.xmlFile:getValue("vehicle.palletFiller.platformAnimation#name")
	v_u_7_.platformAnimation.speed = self.xmlFile:getValue("vehicle.palletFiller.platformAnimation#speed", 1)
	v_u_7_.platformAnimation.middleTime = self.xmlFile:getValue("vehicle.palletFiller.platformAnimation#middleTime", 0.5)
	v_u_7_.platformAnimation.automaticLift = self.xmlFile:getValue("vehicle.palletFiller.platformAnimation#automaticLift", false)
	v_u_7_.platformAnimation.lowerToUnload = self.xmlFile:getValue("vehicle.palletFiller.platformAnimation#lowerToUnload", false)
	v_u_7_.foldable = {}
	v_u_7_.foldable.minLimit = self.xmlFile:getValue("vehicle.palletFiller.foldable#minLimit", 0)
	v_u_7_.foldable.maxLimit = self.xmlFile:getValue("vehicle.palletFiller.foldable#maxLimit", 1)
	if self.isClient then
		v_u_7_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.palletFiller.animationNodes", self.components, self, self.i3dMappings)
		v_u_7_.samples = {}
		v_u_7_.samples.move = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.palletFiller.sounds", "move", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v_u_7_.texts = {}
	v_u_7_.texts.warningPalletFillerNoPalletAvailable = g_i18n:getText("warning_palletFillerNoPalletAvailable", PalletFiller.MOD_NAME)
	v_u_7_.dirtyFlag = self:getNextDirtyFlag()
	if not self.isServer then
		SpecializationUtil.removeEventListener(self, "onUpdate", PalletFiller)
	end
	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", PalletFiller)
	end
end

-- Local values: spec, spec_combine, i, key, state, deflectorState
function PalletFiller:onLoadFinished(savegame)
	local v_u_21_ = self.spec_palletFiller
	if v_u_21_.palletRow.loadingDelay > 0 then
		local v22_ = self.spec_combine
		if self.spec_combine ~= nil then
			v22_.loadingDelay = v_u_21_.palletRow.loadingDelay
			v22_.unloadingDelay = v_u_21_.palletRow.loadingDelay
			v22_.loadingDelaySlotsDelayedInsert = false
			v22_.loadingDelaySlots = {}
			for v23_ = 1, v22_.loadingDelay / 1000 * 60 + 1 do
				v22_.loadingDelaySlots[v23_] = {
					["time"] = -math.huge,
					["fillLevelDelta"] = 0,
					["fillType"] = 0,
					["valid"] = false
				}
			end
		end
	end
	self:setAnimationTime(v_u_21_.platformAnimation.name, 1, true, false)
	self:setAnimationTime(v_u_21_.platformAnimation.name, 0, true, false)
	if savegame == nil or savegame.resetVehicles then
		self:setPalletFillerState(v_u_21_.state, true, true)
	else
		local v24_ = savegame.key .. ".palletFiller"
		local v25_ = PalletFillerState.loadFromXMLFile(savegame.xmlFile, v24_ .. "#state")
		if v25_ ~= nil then
			self:setPalletFillerState(v25_, true, true)
		end
		self:setPalletFillerDeflectorState(savegame.xmlFile:getValue(v24_ .. "#deflectorState", v_u_21_.fillDeflectorAnimation.state), true)
		v_u_21_.objectsToLoad = {}
		savegame.xmlFile:iterate(v24_ .. ".palletSlot", function(_, p26_)
			-- upvalues: (copy) savegame, (copy) v_u_21_
			local v27_ = {
				["slotIndex"] = savegame.xmlFile:getValue(p26_ .. "#slotIndex"),
				["objectUniqueId"] = savegame.xmlFile:getValue(p26_ .. "#objectUniqueId")
			}
			if v27_.slotIndex ~= nil and v27_.objectUniqueId ~= nil then
				v27_.translation = savegame.xmlFile:getValue(p26_ .. "#translation", nil, true)
				v27_.rotation = savegame.xmlFile:getValue(p26_ .. "#rotation", nil, true)
				local v28_ = v_u_21_.objectsToLoad
				table.insert(v28_, v27_)
			end
		end)
	end
end

-- Local values: spec, i, palletSlot, slotKey
function PalletFiller:saveToXMLFile(xmlFile, key, usedModNames)
	local v32_ = self.spec_palletFiller
	PalletFillerState.saveToXMLFile(xmlFile, key .. "#state", v32_.state)
	xmlFile:setValue(key .. "#deflectorState", v32_.fillDeflectorAnimation.state)
	for v33_, v34_ in ipairs(v32_.palletRow.palletSlots) do
		if v34_.object ~= nil then
			local v35_ = string.format("%s.palletSlot(%d)", key, v33_ - 1)
			xmlFile:setValue(v35_ .. "#slotIndex", v33_)
			xmlFile:setValue(v35_ .. "#objectUniqueId", v34_.object:getUniqueId())
			xmlFile:setValue(v35_ .. "#translation", getTranslation(v34_.jointNode))
			xmlFile:setValue(v35_ .. "#rotation", getRotation(v34_.jointNode))
		end
	end
end

-- Local values: spec, pickupTrigger, objectId, _, object, i, palletSlot
function PalletFiller:onDelete()
	local v37_ = self.spec_palletFiller
	local v38_ = v37_.pickupTrigger
	if v38_ ~= nil then
		if v38_.node ~= nil then
			removeTrigger(v38_.node)
		end
		if v38_.triggeredObjects ~= nil then
			for v39_, _ in pairs(v38_.triggeredObjects) do
				local v40_ = NetworkUtil.getObject(v39_)
				if v40_ ~= nil and v40_.removeDeleteListener ~= nil then
					v40_:removeDeleteListener(self, PalletFiller.onObjectDeleted)
				end
			end
			table.clear(v38_.triggeredObjects)
		end
	end
	if v37_.samples ~= nil then
		g_soundManager:deleteSamples(v37_.samples)
	end
	if v37_.palletRow ~= nil then
		for _, v41_ in ipairs(v37_.palletRow.palletSlots) do
			if v41_.object ~= nil then
				self:unloadPalletFillerPallet(v41_.object)
			end
		end
	end
end

-- Local values: spec, state, deflectorState, i, palletSlot
function PalletFiller:onReadStream(streamId, connection)
	local v44_ = self.spec_palletFiller
	self:setPalletFillerState(PalletFillerState.readStream(streamId), true, true)
	self:setPalletFillerDeflectorState(streamReadBool(streamId), true)
	for _, v45_ in ipairs(v44_.palletRow.palletSlots) do
		if streamReadBool(streamId) then
			v45_.object = NetworkUtil.readNodeObject(streamId)
		else
			v45_.object = nil
		end
		v45_.pendingObjectLoading = false
	end
end

-- Local values: spec, i, palletSlot
function PalletFiller:onWriteStream(streamId, connection)
	local v48_ = self.spec_palletFiller
	PalletFillerState.writeStream(streamId, v48_.state)
	streamWriteBool(streamId, v48_.fillDeflectorAnimation.state)
	for _, v49_ in ipairs(v48_.palletRow.palletSlots) do
		if streamWriteBool(streamId, v49_.object ~= nil) then
			NetworkUtil.writeNodeObject(streamId, v49_.object)
		end
	end
end

-- Local values: spec, i, palletSlot
function PalletFiller:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		local v53_ = self.spec_palletFiller
		v53_.palletRow.isMoving = streamReadBool(streamId)
		if v53_.palletRow.isMoving then
			g_animationManager:startAnimations(v53_.animationNodes)
			g_soundManager:playSample(v53_.samples.move)
		else
			g_animationManager:stopAnimations(v53_.animationNodes)
			g_soundManager:stopSample(v53_.samples.move)
		end
		for _, v54_ in ipairs(v53_.palletRow.palletSlots) do
			if streamReadBool(streamId) then
				v54_.objectId = NetworkUtil.readNodeObjectId(streamId)
				v54_.object = NetworkUtil.getObject(v54_.objectId)
				if v54_.object == nil then
					self:raiseActive()
				else
					v54_.objectId = nil
					v54_.pendingObjectLoading = false
				end
			else
				v54_.object = nil
				v54_.pendingObjectLoading = false
			end
		end
		PalletFiller.updatePalletFillerDeflectorState(self)
		PalletFiller.updateActionEventTexts(self)
	end
end

-- Local values: spec, i, palletSlot
function PalletFiller:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v59_ = self.spec_palletFiller
		local v60_ = streamWriteBool
		local v61_ = v59_.dirtyFlag
		if v60_(streamId, bit32.band(dirtyMask, v61_) ~= 0) then
			streamWriteBool(streamId, v59_.palletRow.isMoving)
			for _, v62_ in ipairs(v59_.palletRow.palletSlots) do
				if streamWriteBool(streamId, v62_.object ~= nil) then
					NetworkUtil.writeNodeObject(streamId, v62_.object)
				end
			end
		end
	end
end

-- Local values: spec, i, objectToLoad, vehicle, otherActorId, v, object, allowPickup, _, palletSlot, fillStep, palletsMoving, palletSlotOffset, i, palletSlot, alpha, qStart, qEnd, qx, qy, qz, qw, tx, ty, tz, rlx, rly, rlz, tlx, tly, tlz, targetTrans, _, _, currentTrans, offset, limit, rotLimit, transLimit, rlx, rly, rlz, tlx, tly, tlz, numPallets, _, palletSlot
function PalletFiller:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v65_ = self.spec_palletFiller
	if v65_.objectsToLoad ~= nil and #v65_.objectsToLoad > 0 then
		for v66_ = #v65_.objectsToLoad, 1, -1 do
			local v67_ = v65_.objectsToLoad[v66_]
			local v68_ = g_currentMission.vehicleSystem:getVehicleByUniqueId(v67_.objectUniqueId)
			if v68_ ~= nil then
				if not self:loadPalletFillerPallet(v68_, v67_) then
					Logging.warning("Failed to load pallet object from savegame. UniqueId: %d SlotIndex: %d", v67_.objectUniqueId, v67_.slotIndex)
				end
				v65_.objectsToLoad[v66_] = nil
			end
		end
	end
	if v65_.state == PalletFillerState.LOADING and not self:getIsAnimationPlaying(v65_.platformAnimation.name) then
		for v69_, _ in pairs(v65_.pickupTrigger.triggeredObjects) do
			local v70_ = g_currentMission:getNodeObject(v69_)
			if v70_ ~= nil and (v70_:isa(Vehicle) and self.dynamicMountType == MountableObject.MOUNT_TYPE_NONE) then
				local v71_ = true
				for _, v72_ in ipairs(v65_.palletRow.palletSlots) do
					if v72_.object == v70_ or v72_.interpolationTimer ~= 0 then
						v71_ = false
						break
					end
				end
				if v71_ then
					self:loadPalletFillerPallet(v70_)
				end
			end
			self:raiseActive()
		end
	end
	local v73_ = self:getPalletFillerFillStep()
	if v73_ ~= nil then
		v65_.palletRow.currentTransZ = v73_.transZ
		v65_.palletRow.currentDischargeNodeIndex = v73_.dischargeNodeIndex
		if self:getCurrentDischargeNodeIndex() ~= v73_.dischargeNodeIndex then
			self:setCurrentDischargeNodeIndex(v73_.dischargeNodeIndex)
		end
	end
	local v74_ = 0
	local v75_ = false
	for _, v76_ in ipairs(v65_.palletRow.palletSlots) do
		if v76_.interpolationTimer == 0 then
			if v76_.object ~= nil then
				local v77_ = v65_.palletRow.currentTransZ + v74_
				if v65_.state == PalletFillerState.UNLOADING and v65_.palletRow.minTransZ ~= v65_.palletRow.maxTransZ then
					v77_ = v65_.palletRow.minTransZ - 0.1
				end
				local _, _, v78_ = getTranslation(v76_.jointNode)
				local v79_ = v77_ - v78_
				local v80_ = (v79_ > 0 and math.min or math.max)(v78_ + math.sign(v79_) * v65_.palletRow.moveSpeed * dt, v77_)
				local v81_ = v65_.palletRow.endRotLimit
				local v82_ = v65_.palletRow.endTransLimit
				if v65_.state == PalletFillerState.UNLOADING then
					v81_ = v65_.palletRow.unloadRotLimit
					v82_ = v65_.palletRow.unloadTransLimit
				end
				setTranslation(v76_.jointNode, 0, 0, v80_)
				if v76_.jointIndex ~= nil then
					local v83_ = v81_[1]
					local v84_ = v81_[2]
					local v85_ = v81_[3]
					setJointRotationLimit(v76_.jointIndex, 0, true, -v83_, v83_)
					setJointRotationLimit(v76_.jointIndex, 1, true, -v84_, v84_)
					setJointRotationLimit(v76_.jointIndex, 2, true, -v85_, v85_)
					local v86_ = v82_[1]
					local v87_ = v82_[2]
					local v88_ = v82_[3]
					setJointTranslationLimit(v76_.jointIndex, 0, true, -v86_, v86_)
					setJointTranslationLimit(v76_.jointIndex, 1, true, 0, v87_)
					setJointTranslationLimit(v76_.jointIndex, 2, true, -v88_, v88_)
					setJointFrame(v76_.jointIndex, 0, v76_.jointNode)
				end
				v74_ = v74_ + v65_.pallet.spacing
				v75_ = v75_ or math.abs(v79_) > 0.01
				if v65_.state == PalletFillerState.UNLOADING then
					if v65_.palletRow.minTransZ == v65_.palletRow.maxTransZ then
						if not self:getIsAnimationPlaying(v65_.platformAnimation.name) then
							self:unloadPalletFillerPallet(v76_.object)
						end
					elseif v80_ < v65_.palletRow.minTransZ then
						self:unloadPalletFillerPallet(v76_.object)
					end
				end
			end
		elseif v76_.object == nil then
			v76_.interpolationTimer = 0
		else
			local v89_ = v76_.interpolationTimer - dt
			v76_.interpolationTimer = math.max(v89_, 0)
			local v90_ = 1 - v76_.interpolationTimer / v65_.palletRow.pickupTime
			local v91_ = v76_.startQuaternion
			local v92_ = v76_.endQuaternion
			local v93_, v94_, v95_, v96_ = MathUtil.slerpQuaternionShortestPath(v91_[1], v91_[2], v91_[3], v91_[4], v92_[1], v92_[2], v92_[3], v92_[4], v90_)
			setQuaternion(v76_.jointNode, v93_, v94_, v95_, v96_)
			local v97_, v98_, v99_ = MathUtil.vector3ArrayLerp(v76_.startTranslation, v76_.endTranslation, v90_)
			setTranslation(v76_.jointNode, v97_, v98_, v99_)
			if v76_.jointIndex ~= nil then
				local v100_, v101_, v102_ = MathUtil.vector3ArrayLerp(v65_.palletRow.startRotLimit, v65_.palletRow.endRotLimit, v90_)
				setJointRotationLimit(v76_.jointIndex, 0, true, -v100_, v100_)
				setJointRotationLimit(v76_.jointIndex, 1, true, -v101_, v101_)
				setJointRotationLimit(v76_.jointIndex, 2, true, -v102_, v102_)
				local v103_, v104_, v105_ = MathUtil.vector3ArrayLerp(v65_.palletRow.startTransLimit, v65_.palletRow.endTransLimit, v90_)
				setJointTranslationLimit(v76_.jointIndex, 0, true, -v103_, v103_)
				setJointTranslationLimit(v76_.jointIndex, 1, true, 0, v104_)
				setJointTranslationLimit(v76_.jointIndex, 2, true, -v105_, v105_)
				setJointFrame(v76_.jointIndex, 0, v76_.jointNode)
			end
			v75_ = true
		end
	end
	if v65_.platformAnimation.automaticLift then
		local v106_ = 0
		for _, v107_ in ipairs(v65_.palletRow.palletSlots) do
			if v107_.interpolationTimer == 0 and v107_.object ~= nil then
				v106_ = v106_ + 1
			end
		end
		if v65_.state == PalletFillerState.LOADING then
			if v106_ == #v65_.palletRow.palletSlots then
				self:setPalletFillerState(PalletFillerState.IDLE)
			end
		elseif v65_.state == PalletFillerState.UNLOADING and (v106_ == 0 and next(v65_.pickupTrigger.triggeredObjects) == nil) then
			self:setPalletFillerState(PalletFillerState.IDLE)
		end
	end
	if v75_ ~= v65_.palletRow.isMoving then
		v65_.palletRow.isMoving = v75_
		self:raiseDirtyFlags(v65_.dirtyFlag)
		PalletFiller.updatePalletFillerDeflectorState(self)
		if self.isClient then
			if v75_ then
				g_animationManager:startAnimations(v65_.animationNodes)
				g_soundManager:playSample(v65_.samples.move)
				return
			end
			g_animationManager:stopAnimations(v65_.animationNodes)
			g_soundManager:stopSample(v65_.samples.move)
		end
	end
end

-- Local values: spec, freeCapacity, i, palletSlot, i, palletSlot, object
function PalletFiller:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v110_ = self.spec_palletFiller
	if isActiveForInputIgnoreSelection and (self:getIsTurnedOn() and v110_.state == PalletFillerState.IDLE) then
		local v111_ = 0
		for _, v112_ in ipairs(v110_.palletRow.palletSlots) do
			if v112_.object ~= nil and v112_.object.getFillUnitFreeCapacity ~= nil then
				v111_ = v111_ + v112_.object:getFillUnitFreeCapacity(1)
			end
		end
		if v111_ == 0 then
			g_currentMission:showBlinkingWarning(v110_.texts.warningPalletFillerNoPalletAvailable, 250)
		end
	end
	for _, v113_ in ipairs(v110_.palletRow.palletSlots) do
		if v113_.objectId ~= nil then
			local v114_ = NetworkUtil.getObject(v113_.objectId)
			if v114_ == nil or not v114_:getIsSynchronized() then
				self:raiseActive()
			else
				v113_.object = v114_
				v113_.objectId = nil
				v113_.pendingObjectLoading = false
				PalletFiller.updateActionEventTexts(self)
			end
		end
	end
end

-- Local values: spec
function PalletFiller:onFinishAnimation(name)
	if name == self.spec_palletFiller.platformAnimation.name then
		PalletFiller.updatePalletFillerDeflectorState(self)
	end
end

function PalletFiller:onFoldTimeChanged(name)
	PalletFiller.updateActionEventTexts(self)
end

-- Local values: spec, slotIndex, palletSlot, distance, constr, rlx, rly, rlz, tlx, tly, tlz, dx, _, dz, yRot
function PalletFiller:loadPalletFillerPallet(object, data)
	local v121_ = self.spec_palletFiller
	for v122_, v123_ in ipairs(v121_.palletRow.palletSlots) do
		if data == nil and v123_.object == nil or data ~= nil and data.slotIndex == v122_ then
			v123_.object = object
			if data == nil or data.translation == nil then
				setWorldTranslation(v123_.jointNode, getWorldTranslation(object.rootNode))
				setWorldRotation(v123_.jointNode, getWorldRotation(object.rootNode))
			else
				setTranslation(v123_.jointNode, data.translation[1], data.translation[2], data.translation[3])
				setRotation(v123_.jointNode, data.rotation[1], data.rotation[2], data.rotation[3])
			end
			local v124_ = calcDistanceFrom(v123_.jointNode, object.rootNode)
			local v125_ = JointConstructor.new()
			v125_:setActors(self.rootNode, object.rootNode)
			v125_:setJointTransforms(v123_.jointNode, object.rootNode)
			v125_:setEnableCollision(true)
			local v126_ = v121_.palletRow.startRotLimit[1]
			local v127_ = v121_.palletRow.startRotLimit[2]
			local v128_ = v121_.palletRow.startRotLimit[3]
			v125_:setRotationLimit(0, -v126_, v126_)
			v125_:setRotationLimit(1, -v127_, v127_)
			v125_:setRotationLimit(2, -v128_, v128_)
			local v129_ = v121_.palletRow.startTransLimit[1]
			local v130_ = v121_.palletRow.startTransLimit[2]
			local v131_ = v121_.palletRow.startTransLimit[3]
			v125_:setTranslationLimit(0, true, -v129_, v129_)
			v125_:setTranslationLimit(1, true, 0, v130_)
			v125_:setTranslationLimit(2, true, -v131_, v131_)
			if data == nil then
				v123_.startQuaternion = { getQuaternion(v123_.jointNode) }
				local v132_, _, v133_ = worldDirectionToLocal(getParent(v123_.jointNode), localDirectionToWorld(object.rootNode, 0, 0, 1))
				local v134_ = MathUtil.vector2Normalize(v132_, v133_)
				if math.abs(v134_) < 1.5707963267948966 then
					v123_.endQuaternion = { mathEulerToQuaternion(0, v121_.palletRow.yRotation, 0) }
				else
					v123_.endQuaternion = { mathEulerToQuaternion(0, v121_.palletRow.yRotation + 3.141592653589793, 0) }
				end
				v123_.startTranslation = { getTranslation(v123_.jointNode) }
				v123_.endTranslation = { 0, 0, v121_.palletRow.maxTransZ }
				v123_.interpolationDistance = v124_
				v123_.interpolationTimer = v121_.palletRow.pickupTime
			else
				v123_.interpolationDistance = v124_
				v123_.interpolationTimer = 0
			end
			v123_.jointIndex = v125_:finalize()
			object:setDynamicMountType(MountableObject.MOUNT_TYPE_DYNAMIC)
			self:raiseDirtyFlags(v121_.dirtyFlag)
			PalletFiller.updateActionEventTexts(self)
			return true
		end
	end
	return false
end

-- Local values: spec, i, palletSlot
function PalletFiller:unloadPalletFillerPallet(object)
	local v137_ = self.spec_palletFiller
	for _, v138_ in ipairs(v137_.palletRow.palletSlots) do
		if v138_.object == object then
			v138_.object = nil
			v138_.interpolationTimer = 0
			if v138_.jointIndex ~= nil then
				removeJoint(v138_.jointIndex)
				v138_.jointIndex = nil
			end
			object:setDynamicMountType(MountableObject.MOUNT_TYPE_NONE)
			break
		end
	end
	self:raiseDirtyFlags(v137_.dirtyFlag)
	PalletFiller.updateActionEventTexts(self)
end

-- Local values: spec, palletSlotOffset, i, palletSlot, targetTrans, data, i, palletSlot
function PalletFiller:buyPalletFillerPallets(noEventSend)
	local v141_ = self.spec_palletFiller
	if self.isServer then
		local v142_ = 0
		for _, v143_ in ipairs(v141_.palletRow.palletSlots) do
			local v144_ = v141_.palletRow.currentTransZ + v142_
			setTranslation(v143_.jointNode, 0, 0, v144_)
			if v143_.object == nil then
				v143_.pendingObjectLoading = true
				local v145_ = VehicleLoadingData.new()
				v145_:setFilename(v141_.pallet.filename)
				v145_:setSpawnNode(v143_.jointNode)
				v145_:setIgnoreShopOffset(true)
				v145_:setPropertyState(VehiclePropertyState.OWNED)
				v145_:setOwnerFarmId(self:getOwnerFarmId())
				v145_:load(PalletFiller.onCreatePalletFinished, self, {
					["palletSlot"] = v143_
				})
			elseif v143_.jointIndex ~= nil then
				setJointFrame(v143_.jointIndex, 0, v143_.jointNode)
			end
			v142_ = v142_ + v141_.pallet.spacing
		end
	else
		for _, v146_ in ipairs(v141_.palletRow.palletSlots) do
			if v146_.object == nil then
				v146_.pendingObjectLoading = true
			end
		end
		if noEventSend ~= true then
			g_client:getServerConnection():sendEvent(PalletFillerBuyPalletEvent.new(self))
		end
	end
end

-- Local values: spec, vehicle, data, hasFreeSlots, _, palletSlot
function PalletFiller:onCreatePalletFinished(vehicles, vehicleLoadState, arguments)
	local v151_ = self.spec_palletFiller
	arguments.palletSlot.pendingObjectLoading = false
	if vehicleLoadState == VehicleLoadingState.OK and #vehicles >= 1 then
		local v152_ = vehicles[1]
		v152_:removeFromPhysics()
		v152_:addToPhysics()
		if not self:loadPalletFillerPallet(v152_, {
			["slotIndex"] = arguments.palletSlot.index,
			["translation"] = { getTranslation(arguments.palletSlot.jointNode) },
			["rotation"] = { getRotation(arguments.palletSlot.jointNode) }
		}) then
			v152_:delete()
			return
		end
		g_currentMission:addMoney(-v151_.pallet.storeItem.price, self:getOwnerFarmId(), MoneyType.PURCHASE_PALLETS)
		g_currentMission:addMoneyChange(-v151_.pallet.storeItem.price, self:getOwnerFarmId(), MoneyType.PURCHASE_PALLETS, false)
		local v153_ = false
		for _, v154_ in ipairs(v151_.palletRow.palletSlots) do
			v153_ = v153_ or v154_.object == nil
		end
		if not v153_ then
			g_currentMission:showMoneyChange(MoneyType.PURCHASE_PALLETS)
		end
	end
end

-- Local values: spec, hasPalletsLoaded, hasFreeSlots, _, palletSlot, foldAnimTime
function PalletFiller:getCanChangePalletFillerState(newState)
	local v157_ = self.spec_palletFiller
	if v157_.platformAnimation.automaticLift and v157_.state == PalletFillerState.UNLOADING then
		return false
	end
	local v158_ = false
	local v159_ = false
	for _, v160_ in ipairs(v157_.palletRow.palletSlots) do
		if v160_.object == nil then
			v159_ = true
		else
			v158_ = true
		end
	end
	if v157_.state == PalletFillerState.UNLOADING and v158_ then
		return false
	end
	if v157_.state == PalletFillerState.IDLE and newState == PalletFillerState.UNLOADING then
		if not v158_ then
			return false
		end
		if v157_.platformAnimation.lowerToUnload and not self:getIsLowered(true) then
			return false, string.format(g_i18n:getText("warning_lowerImplementFirst"), self:getName())
		end
	end
	if v157_.state == PalletFillerState.IDLE and (newState == PalletFillerState.LOADING and not v159_) then
		return false
	end
	if newState ~= PalletFillerState.IDLE then
		local v161_ = self:getFoldAnimTime()
		if v161_ < v157_.foldable.minLimit or v157_.foldable.maxLimit < v161_ then
			return false
		end
	end
	return true
end

-- Local values: spec, foldAnimTime
function PalletFiller:getCanBuyPalletFillerPallets()
	local v163_ = self.spec_palletFiller
	local v164_ = self:getFoldAnimTime()
	if v164_ < v163_.foldable.minLimit or v163_.foldable.maxLimit < v164_ then
		return false, string.format(g_i18n:getText("warning_firstUnfoldTheTool"), self:getFullName())
	else
		return true
	end
end

-- Local values: spec, animationTime, targetTime
function PalletFiller:setPalletFillerState(state, updateAnimations, noEventSend)
	local v169_ = self.spec_palletFiller
	v169_.state = state
	local v170_ = self:getAnimationTime(v169_.platformAnimation.name)
	local v171_ = v169_.platformAnimation.middleTime
	local v172_ = v169_.state == PalletFillerState.LOADING and 0 or (v169_.state == PalletFillerState.UNLOADING and 1 or v171_)
	if v172_ ~= v170_ then
		self:setAnimationStopTime(v169_.platformAnimation.name, v172_)
		local v173_ = v169_.platformAnimation.name
		local v174_ = v169_.platformAnimation.speed
		local v175_ = v172_ - v170_
		self:playAnimation(v173_, v174_ * math.sign(v175_), v170_, true)
		if updateAnimations == true then
			AnimatedVehicle.updateAnimationByName(self, v169_.platformAnimation.name, 99999, true)
		end
	end
	PalletFiller.updateActionEventTexts(self)
	PalletFillerStateEvent.sendEvent(self, state, noEventSend)
end

-- Local values: spec, deflectorState
function PalletFiller:updatePalletFillerDeflectorState()
	local v177_ = self.spec_palletFiller
	local v178_ = self:getAnimationTime(v177_.platformAnimation.name) - v177_.platformAnimation.middleTime
	local v179_ = (math.abs(v178_) > 0.01 or v177_.palletRow.isMoving) and true or false
	if v179_ ~= v177_.fillDeflectorAnimation.state then
		self:setPalletFillerDeflectorState(v179_)
	end
end

-- Local values: spec, direction
function PalletFiller:setPalletFillerDeflectorState(state, updateAnimations)
	local v183_ = self.spec_palletFiller
	v183_.fillDeflectorAnimation.state = state
	local v184_ = v183_.fillDeflectorAnimation.state and 1 or -1
	self:playAnimation(v183_.fillDeflectorAnimation.name, v183_.fillDeflectorAnimation.speed * v184_, self:getAnimationTime(v183_.fillDeflectorAnimation.name), true)
	if updateAnimations == true then
		AnimatedVehicle.updateAnimationByName(self, v183_.fillDeflectorAnimation.name, 99999, true)
	end
end

-- Local values: spec, i, fillStep, palletSlot, i, fillStep, palletSlot
function PalletFiller:getPalletFillerFillStep()
	local v186_ = self.spec_palletFiller
	for _, v187_ in ipairs(v186_.palletRow.fillSteps) do
		local v188_ = v186_.palletRow.palletSlots[v187_.palletIndex]
		if v188_.object ~= nil and v188_.object:getFillUnitFreeCapacity(1) > 0 then
			return v187_
		end
	end
	for _, v189_ in ipairs(v186_.palletRow.fillSteps) do
		if v186_.palletRow.palletSlots[v189_.palletIndex].object == nil then
			return v189_
		end
	end
	return v186_.palletRow.fillSteps[1]
end

-- Local values: spec
function PalletFiller:getPalletFillerMovementDirection()
	local v191_ = self.spec_palletFiller
	return v191_.state == PalletFillerState.LOADING and 1 or (v191_.state == PalletFillerState.UNLOADING and -1 or 0)
end

function PalletFiller:getCanToggleDischargeToObject(superFunc)
	return false
end

function PalletFiller:getCanToggleDischargeToGround(superFunc)
	return false
end

-- Local values: spec, i, palletSlot
function PalletFiller:removeFromPhysics(superFunc)
	local v194_ = self.spec_palletFiller
	if v194_.palletRow ~= nil then
		for _, v195_ in ipairs(v194_.palletRow.palletSlots) do
			if v195_.object ~= nil then
				self:unloadPalletFillerPallet(v195_.object)
			end
		end
	end
	return superFunc(self)
end

-- Local values: spec, i, palletSlot
function PalletFiller:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local v200_ = self.spec_palletFiller
	if v200_.state ~= PalletFillerState.IDLE then
		return false, g_i18n:getText("warning_palletFillerPlatformLowered")
	end
	if v200_.palletRow ~= nil then
		for _, v201_ in ipairs(v200_.palletRow.palletSlots) do
			if v201_.object ~= nil or v201_.pendingObjectLoading then
				return false, g_i18n:getText("warning_palletFillerNoEmpty")
			end
		end
	end
	return superFunc(self, direction, onAiTurnOn)
end

-- Local values: fillType, fillLevel, capacity, spec, i, palletSlot, objectFillType
function PalletFiller:getFillLevelInformation(superFunc, display)
	superFunc(self, display)
	local v205_ = self.spec_palletFiller
	local v206_ = 0
	local v207_ = 0
	local v208_ = nil
	for _, v209_ in ipairs(v205_.palletRow.palletSlots) do
		if v209_.object ~= nil and v209_.object.getFillUnitFillLevel ~= nil then
			local v210_ = v209_.object:getFillUnitFillType(1)
			if v210_ == FillType.UNKNOWN then
				v210_ = v208_
			end
			v206_ = v206_ + v209_.object:getFillUnitFillLevel(1)
			v207_ = v207_ + v209_.object:getFillUnitCapacity(1)
			v208_ = v210_
		end
	end
	if v207_ > 0 then
		display:addFillLevel(v208_ or FillType.UNKNOWN, v206_, v207_)
	end
end

-- Local values: spec, i, palletSlot
function PalletFiller:getHasObjectMounted(superFunc, object)
	if superFunc(self, object) then
		return true
	end
	local v214_ = self.spec_palletFiller
	for _, v215_ in ipairs(v214_.palletRow.palletSlots) do
		if v215_.object ~= nil then
			if v215_.object == object then
				return true
			end
			if v215_.object.getHasObjectMounted ~= nil and v215_.object:getHasObjectMounted(object) then
				return true
			end
		end
	end
	return false
end

-- Local values: freeCapacity, numLoadedPallets, spec, i, palletSlot
function PalletFiller:getCanAIImplementContinueWork(superFunc, isTurning)
	local v219_ = self.spec_palletFiller
	local v220_ = 0
	local v221_ = 0
	for _, v222_ in ipairs(v219_.palletRow.palletSlots) do
		if v222_.object ~= nil and v222_.object.getFillUnitFillLevel ~= nil then
			v220_ = v220_ + v222_.object:getFillUnitFreeCapacity(1)
			v221_ = v221_ + 1
		end
	end
	if v220_ == 0 then
		if v221_ > 0 then
			return false, true, AIMessageErrorPalletsFull.new()
		else
			return false, true, AIMessageErrorNoPalletsLoaded.new()
		end
	else
		return superFunc(self, isTurning)
	end
end
function PalletFiller.verifyCombine(p223_, p224_, p225_, p226_, ...)
	local v227_ = p223_.spec_palletFiller
	local v228_ = 0
	for _, v229_ in ipairs(v227_.palletRow.palletSlots) do
		if v229_.object ~= nil and (v229_.object.getFillUnitFillType ~= nil and v229_.object:getIsSynchronized()) then
			if p226_ ~= FillType.UNKNOWN and not v229_.object:getFillUnitAllowsFillType(1, p226_) then
				return nil, p223_, v229_.object:getFillUnitFillType(1)
			end
			v228_ = v228_ + v229_.object:getFillUnitFreeCapacity(1)
		end
	end
	if v228_ == 0 then
		return nil
	else
		return p224_(p223_, p225_, p226_, ...)
	end
end

-- Local values: spec, _, actionEventId
function PalletFiller:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if isActiveForInputIgnoreSelection and self.isClient then
		local v232_ = self.spec_palletFiller
		self:clearActionEventsTable(v232_.actionEvents)
		if v232_.platformAnimation.name ~= nil then
			local _, v233_ = self:addPoweredActionEvent(v232_.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, PalletFiller.actionEventLowerPlatformLoad, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v233_, GS_PRIO_HIGH)
			local _, v234_ = self:addPoweredActionEvent(v232_.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, PalletFiller.actionEventLowerPlatformUnload, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(v234_, GS_PRIO_HIGH)
			if v232_.pallet.storeItem ~= nil then
				local _, v235_ = self:addPoweredActionEvent(v232_.actionEvents, InputAction.PALLET_FILLER_BUY_PALLETS, self, PalletFiller.actionEventBuyPallets, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(v235_, GS_PRIO_HIGH)
				g_inputBinding:setActionEventText(v235_, g_i18n:getText("action_palletFillerBuyPallets"))
			end
			PalletFiller.updateActionEventTexts(self)
		end
	end
end

-- Local values: spec, loadAction, text, isAllowed, warning, isAllowed, warning, unloadAction, text, isAllowed, warning, isAllowed, warning, buyAction, numPallets, _, palletSlot
function PalletFiller:updateActionEventTexts()
	local v237_ = self.spec_palletFiller
	local v238_ = v237_.actionEvents[InputAction.IMPLEMENT_EXTRA3]
	if v238_ ~= nil then
		local v239_ = nil
		if v237_.state == PalletFillerState.IDLE then
			local v240_, v241_ = self:getCanChangePalletFillerState(PalletFillerState.LOADING)
			if v240_ or v241_ ~= nil then
				v239_ = g_i18n:getText("action_palletFillerLoad")
			end
		elseif v237_.state == PalletFillerState.LOADING then
			local v242_, v243_ = self:getCanChangePalletFillerState(PalletFillerState.IDLE)
			if v242_ or v243_ ~= nil then
				v239_ = g_i18n:getText("action_palletFillerIdle")
			end
		end
		if v239_ == nil then
			g_inputBinding:setActionEventActive(v238_.actionEventId, false)
		else
			g_inputBinding:setActionEventText(v238_.actionEventId, v239_)
			g_inputBinding:setActionEventActive(v238_.actionEventId, true)
		end
	end
	local v244_ = v237_.actionEvents[InputAction.IMPLEMENT_EXTRA4]
	if v244_ ~= nil then
		local v245_ = nil
		if v237_.state == PalletFillerState.IDLE then
			local v246_, v247_ = self:getCanChangePalletFillerState(PalletFillerState.UNLOADING)
			if v246_ or v247_ ~= nil then
				v245_ = g_i18n:getText("action_palletFillerUnload")
			end
		elseif v237_.state == PalletFillerState.UNLOADING then
			local v248_, v249_ = self:getCanChangePalletFillerState(PalletFillerState.IDLE)
			if v248_ or v249_ ~= nil then
				v245_ = g_i18n:getText("action_palletFillerIdle")
			end
		end
		if v245_ == nil then
			g_inputBinding:setActionEventActive(v244_.actionEventId, false)
		else
			g_inputBinding:setActionEventText(v244_.actionEventId, v245_)
			g_inputBinding:setActionEventActive(v244_.actionEventId, true)
		end
	end
	local v250_ = v237_.actionEvents[InputAction.PALLET_FILLER_BUY_PALLETS]
	if v250_ ~= nil then
		local v251_ = 0
		for _, v252_ in ipairs(v237_.palletRow.palletSlots) do
			if v252_.object == nil then
				v251_ = v251_ + 1
			end
		end
		local v253_ = g_inputBinding
		local v254_ = v250_.actionEventId
		local v255_
		if v237_.state == PalletFillerState.IDLE then
			v255_ = v251_ > 0
		else
			v255_ = false
		end
		v253_:setActionEventActive(v254_, v255_)
	end
end

-- Local values: spec, newState, isAllowed, warning
function PalletFiller:actionEventLowerPlatformLoad(actionName, inputValue, callbackState, isAnalog)
	local v257_ = self.spec_palletFiller.state == PalletFillerState.IDLE and PalletFillerState.LOADING or PalletFillerState.IDLE
	local v258_, v259_ = self:getCanChangePalletFillerState(v257_)
	if v258_ then
		self:setPalletFillerState(v257_)
	elseif v259_ ~= nil then
		g_currentMission:showBlinkingWarning(v259_, 2000)
	end
end

-- Local values: spec, newState, isAllowed, warning
function PalletFiller:actionEventLowerPlatformUnload(actionName, inputValue, callbackState, isAnalog)
	local v261_ = self.spec_palletFiller.state == PalletFillerState.IDLE and PalletFillerState.UNLOADING or PalletFillerState.IDLE
	local v262_, v263_ = self:getCanChangePalletFillerState(v261_)
	if v262_ then
		self:setPalletFillerState(v261_)
	elseif v263_ ~= nil then
		g_currentMission:showBlinkingWarning(v263_, 2000)
	end
end

-- Local values: spec, isAllowed, warning, numPallets, _, palletSlot, price, callback
function PalletFiller:actionEventBuyPallets(actionName, inputValue, callbackState, isAnalog)
	local v265_ = self.spec_palletFiller
	local v266_, v267_ = self:getCanBuyPalletFillerPallets()
	if v266_ then
		local v268_ = 0
		for _, v269_ in ipairs(v265_.palletRow.palletSlots) do
			if v269_.object == nil then
				v268_ = v268_ + 1
			end
		end
		local v270_ = v265_.pallet.storeItem.price * v268_
		YesNoDialog.show(function(_, p271_)
			-- upvalues: (copy) self
			if p271_ then
				self:buyPalletFillerPallets()
			end
		end, self, string.format(g_i18n:getText("ui_palletFillerBuyPalletsText"), v268_, g_i18n:formatMoney(v270_)), self:getFullName())
	elseif v267_ ~= nil then
		g_currentMission:showBlinkingWarning(v267_, 2000)
	end
end

-- Local values: spec
function PalletFiller:onObjectDeleted(object)
	self.spec_palletFiller.pickupTrigger.triggeredObjects[object.rootNode] = nil
end
