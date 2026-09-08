-- Local values: TransferMoneyDialog_mt
TransferMoneyDialog = {}
local TransferMoneyDialog_mt = Class(TransferMoneyDialog, DialogElement)
function TransferMoneyDialog.register()
	local v2_ = TransferMoneyDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/TransferMoneyDialog.xml", "TransferMoneyDialog", v2_)
	TransferMoneyDialog.INSTANCE = v2_
end

-- Local values: dialog
function TransferMoneyDialog.show(callback, target, farm)
	if TransferMoneyDialog.INSTANCE ~= nil then
		local v6_ = TransferMoneyDialog.INSTANCE
		v6_:setCallback(callback, target)
		v6_:setTargetFarm(farm)
		g_gui:showDialog("TransferMoneyDialog")
	end
end

-- Upvalues: TransferMoneyDialog_mt
-- Local values: self
function TransferMoneyDialog.new(target, custom_mt)
	-- upvalues: (copy) TransferMoneyDialog_mt
	local v9_ = DialogElement.new(target, custom_mt or TransferMoneyDialog_mt)
	v9_.isBackAllowed = false
	v9_.inputDelay = 250
	v9_.amount = 0
	v9_.optionElements = {}
	return v9_
end

-- Local values: newGui, farm, callback, target
function TransferMoneyDialog.createFromExistingGui(gui, guiName)
	local v11_ = TransferMoneyDialog.register()
	local v12_ = gui.farm
	local v13_ = gui.callbackFunc
	local v14_ = gui.target
	TransferMoneyDialog.show(v13_, v14_, v12_)
	return v11_
end

-- Local values: element, amount
function TransferMoneyDialog:onOpen()
	TransferMoneyDialog:superClass().onOpen(self)
	self.inputDelay = self.time + 250
	for v16_, v17_ in pairs(self.optionElements) do
		v16_.elements[3]:setText(g_i18n:formatMoney(v17_))
	end
	self.farm = g_farmManager:getFarmById(g_currentMission:getFarmId())
	self:updateAmount(0)
end

function TransferMoneyDialog:onClickActivate()
	if self.inputDelay >= self.time then
		return true
	end
	self:sendCallback(self.amount)
	return false
end

function TransferMoneyDialog:setCallback(callbackFunc, target)
	self.callbackFunc = callbackFunc
	self.target = target
end

function TransferMoneyDialog:setTargetFarm(farm)
	self.headerText:setText(string.format(g_i18n:getText("button_mp_transferMoney_dialogTitle"), farm.name))
	self.farm = farm
end

function TransferMoneyDialog:onClickBack(forceBack)
	if self.inputDelay >= self.time then
		return true
	end
	self:sendCallback(0)
	return false
end

function TransferMoneyDialog:sendCallback(value)
	if self.inputDelay >= self.time then
		return true
	end
	self:close()
	if self.callbackFunc ~= nil then
		if self.target == nil then
			self.callbackFunc(value)
		else
			self.callbackFunc(self.target, value)
		end
	end
	return false
end

-- Local values: amount
function TransferMoneyDialog:onClickLeft(element)
	self:updateAmount(-1 * self.optionElements[element.parent])
end

-- Local values: amount
function TransferMoneyDialog:onClickRight(element)
	self:updateAmount(self.optionElements[element.parent])
end

function TransferMoneyDialog:updateAmount(diff)
	local v33_ = self.amount + diff
	local v34_ = math.max(v33_, 0)
	local v35_ = self.farm
	self.amount = math.min(v34_, v35_:getBalance())
	self.amountText:setText(g_i18n:formatMoney(self.amount))
end

function TransferMoneyDialog:onCreateScroller(element, amount)
	local v39_ = tonumber(amount)
	self.optionElements[element] = v39_
end
