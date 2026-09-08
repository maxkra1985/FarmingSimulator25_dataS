-- Local values: TrafficSystem_mt
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
	local v2_ = TrafficSystem.xmlSchema
	v2_:register(XMLValueType.STRING, "trafficSystem#licensePlates", "i3d filepath containing licenceplates (TGs on i3d root level with front and back plate as children) to link to traffic vehicles")
	v2_:register(XMLValueType.UINT, "trafficSystem#maxNumVehicles", "Maximum number of active traffic vehicles (no more than 30)")
	v2_:register(XMLValueType.STRING, "trafficSystem.vehicles.vehicle(?)#filename", "traffic vehicle xml filepath")
	v2_:register(XMLValueType.FLOAT, "trafficSystem.vehicles.vehicle(?)#probability")
	v2_:register(XMLValueType.FLOAT, "trafficSystem.vehicles.vehicle(?)#probabilityParked")
	v2_:register(XMLValueType.UINT, "trafficSystem.vehicles.vehicle(?)#typeFlag", "Bitmask flag (2^n) determining which splines the vehicle will drive on. Filtered by the splines bitmask set with the \'vehicleTypes\' user attribute where at least one bit has to match.", "uint max val / all bits")
	local v3_ = TrafficSystem.xmlSchemaVehicle
	v3_:register(XMLValueType.FLOAT, "vehicle#topSpeed", "maximum speed in kph")
	v3_:register(XMLValueType.FLOAT, "vehicle#accel", "acceleration in m/s\194\178")
	v3_:register(XMLValueType.STRING, "vehicle.assets#filename")
	v3_:register(XMLValueType.STRING, "vehicle.assets#filenameParked")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets#driverNode", "driver node, hidden when vehicle is parked. Use \'vehicle.assets.drivers.driver(?)\' for defining multiple drivers")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets#roadSideLimitDistanceFromFront", "optional z offset adjusting the pivot used for placing the vehicle on the spline")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets.drivers.driver(?)#node", "driver node, hidden when vehicle is parked. Use if more than one driver is supposed to be defined and delete \'vehicle.assets#driverNode\' entry")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets.collisionGeometry#node", "transform group where the collision trigger will be dynamically created at runtime")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.collisionGeometry#width")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.collisionGeometry#height")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets.licensePlates#frontNode", "node where license plates from i3d file defined in trafficSystem xml file are linked to")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets.licensePlates#backNode", "node where license plates from i3d file defined in trafficSystem xml file are linked to")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets.wheels.wheel(?)#yRotNode", "node rotated on its y axis when steering, e.g. brakeCalipers as parent of wheel", nil, true)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets.wheels.wheel(?)#xRotNode", "node rotated on x axis, e.g. wheel", nil, true)
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.wheels.wheel(?)#radius", "radius of the wheel used for calculating the rotation speed", nil, true)
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.wheels.wheel(?)#distToRotCenter", "", nil, true)
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets.lights.light#node")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets.lights.light#decoration")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.lights.light#intensity")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets.lights.light#lowProfile")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets.lights.light#highProfile")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets.lights.turnLeft#decoration")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.lights.turnLeft#intensity")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets.lights.turnRight#decoration")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.lights.turnRight#intensity")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets.lights.brake#decoration")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.lights.brake#intensity")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.lights.brake#regularIntensity")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.colors#minDirt")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.colors#maxDirt")
	v3_:register(XMLValueType.NODE_INDEX, "vehicle.assets.colors.colorNodes.colorNode(?)#node")
	v3_:register(XMLValueType.VECTOR_3, "vehicle.assets.colors.availableColors.color(?)#rgb", "triplet of rgb color with range [0..1]")
	v3_:register(XMLValueType.STRING, "vehicle.assets.sounds.motor#filename")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#indoorVolume")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#outdoorVolume")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#range")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#innerRange")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#indoorLowpassGain")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#outdoorLowpassGain")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#indoorLowpassCutoffFrequency")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#indoorLowpassResonance")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#outdoorLowpassCutoffFrequency")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#outdoorLowpassResonance")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#pitchMin")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor#pitchMax")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor.pitch(?)#velocity")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor.pitch(?)#pitchOffset")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.motor.pitch(?)#pitchScale")
	v3_:register(XMLValueType.STRING, "vehicle.assets.sounds.honk#filename")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#indoorVolume")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#outdoorVolume")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#range")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#innerRange")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#innerRange")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#indoorLowpassGain")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#outdoorLowpassGain")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#indoorLowpassCutoffFrequency")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#indoorLowpassResonance")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#outdoorLowpassResonance")
	v3_:register(XMLValueType.FLOAT, "vehicle.assets.sounds.honk#outdoorLowpassCutoffFrequency")
end)

-- Local values: xmlFilename, existingTrafficSystem, lightsProfile, useHighProfile, trafficSystem
function TrafficSystem:onCreate(transformId)
	local v5_ = getUserAttribute(transformId, "xmlFile")
	if v5_ == nil then
		Logging.error("Missing xmlFile attribute for traffic system in node %q", I3DUtil.getNodePath(transformId))
		return false
	end
	if not GS_IS_EDITOR then
		local v6_ = g_currentMission:getTrafficSystem()
		if v6_ ~= nil and v6_.trafficSystemId ~= nil then
			Logging.error("Traffic system already present")
			return false
		end
		local v7_ = Utils.getFilename(v5_, g_currentMission.loadedMapBaseDirectory)
		local v8_ = (Platform.gameplay.lightsProfile or g_gameSettings:getValue(GameSettings.SETTING.LIGHTS_PROFILE)) >= GS_PROFILE_HIGH
		local v9_ = TrafficSystem.new(g_server ~= nil, g_client ~= nil)
		if not v9_:load(v7_, transformId, v8_, g_server ~= nil, g_client ~= nil) then
			v9_:delete()
			return false
		end
		v9_:register(true)
		if g_currentMission.missionDynamicInfo.isMultiplayer then
			g_currentMission.onCreateObjectSystem:add(v9_)
		end
		v9_:setEnabled(g_currentMission.missionInfo.trafficEnabled)
		g_currentMission:setTrafficSystem(v9_)
		return true
	end
end

-- Upvalues: TrafficSystem_mt
-- Local values: self
function TrafficSystem.new(isServer, isClient, customMt)
	-- upvalues: (copy) TrafficSystem_mt
	local v13_ = Object.new(isServer, isClient, customMt or TrafficSystem_mt)
	v13_.trafficSystemId = nil
	v13_.isEnabled = false
	v13_.debugIsEnabled = false
	v13_.trafficSystemDirtyFlag = v13_:getNextDirtyFlag()
	addConsoleCommand("gsTrafficSystemToggleDebug", "Enables debug rendering for the collision geometry", "consoleCommandToggleDebugRendering", v13_)
	addConsoleCommand("gsTrafficSystemValidate", "Validates traffic system setup", "consoleCommandValidate", v13_)
	if isServer and not g_currentMission.missionDynamicInfo.isMultiplayer then
		addConsoleCommand("gsTrafficSystemReload", "Reloads traffic system", "consoleCommandTrafficSystemReload", v13_)
		addConsoleCommand("gsTrafficSystemLightsDebug", "Reloads traffic system", "consoleCommandTrafficSystemDebugLights", v13_, "light|left|right|brake")
	end
	return v13_
end

-- Local values: trafficSystemId
function TrafficSystem:load(xmlFilename, transformId, useHighProfile, isServer, isClient)
	local v20_ = createTrafficSystem(xmlFilename, transformId, useHighProfile, isServer, isClient, AudioGroup.ENVIRONMENT)
	if v20_ == 0 then
		Logging.error("Unable to create TrafficSystem from \'%s\' and \'%s\'", xmlFilename, I3DUtil.getNodePath(transformId))
		return false
	end
	self.trafficSystemId = v20_
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

-- Local values: daylight
function TrafficSystem:updateNightTimeRange()
	local v41_ = g_currentMission.environment.daylight
	self:setNightTimeRange(v41_.logicalNightStart, v41_.logicalNightEnd)
end

function TrafficSystem:onDaylightChanged()
	self:updateNightTimeRange()
end

-- Local values: trafficVehiclesRootNode, textLineNumber, i, trafficVehicle, x, y, z, name, dx, dy, dz
function TrafficSystem:drawDebug()
	local v43_ = getChild(getRootNode(), "TrafficSystemVehicles")
	if v43_ ~= 0 then
		local v44_ = 0
		for v45_ = 0, getNumOfChildren(v43_) - 1 do
			local v46_ = getChildAt(v43_, v45_)
			local v47_, v48_, v49_ = getWorldTranslation(v46_)
			local v50_ = getName(v46_)
			if DebugUtil.isPositionInCameraRange(v47_, v48_, v49_, 100) then
				local v51_, v52_, v53_ = localDirectionToWorld(v46_, 0, 0, 1)
				DebugGizmo.renderAtPosition(v47_, v48_, v49_, v51_, v52_, v53_, 0, 1, 0, v50_, false)
			end
			if getRigidBodyType(v46_) == RigidBodyType.KINEMATIC then
				renderText(0.85, 0.7 - v44_ * 0.012, 0.012, v50_)
				renderText(0.92, 0.7 - v44_ * 0.012, 0.012, string.format("%d %d %d", v47_, v48_, v49_))
				v44_ = v44_ + 1
			end
		end
	end
end

-- Local values: debugElementsGroupName, raycastHeightOverSpline, raycastLength, heightDiffThreshold, numProblems, rcy, raycastCallbackTarget, validCollisionFlags
function TrafficSystem:validateSplines()
	local v_u_55_ = "trafficSystemValidation"
	g_debugManager:removeGroup("trafficSystemValidation")
	local v_u_56_ = 5
	local v_u_57_ = 15
	local v_u_58_ = 0.45
	local v_u_59_ = 0
	local v_u_60_ = nil
	local v_u_62_ = {
		["raycastCallback"] = function(_, _, _, p61_, _, _, _, _, _, _, _, _)
			-- upvalues: (ref) v_u_60_
			v_u_60_ = p61_
		end
	}
	local v_u_63_ = CollisionFlag.getFlagsStringFromMask(self.groundMask)
	I3DUtil.iterateRecursively(self.rootNodeId, function(p64_, p65_)
		-- upvalues: (copy) self, (ref) v_u_59_, (ref) v_u_60_, (copy) v_u_62_, (copy) v_u_63_, (copy) v_u_56_, (copy) v_u_57_, (copy) v_u_58_, (copy) v_u_55_
		if I3DUtil.getIsSpline(p64_) then
			local v66_ = getName(p64_)
			local v67_ = getSplineLength(p64_)
			local v68_ = 1 / v67_
			if p65_ > 0 and v67_ > 50 then
				Logging.warning("Spline %q is a crossroad (child of a transform group) but is longer than 50m. Is this intentional?", I3DUtil.getNodePath(p64_, self.rootNodeId))
				v_u_59_ = v_u_59_ + 1
			end
			for v69_ = 0, 1 + v68_, v68_ do
				local v70_ = math.clamp(v69_, 0, 1)
				local v71_, v72_, v73_ = getSplinePosition(p64_, v70_)
				v_u_60_ = nil
				raycastClosest(v71_, v72_ + 5, v73_, 0, -1, 0, 15, "raycastCallback", v_u_62_, self.groundMask)
				if v_u_60_ ~= nil then
					local v74_ = v72_ - v_u_60_
					if math.abs(v74_) > 0.45 then
						local v75_ = SplineUtil.getClosestEditPoint(p64_, v71_, v72_, v73_) or -1
						local v76_ = string.format("%s\ntime=%.3f closestEP=%d\nx=%d y=%d z=%d\noffset to col: %.2f", v66_, v70_, v75_, v71_, v72_, v73_, v74_)
						DebugPoint.new():createWithWorldPos(v71_, v72_, v73_):setText(v76_):setColor(Color.PRESETS.RED):addToManager("trafficSystemValidation")
						DebugLine.new():createWithStartAndEndPos(v71_, v72_, v73_, v71_, v_u_60_, v73_, false, false):setColor(Color.PRESETS.RED):addToManager("trafficSystemValidation")
						Logging.warning("Spot %d %d %d (t=%.3f, EP=%d) on spline %s is more than %.1fm away from the next valid collision (raycasting against CollisionFlags: %s)", v71_, v72_, v73_, v70_, v75_, v66_, v74_, v_u_63_)
						v_u_59_ = v_u_59_ + 1
					end
				end
			end
		end
	end)
	Logging.info("Finished traffic system spline analysis, found %d problematic spots", v_u_59_)
end

-- Local values: parkedCarPositionsRoot, splines, numSplines, px, py, pz, sx, sy, sz, raycastCollisionMask, alreadyReported, i, parkedCar, hitNode, cx, cy, cz, distance, text, text, spline, text, i, parkedCar2, distance, text
function TrafficSystem:validateParkingPositions()
	print("validating parked car positions")
	local v78_ = getChild(self.rootNodeId, "parkedCars")
	if v78_ == 0 then
		Logging.warning("No \'parkedCars\' transform group found as a child of traffic system root %q", getName(self.rootNodeId))
	else
		local v_u_79_ = {}
		I3DUtil.iterateRecursively(self.rootNodeId, function(p80_)
			-- upvalues: (copy) v_u_79_
			if I3DUtil.getIsSpline(p80_) then
				v_u_79_[p80_] = true
			end
		end)
		print(string.format("found %d traffic system splines", table.size(v_u_79_)))
		if g_currentMission.aiSystem ~= nil then
			local v81_ = table.size(v_u_79_)
			g_currentMission.aiSystem:getRoadSplines(v_u_79_)
			local v82_ = table.size(v_u_79_) - v81_
			print(string.format("found %d ai navigation splines", v82_))
		end
		local v83_ = CollisionFlag.TERRAIN + CollisionFlag.ROAD + CollisionFlag.STATIC_OBJECT + CollisionFlag.BUILDING
		local v84_ = {}
		for _, v85_ in I3DUtil.iteratorChildren(v78_) do
			local v86_, v87_, v88_ = getWorldTranslation(v85_)
			local v89_, v90_, v91_, v92_ = RaycastUtil.raycastClosest(v86_, v87_ + 0.5, v88_, 0, -1, 0, 3, v83_)
			if v89_ ~= nil then
				local v93_ = v87_ - v91_
				if math.abs(v93_) > 0.05 then
					local v94_ = string.format("parkedCar position %q (child %d) not aligned with terrain/collision %s at %d %d, distance %.3f", getName(v85_), getChildIndex(v85_), getName(v89_), v86_, v88_, v93_)
					Logging.error(v94_)
					DebugLine.new():createWithStartAndEndPos(v86_, v87_, v88_, v90_, v91_, v92_):setText(v94_):setColor(Color.PRESETS.RED):addToManager()
				end
			end
			if getTerrainHeightAtWorldPos(g_terrainNode, v86_, v87_, v88_) > v87_ + 0.5 then
				local v95_ = string.format("parkedCar position %q (child %d) is below the terrain at %d %d %d", getName(v85_), getChildIndex(v85_), v86_, v87_, v88_)
				Logging.error(v95_)
				DebugPoint.new():createWithWorldPos(v86_, v87_, v88_):setText(v95_):setColor(Color.PRESETS.RED):addToManager()
			end
			for v96_ in pairs(v_u_79_) do
				local v97_, v98_, v99_ = getClosestSplinePosition(v96_, v86_, v87_, v88_, 0.5)
				if MathUtil.vector3Length(v86_ - v97_, v87_ - v98_, v88_ - v99_) < 3 then
					local v100_ = string.format("parkedCar position %q (child %d) close to spline %q at %d %d", getName(v85_), getChildIndex(v85_), getName(v96_), v86_, v88_)
					Logging.warning(v100_)
					DebugLine.new():createWithStartAndEndPos(v86_, v87_, v88_, v97_, v98_, v99_):setText(v100_):setColor(Color.PRESETS.RED):addToManager()
				end
			end
			for _, v101_ in I3DUtil.iteratorChildren(v78_) do
				if v85_ ~= v101_ and not v84_[v85_] then
					local v102_ = calcDistanceFrom(v85_, v101_)
					if v102_ < 2 then
						local v103_ = string.format("parkedCar position %q (child %d) too close (%.3fm) to other parked car position %q (child %d)", getName(v85_), getChildIndex(v85_), v102_, getName(v101_), getChildIndex(v101_))
						Logging.error(v103_)
						DebugText.new():createWithNode(v85_, v103_):setColor(Color.PRESETS.RED):addToManager()
						v84_[v101_] = true
					end
				end
			end
		end
		print(string.format("checked %d parked car positions against %d splines", getNumOfChildren(v78_), table.size(v_u_79_)))
	end
end

function TrafficSystem:consoleCommandToggleDebugRendering()
	self.debugIsEnabled = not self.debugIsEnabled
	if self.trafficSystemId ~= nil then
		setTrafficSystemRenderCollisionGeometry(self.trafficSystemId, self.debugIsEnabled)
		local v105_ = executeConsoleCommand
		local v106_ = self.debugIsEnabled
		v105_("enableTrafficDebugRendering " .. tostring(v106_), true)
	end
	if self.debugIsEnabled then
		g_debugManager:addDrawable(self)
	else
		g_debugManager:removeDrawable(self)
	end
	local v107_ = self.debugIsEnabled
	return "TrafficSystem Debug: " .. tostring(v107_)
end

-- Local values: xmlDirectory, xmlFile, _, key, vehicleXmlFilepath, vehicleXmlFile, vehicleI3dFilename, vehicleI3d, components, _, wheelKey, xRotNode, wheelDistanceToPivot, x, y, z, radius, maxDiff, yRotNode, rx, ry, rz, distToRotCenter, threshold, lightDecoration, tlLeftDecoration, tlRightDecoration, brakeDecoration, _, colorNodePath, colorNode, colPreset
function TrafficSystem:consoleCommandValidate()
	if self.trafficSystemId == nil then
		printError("Error: no traffic system available")
		return
	else
		self:validateSplines()
		self:validateParkingPositions()
		local v109_ = Utils.getDirectory(self.xmlFilename)
		print("checking vehicle config files")
		local v110_ = XMLFile.load("trafficSystemXMLValidation", self.xmlFilename, TrafficSystem.xmlSchema)
		if v110_ ~= nil then
			setFileLogPrefixTimestamp(false)
			for _, v111_ in v110_:iterator("trafficSystem.vehicles.vehicle") do
				local v112_ = Utils.getFilename(v110_:getValue(v111_ .. "#filename"), v109_)
				if v112_ == nil or v112_ == "" then
					Logging.xmlError(v110_, "Missing \'filename\' attribute for vehicle %q", v111_)
				else
					print(string.format("\nchecking %s", v112_))
					local v113_ = XMLFile.load("trafficSystemVehicleXMLValidation", v112_, TrafficSystem.xmlSchemaVehicle)
					if v113_ ~= nil then
						local v114_ = v113_:getValue("vehicle.assets#filename")
						local v115_ = Utils.getFilename(v114_, v109_)
						if v115_ == nil or v115_ == "" then
							Logging.xmlError(v113_, "Missing vehicle.assets#filename")
						else
							local v116_ = g_i3DManager:loadI3DFile(v115_, false, false)
							if v116_ == 0 then
								v113_:delete()
							else
								local v117_ = I3DUtil.loadI3DComponents(v116_)
								v113_:getValue("vehicle.assets#driverNode", nil, v117_)
								v113_:getValue("vehicle.assets.collisionGeometry#node", nil, v117_)
								v113_:getValue("vehicle.assets.licensePlates#frontNode", nil, v117_)
								v113_:getValue("vehicle.assets.licensePlates#backNode", nil, v117_)
								for _, v118_ in v113_:iterator("vehicle.assets.wheels.wheel") do
									local v119_ = v113_:getValue(v118_ .. "#xRotNode", nil, v117_)
									local v120_
									if v119_ == nil then
										v120_ = nil
									else
										local v121_, v122_, v123_ = getWorldTranslation(v119_)
										local v124_ = v113_:getValue(v118_ .. "#radius")
										local v125_ = v122_ * 0.1
										Assert.areRoughlyEqual(v124_, v122_, v125_, "wheel pivot y-height and wheel radius in xml are different for %q", v118_)
										v120_ = MathUtil.vector2Length(v121_, v123_)
										if v123_ < 0 then
											v120_ = -v120_
										end
									end
									local v126_ = v113_:getValue(v118_ .. "#yRotNode", nil, v117_)
									local v127_, v128_, v129_ = getWorldRotation(v126_)
									Assert.isTrue(v127_ == 0 and v128_ == 0 and true or v129_ == 0, "wheel %q or its parent node rotation is not 0 0 0", getName(v126_))
									local v130_ = v113_:getValue(v118_ .. "#distToRotCenter")
									if v120_ ~= nil and (v130_ ~= nil and v130_ ~= 0) then
										local v131_ = math.abs(v120_) * 0.1
										Assert.areRoughlyEqual(v130_, v120_, v131_, "wheel %q distToRotCenter %f does not match longitudinal position relative to vehicle pivot (expected ~%f)", v118_, v130_, v120_)
									end
								end
								local v132_ = v113_:getValue("vehicle.assets.lights.light#decoration", nil, v117_)
								if v132_ ~= nil then
									Assert.isTrue(getHasClassId(v132_, ClassIds.SHAPE), "light decoration %q is not a shape", getName(v132_))
								end
								v113_:getValue("vehicle.assets.lights.light#lowProfile", nil, v117_)
								v113_:getValue("vehicle.assets.lights.light#highProfile", nil, v117_)
								local v133_ = v113_:getValue("vehicle.assets.lights.turnLeft#decoration", nil, v117_)
								if v133_ ~= nil then
									Assert.isTrue(getHasClassId(v133_, ClassIds.SHAPE), "turn left decoration %q is not a shape", getName(v133_))
								end
								local v134_ = v113_:getValue("vehicle.assets.lights.turnRight#decoration", nil, v117_)
								if v134_ ~= nil then
									Assert.isTrue(getHasClassId(v134_, ClassIds.SHAPE), "turn right decoration %q is not a shape", getName(v134_))
								end
								local v135_ = v113_:getValue("vehicle.assets.lights.brake#decoration", nil, v117_)
								if v135_ ~= nil then
									Assert.isTrue(getHasClassId(v135_, ClassIds.SHAPE), "brake decoration %q is not a shape", getName(v135_))
								end
								for _, v136_ in v113_:iterator("vehicle.assets.colors.colorNodes.colorNode") do
									local v137_ = v113_:getValue(v136_ .. "#node", nil, v117_)
									if v137_ ~= nil then
										Assert.isTrue(getHasClassId(v137_, ClassIds.SHAPE), "colorNode %q at %q is not a shape", getName(v137_), v136_)
									end
								end
								local v_u_138_ = CollisionPreset.TRAFFIC_VEHICLE
								I3DUtil.iterateRecursively(v116_, function(p139_)
									-- upvalues: (copy) v_u_138_
									if getHasClassId(p139_, ClassIds.SHAPE) and getRigidBodyType(p139_) ~= RigidBodyType.NONE then
										local v140_, v141_ = getCollisionFilter(p139_)
										Assert.areEqual(v140_, v_u_138_.group, "collision filter group for node %q does not match the \'TRAFFIC_VEHICLE\' preset", I3DUtil.getNodePath(p139_))
										Assert.areEqual(v141_, v_u_138_.mask, "collision filter mask for node %q does not match the \'TRAFFIC_VEHICLE\' preset", I3DUtil.getNodePath(p139_))
									end
								end)
								delete(v116_)
								v113_:delete()
							end
						end
					end
				end
			end
			v110_:delete()
			setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
		end
	end
end

-- Local values: oldTrafficSystem, xmlFilename, transformId, debugWasEnabled, newTrafficSystem
function TrafficSystem:consoleCommandTrafficSystemReload()
	local v142_ = g_currentMission:getTrafficSystem()
	if v142_ == nil or v142_.trafficSystemId == nil then
		return "Error: No traffic system to reload"
	end
	local v143_ = v142_.xmlFilename
	local v144_ = v142_.rootNodeId
	local v145_ = v142_.debugIsEnabled
	v142_:delete()
	if not TrafficSystem:onCreate(v144_) then
		return "Error while reloading traffic system"
	end
	if v145_ then
		g_currentMission:getTrafficSystem():consoleCommandToggleDebugRendering()
	end
	return string.format("Reloaded traffic system from \'%s\'", v143_)
end

-- Local values: trafficVehiclesRootNode, isLight, isLeft, isRight, isBrake, xmlFile, xmlDirectory, vehicleFilenames, vehicleFilepaths, _, vehicleKey, filepath, i, trafficVehicle, vehicleName, bestMatch, index, vehicleXmlFilepath, vehicleXmlFile, components, lightDecoration, tlLeftDecoration, tlRightDecoration, brakeDecoration
function TrafficSystem:consoleCommandTrafficSystemDebugLights(mode)
	local v148_ = getChild(getRootNode(), "TrafficSystemVehicles")
	if v148_ == 0 then
		return "No traffic vehicles found"
	end
	if not self.debugIsEnabled and mode ~= nil then
		self:consoleCommandToggleDebugRendering()
	end
	local v149_ = mode == "light"
	local v150_ = mode == "left"
	local v151_ = mode == "right"
	local v152_ = mode == "brake"
	local v153_ = XMLFile.load("trafficSystemLightDebug", self.xmlFilename)
	local v154_ = Utils.getDirectory(self.xmlFilename)
	local v155_ = {}
	local v156_ = {}
	for _, v157_ in v153_:iterator("trafficSystem.vehicles.vehicle") do
		local v158_ = Utils.getFilename(v153_:getString(v157_ .. "#filename"), v154_)
		local v159_ = Utils.getFilenameFromPath
		table.insert(v155_, v159_(v158_))
		table.insert(v156_, v158_)
	end
	v153_:delete()
	for v160_ = 0, getNumOfChildren(v148_) - 1 do
		local v161_ = getChildAt(v148_, v160_)
		local v162_ = getName(v161_)
		local v163_ = Utils.getClosestMatchingString(v162_, v155_, 5, false)
		if v163_ == nil then
			Logging.warning("Unable to find xmlFile for vehicle %q", v162_)
		else
			local v164_ = table.find(v155_, v163_)
			local v165_ = Utils.getFilename(v156_[v164_])
			local v166_ = XMLFile.load("trafficSystemLightDebugVehicle", v165_)
			local v167_ = {
				{
					["node"] = v161_
				}
			}
			local v168_ = v166_:getNode("vehicle.assets.lights.light#decoration", nil, v167_)
			if v168_ ~= nil then
				setShaderParameter(v168_, "lightIds0", v149_ and 1 or 0, nil, nil, nil, false)
				setShaderParameter(v168_, "lightTypeBitMask", v149_ and 5 or 0, nil, nil, nil, false)
				if v149_ then
					log("enabled light for", v162_, v165_)
				end
			end
			local v169_ = v166_:getNode("vehicle.assets.lights.turnLeft#decoration", nil, v167_)
			if v169_ ~= nil then
				setShaderParameter(v169_, "lightIds0", v150_ and 1 or 0, nil, nil, nil, false)
				setShaderParameter(v169_, "lightTypeBitMask", v150_ and 5 or 0, nil, nil, nil, false)
				if v150_ then
					log("enabled turnLightLeft for", v162_, v165_)
				end
			end
			local v170_ = v166_:getNode("vehicle.assets.lights.turnRight#decoration", nil, v167_)
			if v170_ ~= nil then
				setShaderParameter(v170_, "lightIds0", v151_ and 1 or 0, nil, nil, nil, false)
				setShaderParameter(v170_, "lightTypeBitMask", v151_ and 5 or 0, nil, nil, nil, false)
				if v151_ then
					log("enabled turnLightRight for", v162_, v165_)
				end
			end
			local v171_ = v166_:getNode("vehicle.assets.lights.brake#decoration", nil, v167_)
			if v171_ ~= nil then
				setShaderParameter(v171_, "lightIds0", v152_ and 1 or 0, nil, nil, nil, false)
				setShaderParameter(v171_, "lightTypeBitMask", v152_ and 5 or 0, nil, nil, nil, false)
				if v152_ then
					log("enabled brakeLight for", v162_, v165_)
				end
			end
			v166_:delete()
		end
	end
	return string.format("Updated light debug for parked cars light=%s, left=%s, right=%s, brake=%s", v149_, v150_, v151_, v152_)
end
