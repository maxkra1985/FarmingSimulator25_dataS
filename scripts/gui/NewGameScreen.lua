-- Local values: NewGameScreen_mt
NewGameScreen = {}
local NewGameScreen_mt = Class(NewGameScreen, ScreenElement)
function NewGameScreen.register()
	local v2_ = NewGameScreen.new()
	g_gui:loadGui("dataS/gui/NewGameScreen.xml", "NewGameScreen", v2_)
	return v2_
end

-- Upvalues: NewGameScreen_mt
-- Local values: self, _, capital, _, capital
function NewGameScreen.new(target, custom_mt)
	-- upvalues: (copy) NewGameScreen_mt
	local v5_ = ScreenElement.new(target, custom_mt or NewGameScreen_mt)
	v5_.maps = {}
	v5_.initialMoney = {
		100000,
		250000,
		500000,
		750000,
		1000000
	}
	if g_isDevelopmentVersion then
		local v6_ = v5_.initialMoney
		table.insert(v6_, 100000000)
	end
	v5_.initialMoneyTexts = {}
	for _, v7_ in ipairs(v5_.initialMoney) do
		local v8_ = v5_.initialMoneyTexts
		local v9_ = g_i18n
		table.insert(v8_, v9_:formatMoney(v7_, 0, true, true))
	end
	v5_.initialLoan = {
		0,
		100000,
		250000,
		500000,
		750000,
		1000000
	}
	v5_.initialLoanTexts = {}
	for _, v10_ in ipairs(v5_.initialLoan) do
		local v11_ = v5_.initialLoanTexts
		local v12_ = g_i18n
		table.insert(v11_, v12_:formatMoney(v10_, 0, true, true))
	end
	v5_.economicDifficultyTexts = { g_i18n:getText("button_easy"), g_i18n:getText("button_normal"), g_i18n:getText("button_hard") }
	v5_.presetNames = { g_i18n:getText("ui_difficulty1"), g_i18n:getText("ui_difficulty2"), g_i18n:getText("ui_difficulty3") }
	v5_.presets = {}
	v5_.presets[1] = {
		["initialMoneyIndex"] = 1,
		["initialLoanIndex"] = 1,
		["startWithFarm"] = true,
		["startWithGuidedTour"] = not g_isDevelopmentVersion,
		["economicDifficulty"] = EconomicDifficulty.EASY
	}
	v5_.presets[2] = {
		["initialMoneyIndex"] = 5,
		["initialLoanIndex"] = 1,
		["startWithFarm"] = false,
		["startWithGuidedTour"] = false,
		["economicDifficulty"] = EconomicDifficulty.NORMAL
	}
	v5_.presets[3] = {
		["initialMoneyIndex"] = 3,
		["initialLoanIndex"] = 3,
		["startWithFarm"] = false,
		["startWithGuidedTour"] = false,
		["economicDifficulty"] = EconomicDifficulty.HARD
	}
	return v5_
end

-- Local values: newGui
function NewGameScreen.createFromExistingGui(gui, guiName)
	local v15_ = NewGameScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v15_)
	return v15_
end

function NewGameScreen:onGuiSetupFinished()
	NewGameScreen:superClass().onGuiSetupFinished(self)
	self.presetSelector:setTexts(self.presetNames)
	self.initialMoneySelector:setTexts(self.initialMoneyTexts)
	self.initialLoanSelector:setTexts(self.initialLoanTexts)
	self.economicDifficultySelector:setTexts(self.economicDifficultyTexts)
	self.mapDotTemplate:unlinkElement()
	FocusManager:removeElement(self.mapDotTemplate)
	FocusManager:linkElements(self.mapSelector, FocusManager.BOTTOM, self.presetSelector)
	FocusManager:linkElements(self.presetSelector, FocusManager.TOP, self.mapSelector)
	self.startWithFarmSelector:setTexts({ g_i18n:getText("button_no"), g_i18n:getText("button_yes") })
	self.startWithGuidedTourSelector:setTexts({ g_i18n:getText("button_no"), g_i18n:getText("button_yes") })
	self:onClickPreset(1)
end

-- Local values: currentSelection, texts, i, map, i, i, dot
function NewGameScreen:onOpen()
	NewGameScreen:superClass().onOpen(self)
	self.maps = {}
	local v18_ = {}
	local v19_ = nil
	for v20_ = 1, g_mapManager:getNumOfMaps() do
		local v21_ = g_mapManager:getMapDataByIndex(v20_)
		if (not v21_.isModMap or g_dedicatedServer == nil and not g_startMissionInfo.isMultiplayer or v21_.isMultiplayerSupported) and v21_.isSelectable then
			local v22_ = self.maps
			table.insert(v22_, v21_)
			local v23_ = v21_.title
			table.insert(v18_, v23_)
			if v21_.id == g_startMissionInfo.mapId then
				v19_ = v20_
			end
		end
	end
	self.mapSelector:setTexts(v18_)
	self.mapSelector:setState(v19_ or 1, true)
	for v24_ = #self.mapDotBox.elements, 1, -1 do
		self.mapDotBox.elements[v24_]:delete()
	end
	if #v18_ < 10 then
		for v_u_25_ = 1, #v18_ do
			self.mapDotTemplate:clone(self.mapDotBox).getIsSelected = function()
				-- upvalues: (copy) self, (copy) v_u_25_
				return self.mapSelector:getState() == v_u_25_
			end
		end
	else
		self.mapDotBox:setVisible(false)
		self.mapNumberText:setVisible(true)
		local v26_ = self.mapNumberText
		local v27_ = #v18_
		v26_:setText("1 / " .. tostring(v27_))
	end
	self.mapDotBox:invalidateLayout()
	self.startWithFarmBox:setVisible(not g_startMissionInfo.isMultiplayer)
	self.startWithGuidedTourBox:setVisible(not g_startMissionInfo.isMultiplayer)
end

-- Local values: i
function NewGameScreen:delete()
	for v29_ = #self.mapDotBox.elements, 1, -1 do
		self.mapDotBox.elements[v29_]:delete()
	end
	self.mapDotTemplate:delete()
	NewGameScreen:superClass().delete(self)
end

function NewGameScreen:update(dt)
	NewGameScreen:superClass().update(self, dt)
	if g_dedicatedServer == nil then
		if Profiler.IS_INITIALIZED then
			self:selectMapByNameAndFile(Profiler.MAP, Profiler.MAP_FILENAME)
			self:onClickOk()
		elseif g_startMissionInfo.isMultiplayer then
			Platform.verifyMultiplayerAvailabilityInMenu()
		end
	else
		self:selectMapByNameAndFile(g_dedicatedServer.mapName, g_dedicatedServer.mapFileName)
		self:onClickOk()
		return
	end
end

-- Local values: mapId, _, k, map, selectedMap
function NewGameScreen:selectMapByNameAndFile(name, filename)
	if filename ~= "default" then
		local v35_, _ = Utils.getFilenameInfo(filename)
		name = v35_ .. "." .. name
	end
	self.mapSelector:setState(1)
	for v36_, v37_ in ipairs(self.maps) do
		if v37_.id == name then
			self.mapSelector:setState(v36_)
			return
		end
	end
	local v38_ = self.maps[self.mapSelector:getState()]
	Logging.devError("Unable to find map with mapId \'%s\'. Using default map \'%s\'", name, v38_.id)
end

function NewGameScreen:onClickStartWithFarm()
	self:updateStartWithTour()
end

-- Local values: startWithFarm
function NewGameScreen:updateStartWithTour()
	local v41_ = self.startWithFarmSelector:getIsChecked()
	if not v41_ then
		self.startWithGuidedTourSelector:setIsChecked(false, true)
		self.startWithGuidedTourSelector:update(1)
	end
	self.startWithGuidedTourSelector:setDisabled(not v41_)
end

-- Local values: startInfo, map, mapModName
function NewGameScreen:onClickOk()
	local v43_ = g_startMissionInfo
	v43_.mapId = self.maps[self.mapSelector:getState()].id
	if g_dedicatedServer == nil then
		v43_.economicDifficulty = self.economicDifficultySelector:getState()
		v43_.initialMoney = self.initialMoney[self.initialMoneySelector:getState()]
		v43_.initialLoan = self.initialLoan[self.initialLoanSelector:getState()]
		v43_.hasStartFarm = self.startWithFarmSelector:getIsChecked()
		v43_.startWithGuidedTour = self.startWithGuidedTourSelector:getIsChecked()
	else
		v43_.economicDifficulty = g_dedicatedServer.economicDifficulty
		v43_.initialMoney = g_dedicatedServer.initialMoney
		v43_.initialLoan = g_dedicatedServer.initialLoan
		v43_.hasStartFarm = g_dedicatedServer.hasStartFarm
		v43_.startWithTour = false
	end
	if g_mapManager:getModNameFromMapId(v43_.mapId) == nil or PlatformPrivilegeUtil.checkModUse(self.onClickOk, self) then
		v43_.canStart = true
		if v43_.isMultiplayer and not v43_.createGame then
			self:changeScreen(MultiplayerScreen)
		else
			self:changeScreen(CareerScreen)
		end
	else
		return
	end
end

-- Local values: map
function NewGameScreen:onClickMap(state)
	local v46_ = self.maps[state]
	self.mapBackground:setImageFilename(v46_.iconFilename)
	if self.mapNumberText:getIsVisible() then
		local v47_ = self.mapNumberText
		local v48_ = tostring(state)
		local v49_ = #self.mapSelector.texts
		v47_:setText(v48_ .. " / " .. tostring(v49_))
	end
end

-- Local values: preset
function NewGameScreen:onClickPreset(state)
	local v52_ = self.presets[state]
	self.initialMoneySelector:setState(v52_.initialMoneyIndex)
	self.initialLoanSelector:setState(v52_.initialLoanIndex)
	self.startWithFarmSelector:setIsChecked(v52_.startWithFarm, true)
	self.economicDifficultySelector:setState(v52_.economicDifficulty)
	self.startWithGuidedTourSelector:setIsChecked(v52_.startWithGuidedTour, true)
	self:updateStartWithTour()
end
