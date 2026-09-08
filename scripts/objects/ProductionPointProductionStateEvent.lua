-- Local values: ProductionPointProductionStateEvent_mt
ProductionPointProductionStateEvent = {}
local ProductionPointProductionStateEvent_mt = Class(ProductionPointProductionStateEvent, Event)
InitStaticEventClass(ProductionPointProductionStateEvent, "ProductionPointProductionStateEvent")
function ProductionPointProductionStateEvent.emptyNew()
	-- upvalues: (copy) ProductionPointProductionStateEvent_mt
	return Event.new(ProductionPointProductionStateEvent_mt)
end

-- Local values: self
function ProductionPointProductionStateEvent.new(productionPoint, productionId, isEnabled)
	local v5_ = ProductionPointProductionStateEvent.emptyNew()
	v5_.productionPoint = productionPoint
	v5_.productionId = productionId
	v5_.isEnabled = isEnabled
	return v5_
end

function ProductionPointProductionStateEvent:readStream(streamId, connection)
	self.productionPoint = NetworkUtil.readNodeObject(streamId)
	self.productionId = streamReadString(streamId)
	self.isEnabled = streamReadBool(streamId)
	self:run(connection)
end

function ProductionPointProductionStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.productionPoint)
	streamWriteString(streamId, self.productionId)
	streamWriteBool(streamId, self.isEnabled)
end

function ProductionPointProductionStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection)
	end
	if self.productionPoint ~= nil then
		self.productionPoint:setProductionState(self.productionId, self.isEnabled, true)
	end
end

function ProductionPointProductionStateEvent.sendEvent(productionPoint, productionId, isEnabled, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(ProductionPointProductionStateEvent.new(productionPoint, productionId, isEnabled))
			return
		end
		g_client:getServerConnection():sendEvent(ProductionPointProductionStateEvent.new(productionPoint, productionId, isEnabled))
	end
end
