-- Local values: FarmlandStatistics_mt
FarmlandStatistics = {}
source(g_currentModDirectory .. "scripts/gui/FarmlandStatsDialog.lua")
FarmlandStatistics.MOD_NAME = g_currentModName
local FarmlandStatistics_mt = Class(FarmlandStatistics)

-- Upvalues: FarmlandStatistics_mt
-- Local values: self
function FarmlandStatistics.new(pfModule, customMt)
	-- upvalues: (copy) FarmlandStatistics_mt
	local v4_ = customMt or FarmlandStatistics_mt
	local v5_ = setmetatable({}, v4_)
	v5_.statistics = {}
	v5_.statisticsByFarmland = {}
	v5_.mapFrame = nil
	v5_.pfModule = pfModule
	return v5_
end

function FarmlandStatistics:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	g_messageCenter:subscribe(MessageType.FARMLAND_OWNER_CHANGED, self.onFarmlandStateChanged, self)
	return true
end

-- Local values: i, statistic, statKey
function FarmlandStatistics:loadFromItemsXML(xmlFile, key)
	local v10_ = key .. ".farmlandStatistics"
	for v11_ = 1, #self.statistics do
		local v12_ = self.statistics[v11_]
		local v13_ = string.format("%s.farmlandStatistic(%d)", v10_, v11_ - 1)
		if not xmlFile:hasProperty(v13_) then
			break
		end
		v12_:loadFromItemsXML(xmlFile, v13_)
	end
end

-- Local values: i, statistic, statKey
function FarmlandStatistics:saveToXMLFile(xmlFile, key, usedModNames)
	local v18_ = key .. ".farmlandStatistics"
	for v19_ = 1, #self.statistics do
		self.statistics[v19_]:saveToXMLFile(xmlFile, string.format("%s.farmlandStatistic(%d)", v18_, v19_ - 1), usedModNames)
	end
end

function FarmlandStatistics:delete()
	g_messageCenter:unsubscribeAll(self)
	self.statistics = {}
	self.statisticsByFarmland = {}
end

-- Local values: totalFieldArea, farmland, statistic
function FarmlandStatistics:readStatisticFromStream(farmlandId, streamId, connection)
	if streamReadBool(streamId) then
		local v25_ = streamReadFloat32(streamId)
		local v26_ = g_farmlandManager.farmlands[farmlandId]
		if v26_ ~= nil then
			v26_.totalFieldArea = v25_
		end
	end
	local v27_ = self.statisticsByFarmland[farmlandId]
	if v27_ ~= nil then
		v27_:onReadStream(streamId, connection)
	end
	self.selectedFarmlandId = farmlandId
	self:openStatistics(farmlandId, true)
end

-- Local values: farmland, statistic
function FarmlandStatistics:writeStatisticToStream(farmlandId, streamId, connection)
	local v32_ = g_farmlandManager.farmlands[farmlandId]
	if streamWriteBool(streamId, v32_ ~= nil) then
		streamWriteFloat32(streamId, v32_.totalFieldArea or 0)
	end
	local v33_ = self.statisticsByFarmland[farmlandId]
	if v33_ ~= nil then
		v33_:onWriteStream(streamId, connection)
	end
end

function FarmlandStatistics:setMapFrame(mapFrame)
	self.mapFrame = mapFrame
end

function FarmlandStatistics:collectFarmlandHotspotActions(actions)
	local v38_ = {
		["title"] = g_i18n:getText("ui_economicAnalysis"),
		["callback"] = self.openStatistics,
		["callbackTarget"] = self
	}
	table.insert(actions, v38_)
end

-- Local values: statistic, fieldNumber, fieldArea
function FarmlandStatistics:openStatistics(farmlandId, noEventSend)
	self.mapFrame:setMapSelectionItem(nil)
	local v42_ = self.statisticsByFarmland[farmlandId]
	if v42_ ~= nil then
		local v43_, v44_ = self:getFarmlandFieldInfo(farmlandId)
		if v44_ >= 0.01 then
			FarmlandStatsDialog.show(farmlandId, v43_, v44_, v42_)
		end
	end
	if not noEventSend and (g_server == nil and g_client ~= nil) then
		g_client:getServerConnection():sendEvent(RequestFarmlandStatisticsEvent.new(farmlandId))
	end
end

function FarmlandStatistics:getFarmlandFieldInfo(farmlandId)
	return self.pfModule:getFarmlandFieldInfo(farmlandId)
end

-- Local values: statistic
function FarmlandStatistics:updateStatistic(farmlandId, name, value)
	local v51_ = self.statisticsByFarmland[farmlandId]
	if v51_ ~= nil then
		v51_:updateStatistic(name, value)
	end
end

-- Local values: statistic
function FarmlandStatistics:resetStatistic(farmlandId, clearTotal)
	local v55_ = self.statisticsByFarmland[farmlandId]
	if v55_ ~= nil then
		v55_:reset(clearTotal)
	end
end

-- Local values: fillType
function FarmlandStatistics:getFillLevelWeight(fillLevel, fillTypeIndex)
	local v58_ = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	if v58_ == nil then
		return fillLevel
	else
		return fillLevel * (v58_.massPerLiter / FillTypeManager.MASS_SCALE)
	end
end

-- Local values: price, fillType
function FarmlandStatistics:getFillLevelPrice(fillLevel, fillTypeIndex)
	if fillTypeIndex == "soilSamples" then
		return fillLevel * (self.pfModule.soilMap.pricePerSample[g_currentMission.missionInfo.economicDifficulty] or 0)
	else
		local v62_ = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
		if v62_ == nil then
			return fillLevel
		else
			return fillLevel * v62_.pricePerLiter
		end
	end
end

function FarmlandStatistics:onFarmlandStateChanged(farmlandId, farmId, loadFromSavegame)
	if not loadFromSavegame then
		self:resetStatistic(farmlandId, true)
	end
end

function FarmlandStatistics:overwriteGameFunctions(pfModule)
	FarmlandStatsDialog.register()
	pfModule:overwriteGameFunction(FarmlandManager, "loadFarmlandData", function(p68_, p69_, p70_)
		-- upvalues: (copy) self
		if not p68_(p69_, p70_) then
			return false
		end
		local v71_ = g_farmlandManager:getFarmlands()
		if v71_ ~= nil then
			for v72_, _ in pairs(v71_) do
				local v73_ = FarmlandStatistic.new(v72_)
				self.statisticsByFarmland[v72_] = v73_
				local v74_ = self.statistics
				table.insert(v74_, v73_)
			end
		end
		return true
	end)
end
