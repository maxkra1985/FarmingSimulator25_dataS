-- Local values: InlineWrapperActivatable_mt
InlineWrapper = {}
InlineWrapper.INTERACTION_RADIUS = 5
InlineWrapper.CONSUMABLE_TYPE_NAME = "BALE_WRAP"
source("dataS/scripts/vehicles/specializations/events/InlineWrapperPushOffEvent.lua")

function InlineWrapper.prerequisitesPresent(specializations)
	local v2_ = SpecializationUtil.hasSpecialization(Foldable, specializations)
	if v2_ then
		v2_ = SpecializationUtil.hasSpecialization(Consumable, specializations)
	end
	return v2_
end
function InlineWrapper.initSpecialization()
	g_storeManager:addSpecType("inlineWrapperBaleSizeRound", "shopListAttributeIconBaleWrapperBaleSizeRound", InlineWrapper.loadSpecValueBaleSizeRound, InlineWrapper.getSpecValueBaleSizeRound, StoreSpecies.VEHICLE)
	g_storeManager:addSpecType("inlineWrapperBaleSizeSquare", "shopListAttributeIconBaleWrapperBaleSizeSquare", InlineWrapper.loadSpecValueBaleSizeSquare, InlineWrapper.getSpecValueBaleSizeSquare, StoreSpecies.VEHICLE)
	local v3_ = Vehicle.xmlSchema
	v3_:setXMLSpecializationType("InlineWrapper")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.baleTrigger#node", "Bale pickup trigger")
	v3_:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTrigger#minFoldTime", "Min. folding time for bale pickup", 0)
	v3_:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTrigger#maxFoldTime", "Max. folding time for bale pickup", 1)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.wrapTrigger#node", "Wrap trigger")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.baleTypes.baleType(?)#startNode", "Start placement node for bale")
	v3_:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?)#wrapUsage", "Usage of wrap rolls per minute", 0.1)
	v3_:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).railing#width", "Railing width to set")
	v3_:register(XMLValueType.STRING, "vehicle.inlineWrapper.baleTypes.baleType(?).inlineBale#filename", "Path to inline bale xml file")
	v3_:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).size#diameter", "Bale diameter")
	v3_:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).size#width", "Bale width")
	v3_:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).size#height", "Bale height")
	v3_:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.baleTypes.baleType(?).size#length", "Bale length")
	v3_:register(XMLValueType.STRING, "vehicle.inlineWrapper.railings#animation", "Railing animation")
	v3_:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.railings#animStartX", "Railing width at start of animation")
	v3_:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.railings#animEndX", "Railing width at end of animation")
	v3_:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.railings#defaultX", "Default railing width", 1)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.wrapping#startNode", "Reference node for wrapping state of bale")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.steeringNodes.steeringNode(?)#node", "Steering node that is aligned to the start wrapping direction")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.wrappingNodes.wrappingNode(?)#node", "Wrapping node")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.inlineWrapper.wrappingNodes.wrappingNode(?)#target", "Target node that is aligned to the bale")
	v3_:register(XMLValueType.VECTOR_TRANS, "vehicle.inlineWrapper.wrappingNodes.wrappingNode(?)#startTrans", "Start translation")
	v3_:register(XMLValueType.STRING, "vehicle.inlineWrapper.animations#pusher", "Pusher animation", "pusherAnimation")
	v3_:register(XMLValueType.STRING, "vehicle.inlineWrapper.animations#wrapping", "Wrapping animation", "wrappingAnimation")
	v3_:register(XMLValueType.STRING, "vehicle.inlineWrapper.animations#pushOff", "Push bale off animation", "pushOffAnimation")
	v3_:register(XMLValueType.STRING, "vehicle.inlineWrapper.pushing#brakeForce", "Brake force while pushing", 0)
	v3_:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.pushing#openBrakeTime", "Pusher animation time to open brake", 0.1)
	v3_:register(XMLValueType.FLOAT, "vehicle.inlineWrapper.pushing#closeBrakeTime", "Pusher animation time to close brake", 0.5)
	v3_:register(XMLValueType.INT, "vehicle.inlineWrapper.pushing#minBaleAmount", "Min. bales wrapped to open brake", 4)
	v3_:register(XMLValueType.FLOAT, "vehicle.inlineWrapper#baleMovedThreshold", "Bale moved threshold for starting wrapping animation", 0.05)
	v3_:register(XMLValueType.INT, "vehicle.inlineWrapper#numObjectBits", "Num bits for sending bales", 4)
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.inlineWrapper.sounds", "wrap")
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.inlineWrapper.sounds", "start")
	SoundManager.registerSampleXMLPaths(v3_, "vehicle.inlineWrapper.sounds", "stop")
	v3_:setXMLSpecializationType()
end

function InlineWrapper.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "readInlineBales", InlineWrapper.readInlineBales)
	SpecializationUtil.registerFunction(vehicleType, "writeInlineBales", InlineWrapper.writeInlineBales)
	SpecializationUtil.registerFunction(vehicleType, "getIsInlineBalingAllowed", InlineWrapper.getIsInlineBalingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "inlineBaleTriggerCallback", InlineWrapper.inlineBaleTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "inlineWrapTriggerCallback", InlineWrapper.inlineWrapTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "updateWrappingNodes", InlineWrapper.updateWrappingNodes)
	SpecializationUtil.registerFunction(vehicleType, "updateRoundBaleWrappingNode", InlineWrapper.updateRoundBaleWrappingNode)
	SpecializationUtil.registerFunction(vehicleType, "updateSquareBaleWrappingNode", InlineWrapper.updateSquareBaleWrappingNode)
	SpecializationUtil.registerFunction(vehicleType, "getWrapperBaleType", InlineWrapper.getWrapperBaleType)
	SpecializationUtil.registerFunction(vehicleType, "getAllowBalePushing", InlineWrapper.getAllowBalePushing)
	SpecializationUtil.registerFunction(vehicleType, "updateWrapperRailings", InlineWrapper.updateWrapperRailings)
	SpecializationUtil.registerFunction(vehicleType, "updateInlineSteeringWheels", InlineWrapper.updateInlineSteeringWheels)
	SpecializationUtil.registerFunction(vehicleType, "getCanInteract", InlineWrapper.getCanInteract)
	SpecializationUtil.registerFunction(vehicleType, "getCanPushOff", InlineWrapper.getCanPushOff)
	SpecializationUtil.registerFunction(vehicleType, "setCurrentInlineBale", InlineWrapper.setCurrentInlineBale)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentInlineBale", InlineWrapper.getCurrentInlineBale)
	SpecializationUtil.registerFunction(vehicleType, "pushOffInlineBale", InlineWrapper.pushOffInlineBale)
end

function InlineWrapper.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", InlineWrapper.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", InlineWrapper.getIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", InlineWrapper.getBrakeForce)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShowConsumableEmptyWarning", InlineWrapper.getShowConsumableEmptyWarning)
end

function InlineWrapper.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", InlineWrapper)
	SpecializationUtil.registerEventListener(vehicleType, "onConsumableVariationChanged", InlineWrapper)
end

-- Local values: spec, baseKey
function InlineWrapper:onLoad(savegame)
	local v_u_8_ = self.spec_inlineWrapper
	v_u_8_.triggerNode = self.xmlFile:getValue("vehicle.inlineWrapper.baleTrigger#node", nil, self.components, self.i3dMappings)
	if v_u_8_.triggerNode ~= nil then
		addTrigger(v_u_8_.triggerNode, "inlineBaleTriggerCallback", self)
	end
	v_u_8_.wrapTriggerNode = self.xmlFile:getValue("vehicle.inlineWrapper.wrapTrigger#node", nil, self.components, self.i3dMappings)
	if v_u_8_.wrapTriggerNode ~= nil then
		addTrigger(v_u_8_.wrapTriggerNode, "inlineWrapTriggerCallback", self)
	end
	v_u_8_.minFoldTime = self.xmlFile:getValue("vehicle.inlineWrapper.baleTrigger#minFoldTime", 0)
	v_u_8_.maxFoldTime = self.xmlFile:getValue("vehicle.inlineWrapper.baleTrigger#maxFoldTime", 1)
	v_u_8_.wrapColor = { 1, 1, 1 }
	v_u_8_.baleTypes = {}
	self.xmlFile:iterate("vehicle.inlineWrapper.baleTypes.baleType", function(_, p9_)
		-- upvalues: (copy) self, (copy) v_u_8_
		local v10_ = {
			["startNode"] = self.xmlFile:getValue(p9_ .. "#startNode", nil, self.components, self.i3dMappings)
		}
		if v10_.startNode == nil then
			Logging.xmlError(self.xmlFile, "Failed to load bale type. Missing start node! \'%s\'", p9_)
			return
		else
			v10_.railingWidth = self.xmlFile:getValue(p9_ .. ".railing#width")
			v10_.wrapUsage = self.xmlFile:getValue(p9_ .. "#wrapUsage", 0.1) / 60 / 1000
			v10_.inlineBaleFilename = Utils.getFilename(self.xmlFile:getValue(p9_ .. ".inlineBale#filename"), self.baseDirectory)
			if v10_.inlineBaleFilename == nil then
				Logging.xmlError(self.xmlFile, "Failed to load bale type. Missing inline bale filename! \'%s\'", p9_)
			else
				v10_.diameter = MathUtil.round(self.xmlFile:getValue(p9_ .. ".size#diameter", 0), 2)
				v10_.width = MathUtil.round(self.xmlFile:getValue(p9_ .. ".size#width", 0), 2)
				v10_.isRoundBale = v10_.diameter ~= 0
				if not v10_.isRoundBale then
					v10_.height = MathUtil.round(self.xmlFile:getValue(p9_ .. ".size#height", 0), 2)
					v10_.length = MathUtil.round(self.xmlFile:getValue(p9_ .. ".size#length", 0), 2)
				end
				v10_.index = #v_u_8_.baleTypes + 1
				local v11_ = v_u_8_.baleTypes
				table.insert(v11_, v10_)
			end
		end
	end)
	v_u_8_.railingsAnimation = self.xmlFile:getValue("vehicle.inlineWrapper.railings#animation")
	v_u_8_.railingsAnimationStartX = self.xmlFile:getValue("vehicle.inlineWrapper.railings#animStartX")
	v_u_8_.railingsAnimationEndX = self.xmlFile:getValue("vehicle.inlineWrapper.railings#animEndX")
	v_u_8_.railingStartX = self.xmlFile:getValue("vehicle.inlineWrapper.railings#defaultX", 1)
	v_u_8_.currentPosition = v_u_8_.railingStartX + 0.01
	v_u_8_.targetPosition = v_u_8_.railingStartX + 0.01
	v_u_8_.wrappingStartNode = self.xmlFile:getValue("vehicle.inlineWrapper.wrapping#startNode", nil, self.components, self.i3dMappings)
	v_u_8_.steeringNodes = {}
	self.xmlFile:iterate("vehicle.inlineWrapper.steeringNodes.steeringNode", function(_, p12_)
		-- upvalues: (copy) self, (copy) v_u_8_
		local v13_ = {
			["node"] = self.xmlFile:getValue(p12_ .. "#node", nil, self.components, self.i3dMappings)
		}
		if v13_.node ~= nil then
			v13_.startRot = { getRotation(v13_.node) }
			local v14_ = v_u_8_.steeringNodes
			table.insert(v14_, v13_)
		end
	end)
	v_u_8_.wrappingNodes = {}
	self.xmlFile:iterate("vehicle.inlineWrapper.wrappingNodes.wrappingNode", function(_, p15_)
		-- upvalues: (copy) self, (copy) v_u_8_
		local v16_ = {
			["node"] = self.xmlFile:getValue(p15_ .. "#node", nil, self.components, self.i3dMappings),
			["target"] = self.xmlFile:getValue(p15_ .. "#target", nil, self.components, self.i3dMappings)
		}
		if v16_.node ~= nil and v16_.target ~= nil then
			v16_.startTrans = self.xmlFile:getValue(p15_ .. "#startTrans", nil, true) or { getTranslation(v16_.target) }
			setTranslation(v16_.target, v16_.startTrans[1], v16_.startTrans[2], v16_.startTrans[3])
			local v17_ = v_u_8_.wrappingNodes
			table.insert(v17_, v16_)
		end
	end)
	v_u_8_.animations = {}
	v_u_8_.animations.pusher = self.xmlFile:getValue("vehicle.inlineWrapper.animations#pusher", "pusherAnimation")
	v_u_8_.animations.wrapping = self.xmlFile:getValue("vehicle.inlineWrapper.animations#wrapping", "wrappingAnimation")
	v_u_8_.animations.pushOff = self.xmlFile:getValue("vehicle.inlineWrapper.animations#pushOff", "pushOffAnimation")
	v_u_8_.pushingBrakeForce = self.xmlFile:getValue("vehicle.inlineWrapper.pushing#brakeForce", 0)
	v_u_8_.pushingOpenBrakeTime = self.xmlFile:getValue("vehicle.inlineWrapper.pushing#openBrakeTime", 0.1)
	v_u_8_.pushingCloseBrakeTime = self.xmlFile:getValue("vehicle.inlineWrapper.pushing#closeBrakeTime", 0.5)
	v_u_8_.pushingMinBaleAmount = self.xmlFile:getValue("vehicle.inlineWrapper.pushing#minBaleAmount", 4)
	v_u_8_.baleMovedThreshold = self.xmlFile:getValue("vehicle.inlineWrapper#baleMovedThreshold", 0.05)
	v_u_8_.pusherAnimationDirty = false
	v_u_8_.showIncompatibleBalesWarning = false
	v_u_8_.pendingSingleBales = {}
	v_u_8_.pendingIncompatibleBales = {}
	v_u_8_.enteredInlineBales = {}
	v_u_8_.enteredBalesToWrap = {}
	v_u_8_.numObjectBits = self.xmlFile:getValue("vehicle.inlineWrapper#numObjectBits", 4)
	v_u_8_.inlineBalesDirtyFlag = self:getNextDirtyFlag()
	v_u_8_.warningDirtyFlag = self:getNextDirtyFlag()
	v_u_8_.currentLineDirection = nil
	v_u_8_.lineDirection = nil
	v_u_8_.activatable = InlineWrapperActivatable.new(self)
	if self.isClient then
		v_u_8_.samples = {}
		v_u_8_.samples.wrap = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.inlineWrapper.sounds", "wrap", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_8_.samples.start = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.inlineWrapper.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v_u_8_.samples.stop = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.inlineWrapper.sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
end

-- Local values: spec
function InlineWrapper:onPostLoad(savegame)
	local v19_ = self.spec_inlineWrapper
	if v19_.railingsAnimation ~= nil then
		self:setAnimationTime(v19_.railingsAnimation, 1, true)
	end
end

-- Local values: spec, inlineBale
function InlineWrapper:onDelete()
	local v21_ = self.spec_inlineWrapper
	if v21_.triggerNode ~= nil then
		removeTrigger(v21_.triggerNode)
	end
	if v21_.wrapTriggerNode ~= nil then
		removeTrigger(v21_.wrapTriggerNode)
	end
	g_soundManager:deleteSamples(v21_.samples)
	g_currentMission.activatableObjectsSystem:removeActivatable(v21_.activatable)
	local v22_ = self:getCurrentInlineBale()
	if v22_ ~= nil then
		v22_:wakeUp(50)
		v22_:setWrappingState(1)
		v22_:setCurrentWrapperInfo(nil, nil)
		self:setCurrentInlineBale(nil)
	end
end

-- Local values: inlineBale, spec
function InlineWrapper:onReadStream(streamId, connection)
	self:readInlineBales("pendingSingleBales", streamId, connection)
	self:readInlineBales("enteredInlineBales", streamId, connection)
	self:readInlineBales("enteredBalesToWrap", streamId, connection)
	if streamReadBool(streamId) then
		self:setCurrentInlineBale(NetworkUtil.readNodeObjectId(streamId), true)
	else
		self:setCurrentInlineBale(nil, true)
	end
	local v26_ = self.spec_inlineWrapper
	v26_.showIncompatibleBalesWarning = streamReadBool(streamId)
	g_currentMission.activatableObjectsSystem:addActivatable(v26_.activatable)
end

-- Local values: currentInlineBale
function InlineWrapper:onWriteStream(streamId, connection)
	self:writeInlineBales("pendingSingleBales", streamId, connection)
	self:writeInlineBales("enteredInlineBales", streamId, connection)
	self:writeInlineBales("enteredBalesToWrap", streamId, connection)
	local v30_ = self:getCurrentInlineBale()
	if streamWriteBool(streamId, v30_ ~= nil) then
		NetworkUtil.writeNodeObject(streamId, v30_)
	end
	streamWriteBool(streamId, self.spec_inlineWrapper.showIncompatibleBalesWarning)
end

-- Local values: spec, inlineBale
function InlineWrapper:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local v34_ = self.spec_inlineWrapper
		if streamReadBool(streamId) then
			self:readInlineBales("pendingSingleBales", streamId, connection)
			self:readInlineBales("enteredInlineBales", streamId, connection)
			self:readInlineBales("enteredBalesToWrap", streamId, connection)
			if streamReadBool(streamId) then
				self:setCurrentInlineBale(NetworkUtil.readNodeObjectId(streamId), true)
			else
				self:setCurrentInlineBale(nil, true)
			end
			g_currentMission.activatableObjectsSystem:addActivatable(v34_.activatable)
		end
		v34_.showIncompatibleBalesWarning = streamReadBool(streamId)
	end
end

-- Local values: spec, currentInlineBale
function InlineWrapper:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v39_ = self.spec_inlineWrapper
		local v40_ = streamWriteBool
		local v41_ = v39_.inlineBalesDirtyFlag
		if v40_(streamId, bit32.band(dirtyMask, v41_) ~= 0) then
			self:writeInlineBales("pendingSingleBales", streamId, connection)
			self:writeInlineBales("enteredInlineBales", streamId, connection)
			self:writeInlineBales("enteredBalesToWrap", streamId, connection)
			local v42_ = self:getCurrentInlineBale()
			if streamWriteBool(streamId, v42_ ~= nil) then
				NetworkUtil.writeNodeObject(streamId, v42_)
			end
		end
		streamWriteBool(streamId, v39_.showIncompatibleBalesWarning)
	end
end

-- Local values: spec, sum, _, object
function InlineWrapper:readInlineBales(name, streamId, connection)
	local v46_ = self.spec_inlineWrapper
	local v47_ = streamReadUIntN(streamId, v46_.numObjectBits)
	v46_[name] = {}
	for _ = 1, v47_ do
		local v48_ = NetworkUtil.readNodeObjectId(streamId)
		v46_[name][v48_] = v48_
	end
end

-- Local values: spec, num, objectIndex, object, _
function InlineWrapper:writeInlineBales(name, streamId, connection)
	local v52_ = self.spec_inlineWrapper
	local v53_ = table.size(v52_[name])
	streamWriteUIntN(streamId, v53_, v52_.numObjectBits)
	local v54_ = 0
	for v55_, _ in pairs(v52_[name]) do
		v54_ = v54_ + 1
		if v54_ <= v53_ then
			NetworkUtil.writeNodeObjectId(streamId, v55_)
		else
			Logging.xmlWarning(self.xmlFile, "Not enough bits to send all inline objects. Please increase \'%s\'", "vehicle.inlineWrapper#numObjectBits")
		end
	end
end

-- Local values: spec
function InlineWrapper:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self:getIsAnimationPlaying(self.spec_inlineWrapper.animations.wrapping) then
		self:updateWrappingNodes()
	end
end

-- Local values: spec, pendingBaleId, pendingBale, baleType, lastBaleId, lastBale, inlineBale, success, currentInlineBale, total, _, showIncompatibleBalesWarning, inlineBaleId, bale, inlineBale, currentInlineBale, needsSteering, steeringActive, x, _, z, currentInlineBale, allowedToPush, _, baleId, _, baleId, pendingBale, pendingBaleId, baleType, replaced, newBaleId, allowBrakeOpening, animTime, isPushing, currentSpeed, isPushingOff, releaseBrake, playWrapAnimation, wrapBaleType, _, wrapBaleId, wrapBale, x, y, z, baleId, baleType, currentInlineBale, actionEvent
function InlineWrapper:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v59_ = self.spec_inlineWrapper
	if self.isServer then
		local v60_ = next(v59_.pendingSingleBales)
		local v61_ = NetworkUtil.getObject(v60_)
		if v61_ ~= nil and self:getIsInlineBalingAllowed() then
			local v62_ = self:getWrapperBaleType(v61_)
			local v63_ = next(v59_.enteredInlineBales)
			local v64_ = NetworkUtil.getObject(v63_)
			local v65_ = nil
			local v66_ = false
			if v64_ == nil then
				v65_ = InlineBale.new(self.isServer, self.isClient)
				if v65_:loadFromConfigXML(v62_.inlineBaleFilename) then
					v65_:setOwnerFarmId(self:getActiveFarm(), true)
					v65_:setCurrentWrapperInfo(self, v59_.wrappingStartNode)
					v65_:register()
					v66_ = v65_:addBale(v61_, v62_)
				else
					v65_:delete()
				end
			elseif v64_:isa(InlineBaleSingle) then
				v65_ = v64_:getConnectedInlineBale()
				if v65_ ~= nil then
					v66_ = v65_:addBale(v61_, v62_)
					if v66_ then
						self:getCurrentInlineBale():setCurrentWrapperInfo(self, v59_.wrappingStartNode)
					end
				end
			end
			if v66_ then
				v59_.pendingSingleBales[v60_] = nil
				v59_.enteredInlineBales[v60_] = v60_
				v59_.pusherAnimationDirty = true
				self:setCurrentInlineBale(v65_)
				g_currentMission.activatableObjectsSystem:addActivatable(v59_.activatable)
				local v67_, _ = g_farmManager:updateFarmStats(self:getOwnerFarmId(), "wrappedBales", 1)
				if v67_ ~= nil then
					g_achievementManager:tryUnlock("WrappedBales", v67_)
				end
				self:raiseDirtyFlags(v59_.inlineBalesDirtyFlag)
			end
		end
		local v68_ = next(v59_.pendingIncompatibleBales) ~= nil
		if v68_ ~= v59_.showIncompatibleBalesWarning then
			v59_.showIncompatibleBalesWarning = v68_
			self:raiseDirtyFlags(v59_.warningDirtyFlag)
		end
	end
	local v69_ = next(v59_.enteredInlineBales)
	local v70_ = NetworkUtil.getObject(v69_)
	if v70_ == nil then
		self:setCurrentInlineBale(nil)
	elseif self:getCurrentInlineBale() == nil and v70_:isa(InlineBaleSingle) then
		local v71_ = v70_:getConnectedInlineBale()
		if v71_ ~= nil then
			self:setCurrentInlineBale(v71_)
			g_currentMission.activatableObjectsSystem:addActivatable(v59_.activatable)
			self:updateWrappingNodes()
			self:getCurrentInlineBale():setCurrentWrapperInfo(self, v59_.wrappingStartNode)
		end
	end
	local v72_ = next(v59_.enteredInlineBales) ~= nil or v59_.pushOffStarted
	if v72_ then
		v72_ = self:getAttacherVehicle() == nil
	end
	local v73_
	if v72_ then
		v73_ = not self:getIsControlled()
	else
		v73_ = v72_
	end
	if v59_.lineDirection == nil and v72_ then
		local v74_, _, v75_ = localDirectionToWorld(self.components[1].node, 0, 0, -1)
		v59_.lineDirection = { v74_, v75_ }
	elseif v59_.lineDirection ~= nil and not v72_ then
		v59_.lineDirection = nil
	end
	if v73_ then
		v59_.currentLineDirection = v59_.lineDirection
	elseif v59_.currentLineDirection ~= nil then
		v59_.currentLineDirection = nil
		self:updateInlineSteeringWheels()
	end
	if v59_.currentLineDirection ~= nil then
		self:updateInlineSteeringWheels(v59_.currentLineDirection[1], v59_.currentLineDirection[2])
	end
	if self.isServer then
		v59_.releaseBrake = false
		local v76_ = self:getCurrentInlineBale()
		if v59_.pusherAnimationDirty then
			local v77_ = true
			for _, v78_ in pairs(v59_.pendingSingleBales) do
				if not self:getAllowBalePushing(NetworkUtil.getObject(v78_)) then
					v77_ = false
					break
				end
			end
			if v77_ then
				for _, v79_ in pairs(v59_.enteredInlineBales) do
					if not self:getAllowBalePushing(NetworkUtil.getObject(v79_)) then
						v77_ = false
						break
					end
				end
			end
			if v77_ and v76_ ~= nil then
				local v80_ = v76_:getPendingBale()
				local v81_ = NetworkUtil.getObjectId(v80_)
				local v82_, v83_ = v76_:replacePendingBale(self:getWrapperBaleType(v80_).startNode, v59_.wrapColor)
				if v82_ then
					v59_.enteredInlineBales[v81_] = nil
					v59_.enteredInlineBales[v83_] = v83_
				end
				self:playAnimation(v59_.animations.pusher, 1, 0)
				v59_.pusherAnimationDirty = false
				v76_:connectPendingBale()
				self:raiseDirtyFlags(v59_.inlineBalesDirtyFlag)
			end
			self:raiseActive()
		end
		if self:getAttacherVehicle() == nil then
			local v84_ = v76_ == nil or v76_:getNumberOfBales() >= v59_.pushingMinBaleAmount
			local v85_ = self:getAnimationTime(v59_.animations.pusher)
			local v86_ = self:getIsAnimationPlaying(v59_.animations.pusher)
			if v86_ then
				if v59_.pushingOpenBrakeTime < v85_ then
					v86_ = v85_ < v59_.pushingCloseBrakeTime
				else
					v86_ = false
				end
			end
			local v87_ = self:getAnimationSpeed(v59_.animations.pushOff)
			local v88_ = self:getIsAnimationPlaying(v59_.animations.pushOff)
			if v88_ then
				v88_ = v87_ > 0
			end
			local v89_ = v86_ or v88_
			if v84_ then
				v59_.releaseBrake = v89_
			end
		end
	end
	local v90_ = false
	local v91_ = nil
	for _, v92_ in pairs(v59_.enteredBalesToWrap) do
		local v93_ = NetworkUtil.getObject(v92_)
		if v93_ ~= nil and entityExists(v93_.nodeId) then
			local v94_, v95_, v96_ = localToLocal(v93_.nodeId, self.components[1].node, 0, 0, 0)
			if v93_.lastWrapTranslation == nil or v93_.lastWrapMoveTime == nil then
				v93_.lastWrapMoveTime = -math.huge
				v93_.lastWrapTranslation = { v94_, v95_, v96_ }
			else
				local v97_ = v93_.lastWrapTranslation[1] - v94_
				local v98_ = math.abs(v97_)
				local v99_ = v93_.lastWrapTranslation[2] - v95_
				local v100_ = v98_ + math.abs(v99_)
				local v101_ = v93_.lastWrapTranslation[3] - v96_
				if v100_ + math.abs(v101_) > v59_.baleMovedThreshold then
					v93_.lastWrapMoveTime = g_currentMission.time
					v93_.lastWrapTranslation = { v94_, v95_, v96_ }
				end
			end
			if v93_.lastWrapMoveTime + 1500 > g_currentMission.time then
				v91_ = self:getWrapperBaleType(v93_)
				v90_ = true
				break
			end
			self:raiseActive()
		end
	end
	if v90_ then
		if self.isServer and v91_ ~= nil then
			self:updateConsumable(InlineWrapper.CONSUMABLE_TYPE_NAME, -v91_.wrapUsage * dt, true)
		end
		if not self:getIsAnimationPlaying(v59_.animations.wrapping) then
			self:playAnimation(v59_.animations.wrapping, 1, self:getAnimationTime(v59_.animations.wrapping), true)
		end
		if self.isClient and not (g_soundManager:getIsSamplePlaying(v59_.samples.start) or g_soundManager:getIsSamplePlaying(v59_.samples.wrap)) then
			g_soundManager:playSample(v59_.samples.start)
			g_soundManager:playSample(v59_.samples.wrap, 0, v59_.samples.start)
		end
	else
		self:stopAnimation(v59_.animations.wrapping, true)
		if self.isClient and (g_soundManager:getIsSamplePlaying(v59_.samples.start) or g_soundManager:getIsSamplePlaying(v59_.samples.wrap)) then
			g_soundManager:stopSample(v59_.samples.start)
			g_soundManager:stopSample(v59_.samples.wrap)
			g_soundManager:playSample(v59_.samples.stop)
		end
	end
	local v102_ = next(v59_.pendingSingleBales) or next(v59_.enteredInlineBales)
	local v103_ = NetworkUtil.getObject(v102_)
	if v103_ == nil then
		self:updateWrapperRailings(v59_.railingStartX, dt)
	elseif self:getIsInlineBalingAllowed() then
		local v104_ = self:getWrapperBaleType(v103_)
		local v105_ = self:getCurrentInlineBale()
		if v105_ ~= nil and not v105_:getIsBaleAllowed(v103_, v104_) then
			v104_ = nil
		end
		if v104_ ~= nil then
			v59_.targetPosition = v104_.railingWidth
			self:updateWrapperRailings(v59_.targetPosition, dt)
		end
	end
	if self.isServer and (v59_.pushOffStarted ~= nil and (v59_.pushOffStarted and not self:getIsAnimationPlaying(v59_.animations.pushOff))) then
		self:playAnimation(v59_.animations.pushOff, -1, 1)
		v59_.pushOffStarted = nil
	end
	if self.isClient then
		local v106_ = v59_.actionEvents[InputAction.ACTIVATE_OBJECT]
		if v106_ ~= nil then
			g_inputBinding:setActionEventActive(v106_.actionEventId, self:getCanPushOff())
		end
	end
end

-- Local values: spec, foldTime
function InlineWrapper:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local v108_ = self.spec_inlineWrapper
		if next(v108_.pendingSingleBales) ~= nil then
			local v109_ = self:getFoldAnimTime()
			if v109_ < v108_.minFoldTime or v108_.maxFoldTime < v109_ then
				g_currentMission:showBlinkingWarning(self.spec_foldable.unfoldWarning, 500)
			end
		end
		if v108_.showIncompatibleBalesWarning then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_baleNotSupported"), 500)
		end
	end
end

-- Local values: spec, inlineBale, bales, _, wrappingNode, x, y, z, minDistance, minBale, _, baleId, bale, bx, _, bz, x1, y1, z1, x2, y2, z2, distance, targetX, targetY, targetZ, _, wrappingNode
function InlineWrapper:updateWrappingNodes()
	local v111_ = self.spec_inlineWrapper
	local v112_ = self:getCurrentInlineBale()
	if v112_ == nil then
		if v111_.resetWrappingNodes then
			for _, v113_ in ipairs(v111_.wrappingNodes) do
				setTranslation(v113_.target, v113_.startTrans[1], v113_.startTrans[2], v113_.startTrans[3])
			end
			v111_.resetWrappingNodes = nil
		end
	else
		local v114_ = v111_.enteredBalesToWrap
		for _, v115_ in ipairs(v111_.wrappingNodes) do
			local v116_, v117_, v118_ = getWorldTranslation(v115_.node)
			local v119_ = math.huge
			local v120_ = nil
			for _, v121_ in pairs(v114_) do
				local v122_ = NetworkUtil.getObject(v121_)
				if v122_ ~= nil and v122_ ~= v112_:getPendingBale() then
					local v123_, _, v124_ = worldToLocal(v122_.nodeId, v116_, v117_, v118_)
					local v125_ = nil
					local v126_ = nil
					local v127_ = nil
					local v128_ = nil
					local v129_ = nil
					local v130_ = nil
					if v122_.isRoundbale then
						if -v122_.width / 2 <= v124_ then
							v125_, v126_, v127_ = localToWorld(v122_.nodeId, 0, 0, v122_.width / 2)
							v128_, v129_, v130_ = localToWorld(v122_.nodeId, 0, 0, -v122_.width / 2)
						end
					elseif -v122_.width / 2 <= v123_ then
						v125_, v126_, v127_ = localToWorld(v122_.nodeId, v122_.width / 2, 0, 0)
						v128_, v129_, v130_ = localToWorld(v122_.nodeId, -v122_.width / 2, 0, 0)
					end
					if v125_ ~= nil then
						local v131_ = MathUtil.vector3Length(v116_ - v125_, v117_ - v126_, v118_ - v127_)
						local v132_ = MathUtil.vector3Length
						local v133_ = v116_ - v128_
						local v134_ = v117_ - v129_
						local v135_ = v118_ - v130_
						local v136_ = math.min(v131_, v132_(v133_, v134_, v135_))
						if v136_ < v119_ then
							v120_ = v122_
							v119_ = v136_
						end
					end
				end
			end
			if v120_ == nil then
				setTranslation(v115_.target, v115_.startTrans[1], v115_.startTrans[2], v115_.startTrans[3])
			else
				local v137_, v138_, v139_
				if v120_.isRoundbale then
					v137_, v138_, v139_ = self:updateRoundBaleWrappingNode(v120_, v115_.node, v116_, v117_, v118_)
				else
					v137_, v138_, v139_ = self:updateSquareBaleWrappingNode(v120_, v115_.node, v116_, v117_, v118_)
				end
				if v137_ == nil then
					setTranslation(v115_.target, v115_.startTrans[1], v115_.startTrans[2], v115_.startTrans[3])
				else
					local v140_, v141_, v142_ = worldToLocal(getParent(v115_.target), v137_, v138_, v139_)
					setTranslation(v115_.target, v140_, v141_, v142_)
				end
			end
		end
		v111_.resetWrappingNodes = true
	end
end

-- Local values: baleNode, baleRadius, steps, intersectOffset, foilOffset, w1x, w1y, w1z, distanceToCenter, maxDirY, targetX, targetY, targetZ, i, a, c, s, distance, intersect, _, _, _, _, px, py, pz, _, wrapDirY, _
function InlineWrapper:updateRoundBaleWrappingNode(bale, wrappingNode, x, y, z)
	local v148_ = bale.nodeId
	local v149_ = bale.diameter / 2
	local v150_, v151_, v152_ = worldToLocal(v148_, x, y, z)
	local v153_ = MathUtil.vector3Length(v150_, v151_, 0)
	local v154_ = -math.huge
	local v155_ = nil
	local v156_ = nil
	local v157_ = nil
	for v158_ = 1, 32 do
		local v159_ = v158_ / 32 * 2 * 3.141592653589793
		local v160_ = math.cos(v159_) * (v149_ + 0.01)
		local v161_ = math.sin(v159_) * (v149_ + 0.01)
		if MathUtil.vector2Length(v160_ - v150_, v161_ - v151_) < v153_ then
			local v162_, _, _, _, _ = MathUtil.getCircleLineIntersection(0, 0, v149_, v150_, v151_, v160_, v161_)
			if not v162_ then
				local v163_, v164_, v165_ = localToWorld(v148_, v160_, v161_, 0)
				local _, v166_, _ = worldToLocal(wrappingNode, v163_, v164_, v165_)
				if v154_ < v166_ then
					v155_, v156_, v157_ = localToWorld(v148_, math.cos(v159_) * (v149_ + -0.03), math.sin(v159_) * (v149_ + -0.03), v152_)
					v154_ = v166_
				end
			end
		end
	end
	return v155_, v156_, v157_
end

-- Local values: baleNode, minAngle, targetX, targetY, targetZ, height, length, intersectOffset, foilOffset, w1x, w1y, w1z, _, edge, edgeY, edgeZ, intersect, i, i2, px, py, pz, _, wrapDirY, wrapDirZ, angle
function InlineWrapper:updateSquareBaleWrappingNode(bale, wrappingNode, x, y, z)
	local v172_ = bale.nodeId
	local v173_ = math.huge
	local v174_ = nil
	local v175_ = nil
	local v176_ = nil
	local v177_ = bale.height / 2
	local v178_ = bale.length / 2
	local v179_, v180_, v181_ = worldToLocal(v172_, x, y, z)
	if bale.wrappingEdges == nil then
		bale.wrappingEdges = {}
		bale.wrappingEdges[1] = { 0, v177_, -v178_ }
		bale.wrappingEdges[2] = { 0, -v177_, -v178_ }
		bale.wrappingEdges[3] = { 0, -v177_, v178_ }
		bale.wrappingEdges[4] = { 0, v177_, v178_ }
	end
	for _, v182_ in ipairs(bale.wrappingEdges) do
		local v183_ = v182_[2]
		local v184_ = v182_[2]
		local v185_ = v183_ + math.sign(v184_) * 0.01
		local v186_ = v182_[3]
		local v187_ = v182_[3]
		local v188_ = v186_ + math.sign(v187_) * 0.01
		local v189_ = false
		for v190_ = 1, 4 do
			local v191_ = v190_ <= 3 and (v190_ + 1 or 1) or 1
			v189_ = v189_ or MathUtil.getLineBoundingVolumeIntersect(v185_, v188_, v180_, v181_, bale.wrappingEdges[v190_][2], bale.wrappingEdges[v190_][3], bale.wrappingEdges[v191_][2], bale.wrappingEdges[v191_][3])
		end
		if not v189_ then
			local v192_, v193_, v194_ = localToWorld(v172_, v179_, v185_, v188_)
			local _, v195_, v196_ = worldToLocal(wrappingNode, v192_, v193_, v194_)
			local v197_ = MathUtil.getYRotationFromDirection(v195_, v196_)
			if v197_ < 0 then
				v197_ = 3.141592653589793 + (3.141592653589793 + v197_)
			end
			if v197_ < v173_ then
				local v198_ = localToWorld
				local v199_ = v182_[2]
				local v200_ = v182_[2]
				local v201_ = v199_ + math.sign(v200_) * -0.05
				local v202_ = v182_[3]
				local v203_ = v182_[3]
				v174_, v175_, v176_ = v198_(v172_, v179_, v201_, v202_ + math.sign(v203_) * -0.05)
				v173_ = v197_
			end
		end
	end
	return v174_, v175_, v176_
end

-- Local values: spec, _, actionEventId
function InlineWrapper:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v206_ = self.spec_inlineWrapper
		self:clearActionEventsTable(v206_.actionEvents)
		if isActiveForInput then
			local _, v207_ = self:addActionEvent(v206_.actionEvents, InputAction.ACTIVATE_OBJECT, self, InlineWrapper.pushOffInlineBaleEvent, false, false, true, true, nil)
			g_inputBinding:setActionEventTextPriority(v207_, GS_PRIO_HIGH)
			g_inputBinding:setActionEventActive(v207_, self:getCanPushOff())
			g_inputBinding:setActionEventTextVisibility(v207_, true)
			g_inputBinding:setActionEventText(v207_, g_i18n:getText("action_baleloaderUnload"))
		end
	end
end

-- Local values: spec
function InlineWrapper:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local v212_ = self.spec_inlineWrapper
	if next(v212_.enteredInlineBales) == nil then
		return superFunc(self, direction, onAiTurnOn)
	else
		return false
	end
end

-- Local values: spec
function InlineWrapper:getIsActive(superFunc)
	local v215_ = self.spec_inlineWrapper
	return (v215_.releaseBrake or v215_.releaseBrake ~= v215_.releaseBrakeSet) and true or superFunc(self)
end

-- Local values: spec
function InlineWrapper:getBrakeForce(superFunc)
	local v218_ = self.spec_inlineWrapper
	if not v218_.releaseBrake then
		return superFunc(self)
	end
	v218_.releaseBrakeSet = v218_.releaseBrake
	return 0
end

-- Local values: spec, foldTime
function InlineWrapper:getShowConsumableEmptyWarning(superFunc, typeName)
	if typeName ~= InlineWrapper.CONSUMABLE_TYPE_NAME or not superFunc(self, typeName) then
		return superFunc(self, typeName)
	end
	local v222_ = self.spec_inlineWrapper
	if next(v222_.pendingSingleBales) ~= nil then
		local v223_ = self:getFoldAnimTime()
		if v222_.minFoldTime <= v223_ or v223_ <= v222_.maxFoldTime then
			return true
		end
	end
	return false
end

-- Local values: spec, foldTime
function InlineWrapper:getIsInlineBalingAllowed()
	local v225_ = self.spec_inlineWrapper
	local v226_ = self:getFoldAnimTime()
	if v226_ < v225_.minFoldTime or v225_.maxFoldTime < v226_ then
		return false
	elseif self:getIsAnimationPlaying(v225_.animations.pusher) then
		return false
	elseif self:getIsAnimationPlaying(v225_.animations.pushOff) or self:getAnimationTime(v225_.animations.pushOff) > 0 then
		return false
	else
		return self:getConsumableIsAvailable(InlineWrapper.CONSUMABLE_TYPE_NAME)
	end
end

-- Local values: object, objectId, spec, connectedInlineBale, connectedInlineBale, bales, removeFromWrapper, _, bale, baleId
function InlineWrapper:inlineBaleTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self.isServer then
		local v231_ = g_currentMission:getNodeObject(otherActorId)
		if v231_ ~= nil and v231_:isa(Bale) then
			local v232_ = NetworkUtil.getObjectId(v231_)
			local v233_ = self.spec_inlineWrapper
			if onEnter then
				if v231_:isa(InlineBaleSingle) then
					v233_.enteredInlineBales[v232_] = v232_
					local v234_ = v231_:getConnectedInlineBale()
					if v234_ == nil then
						v231_.inlineWrapperToAdd = {
							["wrapper"] = self,
							["wrappingNode"] = v233_.wrappingStartNode
						}
					else
						v234_:setCurrentWrapperInfo(self, v233_.wrappingStartNode)
					end
				elseif self:getWrapperBaleType(v231_) == nil then
					v233_.pendingIncompatibleBales[v232_] = v232_
				else
					v233_.pendingSingleBales[v232_] = v232_
				end
			elseif onLeave then
				v233_.pendingSingleBales[v232_] = nil
				v233_.pendingIncompatibleBales[v232_] = nil
				v233_.enteredInlineBales[v232_] = nil
				if v231_:isa(InlineBaleSingle) then
					local v235_ = v231_:getConnectedInlineBale()
					if v235_ ~= nil then
						local v236_ = v235_:getBales()
						local v237_ = true
						for _, v238_ in ipairs(v236_) do
							local v239_ = NetworkUtil.getObjectId(v238_)
							if v233_.pendingSingleBales[v239_] ~= nil or v233_.enteredInlineBales[v239_] ~= nil then
								v237_ = false
								break
							end
						end
						if v237_ then
							v235_:setCurrentWrapperInfo(nil, nil)
							self:setCurrentInlineBale(nil)
						end
					end
				end
			end
			self:raiseDirtyFlags(v233_.inlineBalesDirtyFlag)
		end
	end
end

-- Local values: object, spec, objectId
function InlineWrapper:inlineWrapTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	if self.isServer then
		local v244_ = g_currentMission:getNodeObject(otherActorId)
		if v244_ ~= nil and v244_:isa(Bale) then
			local v245_ = self.spec_inlineWrapper
			local v246_ = NetworkUtil.getObjectId(v244_)
			if onEnter then
				v245_.enteredBalesToWrap[v246_] = v246_
			elseif onLeave then
				v245_.enteredBalesToWrap[v246_] = nil
			end
			self:raiseActive()
			self:raiseDirtyFlags(v245_.inlineBalesDirtyFlag)
		end
	end
end

-- Local values: spec, _, baleType
function InlineWrapper:getWrapperBaleType(bale)
	local v249_ = self.spec_inlineWrapper
	for _, v250_ in pairs(v249_.baleTypes) do
		if bale:getSupportsWrapping() then
			if bale.isRoundbale then
				if v250_.isRoundBale and (bale.diameter == v250_.diameter and bale.width == v250_.width) then
					return v250_
				end
			elseif not v250_.isRoundBale and (bale.width == v250_.width and (bale.height == v250_.height and bale.length == v250_.length)) then
				return v250_
			end
		end
	end
	return nil
end

function InlineWrapper:getAllowBalePushing(bale)
	return bale.dynamicMountJointIndex == nil
end

-- Local values: spec, dir, animTime
function InlineWrapper:updateWrapperRailings(targetPosition, dt)
	local v255_ = self.spec_inlineWrapper
	if targetPosition ~= v255_.currentPosition then
		local v256_ = targetPosition - v255_.currentPosition
		local v257_ = math.sign(v256_)
		v255_.currentPosition = v255_.currentPosition + 0.0001 * dt * v257_
		if v257_ > 0 then
			local v258_ = v255_.currentPosition
			v255_.currentPosition = math.min(v258_, targetPosition)
		else
			local v259_ = v255_.currentPosition
			v255_.currentPosition = math.max(v259_, targetPosition)
		end
		local v260_ = (v255_.currentPosition - v255_.railingsAnimationStartX) / (v255_.railingsAnimationEndX - v255_.railingsAnimationStartX)
		self:setAnimationTime(v255_.railingsAnimation, v260_, true)
	end
end

-- Local values: spec, _, steeringNode, px, py, pz, targetX, _, targetZ, upX, upY, upZ
function InlineWrapper:updateInlineSteeringWheels(dirX, dirZ)
	local v264_ = self.spec_inlineWrapper
	for _, v265_ in ipairs(v264_.steeringNodes) do
		if dirX == nil or dirZ == nil then
			local v266_ = setRotation
			local v267_ = v265_.node
			local v268_ = v265_.startRot
			v266_(v267_, unpack(v268_))
		else
			local v269_, v270_, v271_ = getWorldTranslation(v265_.node)
			local v272_, _, v273_ = worldToLocal(getParent(v265_.node), v269_ + dirX * 10, v270_, v271_ + dirZ * 10)
			local v274_, _, v275_ = MathUtil.vector3Normalize(v272_, 0, v273_)
			local v276_, v277_, v278_ = localDirectionToWorld(getParent(v265_.node), 0, 1, 0)
			setDirection(v265_.node, v274_, 0, v275_, v276_, v277_, v278_)
		end
		if self.setMovingToolDirty ~= nil then
			self:setMovingToolDirty(v265_.node)
		end
	end
end

function InlineWrapper:onLeaveVehicle()
	self.rotatedTime = 0
end

-- Local values: spec, _, steeringNode
function InlineWrapper:onEnterVehicle()
	local v281_ = self.spec_inlineWrapper
	for _, v282_ in ipairs(v281_.steeringNodes) do
		local v283_ = setRotation
		local v284_ = v282_.node
		local v285_ = v282_.startRot
		v283_(v284_, unpack(v285_))
		if self.setMovingToolDirty ~= nil then
			self:setMovingToolDirty(v282_.node)
		end
	end
end

-- Local values: spec
function InlineWrapper:onConsumableVariationChanged(variationIndex, metaData)
	if metaData.color ~= nil then
		local v288_ = self.spec_inlineWrapper
		v288_.wrapColor[1] = metaData.color[1]
		v288_.wrapColor[2] = metaData.color[2]
		v288_.wrapColor[3] = metaData.color[3]
	end
end

-- Local values: localPlayer, x1, y1, z1, x2, y2, z2, distance
function InlineWrapper:getCanInteract()
	local v290_ = g_localPlayer
	if v290_:getIsInVehicle() then
		return false
	end
	if not g_currentMission.accessHandler:canPlayerAccess(self) then
		return false
	end
	local v291_, v292_, v293_ = v290_:getPosition()
	local v294_, v295_, v296_ = getWorldTranslation(self.components[1].node)
	return MathUtil.vector3Length(v291_ - v294_, v292_ - v295_, v293_ - v296_) < InlineWrapper.INTERACTION_RADIUS
end

-- Local values: spec, currentInlineBale
function InlineWrapper:getCanPushOff()
	local v298_ = self.spec_inlineWrapper
	local v299_ = self:getCurrentInlineBale()
	if v299_ == nil then
		return false
	elseif v299_:getPendingBale() == nil then
		if self:getIsAnimationPlaying(v298_.animations.pusher) then
			return false
		else
			return not self:getIsAnimationPlaying(v298_.animations.pushOff)
		end
	else
		return false
	end
end

-- Local values: spec, newInlineBale
function InlineWrapper:setCurrentInlineBale(inlineBale, isClient)
	local v303_ = self.spec_inlineWrapper
	if self.isServer then
		local v304_ = NetworkUtil.getObjectId(inlineBale)
		if v304_ ~= v303_.currentInlineBale then
			v303_.currentInlineBale = v304_
			self:raiseDirtyFlags(v303_.inlineBalesDirtyFlag)
		end
	end
	if isClient then
		v303_.currentInlineBale = inlineBale
	end
end

function InlineWrapper:getCurrentInlineBale()
	return NetworkUtil.getObject(self.spec_inlineWrapper.currentInlineBale)
end

function InlineWrapper:pushOffInlineBaleEvent(actionName, inputValue, callbackState, isAnalog)
	if inputValue == 1 then
		if g_server ~= nil then
			self:pushOffInlineBale()
			return
		end
		g_client:getServerConnection():sendEvent(InlineWrapperPushOffEvent.new(self))
	end
end

-- Local values: spec
function InlineWrapper:pushOffInlineBale()
	local v309_ = self.spec_inlineWrapper
	if not self:getIsAnimationPlaying(v309_.animations.pushOff) then
		self:playAnimation(v309_.animations.pushOff, 1)
		v309_.pushOffStarted = true
	end
end

-- Local values: rootName, baleSizeAttributes
function InlineWrapper.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, roundBaleWrapper)
	local v_u_312_ = {
		["minDiameter"] = math.huge,
		["maxDiameter"] = -math.huge,
		["minLength"] = math.huge,
		["maxLength"] = -math.huge
	}
	xmlFile:iterate(xmlFile:getRootName() .. ".inlineWrapper.baleTypes.baleType", function(_, p313_)
		-- upvalues: (copy) xmlFile, (copy) roundBaleWrapper, (copy) v_u_312_
		local v314_ = MathUtil.round(xmlFile:getValue(p313_ .. ".size#diameter", 0), 2)
		if roundBaleWrapper and v314_ ~= 0 then
			local v315_ = v_u_312_
			local v316_ = v_u_312_.minDiameter
			v315_.minDiameter = math.min(v316_, v314_)
			local v317_ = v_u_312_
			local v318_ = v_u_312_.maxDiameter
			v317_.maxDiameter = math.max(v318_, v314_)
		end
		local v319_ = MathUtil.round(xmlFile:getValue(p313_ .. ".size#length", 0), 2)
		if not roundBaleWrapper and v319_ ~= 0 then
			local v320_ = v_u_312_
			local v321_ = v_u_312_.minLength
			v320_.minLength = math.min(v321_, v319_)
			local v322_ = v_u_312_
			local v323_ = v_u_312_.maxLength
			v322_.maxLength = math.max(v323_, v319_)
		end
	end)
	if v_u_312_.minDiameter == math.huge and v_u_312_.minLength == math.huge then
		return nil
	else
		return v_u_312_
	end
end

-- Local values: baleSizeAttributes, minValue, maxValue, unit, size
function InlineWrapper.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, roundBaleWrapper)
	local v328_ = roundBaleWrapper and storeItem.specs.inlineWrapperBaleSizeRound or storeItem.specs.inlineWrapperBaleSizeSquare
	if v328_ == nil then
		if returnValues and returnRange then
			return 0, 0, ""
		elseif returnValues then
			return 0, ""
		else
			return ""
		end
	else
		local v329_ = roundBaleWrapper and v328_.minDiameter or v328_.minLength
		local v330_ = roundBaleWrapper and v328_.maxDiameter or v328_.maxLength
		if returnValues == nil or not returnValues then
			local v331_ = g_i18n:getText("unit_cmShort")
			if v330_ == v329_ then
				return string.format("%d%s", v329_ * 100, v331_)
			else
				return string.format("%d%s-%d%s", v329_ * 100, v331_, v330_ * 100, v331_)
			end
		elseif returnRange == true and v330_ ~= v329_ then
			return v329_ * 100, v330_ * 100, g_i18n:getText("unit_cmShort")
		else
			return v329_ * 100, g_i18n:getText("unit_cmShort")
		end
	end
end

function InlineWrapper.loadSpecValueBaleSizeRound(xmlFile, customEnvironment, baseDir)
	return InlineWrapper.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, true)
end

function InlineWrapper.loadSpecValueBaleSizeSquare(xmlFile, customEnvironment, baseDir)
	return InlineWrapper.loadSpecValueBaleSize(xmlFile, customEnvironment, baseDir, false)
end

function InlineWrapper.getSpecValueBaleSizeRound(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.inlineWrapperBaleSizeRound == nil then
		return nil
	else
		return InlineWrapper.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, true)
	end
end

function InlineWrapper.getSpecValueBaleSizeSquare(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.inlineWrapperBaleSizeSquare == nil then
		return nil
	else
		return InlineWrapper.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, false)
	end
end
InlineWrapperActivatable = {}
local v_u_350_ = Class(InlineWrapperActivatable)

-- Upvalues: InlineWrapperActivatable_mt
-- Local values: self
function InlineWrapperActivatable.new(inlineWrapper)
	-- upvalues: (copy) v_u_350_
	local v352_ = v_u_350_
	local v353_ = setmetatable({}, v352_)
	v353_.inlineWrapper = inlineWrapper
	v353_.activateText = g_i18n:getText("action_baleloaderUnload")
	return v353_
end

function InlineWrapperActivatable:getIsActivatable()
	return self.inlineWrapper:getCanInteract() and self.inlineWrapper:getCanPushOff() and true or false
end

function InlineWrapperActivatable:run()
	if g_server == nil then
		g_client:getServerConnection():sendEvent(InlineWrapperPushOffEvent.new(self.inlineWrapper))
	else
		self.inlineWrapper:pushOffInlineBale()
	end
end
