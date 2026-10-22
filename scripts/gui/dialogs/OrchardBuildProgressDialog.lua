OrchardBuildProgressDialog = {}
local OrchardBuildProgressDialog_mt = Class(OrchardBuildProgressDialog, DialogElement)
function OrchardBuildProgressDialog.register()
	local dialog = OrchardBuildProgressDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/OrchardBuildProgressDialog.xml", "OrchardBuildProgressDialog", dialog)
	OrchardBuildProgressDialog.INSTANCE = dialog
	return dialog
end
function OrchardBuildProgressDialog.start(totalSteps, cancelCallback, cancelTarget)
	local dialog = OrchardBuildProgressDialog.INSTANCE
	if dialog == nil then
		return
	else
		dialog.doneSteps = 0
		dialog.totalSteps = math.max(totalSteps or 1, 1)
		dialog.cancelCallback = cancelCallback
		dialog.cancelTarget = cancelTarget
		dialog.isCancelling = false
		dialog:setDialogType(DialogElement.TYPE_LOADING)
		dialog:setIsCloseAllowed(false)
		g_gui:showDialog("OrchardBuildProgressDialog")
		dialog:updateBar()
	end
end
function OrchardBuildProgressDialog.finish()
	local dialog = OrchardBuildProgressDialog.INSTANCE
	if dialog ~= nil and dialog.isOpen then
		dialog.cancelCallback = nil
		dialog.cancelTarget = nil
		dialog.isCancelling = false
		g_gui:closeDialogByName("OrchardBuildProgressDialog")
	end
end
function OrchardBuildProgressDialog.getIsOpen()
	local dialog = OrchardBuildProgressDialog.INSTANCE
	if dialog == nil then
		return false
	else
		return dialog.isOpen
	end
end
function OrchardBuildProgressDialog.new(target, custom_mt)
	local self = DialogElement.new(target, custom_mt or OrchardBuildProgressDialog_mt)
	self.doneSteps = 0
	self.totalSteps = 1
	self.cancelCallback = nil
	self.cancelTarget = nil
	self.isOpen = false
	self.isCancelling = false
	return self
end
function OrchardBuildProgressDialog:onCreate(element)
	self:setDialogType(DialogElement.TYPE_LOADING)
end
function OrchardBuildProgressDialog:onOpen()
	OrchardBuildProgressDialog:superClass().onOpen(self)
	self.isOpen = true
	if self.dialogBg ~= nil then
		if g_gui:getIsMenuVisible() then
			self.dialogBg:applyProfile("dialogFullscreenBgWithMenu", true)
		else
			self.dialogBg:applyProfile("dialogFullscreenBgNoMenu", true)
		end
	end
	if self.dialogElement ~= nil then
		if g_gui:getIsMenuVisible() then
			self.dialogElement:applyProfile("dialogElementWithMenu", true)
		else
			self.dialogElement:applyProfile("dialogElementNoMenu", true)
		end
	end
	if self.cancelButton ~= nil then
		FocusManager:setFocus(self.cancelButton)
	end
	self:updateBar()
end
function OrchardBuildProgressDialog:onClose()
	OrchardBuildProgressDialog:superClass().onClose(self)
	self.isOpen = false
end
function OrchardBuildProgressDialog.setProgress(doneSteps, totalSteps)
	local dialog = OrchardBuildProgressDialog.INSTANCE
	if dialog == nil then
		return
	else
		if totalSteps ~= nil then
			dialog.totalSteps = math.max(totalSteps, 1)
		end
		dialog.doneSteps = math.clamp(doneSteps, 0, dialog.totalSteps)
		dialog:updateBar()
	end
end
function OrchardBuildProgressDialog:updateBar()
	local fraction = self.doneSteps / self.totalSteps
	if self.progressBar ~= nil and self.progressBar.parent ~= nil then
		self.progressBar.absSize[1] = self.progressBar.parent.absSize[1] * fraction
	end
	if self.progressText ~= nil then
		self.progressText:setText(string.format("%d%%", fraction * 100))
	end
end
function OrchardBuildProgressDialog:fireCancel()
	if self.isCancelling then
		return
	end
	self.isCancelling = true
	local callback = self.cancelCallback
	local target = self.cancelTarget
	self.cancelCallback = nil
	self.cancelTarget = nil
	if callback == nil then
		OrchardBuildProgressDialog.finish()
	elseif target ~= nil then
		callback(target)
	else
		callback()
	end
end
function OrchardBuildProgressDialog:onClickCancel()
	self:fireCancel()
end
function OrchardBuildProgressDialog:onClickBack(forceBack, usedMenuButton)
	if usedMenuButton then
		return true
	else
		self:fireCancel()
		return false
	end
end
