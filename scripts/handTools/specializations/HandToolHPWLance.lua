HandToolHPWLance = {}

function HandToolHPWLance.registerXMLPaths(xmlSchema)
	xmlSchema:setXMLSpecializationType("HandToolHPWLance")
	xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.highPressureWasherLance.lance#raycastNode", "The range in metres that the lance can wash things", nil, false)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.highPressureWasherLance.lance#washDistance", "The range in metres that the lance can wash things", "10 metres", false)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.highPressureWasherLance.lance#washMultiplier", "The multiplier applied to the wash amount", "1x", false)
	xmlSchema:register(XMLValueType.FLOAT, "handTool.highPressureWasherLance.lance#pricePerMinute", "The cost of using this tool for a minute", "10", false)
	EffectManager.registerEffectXMLPaths(xmlSchema, "handTool.highPressureWasherLance.effects")
	SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.highPressureWasherLance.sounds", "washing")
end

function HandToolHPWLance.registerFunctions(handToolType)
	SpecializationUtil.registerFunction(handToolType, "onWashAction", HandToolHPWLance.onWashAction)
	SpecializationUtil.registerFunction(handToolType, "setIsActivated", HandToolHPWLance.setIsActivated)
	SpecializationUtil.registerFunction(handToolType, "onLanceCallback", HandToolHPWLance.onLanceCallback)
end

function HandToolHPWLance.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeDropped", HandToolHPWLance.getCanBeDropped)
end

function HandToolHPWLance.registerEventListeners(handToolType)
	SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolHPWLance)
	SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolHPWLance)
	SpecializationUtil.registerEventListener(handToolType, "onWriteUpdateStream", HandToolHPWLance)
	SpecializationUtil.registerEventListener(handToolType, "onReadUpdateStream", HandToolHPWLance)
	SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolHPWLance)
	SpecializationUtil.registerEventListener(handToolType, "onRegisterActionEvents", HandToolHPWLance)
	SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolHPWLance)
	SpecializationUtil.registerEventListener(handToolType, "onDebugDraw", HandToolHPWLance)
end

function HandToolHPWLance.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(HandToolTethered, specializations)
end

-- Local values: spec
function HandToolHPWLance:onLoad(xmlFile, baseDirectory)
	local v9_ = self.spec_highPressureWasherLance
	v9_.raycastNode = xmlFile:getValue("handTool.highPressureWasherLance.lance#raycastNode", nil, self.components, self.i3dMappings)
	v9_.washDistance = xmlFile:getValue("handTool.highPressureWasherLance.lance#washDistance", 10)
	v9_.washMultiplier = xmlFile:getValue("handTool.highPressureWasherLance.lance#washMultiplier", 1)
	v9_.pricePerSecond = xmlFile:getValue("handTool.highPressureWasherLance.lance#pricePerMinute", 10) / 60
	if self.isClient then
		v9_.effects = g_effectManager:loadEffect(xmlFile, "handTool.highPressureWasherLance.effects", self.components, self, self.i3dMappings)
		g_effectManager:setEffectTypeInfo(v9_.effects, FillType.WATER)
		v9_.washingSample = g_soundManager:loadSampleFromXML(xmlFile, "handTool.highPressureWasherLance.sounds", "washing", baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v9_.isActivated = false
	v9_.targetedVehicleId = nil
	v9_.activateActionEventId = nil
	v9_.isActivatedSent = false
	v9_.targetedVehicleIdSent = nil
	v9_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec
function HandToolHPWLance:onDelete()
	local v11_ = self.spec_highPressureWasherLance
	g_effectManager:deleteEffects(v11_.effects)
	g_soundManager:deleteSample(v11_.washingSample)
end

-- Local values: spec
function HandToolHPWLance:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v15_ = self.spec_highPressureWasherLance
	if streamWriteBool(streamId, v15_.isActivatedSent) and connection:getIsServer() and streamWriteBool(streamId, v15_.targetedVehicleIdSent ~= nil) then
		NetworkUtil.writeNodeObjectId(streamId, v15_.targetedVehicleIdSent)
	end
end

-- Local values: spec, isActivated, targetedVehicleId, carryingPlayer
function HandToolHPWLance:onReadUpdateStream(streamId, timestamp, connection)
	local v19_ = self.spec_highPressureWasherLance
	local v20_ = streamReadBool(streamId)
	v19_.targetedVehicleId = nil
	if v20_ and (not connection:getIsServer() and streamReadBool(streamId)) then
		local v21_ = NetworkUtil.readNodeObjectId(streamId)
		if not self:getCarryingPlayer().isOwner then
			v19_.targetedVehicleId = v21_
		end
	end
	self:setIsActivated(v20_)
end

-- Local values: carryingPlayer, spec, x, y, z, dirX, dirY, dirZ, vehicle, vehicle, farmId, price, mission
function HandToolHPWLance:onUpdate(dt)
	local v24_ = self:getCarryingPlayer()
	if v24_ == nil then
		return
	else
		local v25_ = self.spec_highPressureWasherLance
		if v25_.isActivated then
			if v24_.isOwner then
				local v26_, v27_, v28_ = getWorldTranslation(v25_.raycastNode)
				local v29_, v30_, v31_ = localDirectionToWorld(v25_.raycastNode, 0, 0, 1)
				raycastAllAsync(v26_, v27_, v28_, v29_, v30_, v31_, v25_.washDistance, "onLanceCallback", self, CollisionFlag.VEHICLE)
				if v25_.targetedVehicleId ~= v25_.targetedVehicleIdSent then
					v25_.targetedVehicleIdSent = v25_.targetedVehicleId
					self:raiseDirtyFlags(v25_.dirtyFlag)
				end
				if v25_.targetedVehicleId == nil then
					g_inputBinding:setActionEventText(v25_.activateActionEventId, string.format(self.activateText, ""))
				else
					local v32_ = NetworkUtil.getObject(v25_.targetedVehicleId)
					g_inputBinding:setActionEventText(v25_.activateActionEventId, string.format(self.activateText, v32_.typeDesc))
				end
			end
			if self.isServer then
				if v25_.targetedVehicleId ~= nil then
					local v33_ = NetworkUtil.getObject(v25_.targetedVehicleId)
					if v33_ ~= nil then
						v33_:cleanVehicle(v25_.washMultiplier * dt / v33_:getWashDuration())
					end
				end
				local v34_ = v24_.farmId
				local v35_ = v25_.pricePerSecond * dt * 0.001
				g_farmManager:updateFarmStats(v34_, "expenses", v35_)
				g_currentMission:addMoney(-v35_, v34_, MoneyType.VEHICLE_RUNNING_COSTS)
			end
		else
			v25_.targetedVehicleId = nil
		end
	end
end

-- Local values: spec, vehicle, continueReporting
function HandToolHPWLance:onLanceCallback(nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	local v39_ = self.spec_highPressureWasherLance
	v39_.targetedVehicleId = nil
	if nodeId == 0 then
		return false
	end
	if not CollisionFlag.getHasMaskFlagSet(shapeId, CollisionFlag.VEHICLE) then
		return true
	end
	local v40_ = g_currentMission.vehicleSystem:getVehicleByNodeId(nodeId, shapeId)
	if v40_ == nil or (v40_.getAllowsWashingByType == nil or not v40_:getAllowsWashingByType(Washable.WASHTYPE_HIGH_PRESSURE_WASHER)) then
		return true
	end
	v39_.targetedVehicleId = NetworkUtil.getObjectId(v40_)
	return false
end

-- Local values: spec, carryingPlayer
function HandToolHPWLance:setIsActivated(isActivated)
	local v43_ = self.spec_highPressureWasherLance
	if v43_.isActivated == isActivated then
		return
	else
		local v44_ = self:getCarryingPlayer()
		if v44_ == nil then
			return
		else
			v43_.isActivated = isActivated
			if v44_.isOwner then
				v43_.isActivatedSent = isActivated
				self:raiseDirtyFlags(v43_.dirtyFlag)
			end
			if v43_.isActivated then
				g_effectManager:startEffects(v43_.effects)
				g_soundManager:playSample(v43_.washingSample)
			else
				g_effectManager:stopEffects(v43_.effects)
				g_soundManager:stopSample(v43_.washingSample)
			end
		end
	end
end

-- Local values: spec, _, actionEventId
function HandToolHPWLance:onRegisterActionEvents()
	if self:getIsActiveForInput(true) then
		local v46_ = self.spec_highPressureWasherLance
		local _, v47_ = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL, self, HandToolHPWLance.onWashAction, false, false, true, true, nil)
		v46_.activateActionEventId = v47_
		g_inputBinding:setActionEventTextPriority(v47_, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(v47_, string.format(self.activateText, ""))
	end
end

function HandToolHPWLance:onWashAction(_, inputValue)
	self:setIsActivated(inputValue > 0)
end

function HandToolHPWLance:getCanBeDropped(superFunc)
	return false
end

function HandToolHPWLance:onHeldEnd()
	self:setIsActivated(false)
	self:returnToHolder(true)
end

-- Local values: spec, vehicle
function HandToolHPWLance:onDebugDraw(x, y, textSize)
	local v55_ = self.spec_highPressureWasherLance
	local v56_ = DebugUtil.renderTextLine
	local v57_ = string.format
	local v58_ = v55_.isActivated
	local v59_ = v56_(x, y, textSize, v57_("isActivated: %s", (tostring(v58_))))
	if v55_.targetedVehicleId ~= nil then
		local v60_ = NetworkUtil.getObject(v55_.targetedVehicleId)
		if v60_ ~= nil then
			v59_ = DebugUtil.renderTextLine(x, v59_, textSize, string.format("Target: %q", v60_.typeName))
		end
	end
	return v59_
end
