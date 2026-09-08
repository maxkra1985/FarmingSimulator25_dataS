-- Local values: AchievementsScreen_mt
AchievementsScreen = {}
local AchievementsScreen_mt = Class(AchievementsScreen, ScreenElement)
function AchievementsScreen.register()
	local v2_ = AchievementsScreen.new()
	g_gui:loadGui("dataS/gui/AchievementsScreen.xml", "AchievementsScreen", v2_)
	return v2_
end

-- Upvalues: AchievementsScreen_mt
-- Local values: self
function AchievementsScreen.new(target, custom_mt)
	-- upvalues: (copy) AchievementsScreen_mt
	local v5_ = ScreenElement.new(target, custom_mt or AchievementsScreen_mt)
	v5_.achievements = {}
	v5_.needAchievementSync = false
	v5_:setReturnScreenClass(MainScreen)
	return v5_
end

-- Local values: newGui
function AchievementsScreen.createFromExistingGui(gui, guiName)
	local v8_ = AchievementsScreen.new()
	g_gui.guis[guiName]:delete()
	g_gui.guis[guiName].target:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_)
	return v8_
end

function AchievementsScreen:onOpen()
	AchievementsScreen:superClass().onOpen(self)
	if Platform.hasMainScreenLanguageSelection then
		self.changeLanguageButton:setVisible(true)
		self.buttonBox:invalidateLayout()
	end
	if self:checkAchievementSynchronization() then
		self:getAchievements()
	else
		self:assignAchievementsStatsValue(false)
		self.achievementList:reloadData()
	end
	self:updateTheme()
	FocusManager:setFocus(self.achievementList)
	g_messageCenter:subscribe(MessageType.INSETS_CHANGED, self.updateInsets, self)
end

function AchievementsScreen:onClose()
	g_messageCenter:unsubscribe(MessageType.INSETS_CHANGED, self)
	AchievementsScreen:superClass().onClose(self)
end

-- Local values: _, rightInset, _, _, listPosX, width, maxPosX, currentMaxX
function AchievementsScreen:updateInsets()
	local _, v12_, _, _ = getSafeFrameInsets()
	self.contentBox:setSize(1 - v12_, 1)
	self.contentBox:updateAbsolutePosition()
	local v13_ = self.achievementList.absPosition[1]
	local v14_ = self.achievementList.absSize[1]
	local v15_ = 1 - v12_
	if v15_ < v13_ + v14_ then
		self.achievementList.absSize[1] = v15_ - v13_
	end
	self.achievementList:updateView()
end

function AchievementsScreen:getAchievements()
	self.achievements = g_achievementManager.achievementList
	self:assignAchievementsStatsValue(true)
	self.achievementList:reloadData()
end

-- Local values: numUnlocked
function AchievementsScreen:assignAchievementsStatsValue(achievementsAvailable)
	local v19_ = achievementsAvailable and g_achievementManager.numberOfUnlockedAchievements or 0
	self.statsValue:setText(string.format("%d/%d", v19_, g_achievementManager.numberOfAchievements))
	self.statsBox:invalidateLayout()
	self.statsBoxBg:setSize(self.statsBox.flowSizes[1] + 65 * g_pixelSizeScaledX)
end

function AchievementsScreen:onCancelAchievementsSync()
	self.needAchievementSync = false
	self:changeScreen(MainScreen)
end

-- Local values: _, achievementsLoaded
function AchievementsScreen:checkAchievementSynchronization()
	local _, v22_ = areAchievementsAvailable()
	if v22_ or self.needAchievementSync then
		if v22_ and self.needAchievementSync then
			self.needAchievementSync = false
			self:getAchievements()
			g_gui:closeAllDialogs()
		end
		return v22_
	end
	self.needAchievementSync = true
	InfoDialog.show(g_i18n:getText("ui_achievementsSynchronizing"), self.onCancelAchievementsSync, self, DialogElement.TYPE_LOADING, g_i18n:getText("button_cancel"), InputAction.MENU_BACK)
	return v22_
end

function AchievementsScreen:update(dt)
	AchievementsScreen:superClass().update(self, dt)
	if Platform.hasOnlineAchievements and getNetworkError() then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		return
	elseif getPlatformId() == PlatformId.ANDROID and not getIsUserSignedIn() then
		g_gui:changeScreen(nil, MainScreen)
	else
		self:checkAchievementSynchronization()
	end
end

-- Local values: filename
function AchievementsScreen:updateTheme()
	local v26_ = Platform.gameLogos[g_languageShort]
	if v26_ == nil then
		v26_ = Platform.gameLogos.en
	end
	if self.logo ~= nil then
		self.logo:setImageFilename(v26_)
	end
end

function AchievementsScreen:getNumberOfItemsInSection(list, section)
	return #self.achievements
end

-- Local values: achievement, icon, v0, u0, v1, u1, v2, u2, v3, u3, imageFilename, lockedUvs, v0, u0, v1, u1, v2, u2, v3, u3
function AchievementsScreen:populateCellForItemInSection(list, section, index, cell)
	local v31_ = self.achievements[index]
	cell:setDisabled(not v31_.unlocked)
	cell:getAttribute("title"):setText(v31_.name)
	cell:getAttribute("description"):setText(v31_.description)
	local v32_ = cell:getAttribute("icon")
	if v31_.unlocked then
		v32_:setImageFilename(v31_.imageFilename)
		local v33_ = v31_.imageUVs
		local v34_, v35_, v36_, v37_, v38_, v39_, v40_, v41_ = unpack(v33_)
		v32_:setImageUVs(nil, v34_, v35_, v36_, v37_, v38_, v39_, v40_, v41_)
	else
		local v42_, v43_ = g_achievementManager:getLockedImageData()
		v32_:setImageFilename(v42_)
		local v44_, v45_, v46_, v47_, v48_, v49_, v50_, v51_ = unpack(v43_)
		v32_:setImageUVs(nil, v44_, v45_, v46_, v47_, v48_, v49_, v50_, v51_)
	end
end
