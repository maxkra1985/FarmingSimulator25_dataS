-- Local values: AIParameterLoadingStation_mt
AIParameterLoadingStation = {}
local AIParameterLoadingStation_mt = Class(AIParameterLoadingStation, AIParameter)

-- Upvalues: AIParameterLoadingStation_mt
-- Local values: self
function AIParameterLoadingStation.new(customMt)
	-- upvalues: (copy) AIParameterLoadingStation_mt
	local v3_ = AIParameter.new(customMt or AIParameterLoadingStation_mt)
	v3_.type = AIParameterType.LOADING_STATION
	v3_.loadingStationId = nil
	v3_.loadingStationIds = {}
	return v3_
end

-- Local values: loadingStation, owningPlaceable, uniqueId, index
function AIParameterLoadingStation:saveToXMLFile(xmlFile, key, usedModNames)
	local v7_ = self:getLoadingStation()
	if v7_ ~= nil then
		local v8_ = v7_.owningPlaceable
		if v8_ ~= nil then
			local v9_ = v8_:getUniqueId()
			if v9_ ~= nil then
				local v10_ = g_currentMission.storageSystem:getPlaceableLoadingStationIndex(v8_, v7_)
				if v10_ ~= nil then
					xmlFile:setString(key .. "#stationUniqueId", v9_)
					xmlFile:setInt(key .. "#stationIndex", v10_)
				end
			end
		end
	end
end

-- Local values: loadingStationUniqueId, stationIndex
function AIParameterLoadingStation:loadFromXMLFile(xmlFile, key)
	local v14_ = xmlFile:getString(key .. "#stationUniqueId")
	local v15_ = xmlFile:getInt(key .. "#stationIndex")
	if v14_ ~= nil and (v15_ ~= nil and not self:setLoadingStationFromUniqueId(v14_, v15_)) then
		g_messageCenter:subscribeOneshot(MessageType.LOADED_ALL_SAVEGAME_PLACEABLES, self.onPlaceableLoaded, self, { v14_, v15_ })
	end
end

function AIParameterLoadingStation:onPlaceableLoaded(args)
	self:setLoadingStationFromUniqueId(args[1], args[2])
end

-- Local values: placeable, loadingStation
function AIParameterLoadingStation:setLoadingStationFromUniqueId(uniqueId, index)
	local v21_ = g_currentMission.placeableSystem:getPlaceableByUniqueId(uniqueId)
	if v21_ == nil then
		return false
	end
	self:setLoadingStation((g_currentMission.storageSystem:getPlaceableLoadingStation(v21_, index)))
	return true
end

function AIParameterLoadingStation:readStream(streamId, connection)
	if streamReadBool(streamId) then
		self.loadingStationId = NetworkUtil.readNodeObjectId(streamId)
	end
end

function AIParameterLoadingStation:writeStream(streamId, connection)
	if streamWriteBool(streamId, self.loadingStationId ~= nil) then
		NetworkUtil.writeNodeObjectId(streamId, self.loadingStationId)
	end
end

function AIParameterLoadingStation:setLoadingStation(loadingStation)
	self.loadingStationId = NetworkUtil.getObjectId(loadingStation)
end

-- Local values: loadingStation
function AIParameterLoadingStation:getLoadingStation()
	local v29_ = NetworkUtil.getObject(self.loadingStationId)
	if v29_ == nil or (v29_.owningPlaceable == nil or not v29_.owningPlaceable:getIsSynchronized()) then
		return nil
	else
		return v29_
	end
end

-- Local values: loadingStation
function AIParameterLoadingStation:getString()
	local v31_ = NetworkUtil.getObject(self.loadingStationId)
	return v31_ == nil and "" or v31_:getName()
end

-- Local values: nextLoadingStationId, _, loadingStation, id
function AIParameterLoadingStation:setValidLoadingStations(loadingStationIds)
	self.loadingStationIds = {}
	local v34_ = nil
	for _, v35_ in ipairs(loadingStationIds) do
		local v36_ = NetworkUtil.getObjectId(v35_)
		if v36_ ~= nil then
			if v36_ == self.loadingStationId then
				v34_ = v36_
			end
			local v37_ = self.loadingStationIds
			table.insert(v37_, v36_)
		end
	end
	self.loadingStationId = v34_ or self.loadingStationIds[1]
end

-- Local values: nextIndex, k, loadingStationId
function AIParameterLoadingStation:setNextItem()
	local v39_ = 0
	for v40_, v41_ in ipairs(self.loadingStationIds) do
		if v41_ == self.loadingStationId then
			v39_ = v40_ + 1
		end
	end
	local v42_ = #self.loadingStationIds < v39_ and 1 or v39_
	self.loadingStationId = self.loadingStationIds[v42_]
end

-- Local values: previousIndex, k, loadingStationId
function AIParameterLoadingStation:setPreviousItem()
	local v44_ = 0
	for v45_, v46_ in ipairs(self.loadingStationIds) do
		if v46_ == self.loadingStationId then
			v44_ = v45_ - 1
		end
	end
	local v47_ = v44_ < 1 and #self.loadingStationIds or v44_
	self.loadingStationId = self.loadingStationIds[v47_]
end

-- Local values: loadingStation
function AIParameterLoadingStation:validate(fillTypeIndex, farmId)
	if self.loadingStationId == nil then
		return false, g_i18n:getText("ai_validationErrorNoLoadingStation")
	end
	local v51_ = self:getLoadingStation()
	if v51_ == nil then
		return false, g_i18n:getText("ai_validationErrorLoadingStationDoesNotExistAnymore")
	end
	if fillTypeIndex ~= nil then
		if not v51_:getIsFillTypeAISupported(fillTypeIndex) then
			return false, g_i18n:getText("ai_validationErrorFillTypeNotSupportedByLoadingStation")
		end
		if v51_:getFillLevel(fillTypeIndex, farmId) <= 0 then
			return false, g_i18n:getText("ai_validationErrorLoadingStationIsEmpty")
		end
	end
	return true, nil
end
