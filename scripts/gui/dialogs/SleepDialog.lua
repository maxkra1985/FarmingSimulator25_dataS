-- Local values: SleepDialog_mt
SleepDialog = {}
SleepDialog.MIN_TARGET_TIME = 0
SleepDialog.MAX_TARGET_TIME = 23.5
SleepDialog.DEFAULT_TARGET_TIME = 16
local SleepDialog_mt = Class(SleepDialog, YesNoDialog)
function SleepDialog.register()
	local v2_ = SleepDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/SleepDialog.xml", "SleepDialog", v2_)
	SleepDialog.INSTANCE = v2_
end

-- Local values: dialog
function SleepDialog.show(text, callback, target)
	if SleepDialog.INSTANCE ~= nil then
		local v6_ = SleepDialog.INSTANCE
		v6_:setCallback(callback, target)
		v6_:setTitle(g_i18n:getText("ui_inGameSleep"))
		v6_:setText(text)
		g_gui:showDialog("SleepDialog")
	end
end

-- Upvalues: SleepDialog_mt
-- Local values: self
function SleepDialog.new(target, custom_mt)
	-- upvalues: (copy) SleepDialog_mt
	local v9_ = YesNoDialog.new(target, custom_mt or SleepDialog_mt)
	v9_.selectedTargetTime = SleepDialog.DEFAULT_TARGET_TIME
	v9_.maxDuration = SleepDialog.DEFAULT_MAX_DURATION
	return v9_
end

-- Local values: text, callback, target
function SleepDialog.createFromExistingGui(gui, guiName)
	SleepDialog.register()
	local v11_ = gui.sleepText
	local v12_ = gui.callbackFunc
	local v13_ = gui.target
	SleepDialog.show(v11_, v12_, v13_)
end

function SleepDialog:onOpen()
	SleepDialog:superClass().onOpen(self)
	self:updateOptions()
end

function SleepDialog:onClose()
	SleepDialog:superClass().onClose(self)
	self:setDialogType(DialogElement.TYPE_QUESTION)
	self:setTitle(nil)
	self:setText(nil)
	self:setButtonTexts(self.defaultYesText, self.defaultNoText)
end

function SleepDialog:sendCallback(value)
	if self.inputDelay >= self.time then
		return true
	end
	self:close()
	if self.callbackFunc ~= nil then
		if self.target == nil then
			self.callbackFunc(value, self.selectedTargetTime)
		else
			self.callbackFunc(self.target, value, self.selectedTargetTime * 0.5)
		end
	end
	return false
end

-- Local values: i
function SleepDialog:updateOptions()
	self.targetTimes = {}
	for v19_ = SleepDialog.MIN_TARGET_TIME, SleepDialog.MAX_TARGET_TIME, 0.5 do
		local v20_ = self.targetTimes
		local v21_ = Utils.formatTime
		local v22_ = v19_ * 60
		table.insert(v20_, v21_(v22_))
	end
	self.targetTimeElement:setTexts(self.targetTimes)
	self.targetTimeElement:setState(self.selectedTargetTime - SleepDialog.MIN_TARGET_TIME + 1)
end

function SleepDialog:onClickTargetTime(state)
	self.selectedTargetTime = state - 1 + SleepDialog.MIN_TARGET_TIME
end
