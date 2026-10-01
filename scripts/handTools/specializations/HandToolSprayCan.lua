HandToolSprayCan = {}
source("dataS/scripts/handTools/events/SprayCanEvent.lua")
function HandToolSprayCan.registerXMLPaths(xmlSchema)
	xmlSchema:setXMLSpecializationType("HandToolSprayCan")
	xmlSchema:register(XMLValueType.NODE_INDEX, "handTool.sprayCan#shakeNode", "Shake node")
	xmlSchema:register(XMLValueType.STRING, "handTool.sprayCan#colorMaterialSlotName", "Material slot name that should be colored")
	xmlSchema:register(XMLValueType.VECTOR_4, "handTool.sprayCan#color", "Color of the paint")
	xmlSchema:register(XMLValueType.FLOAT, "handTool.sprayCan#distance", "Spray distance")
	xmlSchema:register(XMLValueType.FLOAT, "handTool.sprayCan#delay", "Spray delay in seconds")
	xmlSchema:register(XMLValueType.INT, "handTool.sprayCan#totalNumMarkers", "Total number of markers")
	SoundManager.registerSampleXMLPaths(xmlSchema, "handTool.sprayCan.sounds", "spraying")
	EffectManager.registerEffectXMLPaths(xmlSchema, "handTool.sprayCan.effects")
	xmlSchema:setXMLSpecializationType()
end
function HandToolSprayCan.registerSavegameXMLPaths(savegameXMLSchema, baseKey)
	savegameXMLSchema:register(XMLValueType.INT, baseKey .. ".sprayCan#remainingNumMarkers", "Remaining number of markers")
end
function HandToolSprayCan.registerFunctions(handToolType)
	SpecializationUtil.registerFunction(handToolType, "tryToAddTreeMarker", HandToolSprayCan.tryToAddTreeMarker)
	SpecializationUtil.registerFunction(handToolType, "processDelayedMarker", HandToolSprayCan.processDelayedMarker)
	SpecializationUtil.registerFunction(handToolType, "setIsSpraying", HandToolSprayCan.setIsSpraying)
	SpecializationUtil.registerFunction(handToolType, "changeTreeMarkerType", HandToolSprayCan.changeTreeMarkerType)
	SpecializationUtil.registerFunction(handToolType, "getIsSprayingAllowed", HandToolSprayCan.getIsSprayingAllowed)
	SpecializationUtil.registerFunction(handToolType, "activateSpraying", HandToolSprayCan.activateSpraying)
end
function HandToolSprayCan.registerEventListeners(handToolType)
	SpecializationUtil.registerEventListener(handToolType, "onLoad", HandToolSprayCan)
	SpecializationUtil.registerEventListener(handToolType, "onPostLoad", HandToolSprayCan)
	SpecializationUtil.registerEventListener(handToolType, "onDelete", HandToolSprayCan)
	SpecializationUtil.registerEventListener(handToolType, "onUpdate", HandToolSprayCan)
	SpecializationUtil.registerEventListener(handToolType, "onDraw", HandToolSprayCan)
	SpecializationUtil.registerEventListener(handToolType, "onWriteStream", HandToolSprayCan)
	SpecializationUtil.registerEventListener(handToolType, "onReadStream", HandToolSprayCan)
	SpecializationUtil.registerEventListener(handToolType, "onWriteUpdateStream", HandToolSprayCan)
	SpecializationUtil.registerEventListener(handToolType, "onReadUpdateStream", HandToolSprayCan)
	SpecializationUtil.registerEventListener(handToolType, "onRegisterActionEvents", HandToolSprayCan)
	SpecializationUtil.registerEventListener(handToolType, "onHeldStart", HandToolSprayCan)
	SpecializationUtil.registerEventListener(handToolType, "onHeldEnd", HandToolSprayCan)
end
function HandToolSprayCan.prerequisitesPresent(specializations)
	return true
end
function HandToolSprayCan:onLoad(xmlFile)
	local spec = self.spec_sprayCan
	spec.maxTotalNumMarkers = 255
	spec.totalNumMarkers = xmlFile:getValue("handTool.sprayCan#totalNumMarkers", 50)
	if spec.maxTotalNumMarkers < spec.totalNumMarkers or spec.totalNumMarkers < 1 then
		spec.totalNumMarkers = spec.maxTotalNumMarkers
		Logging.xmlWarning(xmlFile, "Invalid totalNumMarkers value. Valid range is 1-%d", spec.maxTotalNumMarkers)
	end
	spec.remainingNumMarkers = spec.totalNumMarkers
	local color = xmlFile:getValue("handTool.sprayCan#color", { 1, 1, 1, 1 }, true)
	spec.sprayColor = color
	spec.sprayDetectionDistance = xmlFile:getValue("handTool.sprayCan#distance", 1.5)
	spec.sprayDelay = xmlFile:getValue("handTool.sprayCan#delay", 0) * 1000
	spec.sprayDuration = 500
	spec.sprayStopTime = 0
	local colorMaterialSlotName = xmlFile:getValue("handTool.sprayCan#colorMaterialSlotName")
	if colorMaterialSlotName ~= nil then
		I3DUtil.setMaterialSlotShaderParameterRec(self.rootNode, colorMaterialSlotName, "colorScale", color[1], color[2], color[3], color[4])
	end
	local shakeNode = xmlFile:getValue("handTool.sprayCan#shakeNode", self.rootNode, self.components, self.i3dMappings)
	spec.canNode = shakeNode
	spec.originalPos = { getTranslation(shakeNode) }
	if self.isClient then
		spec.effects = g_effectManager:loadEffect(xmlFile, "handTool.sprayCan.effects", self.components, self, self.i3dMappings)
		g_effectManager:setEffectTypeInfo(spec.effects, FillType.WATER)
		for _, effect in ipairs(spec.effects) do
			if effect.setColor == nil then
				continue
			end
			effect:setColor(color[1], color[2], color[3], color[4])
		end
	end
	spec.sprayingSample = g_soundManager:loadSampleFromXML(xmlFile, "handTool.sprayCan.sounds", "spraying", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	spec.foundTreeShape = nil
	spec.foundTreeHitPosition = { 0, 0, 0 }
	spec.treeMarkerTypeIndex = 1
	if g_iconGenerator == nil then
		local mission = g_currentMission
		local treeMarkerSystem = mission.treeMarkerSystem
		spec.treeMarkerType = treeMarkerSystem:getTreeMarkerTypeByIndex(spec.treeMarkerTypeIndex)
		if spec.treeMarkerType == nil then
			spec.treeMarkerTypeIndex = 1
			spec.treeMarkerType = treeMarkerSystem:getTreeMarkerTypeByIndex(spec.treeMarkerTypeIndex)
		end
	end
	spec.treeCrosshair = self:createCrosshairOverlayFromFile("data/shared/treeMarker/markerTree_icon.png", HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS * 2)
	if spec.treeMarkerType ~= nil then
		spec.treeTypeCrosshair = self:createCrosshairOverlayFromFile(spec.treeMarkerType.iconFilename, HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS * 2)
	end
	spec.wasActivatePressed = false
	spec.isSpraying = false
	spec.numShakes = 3
	spec.shakeDuration = 200
	spec.shakeEndTime = 0
	spec.delayedMarker = nil
	spec.dirtyFlag = self:getNextDirtyFlag()
	return true
end
function HandToolSprayCan:onPostLoad(savegame)
	if savegame ~= nil then
		local key = savegame.key .. ".sprayCan"
		if savegame.xmlFile:hasProperty(key) then
			local spec = self.spec_sprayCan
			spec.remainingNumMarkers = math.clamp(savegame.xmlFile:getValue(key .. "#remainingNumMarkers", spec.remainingNumMarkers), 1, spec.maxTotalNumMarkers)
		end
	end
end
function HandToolSprayCan:onDelete()
	local spec = self.spec_sprayCan
	self:processDelayedMarker()
	if spec.effects ~= nil then
		g_effectManager:deleteEffects(spec.effects)
	end
	if spec.sprayingSample ~= nil then
		g_soundManager:deleteSample(spec.sprayingSample)
	end
	if spec.treeCrosshair ~= nil then
		spec.treeCrosshair:delete()
		spec.treeCrosshair = nil
	end
	if spec.treeTypeCrosshair ~= nil then
		spec.treeTypeCrosshair:delete()
		spec.treeTypeCrosshair = nil
	end
end
function HandToolSprayCan:onWriteStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_sprayCan
		streamWriteUInt8(streamId, spec.remainingNumMarkers)
	end
end
function HandToolSprayCan:onReadStream(streamId, connection, carryingPlayer)
	if connection:getIsServer() then
		local spec = self.spec_sprayCan
		spec.remainingNumMarkers = streamReadUInt8(streamId)
	end
end
function HandToolSprayCan:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_sprayCan
		if streamWriteBool(streamId, bit32.band(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteUInt8(streamId, spec.remainingNumMarkers)
		end
	end
end
function HandToolSprayCan:onReadUpdateStream(streamId, timestamp, connection, carryingPlayer)
	if connection:getIsServer() and streamReadBool(streamId) then
		local spec = self.spec_sprayCan
		spec.remainingNumMarkers = streamReadUInt8(streamId)
	end
end
function HandToolSprayCan:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_sprayCan
	xmlFile:setValue(key .. "#remainingNumMarkers", spec.remainingNumMarkers)
end
function HandToolSprayCan:onUpdate(dt)
	local spec = self.spec_sprayCan
	local player = self:getCarryingPlayer()
	local allowInput = player ~= nil and player.isOwner or false
	if allowInput then
		local targetTree = player.targeter.closestTargetsByKey[HandToolSprayCan]
		spec.foundTargetTree = targetTree
		if spec.activatePressed and (not spec.wasActivatePressed and not spec.isSpraying) then
			local mission = g_currentMission
			if 0 < spec.remainingNumMarkers then
				local x, y, z, _, _, _ = player:getLookRay()
				local treeMarkerTypeIndex = spec.treeMarkerTypeIndex
				local shape = nil
				local hitX = nil
				local hitY = nil
				local hitZ = nil
				if targetTree ~= nil then
					shape = targetTree.node
					hitX = targetTree.x
					hitY = targetTree.y
					hitZ = targetTree.z
				end
				if self:getIsSprayingAllowed(shape) then
					g_client:getServerConnection():sendEvent(SprayCanEvent.new(self, treeMarkerTypeIndex, shape, x, y, z, hitX, hitY, hitZ))
				else
					mission:showBlinkingWarning(g_i18n:getText("warning_youAreNotAllowedToMarkThisTree", self.customEnvironment), 2000)
				end
			else
				mission:showBlinkingWarning(g_i18n:getText("warning_sprayCanIsEmpty", self.customEnvironment), 2000)
			end
			spec.wasActivatePressed = true
		end
	end
	if spec.delayedMarker ~= nil and spec.delayedMarker.time <= g_time then
		self:processDelayedMarker()
	end
	if spec.isSpraying then
		if allowInput then
			local x = spec.originalPos[1]
			local y = spec.originalPos[2]
			local z = spec.originalPos[3]
			local timeLeft = math.max(0, spec.shakeEndTime - g_time)
			local factor = 1 - timeLeft / spec.shakeDuration
			local animValue = MathUtil.lerp(0, spec.numShakes, factor)
			x = x + math.sin(animValue * 3.141592653589793) * 0.01
			y = y + math.sin(animValue * 3.141592653589793) * 0.05
			z = z + math.sin(animValue * 3.141592653589793) * 0.01
			setTranslation(spec.canNode, x, y, z)
		end
		if spec.sprayStopTime < g_time then
			self:setIsSpraying(false, false)
		end
	end
	if not spec.activatePressed then
		spec.wasActivatePressed = false
	end
	spec.activatePressed = false
end
function HandToolSprayCan:onDraw()
	local spec = self.spec_sprayCan
	if spec.treeMarkerType == nil then
		return
	end
	if spec.remainingNumMarkers == 0 then
		return
	end
	if spec.treeTypeCrosshair ~= nil then
		spec.treeTypeCrosshair:render()
	end
	if spec.foundTargetTree ~= nil then
		spec.treeCrosshair:render()
	end
end
function HandToolSprayCan:onHeldStart()
	if not self:getCarryingPlayer().isOwner then
		return
	else
		local spec = self.spec_sprayCan
		local targeter = self:getCarryingPlayer().targeter
		targeter:addTargetType(HandToolSprayCan, CollisionFlag.TREE, 0.5, spec.sprayDetectionDistance)
		targeter:addFilterToTargetType(HandToolSprayCan, function(hitNode, x, y, z)
			return getHasClassId(hitNode, ClassIds.MESH_SPLIT_SHAPE)
		end)
	end
end
function HandToolSprayCan:onHeldEnd()
	local spec = self.spec_sprayCan
	local mission = g_currentMission
	local carryingPlayer = self:getCarryingPlayer()
	if carryingPlayer ~= nil and carryingPlayer.isOwner then
		carryingPlayer.targeter:removeTargetType(HandToolSprayCan)
		if spec.remainingNumMarkers <= 0 then
			mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("ingameNotification_deletedEmptySprayCan"))
		end
	end
	self:setIsSpraying(false, true)
	spec.wasActivatePressed = false
	spec.delayedMarker = nil
	if spec.remainingNumMarkers <= 0 and self.isServer then
		mission.handToolSystem:markHandToolForDeletion(self)
	end
end
function HandToolSprayCan:onRegisterActionEvents()
	if not self:getIsActiveForInput(true) then
		return
	else
		local _, actionEventId = self:addActionEvent(InputAction.SPRAYCAN_CHANGE_MARKER, self, self.changeTreeMarkerType, false, true, false, true, nil)
		g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_changeTreeMarkerType"))
		_, actionEventId = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL, self, self.activateSpraying, true, true, true, true, nil)
		g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(actionEventId, g_i18n:getText("action_sprayTreeMarker"))
	end
end
function HandToolSprayCan:activateSpraying(_, inputValue)
	local spec = self.spec_sprayCan
	spec.activatePressed = inputValue ~= 0
end
function HandToolSprayCan:tryToAddTreeMarker(treeMarkerTypeIndex, splitShapeId, x, y, z, hitX, hitY, hitZ)
	local spec = self.spec_sprayCan
	self:setIsSpraying(true, false)
	spec.sprayStopTime = g_time + spec.sprayDuration
	spec.remainingNumMarkers = spec.remainingNumMarkers - 1
	if self.isServer then
		self:raiseDirtyFlags(spec.dirtyFlag)
	end
	if splitShapeId ~= nil and self:getIsSprayingAllowed(splitShapeId) then
		spec.delayedMarker = { splitShapeId = splitShapeId, treeMarkerTypeIndex = treeMarkerTypeIndex, hitX = hitX, hitY = hitY, hitZ = hitZ, x = x, y = y, z = z, time = g_time + spec.sprayDelay }
	end
end
function HandToolSprayCan:processDelayedMarker()
	local spec = self.spec_sprayCan
	if spec.delayedMarker ~= nil then
		local splitShapeId = spec.delayedMarker.splitShapeId
		local treeMarkerTypeIndex = spec.delayedMarker.treeMarkerTypeIndex
		local x = spec.delayedMarker.x
		local y = spec.delayedMarker.y
		local z = spec.delayedMarker.z
		local hitX = spec.delayedMarker.hitX
		local hitY = spec.delayedMarker.hitY
		local hitZ = spec.delayedMarker.hitZ
		if entityExists(splitShapeId) then
			local r = spec.sprayColor[1]
			local g = spec.sprayColor[2]
			local b = spec.sprayColor[3]
			local a = spec.sprayColor[4]
			local mission = g_currentMission
			local treeMarkerSystem = mission.treeMarkerSystem
			treeMarkerSystem:addTreeMarkerCameraBased(splitShapeId, treeMarkerTypeIndex, r, g, b, a, x, y, z, hitX, hitY, hitZ, true)
		end
		spec.delayedMarker = nil
	end
end
function HandToolSprayCan:setIsSpraying(isSpraying, force)
	local spec = self.spec_sprayCan
	if spec.isSpraying ~= isSpraying then
		if isSpraying then
			if self:getIsHeld() then
				g_effectManager:startEffects(spec.effects)
				g_soundManager:playSample(spec.sprayingSample)
				spec.shakeEndTime = g_time + spec.shakeDuration
				spec.isSpraying = true
			end
		else
			if force then
				g_effectManager:resetEffects(spec.effects)
			end
			g_effectManager:stopEffects(spec.effects)
			g_soundManager:stopSample(spec.sprayingSample)
			spec.sprayStopTime = 0
			spec.isSpraying = false
		end
	end
end
function HandToolSprayCan:changeTreeMarkerType(_, inputValue)
	local spec = self.spec_sprayCan
	local mission = g_currentMission
	local treeMarkerSystem = mission.treeMarkerSystem
	spec.treeMarkerTypeIndex = spec.treeMarkerTypeIndex + 1
	if treeMarkerSystem:getNumOfTreeMarkerTypes() < spec.treeMarkerTypeIndex then
		spec.treeMarkerTypeIndex = 1
	end
	spec.treeMarkerType = treeMarkerSystem:getTreeMarkerTypeByIndex(spec.treeMarkerTypeIndex)
	if spec.treeTypeCrosshair ~= nil then
		spec.treeTypeCrosshair:delete()
	end
	spec.treeTypeCrosshair = self:createCrosshairOverlayFromFile(spec.treeMarkerType.iconFilename, HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS * 2)
end
function HandToolSprayCan:getIsSprayingAllowed(shape)
	if shape == nil or shape == 0 then
		return true
	end
	local x, _, z = getWorldTranslation(shape)
	local mission = g_currentMission
	if mission.accessHandler:canFarmAccessLand(g_localPlayer.farmId, x, z) then
		return true
	else
		return false
	end
end
