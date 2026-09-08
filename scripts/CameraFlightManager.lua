-- Local values: CameraFlightManager_mt
CameraFlightManager = {}
local CameraFlightManager_mt = Class(CameraFlightManager)
function CameraFlightManager.new()
	-- upvalues: (copy) CameraFlightManager_mt
	local v2_ = CameraFlightManager_mt
	local v3_ = setmetatable({}, v2_)
	v3_.cameraFlightIsActive = false
	v3_.abortCameraFlight = false
	return v3_
end

-- Local values: i, key, flightType, speedScale, filename, i3dFilename, camera, cameraFlight, onMenuAbort
function CameraFlightManager:load(xmlFile)
	self.cameraFlights = {}
	local v6_ = 0
	while true do
		local v7_ = string.format("map.cameraFlights.cameraFlight(%d)", v6_)
		if not hasXMLProperty(xmlFile, v7_) then
			break
		end
		local v8_ = getXMLString(xmlFile, v7_ .. "#type")
		local v9_ = getXMLFloat(xmlFile, v7_ .. "#speedScale")
		local v10_ = getXMLString(xmlFile, v7_ .. "#filename")
		local v11_ = Utils.getFilename(v10_, self.baseDirectory)
		local v12_ = createCamera("cameraFlight_" .. v8_, 1.0471975511965976, 1, 10000)
		local v13_ = CameraPath.createFromI3D(v11_, v9_, v12_)
		if self.cameraFlights[v8_] == nil then
			self.cameraFlights[v8_] = v13_
		end
		v6_ = v6_ + 1
	end
	g_inputBinding:registerActionEvent(InputAction.MENU, self, function()
		-- upvalues: (copy) self
		self.abortCameraFlight = true
		g_inputBinding:removeActionEventsByTarget(self)
	end, false, true, false, true)
end

-- Local values: _, cameraPath
function CameraFlightManager:delete()
	for _, v15_ in pairs(self.cameraFlights) do
		v15_:delete()
	end
end

-- Local values: cameraPath, continue
function CameraFlightManager:update(dt)
	if g_server ~= nil and (g_client ~= nil and (self.cameraFlights.careerStart ~= nil and not self.careerStartFlightPlayed)) then
		local v18_ = self.cameraFlights.careerStart
		if g_localPlayer:getCurrentVehicle() ~= nil then
			self.abortCameraFlight = true
		end
		if self.abortCameraFlight then
			v18_:deactivate()
			self.careerStartFlightPlayed = true
			g_localPlayer.walkingIsLocked = false
			return
		end
		if not g_gui:getIsGuiVisible() then
			if v18_.time == 0 then
				v18_:activate()
			end
			v18_:update(dt)
			g_localPlayer.walkingIsLocked = true
			if v18_.time >= v18_.maxTime then
				self.careerStartFlightPlayed = true
				v18_:deactivate()
				g_localPlayer.walkingIsLocked = false
			end
		end
	end
end
