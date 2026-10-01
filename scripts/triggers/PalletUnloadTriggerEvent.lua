PalletUnloadTriggerEvent = {}
local PalletUnloadTriggerEvent_mt = Class(PalletUnloadTriggerEvent, Event)
InitStaticEventClass(PalletUnloadTriggerEvent, "PalletUnloadTriggerEvent")
function PalletUnloadTriggerEvent.emptyNew()
	local self = Event.new(PalletUnloadTriggerEvent_mt)
	return self
end
function PalletUnloadTriggerEvent.new(object)
	local self = PalletUnloadTriggerEvent.emptyNew()
	self.object = object
	return self
end
function PalletUnloadTriggerEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end
function PalletUnloadTriggerEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end
function PalletUnloadTriggerEvent:run(connection)
	if self.object ~= nil then
		local mission = g_currentMission
		local userId = mission.userManager:getUserIdByConnection(connection)
		if userId ~= nil then
			local farm = g_farmManager:getFarmByUserId(userId)
			if farm ~= nil then
				self.object:unloadPallets(farm.farmId)
			end
		end
	end
end
