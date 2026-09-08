-- Local values: HumanSounds_mt
HumanSounds = {}
local HumanSounds_mt = Class(HumanSounds)
g_xmlManager:addCreateSchemaFunction(function()
	HumanSounds.xmlSchema = XMLSchema.new("HumanSounds")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = HumanSounds.xmlSchema
	HumanSounds.registerXMLPaths(v2_, "humanSounds")
end)

-- Local values: xmlSchema
function HumanSounds.registerXMLPaths(schema, key)
	local v4_ = HumanSounds.xmlSchema
	SoundManager.registerSampleXMLPaths(v4_, key .. ".water", "swim")
	SoundManager.registerSampleXMLPaths(v4_, key .. ".water", "swimFast")
	SoundManager.registerSampleXMLPaths(v4_, key .. ".water", "swimIdle")
	SoundManager.registerSampleXMLPaths(v4_, key .. ".water", "plunge")
	SoundManager.registerSampleXMLPaths(v4_, key .. ".jump", "takeoff")
	SoundManager.registerSampleXMLPaths(v4_, key .. ".jump", "landing")
	v4_:register(XMLValueType.FLOAT, key .. ".footsteps.left#nodeOffset", "The offset of the foot node to the ground while standing still", 0.035, false)
	v4_:register(XMLValueType.FLOAT, key .. ".footsteps.left#liftedDistanceThreshold", "The offset of the foot node to the ground while standing still", 0.1, false)
	v4_:register(XMLValueType.FLOAT, key .. ".footsteps.left#playDistance", "The offset of the foot node to the ground while standing still", 0.02, false)
	v4_:register(XMLValueType.FLOAT, key .. ".footsteps.right#nodeOffset", "The offset of the foot node to the ground while standing still", 0.035, false)
	v4_:register(XMLValueType.FLOAT, key .. ".footsteps.right#liftedDistanceThreshold", "The offset of the foot node to the ground while standing still", 0.1, false)
	v4_:register(XMLValueType.FLOAT, key .. ".footsteps.right#playDistance", "The offset of the foot node to the ground while standing still", 0.02, false)
end

-- Upvalues: HumanSounds_mt
-- Local values: self
function HumanSounds.new(baseDirectory, customMt)
	-- upvalues: (copy) HumanSounds_mt
	local v7_ = customMt or HumanSounds_mt
	local v8_ = setmetatable({}, v7_)
	v8_.isLoaded = false
	v8_.baseDirectory = baseDirectory
	local v9_ = CollisionFlag.STATIC_OBJECT
	local v10_ = CollisionFlag.WATER
	local v11_ = CollisionFlag.TERRAIN
	local v12_ = CollisionFlag.TERRAIN_DELTA
	local v13_ = CollisionFlag.ROAD
	local v14_ = CollisionFlag.BUILDING
	local v15_ = CollisionFlag.VEHICLE
	v8_.raycastMask = bit32.bor(v9_, v10_, v11_, v12_, v13_, v14_, v15_)
	return v8_
end

-- Local values: xmlFile, _, surfaceSound, sampleLeft, sampleRight
function HumanSounds:load(rootNode, xmlFilename, xmlKey, leftFootNode, rightFootNode)
	local v22_ = XMLFile.load("HumandSounds", xmlFilename, HumanSounds.xmlSchema)
	if v22_ == nil then
		return false
	end
	self.rootNode = rootNode
	self.left = {}
	self.left.node = leftFootNode
	self.left.soundNode = createTransformGroup("leftFootSoundNode")
	self.left.isDirty = false
	self.left.nodeOffset = v22_:getValue(xmlKey .. ".footsteps.left#nodeOffset", 0.035)
	self.left.liftedDistanceThreshold = v22_:getValue(xmlKey .. ".footsteps.left#liftedDistanceThreshold", 0.1)
	self.left.playDistance = v22_:getValue(xmlKey .. ".footsteps.left#playDistance", 0.02)
	self.left.surfaceIdToSound = {}
	self.left.surfaceNameToSound = {}
	link(rootNode, self.left.soundNode)
	self.right = {}
	self.right.node = rightFootNode
	self.right.soundNode = createTransformGroup("rightFootSoundNode")
	self.right.isDirty = false
	self.right.nodeOffset = v22_:getValue(xmlKey .. ".footsteps.right#nodeOffset", 0.035)
	self.right.liftedDistanceThreshold = v22_:getValue(xmlKey .. ".footsteps.right#liftedDistanceThreshold", 0.1)
	self.right.playDistance = v22_:getValue(xmlKey .. ".footsteps.right#playDistance", 0.02)
	self.right.surfaceIdToSound = {}
	self.right.surfaceNameToSound = {}
	link(rootNode, self.right.soundNode)
	self.samples = {}
	self.samples.swim = g_soundManager:loadSampleFromXML(v22_, xmlKey .. ".water", "swim", self.baseDirectory, rootNode, 0, AudioGroup.ENVIRONMENT, nil, nil)
	self.samples.swimFast = g_soundManager:loadSampleFromXML(v22_, xmlKey .. ".water", "swimFast", self.baseDirectory, rootNode, 0, AudioGroup.ENVIRONMENT, nil, nil)
	self.samples.swimIdle = g_soundManager:loadSampleFromXML(v22_, xmlKey .. ".water", "swimIdle", self.baseDirectory, rootNode, 0, AudioGroup.ENVIRONMENT, nil, nil)
	self.samples.plunge = g_soundManager:loadSampleFromXML(v22_, xmlKey .. ".water", "plunge", self.baseDirectory, rootNode, 0, AudioGroup.ENVIRONMENT, nil, nil)
	self.samples.jump = g_soundManager:loadSampleFromXML(v22_, xmlKey .. ".jump", "takeoff", self.baseDirectory, rootNode, 0, AudioGroup.ENVIRONMENT, nil, nil)
	self.samples.landing = g_soundManager:loadSampleFromXML(v22_, xmlKey .. ".jump", "landing", self.baseDirectory, rootNode, 0, AudioGroup.ENVIRONMENT, nil, nil)
	if g_currentMission ~= nil then
		for _, v23_ in pairs(g_currentMission.surfaceSounds) do
			if v23_.type == "footstep" and v23_.sample ~= nil then
				local v24_ = g_soundManager:cloneSample(v23_.sample, self.left.soundNode, self)
				v24_.sampleName = v23_.name
				self.left.surfaceIdToSound[v23_.materialId] = v24_
				self.left.surfaceNameToSound[v23_.name] = v24_
				local v25_ = g_soundManager:cloneSample(v23_.sample, self.right.soundNode, self)
				v25_.sampleName = v23_.name
				self.right.surfaceIdToSound[v23_.materialId] = v25_
				self.right.surfaceNameToSound[v23_.name] = v25_
			end
		end
	end
	self.waterHeight = -1
	self.surfaceSample = nil
	self.surfaceId = nil
	self.isLoaded = true
	v22_:delete()
	return true
end

function HumanSounds:delete()
	self:unload()
end

function HumanSounds:unload()
	g_soundManager:deleteSamples(self.samples)
	if self.left ~= nil then
		g_soundManager:deleteSamples(self.left.surfaceNameToSound)
		g_soundManager:deleteSamples(self.right.surfaceNameToSound)
		self.left.surfaceNameToSound = nil
		self.left.surfaceIdToSound = nil
		self.right.surfaceNameToSound = nil
		self.right.surfaceIdToSound = nil
	end
	self.samples = nil
	self.isLoaded = false
end

-- Local values: activeCamera, distance, x, y, z, mask, raycastOffset, raycastDistance
function HumanSounds:update(dt)
	if self.isLoaded then
		local v29_ = g_cameraManager:getActiveCamera()
		if calcDistanceFrom(self.rootNode, v29_) <= 50 then
			local v30_, v31_, v32_ = getWorldTranslation(self.rootNode)
			local v33_ = self.raycastMask
			raycastClosestAsync(v30_, v31_ + 2, v32_, 0, -1, 0, 10, "groundRaycastCallback", self, v33_)
			if self.lastPosX ~= nil then
				self.distanceMoved = MathUtil.vector2Length(v30_ - self.lastPosX, v32_ - self.lastPosZ)
			end
			self:updateSounds()
			self.lastPosX = v30_
			self.lastPosY = v31_
			self.lastPosZ = v32_
		end
	else
		return
	end
end

-- Local values: distanceToGroundLeft, distanceToGroundRight, renderValue
function HumanSounds:drawDebug(posX, posY, textSize)
	local v38_ = self:getFootDistanceToRootNode(self.left)
	DebugUtil.drawDebugNode(self.left.node, string.format("%.3f", v38_), false, 0)
	local v39_ = self:getFootDistanceToRootNode(self.right)
	DebugUtil.drawDebugNode(self.right.node, string.format("%.3f", v39_), false, 0)
	local function v42_(p40_, p41_)
		-- upvalues: (copy) posX, (ref) posY, (copy) textSize
		if type(p41_) == "boolean" then
			p41_ = tostring(p41_)
		elseif type(p41_) ~= "string" then
			p41_ = string.format("%.4f", p41_)
		end
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(posX, posY, textSize, p40_ .. " : ")
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(posX, posY, textSize, p41_)
		posY = posY - textSize - 2 * g_pixelSizeY
	end
	v42_("left", "")
	v42_("distance", v38_)
	v42_("isDirty", self.left.isDirty)
	v42_("nodeOffset", self.left.nodeOffset)
	v42_("liftedDistanceThreshold", self.left.liftedDistanceThreshold)
	v42_("playDistance", self.left.playDistance)
	v42_("", "")
	v42_("right", "")
	v42_("distance", v38_)
	v42_("isDirty", self.right.isDirty)
	v42_("nodeOffset", self.right.nodeOffset)
	v42_("liftedDistanceThreshold", self.right.liftedDistanceThreshold)
	v42_("playDistance", self.right.playDistance)
end

-- Local values: hitTerrain, snowHeight, isOnField, _, _, _, _, _, materialId, hitWater, terrainY, continueReporting
function HumanSounds:groundRaycastCallback(nodeId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	self.waterHeight = -1
	self.surfaceSample = nil
	self.surfaceId = nil
	if nodeId == 0 then
		return false
	elseif nodeId == g_terrainNode then
		if g_currentMission.snowSystem:getSnowHeightAtArea(x, z, x + 0.1, z + 0.1, x + 0.1, z) > 0 then
			self.surfaceSample = "snow"
			return false
		end
		local v48_, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(x, y, z)
		if v48_ then
			self.surfaceName = "field"
			return false
		end
		local _, _, _, _, v49_ = getTerrainAttributesAtWorldPos(g_terrainNode, x, y, z, true, true, true, true, false)
		self.surfaceId = v49_
		return false
	elseif CollisionFlag.getHasGroupFlagSet(nodeId, CollisionFlag.WATER) then
		self.waterHeight = y - getTerrainHeightAtWorldPos(g_terrainNode, x, y, z)
		if self.waterHeight < 0.3 then
			self.surfaceName = "shallowWater"
		else
			self.surfaceName = "mediumWater"
		end
	else
		self.surfaceName = "asphalt"
		return false
	end
end

function HumanSounds:applyState(state)
	self.isCrouching = state.isCrouching
	self.isSwimming = state.isSwimming
	local v52_ = state.isSwimming
	if v52_ then
		v52_ = state.isWalking or state.isRunning
	end
	self.isForwardSwimming = v52_
	local v53_ = state.isSwimming
	if v53_ then
		v53_ = state.isRunning
	end
	self.isSwimmingFast = v53_
	self.isInWater = state.isInWater
	self.isIdling = state.isIdling
	self.isWalking = state.isWalking
	self.isRunning = state.isRunning
	self.isGrounded = state.isGrounded
	self.isCloseToGround = state.isCloseToGround
	self.distanceToGround = state.distanceToGround
	self.absSpeed = state.absSpeed
end

-- Local values: samples, _, sample
function HumanSounds:updateSounds()
	local v55_ = self.samples
	if v55_.swim ~= nil then
		local v56_ = v55_.swim
		local v57_ = self.isSwimming and self.isForwardSwimming
		if v57_ then
			v57_ = not self.isSwimmingFast
		end
		v56_.isActive = v57_
	end
	if v55_.swimFast ~= nil then
		local v58_ = v55_.swimFast
		local v59_ = self.isSwimming and self.isForwardSwimming
		if v59_ then
			v59_ = self.isSwimmingFast
		end
		v58_.isActive = v59_
	end
	if v55_.swimIdle ~= nil then
		local v60_ = v55_.swimIdle
		local v61_ = self.isSwimming
		if v61_ then
			v61_ = not self.isForwardSwimming
		end
		v60_.isActive = v61_
	end
	for _, v62_ in pairs(v55_) do
		if v62_.isActive then
			if not g_soundManager:getIsSamplePlaying(v62_) then
				g_soundManager:playSample(v62_)
			end
		elseif g_soundManager:getIsSamplePlaying(v62_) then
			g_soundManager:stopSample(v62_)
		end
	end
	if not self.isSwimming and self.distanceToGround < 0.1 then
		self:updateFootStep(self.left)
		self:updateFootStep(self.right)
	end
end

-- Local values: distanceToGround, sample
function HumanSounds:updateFootStep(foot)
	setWorldTranslation(foot.soundNode, getWorldTranslation(foot.node))
	local v65_ = self:getFootDistanceToRootNode(foot)
	if foot.liftedDistanceThreshold < v65_ then
		foot.isDirty = true
	end
	if v65_ < foot.playDistance and foot.isDirty then
		foot.isDirty = false
		local v66_ = nil
		if self.surfaceId == nil then
			if self.surfaceName ~= nil then
				v66_ = foot.surfaceNameToSound[self.surfaceName]
			end
		else
			v66_ = foot.surfaceIdToSound[self.surfaceId]
		end
		if v66_ ~= nil then
			g_soundManager:playSample(v66_)
		end
	end
end

-- Local values: _, y, _
function HumanSounds:getFootDistanceToRootNode(foot)
	local _, v69_, _ = localToLocal(foot.node, self.rootNode, 0, 0, 0)
	return v69_ - foot.nodeOffset
end
