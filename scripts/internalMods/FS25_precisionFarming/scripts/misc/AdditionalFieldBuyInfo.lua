AdditionalFieldBuyInfo = {}
AdditionalFieldBuyInfo.MOD_NAME = g_currentModName
local AdditionalFieldBuyInfo_mt = Class(AdditionalFieldBuyInfo)
function AdditionalFieldBuyInfo.new(pfModule, customMt)
	local self = setmetatable({}, customMt or AdditionalFieldBuyInfo_mt)
	self.statistics = {}
	self.statisticsByFarmland = {}
	self.mapFrame = nil
	self.selectedFarmlandId = nil
	self.showTotal = false
	self.selectedField = 0
	self.selectedFieldSize = 0
	self.soilDistribution = { 0, 0, 0, 0 }
	self.soilDistributionTarget = { 0, 0, 0, 0 }
	self.yieldPotential = 0
	self.yieldPotentialTarget = 0
	self.doInterpolation = false
	self.allPlaceablesLoaded = false
	self.pfModule = pfModule
	return self
end
function AdditionalFieldBuyInfo:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.setColorBlindMode, self)
	g_messageCenter:subscribe(MessageType.LOADED_ALL_SAVEGAME_PLACEABLES, self.onAllPlaceablesLoaded, self)
	return true
end
function AdditionalFieldBuyInfo:loadFromItemsXML(xmlFile, key) end
function AdditionalFieldBuyInfo:saveToXMLFile(xmlFile, key, usedModNames) end
function AdditionalFieldBuyInfo:delete()
	g_messageCenter:unsubscribeAll(self)
end
function AdditionalFieldBuyInfo:readInfoFromStream(farmlandId, streamId, connection)
	if streamReadBool(streamId) then
		self.selectedField = streamReadUIntN(streamId, 9)
		self.selectedFieldSize = streamReadFloat32(streamId)
		local farmland = g_farmlandManager.farmlands[farmlandId]
		farmland.totalFieldArea = self.selectedFieldSize
		self.mapFrame.fieldBuyInfoWindow:setVisible(true)
		for i = 1, #self.soilDistributionTarget do
			self.soilDistribution[i] = 0
			self.soilDistributionTarget[i] = streamReadUIntN(streamId, 8) / 255
		end
		self.yieldPotentialTarget = streamReadUIntN(streamId, 8) / 255 * 1.25
		self.yieldPotential = 1
		self.doInterpolation = true
		self:updateUIValues()
	else
		self.mapFrame.fieldBuyInfoWindow:setVisible(false)
	end
end
function AdditionalFieldBuyInfo:writeInfoToStream(farmlandId, streamId, connection)
	local farmland = g_farmlandManager.farmlands[farmlandId]
	local fieldNumber, fieldArea = self:getFarmlandFieldInfo(farmlandId)
	local isValid = 0 < fieldArea and farmland.soilDistribution ~= nil
	if streamWriteBool(streamId, isValid) then
		streamWriteUIntN(streamId, fieldNumber, 9)
		streamWriteFloat32(streamId, fieldArea)
		for i = 1, #self.soilDistributionTarget do
			streamWriteUIntN(streamId, farmland.soilDistribution[i] * 255, 8)
		end
		streamWriteUIntN(streamId, farmland.yieldPotential / 1.25 * 255, 8)
	end
end
function AdditionalFieldBuyInfo:setColorBlindMode(isActive)
	if isActive ~= self.isColorBlindMode then
		self.isColorBlindMode = isActive
		self:updateSoilBars()
	end
end
function AdditionalFieldBuyInfo:update(dt)
	if self.doInterpolation then
		local dir = math.sign(self.yieldPotentialTarget - self.yieldPotential)
		local limit = dir == 1 and math.min or math.max
		self.yieldPotential = limit(self.yieldPotential + dt * 0.00025 * dir, self.yieldPotentialTarget)
		local finishedSoilBars = true
		for i = 1, #self.soilDistributionTarget do
			dir = math.sign(self.soilDistributionTarget[i] - self.soilDistribution[i])
			limit = dir == 1 and math.min or math.max
			self.soilDistribution[i] = limit(self.soilDistribution[i] + dt * 0.001 * dir, self.soilDistributionTarget[i])
			if self.soilDistribution[i] == self.soilDistributionTarget[i] then
				continue
			end
			finishedSoilBars = false
		end
		self:updateUIValues()
		if self.yieldPotential == self.yieldPotentialTarget and finishedSoilBars then
			self.doInterpolation = false
		end
	end
end
function AdditionalFieldBuyInfo:setMapFrame(mapFrame)
	self.mapFrame = mapFrame
	self.maxBarSize = self.maxBarSize or mapFrame.soilPercentageBar[1].size[1]
	mapFrame.fieldBuyInfoWindow:setVisible(false)
end
function AdditionalFieldBuyInfo:updateSoilBars()
	if self.pfModule.soilMap ~= nil then
		local soilTypes = self.pfModule.soilMap.soilTypes
		for i = 1, #soilTypes do
			local soilType = soilTypes[i]
			self.mapFrame.soilNameText[i]:setText(soilType.name)
			self.mapFrame.soilPercentageBar[i]:setImageColor(nil, unpack(self.isColorBlindMode and soilType.colorBlind or soilType.color))
		end
	end
end
function AdditionalFieldBuyInfo:updateUIValues()
	local mapFrame = self.mapFrame
	local contentBox = self.mapFrame.contextBoxFarmland
	local background = contentBox.elements[1]
	if self.farmlandBoxHeight == nil then
		self.farmlandBoxHeight = contentBox.size[2]
		self.farmlandBoxBgHeight = background.size[2]
	end
	if 0.01 <= self.selectedFieldSize then
		self.mapFrame.fieldBuyInfoWindow:setVisible(true)
		contentBox:setSize(nil, self.farmlandBoxHeight + self.mapFrame.fieldBuyInfoWindow.size[2])
		background:setSize(nil, self.farmlandBoxBgHeight + self.mapFrame.fieldBuyInfoWindow.size[2])
		self:updateSoilBars()
		for i = 1, 4 do
			local offset = mapFrame.soilPercentageText[i].size[1] * 0.1
			local str = "~%d%%"
			if self.soilDistribution[i] == 0 then
				str = "%d%%"
				offset = 0
			end
			mapFrame.soilPercentageText[i]:setText(string.format(str, self.soilDistribution[i] * 100))
			mapFrame.soilPercentageBar[i]:setSize(self.maxBarSize * self.soilDistribution[i])
			mapFrame.soilPercentageText[i]:setPosition(mapFrame.soilPercentageBar[i].position[1] + mapFrame.soilPercentageBar[i].size[1] + offset)
		end
		if 1 < self.yieldPotential then
			mapFrame.yieldPercentageBarPos:setPosition(mapFrame.yieldPercentageBarBase.position[1] + mapFrame.yieldPercentageBarBase.size[1])
			mapFrame.yieldPercentageBarPos:setSize(mapFrame.yieldPercentageBarBase.size[1] * (self.yieldPotential - 1))
			mapFrame.yieldPercentageBarNeg:setSize(0)
		elseif self.yieldPotential < 1 then
			local barWidth = mapFrame.yieldPercentageBarBase.size[1] * math.abs(self.yieldPotential - 1)
			mapFrame.yieldPercentageBarNeg:setPosition(mapFrame.yieldPercentageBarBase.position[1] + mapFrame.yieldPercentageBarBase.size[1] - barWidth)
			mapFrame.yieldPercentageBarNeg:setSize(barWidth)
			mapFrame.yieldPercentageBarPos:setSize(0)
		else
			mapFrame.yieldPercentageBarNeg:setSize(0)
			mapFrame.yieldPercentageBarPos:setSize(0)
		end
		mapFrame.yieldPercentageText:setText(string.format("~%d%%", self.yieldPotential * 100))
		local maxWidth = mapFrame.yieldPercentageBarBase.position[1] + mapFrame.yieldPercentageBarBase.size[1] * 1.25 - mapFrame.yieldPercentageText.size[1]
		mapFrame.yieldPercentageText:setPosition(math.min(mapFrame.yieldPercentageBarBase.position[1] + mapFrame.yieldPercentageBarBase.size[1] * self.yieldPotential - mapFrame.yieldPercentageText.size[1] * 0.5, maxWidth))
		self:updateContextBox()
	else
		self.mapFrame.fieldBuyInfoWindow:setVisible(false)
		contentBox:setSize(nil, self.farmlandBoxHeight)
		background:setSize(nil, self.farmlandBoxBgHeight)
	end
end
function AdditionalFieldBuyInfo:onFarmlandSelectionChanged(selectedFarmland)
	if self.mapFrame ~= nil then
		if selectedFarmland ~= nil then
			self.selectedFarmlandId = selectedFarmland.id
			if g_server ~= nil then
				local fieldNumber, fieldArea = self:getFarmlandFieldInfo(selectedFarmland.id)
				if 0.01 <= fieldArea then
					self.selectedField = fieldNumber
					self.selectedFieldSize = fieldArea
					if selectedFarmland.soilDistribution ~= nil then
						for i = 1, #self.soilDistributionTarget do
							self.soilDistribution[i] = 0
							self.soilDistributionTarget[i] = selectedFarmland.soilDistribution[i]
						end
						self.yieldPotentialTarget = selectedFarmland.yieldPotential
						self.yieldPotential = 1
						self.doInterpolation = true
					end
				else
					self.selectedField = 0
					self.selectedFieldSize = 0
				end
				self:updateUIValues()
				return
			end
			if g_server == nil and g_client ~= nil then
				g_client:getServerConnection():sendEvent(RequestFieldBuyInfoEvent.new(selectedFarmland.id))
			end
		else
			self.selectedField = 0
			self.selectedFieldSize = 0
			self.selectedFarmlandId = 0
			self:updateUIValues()
		end
	end
end
function AdditionalFieldBuyInfo:onShowContextBox(farmland, contextBox)
	self.lastContextBox = contextBox
end
function AdditionalFieldBuyInfo:updateContextBox()
	if self.lastContextBox ~= nil then
		local farmland = g_farmlandManager.farmlands[self.selectedFarmlandId]
		if farmland == nil then
			return
		end
		local valueText = nil
		if farmland.totalFieldArea ~= nil then
			valueText = string.format("%s (%s / ha)", g_i18n:formatMoney(farmland.price, 0, true, false), g_i18n:formatMoney(farmland.price / farmland.totalFieldArea, 0, true, false))
		else
			valueText = g_i18n:formatMoney(farmland.price, 0, true, false)
		end
		self.lastContextBox:getDescendantByName("farmlandValue"):setText(valueText)
		if farmland.totalFieldArea ~= nil then
			local text = string.format("%s (%s: %s)", g_i18n:formatArea(farmland.areaInHa, 2), g_i18n:getText("contract_details_field"), g_i18n:formatArea(farmland.totalFieldArea, 2))
			self.lastContextBox:getDescendantByName("farmlandSize"):setText(text)
		end
		if self.mapFrame.updatePrecisionFarmingContextActions ~= nil then
			self.mapFrame.updatePrecisionFarmingContextActions()
		end
	end
end
function AdditionalFieldBuyInfo:getFarmlandFieldInfo(farmlandId)
	local fieldNumber = 0
	local fieldArea = 0
	local farmland = g_farmlandManager.farmlands[farmlandId]
	if farmland ~= nil then
		fieldArea = farmland.totalFieldArea or 0
	end
	local fields = g_fieldManager:getFields()
	if fields ~= nil then
		for _, field in pairs(fields) do
			if field.farmland == nil then
				continue
			end
			if field.farmland.id == farmlandId then
				fieldNumber = field:getId()
				return fieldNumber, fieldArea
			end
		end
	end
	return fieldNumber, fieldArea
end
function AdditionalFieldBuyInfo:updateFieldSoilDistributionData()
	local pfModule = self.pfModule
	local farmlandManager = g_farmlandManager
	if pfModule.soilMap ~= nil then
		local soilBitVectorMap = pfModule.soilMap.bitVectorMap
		if soilBitVectorMap ~= nil then
			local startTime = getTimeSec()
			local farmlandX, _ = getBitVectorMapSize(farmlandManager.localMap)
			local soilX, soilY = getBitVectorMapSize(soilBitVectorMap)
			local farmlandScale = farmlandX / soilX
			for x = 0, soilX - 1 do
				for y = 0, soilY - 1 do
					local worldX = x / (soilX - 1) * g_currentMission.terrainSize - g_currentMission.terrainSize * 0.5
					local worldZ = y / (soilY - 1) * g_currentMission.terrainSize - g_currentMission.terrainSize * 0.5
					local isOnField = getDensityAtWorldPos(g_currentMission.terrainDetailId, worldX, 0, worldZ) ~= 0
					if isOnField then
						local valueFarmland = getBitVectorMapPoint(farmlandManager.localMap, x * farmlandScale, y * farmlandScale, 0, farmlandManager.numberOfBits)
						local valueSoil = bit32.band(getBitVectorMapPoint(soilBitVectorMap, x, y, 0, pfModule.soilMap.numChannels), 3)
						if 0 < valueFarmland then
							local farmland = farmlandManager.farmlands[valueFarmland]
							if farmland ~= nil then
								if farmland.totalFieldArea == nil then
									farmland.totalFieldArea = 0
								end
								farmland.totalFieldArea = farmland.totalFieldArea + 1
								if farmland.soilDistribution == nil then
									farmland.soilDistribution = {}
									for i = 1, #pfModule.soilMap.soilTypes do
										farmland.soilDistribution[i] = 0
									end
								end
								farmland.soilDistribution[valueSoil + 1] = farmland.soilDistribution[valueSoil + 1] + 1
							end
						end
					end
				end
			end
			local totalYieldPotentialPixels = 0
			local totalFarmlandPixels = 0
			for _, farmland in pairs(farmlandManager.farmlands) do
				farmland:updatePrice()
				if farmland.soilDistribution == nil then
					continue
				end
				local soilSum = 0
				for i = 1, #farmland.soilDistribution do
					soilSum = soilSum + farmland.soilDistribution[i]
				end
				if 0 < soilSum then
					local yieldPotential = 0
					for i = 1, #farmland.soilDistribution do
						farmland.soilDistribution[i] = math.floor(farmland.soilDistribution[i] / soilSum * 100) / 100
						yieldPotential = yieldPotential + self.pfModule.soilMap:getYieldPotentialBySoilTypeIndex(i) * farmland.soilDistribution[i]
						self.soilDistribution[i] = 0
					end
					farmland.yieldPotential = math.clamp(yieldPotential, 0, 1.25)
					totalYieldPotentialPixels = totalYieldPotentialPixels + farmland.yieldPotential * soilSum
					totalFarmlandPixels = totalFarmlandPixels + soilSum
				end
				local pixelToSqm = g_currentMission.terrainSize / soilX
				farmland.totalFieldArea = farmland.totalFieldArea * pixelToSqm * pixelToSqm / 10000
			end
			Logging.devInfo("Map Overall Yield Potential: %.3f (%.2fms)", totalYieldPotentialPixels / totalFarmlandPixels, (getTimeSec() - startTime) * 1000)
		end
	end
end
function AdditionalFieldBuyInfo:onAllPlaceablesLoaded()
	self.allPlaceablesLoaded = true
	if self.delayedFieldSoilDistributionUpdate and #g_fieldManager.updateTasks == 0 then
		local readyForUpdate = true
		for _, _field in pairs(g_fieldManager.fields) do
			if _field:getHasOwner() then
				continue
			end
			if _field.isMissionAllowed and not _field.pf_fieldInitialized then
				readyForUpdate = false
				break
			end
		end
		if readyForUpdate then
			self.delayedFieldSoilDistributionUpdate = false
			self:updateFieldSoilDistributionData()
		end
	end
end
function AdditionalFieldBuyInfo:overwriteGameFunctions(pfModule)
	if g_server == nil then
		pfModule:overwriteGameFunction(Placeable, "setLoadingStep", function(superFunc, placeable, loadingStep, ...)
			superFunc(placeable, loadingStep, ...)
			if g_currentMission.placeableSystem:canStartMission() then
				self:onAllPlaceablesLoaded()
			end
		end)
	end
	pfModule:overwriteGameFunction(FarmlandManager, "loadFarmlandData", function(superFunc, farmlandManager, xmlFile)
		if not superFunc(farmlandManager, xmlFile) then
			return false
		else
			if g_currentMission.missionInfo.isValid then
				self:updateFieldSoilDistributionData()
			else
				self.delayedFieldSoilDistributionUpdate = true
			end
			return true
		end
	end)
	pfModule:overwriteGameFunction(FieldManager, "onFinishFieldUpdateTask", function(superFunc, _fieldManager, task, ...)
		superFunc(_fieldManager, task, ...)
		if task.fieldId ~= nil then
			local field = _fieldManager:getFieldById(task.fieldId)
			if field ~= nil then
				field.pf_fieldInitialized = true
			end
		end
		if self.delayedFieldSoilDistributionUpdate and (self.allPlaceablesLoaded and #_fieldManager.updateTasks == 0) then
			local readyForUpdate = true
			for _, _field in pairs(_fieldManager.fields) do
				if _field:getHasOwner() then
					continue
				end
				if _field.isMissionAllowed and not _field.pf_fieldInitialized then
					readyForUpdate = false
					break
				end
			end
			if readyForUpdate then
				self.delayedFieldSoilDistributionUpdate = false
				self:updateFieldSoilDistributionData()
			end
		end
	end)
	pfModule:overwriteGameFunction(Farmland, "updatePrice", function(superFunc, farmland)
		superFunc(farmland)
		if farmland.yieldPotential ~= nil then
			farmland.price = farmland.price * farmland.yieldPotential
		end
	end)
end
