-- Local values: VehicleCamera_mt
VehicleCamera = {}
local VehicleCamera_mt = Class(VehicleCamera)
VehicleCamera.doCameraSmoothing = false
VehicleCamera.raycastMask = CollisionFlag.TERRAIN + CollisionFlag.CAMERA_BLOCKING + CollisionFlag.WATER

-- Upvalues: VehicleCamera_mt
-- Local values: self
function VehicleCamera.new(vehicle, customMt)
	-- upvalues: (copy) VehicleCamera_mt
	local v4_ = customMt or VehicleCamera_mt
	local v5_ = setmetatable({}, v4_)
	v5_.vehicle = vehicle
	v5_.isActivated = false
	v5_.limitRotXDelta = 0
	v5_.cameraNode = nil
	v5_.raycastDistance = 0
	v5_.normalX = 0
	v5_.normalY = 0
	v5_.normalZ = 0
	v5_.raycastNodes = {}
	v5_.disableCollisionTime = -1
	v5_.lookAtPosition = { 0, 0, 0 }
	v5_.lookAtLastTargetPosition = { 0, 0, 0 }
	v5_.position = { 0, 0, 0 }
	v5_.lastTargetPosition = { 0, 0, 0 }
	v5_.upVector = { 0, 0, 0 }
	v5_.lastUpVector = { 0, 0, 0 }
	v5_.lastInputValues = {}
	v5_.lastInputValues.upDown = 0
	v5_.lastInputValues.leftRight = 0
	v5_.isCollisionEnabled = true
	if g_modIsLoaded.FS22_disableVehicleCameraCollision or g_isDevelopmentVersion then
		v5_.isCollisionEnabled = g_gameSettings:getValue(GameSettings.SETTING.CAMERA_CHECK_COLLISION)
		g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.CAMERA_CHECK_COLLISION], v5_.onCameraCollisionDetectionSettingChanged, v5_)
	end
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA], v5_.onActiveCameraSuspensionSettingChanged, v5_)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FOV_Y], v5_.onFovySettingChanged, v5_)
	return v5_
end

-- Local values: lowResColHandlerHighPrio, dofInfo, rotation, rotationNode, translation, useDefaultPositionSmoothing, useHeadTracking, camIndex, x, y, z, rx, ry, rz, dx, _, dz, tx, ty, tz, transLength, trans1OverLength, _, raycastKey, node, sx, sy, sz, cameraKey, rotX, rotY, rotZ, fovY
function VehicleCamera:loadFromXML(xmlFile, key, savegame, cameraIndex)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.vehicle.configFileName, key .. "#index", "#node")
	self.cameraNode = xmlFile:getValue(key .. "#node", nil, self.vehicle.components, self.vehicle.i3dMappings)
	if self.cameraNode == nil or not getHasClassId(self.cameraNode, ClassIds.CAMERA) then
		Logging.xmlWarning(xmlFile, "Invalid camera node for camera \'%s\'. Must be a camera type!", key)
		return false
	end
	self.shadowFocusBoxNode = xmlFile:getValue(key .. "#shadowFocusBox", nil, self.vehicle.components, self.vehicle.i3dMappings)
	if self.shadowFocusBoxNode ~= nil and not (getHasClassId(self.shadowFocusBoxNode, ClassIds.SHAPE) and getShapeIsCPUMesh(self.shadowFocusBoxNode)) then
		Logging.xmlWarning(xmlFile, "Invalid camera shadow focus box \'%s\'. Must be a shape and cpu mesh", getName(self.shadowFocusBoxNode))
		self.shadowFocusBoxNode = nil
	end
	if Platform.gameplay.hasShadowFocusBox then
		if self.isInside and self.shadowFocusBoxNode == nil then
			Logging.xmlDevWarning(xmlFile, "Missing shadow focus box for indoor camera \'%s\'", key)
		end
	elseif self.shadowFocusBoxNode ~= nil then
		Logging.xmlDevWarning(xmlFile, "Shadow focus box for camera \'%s\' not allowed on this platform", key)
		self.shadowFocusBoxNode = nil
	end
	self.isInside = xmlFile:getValue(key .. "#isInside", false)
	self.allowHeadTracking = xmlFile:getValue(key .. "#allowHeadTracking", self.isInside)
	self.useOutdoorSounds = xmlFile:getValue(key .. "#useOutdoorSounds", not self.isInside)
	local v11_ = self.isInside
	local v12_
	if self.isInside then
		v12_ = nil
	else
		v12_ = g_depthOfFieldManager:createInfo(0.5, 1, 0.3, 400, 1400, false)
	end
	g_cameraManager:addCamera(self.cameraNode, self.shadowFocusBoxNode, false, v11_, v12_)
	if self.isInside then
		self.collisionNodes = {}
		I3DUtil.iterateRecursively(self.vehicle.rootNode, function(p13_)
			-- upvalues: (copy) self
			if getHasClassId(p13_, ClassIds.SHAPE) and (getRigidBodyType(p13_) ~= RigidBodyType.NONE or getIsCompoundChild(p13_)) then
				local v14_ = getCollisionFilterGroup(p13_)
				local v15_ = CollisionFlag.VEHICLE
				if bit32.btest(v14_, v15_) then
					local v16_ = self.collisionNodes
					table.insert(v16_, p13_)
				end
			end
		end, true)
	end
	self.defaultFovY = getFovY(self.cameraNode)
	self.fovY = calculateFovY(self.defaultFovY)
	setFovY(self.cameraNode, self.fovY)
	self.isRotatable = xmlFile:getValue(key .. "#rotatable", false)
	self.limit = xmlFile:getValue(key .. "#limit", false)
	if self.limit then
		self.rotMinX = xmlFile:getValue(key .. "#rotMinX")
		self.rotMaxX = xmlFile:getValue(key .. "#rotMaxX")
		self.transMin = xmlFile:getValue(key .. "#transMin")
		self.transMax = xmlFile:getValue(key .. "#transMax")
		if self.transMax ~= nil then
			local v17_ = self.transMin
			local v18_ = self.transMax * Platform.gameplay.maxCameraZoomFactor
			self.transMax = math.max(v17_, v18_)
		end
		if self.rotMinX == nil or (self.rotMaxX == nil or (self.transMin == nil or self.transMax == nil)) then
			Logging.xmlWarning(xmlFile, "Missing \'rotMinX\', \'rotMaxX\', \'transMin\' or \'transMax\' for camera \'%s\'", key)
			return false
		end
	end
	if self.isRotatable then
		self.rotateNode = xmlFile:getValue(key .. "#rotateNode", nil, self.vehicle.components, self.vehicle.i3dMappings)
		self.hasExtraRotationNode = self.rotateNode ~= nil
	end
	local v19_ = xmlFile:getValue(key .. "#rotation", nil, true)
	if v19_ ~= nil then
		local v20_ = self.cameraNode
		if self.rotateNode ~= nil then
			v20_ = self.rotateNode
		end
		setRotation(v20_, unpack(v19_))
	end
	local v21_ = xmlFile:getValue(key .. "#translation", nil, true)
	if v21_ ~= nil then
		setTranslation(self.cameraNode, unpack(v21_))
	end
	local v22_
	if self.rotateNode == nil then
		v22_ = false
	else
		v22_ = self.rotateNode ~= self.cameraNode
	end
	self.allowTranslation = v22_
	self.useMirror = xmlFile:getValue(key .. "#useMirror", false)
	self.useWorldXZRotation = xmlFile:getValue(key .. "#useWorldXZRotation")
	self.resetCameraOnVehicleSwitch = xmlFile:getValue(key .. "#resetCameraOnVehicleSwitch")
	self.suspensionNodeIndex = xmlFile:getValue(key .. "#suspensionNodeIndex")
	if not Platform.gameplay.useWorldCameraInside and self.isInside or not (Platform.gameplay.useWorldCameraOutside or self.isInside) then
		self.useWorldXZRotation = false
	end
	self.positionSmoothingParameter = 0
	self.lookAtSmoothingParameter = 0
	if xmlFile:getValue(key .. "#useDefaultPositionSmoothing", true) then
		if self.isInside then
			self.positionSmoothingParameter = 0.128
			self.lookAtSmoothingParameter = 0.176
		else
			self.positionSmoothingParameter = 0.016
			self.lookAtSmoothingParameter = 0.022
		end
	end
	self.positionSmoothingParameter = xmlFile:getValue(key .. "#positionSmoothingParameter", self.positionSmoothingParameter)
	self.lookAtSmoothingParameter = xmlFile:getValue(key .. "#lookAtSmoothingParameter", self.lookAtSmoothingParameter)
	local v23_ = g_gameSettings:getValue(GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED) and isHeadTrackingAvailable()
	if v23_ then
		v23_ = self.allowHeadTracking
	end
	if v23_ then
		self.positionSmoothingParameter = 0
		self.lookAtSmoothingParameter = 0
	end
	self.cameraPositionNode = self.cameraNode
	if self.positionSmoothingParameter > 0 then
		self.cameraPositionNode = createTransformGroup("cameraPositionNode")
		local v24_ = getChildIndex(self.cameraNode)
		link(getParent(self.cameraNode), self.cameraPositionNode, v24_)
		local v25_, v26_, v27_ = getTranslation(self.cameraNode)
		local v28_, v29_, v30_ = getRotation(self.cameraNode)
		setTranslation(self.cameraPositionNode, v25_, v26_, v27_)
		setRotation(self.cameraPositionNode, v28_, v29_, v30_)
		self.cameraWorldParent = createTransformGroup("cameraWorldParent")
		link(self.cameraWorldParent, self.cameraNode)
	end
	self.rotYSteeringRotSpeed = xmlFile:getValue(key .. "#rotYSteeringRotSpeed", 0)
	if self.rotateNode == nil or self.rotateNode == self.cameraNode then
		self.rotateNode = self.cameraPositionNode
	end
	if v23_ then
		local v31_, _, v32_ = localDirectionToLocal(self.cameraPositionNode, getParent(self.cameraPositionNode), 0, 0, 1)
		local v33_, v34_, v35_ = localToLocal(self.cameraPositionNode, getParent(self.cameraPositionNode), 0, 0, 0)
		self.headTrackingNode = createTransformGroup("headTrackingNode")
		link(getParent(self.cameraPositionNode), self.headTrackingNode)
		setTranslation(self.headTrackingNode, v33_, v34_, v35_)
		if math.abs(v31_) + math.abs(v32_) > 0.0001 then
			setDirection(self.headTrackingNode, v31_, 0, v32_, 0, 1, 0)
		else
			setRotation(self.headTrackingNode, 0, 0, 0)
		end
	end
	local v36_, v37_, v38_ = getRotation(self.rotateNode)
	self.origRotX = v36_
	self.origRotY = v37_
	self.origRotZ = v38_
	self.rotX = self.origRotX
	self.rotY = self.origRotY
	self.rotZ = self.origRotZ
	local v39_, v40_, v41_ = getTranslation(self.cameraPositionNode)
	self.origTransX = v39_
	self.origTransY = v40_
	self.origTransZ = v41_
	self.transX = self.origTransX
	self.transY = self.origTransY
	self.transZ = self.origTransZ
	local v42_ = MathUtil.vector3Length(self.origTransX, self.origTransY, self.origTransZ) + 0.00001
	self.zoom = v42_
	self.zoomTarget = v42_
	self.zoomDefault = v42_
	self.zoomLimitedTarget = -1
	local v43_ = 1 / v42_
	self.transDirX = v43_ * self.origTransX
	self.transDirY = v43_ * self.origTransY
	self.transDirZ = v43_ * self.origTransZ
	if self.allowTranslation and v42_ <= 0.01 then
		Logging.xmlWarning(xmlFile, "Invalid camera translation for camera \'%s\'. Distance needs to be bigger than 0.01", key)
	end
	local v44_ = self.raycastNodes
	local v45_ = self.rotateNode
	table.insert(v44_, v45_)
	for _, v46_ in xmlFile:iterator(key .. ".raycastNode") do
		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.vehicle.configFileName, v46_ .. "#index", v46_ .. "#node")
		local v47_ = xmlFile:getValue(v46_ .. "#node", nil, self.vehicle.components, self.vehicle.i3dMappings)
		if v47_ ~= nil then
			local v48_ = self.raycastNodes
			table.insert(v48_, v47_)
		end
	end
	local v49_, v50_, v51_ = getScale(self.cameraNode)
	if v49_ ~= 1 or (v50_ ~= 1 or v51_ ~= 1) then
		Logging.xmlWarning(xmlFile, "Vehicle camera with scale found for camera \'%s\'. Resetting to scale 1", key)
		setScale(self.cameraNode, 1, 1, 1)
	end
	self.changeObjects = {}
	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, self.changeObjects, self.vehicle.components, self.vehicle)
	ObjectChangeUtil.setObjectChanges(self.changeObjects, false, self.vehicle, self.vehicle.setMovingToolDirty)
	if (not g_gameSettings:getValue(GameSettings.SETTING.RESET_CAMERA) or g_currentMission.vehicleSystem.isReloadRunning) and (savegame ~= nil and not savegame.resetVehicles) then
		local v52_ = string.format(savegame.key .. ".enterable.camera(%d)", cameraIndex)
		if savegame.xmlFile:hasProperty(v52_) then
			local v53_, v54_, v55_ = savegame.xmlFile:getValue(v52_ .. "#rotation", { self.rotX, self.rotY, self.rotZ })
			if not (MathUtil.isNan(v53_) or (MathUtil.isNan(v54_) or MathUtil.isNan(v55_))) then
				self.rotX = v53_
				self.rotY = v54_
				self.rotZ = v55_
				if self.allowTranslation then
					local v56_, v57_, v58_ = savegame.xmlFile:getValue(v52_ .. "#translation", { self.transX, self.transY, self.transZ })
					self.transX = v56_
					self.transY = v57_
					self.transZ = v58_
					self.zoom = savegame.xmlFile:getValue(v52_ .. "#zoom", self.zoom)
					self.zoomTarget = self.zoom
				end
				setTranslation(self.cameraPositionNode, self.transX, self.transY, self.transZ)
				setRotation(self.rotateNode, self.rotX, self.rotY, self.rotZ)
				if g_currentMission.vehicleSystem.isReloadRunning then
					local v59_ = savegame.xmlFile:getValue(v52_ .. "#fovY")
					if v59_ ~= nil then
						setFovY(self.cameraNode, v59_)
					end
				end
				self.lodDebugModeLoaded = savegame.xmlFile:getValue(v52_ .. "#lodDebugActive", false)
				if self.lodDebugModeLoaded then
					self.loadDebugZoom = savegame.xmlFile:getValue(v52_ .. "#lodDebugZoom", self.zoom)
				end
			end
		end
	end
	return true
end

-- Local values: yOffset, transLength, trans1OverLength
function VehicleCamera:onPostLoad(savegame)
	self.suspensionNode = nil
	if self.suspensionNodeIndex ~= nil and self.vehicle.getSuspensionNodeFromIndex ~= nil then
		self.suspensionNode = self.vehicle:getSuspensionNodeFromIndex(self.suspensionNodeIndex)
		if self.suspensionNode == nil then
			Logging.warning("Vehicle Camera \'%s\' with invalid suspensionIndex \'%s\' found.", getName(self.cameraNode), self.suspensionNodeIndex)
		end
	end
	if self.suspensionNode ~= nil then
		if self.suspensionNode.node ~= nil then
			if self.suspensionNode.startTranslationOffset ~= nil then
				local v61_ = self.suspensionNode.startTranslationOffset[2]
				if v61_ ~= 0 then
					self.origTransY = self.origTransY + v61_
					self.transY = self.origTransY
					setTranslation(self.cameraPositionNode, self.origTransX, self.origTransY, self.origTransZ)
					local v62_ = MathUtil.vector3Length(self.origTransX, self.origTransY, self.origTransZ) + 0.00001
					self.zoom = v62_
					self.zoomTarget = v62_
					self.zoomDefault = v62_
					local v63_ = 1 / v62_
					self.transDirX = v63_ * self.origTransX
					self.transDirY = v63_ * self.origTransY
					self.transDirZ = v63_ * self.origTransZ
				end
			end
			self.cameraSuspensionParentNode = createTransformGroup("cameraSuspensionParentNode")
			link(self.suspensionNode.node, self.cameraSuspensionParentNode)
			setWorldTranslation(self.cameraSuspensionParentNode, getWorldTranslation(getParent(self.cameraPositionNode)))
			setWorldQuaternion(self.cameraSuspensionParentNode, getWorldQuaternion(getParent(self.cameraPositionNode)))
			self.cameraBaseParentNode = getParent(self.cameraPositionNode)
			self.lastActiveCameraSuspensionSetting = false
			return
		end
		Logging.warning("Vehicle Camera \'%s\' with invalid suspensionIndex \'%s\' found. CharacterTorso suspensions are not allowed.", getName(self.cameraNode), self.suspensionNodeIndex)
		self.suspensionNode = nil
	end
end

function VehicleCamera:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#rotation", self.rotX, self.rotY, self.rotZ)
	xmlFile:setValue(key .. "#translation", self.transX, self.transY, self.transZ)
	xmlFile:setValue(key .. "#zoom", self.zoom)
	xmlFile:setValue(key .. "#fovY", getFovY(self.cameraNode))
	if self.lodDebugMode then
		xmlFile:setValue(key .. "#lodDebugActive", true)
		xmlFile:setValue(key .. "#lodDebugZoom", self.loadDebugZoom)
	end
end

function VehicleCamera:delete()
	g_cameraManager:removeCamera(self.cameraNode)
	self:onDeactivate()
	if self.cameraNode ~= nil and self.positionSmoothingParameter > 0 then
		delete(self.cameraNode)
		self.cameraNode = nil
	end
	if self.cameraWorldParent ~= nil then
		delete(self.cameraWorldParent)
		self.cameraWorldParent = nil
	end
	g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA], self)
	g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FOV_Y], self)
	g_messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.CAMERA_CHECK_COLLISION], self)
end

-- Local values: transMin, transMax, zoomTarget
function VehicleCamera:zoomSmoothly(offset)
	local v70_ = self.transMin
	local v71_ = self.transMax
	if self.lodDebugMode then
		offset = offset * 10
	end
	local v72_ = self.zoomTarget
	if v70_ ~= nil and (v71_ ~= nil and v70_ ~= v71_) then
		local v73_ = self.zoomTarget + offset
		local v74_ = math.max(v70_, v73_)
		v72_ = math.min(v71_, v74_)
	end
	self.zoomTarget = v72_
end

function VehicleCamera:raycastCallback(transformId, x, y, z, distance, nx, ny, nz)
	self.raycastDistance = distance
	self.normalX = nx
	self.normalY = ny
	self.normalZ = nz
	self.raycastTransformId = transformId
end

-- Local values: target, value, value, tx, ty, tz, pitch, yaw, roll, camParent, ctx, cty, ctz, crx, cry, crz, numIterations, _, transX, transY, transZ, x, y, z, terrainHeight, minHeight, h, h2, hasCollision, collisionDistance, nx, ny, nz, normalDotDir, distOffset, absNormalDotDir, _, lny, _, interpDt, xlook, ylook, zlook, lookAtPos, lookAtLastPos, x, y, z, pos, lastPos, upx, upy, upz, up, lastUp
function VehicleCamera:update(dt)
	local v83_ = self.zoomTarget
	if self.zoomLimitedTarget >= 0 then
		local v84_ = self.zoomLimitedTarget
		local v85_ = self.zoomTarget
		v83_ = math.min(v84_, v85_)
	end
	self.zoom = v83_ + math.pow(0.99579, dt) * (self.zoom - v83_)
	if self.lastInputValues.upDown ~= 0 then
		local v86_ = self.lastInputValues.upDown * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
		self.lastInputValues.upDown = 0
		if g_gameSettings:getValue(GameSettings.SETTING.INVERT_Y_LOOK) then
			v86_ = -v86_ or v86_
		end
		if self.isRotatable and (self.isActivated and not g_gui:getIsGuiVisible()) then
			if self.limitRotXDelta > 0.001 then
				local v87_ = self.rotX - v86_
				local v88_ = self.rotX
				self.rotX = math.min(v87_, v88_)
			elseif self.limitRotXDelta < -0.001 then
				local v89_ = self.rotX - v86_
				local v90_ = self.rotX
				self.rotX = math.max(v89_, v90_)
			else
				self.rotX = self.rotX - v86_
			end
			if self.limit then
				local v91_ = self.rotMaxX
				local v92_ = self.rotMinX
				local v93_ = self.rotX
				local v94_ = math.max(v92_, v93_)
				self.rotX = math.min(v91_, v94_)
			end
		end
	end
	if self.lastInputValues.leftRight ~= 0 or self.autoRotateOverride then
		local v95_ = self.autoRotateOverride or self.lastInputValues.leftRight * g_gameSettings:getValue(GameSettings.SETTING.CAMERA_SENSITIVITY)
		self.lastInputValues.leftRight = 0
		if self.isRotatable and (self.isActivated and not g_gui:getIsGuiVisible()) then
			self.rotY = self.rotY - v95_
		end
	end
	if g_gameSettings:getValue(GameSettings.SETTING.IS_HEAD_TRACKING_ENABLED) and (isHeadTrackingAvailable() and (self.allowHeadTracking and self.headTrackingNode ~= nil)) then
		local v96_, v97_, v98_ = getHeadTrackingTranslation()
		local v99_, v100_, v101_ = getHeadTrackingRotation()
		if v99_ ~= nil then
			local v102_ = getParent(self.cameraNode)
			local v103_, v104_, v105_, v106_, v107_, v108_
			if v102_ == 0 then
				v103_, v104_, v105_ = localToWorld(self.headTrackingNode, v96_, v97_, v98_)
				v106_, v107_, v108_ = localRotationToWorld(self.headTrackingNode, v99_, v100_, v101_)
			else
				v103_, v104_, v105_ = localToLocal(self.headTrackingNode, v102_, v96_, v97_, v98_)
				v106_, v107_, v108_ = localRotationToLocal(self.headTrackingNode, v102_, v99_, v100_, v101_)
			end
			setRotation(self.cameraNode, v106_, v107_, v108_)
			setTranslation(self.cameraNode, v103_, v104_, v105_)
		end
	else
		self:updateRotateNodeRotation()
		if self.limit then
			if self.isRotatable and (self.useWorldXZRotation == nil and g_gameSettings:getValue(GameSettings.SETTING.USE_WORLD_CAMERA) or self.useWorldXZRotation) then
				for _ = 1, 4 do
					local v109_ = self.transDirX * self.zoom
					local v110_ = self.transDirY * self.zoom
					local v111_ = self.transDirZ * self.zoom
					local v112_, v113_, v114_ = localToWorld(getParent(self.cameraPositionNode), v109_, v110_, v111_)
					local v115_ = DensityMapHeightUtil.getHeightAtWorldPos(v112_, 0, v114_) + 0.9
					if v113_ >= v115_ then
						break
					end
					local v116_ = self.rotX
					local v117_ = (math.sin(v116_) * self.zoom - (v115_ - v113_)) / self.zoom
					local v118_ = math.clamp(v117_, -1, 1)
					self.rotX = math.asin(v118_)
					self:updateRotateNodeRotation()
				end
			end
			if self.allowTranslation then
				self.limitRotXDelta = 0
				local v119_, v120_, v121_, v122_, v123_, v124_ = self:getCollisionDistance()
				if v119_ then
					local v125_
					if v124_ == nil then
						v125_ = 0.1
					else
						local v126_ = math.abs(v124_)
						v125_ = MathUtil.lerp(1.2, 0.1, v126_ * v126_ * (3 - 2 * v126_))
					end
					local v127_ = v120_ - v125_
					local v128_ = math.max(v127_, 0.01)
					self.disableCollisionTime = g_currentMission.time + 400
					self.zoomLimitedTarget = v128_
					if v128_ < self.zoom then
						self.zoom = v128_
					end
					if self.isRotatable and (v121_ ~= nil and v128_ < self.transMin) then
						local _, v129_, _ = worldDirectionToLocal(self.rotateNode, v121_, v122_, v123_)
						if v129_ > 0.5 then
							self.limitRotXDelta = 1
						elseif v129_ < -0.5 then
							self.limitRotXDelta = -1
						end
					end
				elseif self.disableCollisionTime <= g_currentMission.time then
					self.zoomLimitedTarget = -1
				end
			end
		end
		local v130_ = self.transDirX * self.zoom
		local v131_ = self.transDirY * self.zoom
		local v132_ = self.transDirZ * self.zoom
		self.transX = v130_
		self.transY = v131_
		self.transZ = v132_
		setTranslation(self.cameraPositionNode, self.transX, self.transY, self.transZ)
		if self.positionSmoothingParameter > 0 then
			local v133_ = g_physicsDt
			if self.vehicle.spec_rideable ~= nil then
				v133_ = self.vehicle.spec_rideable.interpolationDt
			end
			if g_server ~= nil then
				dt = v133_
			end
			if dt > 0 then
				local v134_, v135_, v136_ = getWorldTranslation(self.rotateNode)
				local v137_ = self.lookAtPosition
				local v138_ = self.lookAtLastTargetPosition
				local v139_, v140_, v141_ = self:getSmoothed(self.lookAtSmoothingParameter, v137_[1], v137_[2], v137_[3], v134_, v135_, v136_, v138_[1], v138_[2], v138_[3], dt)
				v137_[1] = v139_
				v137_[2] = v140_
				v137_[3] = v141_
				v138_[1] = v134_
				v138_[2] = v135_
				v138_[3] = v136_
				local v142_, v143_, v144_ = getWorldTranslation(self.cameraPositionNode)
				local v145_ = self.position
				local v146_ = self.lastTargetPosition
				local v147_, v148_, v149_ = self:getSmoothed(self.positionSmoothingParameter, v145_[1], v145_[2], v145_[3], v142_, v143_, v144_, v146_[1], v146_[2], v146_[3], dt)
				v145_[1] = v147_
				v145_[2] = v148_
				v145_[3] = v149_
				v146_[1] = v142_
				v146_[2] = v143_
				v146_[3] = v144_
				local v150_, v151_, v152_ = localDirectionToWorld(self.rotateNode, self:getTiltDirectionOffset(), 1, 0)
				local v153_ = self.upVector
				local v154_ = self.lastUpVector
				local v155_, v156_, v157_ = self:getSmoothed(self.positionSmoothingParameter, v153_[1], v153_[2], v153_[3], v150_, v151_, v152_, v154_[1], v154_[2], v154_[3], dt)
				v153_[1] = v155_
				v153_[2] = v156_
				v153_[3] = v157_
				v154_[1] = v150_
				v154_[2] = v151_
				v154_[3] = v152_
				self:setSeparateCameraPose()
			end
		end
	end
	if MathUtil.isNan(self.rotX) or (MathUtil.isNan(self.rotY) or MathUtil.isNan(self.rotZ)) then
		self:resetCamera()
	end
end

-- Local values: dtLooped, dtDirect, invDt, velX, velY, velZ, velScale, posScale, newX, newY, newZ, i
function VehicleCamera:getSmoothed(alpha, curX, curY, curZ, targetX, targetY, targetZ, lastTargetX, lastTargetY, lastTargetZ, dt)
	local v169_ = dt - 6
	local v170_ = math.floor(v169_)
	local v171_ = math.max(v170_, 0)
	local v172_ = dt - v171_
	local v173_ = 1 / dt
	local v174_ = (targetX - lastTargetX) * v173_
	local v175_ = (targetY - lastTargetY) * v173_
	local v176_ = (targetZ - lastTargetZ) * v173_
	local v177_ = 1 - alpha
	local v178_ = 1 + v172_
	local v179_ = math.pow(v177_, v178_) + (1 + v172_) * alpha - 1
	local v180_ = 1 - alpha
	local v181_ = math.pow(v180_, v172_)
	local v182_ = (v179_ * v174_ + alpha * (v181_ * (curX - lastTargetX) + lastTargetX)) / alpha
	local v183_ = (v179_ * v175_ + alpha * (v181_ * (curY - lastTargetY) + lastTargetY)) / alpha
	local v184_ = (v179_ * v176_ + alpha * (v181_ * (curZ - lastTargetZ) + lastTargetZ)) / alpha
	for v185_ = 1, v171_ do
		v182_ = v182_ + (lastTargetX + v174_ * (v185_ + v172_) - v182_) * alpha
		v183_ = v183_ + (lastTargetY + v175_ * (v185_ + v172_) - v183_) * alpha
		v184_ = v184_ + (lastTargetZ + v176_ * (v185_ + v172_) - v184_) * alpha
	end
	return v182_, v183_, v184_
end

-- Local values: rx, ry, rz, xlook, ylook, zlook, x, y, z, upx, upy, upz, _, actionEventId1, _, actionEventId2
function VehicleCamera:onActivate()
	if self.cameraNode ~= nil then
		if g_addCheatCommands then
			addConsoleCommand("gsCameraAutoRotate", "Auto rotate vehicle outdoor camera", "consoleCommandSetAutoRotate", self, "speed")
			addConsoleCommand("gsCameraOffset", "Offset vehicle outdoor camera target", "consoleCommandSetOffset", self, "x; y; z")
			addConsoleCommand("gsCameraRotationSaveLoad", "Save and load current camera rotation + zoom", "consoleCommandRotationSaveLoad", self)
		end
		self:onActiveCameraSuspensionSettingChanged(g_gameSettings:getValue(GameSettings.SETTING.ACTIVE_SUSPENSION_CAMERA))
		self.isActivated = true
		if not g_currentMission.vehicleSystem.isReloadRunning and (self.resetCameraOnVehicleSwitch == nil and g_gameSettings:getValue(GameSettings.SETTING.RESET_CAMERA) or self.resetCameraOnVehicleSwitch) then
			self:resetCamera()
		end
		if g_cameraManager:getActiveCamera() ~= self.cameraNode then
			g_cameraManager:setActiveCamera(self.cameraNode)
		end
		local v187_, v188_, v189_ = getWorldRotation(self.rotateNode)
		if MathUtil.isNan(v187_) or (MathUtil.isNan(v188_) or MathUtil.isNan(v189_)) then
			self:resetCamera()
		end
		if self.positionSmoothingParameter > 0 then
			local v190_, v191_, v192_ = getWorldTranslation(self.rotateNode)
			local v193_ = v190_ + (self.offsetX or 0)
			local v194_ = v191_ + (self.offsetY or 0)
			local v195_ = v192_ + (self.offsetZ or 0)
			self.lookAtPosition[1] = v193_
			self.lookAtPosition[2] = v194_
			self.lookAtPosition[3] = v195_
			self.lookAtLastTargetPosition[1] = v193_
			self.lookAtLastTargetPosition[2] = v194_
			self.lookAtLastTargetPosition[3] = v195_
			local v196_, v197_, v198_ = getWorldTranslation(self.cameraPositionNode)
			self.position[1] = v196_
			self.position[2] = v197_
			self.position[3] = v198_
			self.lastTargetPosition[1] = v196_
			self.lastTargetPosition[2] = v197_
			self.lastTargetPosition[3] = v198_
			local v199_, v200_, v201_ = localDirectionToWorld(self.rotateNode, self:getTiltDirectionOffset(), 1, 0)
			self.upVector[1] = v199_
			self.upVector[2] = v200_
			self.upVector[3] = v201_
			self.lastUpVector[1] = v199_
			self.lastUpVector[2] = v200_
			self.lastUpVector[3] = v201_
			setWorldRotation(self.cameraNode, v187_, v188_, v189_)
			setWorldTranslation(self.cameraNode, v196_, v197_, v198_)
		end
		self.lastInputValues = {}
		self.lastInputValues.upDown = 0
		self.lastInputValues.leftRight = 0
		g_inputBinding:beginActionEventsModification(Vehicle.INPUT_CONTEXT_NAME)
		local _, v202_ = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_VEHICLE, self, VehicleCamera.actionEventLookUpDown, false, false, true, true, nil)
		local _, v203_ = g_inputBinding:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, self, VehicleCamera.actionEventLookLeftRight, false, false, true, true, nil)
		g_inputBinding:setActionEventTextVisibility(v202_, false)
		g_inputBinding:setActionEventTextVisibility(v203_, false)
		g_inputBinding:endActionEventsModification()
		ObjectChangeUtil.setObjectChanges(self.changeObjects, true, self.vehicle, self.vehicle.setMovingToolDirty)
		self:updatePrecipitationCollisions(true)
		if g_touchHandler ~= nil then
			self.touchListenerPinch = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_PINCH, VehicleCamera.touchEventZoomInOut, self)
			self.touchListenerY = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_AXIS_Y, VehicleCamera.touchEventLookUpDown, self)
			self.touchListenerX = g_touchHandler:registerGestureListener(TouchHandler.GESTURE_AXIS_X, VehicleCamera.touchEventLookLeftRight, self)
		end
		g_activeVehicleCamera = self
		if self.lodDebugModeLoaded then
			self:setLODDebugState(self.lodDebugModeLoaded, self.loadDebugZoom)
			self.lodDebugModeLoaded = nil
		end
	end
end

function VehicleCamera:setLODDebugState(state, zoom)
	if state ~= self.lodDebugMode then
		self.lodDebugMode = state
		if self.lodDebugMode then
			self.transMaxOrig = self.transMax
			self.transMax = 350
			self.loadDebugZoom = zoom or self.zoom
			setViewDistanceCoeff(1)
			setLODDistanceCoeff(1)
			setTerrainLODDistanceCoeff(1)
			return
		end
		self.transMax = self.transMaxOrig
		self.zoomTarget = self.zoomDefault
		self.zoom = self.zoomDefault
		setFovY(self.cameraNode, self.fovY)
		setViewDistanceCoeff(g_settingsModel.percentValues[g_settingsModel:getValue(SettingsModel.SETTING.OBJECT_DRAW_DISTANCE)])
		setLODDistanceCoeff(g_settingsModel.percentValues[g_settingsModel:getValue(SettingsModel.SETTING.LOD_DISTANCE)])
		setTerrainLODDistanceCoeff(g_settingsModel.percentValues[g_settingsModel:getValue(SettingsModel.SETTING.TERRAIN_LOD_DISTANCE)])
	end
end

function VehicleCamera:setCameraYDebugState(state, height)
	if state ~= self.cameraYDebugMode then
		self.cameraYDebugMode = state
		if self.cameraYDebugMode then
			self.cameraYDebugHeight = tonumber(height) or 5
			self.cameraYDebugZoom = self.zoom
			self.rotX = 0
			self.rotY = 1.5707963267948966
			self.rotZ = 0
			setRotation(self.rotateNode, self.rotX, self.rotY, self.rotZ)
			setIsOrthographic(self.cameraNode, true)
			setOrthographicHeight(self.cameraNode, tonumber(height) or 5)
			self.isRotatable = false
			g_currentMission.hud:setIsVisible(false)
			return
		end
		self.isRotatable = true
		setIsOrthographic(self.cameraNode, false)
		if self == g_activeVehicleCamera then
			g_currentMission.hud:setIsVisible(true)
		end
	end
end

function VehicleCamera:onDeactivate()
	self.isActivated = false
	removeConsoleCommand("gsCameraAutoRotate")
	removeConsoleCommand("gsCameraOffset")
	removeConsoleCommand("gsCameraRotationSaveLoad")
	g_inputBinding:beginActionEventsModification(Vehicle.INPUT_CONTEXT_NAME)
	g_inputBinding:removeActionEventsByTarget(self)
	g_inputBinding:endActionEventsModification()
	ObjectChangeUtil.setObjectChanges(self.changeObjects, false, self.vehicle, self.vehicle.setMovingToolDirty)
	self:updatePrecipitationCollisions(false)
	if g_touchHandler ~= nil then
		g_touchHandler:removeGestureListener(self.touchListenerPinch)
		g_touchHandler:removeGestureListener(self.touchListenerY)
		g_touchHandler:removeGestureListener(self.touchListenerX)
	end
	if self.lodDebugMode then
		self:setLODDebugState(false)
	end
	if g_activeVehicleCamera == self then
		g_activeVehicleCamera = nil
	end
end

-- Local values: _, col, oldGroup, newGroup
function VehicleCamera:updatePrecipitationCollisions(isActive)
	if self.collisionNodes ~= nil then
		for _, v213_ in ipairs(self.collisionNodes) do
			local v214_ = getCollisionFilterGroup(v213_)
			local v215_
			if isActive then
				local v216_ = CollisionFlag.PRECIPITATION_BLOCKING
				v215_ = bit32.bor(v214_, v216_)
			else
				local v217_ = CollisionFlag.PRECIPITATION_BLOCKING
				local v218_ = bit32.bnot(v217_)
				v215_ = bit32.band(v214_, v218_)
			end
			setCollisionFilterGroup(v213_, v215_)
		end
	end
end

function VehicleCamera:actionEventLookUpDown(actionName, inputValue, callbackState, isAnalog, isMouse)
	local v222_
	if isMouse then
		v222_ = inputValue * 0.001 * 16.666
	else
		v222_ = inputValue * 0.001 * g_currentDt
	end
	self.lastInputValues.upDown = self.lastInputValues.upDown + v222_
end

-- Local values: factor
function VehicleCamera:touchEventLookUpDown(value)
	if self.isActivated then
		local v225_ = g_screenHeight * g_pixelSizeX * -75
		VehicleCamera.actionEventLookUpDown(self, nil, value * v225_, nil, nil, false)
	end
end

function VehicleCamera:touchEventZoomInOut(value)
	if self.isActivated then
		self:zoomSmoothly(value * 15)
	end
end

-- Local values: factor
function VehicleCamera:touchEventLookLeftRight(value)
	if self.isActivated then
		local v230_ = g_screenAspectRatio * 75
		VehicleCamera.actionEventLookLeftRight(self, nil, value * v230_, nil, nil, false)
	end
end

function VehicleCamera:actionEventLookLeftRight(actionName, inputValue, callbackState, isAnalog, isMouse)
	local v234_
	if isMouse then
		v234_ = inputValue * 0.001 * 16.666
	else
		v234_ = inputValue * 0.001 * g_currentDt
	end
	self.lastInputValues.leftRight = self.lastInputValues.leftRight + v234_
end

-- Local values: transLength, xlook, ylook, zlook, x, y, z
function VehicleCamera:resetCamera()
	self.rotX = self.origRotX
	self.rotY = self.origRotY
	self.rotZ = self.origRotZ
	self.transX = self.origTransX
	self.transY = self.origTransY
	self.transZ = self.origTransZ
	local v236_ = MathUtil.vector3Length(self.origTransX, self.origTransY, self.origTransZ)
	self.zoom = v236_
	self.zoomTarget = v236_
	self.zoomLimitedTarget = -1
	self:updateRotateNodeRotation()
	setTranslation(self.cameraPositionNode, self.transX, self.transY, self.transZ)
	if self.positionSmoothingParameter > 0 then
		local v237_, v238_, v239_ = getWorldTranslation(self.rotateNode)
		self.lookAtPosition[1] = v237_ + (self.offsetX or 0)
		self.lookAtPosition[2] = v238_ + (self.offsetY or 0)
		self.lookAtPosition[3] = v239_ + (self.offsetZ or 0)
		local v240_, v241_, v242_ = getWorldTranslation(self.cameraPositionNode)
		self.position[1] = v240_
		self.position[2] = v241_
		self.position[3] = v242_
		self:setSeparateCameraPose()
	end
end

-- Local values: rotY, vehicleDirectionX, _, vehicleDirectionZ, newDx, newDy, newDz, upx, upy, upz
function VehicleCamera:updateRotateNodeRotation()
	local v244_ = self.rotY
	if self.rotYSteeringRotSpeed ~= nil and (self.rotYSteeringRotSpeed ~= 0 and (self.vehicle.spec_articulatedAxis ~= nil and self.vehicle.spec_articulatedAxis.interpolatedRotatedTime ~= nil)) then
		v244_ = v244_ + self.vehicle.spec_articulatedAxis.interpolatedRotatedTime * self.rotYSteeringRotSpeed
	end
	if self.useWorldXZRotation == nil and g_gameSettings:getValue(GameSettings.SETTING.USE_WORLD_CAMERA) or self.useWorldXZRotation then
		local v245_, _, v246_ = localDirectionToWorld(getParent(self.rotateNode), 0, 0, 1)
		local v247_, v248_ = MathUtil.vector2Normalize(v245_, v246_)
		local v249_ = self.rotX
		local v250_ = math.cos(v249_) * (math.cos(v244_) * v247_ + math.sin(v244_) * v248_)
		local v251_ = self.rotX
		local v252_ = -math.sin(v251_)
		local v253_ = self.rotX
		local v254_ = math.cos(v253_) * (-math.sin(v244_) * v247_ + math.cos(v244_) * v248_)
		local v255_, v256_, v257_ = worldDirectionToLocal(getParent(self.rotateNode), v250_, v252_, v254_)
		local v258_, v259_, v260_ = worldDirectionToLocal(getParent(self.rotateNode), 0, 1, 0)
		local v261_ = MathUtil.dotProduct(v255_, v256_, v257_, v258_, v259_, v260_)
		if math.abs(v261_) > 0.99 * MathUtil.vector3Length(v255_, v256_, v257_) * MathUtil.vector3Length(v258_, v259_, v260_) then
			setRotation(self.rotateNode, self.rotX, v244_, self.rotZ)
		else
			setDirection(self.rotateNode, v255_, v256_, v257_, v258_, v259_, v260_)
		end
	else
		setRotation(self.rotateNode, self.rotX, v244_, self.rotZ)
		return
	end
end

-- Local values: dx, dy, dz, wdx, wdz, upx, upy, upz, dx, dy, dz, upx, upy, upz, _, _, curZoom, l, mouseButtonLast, mouseButtonStateLast
function VehicleCamera:setSeparateCameraPose()
	if self.rotateNode == self.cameraPositionNode then
		local v263_, v264_, v265_ = localDirectionToWorld(self.rotateNode, 0, 0, 1)
		local v266_, v267_, v268_ = localDirectionToWorld(self.rotateNode, self:getTiltDirectionOffset(), 1, 0)
		setWorldDirection(self.cameraNode, v263_, v264_, v265_, v266_, v267_, v268_)
	else
		local v269_ = self.position[1] - self.lookAtPosition[1]
		local v270_ = self.position[2] - self.lookAtPosition[2]
		local v271_ = self.position[3] - self.lookAtPosition[3]
		local v272_, v273_ = MathUtil.vector2Normalize(v269_, v271_)
		setDirection(self.cameraWorldParent, v272_, 0, v273_, 0, 1, 0)
		local v274_ = self.upVector
		local v275_, v276_, v277_ = unpack(v274_)
		local v278_ = v275_ == 0 and (v276_ == 0 and v277_ == 0) and 1 or v276_
		local v279_ = math.abs(v269_) < 0.001 and math.abs(v271_) < 0.001 and 0.1 or v275_
		local v280_, v281_, v282_ = MathUtil.vector3Normalize(v269_, v270_, v271_)
		local v283_, v284_, v285_ = MathUtil.vector3Normalize(v279_, v278_, v277_)
		setWorldDirection(self.cameraNode, v280_, v281_, v282_, v283_, v284_, v285_)
	end
	setWorldTranslation(self.cameraNode, self.position[1], self.position[2], self.position[3])
	if self.lodDebugMode then
		local _, _, v286_ = localToLocal(self.cameraNode, self.rotateNode, 0, 0, 0)
		local v287_ = self.fovY
		local v288_ = math.atan(v287_) * self.loadDebugZoom
		local v289_, v290_ = g_inputBinding:getMouseButtonState()
		if v290_ and v289_ == Input.MOUSE_BUTTON_MIDDLE then
			setFovY(self.cameraNode, self.fovY)
		else
			local v291_ = setFovY
			local v292_ = self.cameraNode
			local v293_ = v288_ / math.max(v286_, v288_)
			v291_(v292_, (math.tan(v293_)))
		end
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(0.5, 0.1, 0.04, string.format("Distance: %d", self.zoom))
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
end

-- Local values: dx, dy, dz, tiltOffset
function VehicleCamera:getTiltDirectionOffset()
	if self.isInside or not (g_gameSettings:getValue(GameSettings.SETTING.CAMERA_TILTING) and getHasTouchpad()) then
		return 0
	end
	local v295_, v296_, v297_ = getGravityDirection()
	return MathUtil.getHorizontalRotationFromDeviceGravity(v295_, v296_, v297_)
end

-- Local values: raycastMask, targetCamX, targetCamY, targetCamZ, hasCollision, collisionDistance, normalX, normalY, normalZ, normalDotDir, _, raycastNode, nodeX, nodeY, nodeZ, dirX, dirY, dirZ, dirLength, startX, startY, startZ, currentDistance, minDistance, ndotd, object, ignoreObject, vehicles, i, vehicle, mountObject
function VehicleCamera:getCollisionDistance()
	if not self.isCollisionEnabled then
		return false, nil, nil, nil, nil, nil
	end
	local v299_ = VehicleCamera.raycastMask
	local v300_, v301_, v302_ = localToWorld(self.rotateNode, self.transDirX * self.zoomTarget, self.transDirY * self.zoomTarget, self.transDirZ * self.zoomTarget)
	local v303_ = -1
	local v304_ = nil
	local v305_ = nil
	local v306_ = nil
	local v307_ = nil
	local v308_ = false
	for _, v309_ in ipairs(self.raycastNodes) do
		local v310_, v311_, v312_ = getWorldTranslation(v309_)
		local v313_ = v300_ - v310_
		local v314_ = v301_ - v311_
		local v315_ = v302_ - v312_
		local v316_ = MathUtil.vector3Length(v313_, v314_, v315_)
		local v317_ = v313_ / v316_
		local v318_ = v314_ / v316_
		local v319_ = v315_ / v316_
		local v320_ = self.transMin
		local v321_ = v310_
		local v322_ = v311_
		local v323_ = v312_
		local v324_ = 0
		v308_ = false
		while true do
			if v316_ - v324_ <= 0 then
				v325_ = v307_
				break
			end
			self.raycastDistance = 0
			raycastClosest(v310_, v311_, v312_, v317_, v318_, v319_, v316_ - v324_, "raycastCallback", self, v299_)
			if self.raycastDistance == 0 then
				v325_ = v307_
				break
			end
			v324_ = v324_ + self.raycastDistance + 0.001
			local v325_ = MathUtil.dotProduct(self.normalX, self.normalY, self.normalZ, v317_, v318_, v319_)
			local v326_ = g_currentMission:getNodeObject(self.raycastTransformId)
			local v327_ = v326_ == self.vehicle
			if v326_ ~= nil and not v327_ then
				v327_ = v326_.rootVehicle == self.vehicle.rootVehicle and true or v327_
				if not v327_ then
					local v328_ = self.vehicle:getChildVehicles()
					for v329_ = 1, #v328_ do
						local v330_ = v328_[v329_]
						if v326_ ~= v330_ then
							local v331_ = v326_.dynamicMountObject or (v326_.tensionMountObject or v326_.mountObject)
							if v331_ ~= nil and (v331_ == v330_ or v331_.rootVehicle == v330_) then
								v327_ = true
								break
							end
						end
					end
				end
			end
			local v332_ = not v327_ and getHasClassId(self.raycastTransformId, ClassIds.MESH_SPLIT_SHAPE) and true or v327_
			if (v332_ or not getHasTrigger(self.raycastTransformId)) and not v332_ then
				v308_ = true
				if v309_ == self.rotateNode then
					v304_ = self.normalX
					v305_ = self.normalY
					v306_ = self.normalZ
					if getRigidBodyType(self.raycastTransformId) == RigidBodyType.STATIC then
						v303_ = v324_
					else
						local v333_ = self.transMin
						v303_ = math.max(v333_, v324_)
					end
				else
					v325_ = v307_
				end
				break
			end
			if v325_ > 0 then
				v320_ = math.max(v320_, v324_)
			end
			v310_ = v321_ + v317_ * v324_
			v311_ = v322_ + v318_ * v324_
			v312_ = v323_ + v319_ * v324_
		end
		if not v308_ then
			v307_ = v325_
		end
		v307_ = v325_
	end
	return v308_, v303_, v304_, v305_, v306_, v307_
end

function VehicleCamera:onActiveCameraSuspensionSettingChanged(newState)
	if self.suspensionNode ~= nil and self.lastActiveCameraSuspensionSetting ~= newState then
		if newState then
			link(self.cameraSuspensionParentNode, self.cameraPositionNode)
		else
			link(self.cameraBaseParentNode, self.cameraPositionNode)
		end
		self.lastActiveCameraSuspensionSetting = newState
	end
end

function VehicleCamera:onFovySettingChanged()
	if self.cameraNode ~= nil then
		self.fovY = calculateFovY(self.defaultFovY)
		setFovY(self.cameraNode, self.fovY)
	end
end

function VehicleCamera:onCameraCollisionDetectionSettingChanged(newState)
	self.isCollisionEnabled = newState
end

function VehicleCamera:consoleCommandSetAutoRotate(speed)
	local v341_ = tonumber(speed)
	if v341_ == nil or v341_ == 0 then
		self.autoRotateOverride = nil
	else
		self.autoRotateOverride = v341_ * 0.01
	end
	return string.format("VehicleCamera.autoRotateOverride %s", v341_)
end

-- Local values: lx, ly, lz, lx, ly, lz
function VehicleCamera:consoleCommandSetOffset(x, y, z)
	if self.rotNodePosBackup == nil then
		local v346_, v347_, v348_ = getTranslation(self.rotateNode)
		self.rotNodePosBackup = { v346_, v347_, v348_ }
	end
	local v349_ = tonumber(x) or 0
	local v350_ = tonumber(y) or 0
	local v351_ = tonumber(z) or 0
	local v352_ = self.rotNodePosBackup
	local v353_, v354_, v355_ = unpack(v352_)
	setTranslation(self.rotateNode, v353_ + v349_, v354_ + v350_, v355_ + v351_)
end

function VehicleCamera:consoleCommandRotationSaveLoad(load)
	if not load then
		self.rotBackup = { self.rotX, self.rotY, self.rotZ }
		self.transBackup = { self.transX, self.transY, self.transZ }
		self.zoomBackup = MathUtil.vector3Length(self.transX, self.transY, self.transZ) + 0.00001
		return "Saved current rotation for this vehicle. Use \'gsCameraRotationSaveLoad load\' to load"
	end
	if self.rotBackup == nil then
		return "Error: no position/rotation saved yet"
	end
	local v358_ = self.rotBackup
	local v359_, v360_, v361_ = unpack(v358_)
	self.rotX = v359_
	self.rotY = v360_
	self.rotZ = v361_
	local v362_ = self.transBackup
	local v363_, v364_, v365_ = unpack(v362_)
	self.transX = v363_
	self.transY = v364_
	self.transZ = v365_
	self.zoom = self.zoomBackup
	self.zoomTarget = self.zoomBackup
	return "Loaded rotation"
end

function VehicleCamera.registerCameraXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Camera node")
	schema:register(XMLValueType.BOOL, basePath .. "#rotatable", "Camera is rotatable", false)
	schema:register(XMLValueType.BOOL, basePath .. "#limit", "Has limits", false)
	schema:register(XMLValueType.FLOAT, basePath .. "#rotMinX", "Min. X rotation")
	schema:register(XMLValueType.FLOAT, basePath .. "#rotMaxX", "Max. X rotation")
	schema:register(XMLValueType.FLOAT, basePath .. "#transMin", "Min. Z translation")
	schema:register(XMLValueType.FLOAT, basePath .. "#transMax", "Max. Z translation")
	schema:register(XMLValueType.BOOL, basePath .. "#isInside", "Is camera inside. Used for camera smoothing and fallback/default value for \'useOutdoorSounds\'", false)
	schema:register(XMLValueType.BOOL, basePath .. "#allowHeadTracking", "Allow head tracking", "isInside value")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#shadowFocusBox", "Shadow focus box")
	schema:register(XMLValueType.BOOL, basePath .. "#useOutdoorSounds", "Use outdoor sounds", "false for \'isInside\' cameras, otherwise true")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#rotateNode", "Rotate node")
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Camera rotation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#translation", "Camera translation")
	schema:register(XMLValueType.BOOL, basePath .. "#useMirror", "Use mirrors", false)
	schema:register(XMLValueType.BOOL, basePath .. "#useWorldXZRotation", "Use world XZ rotation")
	schema:register(XMLValueType.BOOL, basePath .. "#resetCameraOnVehicleSwitch", "Reset camera on vehicle switch")
	schema:register(XMLValueType.INT, basePath .. "#suspensionNodeIndex", "Index of seat suspension node")
	schema:register(XMLValueType.BOOL, basePath .. "#useDefaultPositionSmoothing", "Use default position smoothing parameters", true)
	schema:register(XMLValueType.FLOAT, basePath .. "#positionSmoothingParameter", "Position smoothing parameter", "0.128 for indoor / 0.016 for outside")
	schema:register(XMLValueType.FLOAT, basePath .. "#lookAtSmoothingParameter", "Look at smoothing parameter", "0.176 for indoor / 0.022 for outside")
	schema:register(XMLValueType.ANGLE, basePath .. "#rotYSteeringRotSpeed", "Rot Y steering rotation speed", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".raycastNode(?)#node", "Raycast node")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end

function VehicleCamera.registerCameraSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#rotation", "Camera rotation")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#translation", "Camera translation")
	schema:register(XMLValueType.FLOAT, basePath .. "#zoom", "Camera zoom")
	schema:register(XMLValueType.ANGLE, basePath .. "#fovY", "Custom Field of View Y")
	schema:register(XMLValueType.BOOL, basePath .. "#lodDebugActive", "LOD Debug Mode Active")
	schema:register(XMLValueType.FLOAT, basePath .. "#lodDebugZoom", "LOD Debug Mode Zoom Ref")
	schema:register(XMLValueType.BOOL, basePath .. "#cameraYDebugActive", "Camera Y Debug Mode Active")
	schema:register(XMLValueType.FLOAT, basePath .. "#cameraYDebugHeight", "Camera Y Debug Mode orthographic height")
end
function VehicleCamera.consoleCommandLODDebug()
	if g_activeVehicleCamera == nil then
		return "Enter a vehicle first!"
	end
	g_activeVehicleCamera:setLODDebugState(not g_activeVehicleCamera.lodDebugMode)
	return string.format("(%s) Vehicle Camera LOD Debug: %s", g_activeVehicleCamera.vehicle:getName(), g_activeVehicleCamera.lodDebugMode)
end

function VehicleCamera.consoleCommandCameraYDebug(height)
	if g_activeVehicleCamera == nil then
		return "Enter a vehicle first!"
	end
	g_activeVehicleCamera:setCameraYDebugState(not g_activeVehicleCamera.cameraYDebugMode, height)
	return string.format("(%s) Vehicle Camera Y Debug: %s", g_activeVehicleCamera.vehicle:getName(), g_activeVehicleCamera.cameraYDebugMode)
end
addConsoleCommand("gsVehicleDebugLOD", "Enables vehicle LOD debug", "consoleCommandLODDebug", VehicleCamera)
