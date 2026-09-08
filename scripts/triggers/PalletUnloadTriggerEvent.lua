-- Local values: PalletUnloadTriggerEvent_mt
PalletUnloadTriggerEvent = {}
local PalletUnloadTriggerEvent_mt = Class(PalletUnloadTriggerEvent, Event)
InitStaticEventClass(PalletUnloadTriggerEvent, "PalletUnloadTriggerEvent")
function PalletUnloadTriggerEvent.emptyNew()
	-- upvalues: (copy) PalletUnloadTriggerEvent_mt
	return Event.new(PalletUnloadTriggerEvent_mt)
end

-- Local values: self
function PalletUnloadTriggerEvent.new(object)
	local v3_ = PalletUnloadTriggerEvent.emptyNew()
	v3_.object = object
	return v3_
end

function PalletUnloadTriggerEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function PalletUnloadTriggerEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end

-- Local values: mission, userId, farm
function PalletUnloadTriggerEvent:run(connection)
	if self.object ~= nil then
		local v11_ = g_currentMission.userManager:getUserIdByConnection(connection)
		if v11_ ~= nil then
			local v12_ = g_farmManager:getFarmByUserId(v11_)
			if v12_ ~= nil then
				self.object:unloadPallets(v12_.farmId)
			end
		end
	end
end
