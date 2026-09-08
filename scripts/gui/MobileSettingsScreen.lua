-- Local values: MobileSettingsScreen_mt
MobileSettingsScreen = {}
MobileSettingsScreen.CLOUD_SYNC = { "cloudSync_wifiOnly", "cloudSync_always" }
local MobileSettingsScreen_mt = Class(MobileSettingsScreen, ScreenElement)
function MobileSettingsScreen.register()
	local v2_ = MobileSettingsScreen.new()
	g_gui:loadGui("dataS/gui/MobileSettingsScreen.xml", "MobileSettingsScreen", v2_)
	return v2_
end

-- Upvalues: MobileSettingsScreen_mt
-- Local values: self
function MobileSettingsScreen.new(target, custom_mt)
	-- upvalues: (copy) MobileSettingsScreen_mt
	local v5_ = ScreenElement.new(target, custom_mt or MobileSettingsScreen_mt)
	v5_:setReturnScreenClass(MainScreen)
	return v5_
end

-- Local values: newGui
function MobileSettingsScreen.createFromExistingGui(gui, guiName)
	local v8_ = MobileSettingsScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_)
	return v8_
end

-- Local values: mainContainerSize, isAvailable, texts, _, setting
function MobileSettingsScreen:onOpen()
	MobileSettingsScreen:superClass().onOpen(self)
	if Platform.isMobile then
		local v10_ = (g_screenWidth - self.sidebar.absSize[1] * g_screenWidth - 50) * g_pixelSizeX
		self.mainContainer:setSize(v10_)
		self.languageText:setSize(v10_ - 110 * g_pixelSizeX)
		self.contentContainer:setSize(v10_ - 100 * g_pixelSizeX, (g_screenHeight - 250) * g_pixelSizeY)
		self.contentContainer:setAnchors(0, 1 - (v10_ - self.contentContainer.absSize[1]), 1 - self.contentContainer.absSize[2], 1)
		self.mainContainer.absPosition[1] = 1 - v10_
		self.mainContainer:setAnchors(self.mainContainer.absPosition[1], 1, 0, 1)
		self.mainContainer:updateAbsolutePosition()
	end
	self:updateTheme()
	self.languageElement:setTexts(g_settingsModel:getLanguageTexts())
	self.languageElement:setState(g_settingsModel:getValue(SettingsModel.SETTING.LANGUAGE))
	if getPlatformId() == PlatformId.ANDROID then
		self.achievementsButton:setDisabled(not getIsUserSignedIn())
	end
	local v11_ = {}
	local v12_ = false
	for _, v13_ in pairs(MobileSettingsScreen.CLOUD_SYNC) do
		local v14_ = g_i18n
		table.insert(v11_, v14_:getText(v13_))
	end
	self.cloudSyncElement:setTexts(v11_)
	self.cloudSyncElement:setVisible(Platform.hasCloudSyncSetting and v12_)
	self.cloudSyncText:setVisible(Platform.hasCloudSyncSetting and v12_)
	self.contentContainer:invalidateLayout()
end

-- Local values: filename
function MobileSettingsScreen:updateTheme()
	local v16_ = Platform.gameLogos[g_languageShort]
	if v16_ == nil then
		v16_ = Platform.gameLogos.en
	end
	if self.logo ~= nil then
		self.logo:setImageFilename(v16_)
	end
end

function MobileSettingsScreen:onCareerClick(element)
	self:changeScreen(MainScreen)
	FocusManager:setFocus(g_mainScreen.careerButton)
	g_mainScreen:onCareerClick(element)
end

function MobileSettingsScreen:onAchievementsClick(element)
	self:changeScreen(AchievementsScreen)
	FocusManager:setFocus(g_mainScreen.achievementsButton)
	g_mainScreen:onAchievementsClick(element)
end

function MobileSettingsScreen:onCreditsClick(element)
	self:changeScreen(MainScreen)
	FocusManager:setFocus(g_mainScreen.creditsButton)
	g_mainScreen:onCreditsClick(element)
end

-- Local values: language, languageChanged, message, restartFunc
function MobileSettingsScreen:onClickOk()
	local v24_ = g_availableLanguagesTable[self.languageElement.state]
	local v25_ = setLanguage(v24_)
	local v26_ = g_i18n:getText("ui_languageChangeFailed")
	if v25_ then
		v26_ = string.format(g_i18n:getText("ui_languageChange"), self.languageElement.texts[self.languageElement.state])
	end
	InfoDialog.show(v26_, function(p27_)
		if p27_ then
			doRestart(false, "")
		end
	end, nil, DialogElement.TYPE_INFO)
end
