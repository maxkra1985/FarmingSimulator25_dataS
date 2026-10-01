WardrobeCharactersFrame = {}
local WardrobeCharactersFrame_mt = Class(WardrobeCharactersFrame, TabbedMenuFrameElement)
function WardrobeCharactersFrame.register()
	local wardrobeCharactersFrame = WardrobeCharactersFrame.new()
	g_gui:loadGui("dataS/gui/WardrobeCharactersFrame.xml", "WardrobeCharactersFrame", wardrobeCharactersFrame, true)
end
function WardrobeCharactersFrame.new(target, custom_mt)
	local self = TabbedMenuFrameElement.new(target, custom_mt or WardrobeCharactersFrame_mt)
	self.backButtonInfo = { inputAction = InputAction.MENU_BACK, text = g_i18n:getText("button_confirm") }
	self.nextPageButtonInfo = { inputAction = InputAction.MENU_PAGE_NEXT, text = g_i18n:getText("ui_ingameMenuNext"), callback = self.onPageNext }
	self.prevPageButtonInfo = { inputAction = InputAction.MENU_PAGE_PREV, text = g_i18n:getText("ui_ingameMenuPrev"), callback = self.onPagePrevious }
	self.selectButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText("button_select"),
		callback = function()
			self:onClickSelect()
		end,
	}
	self.nicknameButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = g_i18n:getText("button_changeName"),
		callback = function()
			self:onClickChangeName()
		end,
	}
	self.hasCustomMenuButtons = true
	self.menuButtonInfo = { self.backButtonInfo, self.nextPageButtonInfo, self.prevPageButtonInfo, self.selectButtonInfo }
	if Platform.canChangeGamerTag then
		table.insert(self.menuButtonInfo, self.nicknameButtonInfo)
	end
	self.mapping = {}
	return self
end
function WardrobeCharactersFrame.createFromExistingGui(gui, guiName)
	local newGui = WardrobeCharactersFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, newGui, true)
	return newGui
end
function WardrobeCharactersFrame:initialize(configName, delegate, titleKey, sliceId)
	self.configName = configName
	self.delegate = delegate
	self.title:setLocaKey(titleKey)
	self.headerIcon:setImageSlice(nil, sliceId)
	self:loadPlayers()
end
function WardrobeCharactersFrame:setPlayerStyle(playerStyle, savedPlayerStyle)
	self.playerStyle = playerStyle
	self.savedPlayerStyle = savedPlayerStyle
	self:resetList()
end
function WardrobeCharactersFrame:onFrameOpen()
	WardrobeCharactersFrame:superClass().onFrameOpen(self)
	self.delegate:onItemSelectionStart()
	self.nicknameElement:setText(g_i18n:getText("ui_name") .. ": " .. g_currentMission.playerNickname)
	g_messageCenter:subscribe(MessageType.PLAYER_NICKNAME_CHANGED, self.onNicknameChanged, self)
	self:resetList()
end
function WardrobeCharactersFrame:resetList()
	self.mapping = {}
	if self.playerStyle ~= nil then
		local selectedIndex = 1
		for playerIndex, player in ipairs(self.players) do
			for i, item in ipairs(player.style.configs.face.items) do
				if item.isSelectable then
					table.insert(self.mapping, { index = i, xmlFilename = player.xmlFilename, iconFilename = item.iconFilename, style = player.style })
					if self.playerStyle.configs.face.selectedItemIndex == i and self.playerStyle.xmlFilename == player.xmlFilename then
						selectedIndex = #self.mapping
					end
				end
			end
		end
		self.itemList:reloadData()
		self.itemList:setSelectedItem(1, selectedIndex)
	end
	FocusManager:setFocus(self.itemList)
end
function WardrobeCharactersFrame:onFrameClose()
	for _, cell in ipairs(self.itemList.elements) do
		if cell:getAttribute("icon") == nil then
			continue
		end
		cell:getAttribute("icon"):setImageFilename(g_baseUIFilename)
	end
	g_messageCenter:unsubscribe(MessageType.PLAYER_NICKNAME_CHANGED, self)
	WardrobeCharactersFrame:superClass().onFrameClose(self)
end
function WardrobeCharactersFrame:loadPlayers()
	self.players = {}
	for _, playerStyleConfig in pairs(PlayerSystem.PLAYER_STYLES_BY_FILENAME) do
		local playerStyle = PlayerStyle.new()
		playerStyle:copyFrom(playerStyleConfig.style)
		local info = { style = playerStyle }
		info.xmlFilename = playerStyleConfig.filename
		table.insert(self.players, info)
	end
end
function WardrobeCharactersFrame:getNumberOfItemsInSection(list, section)
	return #self.mapping
end
function WardrobeCharactersFrame:populateCellForItemInSection(list, section, index, cell)
	local item = self.mapping[index]
	local getIsSelectedFunc = function()
		local _v0 = false
		if self.savedPlayerStyle.configs.face.selectedItemIndex == item.index then
			_v0 = self.savedPlayerStyle.xmlFilename == item.xmlFilename
		end
		return _v0
	end
	local getIsFocusedFunc = function()
		return cell.selected
	end
	cell:getAttribute("icon"):setImageFilename(item.iconFilename)
	cell:getAttribute("icon"):setVisible(item.iconFilename ~= nil)
	cell:getAttribute("icon").getIsSelected = getIsSelectedFunc
	cell:getAttribute("background").getIsSelected = getIsSelectedFunc
	cell:getAttribute("background").getIsFocused = getIsFocusedFunc
end
function WardrobeCharactersFrame:onListSelectionChanged(list, section, index)
	local item = self.mapping[index]
	if self.playerStyle.xmlFilename ~= item.xmlFilename then
		self.playerStyle:loadConfigurationXML(item.xmlFilename)
	end
	local faceConfig = self.playerStyle.configs.face
	local beardConfig = self.playerStyle.configs.beard
	local possibleItemIndices = beardConfig:getPossibleItemIndices()
	local oldSelectedBeardIndex = -1
	for k, index in ipairs(possibleItemIndices) do
		if index == beardConfig.selectedItemIndex then
			oldSelectedBeardIndex = k
			break
		end
	end
	faceConfig:setSelectedItemIndex(item.index)
	local newPossibleItemIndices = beardConfig:getPossibleItemIndices()
	local beardConfigIndex = newPossibleItemIndices[oldSelectedBeardIndex]
	if beardConfigIndex ~= nil then
		beardConfig:setSelectedItemIndex(beardConfigIndex)
	end
	self.delegate:onItemSelectionChanged()
end
function WardrobeCharactersFrame:onClickSelect(element)
	self.delegate:onItemSelectionConfirmed()
	self.itemList:reloadData()
end
function WardrobeCharactersFrame:onClickChangeName()
	local text = g_i18n:getText("ui_enterName")
	local callback = function(newName, ok)
		if ok and newName ~= g_currentMission.playerNickname then
			g_currentMission:setPlayerNickname(g_localPlayer, newName)
			self.nicknameElement:setText(g_i18n:getText("ui_name") .. ": " .. g_currentMission.playerNickname)
		end
	end
	local defaultText = g_currentMission.playerNickname
	local imePrompt = g_i18n:getText("ui_enterName")
	local confirmText = g_i18n:getText("button_change")
	TextInputDialog.show(callback, nil, defaultText, nil, imePrompt, nil, confirmText, nil, text)
end
function WardrobeCharactersFrame:onNicknameChanged()
	self.nicknameElement:setText(g_i18n:getText("ui_name") .. ": " .. g_currentMission.playerNickname)
end
