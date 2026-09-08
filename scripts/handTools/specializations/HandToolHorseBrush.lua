HandToolHorseBrush = {}

-- Local values: basePath
function HandToolHorseBrush.registerXMLPaths(xmlSchema)
	xmlSchema:setXMLSpecializationType("HandToolHorseBrush")
	xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.horseBrush#node", "Node of the brush", nil, false)
	SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.horseBrush.sounds", "cleaning")
	xmlSchema:setXMLSpecializationType()
end

function HandToolHorseBrush.registerEventListeners(handToolType)
	SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolHorseBrush)
	SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolHorseBrush)
	SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolHorseBrush)
	SpecializationUtil.registerEventListener(handToolType, "onDraw", HandToolHorseBrush)
	SpecializationUtil.registerEventListener(handToolType, "onHeldStart", HandToolHorseBrush)
	SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolHorseBrush)
	SpecializationUtil.registerEventListener(handToolType, "onRegisterActionEvents", HandToolHorseBrush)
end

function HandToolHorseBrush.prerequisitesPresent(specializations)
	return true
end

-- Local values: spec
function HandToolHorseBrush:onLoad(xmlFile)
	local v5_ = self.spec_horseBrush
	v5_.animalDetectionDistance = 3
	v5_.brushNode = xmlFile:getValue("handTool.horseBrush#node", nil, self.components, self.i3dMappings)
	if v5_.brushNode ~= nil then
		v5_.originalPos = { getTranslation(v5_.brushNode) }
	end
	if self.isClient then
		v5_.samples = {}
		v5_.samples.cleaning = g_soundManager:loadSampleFromXML(xmlFile, "handTool.horseBrush.sounds", "cleaning", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v5_.defaultCrosshair = self:createCrosshairOverlay("gui.crosshairDefault")
		v5_.brushCrosshair = self:createCrosshairOverlay("gui.horseBrush")
	end
	v5_.targetedHusbandryId = nil
	v5_.targetedClusterId = nil
	v5_.dirtyFlag = self:getNextDirtyFlag()
	v5_.cleaningDeltaPerMs = 0.01
	v5_.deltaSum = 0
	v5_.isBrushing = false
	v5_.brushText = g_i18n:getText("action_interactAnimalClean")
end

-- Local values: spec
function HandToolHorseBrush:onDelete()
	local v7_ = self.spec_horseBrush
	g_soundManager:deleteSamples(v7_.samples)
	if v7_.defaultCrosshair ~= nil then
		v7_.defaultCrosshair:delete()
		v7_.defaultCrosshair = nil
	end
	if v7_.brushCrosshair ~= nil then
		v7_.brushCrosshair:delete()
		v7_.brushCrosshair = nil
	end
end

-- Local values: carryingPlayer, spec, targetNode, husbandry, cluster, x, y, z, husbandry, delta, cluster
function HandToolHorseBrush:onUpdate(dt)
	local v10_ = self:getCarryingPlayer()
	if v10_ ~= nil then
		local v11_ = self.spec_horseBrush
		v11_.targetedHusbandryId = nil
		v11_.targetedClusterId = nil
		v11_.targetedHusbandry = nil
		if v10_.isOwner then
			local v12_ = v10_.targeter:getClosestTargetedNodeFromType(HandToolHorseBrush)
			local v13_, v14_ = HandToolHorseBrush.getHusbandryAndClusterFromNode(v10_, v12_)
			v11_.targetedHusbandry = v13_
			if v13_ ~= nil then
				g_inputBinding:setActionEventText(v11_.activateActionEventId, string.format(v11_.brushText, v14_:getName()))
			end
			g_inputBinding:setActionEventActive(v11_.activateActionEventId, v13_ ~= nil)
			if v13_ ~= nil and v11_.isCleaning then
				v11_.targetedHusbandryId = NetworkUtil.getObjectId(v13_)
				v11_.targetedClusterId = v14_.id
				if v11_.brushNode ~= nil then
					local v15_ = v11_.originalPos[1]
					local v16_ = v11_.originalPos[2]
					local v17_ = v11_.originalPos[3]
					local v18_ = g_time * 0.25 * 3.141592653589793
					local v19_ = v15_ + math.sin(v18_) * 0.005
					local v20_ = g_time * 0.25 * 3.141592653589793
					local v21_ = v16_ + math.sin(v20_) * 0.001
					local v22_ = g_time * 0.25 * 3.141592653589793
					local v23_ = v17_ + math.sin(v22_) * 0.05
					setTranslation(v11_.brushNode, v19_, v21_, v23_)
				end
			end
			if v11_.targetedHusbandryId ~= v11_.targetedHusbandryIdSent then
				v11_.targetedHusbandryIdSent = v11_.targetedHusbandryId
				v11_.targetedClusterIdSent = v11_.targetedClusterId
				self:raiseDirtyFlags(v11_.dirtyFlag)
			end
		end
		if self.isClient then
			if v11_.targetedHusbandryId == nil then
				if g_soundManager:getIsSamplePlaying(v11_.samples.cleaning) then
					g_soundManager:stopSample(v11_.samples.cleaning)
				end
			elseif not g_soundManager:getIsSamplePlaying(v11_.samples.cleaning) then
				g_soundManager:playSample(v11_.samples.cleaning)
			end
		end
		if v11_.targetedHusbandryId == nil then
			v11_.deltaSum = 0
		else
			local v24_ = NetworkUtil.getObject(v11_.targetedHusbandryId)
			if v24_ ~= nil then
				v11_.deltaSum = v11_.deltaSum + v11_.cleaningDeltaPerMs * dt
				if v11_.deltaSum > 5 then
					local v25_ = v11_.deltaSum
					local v26_ = math.floor(v25_)
					v11_.deltaSum = v11_.deltaSum - v26_
					if v24_:getClusterById(v11_.targetedClusterId) ~= nil then
						g_client:getServerConnection():sendEvent(AnimalCleanEvent.new(v24_, v11_.targetedClusterId, v26_))
						return
					end
				end
			end
		end
	end
end

-- Local values: spec
function HandToolHorseBrush:onDraw()
	local v28_ = self.spec_horseBrush
	if v28_.treeTypeCrosshair ~= nil then
		v28_.treeTypeCrosshair:render()
	end
	if v28_.targetedHusbandry == nil then
		v28_.defaultCrosshair:render()
	else
		v28_.brushCrosshair:render()
	end
end

-- Local values: spec, _, actionEventId
function HandToolHorseBrush:onRegisterActionEvents()
	if self:getIsActiveForInput(true) then
		local v30_ = self.spec_horseBrush
		local _, v31_ = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL, self, HandToolHorseBrush.onBrushAction, true, true, false, true, nil)
		v30_.activateActionEventId = v31_
		g_inputBinding:setActionEventTextPriority(v31_, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(v31_, "")
		g_inputBinding:setActionEventActive(v31_, false)
	end
end

-- Local values: spec
function HandToolHorseBrush:onBrushAction(_, inputValue)
	self.spec_horseBrush.isCleaning = inputValue > 0
end

-- Local values: spec, targeter
function HandToolHorseBrush:onHeldStart()
	if self:getCarryingPlayer().isOwner then
		local v35_ = self.spec_horseBrush
		self:getCarryingPlayer().targeter:addTargetType(HandToolHorseBrush, CollisionFlag.ANIMAL, 0.5, v35_.animalDetectionDistance)
	end
end

-- Local values: carryingPlayer, spec
function HandToolHorseBrush:onHeldEnd()
	local v37_ = self:getCarryingPlayer()
	if v37_ ~= nil and v37_.isOwner then
		v37_.targeter:removeTargetType(HandToolHorseBrush)
	end
	local v38_ = self.spec_horseBrush
	if v38_.samples ~= nil then
		g_soundManager:stopSample(v38_.samples.cleaning)
	end
end

-- Local values: husbandryId, animalId, mission, clusterHusbandry, husbandry, cluster
function HandToolHorseBrush.getHusbandryAndClusterFromNode(carryingPlayer, node)
	if node == nil or not entityExists(node) then
		return nil, nil
	end
	local v41_, v42_ = getAnimalFromCollisionNode(node)
	if v41_ ~= nil and v41_ ~= 0 then
		local v43_ = g_currentMission
		local v44_ = v43_.husbandrySystem:getClusterHusbandryById(v41_)
		if v44_ ~= nil then
			local v45_ = v44_:getPlaceable()
			local v46_ = v44_:getClusterByAnimalId(v42_)
			if v46_ ~= nil and (v43_.accessHandler:canFarmAccess(carryingPlayer.farmId, v45_) and (v46_.changeDirt ~= nil and v46_.getName ~= nil)) then
				return v45_, v46_
			end
		end
	end
	return nil, nil
end
