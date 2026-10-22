OrchardBuildRequestEvent = {}
local OrchardBuildRequestEvent_mt = Class(OrchardBuildRequestEvent, Event)
InitStaticEventClass(OrchardBuildRequestEvent, "OrchardBuildRequestEvent")
OrchardBuildRequestEvent.MAX_ROWS = 4096
OrchardBuildRequestEvent.MAX_BOUNDARY_POINTS = 2048
OrchardBuildRequestEvent.MIN_BOUNDARY_POINTS = 3
OrchardBuildRequestEvent.OFFSET_LINE_INDEX_NUM_BITS = 16
function OrchardBuildRequestEvent.emptyNew()
	local self = Event.new(OrchardBuildRequestEvent_mt, NetworkNode.CHANNEL_MAIN)
	return self
end
function OrchardBuildRequestEvent.new(requestId, fencePlaceable, templateId, courseSegments, boundaryLine, optionStates)
	local self = OrchardBuildRequestEvent.emptyNew()
	self.requestId = requestId
	self.fencePlaceable = fencePlaceable
	self.templateId = templateId
	self.courseSegments = courseSegments
	self.boundaryLine = boundaryLine or {}
	self.optionStates = optionStates or {}
	return self
end
function OrchardBuildRequestEvent:readStream(streamId, connection)
	local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
	self.requestId = streamReadUInt8(streamId)
	local fencePlaceable = NetworkUtil.readNodeObject(streamId)
	self.fencePlaceable = fencePlaceable
	if streamReadBool(streamId) then
		local templateIndex = streamReadUInt8(streamId)
		if fencePlaceable ~= nil and fencePlaceable.getFence ~= nil then
			local fence = fencePlaceable:getFence()
			if fence ~= nil then
				self.templateId = fence:getSegmentTemplateIdByIndex(templateIndex)
			end
		end
	end
	local numRows = streamReadUInt16(streamId)
	self.isTooLarge = OrchardBuildRequestEvent.MAX_ROWS < numRows
	self.courseSegments = {}
	for i = 1, numRows do
		local startX = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local startZ = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local endX = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local endZ = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local offsetLineIndex = streamReadIntN(streamId, OrchardBuildRequestEvent.OFFSET_LINE_INDEX_NUM_BITS)
		if self.isTooLarge then
			continue
		end
		local courseSegment = { offsetLineIndex = offsetLineIndex, positions = { { startX, startZ }, { endX, endZ } }, isHeadlandSegment = false, isIslandSegment = false }
		self.courseSegments[i] = courseSegment
	end
	local numBoundaryPoints = streamReadUInt16(streamId)
	self.isTooLarge = self.isTooLarge or OrchardBuildRequestEvent.MAX_BOUNDARY_POINTS < numBoundaryPoints
	self.boundaryLine = {}
	for i = 1, numBoundaryPoints do
		local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		if self.isTooLarge then
			continue
		end
		self.boundaryLine[i] = { x, z }
	end
	local numOptionStates = streamReadUInt8(streamId)
	self.optionStates = {}
	for i = 1, numOptionStates do
		self.optionStates[i] = streamReadUInt8(streamId)
	end
	self:run(connection)
end
function OrchardBuildRequestEvent:writeStream(streamId, connection)
	local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
	streamWriteUInt8(streamId, self.requestId)
	NetworkUtil.writeNodeObject(streamId, self.fencePlaceable)
	if streamWriteBool(streamId, self.templateId ~= nil) then
		local fence = self.fencePlaceable:getFence()
		streamWriteUInt8(streamId, fence:getSegmentTemplateIndexById(self.templateId))
	end
	streamWriteUInt16(streamId, #self.courseSegments)
	for _, courseSegment in ipairs(self.courseSegments) do
		local positions = courseSegment.positions
		local startPos = positions[1]
		local endPos = positions[#positions]
		NetworkUtil.writeCompressedWorldPosition(streamId, startPos[1], paramsXZ)
		NetworkUtil.writeCompressedWorldPosition(streamId, startPos[2], paramsXZ)
		NetworkUtil.writeCompressedWorldPosition(streamId, endPos[1], paramsXZ)
		NetworkUtil.writeCompressedWorldPosition(streamId, endPos[2], paramsXZ)
		streamWriteIntN(streamId, courseSegment.offsetLineIndex, OrchardBuildRequestEvent.OFFSET_LINE_INDEX_NUM_BITS)
	end
	streamWriteUInt16(streamId, #self.boundaryLine)
	for _, position in ipairs(self.boundaryLine) do
		NetworkUtil.writeCompressedWorldPosition(streamId, position[1], paramsXZ)
		NetworkUtil.writeCompressedWorldPosition(streamId, position[2], paramsXZ)
	end
	streamWriteUInt8(streamId, #self.optionStates)
	for _, optionState in ipairs(self.optionStates) do
		streamWriteUInt8(streamId, optionState)
	end
end
function OrchardBuildRequestEvent:run(connection)
	if connection:getIsServer() then
		return
	end
	local manager = g_currentMission.orchardBuildManager
	if manager == nil then
		return
	else
		local hasLayout = 0 < #self.courseSegments and OrchardBuildRequestEvent.MIN_BOUNDARY_POINTS <= #self.boundaryLine
		if self.isTooLarge or not hasLayout or not self:getHasValidTemplate() then
			manager:rejectRequest(connection, self.requestId, OrchardBuildFinishedEvent.STATUS.INVALID_REQUEST)
			return
		end
		manager:addRequest(connection, self.requestId, self.fencePlaceable, self.templateId, self.courseSegments, self.boundaryLine, self.optionStates)
	end
end
function OrchardBuildRequestEvent:getHasValidTemplate()
	if self.fencePlaceable == nil then
		return false
	elseif OrchardBuildRequest.getIsLegacyFencePlaceable(self.fencePlaceable) then
		return self.templateId == nil
	else
		return self.templateId ~= nil
	end
end
