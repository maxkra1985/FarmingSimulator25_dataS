-- Local values: GameRateDialog_mt
GameRateDialog = {}
local GameRateDialog_mt = Class(GameRateDialog, MessageDialog)
function GameRateDialog.register()
	local v2_ = GameRateDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/GameRateDialog.xml", "GameRateDialog", v2_)
end
function GameRateDialog.show()
	g_gui:showDialog("GameRateDialog")
end

-- Upvalues: GameRateDialog_mt
-- Local values: self
function GameRateDialog.new(target, custom_mt)
	-- upvalues: (copy) GameRateDialog_mt
	local v5_ = MessageDialog.new(target, custom_mt or GameRateDialog_mt)
	v5_.isBackAllowed = false
	v5_.inputDelay = 250
	v5_.value = 0
	return v5_
end

function GameRateDialog.createFromExistingGui(gui, guiName)
	GameRateDialog.register()
	GameRateDialog.show()
end

function GameRateDialog:onOpen()
	GameRateDialog:superClass().onOpen(self)
	self:setValue(0)
	FocusManager:setFocus(self.ratingLayout)
end

function GameRateDialog:onClose()
	GameRateDialog:superClass().onClose(self)
end

function GameRateDialog:onClickOk()
	self:close()
	openWebFile(Platform.urlRating, "rating=" .. self.value)
	return true
end

function GameRateDialog:onClickBack()
	self:close()
	return true
end

function GameRateDialog:onStarHighlight(element)
	FocusManager:setFocus(element)
end

function GameRateDialog:onStarHighlightRemove()
	self:setStars(self.value)
end

-- Local values: focus
function GameRateDialog:onStarFocus(element)
	self:setValue((self:getValueForElement(element)))
end

function GameRateDialog:onStarClick(element)
	self:setValue(self:getValueForElement(element))
end

function GameRateDialog:setValue(value)
	self.value = value or 5
	self:setStars(self.value)
	if self.stars ~= 0 then
		FocusManager:setFocus(self.stars[value])
	end
	self.okButton:setDisabled(self.value == 0)
end

-- Local values: i, i
function GameRateDialog:setStars(value)
	for v20_ = 1, value do
		self.stars[v20_]:applyProfile("gameRateDialogStarButtonActive")
	end
	for v21_ = value + 1, 5 do
		self.stars[v21_]:applyProfile("gameRateDialogStarButton")
	end
end

-- Local values: i, elem
function GameRateDialog:getValueForElement(element)
	for v24_, v25_ in ipairs(self.stars) do
		if element == v25_ then
			return v24_
		end
	end
	return nil
end
