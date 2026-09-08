-- Local values: HandToolLoadingData_mt
HandToolLoadingData = {}
local HandToolLoadingData_mt = Class(HandToolLoadingData)

-- Upvalues: HandToolLoadingData_mt
-- Local values: self
function HandToolLoadingData.new(customMt)
	-- upvalues: (copy) HandToolLoadingData_mt
	local v3_ = customMt or HandToolLoadingData_mt
	local v4_ = setmetatable({}, v3_)
	v4_.isValid = false
	v4_.storeItem = nil
	v4_.handToolData = nil
	v4_.ownerFarmId = AccessHandler.EVERYONE
	v4_.savegameData = nil
	v4_.isSaved = true
	v4_.canBeDropped = true
	v4_.isRegistered = true
	v4_.forceServer = false
	v4_.loadingHandTool = nil
	v4_.loadingState = nil
	return v4_
end

function HandToolLoadingData:setFilename(filename)
	if fileExists(filename) then
		self.handToolData = {
			["xmlFilename"] = filename
		}
	else
		Logging.error("Unable to find handtool config for \'%s\'", filename)
		printCallstack()
	end
end

function HandToolLoadingData:setStoreItem(storeItem)
	if storeItem == nil then
		Logging.error("No store item defined")
		printCallstack()
	else
		self.storeItem = storeItem
		self.handToolData = {
			["xmlFilename"] = storeItem.xmlFilename
		}
	end
	self.isValid = storeItem ~= nil
end

function HandToolLoadingData:setOwnerFarmId(ownerFarmId)
	self.ownerFarmId = ownerFarmId
end

function HandToolLoadingData:setIsRegistered(isRegistered)
	self.isRegistered = isRegistered
end

function HandToolLoadingData:setHolder(holder)
	self.holder = holder
end

function HandToolLoadingData:setIsSaved(isSaved)
	self.isSaved = isSaved
end

function HandToolLoadingData:setCanBeDropped(canBeDropped)
	self.canBeDropped = canBeDropped
end

function HandToolLoadingData:setSavegameData(savegameData)
	self.savegameData = savegameData
end

-- Local values: handToolData
function HandToolLoadingData:load(callback, callbackTarget, callbackArguments)
	self.callback = callback
	self.callbackTarget = callbackTarget
	self.callbackArguments = callbackArguments
	local v25_ = self.handToolData
	local v26_, v27_ = g_handToolTypeManager:getObjectTypeFromXML(v25_.xmlFilename)
	v25_.handToolType = v26_
	v25_.handToolClass = v27_
	self.loadingState = HandToolLoadingState.OK
	if v25_.handToolType == nil or v25_.handToolClass == nil then
		self.loadingState = HandToolLoadingState.ERROR
		if self.callback ~= nil then
			self.callback(self.callbackTarget, nil, self.loadingState, self.callbackArguments)
			self.callback = nil
			self.callbackTarget = nil
			self.callbackArguments = nil
		end
	else
		self:loadHandTool(v25_)
	end
end

-- Local values: isServer, isClient, handTool
function HandToolLoadingData:loadHandTool(handToolData)
	local v30_ = self.forceServer or g_currentMission:getIsServer()
	local v31_ = self.forceServer or g_currentMission:getIsClient()
	local v32_ = handToolData.handToolClass.new(v30_, v31_)
	v32_:setFilename(handToolData.xmlFilename)
	v32_:setType(handToolData.handToolType)
	v32_:setLoadCallback(self.onHandToolLoaded, self, nil)
	v32_:load(self)
	self.loadingHandTool = v32_
end

-- Local values: handToolData, handToolType, _
function HandToolLoadingData:loadHandToolOnClient(handTool, callback, callbackTarget)
	local v36_ = self.handToolData
	local v37_, _ = g_handToolTypeManager:getObjectTypeFromXML(v36_.xmlFilename)
	if v37_ ~= nil then
		handTool:setFilename(v36_.xmlFilename)
		handTool:setType(v37_)
		handTool:setLoadCallback(callback, self, nil)
		handTool:load(self)
	end
end

function HandToolLoadingData:cancelLoading()
	self.canceledLoading = true
	if self.loadingHandTool ~= nil then
		self.loadingHandTool:delete()
	end
	if self.callback ~= nil then
		self.callback(self.callbackTarget, nil, HandToolLoadingState.CANCELED, self.callbackArguments)
		self.callback = nil
		self.callbackTarget = nil
		self.callbackArguments = nil
	end
end

function HandToolLoadingData:onHandToolLoaded(handTool, loadingState)
	if not self.canceledLoading then
		if loadingState == HandToolLoadingState.OK then
			g_messageCenter:publish(MessageType.HANDTOOL_LOADED, handTool)
		else
			self.loadingState = loadingState
			handTool:delete()
		end
		if self.callback ~= nil then
			self.callback(self.callbackTarget, handTool, self.loadingState, self.callbackArguments)
			self.callback = nil
			self.callbackTarget = nil
			self.callbackArguments = nil
		end
	end
end
