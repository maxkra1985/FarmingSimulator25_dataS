SleepDialog = {}
SleepDialog.MIN_TARGET_TIME = 0
SleepDialog.MAX_TARGET_TIME = 23.5
SleepDialog.DEFAULT_TARGET_TIME = 16
local SleepDialog_mt = Class(SleepDialog, YesNoDialog)
function SleepDialog.register()
	local sleepDialog = SleepDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/SleepDialog.xml", "SleepDialog", sleepDialog)
	SleepDialog.INSTANCE = sleepDialog
end
function SleepDialog.show(text, callback, target)
	if SleepDialog.INSTANCE ~= nil then
		local dialog = SleepDialog.INSTANCE
		dialog:setCallback(callback, target)
		dialog:setTitle(g_i18n:getText("ui_inGameSleep"))
		dialog:setText(text)
		g_gui:showDialog("SleepDialog")
	end
end
function SleepDialog.new(target, custom_mt)
	local self = YesNoDialog.new(target, custom_mt or SleepDialog_mt)
	self.selectedTargetTime = SleepDialog.DEFAULT_TARGET_TIME
	self.maxDuration = SleepDialog.DEFAULT_MAX_DURATION
	return self
end
function SleepDialog.createFromExistingGui(gui, guiName)
	SleepDialog.register()
	local text = gui.sleepText
	local callback = gui.callbackFunc
	local target = gui.target
	SleepDialog.show(text, callback, target)
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
	if self.inputDelay < self.time then
		self:close()
		if self.callbackFunc ~= nil then
			if self.target ~= nil then
				self.callbackFunc(self.target, value, self.selectedTargetTime * 0.5)
			else
				self.callbackFunc(value, self.selectedTargetTime)
			end
		end
		return false
	else
		return true
	end
end
function SleepDialog:updateOptions()
	self.targetTimes = {}
	for i = SleepDialog.MIN_TARGET_TIME, SleepDialog.MAX_TARGET_TIME, 0.5 do
		table.insert(self.targetTimes, Utils.formatTime(i * 60))
	end
	self.targetTimeElement:setTexts(self.targetTimes)
	self.targetTimeElement:setState(self.selectedTargetTime - SleepDialog.MIN_TARGET_TIME + 1)
end
function SleepDialog:onClickTargetTime(state)
	self.selectedTargetTime = state - 1 + SleepDialog.MIN_TARGET_TIME
end
