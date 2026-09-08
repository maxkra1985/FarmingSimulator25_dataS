AIAutomaticSteering = {}
AIAutomaticSteering.LINE_END_SOUND_DISTANCE = 10
AIAutomaticSteering.CRUISE_CONTROL_DISABLE_DISTANCE = 1
AIAutomaticSteering.RESET_COURSE_TIME = 20000
AIAutomaticSteering.HEADING_LETTERS = {}
AIAutomaticSteering.HEADING_LETTERS[1] = "N"
AIAutomaticSteering.HEADING_LETTERS[2] = "NE"
AIAutomaticSteering.HEADING_LETTERS[3] = "E"
AIAutomaticSteering.HEADING_LETTERS[4] = "SE"
AIAutomaticSteering.HEADING_LETTERS[5] = "S"
AIAutomaticSteering.HEADING_LETTERS[6] = "SW"
AIAutomaticSteering.HEADING_LETTERS[7] = "W"
AIAutomaticSteering.HEADING_LETTERS[8] = "NW"
AIAutomaticSteering.STATE = {}
AIAutomaticSteering.STATE.DISABLED = 1
AIAutomaticSteering.STATE.AVAILABLE = 2
AIAutomaticSteering.STATE.ACTIVE = 3
Enum(AIAutomaticSteering.STATE)
source("dataS/scripts/vehicles/specializations/events/AIAutomaticSteeringCourseEvent.lua")
source("dataS/scripts/vehicles/specializations/events/AIAutomaticSteeringLineEndEvent.lua")
source("dataS/scripts/vehicles/specializations/events/AIAutomaticSteeringRequestEvent.lua")
source("dataS/scripts/vehicles/specializations/events/AIAutomaticSteeringStateEvent.lua")

function AIAutomaticSteering.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(Drivable, specializations)
end
function AIAutomaticSteering.initSpecialization()
	local v2_ = Vehicle.xmlSchema
	v2_:setXMLSpecializationType("AIAutomaticSteering")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.ai.automaticSteering.sounds", "engage")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.ai.automaticSteering.sounds", "disengage")
	SoundManager.registerSampleXMLPaths(v2_, "vehicle.ai.automaticSteering.sounds", "lineEnd")
	Dashboard.registerDashboardXMLPaths(v2_, "vehicle.ai.automaticSteering.dashboards", {
		"steeringEngaged",
		"steeringState",
		"heading",
		"headingLetter"
	})
	v2_:register(XMLValueType.FLOAT, "vehicle.ai.automaticSteering#lookAheadDistance", "Distance for aiming onto the wayline", "half of the vehicle length")
	v2_:setXMLSpecializationType()
	local v3_ = Vehicle.xmlSchemaSavegame
	SteeringFieldCourse.registerXMLPaths(v3_, "vehicles.vehicle(?).aiAutomaticSteering.steeringFieldCourse")
	SteeringFieldCourse.registerXMLPaths(v3_, "vehicles.vehicle(?).aiAutomaticSteering.lastActiveSteeringFieldCourse")
	v3_:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiAutomaticSteering#isOnField", "Is on field")
	v3_:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiAutomaticSteering#courseWasActive", "Current course was also the last active one")
end

function AIAutomaticSteering.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onAIAutomaticSteeringLineEnd")
end

function AIAutomaticSteering.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherToolWorkingWidth", AIAutomaticSteering.getAttacherToolWorkingWidth)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticSteeringAllowed", AIAutomaticSteering.getIsAutomaticSteeringAllowed)
	SpecializationUtil.registerFunction(vehicleType, "setAIAutomaticSteeringEnabled", AIAutomaticSteering.setAIAutomaticSteeringEnabled)
	SpecializationUtil.registerFunction(vehicleType, "setAIAutomaticSteeringCourse", AIAutomaticSteering.setAIAutomaticSteeringCourse)
	SpecializationUtil.registerFunction(vehicleType, "generateSteeringFieldCourse", AIAutomaticSteering.generateSteeringFieldCourse)
	SpecializationUtil.registerFunction(vehicleType, "getIsAIAutomaticSteeringAllowed", AIAutomaticSteering.getIsAIAutomaticSteeringAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getAIAutomaticSteeringState", AIAutomaticSteering.getAIAutomaticSteeringState)
	SpecializationUtil.registerFunction(vehicleType, "getAIAutomaticSteeringLookAheadDistance", AIAutomaticSteering.getAIAutomaticSteeringLookAheadDistance)
	SpecializationUtil.registerFunction(vehicleType, "getIsSideOffsetReversed", AIAutomaticSteering.getIsSideOffsetReversed)
end

function AIAutomaticSteering.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setSteeringInput", AIAutomaticSteering.setSteeringInput)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateVehiclePhysics", AIAutomaticSteering.updateVehiclePhysics)
end

function AIAutomaticSteering.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterDashboardValueTypes", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onAIModeChanged", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onAIModeSettingsChanged", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onAIAutomaticSteeringLineEnd", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onActivate", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AIAutomaticSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AIAutomaticSteering)
end

-- Local values: spec
function AIAutomaticSteering:onLoad(savegame)
	local v9_ = self.spec_aiAutomaticSteering
	v9_.lastIsOnField = false
	v9_.forceFieldCourseUpdate = false
	v9_.resetCourseTimer = 0
	v9_.steeringFieldCourse = nil
	v9_.lastActiveSteeringFieldCourse = nil
	v9_.fieldCourseDetectionInProgress = false
	v9_.fieldCourseDetectionPendingData = nil
	v9_.lastDistanceToEnd = 0
	v9_.steeringEnabled = false
	v9_.steeringLastEnableTime = -math.huge
	v9_.steeringLockedMovingDirection = 0
	v9_.steeringValue = 0
	v9_.lookAheadDistance = self.xmlFile:getValue("vehicle.ai.automaticSteering#lookAheadDistance")
	v9_.lastSteeringInputValue = 0
	if self.isClient then
		v9_.samples = {}
		v9_.samples.engage = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.ai.automaticSteering.sounds", "engage", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v9_.samples.disengage = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.ai.automaticSteering.sounds", "disengage", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		v9_.samples.lineEnd = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.ai.automaticSteering.sounds", "lineEnd", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end
	self:registerVehicleSetting(GameSettings.SETTING.STEERING_ASSIST_CRUISE_CONTROL, true)
	v9_.dirtyFlag = self:getNextDirtyFlag()
end

-- Local values: spec, courseWasActive
function AIAutomaticSteering:onPostLoad(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		local v_u_12_ = self.spec_aiAutomaticSteering
		local v_u_13_ = savegame.xmlFile:getValue(savegame.key .. ".aiAutomaticSteering#courseWasActive", false)
		v_u_12_.lastIsOnField = savegame.xmlFile:getValue(savegame.key .. ".aiAutomaticSteering#isOnField", v_u_12_.lastIsOnField)
		SteeringFieldCourse.loadFromXML(savegame.xmlFile, savegame.key .. ".aiAutomaticSteering.lastActiveSteeringFieldCourse", function(p14_)
			-- upvalues: (copy) v_u_12_
			if p14_ ~= nil then
				v_u_12_.lastActiveSteeringFieldCourse = p14_
			end
		end)
		SteeringFieldCourse.loadFromXML(savegame.xmlFile, savegame.key .. ".aiAutomaticSteering.steeringFieldCourse", function(p15_)
			-- upvalues: (copy) self, (copy) v_u_12_, (copy) v_u_13_
			if p15_ ~= nil then
				self:setAIAutomaticSteeringCourse(p15_, true)
				v_u_12_.forceFieldCourseUpdate = false
				if v_u_13_ then
					v_u_12_.lastActiveSteeringFieldCourse = p15_
				end
			end
		end)
	end
end

-- Local values: spec, steeringEngaged, steeringState, heading, headingLetter
function AIAutomaticSteering:onRegisterDashboardValueTypes()
	local v17_ = self.spec_aiAutomaticSteering
	local v18_ = DashboardValueType.new("ai.automaticSteering", "steeringEngaged")
	v18_:setValue(v17_, "steeringEnabled")
	v18_:setPollUpdate(false)
	self:registerDashboardValueType(v18_)
	local v19_ = DashboardValueType.new("ai.automaticSteering", "steeringState")
	v19_:setValue(v17_, function()
		-- upvalues: (copy) self
		return self:getAIAutomaticSteeringState() - 1
	end)
	v19_:setPollUpdate(false)
	self:registerDashboardValueType(v19_)
	local v20_ = DashboardValueType.new("ai.automaticSteering", "heading")
	v20_:setValue(v17_, function()
		-- upvalues: (copy) self
		local v21_, _, v22_ = localDirectionToWorld(self.rootNode, 0, 0, 1)
		local v23_ = MathUtil.getYRotationFromDirection(v21_, v22_)
		if v23_ < 0 then
			v23_ = v23_ + 6.283185307179586
		end
		return 360 - math.deg(v23_)
	end)
	self:registerDashboardValueType(v20_)
	local v24_ = DashboardValueType.new("ai.automaticSteering", "headingLetter")
	v24_:setValue(v17_, function()
		-- upvalues: (copy) self
		local v25_, _, v26_ = localDirectionToWorld(self.rootNode, 0, 0, -1)
		local v27_ = MathUtil.getYRotationFromDirection(v25_, v26_)
		if v27_ < 0 then
			v27_ = v27_ + 6.283185307179586
		end
		local v28_ = 360 - math.deg(v27_)
		if v28_ >= 337.5 or v28_ < 22.5 then
			return AIAutomaticSteering.HEADING_LETTERS[1]
		end
		if v28_ >= 22.5 and v28_ < 67.5 then
			return AIAutomaticSteering.HEADING_LETTERS[2]
		end
		if v28_ >= 67.5 and v28_ < 112.5 then
			return AIAutomaticSteering.HEADING_LETTERS[3]
		end
		if v28_ >= 112.5 and v28_ < 157.5 then
			return AIAutomaticSteering.HEADING_LETTERS[4]
		end
		if v28_ >= 157.5 and v28_ < 202.5 then
			return AIAutomaticSteering.HEADING_LETTERS[5]
		end
		if v28_ >= 202.5 and v28_ < 247.5 then
			return AIAutomaticSteering.HEADING_LETTERS[6]
		end
		if v28_ >= 247.5 and v28_ < 292.5 then
			return AIAutomaticSteering.HEADING_LETTERS[7]
		end
		if v28_ >= 292.5 and v28_ < 337.5 then
			return AIAutomaticSteering.HEADING_LETTERS[8]
		end
	end)
	self:registerDashboardValueType(v24_)
end

-- Local values: spec
function AIAutomaticSteering:onDelete()
	local v30_ = self.spec_aiAutomaticSteering
	if v30_.samples ~= nil then
		g_soundManager:deleteSamples(v30_.samples)
	end
end

-- Local values: spec
function AIAutomaticSteering:saveToXMLFile(xmlFile, key, usedModNames)
	local v34_ = self.spec_aiAutomaticSteering
	xmlFile:setValue(key .. "#courseWasActive", v34_.lastActiveSteeringFieldCourse == v34_.steeringFieldCourse)
	if v34_.lastActiveSteeringFieldCourse ~= nil and v34_.lastActiveSteeringFieldCourse ~= v34_.steeringFieldCourse then
		v34_.lastActiveSteeringFieldCourse:saveToXML(xmlFile, key .. ".lastActiveSteeringFieldCourse")
	end
	if v34_.steeringFieldCourse ~= nil then
		v34_.steeringFieldCourse:saveToXML(xmlFile, key .. ".steeringFieldCourse")
	end
	xmlFile:setValue(key .. "#isOnField", v34_.lastIsOnField)
end

function AIAutomaticSteering:onReadStream(streamId, connection)
	if streamReadBool(streamId) then
		SteeringFieldCourse.readStream(streamId, connection, function(p38_)
			-- upvalues: (copy) self
			self:setAIAutomaticSteeringCourse(p38_, true)
			self.spec_aiAutomaticSteering.lastIsOnField = true
			self.spec_aiAutomaticSteering.forceFieldCourseUpdate = false
		end)
	end
end

-- Local values: spec
function AIAutomaticSteering:onWriteStream(streamId, connection)
	local v42_ = self.spec_aiAutomaticSteering
	if streamWriteBool(streamId, v42_.steeringFieldCourse ~= nil) then
		v42_.steeringFieldCourse:writeStream(streamId, connection)
	end
end

function AIAutomaticSteering:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() and streamReadBool(streamId) then
		SteeringFieldCourse.readSegmentStatesFromStream(self.spec_aiAutomaticSteering.steeringFieldCourse, streamId, connection)
	end
end

-- Local values: spec
function AIAutomaticSteering:onWriteUpdateStream(streamId, connection, dirtyMask)
	local v50_ = self.spec_aiAutomaticSteering
	if not connection:getIsServer() then
		local v51_ = streamWriteBool
		local v52_ = v50_.dirtyFlag
		if v51_(streamId, bit32.band(dirtyMask, v52_) ~= 0) then
			v50_.steeringFieldCourse:writeSegmentStatesToStream(streamId, connection)
		end
	end
end

-- Local values: spec, lastSpeed, aiRootNode, reverserDirection, sideOffsetReversed, lookAheadDistance, x, _, z, dirX, _, dirZ, tX, tZ, distanceToEnd, tX_2, tZ_2, d1X, d1Z, hit, _, f2, rotTime, radius, targetRotTime
function AIAutomaticSteering:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v56_ = self.spec_aiAutomaticSteering
	if self:getAIModeSelection() == AIModeSelection.MODE.STEERING_ASSIST and v56_.steeringFieldCourse ~= nil then
		if isActiveForInputIgnoreSelection and VehicleDebug.state == VehicleDebug.DEBUG_AI then
			v56_.steeringFieldCourse:draw()
		end
		if self.isServer or isActiveForInputIgnoreSelection then
			local v57_ = self:getLastSpeed()
			local v58_ = self:getAIRootNode()
			local v59_ = self:getReverserDirection()
			local v60_ = self:getIsSideOffsetReversed()
			local v61_ = self:getAIAutomaticSteeringLookAheadDistance()
			local v62_
			if self.movingDirection < 0 and v57_ > 0.25 then
				v62_ = math.min(v61_, -4)
			else
				v62_ = math.max(v61_, 4)
			end
			local v63_ = v62_ * v59_
			local v64_ = math.sign(v63_)
			local v65_ = v57_ / 30
			local v66_ = math.min(v65_, 1)
			local v67_ = v63_ + v64_ * math.pow(v66_, 2) * 5
			local v68_, _, v69_ = localToWorld(v58_, 0, 0, v67_)
			local v70_, _, v71_ = localDirectionToWorld(v58_, 0, 0, 1)
			local v72_, v73_ = MathUtil.vector2Normalize(v70_, v71_)
			if v56_.steeringFieldCourse:updateVehicleData(dt, v56_.steeringEnabled, v68_, v69_, v72_, v73_, v60_) then
				AIAutomaticSteering.updateActionEvents(self)
			end
			if self.isServer then
				if v56_.steeringFieldCourse.currentSegment ~= nil and v56_.steeringEnabled then
					local v74_, v75_, v76_ = v56_.steeringFieldCourse:getSteeringTarget(v58_, v67_, v60_)
					if v74_ ~= 0 and v75_ ~= 0 then
						local v77_ = v74_ * 0.5
						local v78_ = v75_ * 0.5
						local v79_ = -v77_
						local v80_
						if v74_ > 0 then
							v80_ = -v78_
							v79_ = v77_
						else
							v80_ = v78_
						end
						local v81_, _, v82_ = MathUtil.getLineLineIntersection2D(v77_, v78_, v80_, v79_, 0, 0, v74_, 0)
						local v83_
						if v81_ and math.abs(v82_) < 100000 then
							v83_ = self:getSteeringRotTimeByCurvature(1 / (v74_ * v82_))
							if v59_ < 0 then
								v83_ = -v83_
							end
						else
							v83_ = 0
						end
						local v84_
						if v83_ >= 0 then
							local v85_ = self.maxRotTime
							v84_ = math.min(v83_, v85_)
						else
							local v86_ = self.minRotTime
							v84_ = math.max(v83_, v86_)
						end
						if v56_.steeringValue < v84_ then
							local v87_ = v56_.steeringValue + dt * self:getAISteeringSpeed()
							v56_.steeringValue = math.min(v87_, v84_)
						else
							local v88_ = v56_.steeringValue - dt * self:getAISteeringSpeed()
							v56_.steeringValue = math.max(v88_, v84_)
						end
						if v76_ == nil then
							v56_.lastDistanceToEnd = 0
						elseif v76_ ~= v56_.lastDistanceToEnd then
							if v56_.lastDistanceToEnd > AIAutomaticSteering.LINE_END_SOUND_DISTANCE and v76_ <= AIAutomaticSteering.LINE_END_SOUND_DISTANCE then
								SpecializationUtil.raiseEvent(self, "onAIAutomaticSteeringLineEnd")
								g_server:broadcastEvent(AIAutomaticSteeringLineEndEvent.new(self), nil, nil, self)
							end
							if self.isServer and (v56_.lastDistanceToEnd > AIAutomaticSteering.CRUISE_CONTROL_DISABLE_DISTANCE and (v76_ <= AIAutomaticSteering.CRUISE_CONTROL_DISABLE_DISTANCE and (self:getVehicleSettingState(GameSettings.SETTING.STEERING_ASSIST_CRUISE_CONTROL) and self.setCruiseControlState ~= nil))) then
								self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
							end
							v56_.lastDistanceToEnd = v76_
						end
					end
				end
				if v56_.steeringFieldCourse.segmentStatesDirty then
					self:raiseDirtyFlags(v56_.dirtyFlag)
					v56_.steeringFieldCourse.segmentStatesDirty = false
				end
			end
		end
	end
end

-- Local values: spec, x, _, z, isOnField, farmId, hasAccess, workingWidth, generateCourse, fieldCourseSettings, lastSpeed
function AIAutomaticSteering:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local v92_ = self.spec_aiAutomaticSteering
	if isActiveForInputIgnoreSelection and self:getAIModeSelection() == AIModeSelection.MODE.STEERING_ASSIST then
		local v93_, _, v94_ = localToWorld(self.rootNode, 0, 0, self.size.length * 0.5 + self.size.lengthOffset)
		local v95_, v96_ = g_fieldCourseManager:roundToTerrainDetailPixel(v93_, v94_)
		local v97_ = getDensityAtWorldPos(g_currentMission.terrainDetailId, v95_, 0, v96_) ~= 0
		if not v97_ then
			local v98_, _, v99_ = localToWorld(self.rootNode, 0, 0, -self.size.length * 0.5 + self.size.lengthOffset + 1)
			v95_, v96_ = g_fieldCourseManager:roundToTerrainDetailPixel(v98_, v99_)
			if getDensityAtWorldPos(g_currentMission.terrainDetailId, v95_, 0, v96_) == 0 then
				v97_ = false
			else
				v97_ = true
			end
		end
		local v100_ = self:getActiveFarm()
		if not (g_currentMission.accessHandler:canFarmAccessLand(v100_, v95_, v96_) or g_missionManager:getIsMissionWorkAllowed(v100_, v95_, v96_, nil, self)) then
			v97_ = false
		end
		if v97_ ~= v92_.lastIsOnField or v92_.forceFieldCourseUpdate then
			v92_.lastIsOnField = v97_
			if v97_ then
				v92_.resetCourseTimer = 0
				local v101_ = self:getAttacherToolWorkingWidth()
				local v102_ = true
				if v92_.steeringFieldCourse ~= nil and (not v92_.forceFieldCourseUpdate and v92_.steeringFieldCourse:getIsPointInsideBoundary(v95_, v96_)) then
					if v101_ == 0 then
						v102_ = false
					else
						local v103_ = v101_ - v92_.steeringFieldCourse.fieldCourseSettings.implementWidth
						if math.abs(v103_) < 0.05 then
							v102_ = false
						end
					end
				end
				if v102_ then
					self:initializeLoadedAIModeUserSettings()
					local v104_ = self:getAIModeFieldCourseSettings()
					if v104_ == nil then
						local v105_
						v104_, v105_ = FieldCourseSettings.generate(self.rootVehicle)
					end
					if VehicleDebug.state == VehicleDebug.DEBUG_AI then
						v104_:print()
					end
					g_client:getServerConnection():sendEvent(AIAutomaticSteeringRequestEvent.new(self, v95_, v96_, v104_))
				end
			else
				v92_.resetCourseTimer = AIAutomaticSteering.RESET_COURSE_TIME
			end
			v92_.forceFieldCourseUpdate = false
		end
		if not v97_ and (not v92_.steeringEnabled and v92_.resetCourseTimer > 0) then
			v92_.resetCourseTimer = v92_.resetCourseTimer - dt
			if v92_.resetCourseTimer <= 0 then
				self:setAIAutomaticSteeringCourse(nil)
			end
		end
	end
	if self.isServer and (self:getAIModeSelection() == AIModeSelection.MODE.STEERING_ASSIST and (v92_.steeringFieldCourse ~= nil and (v92_.steeringEnabled and g_time - v92_.steeringLastEnableTime > 2500))) then
		local v106_ = self:getLastSpeed()
		if v92_.steeringLockedMovingDirection == 0 then
			if v106_ > 2.5 then
				v92_.steeringLockedMovingDirection = self.movingDirection * self:getReverserDirection()
				return
			end
		elseif v106_ > 1 and self.movingDirection * self:getReverserDirection() ~= v92_.steeringLockedMovingDirection then
			self:setAIAutomaticSteeringEnabled(false)
		end
	end
end

-- Local values: spec
function AIAutomaticSteering:onStateChange(state, data)
	if state == VehicleStateChange.ATTACH and not data.loadFromSavegame or state == VehicleStateChange.DETACH then
		local v110_ = self.spec_aiAutomaticSteering
		v110_.forceFieldCourseUpdate = true
		v110_.lastActiveSteeringFieldCourse = nil
		if self.isServer and (self:getAIModeSelection() == AIModeSelection.MODE.STEERING_ASSIST and not self:getIsAutomaticSteeringAllowed()) then
			self:setAIModeSelection(AIModeSelection.MODE.WORKER)
		end
	end
end

function AIAutomaticSteering:onAIModeChanged(aiMode)
	if aiMode == AIModeSelection.MODE.STEERING_ASSIST then
		if self.isActiveForInputIgnoreSelectionIgnoreAI then
			self.spec_aiAutomaticSteering.forceFieldCourseUpdate = true
		end
	else
		self:setAIAutomaticSteeringCourse(nil, true)
	end
end

function AIAutomaticSteering:onAIModeSettingsChanged(aiMode)
	if self.isActiveForInputIgnoreSelectionIgnoreAI and aiMode == AIModeSelection.MODE.STEERING_ASSIST then
		self:setAIAutomaticSteeringCourse(nil)
		self.spec_aiAutomaticSteering.forceFieldCourseUpdate = true
	end
end

-- Local values: spec
function AIAutomaticSteering:onAIAutomaticSteeringLineEnd()
	local v116_ = self.spec_aiAutomaticSteering
	g_soundManager:playSample(v116_.samples.lineEnd)
end

-- Local values: spec
function AIAutomaticSteering:onActivate()
	if self:getAIModeSelection() == AIModeSelection.MODE.STEERING_ASSIST and self:getIsActiveForInput(true, true) then
		local v118_ = self.spec_aiAutomaticSteering
		if v118_.steeringFieldCourse ~= nil then
			g_fieldCourseManager:setActiveSteeringFieldCourse(v118_.steeringFieldCourse, self)
		end
	end
end

-- Local values: spec
function AIAutomaticSteering:onLeaveVehicle(wasEntered)
	if self.isServer and not (self.isDeleted or self.isDeleting) then
		if self.spec_aiAutomaticSteering.steeringFieldCourse ~= nil then
			g_fieldCourseManager:setActiveSteeringFieldCourse(nil, self)
		end
		self:setAIAutomaticSteeringEnabled(false)
	end
end

-- Local values: workingWidth, _, vehicle, _, _, _, _, aiMarkerWidth
function AIAutomaticSteering:getAttacherToolWorkingWidth()
	local v121_ = 0
	for _, v122_ in pairs(self.rootVehicle.childVehicles) do
		if v122_.getAIMarkers ~= nil then
			v122_:updateAIMarkerWidth()
			local _, _, _, _, v123_ = v122_:getAIMarkers()
			if v123_ ~= nil then
				v121_ = math.max(v121_, v123_)
			end
		end
		if v122_.getAIWorkAreaWidth ~= nil then
			v121_ = math.max(v121_, v122_:getAIWorkAreaWidth())
		end
	end
	return v121_
end

-- Local values: _, vehicle
function AIAutomaticSteering:getIsAutomaticSteeringAllowed()
	if self.rootVehicle.getImplementAllowAutomaticSteering ~= nil and self.rootVehicle:getImplementAllowAutomaticSteering() then
		return true
	end
	for _, v125_ in pairs(self.rootVehicle.childVehicles) do
		if v125_.getImplementAllowAutomaticSteering ~= nil and v125_:getImplementAllowAutomaticSteering() then
			return true
		end
	end
	return false
end

-- Local values: spec
function AIAutomaticSteering:setAIAutomaticSteeringEnabled(isEnabled, segmentIndex, segmentIsLeft, noEventSend)
	local v131_ = self.spec_aiAutomaticSteering
	if isEnabled == nil then
		isEnabled = not v131_.steeringEnabled
	end
	if isEnabled ~= v131_.steeringEnabled then
		v131_.steeringEnabled = isEnabled
		if isEnabled then
			v131_.steeringValue = self.rotatedTime
			v131_.steeringLastEnableTime = g_time
			v131_.steeringLockedMovingDirection = 0
			v131_.lastDistanceToEnd = 0
			if self.isServer then
				v131_.lastActiveSteeringFieldCourse = v131_.steeringFieldCourse
			end
		end
		if self.isClient then
			if isEnabled then
				g_soundManager:playSample(v131_.samples.engage)
			else
				g_soundManager:playSample(v131_.samples.disengage)
			end
			AIAutomaticSteering.updateActionEvents(self)
			if self.updateDashboardValueType ~= nil then
				self:updateDashboardValueType("ai.automaticSteering.steeringEngaged")
				self:updateDashboardValueType("ai.automaticSteering.steeringState")
			end
		end
	end
	if v131_.steeringFieldCourse ~= nil then
		if self.isServer then
			segmentIndex = v131_.steeringFieldCourse.currentSegmentIndex
			segmentIsLeft = v131_.steeringFieldCourse.currentSegmentIsLeft
		elseif segmentIndex ~= nil then
			v131_.steeringFieldCourse:setCurrentSegmentIndex(segmentIndex, segmentIsLeft)
		end
	end
	AIAutomaticSteeringStateEvent.sendEvent(self, isEnabled, segmentIndex, segmentIsLeft, noEventSend)
	return segmentIndex, segmentIsLeft
end

-- Local values: spec
function AIAutomaticSteering:setAIAutomaticSteeringCourse(steeringFieldCourse, noEventSend)
	local v135_ = self.spec_aiAutomaticSteering
	v135_.steeringFieldCourse = steeringFieldCourse
	if steeringFieldCourse == nil and v135_.steeringEnabled then
		self:setAIAutomaticSteeringEnabled(false, nil, nil, true)
	end
	if self.isActiveForInputIgnoreSelectionIgnoreAI then
		g_fieldCourseManager:setActiveSteeringFieldCourse(steeringFieldCourse, self)
	end
	if self.isClient then
		AIAutomaticSteering.updateActionEvents(self)
		if self.updateDashboardValueType ~= nil then
			self:updateDashboardValueType("ai.automaticSteering.steeringState")
		end
	end
	if noEventSend ~= true then
		if g_server ~= nil then
			g_server:broadcastEvent(AIAutomaticSteeringCourseEvent.new(self, steeringFieldCourse), nil, nil, self)
			return
		end
		g_client:getServerConnection():sendEvent(AIAutomaticSteeringCourseEvent.new(self, steeringFieldCourse))
	end
end

-- Local values: spec
function AIAutomaticSteering:generateSteeringFieldCourse(x, z, fieldCourseSettings)
	local v_u_140_ = self.spec_aiAutomaticSteering
	if v_u_140_.lastActiveSteeringFieldCourse == nil or not (v_u_140_.lastActiveSteeringFieldCourse:getIsPointInsideBoundary(x, z) and fieldCourseSettings:isIdentical(v_u_140_.lastActiveSteeringFieldCourse.fieldCourseSettings)) then
		if v_u_140_.fieldCourseDetectionInProgress then
			v_u_140_.fieldCourseDetectionPendingData = {
				["x"] = x,
				["z"] = z,
				["fieldCourseSettings"] = fieldCourseSettings
			}
		else
			v_u_140_.fieldCourseDetectionInProgress = true
			g_fieldCourseManager:generateFieldCourseAtWorldPos(x, z, fieldCourseSettings, function(_, p141_)
				-- upvalues: (copy) v_u_140_, (copy) self
				v_u_140_.fieldCourseDetectionInProgress = false
				if p141_ == nil then
					Logging.devInfo("Failed to generate field course for AISteering")
					self:setAIAutomaticSteeringCourse(nil)
				else
					self:setAIAutomaticSteeringCourse((SteeringFieldCourse.new(p141_)))
				end
				if v_u_140_.fieldCourseDetectionPendingData ~= nil then
					local v142_ = v_u_140_.fieldCourseDetectionPendingData
					v_u_140_.fieldCourseDetectionPendingData = nil
					self:generateSteeringFieldCourse(v142_.x, v142_.z, v142_.fieldCourseSettings)
				end
			end)
		end
	else
		self:setAIAutomaticSteeringCourse(v_u_140_.lastActiveSteeringFieldCourse)
		return
	end
end

-- Local values: spec
function AIAutomaticSteering:getIsAIAutomaticSteeringAllowed()
	local v144_ = self.spec_aiAutomaticSteering
	if v144_.steeringFieldCourse == nil then
		return false, g_i18n:getText("ai_automaticSteeringWarningNoCourse")
	elseif v144_.steeringFieldCourse.currentSegment == nil then
		return false, g_i18n:getText("ai_automaticSteeringWarningNoSegment")
	else
		return true
	end
end

-- Local values: spec
function AIAutomaticSteering:getAIAutomaticSteeringState()
	local v146_ = self.spec_aiAutomaticSteering
	if v146_.steeringFieldCourse == nil then
		return AIAutomaticSteering.STATE.DISABLED
	elseif v146_.steeringEnabled then
		return AIAutomaticSteering.STATE.ACTIVE
	else
		return AIAutomaticSteering.STATE.AVAILABLE
	end
end

-- Local values: spec
function AIAutomaticSteering:getAIAutomaticSteeringLookAheadDistance()
	local v148_ = self.spec_aiAutomaticSteering
	if v148_.lookAheadDistance == nil then
		return self.movingDirection >= 0 and self:getAIRootNodeMaxZOffset() or self:getAIRootNodeMinZOffset()
	else
		return v148_.lookAheadDistance
	end
end

-- Local values: _, vehicle
function AIAutomaticSteering:getIsSideOffsetReversed()
	for _, v150_ in pairs(self.rootVehicle.childVehicles) do
		if v150_.spec_plow ~= nil then
			return v150_.spec_plow.rotationMax
		end
	end
	return false
end

-- Local values: spec, diff
function AIAutomaticSteering:setSteeringInput(superFunc, inputValue, isAnalog, deviceCategory)
	local v156_ = self.spec_aiAutomaticSteering
	if v156_.steeringEnabled then
		if deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE then
			self:setAIAutomaticSteeringEnabled(false)
		elseif g_time - v156_.steeringLastEnableTime > 2500 then
			local v157_ = inputValue - v156_.lastSteeringInputValue
			if math.abs(v157_) > 0.1 then
				self:setAIAutomaticSteeringEnabled(false)
			end
		else
			v156_.lastSteeringInputValue = inputValue
		end
	else
		v156_.lastSteeringInputValue = inputValue
	end
	return superFunc(self, inputValue, isAnalog, deviceCategory)
end

-- Local values: spec, acceleration
function AIAutomaticSteering:updateVehiclePhysics(superFunc, axisForward, axisSide, doHandbrake, dt)
	local v164_ = self.spec_aiAutomaticSteering
	if not v164_.steeringEnabled then
		return superFunc(self, axisForward, axisSide, doHandbrake, dt)
	end
	local v165_
	if v164_.steeringValue < 0 then
		v165_ = -v164_.steeringValue / self.maxRotTime
	else
		v165_ = v164_.steeringValue / self.minRotTime
	end
	local v166_ = superFunc(self, axisForward, v165_, doHandbrake, dt)
	self.rotatedTime = v164_.steeringValue
	self.spec_drivable.axisSide = v165_
	return v166_
end

-- Local values: spec, _, actionEventId, _, actionEventId
function AIAutomaticSteering:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local v169_ = self.spec_aiAutomaticSteering
		self:clearActionEventsTable(v169_.actionEvents)
		if isActiveForInputIgnoreSelection then
			local _, v170_ = self:addActionEvent(v169_.actionEvents, InputAction.TOGGLE_AI_STEERING, self, AIAutomaticSteering.actionEventSteering, false, true, false, true, nil)
			if v170_ ~= nil then
				g_inputBinding:setActionEventTextPriority(v170_, GS_PRIO_HIGH)
				g_inputBinding:setActionEventText(v170_, string.format(g_i18n:getText("ai_modeSelect"), g_i18n:getText("ai_modeSteeringAssist")))
				AIAutomaticSteering.updateActionEvents(self)
			end
			local _, v171_ = self:addActionEvent(v169_.actionEvents, InputAction.TOGGLE_AI_STEERING_LINES, self, AIAutomaticSteering.actionEventSteeringLines, false, true, false, true, nil)
			if v171_ ~= nil then
				g_inputBinding:setActionEventTextVisibility(v171_, false)
			end
		end
	end
end

function AIAutomaticSteering:actionEventSteering(actionName, inputValue, callbackState, isAnalog)
	self:setAIAutomaticSteeringEnabled()
end

-- Local values: spec, actionEvent, isActive
function AIAutomaticSteering:updateActionEvents()
	local v174_ = self.spec_aiAutomaticSteering
	local v175_ = v174_.actionEvents[InputAction.TOGGLE_AI_STEERING]
	if v175_ ~= nil then
		local v176_
		if v174_.steeringFieldCourse == nil then
			v176_ = false
		else
			v176_ = v174_.steeringFieldCourse.currentSegment ~= nil
		end
		g_inputBinding:setActionEventActive(v175_.actionEventId, v176_)
	end
end

-- Local values: value
function AIAutomaticSteering:actionEventSteeringLines()
	local v177_ = g_gameSettings:getValue(GameSettings.SETTING.STEERING_ASSIST_LINES)
	g_gameSettings:setValue(GameSettings.SETTING.STEERING_ASSIST_LINES, not v177_, true)
end
