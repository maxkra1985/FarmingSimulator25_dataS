OrchardBuildManager = {}
local OrchardBuildManager_mt = Class(OrchardBuildManager)
function OrchardBuildManager.new(custom_mt)
	local self = setmetatable({}, custom_mt or OrchardBuildManager_mt)
	self.pendingRequests = {}
	self.activeRequest = nil
	return self
end
function OrchardBuildManager:delete()
	g_currentMission:removeUpdateable(self)
	self.pendingRequests = {}
	self.activeRequest = nil
end
function OrchardBuildManager:update(dt)
	if self.activeRequest == nil then
		self:startNextRequest()
	end
	if self.activeRequest ~= nil then
		self.activeRequest:update(dt)
		if self.activeRequest:getHasFinished() then
			self.activeRequest = nil
		end
	end
	if self.activeRequest == nil and #self.pendingRequests == 0 then
		g_currentMission:removeUpdateable(self)
	end
end
function OrchardBuildManager:startNextRequest()
	while 0 < #self.pendingRequests do
		local request = table.remove(self.pendingRequests, 1)
		if request == nil then
			return
		end
		request:start()
		if request:getHasFinished() then
			continue
		end
		self.activeRequest = request
		return
	end
end
function OrchardBuildManager:getHasRequestForConnection(connection)
	if self.activeRequest ~= nil and self.activeRequest.connection == connection then
		return true
	end
	for _, request in ipairs(self.pendingRequests) do
		if request.connection == connection then
			return true
		end
	end
	return false
end
function OrchardBuildManager:addRequest(connection, requestId, fencePlaceable, templateId, courseSegments, boundaryLine, optionStates)
	if self:getHasRequestForConnection(connection) then
		self:rejectRequest(connection, requestId, OrchardBuildFinishedEvent.STATUS.BUSY)
	else
		local request = OrchardBuildRequest.new(connection, requestId, fencePlaceable, templateId, courseSegments, boundaryLine, optionStates)
		table.insert(self.pendingRequests, request)
		g_currentMission:addUpdateable(self)
	end
end
function OrchardBuildManager:cancelRequest(connection, requestId)
	if self.activeRequest ~= nil and (self.activeRequest.connection == connection and self.activeRequest.requestId == requestId) then
		self.activeRequest:cancel()
		return
	end
	for i, request in ipairs(self.pendingRequests) do
		if request.connection == connection and request.requestId == requestId then
			table.remove(self.pendingRequests, i)
			break
		end
	end
	self:rejectRequest(connection, requestId, OrchardBuildFinishedEvent.STATUS.CANCELLED)
end
function OrchardBuildManager:rejectRequest(connection, requestId, statusCode)
	if not connection.isConnected then
		return
	else
		connection:sendEvent(OrchardBuildFinishedEvent.new(requestId, statusCode, 0))
	end
end
