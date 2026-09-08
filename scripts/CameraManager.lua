-- Local values: CameraManager_mt, setCameraLocal
CameraManager = {}
local CameraManager_mt = Class(CameraManager)
local setCameraLocal = setCamera
function setCamera(p3_)
	Logging.warning("Use g_cameraManager:setActiveCamera(cameraNode) instead of setCamera(cameraNode)!")
	g_cameraManager:setActiveCamera(p3_)
end

-- Upvalues: CameraManager_mt
-- Local values: self
function CameraManager.new(customMt)
	-- upvalues: (copy) CameraManager_mt
	local v5_ = customMt or CameraManager_mt
	local v6_ = setmetatable({}, v5_)
	v6_.cameraInfo = {}
	v6_.originDebugCamera = nil
	v6_.activeCameraNode = nil
	v6_.defaultCameraNode = nil
	v6_.lowResColHandlerHighPrioActive = false
	v6_.virtualTerrainUpdateEnabled = true
	addConsoleCommand("gsCameraFovSet", "Sets camera field of view angle", "consoleCommandSetFOV", v6_)
	addConsoleCommand("gsCameraManagerDebug", "Toggle camera manager debug mode", "consoleCommandToggleDebug", v6_)
	return v6_
end

-- Local values: cameraNode, info
function CameraManager:delete()
	if self.originDebugCamera ~= nil then
		delete(self.originDebugCamera)
		self.originDebugCamera = nil
	end
	for _, v8_ in pairs(self.cameraInfo) do
		if not v8_.isDefaultCamera then
			Logging.devWarning("CameraManager: Camera \'%s\' was not removed! \n%s", v8_.name, v8_.callstack)
		end
	end
end

-- Local values: offsetX, offsetY, offsetZ, dirX, dirY, dirZ, upX, upY, upZ
function CameraManager:init()
	if g_isDevelopmentVersion then
		self.originDebugCamera = createCamera("originDebugCamera", 1.0471975511965976, 0.15, 10000)
		link(getRootNode(), self.originDebugCamera)
		local v10_, v11_, v12_ = MathUtil.vector3Normalize(-20, 10, 20)
		setWorldTranslation(self.originDebugCamera, -20, 10, 20)
		setDirection(self.originDebugCamera, v10_, v11_, v12_, 0, 1, 0)
	end
end

-- Local values: cameraInfo
function CameraManager:addCamera(cameraNode, shadowFocusBoxNode, isDefaultCamera, colHandlerHighPrio, dofInfo, virtualTerrainUpdateEnabled)
	if self.cameraInfo[cameraNode] == nil then
		if isDefaultCamera then
			if self.defaultCameraNode == nil then
				self.defaultCameraNode = cameraNode
			elseif g_showDevelopmentWarnings then
				Logging.devWarning("Try to set an already existing default camera")
				printCallstack()
			end
		end
		self.cameraInfo[cameraNode] = {
			["node"] = cameraNode,
			["shadowFocusBoxNode"] = shadowFocusBoxNode,
			["isDefaultCamera"] = isDefaultCamera,
			["colHandlerHighPrio"] = colHandlerHighPrio,
			["dofInfo"] = dofInfo,
			["name"] = getName(cameraNode),
			["virtualTerrainUpdateEnabled"] = Utils.getNoNil(virtualTerrainUpdateEnabled, true)
		}
		if g_isDevelopmentVersion and (debug ~= nil and debug.traceback ~= nil) then
			self.cameraInfo[cameraNode].callstack = debug.traceback()
		end
	elseif g_showDevelopmentWarnings then
		Logging.devWarning("Try to add an already existing camera")
		printCallstack()
	end
end

-- Local values: cameraInfo
function CameraManager:removeCamera(cameraNode)
	local v22_ = self.cameraInfo[cameraNode]
	if v22_ == nil then
		if g_showDevelopmentWarnings then
			Logging.devWarning("Try to remove an undefined camera")
			printCallstack()
		end
		return
	elseif v22_.isDefaultCamera then
		if g_showDevelopmentWarnings then
			Logging.devWarning("Cannot remove default camera")
			printCallstack()
		end
	else
		if cameraNode == self.activeCameraNode then
			if g_showDevelopmentWarnings then
				Logging.devWarning("Trying to remove active camera. Disable camera first!")
				printCallstack()
			end
			self:setDefaultCamera()
		end
		self.cameraInfo[cameraNode] = nil
	end
end

function CameraManager:setDefaultCamera()
	if self.defaultCameraNode == nil then
		if g_showDevelopmentWarnings then
			Logging.devWarning("No default camera set")
			printCallstack()
		end
	else
		self:setActiveCamera(self.defaultCameraNode)
	end
end

-- Upvalues: setCameraLocal
-- Local values: cameraInfo, shadowFocusBoxNode
function CameraManager:setActiveCamera(cameraNode)
	-- upvalues: (copy) setCameraLocal
	if cameraNode == nil then
		if g_showDevelopmentWarnings then
			Logging.devWarning("Try to set nil as a camera")
			printCallstack()
		end
		return
	else
		local v26_ = self.cameraInfo[cameraNode]
		if v26_ == nil then
			if g_showDevelopmentWarnings then
				Logging.devWarning("Try to set an undefined camera \'%s\'", getName(cameraNode))
				printCallstack()
			end
			return
		elseif self.activeCameraNode == cameraNode then
			Logging.devWarning("Try to set the active camera \'%s\' again", getName(cameraNode))
		else
			if g_terrainNode ~= nil and not v26_.virtualTerrainUpdateEnabled then
				setVirtualTerrainUpdateEnabled(g_terrainNode, false)
				self.virtualTerrainUpdateEnabled = false
			end
			local v27_ = v26_.shadowFocusBoxNode or 0
			setCameraLocal(cameraNode)
			setShadowFocusBox(v27_)
			if g_terrainNode ~= nil and v26_.virtualTerrainUpdateEnabled then
				setVirtualTerrainUpdateEnabled(g_terrainNode, true)
				self.virtualTerrainUpdateEnabled = true
			end
			if v26_.colHandlerHighPrio then
				setLowResCollisionHandlerHighPrioriyUpdateArea(2)
				self.lowResColHandlerHighPrioActive = true
			else
				setLowResCollisionHandlerHighPrioriyUpdateArea(0)
				self.lowResColHandlerHighPrioActive = false
			end
			if v26_.dofInfo == nil then
				g_depthOfFieldManager:reset()
			else
				g_depthOfFieldManager:applyInfo(v26_.dofInfo)
			end
			self.activeCameraNode = cameraNode
		end
	end
end

-- Local values: cameraInfo
function CameraManager:getActiveCamera()
	if g_isDevelopmentVersion and not entityExists(self.activeCameraNode) then
		local v29_ = self.cameraInfo[self.activeCameraNode]
		if v29_ == nil then
			Logging.devError("Trying to get already deleted camera node. Camera was not added to camera manager")
		else
			Logging.devError("Trying to get already deleted camera node (%s)\n\n%s", v29_.name, v29_.callstack)
		end
	end
	return self.activeCameraNode
end

-- Local values: shadowFocusBoxNode
function CameraManager:drawDebug()
	local v31_ = self.cameraInfo[self.activeCameraNode]
	if v31_ then
		v31_ = self.cameraInfo[self.activeCameraNode].shadowFocusBoxNode
	end
	if v31_ ~= nil then
		DebugSphere.renderShapeBoundingSphere(v31_, nil, nil, nil, getName(v31_) .. " (BV)")
	end
	renderText(0.45, 0.09, 0.01, string.format("Active: %s | Current: %s", getName(self.activeCameraNode), getName(getCamera())))
	renderText(0.45, 0.08, 0.01, string.format("shadowFocusBox: %s", v31_ and getName(v31_) or "None"))
	renderText(0.45, 0.07, 0.01, string.format("lowResColHandlerHighPrio: %s", self.lowResColHandlerHighPrioActive))
	renderText(0.45, 0.06, 0.01, string.format("virtualTerrainUpdateEnabled: %s", self.virtualTerrainUpdateEnabled))
end

function CameraManager:consoleCommandToggleDebug()
	if g_debugManager:hasDrawable(self) then
		g_debugManager:removeDrawable(self)
		return "CameraManager debug mode: disabled"
	else
		g_debugManager:addDrawable(self)
		return "CameraManager debug mode: enabled"
	end
end

-- Local values: camera, cameraInfo, getVehicleCamFovy, cameraBase, fovYBackup, currentFovY, cameraBase
function CameraManager:consoleCommandSetFOV(fovYDeg)
	local v35_ = tonumber(fovYDeg)
	if v35_ == nil then
		return "Error: Command needs number argument. gsCameraFovSet fieldOfViewAngle (-1 to reset to default)"
	end
	local v36_ = self.activeCameraNode
	local v37_ = self.cameraInfo[v36_]
	if v37_ == nil then
		return "Error: current camera not registered in camera manager"
	end
	if v35_ >= 0 then
		if v37_.fovBackup == nil then
			local v38_
			if g_currentMission and g_localPlayer:getCurrentVehicle() ~= nil then
				local v39_ = g_localPlayer:getCurrentVehicle():getActiveCamera()
				if v39_ == nil then
					v38_ = nil
				else
					v38_ = v39_.fovY
				end
			else
				v38_ = nil
			end
			v37_.fovBackup = v38_ or getFovY(v36_)
		end
		setFovY(v36_, (math.rad(v35_)))
		return string.format("Set camera %q fov to %.1f\194\176", getName(v36_), v35_)
	end
	local v40_
	if g_currentMission and g_localPlayer:getCurrentVehicle() ~= nil then
		local v41_ = g_localPlayer:getCurrentVehicle():getActiveCamera()
		if v41_ == nil then
			v40_ = nil
		else
			v40_ = v41_.fovY
		end
	else
		v40_ = nil
	end
	local v42_ = v40_ or v37_.fovBackup
	v37_.fovBackup = nil
	local v43_ = getFovY(v36_)
	if v42_ == nil or v42_ == v43_ then
		return string.format("Camera %q still on original fov %.1f\194\176", getName(v36_), (math.deg(v43_)))
	end
	setFovY(v36_, v42_)
	return string.format("Reset camera %q fov to original %.1f\194\176", getName(v36_), (math.deg(v42_)))
end
g_cameraManager = CameraManager.new()
