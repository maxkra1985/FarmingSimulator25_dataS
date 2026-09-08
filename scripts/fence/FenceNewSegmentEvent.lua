-- Local values: FenceNewSegmentEvent_mt
FenceNewSegmentEvent = {}
FenceNewSegmentEvent.STATUS_CODE = {
	["SUCCESS"] = 0,
	["ERROR"] = 1
}
local FenceNewSegmentEvent_mt = Class(FenceNewSegmentEvent, Event)
InitStaticEventClass(FenceNewSegmentEvent, "FenceNewSegmentEvent")
function FenceNewSegmentEvent.emptyNew()
	-- upvalues: (copy) FenceNewSegmentEvent_mt
	return Event.new(FenceNewSegmentEvent_mt, NetworkNode.CHANNEL_MAIN)
end

-- Local values: self
function FenceNewSegmentEvent.newClientToServer(fencePlaceable, segment)
	local v4_ = FenceNewSegmentEvent.emptyNew()
	v4_.fencePlaceable = fencePlaceable
	v4_.segment = segment
	return v4_
end

-- Local values: self
function FenceNewSegmentEvent.newServerToClient(statusCode, segmentId, ex, ey, ez)
	local v10_ = FenceNewSegmentEvent.emptyNew()
	v10_.statusCode = statusCode
	v10_.segmentId = segmentId
	v10_.ex = ex
	v10_.ey = ey
	v10_.ez = ez
	return v10_
end

-- Local values: fence, templateIndex, templateId, statusCode, segmentId, ex, ey, ez
function FenceNewSegmentEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		local v14_ = streamReadUInt8(streamId)
		local v15_ = streamReadUInt16(streamId)
		local v16_ = streamReadFloat32(streamId)
		local v17_ = streamReadFloat32(streamId)
		local v18_ = streamReadFloat32(streamId)
		g_messageCenter:publish(FenceNewSegmentEvent, v14_, v15_, v16_, v17_, v18_)
	else
		self.fencePlaceable = NetworkUtil.readNodeObject(streamId)
		local v19_ = self.fencePlaceable:getFence()
		self.segment = v19_:createNewSegment((v19_:getSegmentTemplateIdByIndex((streamReadUInt8(streamId)))))
		self.segment:readStream(streamId, connection)
		self:run(connection)
	end
end

-- Local values: segmentId, fence, fenceTemplateIndex
function FenceNewSegmentEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)
		local v23_ = self.segment:getId()
		local v24_ = self.fencePlaceable:getFence():getSegmentTemplateIndexById(v23_)
		streamWriteUInt8(streamId, v24_)
		self.segment:writeStream(streamId, connection)
	else
		streamWriteUInt8(streamId, self.statusCode)
		streamWriteUInt16(streamId, self.segmentId)
		streamWriteFloat32(streamId, self.ex)
		streamWriteFloat32(streamId, self.ey)
		streamWriteFloat32(streamId, self.ez)
	end
end

-- Local values: statusCode, player, farmId, price, ex, ey, ez
function FenceNewSegmentEvent:run(connection)
	if self.fencePlaceable ~= nil and self.fencePlaceable:getIsSynchronized() then
		local v27_ = FenceNewSegmentEvent.STATUS_CODE.SUCCESS
		if self.segment:updateMeshes(true) then
			local v28_ = g_currentMission:getPlayerByConnection(connection)
			if v28_ ~= nil then
				local v29_ = v28_.farmId
				if v29_ ~= nil then
					local v30_ = self.segment:getPrice()
					g_currentMission:addMoney(-v30_, v29_, MoneyType.SHOP_PROPERTY_BUY, true)
				end
			end
			self.segment:finalize()
		else
			v27_ = FenceNewSegmentEvent.STATUS_CODE.ERROR
		end
		if v27_ == FenceNewSegmentEvent.STATUS_CODE.SUCCESS then
			g_server:broadcastEvent(FenceSegmentEvent.new(self.fencePlaceable, self.segment), false, nil, self.fencePlaceable)
		end
		local v31_, v32_, v33_ = self.segment:getEndPos()
		if not connection:getIsLocal() then
			connection:sendEvent(FenceNewSegmentEvent.newServerToClient(v27_, self.segment.id, v31_, v32_, v33_))
			return
		end
		g_messageCenter:publish(FenceNewSegmentEvent, v27_, self.segment.id, v31_, v32_, v33_)
	end
end
