-- Local values: VoteDialog_mt
VoteDialog = {}
local VoteDialog_mt = Class(VoteDialog, MessageDialog)
function VoteDialog.register()
	local v2_ = VoteDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/VoteDialog.xml", "VoteDialog", v2_)
	VoteDialog.INSTANCE = v2_
end

-- Local values: dialog
function VoteDialog.show(callback, target, value)
	if VoteDialog.INSTANCE ~= nil then
		local v6_ = VoteDialog.INSTANCE
		v6_:setCallback(callback, target)
		v6_:setValue(value)
		g_gui:showDialog("VoteDialog")
	end
end

-- Upvalues: VoteDialog_mt
-- Local values: self
function VoteDialog.new(target, custom_mt)
	-- upvalues: (copy) VoteDialog_mt
	local v9_ = MessageDialog.new(target, custom_mt or VoteDialog_mt)
	v9_.value = 0
	v9_.isBackAllowed = true
	v9_.inputDelay = 250
	return v9_
end

-- Local values: callback, target, value
function VoteDialog.createFromExistingGui(gui, guiName)
	VoteDialog.register()
	local v11_ = gui.callbackFunc
	local v12_ = gui.target
	local v13_ = gui.value
	VoteDialog.show(v11_, v12_, v13_)
end

function VoteDialog:onGuiSetupFinished()
	VoteDialog:superClass().onGuiSetupFinished(self)
	FocusManager:linkElements(self.stars[1], FocusManager.LEFT, nil)
end

function VoteDialog:onClickBack(forceBack, usedMenuButton)
	self:close()
	if self.callback ~= nil then
		if self.target == nil then
			self.callback(self.args, nil)
		else
			self.callback(self.target, self.args, nil)
		end
	end
	return false
end

function VoteDialog:onClickOk()
	if self.value ~= 0 then
		if self.inputDelay >= self.time then
			return true
		end
		self:close()
		if self.callback ~= nil then
			if self.target == nil then
				self.callback(self.value)
			else
				self.callback(self.target, self.value)
			end
		end
		return false
	end
end

function VoteDialog:setCallback(callback, target)
	self.callback = callback
	self.target = target
end

function VoteDialog:setValue(value)
	self.value = value or 5
	self:setStars(self.value)
	self.okButton:setDisabled(value == 0)
	FocusManager:setFocus(self.stars[value])
end

-- Local values: focus
function VoteDialog:onStarHighlight(element)
	self:setStars((self:getValueForElement(element)))
end

function VoteDialog:onStarHighlightRemove()
	self:setStars(self.value)
end

-- Local values: focus
function VoteDialog:onStarFocus(element)
	self:setValue((self:getValueForElement(element)))
end

function VoteDialog:onStarClick(element)
	self:setValue(self:getValueForElement(element))
end

-- Local values: i, elem
function VoteDialog:getValueForElement(element)
	for v31_, v32_ in ipairs(self.stars) do
		if element == v32_ then
			return v31_
		end
	end
	return nil
end

-- Local values: i, i
function VoteDialog:setStars(value)
	for v35_ = 1, value do
		self.stars[v35_]:applyProfile("fs25_voteDialogStarButtonActive")
	end
	for v36_ = value + 1, 5 do
		self.stars[v36_]:applyProfile("fs25_voteDialogStarButton")
	end
end
