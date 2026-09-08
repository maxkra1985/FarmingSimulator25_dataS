-- Local values: ElkTrigger_mt
ElkTrigger = {}
local ElkTrigger_mt = Class(ElkTrigger)

function ElkTrigger:onCreate(id)
	g_currentMission:addUpdateable(ElkTrigger.new(id))
end

-- Upvalues: ElkTrigger_mt
-- Local values: self, i, splineId, elkId1, elkId2, elk
function ElkTrigger.new(nodeId)
	-- upvalues: (copy) ElkTrigger_mt
	local v4_ = ElkTrigger_mt
	local v5_ = setmetatable({}, v4_)
	v5_.nodeId = nodeId
	v5_.triggerId = getChildAt(nodeId, 0)
	addTrigger(v5_.triggerId, "triggerCallback", v5_)
	v5_.motherElkId = getChildAt(nodeId, 1)
	v5_.splinesNode = getChildAt(nodeId, 2)
	v5_.inProgress = false
	v5_.time = 0
	v5_.duration1 = 10000
	v5_.duration2 = 14000
	v5_.nextTriggerTime = 0
	v5_.elkSound = createSample("elkSound")
	loadSample(v5_.elkSound, "data/maps/sounds/elk.wav", false)
	v5_.playerInRange = false
	v5_.elks = {}
	for v6_ = 1, getNumOfChildren(v5_.splinesNode) do
		local v7_ = getChildAt(v5_.splinesNode, v6_ - 1)
		local v8_ = {
			["elkId1"] = clone(v5_.motherElkId, true),
			["elkId2"] = clone(v5_.motherElkId, true),
			["splineId"] = v7_
		}
		local v9_ = v5_.elks
		table.insert(v9_, v8_)
	end
	return v5_
end

function ElkTrigger:delete()
	removeTrigger(self.triggerId)
	delete(self.elkSound)
end

-- Local values: _, elk, _, elk, splinePos, x, y, z, rx, ry, rz, _, elk
function ElkTrigger:update(dt)
	if self.inProgress then
		self.time = self.time + dt
		for _, v13_ in pairs(self.elks) do
			local v14_ = self.time / self.duration1
			local v15_ = math.min(v14_, 1)
			local v16_, v17_, v18_ = getSplinePosition(v13_.splineId, v15_)
			local v19_, v20_, v21_ = getSplineOrientation(v13_.splineId, v15_, 0, -1, 0)
			setTranslation(v13_.elkId1, v16_, v17_, v18_)
			setRotation(v13_.elkId1, v19_, v20_, v21_)
			local v22_ = self.time / self.duration2
			local v23_ = math.min(v22_, 1)
			local v24_, v25_, v26_ = getSplinePosition(v13_.splineId, v23_)
			local v27_, v28_, v29_ = getSplineOrientation(v13_.splineId, v23_, 0, -1, 0)
			setTranslation(v13_.elkId2, v24_, v25_, v26_)
			setRotation(v13_.elkId2, v27_, v28_, v29_)
		end
		if self.time > self.duration2 then
			self.inProgress = false
			for _, v30_ in pairs(self.elks) do
				setTranslation(v30_.elkId1, 0, 0, 0)
				setTranslation(v30_.elkId2, 0, 0, 0)
				setVisibility(v30_.elkId1, false)
				setVisibility(v30_.elkId2, false)
				self.nextTriggerTime = g_currentMission.time + 10000
			end
		end
	elseif self.playerInRange and (g_currentMission.environment.dayTime > 43200000 and (g_currentMission.environment.dayTime < 43260000 and g_currentMission.time > self.nextTriggerTime)) then
		self.inProgress = true
		self.splinePos = 0
		self.time = 0
		for _, v31_ in pairs(self.elks) do
			setTranslation(v31_.elkId1, 0, 0, 0)
			setTranslation(v31_.elkId2, 0, 0, 0)
			setVisibility(v31_.elkId1, true)
			setVisibility(v31_.elkId2, true)
		end
		playSample(self.elkSound, 1, 1, 0, 0, 0)
		return
	end
end

-- Local values: localPlayer
function ElkTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local v36_ = g_localPlayer
	if v36_ == nil or (v36_:getIsInVehicle() or otherId ~= v36_.rootNode) then
		return
	elseif onEnter then
		self.playerInRange = true
	elseif onLeave then
		self.playerInRange = false
	end
end
