-- Local values: TransportMissionTrigger_mt
TransportMissionTrigger = {}
local TransportMissionTrigger_mt = Class(TransportMissionTrigger)

function TransportMissionTrigger:onCreate(id)
	g_currentMission:addNonUpdateable(TransportMissionTrigger.new(id))
end

-- Upvalues: TransportMissionTrigger_mt
-- Local values: self
function TransportMissionTrigger.new(id)
	-- upvalues: (copy) TransportMissionTrigger_mt
	local v4_ = TransportMissionTrigger_mt
	local v5_ = setmetatable({}, v4_)
	v5_.triggerId = id
	v5_.index = getUserAttribute(v5_.triggerId, "index")
	addTrigger(id, "triggerCallback", v5_)
	v5_.isEnabled = true
	g_missionManager:addTransportMissionTrigger(v5_)
	v5_:setMission(nil)
	return v5_
end

function TransportMissionTrigger:delete()
	removeTrigger(self.triggerId)
	g_missionManager:removeTransportMissionTrigger(self)
end

function TransportMissionTrigger:setMission(mission)
	self.mission = mission
	self:onMissionUpdated()
end

function TransportMissionTrigger:onMissionUpdated()
	local v10_ = setVisibility
	local v11_ = self.triggerId
	local v12_
	if self.mission == nil then
		v12_ = false
	else
		v12_ = self.mission.status == MissionStatus.RUNNING
	end
	v10_(v11_, v12_)
end

function TransportMissionTrigger:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if self.isEnabled and self.mission ~= nil then
		if onEnter then
			self.mission:objectEnteredTrigger(self, otherId)
			return
		end
		if onLeave then
			self.mission:objectLeftTrigger(self, otherId)
		end
	end
end
