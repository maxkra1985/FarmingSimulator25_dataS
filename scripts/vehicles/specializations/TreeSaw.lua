TreeSaw = {}

function TreeSaw.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end
function TreeSaw.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("TreeSaw")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.treeSaw.sounds", "cut")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.treeSaw.sounds", "saw")
	AnimationManager.registerAnimationNodesXMLPaths(v2_, "vehicle.treeSaw.animationNodes")
	EffectManager.registerEffectXMLPaths(v2_, "vehicle.treeSaw.effects")
	v2_:register(XMLValueType.NODE_INDEX, "vehicle.treeSaw.cutNode#node", "Cut node")
	v2_:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#sizeY", "Size Y", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#sizeZ", "Size Z", 1)
	v2_:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#lengthAboveThreshold", "Min. tree length above cut node", 0.3)
	v2_:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#lengthBelowThreshold", "Min. tree length below cut node", 0.3)
	v2_:register(XMLValueType.FLOAT, "vehicle.treeSaw.cutNode#timer", "Cut delay (sec.)", 1)
	v2_:setXMLSpecializationType()
end

function TreeSaw.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", TreeSaw)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", TreeSaw)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", TreeSaw)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", TreeSaw)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", TreeSaw)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", TreeSaw)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", TreeSaw)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", TreeSaw)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", TreeSaw)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", TreeSaw)
end

-- Local values: spec, baseKey
function TreeSaw:onLoad(savegame)
	local v5_ = self.spec_treeSaw
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode", "vehicle.treeSaw.animationNodes.animationNode", "stumbCutter")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.treeSaw.cutParticleSystems.emitterShape(0)", "vehicle.treeSaw.effects.effectNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.treeSaw.sawSound", "vehicle.treeSaw.sounds.saw")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.treeSaw.cutSound", "vehicle.treeSaw.sounds.cut")
	if self.isClient then
		v5_.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.treeSaw.animationNodes", self.components, self, self.i3dMappings)
		v5_.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.treeSaw.effects", self.components, self, self.i3dMappings)
		v5_.samples = {}
		v5_.samples.cut = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.treeSaw.sounds", "cut", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		v5_.samples.saw = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.treeSaw.sounds", "saw", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	v5_.cutNode = self.xmlFile:getValue("vehicle.treeSaw.cutNode#node", nil, self.components, self.i3dMappings)
	v5_.cutSizeY = self.xmlFile:getValue("vehicle.treeSaw.cutNode#sizeY", 1)
	v5_.cutSizeZ = self.xmlFile:getValue("vehicle.treeSaw.cutNode#sizeZ", 1)
	v5_.lengthAboveThreshold = self.xmlFile:getValue("vehicle.treeSaw.cutNode#lengthAboveThreshold", 0.3)
	v5_.lengthBelowThreshold = self.xmlFile:getValue("vehicle.treeSaw.cutNode#lengthBelowThreshold", 0.3)
	v5_.cutTimerDuration = self.xmlFile:getValue("vehicle.treeSaw.cutNode#timer", 1) * 1000
	v5_.curSplitShape = nil
	v5_.cutTimer = -1
	v5_.isCutting = false
	v5_.warnTreeNotOwned = false
end

-- Local values: spec
function TreeSaw:onDelete()
	local v7_ = self.spec_treeSaw
	g_effectManager:deleteEffects(v7_.effects)
	g_soundManager:deleteSamples(v7_.samples)
	g_animationManager:deleteAnimations(v7_.animationNodes)
end

-- Local values: spec
function TreeSaw:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		self.spec_treeSaw.isCutting = streamReadBool(streamId)
	end
end

-- Local values: spec
function TreeSaw:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local v14_ = self.spec_treeSaw
		streamWriteBool(streamId, v14_.isCutting)
	end
end

-- Local values: spec, x, y, z, nx, ny, nz, yx, yy, yz
function TreeSaw:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v17_ = self.spec_treeSaw
	if self.isServer then
		if v17_.curSplitShape ~= nil and not entityExists(v17_.curSplitShape) then
			v17_.curSplitShape = nil
			if g_server ~= nil then
				v17_.cutTimer = -1
			end
		end
		v17_.isCutting = v17_.curSplitShape ~= nil
		if v17_.curSplitShape ~= nil then
			if v17_.cutTimer > 0 then
				local v18_ = v17_.cutTimer - dt
				v17_.cutTimer = math.max(v18_, 0)
			end
			if v17_.cutTimer == 0 then
				v17_.cutTimer = -1
				local v19_, v20_, v21_ = getWorldTranslation(v17_.cutNode)
				local v22_, v23_, v24_ = localDirectionToWorld(v17_.cutNode, 1, 0, 0)
				local v25_, v26_, v27_ = localDirectionToWorld(v17_.cutNode, 0, 1, 0)
				ChainsawUtil.cutSplitShape(v17_.curSplitShape, v19_, v20_, v21_, v22_, v23_, v24_, v25_, v26_, v27_, v17_.cutSizeY, v17_.cutSizeZ, self:getActiveFarm())
				v17_.curSplitShape = nil
			end
		end
	end
	if self.isClient then
		if v17_.cutTimer > 0 then
			g_effectManager:setEffectTypeInfo(v17_.effects, FillType.WOODCHIPS)
			g_effectManager:startEffects(v17_.effects)
			if not g_soundManager:getIsSamplePlaying(v17_.samples.cut) then
				g_soundManager:playSample(v17_.samples.cut)
				return
			end
		else
			g_effectManager:stopEffects(v17_.effects)
			if g_soundManager:getIsSamplePlaying(v17_.samples.cut) then
				g_soundManager:stopSample(v17_.samples.cut)
			end
		end
	end
end

-- Local values: spec, x, y, z, nx, ny, nz, yx, yy, yz, shape, _, _, _, _, minY, maxY, minZ, maxZ, cutTooLow, _, ly, _, lenBelow, lenAbove
function TreeSaw:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v29_ = self.spec_treeSaw
	v29_.warnTreeNotOwned = false
	if self:getIsTurnedOn() and v29_.cutNode ~= nil then
		local v30_, v31_, v32_ = getWorldTranslation(v29_.cutNode)
		local v33_, v34_, v35_ = localDirectionToWorld(v29_.cutNode, 1, 0, 0)
		local v36_, v37_, v38_ = localDirectionToWorld(v29_.cutNode, 0, 1, 0)
		if v29_.curSplitShape == nil then
			local v39_, _, _, _, _ = findSplitShape(v30_, v31_, v32_, v33_, v34_, v35_, v36_, v37_, v38_, v29_.cutSizeY, v29_.cutSizeZ)
			if v39_ ~= 0 then
				if g_currentMission.accessHandler:canFarmAccessLand(self:getActiveFarm(), v30_, v32_) then
					v29_.curSplitShape = v39_
					v29_.cutTimer = v29_.cutTimerDuration
				else
					v29_.warnTreeNotOwned = true
				end
			end
		elseif not entityExists(v29_.curSplitShape) then
			v29_.curSplitShape = nil
		end
		if v29_.curSplitShape ~= nil then
			local v40_, v41_, v42_, v43_ = testSplitShape(v29_.curSplitShape, v30_, v31_, v32_, v33_, v34_, v35_, v36_, v37_, v38_, v29_.cutSizeY, v29_.cutSizeZ)
			if v40_ == nil then
				v29_.curSplitShape = nil
			else
				local _, v44_, _ = localToLocal(v29_.cutNode, v29_.curSplitShape, 0, v40_, v42_)
				local v45_ = v44_ < 0.01
				local _, v46_, _ = localToLocal(v29_.cutNode, v29_.curSplitShape, 0, v40_, v43_)
				local v47_ = v45_ or v46_ < 0.01
				local _, v48_, _ = localToLocal(v29_.cutNode, v29_.curSplitShape, 0, v41_, v42_)
				local v49_ = v47_ or v48_ < 0.01
				local _, v50_, _ = localToLocal(v29_.cutNode, v29_.curSplitShape, 0, v41_, v43_)
				if v49_ or v50_ < 0.01 then
					v29_.curSplitShape = nil
				end
			end
		end
		if v29_.curSplitShape ~= nil then
			local v51_, v52_ = getSplitShapePlaneExtents(v29_.curSplitShape, v30_, v31_, v32_, v33_, v34_, v35_)
			if v52_ < v29_.lengthAboveThreshold or v51_ < v29_.lengthBelowThreshold then
				v29_.curSplitShape = nil
			end
		end
		if v29_.curSplitShape == nil and v29_.cutTimer > -1 then
			v29_.cutTimer = -1
		end
	end
end

-- Local values: spec
function TreeSaw:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v54_ = self.spec_treeSaw
	if v54_.isCutting then
		g_currentMission:addExtraPrintText(g_i18n:getText("info_cutting"))
	end
	if v54_.warnTreeNotOwned then
		g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"), 1000)
	end
end

-- Local values: spec
function TreeSaw:onDeactivate()
	local v56_ = self.spec_treeSaw
	v56_.curSplitShape = nil
	v56_.cutTimer = -1
end

-- Local values: spec
function TreeSaw:onTurnedOn()
	if self.isClient then
		local v58_ = self.spec_treeSaw
		g_animationManager:startAnimations(v58_.animationNodes)
		g_soundManager:playSample(v58_.samples.saw)
	end
end

-- Local values: spec
function TreeSaw:onTurnedOff()
	local v60_ = self.spec_treeSaw
	v60_.curSplitShape = nil
	v60_.cutTimer = -1
	if self.isClient then
		g_animationManager:stopAnimations(v60_.animationNodes)
		g_effectManager:stopEffects(v60_.effects)
		g_soundManager:stopSamples(v60_.samples)
	end
end
