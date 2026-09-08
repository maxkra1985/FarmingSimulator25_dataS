-- Local values: AIDebugDump_mt
AIDebugDump = {}
local AIDebugDump_mt = Class(AIDebugDump)
AIDebugDump.SAVE_DIRECTORY = getUserProfileAppPath() .. "aiSystem/"

-- Upvalues: AIDebugDump_mt
-- Local values: self
function AIDebugDump.new(vehicle, agentId, customMt)
	-- upvalues: (copy) AIDebugDump_mt
	local v5_ = customMt or AIDebugDump_mt
	local v6_ = setmetatable({}, v5_)
	v6_.vehicle = vehicle
	v6_.agentId = agentId
	v6_.dumpedAgent = false
	v6_.plannedTargetIndex = nil
	return v6_
end

function AIDebugDump:delete()
	self:stopRecording()
end

-- Local values: currentTarget
function AIDebugDump:setTarget(x, y, z, dirX, dirY, dirZ, cx, cy, cz, cDirX, cDirY, cDirZ)
	if self.dump ~= nil then
		local v21_ = self.dump.targets
		table.insert(v21_, {
			["frames"] = {},
			["target"] = {
				x,
				y,
				z,
				dirX,
				dirY,
				dirZ
			},
			["start"] = {
				cx,
				cy,
				cz,
				cDirX,
				cDirY,
				cDirZ
			}
		})
	end
end

-- Local values: debugData
function AIDebugDump:addData(dt, x, y, z, dirX, dirY, dirZ, lastSpeed, curvature, maxSpeed, status)
	if self.dump ~= nil then
		local v34_ = self.dump.targets[#self.dump.targets].frames
		table.insert(v34_, {
			["dt"] = dt,
			["pos"] = { x, y, z },
			["dir"] = { dirX, dirY, dirZ },
			["lastSpeed"] = lastSpeed,
			["curvature"] = curvature,
			["speed"] = maxSpeed,
			["status"] = status
		})
		if not self.dumpedAgent then
			self.dumpedAgent = true
			local v35_ = dumpVehicleNavigationAgent
			local v36_ = self.agentId
			local v37_ = AIDebugDump.SAVE_DIRECTORY
			local v38_ = self.filename
			local v39_ = self.plannedTargetIndex or -1
			v35_(v36_, v37_ .. v38_ .. "_target" .. tostring(v39_) .. ".dat")
		end
	end
end

function AIDebugDump:startRecording(minTurningRadius, allowBackwards, width, length, lengthOffset, frontOffset, maxBrakeAcceleration, maxCentripetalAcceleration)
	if self.dump == nil then
		self.dumpedAgent = false
		createFolder(AIDebugDump.SAVE_DIRECTORY)
		self.filename = getDate("%Y_%m_%d_%H_%M_%S") .. "_dump"
		self.dump = {
			["minTurningRadius"] = minTurningRadius,
			["allowBackwards"] = allowBackwards,
			["width"] = width,
			["length"] = length,
			["lengthOffset"] = lengthOffset,
			["frontOffset"] = frontOffset,
			["maxBrakeAcceleration"] = maxBrakeAcceleration,
			["maxCentripetalAcceleration"] = maxCentripetalAcceleration,
			["targets"] = {}
		}
	end
end

-- Local values: folder, filename, dumpXMLFilename, xmlFile, stateCache, k, target, key, j, frameData, frameKey, stateName
function AIDebugDump:stopRecording()
	if self.dump ~= nil then
		Logging.info("Writing debug dump...")
		self:stopPlanningRecording()
		local v50_ = AIDebugDump.SAVE_DIRECTORY .. self.filename .. ".xml"
		local v51_ = createXMLFile("dumpData", v50_, "dumpData")
		if v51_ == 0 then
			Logging.error("Failed to create ai dumpdata xml file")
			return
		end
		setXMLString(v51_, "dumpData.vehicle", self.vehicle.configFileName)
		setXMLFloat(v51_, "dumpData.settings#minTurningRadius", self.dump.minTurningRadius)
		setXMLBool(v51_, "dumpData.settings#allowBackwards", self.dump.allowBackwards)
		setXMLFloat(v51_, "dumpData.settings#width", self.dump.width)
		setXMLFloat(v51_, "dumpData.settings#length", self.dump.length)
		setXMLFloat(v51_, "dumpData.settings#lengthOffset", self.dump.lengthOffset)
		setXMLFloat(v51_, "dumpData.settings#frontOffset", self.dump.frontOffset)
		setXMLFloat(v51_, "dumpData.settings#maxBrakeAcceleration", self.dump.maxBrakeAcceleration)
		setXMLFloat(v51_, "dumpData.settings#maxCentripetalAcceleration", self.dump.maxCentripetalAcceleration)
		local v52_ = {}
		for v53_, v54_ in ipairs(self.dump.targets) do
			local v55_ = string.format("dumpData.targets.target(%d)", v53_ - 1)
			setXMLFloat(v51_, v55_ .. ".start#x", v54_.start[1])
			setXMLFloat(v51_, v55_ .. ".start#y", v54_.start[2])
			setXMLFloat(v51_, v55_ .. ".start#z", v54_.start[3])
			setXMLFloat(v51_, v55_ .. ".start#xDir", v54_.start[4])
			setXMLFloat(v51_, v55_ .. ".start#yDir", v54_.start[5])
			setXMLFloat(v51_, v55_ .. ".start#zDir", v54_.start[6])
			setXMLFloat(v51_, v55_ .. ".target#x", v54_.target[1])
			setXMLFloat(v51_, v55_ .. ".target#y", v54_.target[2])
			setXMLFloat(v51_, v55_ .. ".target#z", v54_.target[3])
			setXMLFloat(v51_, v55_ .. ".target#xDir", v54_.target[4])
			setXMLFloat(v51_, v55_ .. ".target#yDir", v54_.target[5])
			setXMLFloat(v51_, v55_ .. ".target#zDir", v54_.target[6])
			for v56_, v57_ in ipairs(v54_.frames) do
				local v58_ = string.format("%s.frames.frame(%d)", v55_, v56_ - 1)
				local v59_ = v52_[v57_.status]
				if v59_ == nil then
					v59_ = AISystem.getAgentStateName(v57_.status)
					v52_[v57_.status] = v59_
				end
				setXMLString(v51_, v58_ .. "#status", v59_)
				setXMLFloat(v51_, v58_ .. "#speed", v57_.speed)
				setXMLFloat(v51_, v58_ .. "#curvature", v57_.curvature)
				setXMLFloat(v51_, v58_ .. "#dt", v57_.dt)
				setXMLFloat(v51_, v58_ .. "#x", v57_.pos[1])
				setXMLFloat(v51_, v58_ .. "#y", v57_.pos[2])
				setXMLFloat(v51_, v58_ .. "#z", v57_.pos[3])
				setXMLFloat(v51_, v58_ .. "#dirX", v57_.dir[1])
				setXMLFloat(v51_, v58_ .. "#dirY", v57_.dir[2])
				setXMLFloat(v51_, v58_ .. "#dirZ", v57_.dir[3])
				setXMLFloat(v51_, v58_ .. "#lastSpeed", v57_.lastSpeed)
			end
		end
		saveXMLFile(v51_)
		delete(v51_)
	end
end

function AIDebugDump:startPlanningRecording()
	beginVehicleNavigationDebugLogging(self.agentId)
	beginVehicleNavigationPlannerRecording(self.agentId)
	self.plannedTargetIndex = #self.dump.targets + 1
	self.dumpedAgent = false
end

-- Local values: folder, filename, logFilename, bitmapFilename, entityId
function AIDebugDump:stopPlanningRecording()
	if self.plannedTargetIndex ~= nil then
		Logging.info("Writing Planning Data...")
		local v62_ = AIDebugDump.SAVE_DIRECTORY
		local v63_ = self.filename
		local v64_ = self.plannedTargetIndex
		local v65_ = v62_ .. v63_ .. "_target" .. tostring(v64_) .. ".log"
		endVehicleNavigationDebugLogging(self.agentId, v65_)
		local v66_ = self.plannedTargetIndex
		local v67_ = v63_ .. "_target" .. tostring(v66_) .. "_bitmap"
		local v68_ = endVehicleNavigationPlannerRecording(self.agentId, v67_)
		local v69_ = saveBitVectorMapToFile
		local v70_ = self.plannedTargetIndex
		v69_(v68_, v62_ .. v63_ .. "_target" .. tostring(v70_) .. ".grle")
		g_currentMission.aiSystem:setPlanningBitVectorMap(v68_)
		self.plannedTargetIndex = nil
	end
end
