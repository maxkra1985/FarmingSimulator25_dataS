-- Local values: EnvironmentalScore_mt
EnvironmentalScore = {}
EnvironmentalScore.MOD_NAME = g_currentModName
EnvironmentalScore.MOD_DIR = g_currentModDirectory
EnvironmentalScore.YIELD_INCREASE = 0.15
EnvironmentalScore.SCORE_UPDATE_TIME = 2500
EnvironmentalScore.GUI_ELEMENTS = EnvironmentalScore.MOD_DIR .. "gui/ui_elements.png"
source(EnvironmentalScore.MOD_DIR .. "scripts/environmentalScore/EnvironmentalScoreValue.lua")
source(EnvironmentalScore.MOD_DIR .. "scripts/environmentalScore/EnvironmentalScoreHerbicide.lua")
source(EnvironmentalScore.MOD_DIR .. "scripts/environmentalScore/EnvironmentalScoreNitrogen.lua")
source(EnvironmentalScore.MOD_DIR .. "scripts/environmentalScore/EnvironmentalScorePH.lua")
source(EnvironmentalScore.MOD_DIR .. "scripts/environmentalScore/EnvironmentalScoreSoilSample.lua")
source(EnvironmentalScore.MOD_DIR .. "scripts/environmentalScore/EnvironmentalScoreTillage.lua")
source(EnvironmentalScore.MOD_DIR .. "scripts/events/EnvironmentalScoreEvent.lua")
source(EnvironmentalScore.MOD_DIR .. "scripts/events/RequestEnvironmentalScoreEvent.lua")
local EnvironmentalScore_mt = Class(EnvironmentalScore)

-- Upvalues: EnvironmentalScore_mt
-- Local values: self, _
function EnvironmentalScore.new(pfModule, customMt)
	-- upvalues: (copy) EnvironmentalScore_mt
	local v4_ = customMt or EnvironmentalScore_mt
	local v5_ = setmetatable({}, v4_)
	v5_.pfModule = pfModule
	v5_.mapFrame = nil
	v5_.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE)
	v5_.moneyChangeTypePos = MoneyType.register("other", "info_environmentalScoreReward", SoilMap.MOD_NAME)
	v5_.moneyChangeTypeNeg = MoneyType.register("other", "info_environmentalScorePenalty", SoilMap.MOD_NAME)
	v5_.scoreUpdateTimer = 0
	v5_.harvestedStates = {}
	v5_.farmRevenueIncrease = {}
	v5_.farmRevenueIncreaseMessageDirty = false
	v5_.overwrittenWindowState = false
	v5_.currentInputHelpMode = g_inputBinding:getInputHelpMode()
	v5_.scoreValues = {}
	v5_.scoreObjects = {}
	v5_.scoreObjects.EnvironmentalScoreHerbicide = EnvironmentalScoreHerbicide.new(pfModule)
	v5_.scoreObjects.EnvironmentalScoreNitrogen = EnvironmentalScoreNitrogen.new(pfModule)
	v5_.scoreObjects.EnvironmentalScorePH = EnvironmentalScorePH.new(pfModule)
	v5_.scoreObjects.EnvironmentalScoreSoilSample = EnvironmentalScoreSoilSample.new(pfModule)
	v5_.scoreObjects.EnvironmentalScoreTillage = EnvironmentalScoreTillage.new(pfModule)
	v5_.ui = {}
	local v6_ = v5_.ui
	local v7_ = v5_.ui
	local v8_, v9_ = getNormalizedScreenValues(110, 110)
	v6_.fieldInfoWidth = v8_
	v7_.fieldInfoHeight = v9_
	local v10_ = v5_.ui
	local _, v11_ = getNormalizedScreenValues(0, 65)
	v10_.fieldInfoHeightSmall = v11_
	local v12_ = v5_.ui
	local v13_ = v5_.ui
	local v14_, v15_ = getNormalizedScreenValues(92, 11)
	v12_.scoreBarMainWidth = v14_
	v13_.scoreBarMainHeight = v15_
	local v16_ = v5_.ui
	local v17_ = v5_.ui
	local v18_, v19_ = getNormalizedScreenValues(2, 15)
	v16_.scoreBarMainIndicatorWidth = v18_
	v17_.scoreBarMainIndicatorHeight = v19_
	local v20_ = v5_.ui
	local v21_ = v5_.ui
	local v22_, v23_ = getNormalizedScreenValues(70, 5)
	v20_.scoreBarSmallWidth = v22_
	v21_.scoreBarSmallHeight = v23_
	local v24_ = v5_.ui
	local v25_ = v5_.ui
	local v26_, v27_ = getNormalizedScreenValues(40, 40)
	v24_.iconWidth = v26_
	v25_.iconHeight = v27_
	local v28_ = v5_.ui
	local _, v29_ = getNormalizedScreenValues(0, 4)
	v28_.scoreBarOffset = v29_
	local v30_ = v5_.ui
	local _, v31_ = getNormalizedScreenValues(0, 2)
	v30_.topOffset = v31_
	local v32_ = v5_.ui
	local _, v33_ = getNormalizedScreenValues(0, 5)
	v32_.spacingY = v33_
	local v34_ = v5_.ui
	local _, v35_ = getNormalizedScreenValues(0, 12)
	v34_.fieldInfoHeightOffset = v35_
	local v36_ = v5_.ui
	local _, v37_ = getNormalizedScreenValues(0, 30)
	v36_.textSizeHeader = v37_
	local v38_ = v5_.ui
	local _, v39_ = getNormalizedScreenValues(0, 7)
	v38_.textOffsetHeader = v39_
	v5_.ui.iconOverlay = Overlay.new(EnvironmentalScore.GUI_ELEMENTS, 0, 0, v5_.ui.iconWidth, v5_.ui.iconHeight)
	v5_.ui.iconOverlay:setSliceId("precisionFarming.env_score_icon")
	v5_.ui.iconOverlay:setColor(1, 1, 1, 1)
	v5_.ui.gradientOverlay = Overlay.new(EnvironmentalScore.GUI_ELEMENTS, 0, 0, v5_.ui.scoreBarMainWidth, v5_.ui.scoreBarMainHeight)
	v5_.ui.gradientOverlay:setSliceId(v5_.isColorBlindMode and "precisionFarming.gradient_color_blind" or "precisionFarming.gradient_red_green")
	v5_.ui.gradientOverlay:setColor(1, 1, 1, 1)
	v5_.ui.gradientIndicatorOverlay = Overlay.new(EnvironmentalScore.GUI_ELEMENTS, 0, 0, v5_.ui.scoreBarSmallWidth, v5_.ui.scoreBarSmallHeight)
	v5_.ui.gradientIndicatorOverlay:setSliceId("precisionFarming.filled")
	v5_.ui.gradientIndicatorOverlay:setColor(1, 1, 1, 1)
	v5_.ui.smallBarOverlay = Overlay.new(EnvironmentalScore.GUI_ELEMENTS, 0, 0, v5_.ui.scoreBarSmallWidth, v5_.ui.scoreBarSmallHeight)
	v5_.ui.smallBarOverlay:setSliceId("precisionFarming.filled")
	v5_.ui.smallBarOverlay:setColor(1, 1, 1, 1)
	v5_.ui.colorBackground = {
		0.018,
		0.016,
		0.015,
		0.6
	}
	v5_.ui.colorMainUI = {
		0.22323,
		0.40724,
		0.00368,
		1
	}
	v5_.ui.farmlandData = {}
	g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, v5_.onPeriodChanged, v5_)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], v5_.setColorBlindMode, v5_)
	return v5_
end

function EnvironmentalScore:delete()
	self.ui.iconOverlay:delete()
	self.ui.gradientOverlay:delete()
	self.ui.gradientIndicatorOverlay:delete()
	self.ui.smallBarOverlay:delete()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: i, baseKey, scoreValue, className
function EnvironmentalScore:loadFromXML(xmlFile, key, baseDirectory, configFileName, mapFilename)
	self.infoTextPos = g_i18n:getText("environmentalScore_rewardPos", EnvironmentalScore.MOD_NAME)
	self.infoTextNeg = g_i18n:getText("environmentalScore_rewardNeg", EnvironmentalScore.MOD_NAME)
	self.infoTextNone = g_i18n:getText("environmentalScore_rewardNone", EnvironmentalScore.MOD_NAME)
	local v47_ = 0
	while true do
		local v48_ = string.format("%s.scoreValues.scoreValue(%d)", key, v47_)
		if not hasXMLProperty(xmlFile, v48_) then
			break
		end
		local v49_ = {
			["id"] = getXMLString(xmlFile, v48_ .. "#id")
		}
		if v49_.id == nil then
			Logging.warning("Missing scoreValue id in \'%s\'", v48_)
		else
			v49_.id = string.upper(v49_.id)
			v49_.name = g_i18n:convertText(getXMLString(xmlFile, v48_ .. "#name"), EnvironmentalScore.MOD_NAME)
			local v50_ = getXMLString(xmlFile, v48_ .. "#className")
			if v50_ ~= nil and self.scoreObjects[v50_] ~= nil then
				v49_.object = self.scoreObjects[v50_]
				v49_.object:loadFromXML(xmlFile, v48_, baseDirectory, configFileName, mapFilename)
			end
			if v49_.name == nil then
				Logging.warning("Missing scoreValue name in \'%s\'", v48_)
			elseif v49_.object == nil then
				Logging.warning("Missing score object className in \'%s\'", v48_)
			else
				v49_.maxScore = getXMLInt(xmlFile, v48_ .. "#maxScore") or 10
				v49_.curScore = v49_.maxScore * 0.5
				local v51_ = self.scoreValues
				table.insert(v51_, v49_)
			end
		end
		v47_ = v47_ + 1
	end
	return true
end

-- Local values: i, scoreValue
function EnvironmentalScore:loadFromItemsXML(xmlFile, key)
	local v55_ = key .. ".environmentalScore"
	for v56_ = 1, #self.scoreValues do
		local v57_ = self.scoreValues[v56_]
		if v57_.object ~= nil then
			v57_.object:loadFromItemsXML(xmlFile, v55_)
		end
	end
	xmlFile:iterate(v55_ .. ".harvestedStates.harvestedState", function(_, p58_)
		-- upvalues: (copy) xmlFile, (copy) self
		local v59_ = xmlFile:getInt(p58_ .. "#farmlandId")
		local v60_ = xmlFile:getInt(p58_ .. "#state")
		if v59_ ~= nil and v60_ ~= nil then
			self.harvestedStates[v59_] = v60_
		end
	end)
end

-- Local values: i, scoreValue, index, farmlandId, state
function EnvironmentalScore:saveToXMLFile(xmlFile, key, usedModNames)
	local v65_ = key .. ".environmentalScore"
	for v66_ = 1, #self.scoreValues do
		local v67_ = self.scoreValues[v66_]
		if v67_.object ~= nil then
			v67_.object:saveToXMLFile(xmlFile, v65_, usedModNames)
		end
	end
	local v68_ = 0
	for v69_, v70_ in pairs(self.harvestedStates) do
		xmlFile:setInt(string.format("%s.harvestedStates.harvestedState(%d)#farmlandId", v65_, v68_), v69_)
		xmlFile:setInt(string.format("%s.harvestedStates.harvestedState(%d)#state", v65_, v68_), v70_)
		v68_ = v68_ + 1
	end
end

-- Local values: i, scoreValue
function EnvironmentalScore:readStream(streamId, connection, farmId)
	for v75_ = 1, #self.scoreValues do
		local v76_ = self.scoreValues[v75_]
		if v76_.object ~= nil then
			v76_.object:readStream(streamId, connection, farmId)
		end
	end
end

-- Local values: i, scoreValue
function EnvironmentalScore:writeStream(streamId, connection, farmId)
	for v81_ = 1, #self.scoreValues do
		local v82_ = self.scoreValues[v81_]
		if v82_.object ~= nil then
			v82_.object:writeStream(streamId, connection, farmId)
		end
	end
end

-- Local values: x, y, sizeX, sizeY, isHovering, currentSizeY, target, direction, sizeY, keepDirty, farmId, data
function EnvironmentalScore:update(dt)
	if self.mapFrame ~= nil then
		local v85_ = self.mapFrame.envScoreWindow.absPosition[1]
		local v86_ = self.mapFrame.envScoreWindow.absPosition[2]
		local v87_ = self.mapFrame.envScoreWindow.absSize[1]
		local v88_ = self.mapFrame.envScoreWindow.absSize[2]
		local v89_ = self.overwrittenWindowState
		local v90_
		if g_gui:getIsDialogVisible() then
			v90_ = false
		else
			v90_ = g_inputBinding.mousePosXLast ~= nil and (v85_ < g_inputBinding.mousePosXLast and (g_inputBinding.mousePosXLast < v85_ + v87_ and (v86_ < g_inputBinding.mousePosYLast and g_inputBinding.mousePosYLast < v86_ + v88_))) and true or v89_
		end
		local v91_ = self.mapFrame.envScoreWindow.size[2]
		local v92_ = (v90_ and self.envScoreWindowSize * 2.692 or self.envScoreWindowSize) - v91_
		local v93_ = v91_ + math.sign(v92_) * dt / 1000
		local v94_ = self.envScoreWindowSize
		local v95_ = self.envScoreWindowSize * 2.692
		local v96_ = math.clamp(v93_, v94_, v95_)
		self.mapFrame.envScoreWindow:setSize(nil, v96_)
		self.mapFrame.envScoreWindowBackground:setSize(nil, v96_ + self.envScoreWindowBackgroundOffset)
		self.scoreUpdateTimer = self.scoreUpdateTimer + dt
		if self.scoreUpdateTimer > EnvironmentalScore.SCORE_UPDATE_TIME then
			self:updateUI()
			self.scoreUpdateTimer = 0
		end
	end
	if self.farmRevenueIncreaseMessageDirty then
		local v97_ = false
		for v98_, v99_ in pairs(self.farmRevenueIncrease) do
			if v99_.revenue == 0 or g_time - v99_.lastSellTime <= 1000 then
				if v99_.revenue ~= 0 then
					v97_ = true
				end
			else
				v99_.lastSellTime = 0
				g_currentMission:showMoneyChange(v99_.revenue < 0 and self.moneyChangeTypeNeg or self.moneyChangeTypePos, nil, nil, v98_)
				v99_.revenue = 0
			end
		end
		if not v97_ then
			self.farmRevenueIncreaseMessageDirty = false
		end
	end
end

function EnvironmentalScore:toggleWindowSize(state)
	if state == nil then
		state = not self.overwrittenWindowState
	end
	self.overwrittenWindowState = state
end

-- Local values: sliceId
function EnvironmentalScore:setMapFrame(mapFrame)
	self.mapFrame = mapFrame
	self.envScoreWindowSize = self.mapFrame.envScoreWindow.size[2]
	self.envScoreWindowBackgroundOffset = self.mapFrame.envScoreWindowBackground.size[2] - self.mapFrame.envScoreWindow.size[2]
	local v104_ = self.isColorBlindMode and "precisionFarming.gradient_color_blind" or "precisionFarming.gradient_red_green"
	self.mapFrame.envScoreBarDynamic:setImageSlice(nil, v104_)
	self.mapFrame.envScoreBarStatic:setImageSlice(nil, v104_)
	self:updateInputGlyphs()
end

function EnvironmentalScore:onEnvScoreDetailsButton()
	self:toggleWindowSize()
end

function EnvironmentalScore:updateInputGlyphs()
	self.currentInputHelpMode = g_inputBinding:getInputHelpMode()
	self.mapFrame.envScoreInputGlyph:setActions({ InputAction.SWITCH_IMPLEMENT })
	self.mapFrame.envScoreInputBox:setVisible(self.currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD)
	if self.currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		g_inputBinding:registerActionEvent(InputAction.SWITCH_IMPLEMENT, self, self.onEnvScoreDetailsButton, false, true, false, true)
	else
		g_inputBinding:removeActionEventsByTarget(self)
	end
end

-- Local values: farmId
function EnvironmentalScore:onMapFrameOpen(mapFrame)
	if g_server == nil and g_client ~= nil then
		local v108_ = g_currentMission:getFarmId()
		if v108_ ~= FarmManager.SPECTATOR_FARM_ID then
			g_client:getServerConnection():sendEvent(RequestEnvironmentalScoreEvent.new(v108_))
		end
	end
	mapFrame.envScoreWindow:setVisible(g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID)
end

-- Local values: i, scoreValue
function EnvironmentalScore:onHarvestScoreReset(farmlandId)
	for v111_ = 1, #self.scoreValues do
		local v112_ = self.scoreValues[v111_]
		if v112_.object ~= nil and v112_.object.onHarvestScoreReset ~= nil then
			v112_.object:onHarvestScoreReset(farmlandId)
		end
	end
end

-- Local values: sum, i
function EnvironmentalScore:getFarmlandScore(farmlandId)
	local v115_ = 0
	for v116_ = 1, #self.scoreValues do
		v115_ = v115_ + self.scoreValues[v116_].object:getScore(farmlandId) * self.scoreValues[v116_].maxScore
	end
	return v115_
end

-- Local values: sumFarmlandSize, farmlandId, _farmId, farmland, score, numValidInfluences, farmlandId, _farmId, farmland
function EnvironmentalScore:getTotalScoreFromValue(scoreValue, farmId)
	local v119_ = 0
	for v120_, v121_ in pairs(g_farmlandManager.farmlandMapping) do
		if v121_ == farmId then
			local v122_ = g_farmlandManager:getFarmlandById(v120_)
			if v122_ ~= nil and (v122_.totalFieldArea ~= nil and v122_.totalFieldArea > 0.01) then
				v119_ = v119_ + v122_.totalFieldArea
			end
		end
	end
	local v123_ = 0
	local v124_ = 0
	if scoreValue.object ~= nil then
		for v125_, v126_ in pairs(g_farmlandManager.farmlandMapping) do
			if v126_ == farmId then
				local v127_ = g_farmlandManager:getFarmlandById(v125_)
				if v127_ ~= nil and (v127_.totalFieldArea ~= nil and v127_.totalFieldArea > 0.01) then
					v123_ = v123_ + scoreValue.object:getScore(v125_) * scoreValue.maxScore * (v127_.totalFieldArea / v119_)
					v124_ = v124_ + 1
				end
			end
		end
	end
	if v124_ == 0 then
		return scoreValue.maxScore * 0.5
	else
		return v123_
	end
end

-- Local values: sumFarmlandSize, farmlandId, _farmId, farmland, sum, farmlandId, _farmId, farmland, i
function EnvironmentalScore:getTotalScore(farmId)
	local v130_ = 0
	if farmId ~= FarmManager.SPECTATOR_FARM_ID then
		for v131_, v132_ in pairs(g_farmlandManager.farmlandMapping) do
			if v132_ == farmId then
				local v133_ = g_farmlandManager:getFarmlandById(v131_)
				if v133_ ~= nil and (v133_.totalFieldArea ~= nil and v133_.totalFieldArea > 0.01) then
					v130_ = v130_ + v133_.totalFieldArea
				end
			end
		end
		if v130_ > 0 then
			local v134_ = 0
			for v135_, v136_ in pairs(g_farmlandManager.farmlandMapping) do
				if v136_ == farmId then
					local v137_ = g_farmlandManager:getFarmlandById(v135_)
					if v137_ ~= nil and (v137_.totalFieldArea ~= nil and v137_.totalFieldArea > 0.01) then
						for v138_ = 1, #self.scoreValues do
							v134_ = v134_ + self.scoreValues[v138_].object:getScore(v135_) * self.scoreValues[v138_].maxScore * (v137_.totalFieldArea / v130_)
						end
					end
				end
			end
			return v134_
		end
	end
	return 50
end

-- Local values: percentage, factor
function EnvironmentalScore:getSellPriceFactor(farmId)
	local v141_ = (self:getTotalScore(farmId) / 100 - 0.5) / 0.5 * EnvironmentalScore.YIELD_INCREASE
	return math.abs(v141_) < 0.01 and 0 or v141_
end

-- Local values: farmId, totalScore, percentage, uvs, indicatorX, i, scoreValue, score, factor, text
function EnvironmentalScore:updateUI()
	if self.mapFrame ~= nil then
		local v143_ = g_currentMission:getFarmId()
		local v144_ = self:getTotalScore(v143_)
		local v145_ = self:getTotalScore(v143_) / 100
		self.mapFrame.envScoreBarNumber:setText(string.format("%d", MathUtil.round(v144_)))
		self.mapFrame.envScoreBarDynamic:setSize(self.mapFrame.envScoreBarStatic.size[1] * v145_)
		local v146_ = GuiOverlay.getOverlayUVs(self.mapFrame.envScoreBarStatic.overlay, true)
		self.mapFrame.envScoreBarDynamic:setImageUVs(true, v146_[1], v146_[2], v146_[3], v146_[4], (v146_[5] - v146_[1]) * v145_ + v146_[1], v146_[6], (v146_[7] - v146_[3]) * v145_ + v146_[3], v146_[8])
		local v147_ = self.mapFrame.envScoreBarStatic.position[1] + self.mapFrame.envScoreBarStatic.size[1] * v145_
		self.mapFrame.envScoreBarIndicator:setPosition(v147_ - self.mapFrame.envScoreBarIndicator.size[1] * 0.5)
		self.mapFrame.envScoreBarNumber:setPosition(v147_ - self.mapFrame.envScoreBarNumber.size[1] * 0.5)
		for v148_ = 1, #self.scoreValues do
			local v149_ = self.scoreValues[v148_]
			if self.mapFrame.envScoreDistributionText[v148_] ~= nil then
				local v150_ = self:getTotalScoreFromValue(v149_, v143_)
				self.mapFrame.envScoreDistributionText[v148_]:setText(v149_.name)
				self.mapFrame.envScoreDistributionValue[v148_]:setText(string.format("%.1f", MathUtil.round(v150_, 1)))
				self.mapFrame.envScoreDistributionBar[v148_]:setSize(self.mapFrame.envScoreDistributionBarBackground[v148_].size[1] * (v150_ / v149_.maxScore))
			end
		end
		local v151_ = MathUtil.round(self:getSellPriceFactor(v143_) * 100)
		local v152_ = v151_ >= 1 and self.infoTextPos or (v151_ <= -1 and self.infoTextNeg or self.infoTextNone)
		self.mapFrame.envScoreInfoText:setText(string.format(v152_, (math.abs(v151_))))
	end
end

-- Local values: _, hotspot, worldX, worldZ, objectX, objectZ, x, y, _, visible
function EnvironmentalScore:onDraw(element, ingameMap)
	if g_currentMission:getFarmId() ~= FarmManager.SPECTATOR_FARM_ID then
		for _, v156_ in pairs(ingameMap.hotspots) do
			if v156_:isa(FarmlandHotspot) then
				local v157_, v158_ = v156_:getWorldPosition()
				local v159_ = (v157_ + ingameMap.worldCenterOffsetX) / ingameMap.worldSizeX * 0.5 + 0.25
				local v160_ = (v158_ + ingameMap.worldCenterOffsetZ) / ingameMap.worldSizeZ * 0.5 + 0.25
				local v161_, v162_, _, v163_ = ingameMap.layout:getMapObjectPosition(v159_, v160_, v156_:getWidth(), v156_:getHeight(), 0, v156_:getIsPersistent())
				if v163_ then
					self:onDrawFieldNumber(element, ingameMap, v161_ + v156_:getWidth() * 0.5, v162_, v156_:getFarmland())
				end
			end
		end
	end
end

-- Local values: farmlandId
function EnvironmentalScore:onDrawFieldNumber(element, ingameMap, x, y, farmland)
	local v169_ = farmland.id
	if farmland.totalFieldArea ~= nil and (farmland.totalFieldArea > 0.01 and g_farmlandManager.farmlandMapping[v169_] == g_currentMission:getFarmId()) then
		self:drawFarmlandScore(x, y, farmland, v169_, ingameMap.layout:getIconZoom())
	end
end

-- Local values: alpha, scale, farmlandData, windowWidth, windowHeight, windowX, windowY, cursorX, cursorY, isHovering, target, direction, iconOffsetX, iconOffsetY, score, gradientX, gradientY, i, posX, posY
function EnvironmentalScore:drawFarmlandScore(x, y, dataKey, farmlandId, zoom)
	local v176_ = zoom / 1.2 - 0.55
	local v177_ = math.max(v176_, 0) / 0.05
	local v178_ = math.min(v177_, 1)
	if v178_ ~= 0 then
		local v179_ = self.ui.farmlandData[dataKey]
		if v179_ == nil then
			v179_ = {
				["state"] = 0
			}
			self.ui.farmlandData[dataKey] = v179_
		end
		local v180_ = self.ui.fieldInfoWidth * 1
		local v181_ = ((self.ui.fieldInfoHeight - self.ui.fieldInfoHeightSmall) * v179_.state + self.ui.fieldInfoHeightSmall) * 1
		local v182_ = x - v180_ * 0.5
		local v183_ = y - v181_ - self.ui.fieldInfoHeightOffset * 1
		local v184_ = nil
		local v185_ = nil
		if self.currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
			v184_, v185_ = self.mapFrame.mapCursor:getCenter()
		elseif g_inputBinding.mousePosXLast ~= nil then
			v184_ = g_inputBinding.mousePosXLast
			v185_ = g_inputBinding.mousePosYLast
		end
		local v186_ = (v184_ ~= nil and (v182_ < v184_ and (v184_ < v182_ + v180_ and (v185_ ~= nil and (v183_ < v185_ and v185_ < v183_ + v181_)))) and 1 or 0) - v179_.state
		local v187_ = math.sign(v186_)
		local v188_ = v179_.state + v187_ * g_currentDt / 150
		v179_.state = math.clamp(v188_, 0, 1)
		local v189_ = ((self.ui.fieldInfoHeight - self.ui.fieldInfoHeightSmall) * v179_.state + self.ui.fieldInfoHeightSmall) * 1
		local v190_ = y - v189_ - self.ui.fieldInfoHeightOffset * 1
		drawFilledRect(v182_, v190_, v180_, v189_, self.ui.colorBackground[1], self.ui.colorBackground[2], self.ui.colorBackground[3], self.ui.colorBackground[4] * v178_)
		local v191_ = v180_ * 0.3 - self.ui.iconWidth * 1 * 0.5
		local v192_ = v189_ - self.ui.topOffset * 1 - self.ui.iconHeight * 1
		self.ui.iconOverlay:setDimension(self.ui.iconWidth * 1, self.ui.iconHeight * 1)
		self.ui.iconOverlay:setColor(self.ui.colorMainUI[1], self.ui.colorMainUI[2], self.ui.colorMainUI[3], self.ui.colorMainUI[4] * v178_)
		self.ui.iconOverlay:setPosition(v182_ + v191_, v190_ + v192_)
		self.ui.iconOverlay:render()
		setTextColor(1, 1, 1, v178_)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		local v193_ = self:getFarmlandScore(farmlandId)
		renderText(v182_ + v180_ - v191_ - self.ui.iconOverlay.width * 0.5, v190_ + v192_ + self.ui.textOffsetHeader * 1, self.ui.textSizeHeader * 1, string.format("%d", v193_))
		local v194_ = v182_ + v180_ * 0.5 - self.ui.gradientOverlay.width * 0.5
		local v195_ = v190_ + v189_ - self.ui.topOffset * 1 - self.ui.iconOverlay.height - self.ui.spacingY * 1 - self.ui.gradientOverlay.height
		self.ui.gradientOverlay:setDimension(self.ui.scoreBarMainWidth * 1, self.ui.scoreBarMainHeight * 1)
		self.ui.gradientOverlay:setColor(1, 1, 1, v178_)
		self.ui.gradientOverlay:setPosition(v194_, v195_)
		self.ui.gradientOverlay:render()
		self.ui.gradientIndicatorOverlay:setDimension(self.ui.scoreBarMainIndicatorWidth * 1, self.ui.scoreBarMainIndicatorHeight * 1)
		self.ui.gradientIndicatorOverlay:setColor(1, 1, 1, v178_)
		self.ui.gradientIndicatorOverlay:setPosition(v194_ - self.ui.scoreBarMainIndicatorWidth * 1 * 0.5 + self.ui.gradientOverlay.width * (v193_ / 100), v195_ - (self.ui.scoreBarMainIndicatorHeight - self.ui.scoreBarMainHeight) * 0.5 * 1)
		self.ui.gradientIndicatorOverlay:render()
		if v179_.state == 1 then
			for v196_ = 1, #self.scoreValues do
				local v197_ = v182_ + v180_ * 0.5 - self.ui.scoreBarSmallWidth * 1 * 0.5
				local v198_ = v190_ + self.ui.spacingY * 1 + (self.ui.scoreBarSmallHeight * 1 + self.ui.scoreBarOffset * 1) * (#self.scoreValues - v196_)
				self.ui.smallBarOverlay:setPosition(v197_, v198_)
				self.ui.smallBarOverlay:setDimension(self.ui.scoreBarSmallWidth * 1, self.ui.scoreBarSmallHeight * 1)
				self.ui.smallBarOverlay:setColor(self.ui.colorBackground[1], self.ui.colorBackground[2], self.ui.colorBackground[3], self.ui.colorBackground[4] * v178_)
				self.ui.smallBarOverlay:render()
				self.ui.smallBarOverlay:setPosition(v197_, v198_)
				self.ui.smallBarOverlay:setDimension(self.ui.scoreBarSmallWidth * self.scoreValues[v196_].object:getScore(farmlandId) * 1, self.ui.scoreBarSmallHeight * 1)
				self.ui.smallBarOverlay:setColor(self.ui.colorMainUI[1], self.ui.colorMainUI[2], self.ui.colorMainUI[3], self.ui.colorMainUI[4] * v178_)
				self.ui.smallBarOverlay:render()
			end
		end
	end
end

-- Local values: farmlandId, state
function EnvironmentalScore:onPeriodChanged(currentPeriod)
	for v200_, v201_ in pairs(self.harvestedStates) do
		if v201_ == 2 then
			self.harvestedStates[v200_] = 0
			self:onHarvestScoreReset(v200_)
		end
		if v201_ == 1 then
			self.harvestedStates[v200_] = 2
		end
	end
end

-- Local values: sliceId
function EnvironmentalScore:setColorBlindMode()
	self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE)
	local v203_ = self.isColorBlindMode and "precisionFarming.gradient_color_blind" or "precisionFarming.gradient_red_green"
	self.ui.gradientOverlay:setSliceId(v203_)
	if self.mapFrame ~= nil then
		self.mapFrame.envScoreBarDynamic:setImageSlice(nil, v203_)
		self.mapFrame.envScoreBarStatic:setImageSlice(nil, v203_)
	end
	self:updateUI()
end

-- Local values: _, object
function EnvironmentalScore:overwriteGameFunctions(pfModule)
	for _, v206_ in pairs(self.scoreObjects) do
		v206_:overwriteGameFunctions(pfModule)
	end
	pfModule:overwriteGameFunction(CoverMap, "preUpdateCoverArea", function(p207_, p208_, p209_, p210_, p211_, p212_)
		-- upvalues: (copy) self
		local v213_, v214_ = p207_(p208_, p209_, p210_, p211_, p212_)
		local v215_, v216_ = p210_:getCenter()
		local v217_ = g_farmlandManager:getFarmlandIdAtWorldPosition(v215_, v216_)
		if v217_ ~= nil then
			self.harvestedStates[v217_] = 1
		end
		return v213_, v214_
	end)
	pfModule:overwriteGameFunction(SellingStation, "sellFillType", function(p218_, p219_, p220_, p221_, p222_, p223_, p224_)
		-- upvalues: (copy) self
		local v225_ = p218_(p219_, p220_, p221_, p222_, p223_, p224_)
		local v226_ = v225_ * self:getSellPriceFactor(p220_)
		if v226_ ~= 0 then
			if self.farmRevenueIncrease[p220_] == nil then
				self.farmRevenueIncrease[p220_] = {
					["revenue"] = 0,
					["lastSellTime"] = g_time
				}
			end
			self.farmRevenueIncrease[p220_].revenue = self.farmRevenueIncrease[p220_].revenue + v226_
			self.farmRevenueIncrease[p220_].lastSellTime = g_time
			g_currentMission:addMoney(v226_, p220_, v226_ < 0 and self.moneyChangeTypeNeg or self.moneyChangeTypePos, true)
			self.farmRevenueIncreaseMessageDirty = true
		end
		return v225_
	end)
end
