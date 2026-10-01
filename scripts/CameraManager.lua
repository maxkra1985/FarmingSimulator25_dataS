CameraManager = {}
local CameraManager_mt = Class(CameraManager)
local setCameraLocal = setCamera
function setCamera(cameraNode)
	Logging.warning("Use g_cameraManager:setActiveCamera(cameraNode) instead of setCamera(cameraNode)!")
	g_cameraManager:setActiveCamera(cameraNode)
end
function CameraManager.new(customMt)
	local self = setmetatable({}, customMt or CameraManager_mt)
	self.cameraInfo = {}
	self.originDebugCamera = nil
	self.activeCameraNode = nil
	self.defaultCameraNode = nil
	self.lowResColHandlerHighPrioActive = false
	self.virtualTerrainUpdateEnabled = true
	addConsoleCommand("gsCameraFovSet", "Sets camera field of view angle", "consoleCommandSetFOV", self)
	addConsoleCommand("gsCameraManagerDebug", "Toggle camera manager debug mode", "consoleCommandToggleDebug", self)
	return self
end
function CameraManager:delete()
	if self.originDebugCamera ~= nil then
		delete(self.originDebugCamera)
		self.originDebugCamera = nil
	end
	for cameraNode, info in pairs(self.cameraInfo) do
		if info.isDefaultCamera then
			continue
		end
		Logging.devWarning("CameraManager: Camera '%s' was not removed! \n%s", info.name, info.callstack)
	end
end
function CameraManager:init()
	if g_isDevelopmentVersion then
		self.originDebugCamera = createCamera("originDebugCamera", 1.0471975511965976, 0.15, 10000)
		link(getRootNode(), self.originDebugCamera)
		local offsetX = -20
		local offsetY = 10
		local offsetZ = 20
		local dirX, dirY, dirZ = MathUtil.vector3Normalize(-20, 10, 20)
		local upX = 0
		local upY = 1
		local upZ = 0
		setWorldTranslation(self.originDebugCamera, -20, 10, 20)
		setDirection(self.originDebugCamera, dirX, dirY, dirZ, 0, 1, 0)
	end
end
function CameraManager:addCamera(cameraNode, shadowFocusBoxNode, isDefaultCamera, colHandlerHighPrio, dofInfo, virtualTerrainUpdateEnabled)
	local cameraInfo = self.cameraInfo[cameraNode]
	if cameraInfo ~= nil then
		if g_showDevelopmentWarnings then
			Logging.devWarning("Try to add an already existing camera")
			printCallstack()
		end
	else
		if isDefaultCamera then
			if self.defaultCameraNode == nil then
				self.defaultCameraNode = cameraNode
			elseif g_showDevelopmentWarnings then
				Logging.devWarning("Try to set an already existing default camera")
				printCallstack()
			end
		end
		self.cameraInfo[cameraNode] = { node = cameraNode, shadowFocusBoxNode = shadowFocusBoxNode, isDefaultCamera = isDefaultCamera, colHandlerHighPrio = colHandlerHighPrio, dofInfo = dofInfo, name = getName(cameraNode), virtualTerrainUpdateEnabled = Utils.getNoNil(virtualTerrainUpdateEnabled, true) }
		if g_isDevelopmentVersion and (debug ~= nil and debug.traceback ~= nil) then
			self.cameraInfo[cameraNode].callstack = debug.traceback()
		end
	end
end
function CameraManager:removeCamera(cameraNode)
	local cameraInfo = self.cameraInfo[cameraNode]
	if cameraInfo == nil then
		if g_showDevelopmentWarnings then
			Logging.devWarning("Try to remove an undefined camera")
			printCallstack()
		end
	elseif cameraInfo.isDefaultCamera then
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
function CameraManager:setActiveCamera(cameraNode)
	if cameraNode == nil then
		if g_showDevelopmentWarnings then
			Logging.devWarning("Try to set nil as a camera")
			printCallstack()
		end
		return
	end
	local cameraInfo = self.cameraInfo[cameraNode]
	if cameraInfo == nil then
		if g_showDevelopmentWarnings then
			Logging.devWarning("Try to set an undefined camera '%s'", getName(cameraNode))
			printCallstack()
		end
	elseif self.activeCameraNode == cameraNode then
		Logging.devWarning("Try to set the active camera '%s' again", getName(cameraNode))
	else
		if g_terrainNode ~= nil and not cameraInfo.virtualTerrainUpdateEnabled then
			setVirtualTerrainUpdateEnabled(g_terrainNode, false)
			self.virtualTerrainUpdateEnabled = false
		end
		local shadowFocusBoxNode = cameraInfo.shadowFocusBoxNode or 0
		setCameraLocal(cameraNode)
		setShadowFocusBox(shadowFocusBoxNode)
		if g_terrainNode ~= nil and cameraInfo.virtualTerrainUpdateEnabled then
			setVirtualTerrainUpdateEnabled(g_terrainNode, true)
			self.virtualTerrainUpdateEnabled = true
		end
		if cameraInfo.colHandlerHighPrio then
			setLowResCollisionHandlerHighPrioriyUpdateArea(2)
			self.lowResColHandlerHighPrioActive = true
		else
			setLowResCollisionHandlerHighPrioriyUpdateArea(0)
			self.lowResColHandlerHighPrioActive = false
		end
		if cameraInfo.dofInfo ~= nil then
			g_depthOfFieldManager:applyInfo(cameraInfo.dofInfo)
		else
			g_depthOfFieldManager:reset()
		end
		self.activeCameraNode = cameraNode
	end
end
function CameraManager:getActiveCamera()
	if g_isDevelopmentVersion and not entityExists(self.activeCameraNode) then
		local cameraInfo = self.cameraInfo[self.activeCameraNode]
		if cameraInfo ~= nil then
			Logging.devError("Trying to get already deleted camera node (%s)\n\n%s", cameraInfo.name, cameraInfo.callstack)
		else
			Logging.devError("Trying to get already deleted camera node. Camera was not added to camera manager")
		end
	end
	return self.activeCameraNode
end
function CameraManager:drawDebug()
	local shadowFocusBoxNode = self.cameraInfo[self.activeCameraNode] and self.cameraInfo[self.activeCameraNode].shadowFocusBoxNode
	if shadowFocusBoxNode ~= nil then
		DebugSphere.renderShapeBoundingSphere(shadowFocusBoxNode, nil, nil, nil, getName(shadowFocusBoxNode) .. " (BV)")
	end
	renderText(0.45, 0.09, 0.01, string.format("Active: %s | Current: %s", getName(self.activeCameraNode), getName(getCamera())))
	renderText(0.45, 0.08, 0.01, string.format("shadowFocusBox: %s", shadowFocusBoxNode and getName(shadowFocusBoxNode) or "None"))
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
function CameraManager:consoleCommandSetFOV(fovYDeg)
	fovYDeg = tonumber(fovYDeg)
	if fovYDeg == nil then
		return "Error: Command needs number argument. gsCameraFovSet fieldOfViewAngle (-1 to reset to default)"
	end
	local camera = self.activeCameraNode
	local cameraInfo = self.cameraInfo[camera]
	if cameraInfo == nil then
		return "Error: current camera not registered in camera manager"
	else
		local getVehicleCamFovy = function()
			if g_currentMission and g_localPlayer:getCurrentVehicle() ~= nil then
				local cameraBase = g_localPlayer:getCurrentVehicle():getActiveCamera()
				if cameraBase ~= nil then
					return cameraBase.fovY
				end
			end
			return nil
		end
		if fovYDeg < 0 and (g_currentMission and g_localPlayer:getCurrentVehicle() ~= nil) then
			local cameraBase = g_localPlayer:getCurrentVehicle():getActiveCamera()
			local fovYBackup = cameraBase ~= nil and cameraBase.fovY or cameraInfo.fovBackup
			cameraInfo.fovBackup = nil
			local currentFovY = getFovY(camera)
			if fovYBackup == nil or fovYBackup == currentFovY then
				return string.format("Camera %q still on original fov %.1f\194\176", getName(camera), math.deg(currentFovY))
			end
			setFovY(camera, fovYBackup)
			return string.format("Reset camera %q fov to original %.1f\194\176", getName(camera), math.deg(fovYBackup))
		end
		if cameraInfo.fovBackup == nil and (g_currentMission and g_localPlayer:getCurrentVehicle() ~= nil) then
			local cameraBase = g_localPlayer:getCurrentVehicle():getActiveCamera()
			cameraInfo.fovBackup = cameraBase ~= nil and cameraBase.fovY or getFovY(camera)
		end
		setFovY(camera, math.rad(fovYDeg))
		return string.format("Set camera %q fov to %.1f\194\176", getName(camera), fovYDeg)
	end
end
g_cameraManager = CameraManager.new()
