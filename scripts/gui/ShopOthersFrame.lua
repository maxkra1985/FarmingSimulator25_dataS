-- Local values: ShopOthersFrame_mt
ShopOthersFrame = {}
ShopOthersFrame.NUM_GAMEPLAY_HINTS = 4
local ShopOthersFrame_mt = Class(ShopOthersFrame, TabbedMenuFrameElement)
function ShopOthersFrame.register()
	local v2_ = ShopOthersFrame.new()
	g_gui:loadGui("dataS/gui/ShopOthersFrame.xml", "ShopOthersFrame", v2_, true)
end

-- Upvalues: ShopOthersFrame_mt
-- Local values: self
function ShopOthersFrame.new(target, custom_mt)
	-- upvalues: (copy) ShopOthersFrame_mt
	local v5_ = TabbedMenuFrameElement.new(target, custom_mt or ShopOthersFrame_mt)
	v5_.headerLabelText = ""
	v5_.gameplayHintsInitialized = false
	v5_.gameplayHintDuration = 6500
	v5_.gameplayHintTime = v5_.gameplayHintDuration
	return v5_
end

-- Local values: newGui
function ShopOthersFrame.createFromExistingGui(gui, guiName)
	local v8_ = ShopOthersFrame.new()
	g_gui.frames[gui.name].target:delete()
	g_gui.frames[gui.name]:delete()
	g_gui:loadGui(gui.xmlFilename, guiName, v8_, true)
	return v8_
end

function ShopOthersFrame:initialize(categorySelectedCallback, headerText, headerIconSlice)
	self.headerLabelText = headerText
	self.notifySelectedCategoryCallback = categorySelectedCallback
	if self.categoryHeaderText ~= nil then
		self.categoryHeaderText:setText(headerText)
		self.categoryHeaderText:updateAbsolutePosition()
		self.categoryHeaderIcon:setImageSlice(nil, headerIconSlice)
	end
	self:setTitle(headerText)
end

-- Local values: hints, texts, _, hint, text
function ShopOthersFrame:onFrameOpen()
	ShopOthersFrame:superClass().onFrameOpen(self)
	self.notifySelectedCategoryCallback(nil)
	if g_gameplayHintManager:getIsLoaded() then
		local v14_ = g_gameplayHintManager:getRandomGameplayHint(InGameMenuSaveFrame.NUM_GAMEPLAY_HINTS)
		if v14_ ~= nil then
			local v15_ = {}
			for _, v16_ in ipairs(v14_) do
				local v17_ = string.gsub(v16_, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
				table.insert(v15_, v17_)
			end
			self.gameplayHintsInitialized = true
			self.gameplayHintSelector:setTexts(v15_)
			self.hintStateBox:setPageCount(InGameMenuSaveFrame.NUM_GAMEPLAY_HINTS)
		end
		self.gameplayHintTime = self.gameplayHintDuration
	end
end

function ShopOthersFrame:onFrameClose()
	ShopOthersFrame:superClass().onFrameClose(self)
	self:setSoundSuppressed(true)
end

-- Local values: hints, texts, _, hint, text
function ShopOthersFrame:update(dt)
	ShopOthersFrame:superClass().update(self, dt)
	if self.gameplayHintsInitialized then
		self.gameplayHintTime = self.gameplayHintTime - dt
		if self.gameplayHintTime <= 0 then
			self.gameplayHintTime = self.gameplayHintDuration
			self.gameplayHintSelector.soundDisabled = true
			self.gameplayHintSelector:onRightButtonClicked(nil, true)
			self.gameplayHintSelector.soundDisabled = false
			return
		end
	elseif g_gameplayHintManager:getIsLoaded() then
		local v21_ = g_gameplayHintManager:getRandomGameplayHint(ShopOthersFrame.NUM_GAMEPLAY_HINTS)
		if v21_ ~= nil then
			local v22_ = {}
			for _, v23_ in ipairs(v21_) do
				local v24_ = string.gsub(v23_, "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))
				table.insert(v22_, v24_)
			end
			self.gameplayHintsInitialized = true
			self.gameplayHintSelector:setTexts(v22_)
			self.hintStateBox:setPageCount(ShopOthersFrame.NUM_GAMEPLAY_HINTS)
		end
		self.gameplayHintTime = self.gameplayHintDuration
	end
end

function ShopOthersFrame:updateMenuButtons()
	g_shopMenu:updateButtonsPanel(g_shopMenu.pageShopOthers)
end

function ShopOthersFrame:onButtonFocused(button)
	FocusManager:linkElements(self.gameplayHintSelector, FocusManager.TOP, button)
	FocusManager:linkElements(self.gameplayHintSelector, FocusManager.BOTTOM, button)
end

-- Local values: focusedButton
function ShopOthersFrame:onMenuAccept()
	local v27_ = FocusManager:getFocusedElement()
	if v27_.onClickCallback ~= nil then
		v27_:onClickCallback()
	end
end

function ShopOthersFrame:onOpenAnimalDealer()
	AnimalScreen.show(nil, nil, true)
end

function ShopOthersFrame:onOpenWardrobeScreen()
	g_gui:changeScreen(nil, WardrobeScreen)
end

function ShopOthersFrame:onOpenConstructionScreen()
	g_gui:changeScreen(nil, ConstructionScreen)
end

function ShopOthersFrame:onOpenFarmlandScreen()
	g_gui:changeScreen(nil, InGameMenu)
	g_inGameMenu:openFarmlandsScreen()
end

function ShopOthersFrame:onOpenVehicleOverview()
	g_gui:changeScreen(nil, InGameMenu)
	g_inGameMenu:onOpenVehicleOverview()
end
