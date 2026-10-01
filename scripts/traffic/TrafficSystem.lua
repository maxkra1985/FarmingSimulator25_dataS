TrafficSystem = {}
local TrafficSystem_mt = Class(TrafficSystem, Object)
InitStaticObjectClass(TrafficSystem, "TrafficSystem")
g_xmlManager:addCreateSchemaFunction(function()
	TrafficSystem.xmlSchema = XMLSchema.new("trafficSystem")
	TrafficSystem.xmlSchema.supportsParentFile = false
	TrafficSystem.xmlSchemaVehicle = XMLSchema.new("trafficSystemVehicle")
	TrafficSystem.xmlSchemaVehicle.supportsParentFile = false
end)
g_xmlManager:addInitSchemaFunction(function()
	local xmlSchema = TrafficSystem.xmlSchema
	xmlSchema:register(XMLValueType.STRING, "trafficSystem#licensePlates", "i3d filepath containing licenceplates (TGs on i3d root level with front and back plate as children) to link to traffic vehicles")
	xmlSchema:register(XMLValueType.UINT, "trafficSystem#maxNumVehicles", "Maximum number of active traffic vehicles (no more than 30)")
	xmlSchema:register(XMLValueType.STRING, "trafficSystem.vehicles.vehicle(?)#filename", "traffic vehicle xml filepath")
	xmlSchema:register(XMLValueType.FLOAT, "trafficSystem.vehicles.vehicle(?)#probability")
	xmlSchema:register(XMLValueType.FLOAT, "trafficSystem.vehicles.vehicle(?)#probabilityParked")
	xmlSchema:register(XMLValueType.UINT, "trafficSystem.vehicles.vehicle(?)#typeFlag", "Bitmask flag (2^n) determining which splines the vehicle will drive on. Filtered by the splines bitmask set with the 'vehicleTypes' user attribute where at least one bit has to match.", "uint max val / all bits")
	local xmlSchemaVehicle = TrafficSystem.xmlSchemaVehicle
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle#topSpeed", "maximum speed in kph")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle#accel", "acceleration in m/s\194\178")
	xmlSchemaVehicle:register(XMLValueType.STRING, "vehicle.assets#filename")
	xmlSchemaVehicle:register(XMLValueType.STRING, "vehicle.assets#filenameParked")
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets#driverNode", "driver node, hidden when vehicle is parked. Use 'vehicle.assets.drivers.driver(?)' for defining multiple drivers")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets#roadSideLimitDistanceFromFront", "optional z offset adjusting the pivot used for placing the vehicle on the spline")
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets.drivers.driver(?)#node", "driver node, hidden when vehicle is parked. Use if more than one driver is supposed to be defined and delete 'vehicle.assets#driverNode' entry")
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets.collisionGeometry#node", "transform group where the collision trigger will be dynamically created at runtime")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.collisionGeometry#width")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.collisionGeometry#height")
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets.licensePlates#frontNode", "node where license plates from i3d file defined in trafficSystem xml file are linked to")
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets.licensePlates#backNode", "node where license plates from i3d file defined in trafficSystem xml file are linked to")
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets.wheels.wheel(?)#yRotNode", "node rotated on its y axis when steering, e.g. brakeCalipers as parent of wheel", nil, true)
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets.wheels.wheel(?)#xRotNode", "node rotated on x axis, e.g. wheel", nil, true)
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.wheels.wheel(?)#radius", "radius of the wheel used for calculating the rotation speed", nil, true)
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.wheels.wheel(?)#distToRotCenter", "", nil, true)
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets.lights.light#node")
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets.lights.light#decoration")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.lights.light#intensity")
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets.lights.light#lowProfile")
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets.lights.light#highProfile")
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets.lights.turnLeft#decoration")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.lights.turnLeft#intensity")
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets.lights.turnRight#decoration")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.lights.turnRight#intensity")
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets.lights.brake#decoration")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.lights.brake#intensity")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.lights.brake#regularIntensity")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.colors#minDirt")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.colors#maxDirt")
	xmlSchemaVehicle:register(XMLValueType.NODE_INDEX, "vehicle.assets.colors.colorNodes.colorNode(?)#node")
	xmlSchemaVehicle:register(XMLValueType.VECTOR_3, "vehicle.assets.colors.availableColors.color(?)#rgb", "triplet of rgb color with range [0..1]")
	xmlSchemaVehicle:register(XMLValueType.STRING, "vehicle.assets.sounds.motor#filename")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#indoorVolume")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#outdoorVolume")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#range")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#innerRange")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#indoorLowpassGain")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#outdoorLowpassGain")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#indoorLowpassCutoffFrequency")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#indoorLowpassResonance")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#outdoorLowpassCutoffFrequency")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#outdoorLowpassResonance")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#pitchMin")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#pitchMax")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor.pitch(?)#velocity")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor.pitch(?)#pitchOffset")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor.pitch(?)#pitchScale")
	xmlSchemaVehicle:register(XMLValueType.STRING, "vehicle.assets.sounds.honk#filename")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#indoorVolume")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#outdoorVolume")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#range")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#innerRange")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#innerRange")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#indoorLowpassGain")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#outdoorLowpassGain")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#indoorLowpassCutoffFrequency")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#indoorLowpassResonance")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#outdoorLowpassResonance")
	xmlSchemaVehicle:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#outdoorLowpassCutoffFrequency")
end)
function TrafficSystem:onCreate(transformId)
	local xmlFilename = getUserAttribute(transformId, "xmlFile")
	if xmlFilename == nil then
		Logging.error("Missing xmlFile attribute for traffic system in node %q", I3DUtil.getNodePath(transformId))
		return false
	end
	if GS_IS_EDITOR then
		return
	end
	local existingTrafficSystem = g_currentMission:getTrafficSystem()
	if existingTrafficSystem ~= nil and existingTrafficSystem.trafficSystemId ~= nil then
		Logging.error("Traffic system already present")
		return false
	end
	xmlFilename = Utils.getFilename(xmlFilename, g_currentMission.loadedMapBaseDirectory)
	local lightsProfile = Platform.gameplay.lightsProfile or g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)
	local useHighProfile = GS_PROFILE_HIGH <= lightsProfile
	local trafficSystem = TrafficSystem.new(g_server ~= nil, g_client ~= nil)
	if not trafficSystem:load(xmlFilename, transformId, useHighProfile, g_server ~= nil, g_client ~= nil) then
		trafficSystem:delete()
		return false
	else
		trafficSystem:register(true)
		if g_currentMission.missionDynamicInfo.isMultiplayer then
			g_currentMission.onCreateObjectSystem:add(trafficSystem)
		end
		trafficSystem:setEnabled(g_currentMission.missionInfo.trafficEnabled)
		g_currentMission:setTrafficSystem(trafficSystem)
		return true
	end
end
function TrafficSystem.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or TrafficSystem_mt)
	self.trafficSystemId = nil
	self.isEnabled = false
	self.debugIsEnabled = false
	self.trafficSystemDirtyFlag = self:getNextDirtyFlag()
	addConsoleCommand("gsTrafficSystemToggleDebug", "Enables debug rendering for the collision geometry", "consoleCommandToggleDebugRendering", self)
	addConsoleCommand("gsTrafficSystemValidate", "Validates traffic system setup", "consoleCommandValidate", self)
	if isServer and not g_currentMission.missionDynamicInfo.isMultiplayer then
		addConsoleCommand("gsTrafficSystemReload", "Reloads traffic system", "consoleCommandTrafficSystemReload", self)
		addConsoleCommand("gsTrafficSystemLightsDebug", "Reloads traffic system", "consoleCommandTrafficSystemDebugLights", self, "light|left|right|brake")
	end
	return self
end
function TrafficSystem:load(xmlFilename, transformId, useHighProfile, isServer, isClient)
	local trafficSystemId = createTrafficSystem(xmlFilename, transformId, useHighProfile, isServer, isClient, AudioGroup.ENVIRONMENT)
	if trafficSystemId == 0 then
		Logging.error("Unable to create TrafficSystem from '%s' and '%s'", xmlFilename, I3DUtil.getNodePath(transformId))
		return false
	else
		self.trafficSystemId = trafficSystemId
		self.rootNodeId = transformId
		setVisibility(self.rootNodeId, false)
		self.xmlFilename = xmlFilename
		self.groundMask = CollisionFlag.TERRAIN + CollisionFlag.ROAD
		self.stopMask = CollisionFlag.DYNAMIC_OBJECT + CollisionFlag.TRAFFIC_VEHICLE + CollisionFlag.PLAYER
		self.playerStopMask = CollisionFlag.VEHICLE
		self.ignoreMask = CollisionFlag.TRAFFIC_VEHICLE_BLOCKING
		setTrafficSystemCollisionMasks(self.trafficSystemId, self.groundMask, self.stopMask, self.playerStopMask, self.ignoreMask)
		self.isEnabled = true
		g_soundManager:addIndoorStateChangedListener(self)
		setTrafficSystemUseOutdoorAudioSetup(self.trafficSystemId, not g_soundManager:getIsIndoor())
		self:updateNightTimeRange()
		g_messageCenter:subscribe(MessageType.DAYLIGHT_CHANGED, self.onDaylightChanged, self)
		g_messageCenter:publishDelayed(MessageType.TRAFFIC_SYSTEM_LOADED, self)
		return true
	end
end
function TrafficSystem:delete()
	if self.trafficSystemId ~= nil then
		g_currentMission:setTrafficSystem(nil)
		self:unregister()
		delete(self.trafficSystemId)
		self.trafficSystemId = nil
	end
	removeConsoleCommand("gsTrafficSystemToggleDebug")
	removeConsoleCommand("gsTrafficSystemValidate")
	removeConsoleCommand("gsTrafficSystemReload")
	removeConsoleCommand("gsTrafficSystemLightsDebug")
	g_messageCenter:unsubscribeAll(self)
	g_soundManager:removeIndoorStateChangedListener(self)
	g_debugManager:removeDrawable(self)
end
function TrafficSystem:writeUpdateStream(streamId, connection, dirtyMask)
	TrafficSystem:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		writeTrafficSystemToStream(self.trafficSystemId, streamId)
	end
end
function TrafficSystem:readUpdateStream(streamId, timestamp, connection)
	TrafficSystem:superClass().readUpdateStream(self, streamId, timestamp, connection)
	if connection:getIsServer() then
		readTrafficSystemFromStream(self.trafficSystemId, streamId, g_clientInterpDelay, g_packetPhysicsNetworkTime, g_client.tickDuration)
	end
end
function TrafficSystem:update(dt)
	setTrafficSystemDaytime(self.trafficSystemId, g_currentMission.environment.dayTime)
	if self.isEnabled then
		self:raiseActive()
	end
end
function TrafficSystem:updateTick(dt)
	if self.isServer then
		self:raiseDirtyFlags(self.trafficSystemDirtyFlag)
	end
end
function TrafficSystem:setNightTimeRange(nightStart, nightEnd)
	setTrafficSystemNightTimeRange(self.trafficSystemId, nightStart, nightEnd)
end
function TrafficSystem:setEnabled(state)
	setTrafficSystemEnabled(self.trafficSystemId, state)
	self.isEnabled = state
	if state then
		self:raiseActive()
	end
end
function TrafficSystem:reset()
	resetTrafficSystem(self.trafficSystemId)
end
function TrafficSystem:onIndoorStateChanged(isIndoor)
	setTrafficSystemUseOutdoorAudioSetup(self.trafficSystemId, not isIndoor)
end
function TrafficSystem:updateNightTimeRange()
	local daylight = g_currentMission.environment.daylight
	self:setNightTimeRange(daylight.logicalNightStart, daylight.logicalNightEnd)
end
function TrafficSystem:onDaylightChanged()
	self:updateNightTimeRange()
end
function TrafficSystem:drawDebug()
	local trafficVehiclesRootNode = getChild(getRootNode(), "TrafficSystemVehicles")
	if trafficVehiclesRootNode ~= 0 then
		local textLineNumber = 0
		for i = 0, getNumOfChildren(trafficVehiclesRootNode) - 1 do
			local trafficVehicle = getChildAt(trafficVehiclesRootNode, i)
			local x, y, z = getWorldTranslation(trafficVehicle)
			local name = getName(trafficVehicle)
			if DebugUtil.isPositionInCameraRange(x, y, z, 100) then
				local dx, dy, dz = localDirectionToWorld(trafficVehicle, 0, 0, 1)
				DebugGizmo.renderAtPosition(x, y, z, dx, dy, dz, 0, 1, 0, name, false)
			end
			if getRigidBodyType(trafficVehicle) == RigidBodyType.KINEMATIC then
				renderText(0.85, 0.7 - textLineNumber * 0.012, 0.012, name)
				renderText(0.92, 0.7 - textLineNumber * 0.012, 0.012, string.format("%d %d %d", x, y, z))
				textLineNumber = textLineNumber + 1
			end
		end
	end
end
function TrafficSystem:validateSplines()
	local debugElementsGroupName = "trafficSystemValidation"
	g_debugManager:removeGroup("trafficSystemValidation")
	local raycastHeightOverSpline = 5
	local raycastLength = 15
	local heightDiffThreshold = 0.45
	local numProblems = 0
	local rcy = nil
	local raycastCallbackTarget = {
		raycastCallback = function(_, actorId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
			rcy = y
		end,
	}
	local validCollisionFlags = CollisionFlag.getFlagsStringFromMask(self.groundMask)
	I3DUtil.iterateRecursively(self.rootNodeId, function(child, depth)
		if I3DUtil.getIsSpline(child) then
			local splineName = getName(child)
			local splineLength = getSplineLength(child)
			local stepLength = 1
			local stepSize = 1 / splineLength
			if 0 < depth and 50 < splineLength then
				Logging.warning("Spline %q is a crossroad (child of a transform group) but is longer than 50m. Is this intentional?", I3DUtil.getNodePath(child, self.rootNodeId))
				numProblems = numProblems + 1
			end
			for stepSplineTime = 0, 1 + stepSize, stepSize do
				local clampedSplineTime = math.clamp(stepSplineTime, 0, 1)
				local wx, wy, wz = getSplinePosition(child, clampedSplineTime)
				rcy = nil
				raycastClosest(wx, wy + 5, wz, 0, -1, 0, 15, "raycastCallback", raycastCallbackTarget, self.groundMask)
				if rcy == nil then
					continue
				end
				local heightDiff = wy - rcy
				if 0.45 < math.abs(heightDiff) then
					local closestEP = SplineUtil.getClosestEditPoint(child, wx, wy, wz) or -1
					local text = string.format("%s\ntime=%.3f closestEP=%d\nx=%d y=%d z=%d\noffset to col: %.2f", splineName, clampedSplineTime, closestEP, wx, wy, wz, heightDiff)
					DebugPoint.new():createWithWorldPos(wx, wy, wz):setText(text):setColor(Color.PRESETS.RED):addToManager("trafficSystemValidation")
					DebugLine.new():createWithStartAndEndPos(wx, wy, wz, wx, rcy, wz, false, false):setColor(Color.PRESETS.RED):addToManager("trafficSystemValidation")
					Logging.warning("Spot %d %d %d (t=%.3f, EP=%d) on spline %s is more than %.1fm away from the next valid collision (raycasting against CollisionFlags: %s)", wx, wy, wz, clampedSplineTime, closestEP, splineName, heightDiff, validCollisionFlags)
					numProblems = numProblems + 1
				end
			end
		end
	end)
	Logging.info("Finished traffic system spline analysis, found %d problematic spots", numProblems)
end
function TrafficSystem:validateParkingPositions()
	print("validating parked car positions")
	local parkedCarPositionsRoot = getChild(self.rootNodeId, "parkedCars")
	if parkedCarPositionsRoot == 0 then
		Logging.warning("No 'parkedCars' transform group found as a child of traffic system root %q", getName(self.rootNodeId))
	else
		local splines = {}
		I3DUtil.iterateRecursively(self.rootNodeId, function(node)
			if I3DUtil.getIsSpline(node) then
				splines[node] = true
			end
		end)
		print(string.format("found %d traffic system splines", table.size(splines)))
		if g_currentMission.aiSystem ~= nil then
			local numSplines = table.size(splines)
			g_currentMission.aiSystem:getRoadSplines(splines)
			numSplines = table.size(splines) - numSplines
			print(string.format("found %d ai navigation splines", numSplines))
		end
		local px = nil
		local py = nil
		local pz = nil
		local sx = nil
		local sy = nil
		local sz = nil
		local raycastCollisionMask = CollisionFlag.TERRAIN + CollisionFlag.ROAD + CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING
		local alreadyReported = {}
		for i, parkedCar in I3DUtil.iteratorChildren(parkedCarPositionsRoot) do
			px, py, pz = getWorldTranslation(parkedCar)
			local hitNode, cx, cy, cz = RaycastUtil.raycastClosest(px, py + 0.5, pz, 0, -1, 0, 3, raycastCollisionMask)
			if hitNode ~= nil then
				local distance = py - cy
				if 0.05 < math.abs(distance) then
					local text = string.format("parkedCar position %q (child %d) not aligned with terrain/collision %s at %d %d, distance %.3f", getName(parkedCar), getChildIndex(parkedCar), getName(hitNode), px, pz, distance)
					Logging.error(text)
					DebugLine.new():createWithStartAndEndPos(px, py, pz, cx, cy, cz):setText(text):setColor(Color.PRESETS.RED):addToManager()
				end
			end
			if py + 0.5 < getTerrainHeightAtWorldPos(g_terrainNode, px, py, pz) then
				local text = string.format("parkedCar position %q (child %d) is below the terrain at %d %d %d", getName(parkedCar), getChildIndex(parkedCar), px, py, pz)
				Logging.error(text)
				DebugPoint.new():createWithWorldPos(px, py, pz):setText(text):setColor(Color.PRESETS.RED):addToManager()
			end
			for spline in pairs(splines) do
				sx, sy, sz = getClosestSplinePosition(spline, px, py, pz, 0.5)
				if MathUtil.vector3Length(px - sx, py - sy, pz - sz) < 3 then
					local text = string.format("parkedCar position %q (child %d) close to spline %q at %d %d", getName(parkedCar), getChildIndex(parkedCar), getName(spline), px, pz)
					Logging.warning(text)
					DebugLine.new():createWithStartAndEndPos(px, py, pz, sx, sy, sz):setText(text):setColor(Color.PRESETS.RED):addToManager()
				end
			end
			for i, parkedCar2 in I3DUtil.iteratorChildren(parkedCarPositionsRoot) do
				if parkedCar == parkedCar2 or alreadyReported[parkedCar] then
					continue
				end
				local distance = calcDistanceFrom(parkedCar, parkedCar2)
				if distance < 2 then
					local text = string.format("parkedCar position %q (child %d) too close (%.3fm) to other parked car position %q (child %d)", getName(parkedCar), getChildIndex(parkedCar), distance, getName(parkedCar2), getChildIndex(parkedCar2))
					Logging.error(text)
					DebugText.new():createWithNode(parkedCar, text):setColor(Color.PRESETS.RED):addToManager()
					alreadyReported[parkedCar2] = true
				end
			end
		end
		print(string.format("checked %d parked car positions against %d splines", getNumOfChildren(parkedCarPositionsRoot), table.size(splines)))
	end
end
function TrafficSystem:consoleCommandToggleDebugRendering()
	self.debugIsEnabled = not self.debugIsEnabled
	if self.trafficSystemId ~= nil then
		setTrafficSystemRenderCollisionGeometry(self.trafficSystemId, self.debugIsEnabled)
		executeConsoleCommand("enableTrafficDebugRendering " .. tostring(self.debugIsEnabled), true)
	end
	if self.debugIsEnabled then
		g_debugManager:addDrawable(self)
	else
		g_debugManager:removeDrawable(self)
	end
	return "TrafficSystem Debug: " .. tostring(self.debugIsEnabled)
end
function TrafficSystem:consoleCommandValidate()
	if self.trafficSystemId == nil then
		printError("Error: no traffic system available")
		return
	end
	self:validateSplines()
	self:validateParkingPositions()
	local xmlDirectory = Utils.getDirectory(self.xmlFilename)
	print("checking vehicle config files")
	local xmlFile = XMLFile.load("trafficSystemXMLValidation", self.xmlFilename, TrafficSystem.xmlSchema)
	if xmlFile == nil then
		return
	else
		setFileLogPrefixTimestamp(false)
		for _, key in xmlFile:iterator("trafficSystem.vehicles.vehicle") do
			local vehicleXmlFilepath = Utils.getFilename(xmlFile:getValue(key .. "#filename"), xmlDirectory)
			if vehicleXmlFilepath == nil or vehicleXmlFilepath == "" then
				Logging.xmlError(xmlFile, "Missing 'filename' attribute for vehicle %q", key)
			else
				print(string.format("\nchecking %s", vehicleXmlFilepath))
				local vehicleXmlFile = XMLFile.load("trafficSystemVehicleXMLValidation", vehicleXmlFilepath, TrafficSystem.xmlSchemaVehicle)
				if vehicleXmlFile == nil then
					continue
				end
				local vehicleI3dFilename = vehicleXmlFile:getValue("vehicle.assets#filename")
				vehicleI3dFilename = Utils.getFilename(vehicleI3dFilename, xmlDirectory)
				if vehicleI3dFilename == nil or vehicleI3dFilename == "" then
					Logging.xmlError(vehicleXmlFile, "Missing vehicle.assets#filename")
				else
					local vehicleI3d = g_i3DManager:loadI3DFile(vehicleI3dFilename, false, false)
					if vehicleI3d == 0 then
						vehicleXmlFile:delete()
					else
						local components = I3DUtil.loadI3DComponents(vehicleI3d)
						vehicleXmlFile:getValue("vehicle.assets#driverNode", nil, components)
						vehicleXmlFile:getValue("vehicle.assets.collisionGeometry#node", nil, components)
						vehicleXmlFile:getValue("vehicle.assets.licensePlates#frontNode", nil, components)
						vehicleXmlFile:getValue("vehicle.assets.licensePlates#backNode", nil, components)
						for _, wheelKey in vehicleXmlFile:iterator("vehicle.assets.wheels.wheel") do
							local xRotNode = vehicleXmlFile:getValue(wheelKey .. "#xRotNode", nil, components)
							local wheelDistanceToPivot = nil
							if xRotNode ~= nil then
								local x, y, z = getWorldTranslation(xRotNode)
								local radius = vehicleXmlFile:getValue(wheelKey .. "#radius")
								local maxDiff = y * 0.1
								Assert.areRoughlyEqual(radius, y, maxDiff, "wheel pivot y-height and wheel radius in xml are different for %q", wheelKey)
								wheelDistanceToPivot = MathUtil.vector2Length(x, z)
								if z < 0 then
									wheelDistanceToPivot = -wheelDistanceToPivot
								end
							end
							local yRotNode = vehicleXmlFile:getValue(wheelKey .. "#yRotNode", nil, components)
							local rx, ry, rz = getWorldRotation(yRotNode)
							if rx == 0 then
								local _v21 = ry == 0 or rz == 0
							end
							Assert.isTrue(_v21, "wheel %q or its parent node rotation is not 0 0 0", getName(yRotNode))
							local distToRotCenter = vehicleXmlFile:getValue(wheelKey .. "#distToRotCenter")
							if wheelDistanceToPivot == nil or distToRotCenter == nil or distToRotCenter == 0 then
								continue
							end
							local threshold = math.abs(wheelDistanceToPivot) * 0.1
							Assert.areRoughlyEqual(distToRotCenter, wheelDistanceToPivot, threshold, "wheel %q distToRotCenter %f does not match longitudinal position relative to vehicle pivot (expected ~%f)", wheelKey, distToRotCenter, wheelDistanceToPivot)
						end
						local lightDecoration = vehicleXmlFile:getValue("vehicle.assets.lights.light#decoration", nil, components)
						if lightDecoration ~= nil then
							Assert.isTrue(getHasClassId(lightDecoration, ClassIds.SHAPE), "light decoration %q is not a shape", getName(lightDecoration))
						end
						vehicleXmlFile:getValue("vehicle.assets.lights.light#lowProfile", nil, components)
						vehicleXmlFile:getValue("vehicle.assets.lights.light#highProfile", nil, components)
						local tlLeftDecoration = vehicleXmlFile:getValue("vehicle.assets.lights.turnLeft#decoration", nil, components)
						if tlLeftDecoration ~= nil then
							Assert.isTrue(getHasClassId(tlLeftDecoration, ClassIds.SHAPE), "turn left decoration %q is not a shape", getName(tlLeftDecoration))
						end
						local tlRightDecoration = vehicleXmlFile:getValue("vehicle.assets.lights.turnRight#decoration", nil, components)
						if tlRightDecoration ~= nil then
							Assert.isTrue(getHasClassId(tlRightDecoration, ClassIds.SHAPE), "turn right decoration %q is not a shape", getName(tlRightDecoration))
						end
						local brakeDecoration = vehicleXmlFile:getValue("vehicle.assets.lights.brake#decoration", nil, components)
						if brakeDecoration ~= nil then
							Assert.isTrue(getHasClassId(brakeDecoration, ClassIds.SHAPE), "brake decoration %q is not a shape", getName(brakeDecoration))
						end
						for _, colorNodePath in vehicleXmlFile:iterator("vehicle.assets.colors.colorNodes.colorNode") do
							local colorNode = vehicleXmlFile:getValue(colorNodePath .. "#node", nil, components)
							if colorNode == nil then
								continue
							end
							Assert.isTrue(getHasClassId(colorNode, ClassIds.SHAPE), "colorNode %q at %q is not a shape", getName(colorNode), colorNodePath)
						end
						local colPreset = CollisionPreset.TRAFFIC_VEHICLE
						I3DUtil.iterateRecursively(vehicleI3d, function(node)
							if getHasClassId(node, ClassIds.SHAPE) and getRigidBodyType(node) ~= RigidBodyType.NONE then
								local group, mask = getCollisionFilter(node)
								Assert.areEqual(group, colPreset.group, "collision filter group for node %q does not match the 'TRAFFIC_VEHICLE' preset", I3DUtil.getNodePath(node))
								Assert.areEqual(mask, colPreset.mask, "collision filter mask for node %q does not match the 'TRAFFIC_VEHICLE' preset", I3DUtil.getNodePath(node))
							end
						end)
						delete(vehicleI3d)
						vehicleXmlFile:delete()
					end
				end
			end
		end
		xmlFile:delete()
		setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
	end
end
function TrafficSystem:consoleCommandTrafficSystemReload()
	local oldTrafficSystem = g_currentMission:getTrafficSystem()
	if oldTrafficSystem == nil or oldTrafficSystem.trafficSystemId == nil then
		return "Error: No traffic system to reload"
	end
	local xmlFilename = oldTrafficSystem.xmlFilename
	local transformId = oldTrafficSystem.rootNodeId
	local debugWasEnabled = oldTrafficSystem.debugIsEnabled
	oldTrafficSystem:delete()
	if TrafficSystem:onCreate(transformId) then
		if debugWasEnabled then
			local newTrafficSystem = g_currentMission:getTrafficSystem()
			newTrafficSystem:consoleCommandToggleDebugRendering()
		end
		return string.format("Reloaded traffic system from '%s'", xmlFilename)
	else
		return "Error while reloading traffic system"
	end
end
function TrafficSystem:consoleCommandTrafficSystemDebugLights(mode)
	local trafficVehiclesRootNode = getChild(getRootNode(), "TrafficSystemVehicles")
	if trafficVehiclesRootNode == 0 then
		return "No traffic vehicles found"
	else
		if not self.debugIsEnabled and mode ~= nil then
			self:consoleCommandToggleDebugRendering()
		end
		local isLight = mode == "light"
		local isLeft = mode == "left"
		local isRight = mode == "right"
		local isBrake = mode == "brake"
		local xmlFile = XMLFile.load("trafficSystemLightDebug", self.xmlFilename)
		local xmlDirectory = Utils.getDirectory(self.xmlFilename)
		local vehicleFilenames = {}
		local vehicleFilepaths = {}
		for _, vehicleKey in xmlFile:iterator("trafficSystem.vehicles.vehicle") do
			local filepath = Utils.getFilename(xmlFile:getString(vehicleKey .. "#filename"), xmlDirectory)
			table.insert(vehicleFilenames, Utils.getFilenameFromPath(filepath))
			table.insert(vehicleFilepaths, filepath)
		end
		xmlFile:delete()
		for i = 0, getNumOfChildren(trafficVehiclesRootNode) - 1 do
			local trafficVehicle = getChildAt(trafficVehiclesRootNode, i)
			local vehicleName = getName(trafficVehicle)
			local bestMatch = Utils.getClosestMatchingString(vehicleName, vehicleFilenames, 5, false)
			if bestMatch == nil then
				Logging.warning("Unable to find xmlFile for vehicle %q", vehicleName)
			else
				local index = table.find(vehicleFilenames, bestMatch)
				local vehicleXmlFilepath = Utils.getFilename(vehicleFilepaths[index])
				local vehicleXmlFile = XMLFile.load("trafficSystemLightDebugVehicle", vehicleXmlFilepath)
				local components = { { node = trafficVehicle } }
				local lightDecoration = vehicleXmlFile:getNode("vehicle.assets.lights.light#decoration", nil, components)
				if lightDecoration ~= nil then
					setShaderParameter(lightDecoration, "lightIds0", isLight and 1 or 0, nil, nil, nil, false)
					setShaderParameter(lightDecoration, "lightTypeBitMask", isLight and 5 or 0, nil, nil, nil, false)
					if isLight then
						log("enabled light for", vehicleName, vehicleXmlFilepath)
					end
				end
				local tlLeftDecoration = vehicleXmlFile:getNode("vehicle.assets.lights.turnLeft#decoration", nil, components)
				if tlLeftDecoration ~= nil then
					setShaderParameter(tlLeftDecoration, "lightIds0", isLeft and 1 or 0, nil, nil, nil, false)
					setShaderParameter(tlLeftDecoration, "lightTypeBitMask", isLeft and 5 or 0, nil, nil, nil, false)
					if isLeft then
						log("enabled turnLightLeft for", vehicleName, vehicleXmlFilepath)
					end
				end
				local tlRightDecoration = vehicleXmlFile:getNode("vehicle.assets.lights.turnRight#decoration", nil, components)
				if tlRightDecoration ~= nil then
					setShaderParameter(tlRightDecoration, "lightIds0", isRight and 1 or 0, nil, nil, nil, false)
					setShaderParameter(tlRightDecoration, "lightTypeBitMask", isRight and 5 or 0, nil, nil, nil, false)
					if isRight then
						log("enabled turnLightRight for", vehicleName, vehicleXmlFilepath)
					end
				end
				local brakeDecoration = vehicleXmlFile:getNode("vehicle.assets.lights.brake#decoration", nil, components)
				if brakeDecoration ~= nil then
					setShaderParameter(brakeDecoration, "lightIds0", isBrake and 1 or 0, nil, nil, nil, false)
					setShaderParameter(brakeDecoration, "lightTypeBitMask", isBrake and 5 or 0, nil, nil, nil, false)
					if isBrake then
						log("enabled brakeLight for", vehicleName, vehicleXmlFilepath)
					end
				end
				vehicleXmlFile:delete()
			end
		end
		return string.format("Updated light debug for parked cars light=%s, left=%s, right=%s, brake=%s", isLight, isLeft, isRight, isBrake)
	end
end
