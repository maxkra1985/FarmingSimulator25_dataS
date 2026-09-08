-- Local values: WardrobeCharactersFrame_mt
WardrobeCharactersFrame = {}
local WardrobeCharactersFrame_mt = Class(WardrobeCharactersFrame, TabbedMenuFrameElement)
function WardrobeCharactersFrame.register()
	local v2_ = WardrobeCharactersFrame.new()
	g_gui:loadGui("dataS/gui/WardrobeCharactersFrame.xml", "WardrobeCharactersFrame", v2_, true)
end

-- Upvalues: WardrobeCharactersFrame_mt
-- Local values: self
function WardrobeCharactersFrame.new(target, custom_mt)
	-- upvalues: (copy) WardrobeCharactersFrame_mt
	local v_u_5_ = TabbedMenuFrameElement.new(target, custom_mt or WardrobeCharactersFrame_mt)
	v_u_5_.backButtonInfo = {
		["inputAction"] = InputAction.MENU_BACK,
		["text"] = g_i18n:getText("button_confirm")
	}
	v_u_5_.nextPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_NEXT,
		["text"] = g_i18n:getText("ui_ingameMenuNext"),
		["callback"] = v_u_5_.onPageNext
	}
	v_u_5_.prevPageButtonInfo = {
		["inputAction"] = InputAction.MENU_PAGE_PREV,
		["text"] = g_i18n:getText("ui_ingameMenuPrev"),
		["callback"] = v_u_5_.onPagePrevious
	}
	v_u_5_.selectButtonInfo = {
		["inputAction"] = InputAction.MENU_ACCEPT,
		["text"] = g_i18n:getText("button_select"),
		["callback"] = function()
			-- upvalues: (copy) v_u_5_
			v_u_5_:onClickSelect()
		end
	}
	v_u_5_.nicknameButtonInfo = {
		["inputAction"] = InputAction.MENU_CANCEL,
		["text"] = g_i18n:getText("button_changeName"),
		["callback"] = function()
			-- upvalues: (copy) v_u_5_
			v_u_5_:onClickChangeName()
		end
	}
	v_u_5_.hasCustomMenuButtons = true
	v_u_5_.menuButtonInfo = {
		v_u_5_.backButtonInfo,
		v_u_5_.nextPageButtonInfo,
		v_u_5_.prevPageButtonInfo,
		v_u_5_.selectButtonInfo
	}
	if Platform.canChangeGamerTag then
		local v6_ = v_u_5_.menuButtonInfo
		local v7_ = v_u_5_.nicknameButtonInfo
		table.insert(v6_, v7_)
	end
	v_u_5_.mapping = {}
	return v_u_5_
end

-- Local values: newGui
function WardrobeCharactersFrame.createFromExistingGui(gui, guiName)
	local v10_ = WardrobeCharactersFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v10_, true)
	return v10_
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

-- Local values: selectedIndex, playerIndex, player, i, item
function WardrobeCharactersFrame:resetList()
	self.mapping = {}
	if self.playerStyle ~= nil then
		local v21_ = 1
		for _, v22_ in ipairs(self.players) do
			for v23_, v24_ in ipairs(v22_.style.configs.face.items) do
				if v24_.isSelectable then
					local v25_ = self.mapping
					local v26_ = {
						["xmlFilename"] = v22_.xmlFilename,
						["iconFilename"] = v24_.iconFilename,
						["index"] = v23_,
						["style"] = v22_.style
					}
					table.insert(v25_, v26_)
					if self.playerStyle.configs.face.selectedItemIndex == v23_ and self.playerStyle.xmlFilename == v22_.xmlFilename then
						v21_ = #self.mapping
					end
				end
			end
		end
		self.itemList:reloadData()
		self.itemList:setSelectedItem(1, v21_)
	end
	FocusManager:setFocus(self.itemList)
end

-- Local values: _, cell
function WardrobeCharactersFrame:onFrameClose()
	for _, v28_ in ipairs(self.itemList.elements) do
		if v28_:getAttribute("icon") ~= nil then
			v28_:getAttribute("icon"):setImageFilename(g_baseUIFilename)
		end
	end
	g_messageCenter:unsubscribe(MessageType.PLAYER_NICKNAME_CHANGED, self)
	WardrobeCharactersFrame:superClass().onFrameClose(self)
end

-- Local values: _, playerStyleConfig, playerStyle, info
function WardrobeCharactersFrame:loadPlayers()
	self.players = {}
	for _, v30_ in pairs(PlayerSystem.PLAYER_STYLES_BY_FILENAME) do
		local v31_ = PlayerStyle.new()
		v31_:copyFrom(v30_.style)
		local v32_ = {
			["xmlFilename"] = v30_.filename,
			["style"] = v31_
		}
		local v33_ = self.players
		table.insert(v33_, v32_)
	end
end

function WardrobeCharactersFrame:getNumberOfItemsInSection(list, section)
	return #self.mapping
end

-- Local values: item, getIsSelectedFunc, getIsFocusedFunc
function WardrobeCharactersFrame:populateCellForItemInSection(list, section, index, cell)
	local v_u_38_ = self.mapping[index]
	local function v40_()
		-- upvalues: (copy) self, (copy) v_u_38_
		local v39_
		if self.savedPlayerStyle.configs.face.selectedItemIndex == v_u_38_.index then
			v39_ = self.savedPlayerStyle.xmlFilename == v_u_38_.xmlFilename
		else
			v39_ = false
		end
		return v39_
	end
	cell:getAttribute("icon"):setImageFilename(v_u_38_.iconFilename)
	cell:getAttribute("icon"):setVisible(v_u_38_.iconFilename ~= nil)
	cell:getAttribute("icon").getIsSelected = v40_
	cell:getAttribute("background").getIsSelected = v40_
	cell:getAttribute("background").getIsFocused = function()
		-- upvalues: (copy) cell
		return cell.selected
	end
end

-- Local values: item, faceConfig, beardConfig, possibleItemIndices, oldSelectedBeardIndex, k, index, newPossibleItemIndices, beardConfigIndex
function WardrobeCharactersFrame:onListSelectionChanged(list, section, index)
	local v43_ = self.mapping[index]
	if self.playerStyle.xmlFilename ~= v43_.xmlFilename then
		self.playerStyle:loadConfigurationXML(v43_.xmlFilename)
	end
	local v44_ = self.playerStyle.configs.face
	local v45_ = self.playerStyle.configs.beard
	local v46_ = v45_:getPossibleItemIndices()
	local v47_ = -1
	for v48_, v49_ in ipairs(v46_) do
		if v49_ == v45_.selectedItemIndex then
			v47_ = v48_
			break
		end
	end
	v44_:setSelectedItemIndex(v43_.index)
	local v50_ = v45_:getPossibleItemIndices()[v47_]
	if v50_ ~= nil then
		v45_:setSelectedItemIndex(v50_)
	end
	self.delegate:onItemSelectionChanged()
end

function WardrobeCharactersFrame:onClickSelect(element)
	self.delegate:onItemSelectionConfirmed()
	self.itemList:reloadData()
end

-- Local values: text, callback, defaultText, imePrompt, confirmText
function WardrobeCharactersFrame:onClickChangeName()
	local v53_ = g_i18n:getText("ui_enterName")
	local v54_ = g_currentMission.playerNickname
	local v55_ = g_i18n:getText("ui_enterName")
	local v56_ = g_i18n:getText("button_change")
	TextInputDialog.show(function(p57_, p58_)
		-- upvalues: (copy) self
		if p58_ and p57_ ~= g_currentMission.playerNickname then
			g_currentMission:setPlayerNickname(g_localPlayer, p57_)
			self.nicknameElement:setText(g_i18n:getText("ui_name") .. ": " .. g_currentMission.playerNickname)
		end
	end, nil, v54_, nil, v55_, nil, v56_, nil, v53_)
end

function WardrobeCharactersFrame:onNicknameChanged()
	self.nicknameElement:setText(g_i18n:getText("ui_name") .. ": " .. g_currentMission.playerNickname)
end
