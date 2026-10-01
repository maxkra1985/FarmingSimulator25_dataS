NewGameScreen = {}
local NewGameScreen_mt = Class(NewGameScreen, ScreenElement)
function NewGameScreen.register()
	local newGameScreen = NewGameScreen.new()
	g_gui:loadGui("dataS/gui/NewGameScreen.xml", "NewGameScreen", newGameScreen)
	return newGameScreen
end
function NewGameScreen.new(target, custom_mt)
	local self = ScreenElement.new(target, custom_mt or NewGameScreen_mt)
	self.maps = {}
	self.initialMoney = { 100000, 250000, 500000, 750000, 1000000 }
	if g_isDevelopmentVersion then
		table.insert(self.initialMoney, 100000000)
	end
	self.initialMoneyTexts = {}
	for _, capital in ipairs(self.initialMoney) do
		table.insert(self.initialMoneyTexts, g_i18n:formatMoney(capital, 0, true, true))
	end
	self.initialLoan = { 0, 100000, 250000, 500000, 750000, 1000000 }
	self.initialLoanTexts = {}
	for _, capital in ipairs(self.initialLoan) do
		table.insert(self.initialLoanTexts, g_i18n:formatMoney(capital, 0, true, true))
	end
	self.economicDifficultyTexts = { g_i18n:getText("button_easy"), g_i18n:getText("button_normal"), g_i18n:getText("button_hard") }
	self.presetNames = { g_i18n:getText("ui_difficulty1"), g_i18n:getText("ui_difficulty2"), g_i18n:getText("ui_difficulty3") }
	self.presets = {}
	self.presets[1] = { initialMoneyIndex = 1, initialLoanIndex = 1, startWithFarm = true, startWithGuidedTour = not g_isDevelopmentVersion, economicDifficulty = EconomicDifficulty.EASY }
	self.presets[2] = { initialMoneyIndex = 5, initialLoanIndex = 1, startWithFarm = false, startWithGuidedTour = false, economicDifficulty = EconomicDifficulty.NORMAL }
	self.presets[3] = { initialMoneyIndex = 3, initialLoanIndex = 3, startWithFarm = false, startWithGuidedTour = false, economicDifficulty = EconomicDifficulty.HARD }
	return self
end
function NewGameScreen.createFromExistingGui(gui, guiName)
	local newGui = NewGameScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui)
	return newGui
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
function NewGameScreen:onOpen()
	NewGameScreen:superClass().onOpen(self)
	self.maps = {}
	local currentSelection = nil
	local texts = {}
	for i = 1, g_mapManager:getNumOfMaps() do
		local map = g_mapManager:getMapDataByIndex(i)
		if (not map.isModMap or g_dedicatedServer == nil and not g_startMissionInfo.isMultiplayer or map.isMultiplayerSupported) and map.isSelectable then
			table.insert(self.maps, map)
			table.insert(texts, map.title)
			if map.id == g_startMissionInfo.mapId then
				currentSelection = i
			end
		end
	end
	self.mapSelector:setTexts(texts)
	self.mapSelector:setState(currentSelection or 1, true)
	for i = #self.mapDotBox.elements, 1, -1 do
		self.mapDotBox.elements[i]:delete()
	end
	if #texts < 10 then
		for i = 1, #texts do
			local dot = self.mapDotTemplate:clone(self.mapDotBox)
			function dot.getIsSelected()
				return self.mapSelector:getState() == i
			end
		end
	else
		self.mapDotBox:setVisible(false)
		self.mapNumberText:setVisible(true)
		self.mapNumberText:setText("1 / " .. tostring(#texts))
	end
	self.mapDotBox:invalidateLayout()
	self.startWithFarmBox:setVisible(not g_startMissionInfo.isMultiplayer)
	self.startWithGuidedTourBox:setVisible(not g_startMissionInfo.isMultiplayer)
end
function NewGameScreen:delete()
	for i = #self.mapDotBox.elements, 1, -1 do
		self.mapDotBox.elements[i]:delete()
	end
	self.mapDotTemplate:delete()
	NewGameScreen:superClass().delete(self)
end
function NewGameScreen:update(dt)
	NewGameScreen:superClass().update(self, dt)
	if g_dedicatedServer ~= nil then
		self:selectMapByNameAndFile(g_dedicatedServer.mapName, g_dedicatedServer.mapFileName)
		self:onClickOk()
	elseif Profiler.IS_INITIALIZED then
		self:selectMapByNameAndFile(Profiler.MAP, Profiler.MAP_FILENAME)
		self:onClickOk()
	else
		if g_startMissionInfo.isMultiplayer then
			Platform.verifyMultiplayerAvailabilityInMenu()
		end
	end
end
function NewGameScreen:selectMapByNameAndFile(name, filename)
	local mapId = name
	if filename ~= "default" then
		local _ = nil
		filename, _ = Utils.getFilenameInfo(filename)
		mapId = filename .. "." .. name
	end
	self.mapSelector:setState(1)
	for k, map in ipairs(self.maps) do
		if map.id == mapId then
			self.mapSelector:setState(k)
			return
		end
	end
	local selectedMap = self.maps[self.mapSelector:getState()]
	Logging.devError("Unable to find map with mapId '%s'. Using default map '%s'", mapId, selectedMap.id)
end
function NewGameScreen:onClickStartWithFarm()
	self:updateStartWithTour()
end
function NewGameScreen:updateStartWithTour()
	local startWithFarm = self.startWithFarmSelector:getIsChecked()
	if not startWithFarm then
		self.startWithGuidedTourSelector:setIsChecked(false, true)
		self.startWithGuidedTourSelector:update(1)
	end
	self.startWithGuidedTourSelector:setDisabled(not startWithFarm)
end
function NewGameScreen:onClickOk()
	local startInfo = g_startMissionInfo
	local map = self.maps[self.mapSelector:getState()]
	startInfo.mapId = map.id
	if g_dedicatedServer ~= nil then
		startInfo.economicDifficulty = g_dedicatedServer.economicDifficulty
		startInfo.initialMoney = g_dedicatedServer.initialMoney
		startInfo.initialLoan = g_dedicatedServer.initialLoan
		startInfo.hasStartFarm = g_dedicatedServer.hasStartFarm
		startInfo.startWithTour = false
	else
		startInfo.economicDifficulty = self.economicDifficultySelector:getState()
		startInfo.initialMoney = self.initialMoney[self.initialMoneySelector:getState()]
		startInfo.initialLoan = self.initialLoan[self.initialLoanSelector:getState()]
		startInfo.hasStartFarm = self.startWithFarmSelector:getIsChecked()
		startInfo.startWithGuidedTour = self.startWithGuidedTourSelector:getIsChecked()
	end
	local mapModName = g_mapManager:getModNameFromMapId(startInfo.mapId)
	if mapModName ~= nil and not PlatformPrivilegeUtil.checkModUse(self.onClickOk, self) then
		return
	end
	startInfo.canStart = true
	if startInfo.isMultiplayer and not startInfo.createGame then
		self:changeScreen(MultiplayerScreen)
		return
	end
	self:changeScreen(CareerScreen)
end
function NewGameScreen:onClickMap(state)
	local map = self.maps[state]
	self.mapBackground:setImageFilename(map.iconFilename)
	if self.mapNumberText:getIsVisible() then
		self.mapNumberText:setText(tostring(state) .. " / " .. tostring(#self.mapSelector.texts))
	end
end
function NewGameScreen:onClickPreset(state)
	local preset = self.presets[state]
	self.initialMoneySelector:setState(preset.initialMoneyIndex)
	self.initialLoanSelector:setState(preset.initialLoanIndex)
	self.startWithFarmSelector:setIsChecked(preset.startWithFarm, true)
	self.economicDifficultySelector:setState(preset.economicDifficulty)
	self.startWithGuidedTourSelector:setIsChecked(preset.startWithGuidedTour, true)
	self:updateStartWithTour()
end
