-- Local values: RiceFieldDialog_mt
RiceFieldDialog = {}
local RiceFieldDialog_mt = Class(RiceFieldDialog, InfoDialog)
function RiceFieldDialog.register()
	local v2_ = RiceFieldDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/RiceFieldDialog.xml", "RiceFieldDialog", v2_)
	RiceFieldDialog.INSTANCE = v2_
end

-- Local values: dialog, areaSqm, fillLevelCbm, maxWaterHeight, fillHeightMeters, fillHeightPercentage
function RiceFieldDialog.show(callback, riceFieldPlaceable, title, riceFieldIndex)
	if RiceFieldDialog.INSTANCE ~= nil then
		local v7_ = RiceFieldDialog.INSTANCE
		v7_.headerTitle:setText(title)
		v7_:setCallback(callback, riceFieldPlaceable)
		v7_:setButtonAction(InputAction.MENU_BACK)
		v7_.args = {}
		v7_.args.isAccepted = false
		v7_.riceFieldPlaceable = riceFieldPlaceable
		v7_.riceFieldIndex = riceFieldIndex
		local v8_ = riceFieldPlaceable:getArea(riceFieldIndex)
		local v9_ = riceFieldPlaceable:getWaterFillLevel(riceFieldIndex) / 1000
		local v10_ = riceFieldPlaceable:getMaxWaterHeight()
		local v11_ = v9_ / v8_ / v10_ * 100
		v7_.buttonEmpty:setDisabled(true)
		v7_.buttonFill:setDisabled(true)
		if g_server == nil then
			g_messageCenter:subscribe(PlaceableRiceFieldStateEvent, v7_.onRiceFieldStatusResult, v7_)
			g_client:getServerConnection():sendEvent(PlaceableRiceFieldStateEvent.new(riceFieldPlaceable, riceFieldIndex))
		else
			riceFieldPlaceable:getRiceFieldState(riceFieldIndex, v7_.onRiceFieldStatusResult, v7_)
		end
		v7_.textFieldNr:setText(riceFieldIndex)
		v7_.textFieldSize:setText(g_i18n:formatArea(v8_ / 10000, 2))
		v7_.textCropType:setText("")
		v7_.textWaterLevel:setText(g_i18n:formatNumber(v11_, 0) .. " %")
		v7_.warning:setText("")
		v7_.warning:setVisible(false)
		g_gui:showDialog("RiceFieldDialog")
	end
end

-- Upvalues: RiceFieldDialog_mt
-- Local values: self
function RiceFieldDialog.new(target, custom_mt)
	-- upvalues: (copy) RiceFieldDialog_mt
	local v14_ = InfoDialog.new(target, custom_mt or RiceFieldDialog_mt)
	v14_.areButtonsDisabled = false
	return v14_
end

-- Local values: callback, target, title, riceFieldIndex
function RiceFieldDialog.createFromExistingGui(gui, guiName)
	RiceFieldDialog.register()
	local v16_ = gui.callbackFunc
	local v17_ = gui.target
	local v18_ = gui.headerTitle.text
	local v19_ = gui.riceFieldIndex
	RiceFieldDialog.show(v16_, v17_, v18_, v19_)
end

function RiceFieldDialog:onOpen()
	RiceFieldDialog:superClass().onOpen(self)
	if self.buttonEmpty:getIsDisabled() then
		FocusManager:setFocus(self.buttonFill)
	end
end

function RiceFieldDialog:onClose()
	g_messageCenter:unsubscribe(PlaceableRiceFieldStateEvent, self)
	self.riceFieldPlaceable = nil
	RiceFieldDialog:superClass().onClose(self)
end

-- Local values: currentWaterLevelLiters, fruitType, fieldMaxWaterLiters, minWaterLiters, maxWaterLiters, targetWaterLevel, warningText
function RiceFieldDialog:onRiceFieldStatusResult(maxFruitIndex, maxStage)
	g_messageCenter:unsubscribe(PlaceableRiceFieldStateEvent, self)
	local v25_ = self.riceFieldPlaceable:getWaterFillLevelPerSqm(self.riceFieldIndex)
	if maxFruitIndex == FruitType.UNKNOWN then
		self.textCropType:setText("-")
		if v25_ == 0 then
			self.buttonFill:setDisabled(false)
			self.targetWaterPercentage = 0.65
		else
			self.buttonEmpty:setDisabled(false)
			self.targetWaterPercentage = 0
		end
	else
		local v26_ = g_fruitTypeManager:getFruitTypeByIndex(maxFruitIndex)
		local v27_ = self.riceFieldPlaceable:getMaxWaterHeight() * 1000
		local v28_ = v26_.minWaterLitersPerSqm and (v26_.minWaterLitersPerSqm[maxStage] or 0) or 0
		local v29_
		if v26_.maxWaterLitersPerSqm then
			v29_ = v26_.maxWaterLitersPerSqm[maxStage] or v27_
		else
			v29_ = v27_
		end
		self.targetWaterPercentage = (v28_ + v29_) / 2 / v27_
		self.textCropType:setText(v26_.fillType.title)
		self.buttonEmpty:setDisabled(v25_ <= v29_)
		self.buttonFill:setDisabled(v28_ <= v25_)
		local v30_ = nil
		if v29_ < v25_ then
			v30_ = g_i18n:getText("ui_riceFieldWarningWaterLevelTooHigh")
		elseif v25_ < v28_ then
			v30_ = g_i18n:getText("ui_riceFieldWarningWaterLevelTooLow")
		end
		if v30_ == nil then
			self.warning:setVisible(false)
		else
			self.warning:setText(v30_)
			self.warning:setVisible(true)
		end
	end
end

function RiceFieldDialog:setButtonDisabled(disabled)
	self.messageBackground:setVisible(disabled)
	self.areButtonsDisabled = disabled
end

function RiceFieldDialog:onClickEmpty()
	self.args.fillLevelPercentage = self.targetWaterPercentage
	self.args.isAccepted = true
	self:onClickOk()
end

function RiceFieldDialog:onClickFill()
	self.args.fillLevelPercentage = self.targetWaterPercentage
	self.args.isAccepted = true
	self:onClickOk()
end
