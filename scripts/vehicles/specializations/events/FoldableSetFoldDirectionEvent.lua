-- Local values: FoldableSetFoldDirectionEvent_mt
FoldableSetFoldDirectionEvent = {}
local FoldableSetFoldDirectionEvent_mt = Class(FoldableSetFoldDirectionEvent, Event)
InitStaticEventClass(FoldableSetFoldDirectionEvent, "FoldableSetFoldDirectionEvent")
function FoldableSetFoldDirectionEvent.emptyNew()
	-- upvalues: (copy) FoldableSetFoldDirectionEvent_mt
	return Event.new(FoldableSetFoldDirectionEvent_mt)
end

-- Local values: self
function FoldableSetFoldDirectionEvent.new(object, direction, moveToMiddle)
	local v5_ = FoldableSetFoldDirectionEvent.emptyNew()
	v5_.object = object
	v5_.direction = math.sign(direction)
	v5_.moveToMiddle = moveToMiddle
	return v5_
end

function FoldableSetFoldDirectionEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.direction = streamReadUIntN(streamId, 2) - 1
	self.moveToMiddle = streamReadBool(streamId)
	self:run(connection)
end

function FoldableSetFoldDirectionEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.direction + 1, 2)
	streamWriteBool(streamId, self.moveToMiddle)
end

function FoldableSetFoldDirectionEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setFoldState(self.direction, self.moveToMiddle, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(FoldableSetFoldDirectionEvent.new(self.object, self.direction, self.moveToMiddle), nil, connection, self.object)
	end
end
