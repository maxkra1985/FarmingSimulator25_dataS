-- Local values: AnimalTradingDialog_mt
AnimalTradingDialog = {}
local AnimalTradingDialog_mt = Class(AnimalTradingDialog, MessageDialog)
function AnimalTradingDialog.register()
	local v2_ = AnimalTradingDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/AnimalTradingDialog.xml", "AnimalTradingDialog", v2_)
	AnimalTradingDialog.INSTANCE = v2_
end

-- Local values: dialog
function AnimalTradingDialog.show(callback, target, animalIndex, isHorse, infoIcon, maxAnimals, isBuying, selectionState, getPriceFunc, buyText, sellText)
	if AnimalTradingDialog.INSTANCE ~= nil then
		local v14_ = AnimalTradingDialog.INSTANCE
		v14_:setCallback(callback, target)
		v14_:setAnimalIndex(animalIndex)
		v14_:setIsHorse(isHorse)
		v14_:setInfoIcon(infoIcon)
		v14_:setMaxAnimals(maxAnimals)
		v14_:setIsBuying(isBuying)
		v14_:setSelectionState(selectionState)
		v14_:setGetPriceFunc(getPriceFunc)
		v14_:setButtonTexts(buyText, sellText, nil)
		g_gui:showDialog("AnimalTradingDialog")
	end
end

-- Upvalues: AnimalTradingDialog_mt
-- Local values: self
function AnimalTradingDialog.new(target, custom_mt)
	-- upvalues: (copy) AnimalTradingDialog_mt
	local v17_ = YesNoDialog.new(target, custom_mt or AnimalTradingDialog_mt)
	v17_.inputDelay = 250
	return v17_
end

-- Local values: newGui, callback, getPrice, target, animalIndex, isHorse, infoIcon, maxAnimals, selectionState, buying
function AnimalTradingDialog.createFromExistingGui(gui, guiName)
	local v20_ = AnimalTradingDialog.new()
	g_gui:loadGui(gui.xmlFilename, guiName, v20_)
	local v21_ = gui.callbackFunc
	local v22_ = gui.getPrice
	local v23_ = gui.target
	local v24_ = gui.animalIndex
	local v25_ = gui.target.isHorse
	local v26_ = gui.infoIcon
	local v27_ = gui.maxAnimals
	local v28_ = gui.selectionState
	local v29_ = gui.buying
	AnimalTradingDialog.show(v21_, v23_, v24_, v25_, v26_, v27_, v29_, v28_, v22_)
	return v20_
end

function AnimalTradingDialog:onCreate()
	AnimalTradingDialog:superClass().onCreate(self)
	self.numAnimalsElement:setTexts({ "1" })
	self.defaultBuyText = self.buyButton.text
	self.defaultSellText = self.sellButton.text
	self.defaultCancelText = self.backButton.text
end

function AnimalTradingDialog:onOpen()
	AnimalTradingDialog:superClass().onOpen(self)
	self.inputDelay = self.time + 250
	self:updatePrice()
end

function AnimalTradingDialog:onClose()
	self:setDialogType(DialogElement.TYPE_QUESTION)
	self:setText(nil)
	self:setButtonTexts(self.defaultYesText, self.defaultNoText)
	AnimalTradingDialog:superClass().onClose(self)
end

-- Local values: numAnimals
function AnimalTradingDialog:sendCallback(tradeAccepted)
	if self.inputDelay >= self.time then
		return true
	end
	self:close()
	if self.callbackFunc ~= nil then
		local v35_ = self.numAnimalsElement:getState()
		if self.target == nil then
			self.callbackFunc(self.buying, tradeAccepted, self.animalIndex, v35_)
		else
			self.callbackFunc(self.target, self.buying, tradeAccepted, self.animalIndex, v35_)
		end
	end
	return false
end

function AnimalTradingDialog:setCallback(callbackFunc, target, args)
	self.callbackFunc = callbackFunc
	self.target = target
	self.callbackArgs = args
end

function AnimalTradingDialog:setButtonTexts(buyText, sellText, cancelText)
	self.buyButton:setText(Utils.getNoNil(buyText, self.defaultBuyText))
	self.sellButton:setText(Utils.getNoNil(sellText, self.defaultSellText))
	self.backButton:setText(Utils.getNoNil(cancelText, self.defaultCancelText))
end

function AnimalTradingDialog:setAnimalIndex(animalIndex)
	self.animalIndex = animalIndex
end

function AnimalTradingDialog:setIsHorse(isHorse)
	if isHorse then
		self.numAnimalsElement:setVisible(false)
	else
		self.numAnimalsElement:setVisible(true)
		FocusManager:setFocus(self.numAnimalsElement)
	end
end

function AnimalTradingDialog:setInfoIcon(infoIcon)
	self.infoIcon:setImageFilename(infoIcon.overlay.filename)
end

-- Local values: texts, i
function AnimalTradingDialog:setMaxAnimals(maxAnimals)
	self.maxAnimals = maxAnimals
	local v52_ = {}
	for v53_ = 1, self.maxAnimals do
		local v54_ = tostring(v53_)
		table.insert(v52_, v54_)
	end
	self.numAnimalsElement:setTexts(v52_)
	self.numAnimalsElement:setState(1)
end

function AnimalTradingDialog:setIsBuying(buying)
	self.buying = buying
	self.buyButton:setVisible(self.buying)
	self.sellButton:setVisible(not self.buying)
end

function AnimalTradingDialog:setSelectionState(selectionState)
	self.selectionState = selectionState
end

function AnimalTradingDialog:setGetPriceFunc(getPriceFunc)
	self.getPrice = getPriceFunc
end

function AnimalTradingDialog:setTitle() end

-- Local values: hasCosts, price, fee, total
function AnimalTradingDialog:updatePrice()
	local v62_, v63_, v64_, v65_ = self.getPrice(self.target, self.numAnimalsElement:getState())
	self.infoPrice:setValue(0)
	self.infoFee:setValue(0)
	self.infoTotal:setValue(0)
	self.infoPrice:setFormat(v62_ and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
	self.infoFee:setFormat(v62_ and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
	self.infoTotal:setFormat(v62_ and TextElement.FORMAT.CURRENCY or TextElement.FORMAT.NONE)
	self.infoPrice:setValue(v62_ and v63_ and v63_ or "-")
	self.infoFee:setValue(v62_ and v64_ and v64_ or "-")
	self.infoTotal:setValue(v62_ and v65_ and v65_ or "-")
end

-- Local values: texts, i
function AnimalTradingDialog:onClickNumAnimals(state)
	local v67_ = {}
	for v68_ = 1, self.maxAnimals do
		local v69_ = tostring(v68_)
		table.insert(v67_, v69_)
	end
	self.numAnimalsElement:setTexts(v67_)
	self:updatePrice()
end

function AnimalTradingDialog:onBuy(sender)
	self:sendCallback(true)
end

function AnimalTradingDialog:onSell(sender)
	self:sendCallback(true)
end

function AnimalTradingDialog:onClickBack(sender)
	self:sendCallback(false)
end
