-- Local values: AIParameterUnloadingStation_mt
AIParameterUnloadingStation = {}
local AIParameterUnloadingStation_mt = Class(AIParameterUnloadingStation, AIParameter)

-- Upvalues: AIParameterUnloadingStation_mt
-- Local values: self
function AIParameterUnloadingStation.new(customMt)
	-- upvalues: (copy) AIParameterUnloadingStation_mt
	local v3_ = AIParameter.new(customMt or AIParameterUnloadingStation_mt)
	v3_.type = AIParameterType.UNLOADING_STATION
	v3_.unloadingStationId = nil
	v3_.unloadingStationIds = {}
	return v3_
end

-- Local values: unloadingStation, owningPlaceable, uniqueId, index
function AIParameterUnloadingStation:saveToXMLFile(xmlFile, key, usedModNames)
	local v7_ = self:getUnloadingStation()
	if v7_ ~= nil then
		local v8_ = v7_.owningPlaceable
		if v8_ ~= nil then
			local v9_ = v8_:getUniqueId()
			if v9_ ~= nil then
				local v10_ = g_currentMission.storageSystem:getPlaceableUnloadingStationIndex(v8_, v7_)
				if v10_ ~= nil then
					xmlFile:setString(key .. "#stationUniqueId", v9_)
					xmlFile:setInt(key .. "#stationIndex", v10_)
				end
			end
		end
	end
end

-- Local values: unloadingStationUniqueId, stationIndex
function AIParameterUnloadingStation:loadFromXMLFile(xmlFile, key)
	local v14_ = xmlFile:getString(key .. "#stationUniqueId")
	local v15_ = xmlFile:getInt(key .. "#stationIndex")
	if v14_ ~= nil and (v15_ ~= nil and not self:setUnloadingStationFromUniqueId(v14_, v15_)) then
		g_messageCenter:subscribeOneshot(MessageType.LOADED_ALL_SAVEGAME_PLACEABLES, self.onPlaceableLoaded, self, { v14_, v15_ })
	end
end

function AIParameterUnloadingStation:onPlaceableLoaded(args)
	self:setUnloadingStationFromUniqueId(args[1], args[2])
end

-- Local values: placeable, unloadingStation
function AIParameterUnloadingStation:setUnloadingStationFromUniqueId(uniqueId, index)
	local v21_ = g_currentMission.placeableSystem:getPlaceableByUniqueId(uniqueId)
	if v21_ == nil then
		return false
	end
	self:setUnloadingStation((g_currentMission.storageSystem:getPlaceableUnloadingStation(v21_, index)))
	return true
end

function AIParameterUnloadingStation:readStream(streamId, connection)
	if streamReadBool(streamId) then
		self.unloadingStationId = NetworkUtil.readNodeObjectId(streamId)
	end
end

function AIParameterUnloadingStation:writeStream(streamId, connection)
	if streamWriteBool(streamId, self.unloadingStationId ~= nil) then
		NetworkUtil.writeNodeObjectId(streamId, self.unloadingStationId)
	end
end

function AIParameterUnloadingStation:setUnloadingStation(unloadingStation)
	self.unloadingStationId = NetworkUtil.getObjectId(unloadingStation)
end

-- Local values: unloadingStation
function AIParameterUnloadingStation:getUnloadingStation()
	local v29_ = NetworkUtil.getObject(self.unloadingStationId)
	if v29_ == nil or (v29_.owningPlaceable == nil or not v29_.owningPlaceable:getIsSynchronized()) then
		return nil
	else
		return v29_
	end
end

-- Local values: unloadingStation
function AIParameterUnloadingStation:getString()
	local v31_ = NetworkUtil.getObject(self.unloadingStationId)
	return v31_ == nil and "" or v31_:getName()
end

-- Local values: nextUnloadingStationId, _, unloadingStation, id
function AIParameterUnloadingStation:setValidUnloadingStations(unloadingStations)
	self.unloadingStationIds = {}
	local v34_ = nil
	for _, v35_ in ipairs(unloadingStations) do
		local v36_ = NetworkUtil.getObjectId(v35_)
		if v36_ ~= nil then
			if v36_ == self.unloadingStationId then
				v34_ = v36_
			end
			local v37_ = self.unloadingStationIds
			table.insert(v37_, v36_)
		end
	end
	self.unloadingStationId = v34_ or self.unloadingStationIds[1]
end

-- Local values: nextIndex, k, unloadingStationId
function AIParameterUnloadingStation:setNextItem()
	local v39_ = 0
	for v40_, v41_ in ipairs(self.unloadingStationIds) do
		if v41_ == self.unloadingStationId then
			v39_ = v40_ + 1
		end
	end
	local v42_ = #self.unloadingStationIds < v39_ and 1 or v39_
	self.unloadingStationId = self.unloadingStationIds[v42_]
end

-- Local values: previousIndex, k, unloadingStationId
function AIParameterUnloadingStation:setPreviousItem()
	local v44_ = 0
	for v45_, v46_ in ipairs(self.unloadingStationIds) do
		if v46_ == self.unloadingStationId then
			v44_ = v45_ - 1
		end
	end
	local v47_ = v44_ < 1 and #self.unloadingStationIds or v44_
	self.unloadingStationId = self.unloadingStationIds[v47_]
end

-- Local values: unloadingStation
function AIParameterUnloadingStation:validate(fillTypeIndex, farmId)
	if self.unloadingStationId == nil then
		return false, g_i18n:getText("ai_validationErrorNoUnloadingStation")
	end
	local v51_ = self:getUnloadingStation()
	if v51_ == nil then
		return false, g_i18n:getText("ai_validationErrorUnloadingStationDoesNotExistAnymore")
	end
	if fillTypeIndex ~= nil then
		if not v51_:getIsFillTypeAISupported(fillTypeIndex) then
			return false, g_i18n:getText("ai_validationErrorFillTypeNotSupportedByUnloadingStation")
		end
		if v51_:getFreeCapacity(fillTypeIndex, farmId) <= 0 then
			return false, g_i18n:getText("ai_validationErrorUnloadingStationIsFull")
		end
	end
	return true, nil
end
