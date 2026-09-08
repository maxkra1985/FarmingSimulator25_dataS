-- Local values: AdditionalFieldBuyInfo_mt
AdditionalFieldBuyInfo = {}
AdditionalFieldBuyInfo.MOD_NAME = g_currentModName
local AdditionalFieldBuyInfo_mt = Class(AdditionalFieldBuyInfo)

-- Upvalues: AdditionalFieldBuyInfo_mt
-- Local values: self
function AdditionalFieldBuyInfo.new(pfModule, customMt)
	-- upvalues: (copy) AdditionalFieldBuyInfo_mt
	local v4_ = customMt or AdditionalFieldBuyInfo_mt
	local v5_ = setmetatable({}, v4_)
	v5_.statistics = {}
	v5_.statisticsByFarmland = {}
	v5_.mapFrame = nil
	v5_.selectedFarmlandId = nil
	v5_.showTotal = false
	v5_.selectedField = 0
	v5_.selectedFieldSize = 0
	v5_.soilDistribution = {
		0,
		0,
		0,
		0
	}
	v5_.soilDistributionTarget = {
		0,
		0,
		0,
		0
	}
	v5_.yieldPotential = 0
	v5_.yieldPotentialTarget = 0
	v5_.doInterpolation = false
	v5_.allPlaceablesLoaded = false
	v5_.pfModule = pfModule
	return v5_
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

-- Local values: farmland, i
function AdditionalFieldBuyInfo:readInfoFromStream(farmlandId, streamId, connection)
	if streamReadBool(streamId) then
		self.selectedField = streamReadUIntN(streamId, 9)
		self.selectedFieldSize = streamReadFloat32(streamId)
		g_farmlandManager.farmlands[farmlandId].totalFieldArea = self.selectedFieldSize
		self.mapFrame.fieldBuyInfoWindow:setVisible(true)
		for v11_ = 1, #self.soilDistributionTarget do
			self.soilDistribution[v11_] = 0
			self.soilDistributionTarget[v11_] = streamReadUIntN(streamId, 8) / 255
		end
		self.yieldPotentialTarget = streamReadUIntN(streamId, 8) / 255 * 1.25
		self.yieldPotential = 1
		self.doInterpolation = true
		self:updateUIValues()
	else
		self.mapFrame.fieldBuyInfoWindow:setVisible(false)
	end
end

-- Local values: farmland, fieldNumber, fieldArea, isValid, i
function AdditionalFieldBuyInfo:writeInfoToStream(farmlandId, streamId, connection)
	local v15_ = g_farmlandManager.farmlands[farmlandId]
	local v16_, v17_ = self:getFarmlandFieldInfo(farmlandId)
	local v18_
	if v17_ > 0 then
		v18_ = v15_.soilDistribution ~= nil
	else
		v18_ = false
	end
	if streamWriteBool(streamId, v18_) then
		streamWriteUIntN(streamId, v16_, 9)
		streamWriteFloat32(streamId, v17_)
		for v19_ = 1, #self.soilDistributionTarget do
			streamWriteUIntN(streamId, v15_.soilDistribution[v19_] * 255, 8)
		end
		streamWriteUIntN(streamId, v15_.yieldPotential / 1.25 * 255, 8)
	end
end

function AdditionalFieldBuyInfo:setColorBlindMode(isActive)
	if isActive ~= self.isColorBlindMode then
		self.isColorBlindMode = isActive
		self:updateSoilBars()
	end
end

-- Local values: dir, limit, finishedSoilBars, i
function AdditionalFieldBuyInfo:update(dt)
	if self.doInterpolation then
		local v24_ = self.yieldPotentialTarget - self.yieldPotential
		local v25_ = math.sign(v24_)
		self.yieldPotential = (v25_ == 1 and math.min or math.max)(self.yieldPotential + dt * 0.00025 * v25_, self.yieldPotentialTarget)
		local v26_ = true
		for v27_ = 1, #self.soilDistributionTarget do
			local v28_ = self.soilDistributionTarget[v27_] - self.soilDistribution[v27_]
			local v29_ = math.sign(v28_)
			local v30_ = v29_ == 1 and math.min or math.max
			self.soilDistribution[v27_] = v30_(self.soilDistribution[v27_] + dt * 0.001 * v29_, self.soilDistributionTarget[v27_])
			if self.soilDistribution[v27_] ~= self.soilDistributionTarget[v27_] then
				v26_ = false
			end
		end
		self:updateUIValues()
		if self.yieldPotential == self.yieldPotentialTarget and v26_ then
			self.doInterpolation = false
		end
	end
end

function AdditionalFieldBuyInfo:setMapFrame(mapFrame)
	self.mapFrame = mapFrame
	self.maxBarSize = self.maxBarSize or mapFrame.soilPercentageBar[1].size[1]
	mapFrame.fieldBuyInfoWindow:setVisible(false)
end

-- Local values: soilTypes, i, soilType
function AdditionalFieldBuyInfo:updateSoilBars()
	if self.pfModule.soilMap ~= nil then
		local v34_ = self.pfModule.soilMap.soilTypes
		for v35_ = 1, #v34_ do
			local v36_ = v34_[v35_]
			self.mapFrame.soilNameText[v35_]:setText(v36_.name)
			local v37_ = self.mapFrame.soilPercentageBar[v35_]
			local v38_ = self.isColorBlindMode and v36_.colorBlind or v36_.color
			v37_:setImageColor(nil, unpack(v38_))
		end
	end
end

-- Local values: mapFrame, contentBox, background, i, offset, str, barWidth, maxWidth
function AdditionalFieldBuyInfo:updateUIValues()
	local v40_ = self.mapFrame
	local v41_ = self.mapFrame.contextBoxFarmland
	local v42_ = v41_.elements[1]
	if self.farmlandBoxHeight == nil then
		self.farmlandBoxHeight = v41_.size[2]
		self.farmlandBoxBgHeight = v42_.size[2]
	end
	if self.selectedFieldSize >= 0.01 then
		self.mapFrame.fieldBuyInfoWindow:setVisible(true)
		v41_:setSize(nil, self.farmlandBoxHeight + self.mapFrame.fieldBuyInfoWindow.size[2])
		v42_:setSize(nil, self.farmlandBoxBgHeight + self.mapFrame.fieldBuyInfoWindow.size[2])
		self:updateSoilBars()
		for v43_ = 1, 4 do
			local v44_ = v40_.soilPercentageText[v43_].size[1] * 0.1
			local v45_
			if self.soilDistribution[v43_] == 0 then
				v45_ = "%d%%"
				v44_ = 0
			else
				v45_ = "~%d%%"
			end
			v40_.soilPercentageText[v43_]:setText(string.format(v45_, self.soilDistribution[v43_] * 100))
			v40_.soilPercentageBar[v43_]:setSize(self.maxBarSize * self.soilDistribution[v43_])
			v40_.soilPercentageText[v43_]:setPosition(v40_.soilPercentageBar[v43_].position[1] + v40_.soilPercentageBar[v43_].size[1] + v44_)
		end
		if self.yieldPotential > 1 then
			v40_.yieldPercentageBarPos:setPosition(v40_.yieldPercentageBarBase.position[1] + v40_.yieldPercentageBarBase.size[1])
			v40_.yieldPercentageBarPos:setSize(v40_.yieldPercentageBarBase.size[1] * (self.yieldPotential - 1))
			v40_.yieldPercentageBarNeg:setSize(0)
		elseif self.yieldPotential < 1 then
			local v46_ = v40_.yieldPercentageBarBase.size[1]
			local v47_ = self.yieldPotential - 1
			local v48_ = v46_ * math.abs(v47_)
			v40_.yieldPercentageBarNeg:setPosition(v40_.yieldPercentageBarBase.position[1] + v40_.yieldPercentageBarBase.size[1] - v48_)
			v40_.yieldPercentageBarNeg:setSize(v48_)
			v40_.yieldPercentageBarPos:setSize(0)
		else
			v40_.yieldPercentageBarNeg:setSize(0)
			v40_.yieldPercentageBarPos:setSize(0)
		end
		v40_.yieldPercentageText:setText(string.format("~%d%%", self.yieldPotential * 100))
		local v49_ = v40_.yieldPercentageBarBase.position[1] + v40_.yieldPercentageBarBase.size[1] * 1.25 - v40_.yieldPercentageText.size[1]
		local v50_ = v40_.yieldPercentageText
		local v51_ = v40_.yieldPercentageBarBase.position[1] + v40_.yieldPercentageBarBase.size[1] * self.yieldPotential - v40_.yieldPercentageText.size[1] * 0.5
		v50_:setPosition((math.min(v51_, v49_)))
		self:updateContextBox()
	else
		self.mapFrame.fieldBuyInfoWindow:setVisible(false)
		v41_:setSize(nil, self.farmlandBoxHeight)
		v42_:setSize(nil, self.farmlandBoxBgHeight)
	end
end

-- Local values: fieldNumber, fieldArea, i
function AdditionalFieldBuyInfo:onFarmlandSelectionChanged(selectedFarmland)
	if self.mapFrame ~= nil then
		if selectedFarmland == nil then
			self.selectedField = 0
			self.selectedFieldSize = 0
			self.selectedFarmlandId = 0
			self:updateUIValues()
		else
			self.selectedFarmlandId = selectedFarmland.id
			if g_server ~= nil then
				local v54_, v55_ = self:getFarmlandFieldInfo(selectedFarmland.id)
				if v55_ >= 0.01 then
					self.selectedField = v54_
					self.selectedFieldSize = v55_
					if selectedFarmland.soilDistribution ~= nil then
						for v56_ = 1, #self.soilDistributionTarget do
							self.soilDistribution[v56_] = 0
							self.soilDistributionTarget[v56_] = selectedFarmland.soilDistribution[v56_]
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
				return
			end
		end
	end
end

function AdditionalFieldBuyInfo:onShowContextBox(farmland, contextBox)
	self.lastContextBox = contextBox
end

-- Local values: farmland, valueText, text
function AdditionalFieldBuyInfo:updateContextBox()
	if self.lastContextBox ~= nil then
		local v60_ = g_farmlandManager.farmlands[self.selectedFarmlandId]
		if v60_ == nil then
			return
		end
		local v61_
		if v60_.totalFieldArea == nil then
			v61_ = g_i18n:formatMoney(v60_.price, 0, true, false)
		else
			v61_ = string.format("%s (%s / ha)", g_i18n:formatMoney(v60_.price, 0, true, false), g_i18n:formatMoney(v60_.price / v60_.totalFieldArea, 0, true, false))
		end
		self.lastContextBox:getDescendantByName("farmlandValue"):setText(v61_)
		if v60_.totalFieldArea ~= nil then
			local v62_ = string.format("%s (%s: %s)", g_i18n:formatArea(v60_.areaInHa, 2), g_i18n:getText("contract_details_field"), g_i18n:formatArea(v60_.totalFieldArea, 2))
			self.lastContextBox:getDescendantByName("farmlandSize"):setText(v62_)
		end
		if self.mapFrame.updatePrecisionFarmingContextActions ~= nil then
			self.mapFrame.updatePrecisionFarmingContextActions()
		end
	end
end

-- Local values: fieldNumber, fieldArea, farmland, fields, _, field
function AdditionalFieldBuyInfo:getFarmlandFieldInfo(farmlandId)
	local v64_ = 0
	local v65_ = g_farmlandManager.farmlands[farmlandId]
	local v66_ = v65_ == nil and 0 or (v65_.totalFieldArea or 0)
	local v67_ = g_fieldManager:getFields()
	if v67_ ~= nil then
		for _, v68_ in pairs(v67_) do
			if v68_.farmland ~= nil and v68_.farmland.id == farmlandId then
				return v68_:getId(), v66_
			end
		end
	end
	return v64_, v66_
end

-- Local values: pfModule, farmlandManager, soilBitVectorMap, startTime, farmlandX, _, soilX, soilY, farmlandScale, x, y, worldX, worldZ, isOnField, valueFarmland, valueSoil, farmland, i, totalYieldPotentialPixels, totalFarmlandPixels, _, farmland, soilSum, i, yieldPotential, i, pixelToSqm
function AdditionalFieldBuyInfo:updateFieldSoilDistributionData()
	local v70_ = self.pfModule
	local v71_ = g_farmlandManager
	if v70_.soilMap ~= nil then
		local v72_ = v70_.soilMap.bitVectorMap
		if v72_ ~= nil then
			local v73_ = getTimeSec()
			local v74_, _ = getBitVectorMapSize(v71_.localMap)
			local v75_, v76_ = getBitVectorMapSize(v72_)
			local v77_ = v74_ / v75_
			for v78_ = 0, v75_ - 1 do
				for v79_ = 0, v76_ - 1 do
					local v80_ = v78_ / (v75_ - 1) * g_currentMission.terrainSize - g_currentMission.terrainSize * 0.5
					local v81_ = v79_ / (v76_ - 1) * g_currentMission.terrainSize - g_currentMission.terrainSize * 0.5
					if getDensityAtWorldPos(g_currentMission.terrainDetailId, v80_, 0, v81_) ~= 0 then
						local v82_ = getBitVectorMapPoint(v71_.localMap, v78_ * v77_, v79_ * v77_, 0, v71_.numberOfBits)
						local v83_ = getBitVectorMapPoint(v72_, v78_, v79_, 0, v70_.soilMap.numChannels)
						local v84_ = bit32.band(v83_, 3)
						if v82_ > 0 then
							local v85_ = v71_.farmlands[v82_]
							if v85_ ~= nil then
								if v85_.totalFieldArea == nil then
									v85_.totalFieldArea = 0
								end
								v85_.totalFieldArea = v85_.totalFieldArea + 1
								if v85_.soilDistribution == nil then
									v85_.soilDistribution = {}
									for v86_ = 1, #v70_.soilMap.soilTypes do
										v85_.soilDistribution[v86_] = 0
									end
								end
								v85_.soilDistribution[v84_ + 1] = v85_.soilDistribution[v84_ + 1] + 1
							end
						end
					end
				end
			end
			local v87_ = 0
			local v88_ = 0
			for _, v89_ in pairs(v71_.farmlands) do
				v89_:updatePrice()
				if v89_.soilDistribution ~= nil then
					local v90_ = 0
					for v91_ = 1, #v89_.soilDistribution do
						v90_ = v90_ + v89_.soilDistribution[v91_]
					end
					if v90_ > 0 then
						local v92_ = 0
						for v93_ = 1, #v89_.soilDistribution do
							local v94_ = v89_.soilDistribution
							local v95_ = v89_.soilDistribution[v93_] / v90_ * 100
							v94_[v93_] = math.floor(v95_) / 100
							v92_ = v92_ + self.pfModule.soilMap:getYieldPotentialBySoilTypeIndex(v93_) * v89_.soilDistribution[v93_]
							self.soilDistribution[v93_] = 0
						end
						v89_.yieldPotential = math.clamp(v92_, 0, 1.25)
						v87_ = v87_ + v89_.yieldPotential * v90_
						v88_ = v88_ + v90_
					end
					local v96_ = g_currentMission.terrainSize / v75_
					v89_.totalFieldArea = v89_.totalFieldArea * v96_ * v96_ / 10000
				end
			end
			Logging.devInfo("Map Overall Yield Potential: %.3f (%.2fms)", v87_ / v88_, (getTimeSec() - v73_) * 1000)
		end
	end
end

-- Local values: readyForUpdate, _, _field
function AdditionalFieldBuyInfo:onAllPlaceablesLoaded()
	self.allPlaceablesLoaded = true
	if self.delayedFieldSoilDistributionUpdate and #g_fieldManager.updateTasks == 0 then
		local v98_ = true
		for _, v99_ in pairs(g_fieldManager.fields) do
			if not v99_:getHasOwner() and (v99_.isMissionAllowed and not v99_.pf_fieldInitialized) then
				v98_ = false
				break
			end
		end
		if v98_ then
			self.delayedFieldSoilDistributionUpdate = false
			self:updateFieldSoilDistributionData()
		end
	end
end

function AdditionalFieldBuyInfo:overwriteGameFunctions(pfModule)
	if g_server == nil then
		pfModule:overwriteGameFunction(Placeable, "setLoadingStep", function(p102_, p103_, p104_, ...)
			-- upvalues: (copy) self
			p102_(p103_, p104_, ...)
			if g_currentMission.placeableSystem:canStartMission() then
				self:onAllPlaceablesLoaded()
			end
		end)
	end
	pfModule:overwriteGameFunction(FarmlandManager, "loadFarmlandData", function(p105_, p106_, p107_)
		-- upvalues: (copy) self
		if not p105_(p106_, p107_) then
			return false
		end
		if g_currentMission.missionInfo.isValid then
			self:updateFieldSoilDistributionData()
		else
			self.delayedFieldSoilDistributionUpdate = true
		end
		return true
	end)
	pfModule:overwriteGameFunction(FieldManager, "onFinishFieldUpdateTask", function(p108_, p109_, p110_, ...)
		-- upvalues: (copy) self
		p108_(p109_, p110_, ...)
		if p110_.fieldId ~= nil then
			local v111_ = p109_:getFieldById(p110_.fieldId)
			if v111_ ~= nil then
				v111_.pf_fieldInitialized = true
			end
		end
		if self.delayedFieldSoilDistributionUpdate and (self.allPlaceablesLoaded and #p109_.updateTasks == 0) then
			local v112_ = true
			for _, v113_ in pairs(p109_.fields) do
				if not v113_:getHasOwner() and (v113_.isMissionAllowed and not v113_.pf_fieldInitialized) then
					v112_ = false
					break
				end
			end
			if v112_ then
				self.delayedFieldSoilDistributionUpdate = false
				self:updateFieldSoilDistributionData()
			end
		end
	end)
	pfModule:overwriteGameFunction(Farmland, "updatePrice", function(p114_, p115_)
		p114_(p115_)
		if p115_.yieldPotential ~= nil then
			p115_.price = p115_.price * p115_.yieldPotential
		end
	end)
end
