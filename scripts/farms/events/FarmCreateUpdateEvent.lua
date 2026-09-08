-- Local values: FarmCreateUpdateEvent_mt
FarmCreateUpdateEvent = {}
local FarmCreateUpdateEvent_mt = Class(FarmCreateUpdateEvent, Event)
InitStaticEventClass(FarmCreateUpdateEvent, "FarmCreateUpdateEvent")
function FarmCreateUpdateEvent.emptyNew()
	-- upvalues: (copy) FarmCreateUpdateEvent_mt
	return Event.new(FarmCreateUpdateEvent_mt)
end

-- Local values: self
function FarmCreateUpdateEvent.new(name, color, password, isUpdate, farmId)
	local v7_ = FarmCreateUpdateEvent.emptyNew()
	v7_.name = name
	v7_.color = color
	v7_.password = password
	v7_.isUpdate = isUpdate
	v7_.farmId = farmId
	return v7_
end

-- Local values: filteredName
function FarmCreateUpdateEvent:writeStream(streamId, connection)
	local v10_ = filterText(self.name, false, false)
	streamWriteString(streamId, v10_)
	streamWriteUIntN(streamId, self.color, Farm.COLOR_SEND_NUM_BITS)
	streamWriteBool(streamId, self.isUpdate)
	if streamWriteBool(streamId, self.password ~= nil) then
		streamWriteString(streamId, self.password)
	end
	if streamWriteBool(streamId, self.isUpdate or self.farmId ~= nil) then
		streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	end
end

function FarmCreateUpdateEvent:readStream(streamId, connection)
	self.name = streamReadString(streamId)
	self.color = streamReadUIntN(streamId, Farm.COLOR_SEND_NUM_BITS)
	self.isUpdate = streamReadBool(streamId)
	if streamReadBool(streamId) then
		self.password = streamReadString(streamId)
	else
		self.password = nil
	end
	if streamReadBool(streamId) then
		self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	end
	self:run(connection)
end

-- Local values: farm, farm
function FarmCreateUpdateEvent:run(connection)
	if connection:getIsServer() then
		if self.isUpdate then
			local v16_ = g_farmManager:getFarmById(self.farmId)
			v16_.name = self.name
			v16_.color = self.color
			g_messageCenter:publish(MessageType.FARM_SETTINGS_CHANGED, v16_.farmId)
		end
	elseif self.isUpdate then
		if g_currentMission:getHasPlayerPermission("updateFarm", connection, self.farmId) then
			local v17_ = g_farmManager:getFarmById(self.farmId)
			v17_.name = self.name
			v17_.color = self.color
			v17_.password = self.password
			g_server:broadcastEvent(FarmCreateUpdateEvent.new(self.name, self.color, nil, true, self.farmId))
			g_messageCenter:publish(MessageType.FARM_SETTINGS_CHANGED, self.farmId)
			return
		end
	elseif connection:getIsLocal() or g_currentMission.userManager:getIsConnectionMasterUser(connection) then
		g_farmManager:createFarm(self.name, self.color, self.password)
		return
	end
end
