-- Local values: InGameMenuMapFrameExtension_mt
InGameMenuMapFrameExtension = {}
InGameMenuMapFrameExtension.MOD_NAME = g_currentModName
InGameMenuMapFrameExtension.MOD_DIR = g_currentModDirectory
local InGameMenuMapFrameExtension_mt = Class(InGameMenuMapFrameExtension)

-- Upvalues: InGameMenuMapFrameExtension_mt
-- Local values: self
function InGameMenuMapFrameExtension.new(precisionFarming, customMt)
	-- upvalues: (copy) InGameMenuMapFrameExtension_mt
	local v4_ = customMt or InGameMenuMapFrameExtension_mt
	local v5_ = setmetatable({}, v4_)
	v5_.precisionFarming = precisionFarming
	v5_.valueMapToSelectorIndex = {}
	v5_.selectorIndexToValueMap = {}
	v5_.displayPrecisionFarmingData = {}
	v5_.activeValueMapIndex = 1
	v5_.overlayUpdateTimer = 0
	v5_.overlayUpdateInterval = 1000
	return v5_
end

function InGameMenuMapFrameExtension:initialize(pfModule)
	self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE)
	g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.setColorBlindMode, self)
end

function InGameMenuMapFrameExtension:unloadMapData()
	g_messageCenter:unsubscribeAll(self)
end

-- Local values: i
function InGameMenuMapFrameExtension:delete()
	if self.soilStateOverlay ~= nil then
		delete(self.soilStateOverlay)
	end
	if self.coverStateOverlays ~= nil then
		for v9_ = 1, #self.coverStateOverlays do
			delete(self.coverStateOverlays[v9_].overlay)
		end
	end
end

function InGameMenuMapFrameExtension:update(dt) end

-- Local values: valueMaps, valueMap, displayValues, valueFilter, valueFilterEnabled, numSelectedFilters, i
function InGameMenuMapFrameExtension:onPrecisionFarmingSelectorChanged(state)
	self.activeValueMapIndex = state
	local v12_ = self.precisionFarming:getValueMaps()[state]
	local v13_ = v12_:getDisplayValues()
	local v14_, v15_ = v12_:getValueFilter()
	self.inGameMenuMapFrame.dataTables[self.inGameMenuMapFrame.precisionFarmingPageIndex] = v13_
	self.inGameMenuMapFrame.filterStates[self.inGameMenuMapFrame.precisionFarmingPageIndex] = v14_
	self.valueFilterEnabled = v15_
	local v16_ = 0
	for v17_ = 1, #v14_ do
		if v14_[v17_] then
			v16_ = v16_ + 1
		end
	end
	self.inGameMenuMapFrame.numSelectedFilters[self.inGameMenuMapFrame.precisionFarmingPageIndex] = v16_
	if v16_ == 0 then
		self.inGameMenuMapFrame.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.SELECT_ALL))
	else
		self.inGameMenuMapFrame.buttonDeselectAllText:setText(g_i18n:getText(InGameMenuMapFrame.L10N_SYMBOL.DESELECT_ALL))
	end
	self.inGameMenuMapFrame.filterList:reloadData()
	self:updateSoilStateMapOverlay()
end

function InGameMenuMapFrameExtension:updatePrecisionFarmingOverlays()
	self:updateSoilStateMapOverlay()
end

-- Local values: valueMaps, valueMap, valueFilter, _, coverMap, i, coverStateOverlay
function InGameMenuMapFrameExtension:updateSoilStateMapOverlay()
	if self.soilStateOverlay ~= nil then
		local v20_ = self.precisionFarming:getValueMaps()[self.activeValueMapIndex]
		if v20_ ~= nil then
			local v21_, _ = v20_:getValueFilter()
			v20_:buildOverlay(self.soilStateOverlay, v21_, self.isColorBlindMode)
			generateDensityMapVisualizationOverlay(self.soilStateOverlay)
			self.soilStateOverlayReady = false
		end
		local v22_ = self.precisionFarming.coverMap
		if v22_ ~= nil then
			for v23_ = 1, #self.coverStateOverlays do
				local v24_ = self.coverStateOverlays[v23_]
				v22_:buildCoverStateOverlay(v24_.overlay, v23_)
				generateDensityMapVisualizationOverlay(v24_.overlay)
				v24_.overlayReady = false
			end
		end
	end
end

-- Local values: coverMap, i, coverStateOverlay, i
function InGameMenuMapFrameExtension:onLoadMapFinished()
	self.soilStateOverlay = createDensityMapVisualizationOverlay("soilState", 1024, 1024)
	self.soilStateOverlayReady = false
	local v26_ = self.precisionFarming.coverMap
	if v26_ ~= nil then
		self.coverStateOverlays = {}
		for v27_ = 1, v26_:getNumCoverOverlays() do
			local v28_ = {
				["overlay"] = createDensityMapVisualizationOverlay("coverState" .. v27_, 1024, 1024),
				["overlayReady"] = false
			}
			local v29_ = self.coverStateOverlays
			table.insert(v29_, v28_)
		end
	end
	self.precisionFarming:registerVisualizationOverlay(self.soilStateOverlay)
	for v30_ = 1, #self.coverStateOverlays do
		self.precisionFarming:registerVisualizationOverlay(self.coverStateOverlays[v30_].overlay)
	end
end

-- Local values: allowCoverage, valueMaps, valueMap, coverMap, i, coverStateOverlay
function InGameMenuMapFrameExtension:onDrawStateOverlays(x, y, width, height)
	if not self.soilStateOverlayReady and getIsDensityMapVisualizationOverlayReady(self.soilStateOverlay) then
		self.soilStateOverlayReady = true
	end
	if self.soilStateOverlay ~= 0 and self.soilStateOverlayReady then
		setOverlayUVs(self.soilStateOverlay, 0, 0, 0, 1, 1, 0, 1, 1)
		renderOverlay(self.soilStateOverlay, x, y, width, height)
	end
	local v36_ = self.precisionFarming:getValueMaps()[self.activeValueMapIndex]
	local v37_
	if v36_ == nil then
		v37_ = false
	else
		v37_ = v36_:getAllowCoverage()
	end
	if v37_ and self.precisionFarming.coverMap ~= nil then
		for v38_ = 1, #self.coverStateOverlays do
			local v39_ = self.coverStateOverlays[v38_]
			if not v39_.overlayReady and getIsDensityMapVisualizationOverlayReady(v39_.overlay) then
				v39_.overlayReady = true
			end
			if v39_.overlay ~= 0 then
				setOverlayUVs(v39_.overlay, 0, 0, 0, 1, 1, 0, 1, 1)
				renderOverlay(v39_.overlay, x, y, width, height)
			end
		end
	end
end

function InGameMenuMapFrameExtension:setColorBlindMode()
	self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE)
end

function InGameMenuMapFrameExtension:overwriteGameFunctions(pfModule)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "onLoadMapFinished", function(p43_, p_u_44_)
		-- upvalues: (copy) pfModule, (copy) self
		p43_(p_u_44_)
		pfModule.inGameMenuMapFrameExtension.inGameMenuMapFrame = p_u_44_
		function p_u_44_.mapOverviewSelector.onClickCallback(_, p45_)
			-- upvalues: (copy) p_u_44_
			p_u_44_:onClickMapOverviewSelector(p45_)
		end
		function p_u_44_.onClickButtonResetStats()
			-- upvalues: (ref) self
			if self.precisionFarming.farmlandStatistics ~= nil then
				self.precisionFarming.farmlandStatistics:onClickButtonResetStats()
			end
		end
		function p_u_44_.onClickButtonSwitchValues()
			-- upvalues: (ref) self
			if self.precisionFarming.farmlandStatistics ~= nil then
				self.precisionFarming.farmlandStatistics:onClickButtonSwitchValues()
			end
		end
		local v46_ = {}
		self.precisionFarming:collectFarmlandHotspotActions(v46_)
		self.precisionFarmingHotspotActionIndices = {}
		for _, v_u_47_ in ipairs(v46_) do
			local v48_ = p_u_44_.contextActions
			local v49_ = {
				["title"] = v_u_47_.title,
				["callback"] = function()
					-- upvalues: (copy) p_u_44_, (copy) v_u_47_
					if p_u_44_.selectedFarmland ~= nil then
						v_u_47_.callback(v_u_47_.callbackTarget, p_u_44_.selectedFarmland.id)
					end
					return true
				end,
				["isActive"] = false
			}
			table.insert(v48_, v49_)
			local v50_ = self.precisionFarmingHotspotActionIndices
			local v51_ = #p_u_44_.contextActions
			table.insert(v50_, v51_)
		end
		self:onLoadMapFinished()
		self.precisionFarmingEnvScoreContainer = PrecisionFarmingGUI.loadAdditionalGUI("gui/MapFrameExtensionEnvironmentalScore.xml", p_u_44_, p_u_44_.elements[1])
		self.precisionFarmingFieldBuyContainer = PrecisionFarmingGUI.loadAdditionalGUI("gui/MapFrameExtensionFieldBuyInfo.xml", p_u_44_, p_u_44_.contextBoxFarmland)
		self.precisionFarmingLaboratoryContainer = PrecisionFarmingGUI.loadAdditionalGUI("gui/MapFrameExtensionLaboratory.xml", p_u_44_, p_u_44_.elements[1])
		p_u_44_.deadzoneElements = {}
		local v52_ = p_u_44_.deadzoneElements
		local v53_ = p_u_44_.fieldBuyInfoWindow
		table.insert(v52_, v53_)
		local v54_ = p_u_44_.deadzoneElements
		local v55_ = p_u_44_.laboratoryWindow
		table.insert(v54_, v55_)
		local v56_ = p_u_44_.deadzoneElements
		local v57_ = p_u_44_.envScoreWindow
		table.insert(v56_, v57_)
		p_u_44_.precisionFarmingOnlyElements = {}
		local v58_ = p_u_44_.precisionFarmingOnlyElements
		local v59_ = p_u_44_.laboratoryWindow
		table.insert(v58_, v59_)
		local v60_ = p_u_44_.precisionFarmingOnlyElements
		local v61_ = p_u_44_.envScoreWindow
		table.insert(v60_, v61_)
		pfModule:setMapFrame(p_u_44_)
	end)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "setupMapOverview", function(p62_, p_u_63_)
		-- upvalues: (copy) self
		p62_(p_u_63_)
		local v64_ = p_u_63_.mapSelectorTexts
		local v65_ = g_i18n
		table.insert(v64_, v65_:getText("ui_header"))
		p_u_63_.precisionFarmingPageIndex = #p_u_63_.mapSelectorTexts
		p_u_63_.mapOverviewSelector:setTexts(p_u_63_.mapSelectorTexts)
		p_u_63_.dataTables[p_u_63_.precisionFarmingPageIndex] = {}
		p_u_63_.filterStates[p_u_63_.precisionFarmingPageIndex] = {}
		p_u_63_.numSelectedFilters[p_u_63_.precisionFarmingPageIndex] = 0
		p_u_63_.subCategoryDotBox:addElement(p_u_63_.subCategoryDotBox.elements[1]:clone(p_u_63_.subCategoryDotBox))
		p_u_63_.subCategoryDotBox:invalidateLayout()
		for v_u_66_, v67_ in pairs(p_u_63_.subCategoryDotBox.elements) do
			function v67_.getIsSelected()
				-- upvalues: (copy) p_u_63_, (copy) v_u_66_
				return p_u_63_.mapOverviewSelector:getState() == v_u_66_
			end
		end
		self.precisionFarmingSelector = p_u_63_.mapOverviewSelector:clone(p_u_63_.filterBox)
		self.precisionFarmingSelectorTexts = {}
		local v68_ = self.precisionFarming:getValueMaps()
		for v69_ = 1, #v68_ do
			local v70_ = v68_[v69_]
			if v70_:getShowInMenu() then
				local v71_ = self.precisionFarmingSelectorTexts
				table.insert(v71_, v70_:getOverviewLabel())
			end
		end
		self.precisionFarmingSelector:setTexts(self.precisionFarmingSelectorTexts)
		local _, v72_ = getNormalizedScreenValues(0, 80)
		self.precisionFarmingSelector:setPosition(nil, self.precisionFarmingSelector.position[2] - v72_)
		function self.precisionFarmingSelector.onClickCallback(_, p73_)
			-- upvalues: (ref) self
			self:onPrecisionFarmingSelectorChanged(p73_)
		end
		self.precisionFarmingSelector.defaultProfileText = "pf_subCategorySelectorTextSmall"
		self.precisionFarmingSelector:addDefaultElements()
		self.precisionFarmingSelector.textElement:applyProfile("pf_subCategorySelectorTextSmall")
		self.precisionFarmingDotBox = p_u_63_.subCategoryDotBox:clone(p_u_63_.filterBox)
		local _, v74_ = getNormalizedScreenValues(0, 75)
		self.precisionFarmingDotBox:setPosition(nil, self.precisionFarmingDotBox.position[2] - v74_)
		local v75_ = #self.precisionFarmingSelectorTexts
		local v76_ = #self.precisionFarmingDotBox.elements
		if v76_ < v75_ then
			for _ = 1, v75_ - v76_ do
				self.precisionFarmingDotBox:addElement(self.precisionFarmingDotBox.elements[1]:clone(self.precisionFarmingDotBox))
			end
		elseif v75_ < v76_ then
			for _ = 1, v76_ - v75_ do
				self.precisionFarmingDotBox.elements[#self.precisionFarmingDotBox.elements]:delete()
			end
		end
		for v_u_77_, v78_ in pairs(self.precisionFarmingDotBox.elements) do
			function v78_.getIsSelected()
				-- upvalues: (ref) self, (copy) v_u_77_
				return self.precisionFarmingSelector:getState() == v_u_77_
			end
		end
		self.precisionFarmingDotBox:invalidateLayout()
		self.helpButtonContainer = p_u_63_.buttonDeselectAllContainer:clone(p_u_63_.filterListContainer)
		p_u_63_.filterListContainer:addElement(self.helpButtonContainer)
		local _, v79_ = getNormalizedScreenValues(0, 16)
		self.buttonPositionDeselectAllDefault = p_u_63_.buttonDeselectAllContainer.position[2]
		self.buttonPositionDeselectAll = p_u_63_.buttonDeselectAllContainer.position[2] + v79_
		self.helpButtonContainer:setPosition(nil, p_u_63_.buttonDeselectAllContainer.position[2] - v79_)
		self.helpButtonContainer.elements[2]:setText(g_i18n:getText("ui_help"))
		self.helpButtonContainer.elements[3]:setInputAction("MENU_EXTRA_1")
		self.helpButtonContainer.elements[3].onClickCallback = function()
			-- upvalues: (ref) self
			local v80_ = self.precisionFarming:getValueMaps()[self.activeValueMapIndex]
			if v80_ == nil then
				self.precisionFarming.helplineExtension:openHelpMenu(0)
			else
				self.precisionFarming.helplineExtension:openHelpMenu(v80_:getHelpLinePage())
			end
		end
		self.filterListContainerPositionY = p_u_63_.filterListContainer.position[2]
		self.filterListContainerSizeY = p_u_63_.filterListContainer.size[2]
		self.filterListSizeY = p_u_63_.filterList.size[2]
		self.filterListSliderSizeY = p_u_63_.filterListSlider.size[2]
		self.filterListSliderElementSizeY = p_u_63_.filterListSlider.elements[1].size[2]
		p_u_63_.ingameMap.onDrawPostIngameMapCallback = InGameMenuMapFrame.onDrawPostIngameMap
		p_u_63_.ingameMap.onDrawPostIngameMapHotspotsCallback = InGameMenuMapFrame.onDrawPostIngameMapHotspots
		p_u_63_.ingameMap.onClickMapCallback = InGameMenuMapFrame.onClickMap
		p_u_63_.filterList:reloadData()
	end)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "onClickMapOverviewSelector", function(p81_, p82_, p83_)
		-- upvalues: (copy) self, (copy) pfModule
		p81_(p82_, p83_)
		if p83_ == p82_.precisionFarmingPageIndex then
			self.precisionFarmingSelector:setVisible(true)
			self.precisionFarmingDotBox:setVisible(true)
			self.helpButtonContainer:setVisible(true)
			p82_.filterListContainer:setVisible(true)
			p82_.buttonDeselectAllContainer:setVisible(true)
			local _, v84_ = getNormalizedScreenValues(0, 60)
			p82_.filterListContainer:setPosition(nil, self.filterListContainerPositionY - v84_)
			p82_.filterListContainer:setSize(nil, self.filterListContainerSizeY - v84_, true)
			p82_.filterList:setSize(nil, self.filterListSizeY - v84_, true)
			p82_.filterListSlider:setSize(nil, self.filterListSliderSizeY - v84_, true)
			p82_.filterListSlider.elements[1]:setSize(nil, self.filterListSliderElementSizeY - v84_, true)
			p82_.buttonDeselectAllContainer:setPosition(nil, self.buttonPositionDeselectAll)
			self:onPrecisionFarmingSelectorChanged(self.precisionFarmingSelector:getState())
			pfModule:onMapFrameOpen(p82_)
		else
			self.precisionFarmingSelector:setVisible(false)
			self.precisionFarmingDotBox:setVisible(false)
			self.helpButtonContainer:setVisible(false)
			p82_.filterListContainer:setPosition(nil, self.filterListContainerPositionY)
			p82_.filterListContainer:setSize(nil, self.filterListContainerSizeY, true)
			p82_.filterList:setSize(nil, self.filterListSizeY, true)
			p82_.filterListSlider:setSize(nil, self.filterListSliderSizeY, true)
			p82_.filterListSlider.elements[1]:setSize(nil, self.filterListSliderElementSizeY, true)
			p82_.buttonDeselectAllContainer:setPosition(nil, self.buttonPositionDeselectAllDefault)
		end
		if p82_.precisionFarmingOnlyElements ~= nil then
			for _, v85_ in ipairs(p82_.precisionFarmingOnlyElements) do
				v85_:setVisible(p83_ == p82_.precisionFarmingPageIndex)
			end
		end
	end)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "populateCellForItemInSection", function(p86_, p87_, p88_, p89_, p90_, p91_)
		-- upvalues: (copy) self
		p86_(p87_, p88_, p89_, p90_, p91_)
		if p88_ == p87_.contextButtonList or p88_ ~= p87_.contextButtonListFarmland then
			return
		elseif p87_.mapOverviewSelector:getState() == p87_.precisionFarmingPageIndex then
			if self.valueFilterEnabled == nil then
				p91_.allowSelected = true
			else
				p91_.allowSelected = self.valueFilterEnabled[p90_]
			end
		else
			p91_.allowSelected = true
			return
		end
	end)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "getHasChangeableFilterList", function(p92_, p93_, ...)
		return p92_(p93_, ...) or p93_.mapOverviewSelector:getState() == p93_.precisionFarmingPageIndex
	end)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "updateInputGlyphs", function(p94_, p95_, ...)
		-- upvalues: (copy) self
		p94_(p95_, ...)
		if self.precisionFarming.environmentalScore ~= nil then
			self.precisionFarming.environmentalScore:updateInputGlyphs()
		end
	end)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "onDrawPostIngameMap", function(p96_, p97_, p98_, p99_, ...)
		-- upvalues: (copy) self
		if p97_.mapOverviewSelector:getState() == p97_.precisionFarmingPageIndex then
			local v100_ = p97_.hideContentOverlay
			p97_.hideContentOverlay = true
			p96_(p97_, p98_, p99_, ...)
			p97_.hideContentOverlay = v100_
			local v101_, v102_ = p97_.ingameMapBase.fullScreenLayout:getMapSize()
			local v103_, v104_ = p97_.ingameMapBase.fullScreenLayout:getMapPosition()
			self:onDrawStateOverlays(v103_ + v101_ * 0.25, v104_ + v102_ * 0.25, v101_ * 0.5, v102_ * 0.5)
			if self.activeValueMapIndex == 1 and self.precisionFarming.environmentalScore ~= nil then
				self.precisionFarming.environmentalScore:onDraw(p98_, p99_)
				return
			end
		else
			p96_(p97_, p98_, p99_, ...)
		end
	end)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "onClickSwitchMapMode", function(p105_, p106_)
		-- upvalues: (copy) pfModule
		if pfModule.additionalFieldBuyInfo ~= nil then
			pfModule.additionalFieldBuyInfo:onFarmlandSelectionChanged()
			p106_:resetUIDeadzones()
		end
		p105_(p106_)
	end)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "onFrameClose", function(p107_, p108_)
		-- upvalues: (copy) pfModule
		p107_(p108_)
		if pfModule.additionalFieldBuyInfo ~= nil then
			pfModule.additionalFieldBuyInfo:onFarmlandSelectionChanged()
			p108_:resetUIDeadzones()
		end
	end)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "update", function(p109_, p110_, p111_)
		-- upvalues: (copy) self
		p109_(p110_, p111_)
		if p110_.mapOverviewSelector:getState() == p110_.precisionFarmingPageIndex then
			self.overlayUpdateTimer = self.overlayUpdateTimer + p111_
			if self.overlayUpdateTimer > self.overlayUpdateInterval then
				self:updateSoilStateMapOverlay()
				self.overlayUpdateTimer = 0
			end
		end
	end)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "generateOverviewOverlay", function(p112_, p113_, ...)
		-- upvalues: (copy) self
		p112_(p113_, ...)
		self:updateSoilStateMapOverlay()
	end)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "setMapSelectionItem", function(p114_, p_u_115_, p_u_116_, ...)
		-- upvalues: (copy) self, (copy) pfModule
		local v117_ = p_u_115_.selectedFarmland
		p114_(p_u_115_, p_u_116_, ...)
		function p_u_115_.updatePrecisionFarmingContextActions(p118_)
			-- upvalues: (ref) self, (copy) p_u_115_, (copy) p_u_116_
			local v119_ = false
			if self.precisionFarmingHotspotActionIndices ~= nil and (p_u_115_.mapOverviewSelector:getState() == p_u_115_.precisionFarmingPageIndex and (p_u_116_ ~= nil and p_u_116_:isa(FarmlandHotspot))) then
				local v120_ = p_u_116_:getFarmland()
				v119_ = g_farmlandManager:getFarmlandOwner(v120_.id) == g_currentMission:getFarmId() and v120_.totalFieldArea ~= nil and true or v119_
			end
			if v119_ then
				for _, v121_ in pairs(p_u_115_.contextActions) do
					v121_.isActive = false
				end
			end
			if self.precisionFarmingHotspotActionIndices ~= nil then
				for _, v122_ in ipairs(self.precisionFarmingHotspotActionIndices) do
					p_u_115_.contextActions[v122_].isActive = v119_
				end
			end
			if p118_ then
				p_u_115_.contextButtonList:reloadData()
			end
		end
		p_u_115_.updatePrecisionFarmingContextActions()
		if p_u_115_.selectedFarmland ~= v117_ and pfModule.additionalFieldBuyInfo ~= nil then
			pfModule.additionalFieldBuyInfo:onFarmlandSelectionChanged(p_u_115_.selectedFarmland)
			p_u_115_:resetUIDeadzones()
		end
	end)
	pfModule:overwriteGameFunction(InGameMenuMapUtil, "showContextBox", function(p123_, p124_, p125_, p126_, p127_, p128_, p129_, p130_, p131_, p132_, p133_, ...)
		-- upvalues: (copy) pfModule
		p123_(p124_, p125_, p126_, p127_, p128_, p129_, p130_, p131_, p132_, p133_, ...)
		local v134_
		if p124_ == nil or not p133_ then
			v134_ = nil
		else
			v134_ = p125_:getFarmland()
		end
		if v134_ == nil then
			if pfModule.additionalFieldBuyInfo ~= nil then
				pfModule.additionalFieldBuyInfo:onShowContextBox(nil, nil)
			end
		elseif pfModule.additionalFieldBuyInfo ~= nil then
			pfModule.additionalFieldBuyInfo:onShowContextBox(v134_, p124_)
			return
		end
	end)
	pfModule:overwriteGameFunction(InGameMenuMapFrame, "resetUIDeadzones", function(p135_, p136_)
		p135_(p136_)
		if p136_.deadzoneElements ~= nil then
			for _, v137_ in ipairs(p136_.deadzoneElements) do
				if v137_:getIsVisible() then
					p136_.ingameMap:addCursorDeadzone(v137_.absPosition[1], v137_.absPosition[2], v137_.size[1], v137_.size[2])
				end
			end
		end
	end)
	pfModule:overwriteGameFunction(MapOverlayGenerator, "getDisplaySoilStates", function(p138_, p139_)
		local v140_ = p138_(p139_)
		v140_[MapOverlayGenerator.SOIL_STATE_INDEX.FERTILIZED] = nil
		v140_[MapOverlayGenerator.SOIL_STATE_INDEX.NEEDS_LIME] = nil
		return v140_
	end)
end
