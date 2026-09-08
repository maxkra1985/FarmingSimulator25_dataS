-- Local values: VehicleCharacter_mt, setCharacterVisibilityBackup
VehicleCharacter = {}
VehicleCharacter.DEFAULT_MAX_UPDATE_DISTANCE = 35
VehicleCharacter.DEFAULT_CLIP_DISTANCE = 75
VehicleCharacter.SPINE_ROTATION = { -1.5707963267948966, -0.2461786909938002, 1.5707963267948966 }
local VehicleCharacter_mt = Class(VehicleCharacter)

-- Upvalues: VehicleCharacter_mt
-- Local values: self
function VehicleCharacter.new(vehicle, customMt)
	-- upvalues: (copy) VehicleCharacter_mt
	local v4_ = customMt or VehicleCharacter_mt
	local v5_ = setmetatable({}, v4_)
	v5_.vehicle = vehicle
	v5_.characterNode = nil
	v5_.allowUpdate = true
	v5_.ikChainTargets = {}
	v5_.animationCharsetId = nil
	v5_.animationPlayer = nil
	v5_.useAnimation = false
	v5_.isVisible = false
	return v5_
end

function VehicleCharacter:load(xmlFile, xmlNode)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlNode .. "#index", xmlNode .. "#node")
	self.characterNode = xmlFile:getValue(xmlNode .. "#node", nil, self.vehicle.components, self.vehicle.i3dMappings)
	if self.characterNode == nil then
		return false
	end
	self.parentComponent = self.vehicle:getParentComponent(self.characterNode)
	self.characterCameraMinDistance = xmlFile:getValue(xmlNode .. "#cameraMinDistance", 1.5)
	self.characterDistanceRefNodeCustom = xmlFile:getValue(xmlNode .. "#distanceRefNode", nil, self.vehicle.components, self.vehicle.i3dMappings)
	self.characterDistanceRefNode = self.characterDistanceRefNodeCustom or self.characterNode
	setVisibility(self.characterNode, false)
	self.useAnimation = xmlFile:getValue(xmlNode .. "#useAnimation", false)
	local v9_ = xmlNode .. "#useIdleAnimation"
	local v10_ = not self.useAnimation
	if v10_ then
		v10_ = Platform.gameplay.hasVehicleCharacterIdleAnimations
	end
	self.useIdleAnimation = xmlFile:getValue(v9_, v10_)
	if not self.useAnimation then
		self.ikChainTargets = {}
		IKUtil.loadIKChainTargets(xmlFile, xmlNode, self.vehicle.components, self.ikChainTargets, self.vehicle.i3dMappings)
	end
	self.characterSpineRotationOffset = xmlFile:getValue(xmlNode .. "#spineRotationOffset", nil, true)
	self.characterSpineSpeedDepended = xmlFile:getValue(xmlNode .. "#speedDependedSpine", false)
	self.characterSpineNodeMinRot = xmlFile:getValue(xmlNode .. "#spineNodeMinRot", 10)
	self.characterSpineNodeMaxRot = xmlFile:getValue(xmlNode .. "#spineNodeMaxRot", -10)
	self.characterSpineNodeMinAcc = xmlFile:getValue(xmlNode .. "#spineNodeMinAcc", -1) / 1000000
	self.characterSpineNodeMaxAcc = xmlFile:getValue(xmlNode .. "#spineNodeMaxAcc", 1) / 1000000
	self.characterSpineNodeAccDeadZone = xmlFile:getValue(xmlNode .. "#spineNodeAccDeadZone", 0.2) / 1000000
	self.characterSpineLastRotation = 0
	self:setCharacterVisibility(self.isVisible)
	self.maxUpdateDistance = xmlFile:getValue(xmlNode .. "#maxUpdateDistance", VehicleCharacter.DEFAULT_MAX_UPDATE_DISTANCE)
	setClipDistance(self.characterNode, xmlFile:getValue(xmlNode .. "#clipDistance", VehicleCharacter.DEFAULT_CLIP_DISTANCE))
	return true
end

function VehicleCharacter:getParentComponent()
	return self.parentComponent
end

-- Local values: arguments
function VehicleCharacter:loadCharacter(playerStyle, asyncCallbackObject, asyncCallbackFunction, asyncCallbackArguments)
	if playerStyle == nil then
		asyncCallbackFunction(asyncCallbackObject, false, asyncCallbackArguments)
	else
		if self.playerModel ~= nil then
			self.playerModel:delete()
		end
		self.playerModel = HumanModel.new()
		self.playerModel:load(playerStyle.xmlFilename, false, false, self.useAnimation, self.characterLoaded, self, {
			["asyncCallbackObject"] = asyncCallbackObject,
			["asyncCallbackFunction"] = asyncCallbackFunction,
			["asyncCallbackArguments"] = asyncCallbackArguments,
			["playerStyle"] = playerStyle
		})
	end
end

-- Local values: linkNode, ikChainId, target, x, y, z, skeleton, animNode, animationPlayer, skeleton, animNode, playerStyle, asyncCallbackObject, asyncCallbackFunction, asyncCallbackArguments
function VehicleCharacter:characterLoaded(loadingState, arguments)
	if loadingState == HumanModelLoadingState.OK then
		if self.playerModel.rootNode == nil then
			return
		end
		self.isStyleLoaded = false
		local v20_ = Utils.getNoNil(self.characterNode, self.vehicle.rootNode)
		link(v20_, self.playerModel.rootNode)
		for v21_, v22_ in pairs(self.ikChainTargets) do
			IKUtil.setTarget(self.playerModel:getIKChains(), v21_, v22_)
		end
		if self.playerModel.thirdPersonHipsNode ~= nil then
			local v23_ = VehicleCharacter.SPINE_ROTATION[1]
			local v24_ = VehicleCharacter.SPINE_ROTATION[2]
			local v25_ = VehicleCharacter.SPINE_ROTATION[3]
			if self.characterSpineRotationOffset ~= nil then
				v23_ = self.characterSpineRotationOffset[1] + v23_
				v24_ = self.characterSpineRotationOffset[2] + v24_
				v25_ = self.characterSpineRotationOffset[3] + v25_
			end
			setRotation(self.playerModel.thirdPersonHipsNode, v23_, v24_, v25_)
		end
		self.characterDistanceRefNode = self.characterDistanceRefNodeCustom or self.playerModel.thirdPersonHeadNode
		if self.playerModel.skeleton ~= nil and getNumOfChildren(self.playerModel.skeleton) > 0 then
			if self.useAnimation then
				local v26_ = self.playerModel.skeleton
				local v27_ = g_animCache:getNode(AnimationCache.CHARACTER)
				cloneAnimCharacterSet(getChildAt(v27_, 0), v26_)
				self.animationCharsetId = getAnimCharacterSet(getChildAt(v26_, 0))
				local v28_ = createConditionalAnimation()
				if v28_ ~= 0 then
					self.animationPlayer = v28_
				end
				if self.animationCharsetId == 0 then
					self.animationCharsetId = nil
					Logging.devError("-- [VehicleCharacter:loadCharacter] Could not load animation CharSet from: [%s/%s]", getName(getParent(v26_)), getName(v26_))
					printScenegraph(getParent(v26_))
				end
			elseif self.useIdleAnimation then
				local v29_ = self.playerModel.skeleton
				local v30_ = g_animCache:getNode(AnimationCache.VEHICLE_CHARACTER)
				cloneAnimCharacterSet(getChildAt(v30_, 0), v29_)
				self.animationCharsetId = getAnimCharacterSet(v29_)
				if self.animationCharsetId == 0 then
					self.useIdleAnimation = false
					self.animationCharsetId = nil
					Logging.devError("-- [VehicleCharacter:loadCharacter] Could not load animation CharSet from: [%s/%s]", getName(getParent(v29_)), getName(v29_))
				else
					self.idleClipIndex = getAnimClipIndex(self.animationCharsetId, "idle1Source")
					clearAnimTrackClip(self.animationCharsetId, 0)
					assignAnimTrackClip(self.animationCharsetId, 0, self.idleClipIndex)
					setAnimTrackLoopState(self.animationCharsetId, 0, true)
					self.idleAnimationState = false
				end
			end
		end
		local v31_ = arguments.playerStyle
		self.playerModel:loadFromStyleAsync(v31_, function(_, p32_, _)
			-- upvalues: (copy) self
			if p32_ == HumanModelLoadingState.OK then
				self.isStyleLoaded = true
				self:setDirty(true)
				self:setCharacterVisibility(self.isVisible)
			end
		end, nil, nil)
	else
		self.playerModel:delete()
		self.playerModel = nil
		Logging.error("Failed to load vehicleCharacter")
	end
	local v33_ = arguments.asyncCallbackObject
	local v34_ = arguments.asyncCallbackFunction
	local v35_ = arguments.asyncCallbackArguments
	if v34_ ~= nil then
		v34_(v33_, loadingState, v35_)
	end
end

function VehicleCharacter:delete()
	self:unloadCharacter()
end

function VehicleCharacter:unloadCharacter()
	if self.playerModel ~= nil then
		self.characterDistanceRefNode = self.characterDistanceRefNodeCustom or self.characterNode
		self.playerModel:delete()
		self.playerModel = nil
		if self.animationPlayer ~= nil then
			delete(self.animationPlayer)
			self.animationPlayer = nil
		end
	end
end

-- Local values: chainId, target
function VehicleCharacter:setDirty(setAllDirty)
	if self.playerModel ~= nil then
		for v40_, v41_ in pairs(self.ikChainTargets) do
			if v41_.setDirty or setAllDirty then
				IKUtil.setIKChainDirty(self.playerModel:getIKChains(), v40_)
			end
		end
	end
end

function VehicleCharacter:updateIKChains()
	IKUtil.updateIKChains(self.playerModel:getIKChains(), true)
end

-- Local values: ikChains, chain
function VehicleCharacter:setIKChainPoseByTarget(target, poseId)
	if self.playerModel ~= nil then
		local v46_ = self.playerModel:getIKChains()
		local v47_ = IKUtil.getIKChainByTarget(v46_, target)
		if v47_ ~= nil then
			IKUtil.setIKChainPose(v46_, v47_.id, poseId)
		end
	end
end

-- Local values: alpha, rotation
function VehicleCharacter:setSpineDirty(acc)
	local v50_ = ((math.abs(acc) < self.characterSpineNodeAccDeadZone and 0 or acc) - self.characterSpineNodeMinAcc) / (self.characterSpineNodeMaxAcc - self.characterSpineNodeMinAcc)
	local v51_ = math.clamp(v50_, 0, 1)
	local v52_ = MathUtil.lerp(self.characterSpineNodeMinRot, self.characterSpineNodeMaxRot, v51_)
	if v52_ ~= self.characterSpineLastRotation then
		self.characterSpineLastRotation = self.characterSpineLastRotation * 0.95 + v52_ * 0.05
		setRotation(self.player.spineNode, self.characterSpineLastRotation, 0, 0)
		self:setDirty()
	end
end

-- Local values: dist, visible
function VehicleCharacter:updateVisibility()
	if self.isStyleLoaded and (entityExists(self.characterDistanceRefNode) and entityExists(g_cameraManager:getActiveCamera())) then
		self:setCharacterVisibility(calcDistanceFrom(self.characterDistanceRefNode, g_cameraManager:getActiveCamera()) >= self.characterCameraMinDistance)
	end
end

function VehicleCharacter:setCharacterVisibility(isVisible)
	if self.characterNode ~= nil then
		setVisibility(self.characterNode, isVisible)
	end
	if self.playerModel ~= nil and self.playerModel.isLoaded then
		self.playerModel:setVisibility(isVisible)
	end
	self.isVisible = isVisible
end

function VehicleCharacter:setAllowCharacterUpdate(state)
	self.allowUpdate = state
end

function VehicleCharacter:getAllowCharacterUpdate()
	return self.allowUpdate
end

function VehicleCharacter:update(dt)
	if self.playerModel ~= nil and self.playerModel.isLoaded then
		if Platform.gameplay.allowVehicleCharacterIKDirtyUpdate and (self.vehicle.currentUpdateDistance < self.maxUpdateDistance and self.isVisible) then
			if self:getAllowCharacterUpdate() then
				self:setDirty(false)
			end
			self:updateIKChains()
		end
		if self.useIdleAnimation then
			if self.vehicle.currentUpdateDistance < self.maxUpdateDistance then
				if not self.idleAnimationState then
					self.idleAnimationState = true
					enableAnimTrack(self.animationCharsetId, 0)
					return
				end
			elseif self.idleAnimationState then
				self.idleAnimationState = false
				disableAnimTrack(self.animationCharsetId, 0)
			end
		end
	end
end

function VehicleCharacter:getIKChainTargets()
	return self.ikChainTargets
end

-- Local values: ikChainId, target
function VehicleCharacter:setIKChainTargets(targets, force)
	if self.ikChainTargets ~= targets or force then
		self.ikChainTargets = targets
		if self.playerModel ~= nil then
			for v64_, v65_ in pairs(self.ikChainTargets) do
				IKUtil.setTarget(self.playerModel:getIKChains(), v64_, v65_)
			end
			self:setDirty(true)
		end
	end
end

function VehicleCharacter:getPlayerStyle()
	if self.playerModel == nil then
		return nil
	else
		return self.playerModel.style
	end
end

function VehicleCharacter.registerCharacterXMLPaths(schema, basePath, name)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Character root node")
	schema:register(XMLValueType.FLOAT, basePath .. "#cameraMinDistance", "Min. distance until character is hidden", 1.5)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#distanceRefNode", "Distance reference node", "Character root node")
	schema:register(XMLValueType.BOOL, basePath .. "#useAnimation", "Use animation instead of ik chains", false)
	schema:register(XMLValueType.BOOL, basePath .. "#useIdleAnimation", "Apply character idle animation additionally to ik chain control", "set if #useAnimation not set")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#spineRotationOffset", "Spine rotation offset")
	schema:register(XMLValueType.BOOL, basePath .. "#speedDependedSpine", "Speed dependent spine", false)
	schema:register(XMLValueType.ANGLE, basePath .. "#spineNodeMinRot", "Spine node min. rotation", 10)
	schema:register(XMLValueType.ANGLE, basePath .. "#spineNodeMaxRot", "Spine node max. rotation", -10)
	schema:register(XMLValueType.FLOAT, basePath .. "#spineNodeMinAcc", "Spine node min. acceleration", -1)
	schema:register(XMLValueType.FLOAT, basePath .. "#spineNodeMaxAcc", "Spine node max. acceleration", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#spineNodeAccDeadZone", "Spine node acceleration dead zone", 0.2)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxUpdateDistance", "Max. distance to vehicle root to update ik chains of character", VehicleCharacter.DEFAULT_MAX_UPDATE_DISTANCE)
	schema:register(XMLValueType.FLOAT, basePath .. "#clipDistance", "Clip distance of character", VehicleCharacter.DEFAULT_CLIP_DISTANCE)
	IKUtil.registerIKChainTargetsXMLPaths(schema, basePath)
end
local v_u_69_ = nil
local function v72_()
	-- upvalues: (ref) v_u_69_
	if v_u_69_ == nil then
		v_u_69_ = VehicleCharacter.setCharacterVisibility
		VehicleCharacter.setCharacterVisibility = Utils.overwrittenFunction(VehicleCharacter.setCharacterVisibility, function(p70_, p71_, _)
			p71_(p70_, false)
		end)
		return "Vehicle characters hidden"
	else
		VehicleCharacter.setCharacterVisibility = v_u_69_
		v_u_69_ = nil
		return "Vehicle characters unhidden"
	end
end
VehicleCharacter.consoleCommandVisibilityToggle = v72_
addConsoleCommand("gsVehicleCharacterVisibilityToggle", "Locally toggles visibility of all vehicle characters/drivers/players", "consoleCommandVisibilityToggle", VehicleCharacter)
