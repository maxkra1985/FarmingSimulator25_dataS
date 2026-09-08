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

-- Local values: spec, color, colorMaterialSlotName, shakeNode, _, effect, mission, treeMarkerSystem
function HandToolSprayCan:onLoad(xmlFile)
	local v8_ = self.spec_sprayCan
	v8_.maxTotalNumMarkers = 255
	v8_.totalNumMarkers = xmlFile:getValue("handTool.sprayCan#totalNumMarkers", 50)
	if v8_.totalNumMarkers > v8_.maxTotalNumMarkers or v8_.totalNumMarkers < 1 then
		v8_.totalNumMarkers = v8_.maxTotalNumMarkers
		Logging.xmlWarning(xmlFile, "Invalid totalNumMarkers value. Valid range is 1-%d", v8_.maxTotalNumMarkers)
	end
	v8_.remainingNumMarkers = v8_.totalNumMarkers
	local v9_ = xmlFile:getValue("handTool.sprayCan#color", {
		1,
		1,
		1,
		1
	}, true)
	v8_.sprayColor = v9_
	v8_.sprayDetectionDistance = xmlFile:getValue("handTool.sprayCan#distance", 1.5)
	v8_.sprayDelay = xmlFile:getValue("handTool.sprayCan#delay", 0) * 1000
	v8_.sprayDuration = 500
	v8_.sprayStopTime = 0
	local v10_ = xmlFile:getValue("handTool.sprayCan#colorMaterialSlotName")
	if v10_ ~= nil then
		I3DUtil.setMaterialSlotShaderParameterRec(self.rootNode, v10_, "colorScale", v9_[1], v9_[2], v9_[3], v9_[4])
	end
	local v11_ = xmlFile:getValue("handTool.sprayCan#shakeNode", self.rootNode, self.components, self.i3dMappings)
	v8_.canNode = v11_
	v8_.originalPos = { getTranslation(v11_) }
	if self.isClient then
		v8_.effects = g_effectManager:loadEffect(xmlFile, "handTool.sprayCan.effects", self.components, self, self.i3dMappings)
		g_effectManager:setEffectTypeInfo(v8_.effects, FillType.WATER)
		for _, v12_ in ipairs(v8_.effects) do
			if v12_.setColor ~= nil then
				v12_:setColor(v9_[1], v9_[2], v9_[3], v9_[4])
			end
		end
	end
	v8_.sprayingSample = g_soundManager:loadSampleFromXML(xmlFile, "handTool.sprayCan.sounds", "spraying", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	v8_.foundTreeShape = nil
	v8_.foundTreeHitPosition = { 0, 0, 0 }
	v8_.treeMarkerTypeIndex = 1
	if g_iconGenerator == nil then
		local v13_ = g_currentMission.treeMarkerSystem
		v8_.treeMarkerType = v13_:getTreeMarkerTypeByIndex(v8_.treeMarkerTypeIndex)
		if v8_.treeMarkerType == nil then
			v8_.treeMarkerTypeIndex = 1
			v8_.treeMarkerType = v13_:getTreeMarkerTypeByIndex(v8_.treeMarkerTypeIndex)
		end
	end
	v8_.treeCrosshair = self:createCrosshairOverlayFromFile("data/shared/treeMarker/markerTree_icon.png", HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS * 2)
	if v8_.treeMarkerType ~= nil then
		v8_.treeTypeCrosshair = self:createCrosshairOverlayFromFile(v8_.treeMarkerType.iconFilename, HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS * 2)
	end
	v8_.wasActivatePressed = false
	v8_.isSpraying = false
	v8_.numShakes = 3
	v8_.shakeDuration = 200
	v8_.shakeEndTime = 0
	v8_.delayedMarker = nil
	v8_.dirtyFlag = self:getNextDirtyFlag()
	return true
end

-- Local values: key, spec
function HandToolSprayCan:onPostLoad(savegame)
	if savegame ~= nil then
		local v16_ = savegame.key .. ".sprayCan"
		if savegame.xmlFile:hasProperty(v16_) then
			local v17_ = self.spec_sprayCan
			local v18_ = savegame.xmlFile:getValue(v16_ .. "#remainingNumMarkers", v17_.remainingNumMarkers)
			local v19_ = v17_.maxTotalNumMarkers
			v17_.remainingNumMarkers = math.clamp(v18_, 1, v19_)
		end
	end
end

-- Local values: spec
function HandToolSprayCan:onDelete()
	local v21_ = self.spec_sprayCan
	self:processDelayedMarker()
	if v21_.effects ~= nil then
		g_effectManager:deleteEffects(v21_.effects)
	end
	if v21_.sprayingSample ~= nil then
		g_soundManager:deleteSample(v21_.sprayingSample)
	end
	if v21_.treeCrosshair ~= nil then
		v21_.treeCrosshair:delete()
		v21_.treeCrosshair = nil
	end
	if v21_.treeTypeCrosshair ~= nil then
		v21_.treeTypeCrosshair:delete()
		v21_.treeTypeCrosshair = nil
	end
end

-- Local values: spec
function HandToolSprayCan:onWriteStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v25_ = self.spec_sprayCan
		streamWriteUInt8(streamId, v25_.remainingNumMarkers)
	end
end

-- Local values: spec
function HandToolSprayCan:onReadStream(streamId, connection, carryingPlayer)
	if connection:getIsServer() then
		self.spec_sprayCan.remainingNumMarkers = streamReadUInt8(streamId)
	end
end

-- Local values: spec
function HandToolSprayCan:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v33_ = self.spec_sprayCan
		local v34_ = streamWriteBool
		local v35_ = v33_.dirtyFlag
		if v34_(streamId, bit32.band(dirtyMask, v35_) ~= 0) then
			streamWriteUInt8(streamId, v33_.remainingNumMarkers)
		end
	end
end

-- Local values: spec
function HandToolSprayCan:onReadUpdateStream(streamId, timestamp, connection, carryingPlayer)
	if connection:getIsServer() and streamReadBool(streamId) then
		self.spec_sprayCan.remainingNumMarkers = streamReadUInt8(streamId)
	end
end

-- Local values: spec
function HandToolSprayCan:saveToXMLFile(xmlFile, key, usedModNames)
	local v42_ = self.spec_sprayCan
	xmlFile:setValue(key .. "#remainingNumMarkers", v42_.remainingNumMarkers)
end

-- Local values: spec, player, allowInput, targetTree, mission, x, y, z, _, _, _, treeMarkerTypeIndex, shape, hitX, hitY, hitZ, x, y, z, timeLeft, factor, animValue
function HandToolSprayCan:onUpdate(dt)
	local v44_ = self.spec_sprayCan
	local v45_ = self:getCarryingPlayer()
	local v46_
	if v45_ == nil then
		v46_ = false
	else
		v46_ = v45_.isOwner or false
	end
	if v46_ then
		local v47_ = v45_.targeter.closestTargetsByKey[HandToolSprayCan]
		v44_.foundTargetTree = v47_
		if v44_.activatePressed and not (v44_.wasActivatePressed or v44_.isSpraying) then
			local v48_ = g_currentMission
			if v44_.remainingNumMarkers > 0 then
				local v49_, v50_, v51_, _, _, _ = v45_:getLookRay()
				local v52_ = v44_.treeMarkerTypeIndex
				local v53_, v54_, v55_, v56_
				if v47_ == nil then
					v53_ = nil
					v54_ = nil
					v55_ = nil
					v56_ = nil
				else
					v54_ = v47_.node
					v56_ = v47_.x
					v53_ = v47_.y
					v55_ = v47_.z
				end
				if self:getIsSprayingAllowed(v54_) then
					g_client:getServerConnection():sendEvent(SprayCanEvent.new(self, v52_, v54_, v49_, v50_, v51_, v56_, v53_, v55_))
				else
					v48_:showBlinkingWarning(g_i18n:getText("warning_youAreNotAllowedToMarkThisTree", self.customEnvironment), 2000)
				end
			else
				v48_:showBlinkingWarning(g_i18n:getText("warning_sprayCanIsEmpty", self.customEnvironment), 2000)
			end
			v44_.wasActivatePressed = true
		end
	end
	if v44_.delayedMarker ~= nil and v44_.delayedMarker.time <= g_time then
		self:processDelayedMarker()
	end
	if v44_.isSpraying then
		if v46_ then
			local v57_ = v44_.originalPos[1]
			local v58_ = v44_.originalPos[2]
			local v59_ = v44_.originalPos[3]
			local v60_ = v44_.shakeEndTime - g_time
			local v61_ = 1 - math.max(0, v60_) / v44_.shakeDuration
			local v62_ = MathUtil.lerp(0, v44_.numShakes, v61_)
			local v63_ = v62_ * 3.141592653589793
			local v64_ = v57_ + math.sin(v63_) * 0.01
			local v65_ = v62_ * 3.141592653589793
			local v66_ = v58_ + math.sin(v65_) * 0.05
			local v67_ = v62_ * 3.141592653589793
			local v68_ = v59_ + math.sin(v67_) * 0.01
			setTranslation(v44_.canNode, v64_, v66_, v68_)
		end
		if g_time > v44_.sprayStopTime then
			self:setIsSpraying(false, false)
		end
	end
	if not v44_.activatePressed then
		v44_.wasActivatePressed = false
	end
	v44_.activatePressed = false
end

-- Local values: spec
function HandToolSprayCan:onDraw()
	local v70_ = self.spec_sprayCan
	if v70_.treeMarkerType == nil then
		return
	elseif v70_.remainingNumMarkers ~= 0 then
		if v70_.treeTypeCrosshair ~= nil then
			v70_.treeTypeCrosshair:render()
		end
		if v70_.foundTargetTree ~= nil then
			v70_.treeCrosshair:render()
		end
	end
end

-- Local values: spec, targeter
function HandToolSprayCan:onHeldStart()
	if self:getCarryingPlayer().isOwner then
		local v72_ = self.spec_sprayCan
		local v73_ = self:getCarryingPlayer().targeter
		v73_:addTargetType(HandToolSprayCan, CollisionFlag.TREE, 0.5, v72_.sprayDetectionDistance)
		v73_:addFilterToTargetType(HandToolSprayCan, function(p74_, _, _, _)
			return getHasClassId(p74_, ClassIds.MESH_SPLIT_SHAPE)
		end)
	end
end

-- Local values: spec, mission, carryingPlayer
function HandToolSprayCan:onHeldEnd()
	local v76_ = self.spec_sprayCan
	local v77_ = g_currentMission
	local v78_ = self:getCarryingPlayer()
	if v78_ ~= nil and v78_.isOwner then
		v78_.targeter:removeTargetType(HandToolSprayCan)
		if v76_.remainingNumMarkers <= 0 then
			v77_:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("ingameNotification_deletedEmptySprayCan"))
		end
	end
	self:setIsSpraying(false, true)
	v76_.wasActivatePressed = false
	v76_.delayedMarker = nil
	if v76_.remainingNumMarkers <= 0 and self.isServer then
		v77_.handToolSystem:markHandToolForDeletion(self)
	end
end

-- Local values: _, actionEventId
function HandToolSprayCan:onRegisterActionEvents()
	if self:getIsActiveForInput(true) then
		local _, v80_ = self:addActionEvent(InputAction.SPRAYCAN_CHANGE_MARKER, self, self.changeTreeMarkerType, false, true, false, true, nil)
		g_inputBinding:setActionEventText(v80_, g_i18n:getText("action_changeTreeMarkerType"))
		local _, v81_ = self:addActionEvent(InputAction.ACTIVATE_HANDTOOL, self, self.activateSpraying, true, true, true, true, nil)
		g_inputBinding:setActionEventTextPriority(v81_, GS_PRIO_VERY_HIGH)
		g_inputBinding:setActionEventText(v81_, g_i18n:getText("action_sprayTreeMarker"))
	end
end

-- Local values: spec
function HandToolSprayCan:activateSpraying(_, inputValue)
	self.spec_sprayCan.activatePressed = inputValue ~= 0
end

-- Local values: spec
function HandToolSprayCan:tryToAddTreeMarker(treeMarkerTypeIndex, splitShapeId, x, y, z, hitX, hitY, hitZ)
	local v93_ = self.spec_sprayCan
	self:setIsSpraying(true, false)
	v93_.sprayStopTime = g_time + v93_.sprayDuration
	v93_.remainingNumMarkers = v93_.remainingNumMarkers - 1
	if self.isServer then
		self:raiseDirtyFlags(v93_.dirtyFlag)
	end
	if splitShapeId ~= nil and self:getIsSprayingAllowed(splitShapeId) then
		v93_.delayedMarker = {
			["time"] = g_time + v93_.sprayDelay,
			["splitShapeId"] = splitShapeId,
			["treeMarkerTypeIndex"] = treeMarkerTypeIndex,
			["hitX"] = hitX,
			["hitY"] = hitY,
			["hitZ"] = hitZ,
			["x"] = x,
			["y"] = y,
			["z"] = z
		}
	end
end

-- Local values: spec, splitShapeId, treeMarkerTypeIndex, x, y, z, hitX, hitY, hitZ, r, g, b, a, mission, treeMarkerSystem
function HandToolSprayCan:processDelayedMarker()
	local v95_ = self.spec_sprayCan
	if v95_.delayedMarker ~= nil then
		local v96_ = v95_.delayedMarker.splitShapeId
		local v97_ = v95_.delayedMarker.treeMarkerTypeIndex
		local v98_ = v95_.delayedMarker.x
		local v99_ = v95_.delayedMarker.y
		local v100_ = v95_.delayedMarker.z
		local v101_ = v95_.delayedMarker.hitX
		local v102_ = v95_.delayedMarker.hitY
		local v103_ = v95_.delayedMarker.hitZ
		if entityExists(v96_) then
			local v104_ = v95_.sprayColor[1]
			local v105_ = v95_.sprayColor[2]
			local v106_ = v95_.sprayColor[3]
			local v107_ = v95_.sprayColor[4]
			g_currentMission.treeMarkerSystem:addTreeMarkerCameraBased(v96_, v97_, v104_, v105_, v106_, v107_, v98_, v99_, v100_, v101_, v102_, v103_, true)
		end
		v95_.delayedMarker = nil
	end
end

-- Local values: spec
function HandToolSprayCan:setIsSpraying(isSpraying, force)
	local v111_ = self.spec_sprayCan
	if v111_.isSpraying ~= isSpraying then
		if isSpraying then
			if self:getIsHeld() then
				g_effectManager:startEffects(v111_.effects)
				g_soundManager:playSample(v111_.sprayingSample)
				v111_.shakeEndTime = g_time + v111_.shakeDuration
				v111_.isSpraying = true
				return
			end
		else
			if force then
				g_effectManager:resetEffects(v111_.effects)
			end
			g_effectManager:stopEffects(v111_.effects)
			g_soundManager:stopSample(v111_.sprayingSample)
			v111_.sprayStopTime = 0
			v111_.isSpraying = false
		end
	end
end

-- Local values: spec, mission, treeMarkerSystem
function HandToolSprayCan:changeTreeMarkerType(_, inputValue)
	local v113_ = self.spec_sprayCan
	local v114_ = g_currentMission.treeMarkerSystem
	v113_.treeMarkerTypeIndex = v113_.treeMarkerTypeIndex + 1
	if v113_.treeMarkerTypeIndex > v114_:getNumOfTreeMarkerTypes() then
		v113_.treeMarkerTypeIndex = 1
	end
	v113_.treeMarkerType = v114_:getTreeMarkerTypeByIndex(v113_.treeMarkerTypeIndex)
	if v113_.treeTypeCrosshair ~= nil then
		v113_.treeTypeCrosshair:delete()
	end
	v113_.treeTypeCrosshair = self:createCrosshairOverlayFromFile(v113_.treeMarkerType.iconFilename, HandTool.DEFAULT_CROSSHAIR_SIZE_PIXELS * 2)
end

-- Local values: x, _, z, mission
function HandToolSprayCan:getIsSprayingAllowed(shape)
	if shape == nil or shape == 0 then
		return true
	end
	local v116_, _, v117_ = getWorldTranslation(shape)
	return g_currentMission.accessHandler:canFarmAccessLand(g_localPlayer.farmId, v116_, v117_) and true or false
end
