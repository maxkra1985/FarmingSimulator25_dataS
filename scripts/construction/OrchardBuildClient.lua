OrchardBuildClient = {}
local OrchardBuildClient_mt = Class(OrchardBuildClient)
OrchardBuildClient.ANSWER_TIMEOUT = 15000
OrchardBuildClient.MAX_REQUEST_ID = 255
OrchardBuildClient.STATUS_MESSAGES = { [OrchardBuildFinishedEvent.STATUS.NO_PERMISSION] = "ui_construction_noBuildPermission", [OrchardBuildFinishedEvent.STATUS.NOT_ENOUGH_MONEY] = "ui_construction_notEnoughMoney", [OrchardBuildFinishedEvent.STATUS.LAND_UNOWNED] = "ui_construction_landIsNotOwned", [OrchardBuildFinishedEvent.STATUS.OVERLAP] = "ui_construction_overlapsWithObject", [OrchardBuildFinishedEvent.STATUS.INVALID_REQUEST] = "ui_construction_orchardBuildFailed", [OrchardBuildFinishedEvent.STATUS.EXTRA_CONTENT_FAILED] = "ui_construction_orchardBuildFailed", [OrchardBuildFinishedEvent.STATUS.BUSY] = "ui_construction_orchardBuildFailed", [OrchardBuildFinishedEvent.STATUS.BUILD_RESTRICTED] = "ui_construction_orchardBuildFailed" }
function OrchardBuildClient.new(custom_mt)
	local self = setmetatable({}, custom_mt or OrchardBuildClient_mt)
	self.lastRequestId = 0
	self.requestId = nil
	self.fencePlaceable = nil
	self.answerTimer = 0
	self.isCancelPending = false
	return self
end
function OrchardBuildClient:delete()
	self:clearSession()
end
function OrchardBuildClient:update(dt)
	if self.requestId == nil then
		return
	end
	self.answerTimer = self.answerTimer - dt
	if 0 < self.answerTimer then
		return
	else
		Logging.warning("Orchard build %d timed out waiting for the server", self.requestId)
		self:clearSession()
		OrchardBuildProgressDialog.finish()
		g_currentMission:showBlinkingWarning(g_i18n:getText("ui_construction_orchardBuildFailed"))
	end
end
function OrchardBuildClient:getIsBuilding()
	return self.requestId ~= nil
end
function OrchardBuildClient:startBuild(fencePlaceable, templateId, courseSegments, boundaryLine, optionStates)
	if self:getIsBuilding() then
		return false
	else
		local extraSteps = 0
		if fencePlaceable.getOrchardBrushExtraStepCount ~= nil then
			extraSteps = fencePlaceable:getOrchardBrushExtraStepCount(courseSegments, optionStates)
		end
		self.lastRequestId = self.lastRequestId % OrchardBuildClient.MAX_REQUEST_ID + 1
		self.requestId = self.lastRequestId
		self.fencePlaceable = fencePlaceable
		self.answerTimer = OrchardBuildClient.ANSWER_TIMEOUT
		self.isCancelPending = false
		OrchardBuildProgressDialog.start(#courseSegments + extraSteps, self.onCancelClicked, self)
		g_messageCenter:subscribe(FenceSegmentBatchEvent, self.onBuildProgress, self)
		g_messageCenter:subscribe(OrchardBuildFinishedEvent, self.onBuildFinished, self)
		g_currentMission:addUpdateable(self)
		g_client:getServerConnection():sendEvent(OrchardBuildRequestEvent.new(self.requestId, fencePlaceable, templateId, courseSegments, boundaryLine, optionStates))
		return true
	end
end
function OrchardBuildClient:onBuildProgress(requestId, doneSteps, totalSteps)
	if requestId ~= self.requestId then
		return
	else
		self.answerTimer = OrchardBuildClient.ANSWER_TIMEOUT
		OrchardBuildProgressDialog.setProgress(doneSteps, totalSteps)
		if self.fencePlaceable ~= nil and self.fencePlaceable.playPlaceSound ~= nil then
			self.fencePlaceable:playPlaceSound()
		end
	end
end
function OrchardBuildClient:onBuildFinished(requestId, statusCode, builtSteps)
	if requestId ~= self.requestId then
		return
	else
		local warning = self:getStatusWarning(statusCode)
		self:clearSession()
		OrchardBuildProgressDialog.finish()
		if warning ~= nil then
			g_currentMission:showBlinkingWarning(warning)
		end
	end
end
function OrchardBuildClient:getStatusWarning(statusCode)
	local placeable = self.fencePlaceable
	if placeable ~= nil and placeable.getOrchardBuildStatusWarning ~= nil then
		local warning = placeable:getOrchardBuildStatusWarning(statusCode)
		if warning ~= nil then
			return warning
		end
	end
	local message = OrchardBuildClient.STATUS_MESSAGES[statusCode]
	if message == nil then
		return nil
	else
		return g_i18n:getText(message)
	end
end
function OrchardBuildClient:onCancelClicked()
	if self:getIsBuilding() and not self.isCancelPending then
		self.isCancelPending = true
		self.answerTimer = OrchardBuildClient.ANSWER_TIMEOUT
		g_client:getServerConnection():sendEvent(OrchardBuildCancelEvent.new(self.requestId))
	end
end
function OrchardBuildClient:clearSession()
	if self.requestId == nil then
		return
	else
		g_messageCenter:unsubscribe(FenceSegmentBatchEvent, self)
		g_messageCenter:unsubscribe(OrchardBuildFinishedEvent, self)
		g_currentMission:removeUpdateable(self)
		self.requestId = nil
		self.fencePlaceable = nil
		self.isCancelPending = false
	end
end
