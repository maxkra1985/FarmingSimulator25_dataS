DenyAcceptDialog = {}
local DenyAcceptDialog_mt = Class(DenyAcceptDialog, YesNoDialog)
function DenyAcceptDialog.register()
	local denyAcceptDialog = DenyAcceptDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/DenyAcceptDialog.xml", "DenyAcceptDialog", denyAcceptDialog)
	DenyAcceptDialog.INSTANCE = denyAcceptDialog
end
function DenyAcceptDialog.show(callback, target, connection, nickname, platformId, splitShapesWithinLimits)
	if DenyAcceptDialog.INSTANCE ~= nil then
		local dialog = DenyAcceptDialog.INSTANCE
		dialog:setCallback(callback, target)
		dialog:setConnection(connection, nickname, platformId, splitShapesWithinLimits)
		g_gui:showDialog("DenyAcceptDialog")
	end
end
function DenyAcceptDialog.new(target, custom_mt)
	local self = YesNoDialog.new(target, custom_mt or DenyAcceptDialog_mt)
	return self
end
function DenyAcceptDialog.createFromExistingGui(gui, guiName)
	local newGui = DenyAcceptDialog.new(nil, nil)
	g_gui:loadGui(gui.xmlFilename, guiName, newGui)
	local callback = gui.callbackFunc
	local target = gui.target
	local connection = gui.connection
	local nickname = gui.nickname
	local platformId = gui.platformId
	local splitShapesWithinLimits = gui.splitShapesWithinLimits
	DenyAcceptDialog.show(callback, target, connection, nickname, platformId, splitShapesWithinLimits)
	return newGui
end
function DenyAcceptDialog:sendCallback(isDenied, isAlwaysDenied)
	if self.inputDelay < self.time then
		self:close()
		if self.callbackFunc ~= nil then
			if self.target ~= nil then
				self.callbackFunc(self.target, self.connection, isDenied, isAlwaysDenied)
			else
				self.callbackFunc(self.connection, isDenied, isAlwaysDenied)
			end
		end
		return false
	else
		return true
	end
end
function DenyAcceptDialog:onClickAccept()
	self:sendCallback(false, false)
	return false
end
function DenyAcceptDialog:onClickBack(forceBack)
	self:onClickRefuse()
end
function DenyAcceptDialog:onClickRefuse(forceBack)
	self:sendCallback(true, false)
	return false
end
function DenyAcceptDialog:onClickDenyAlways()
	self:sendCallback(true, true)
	return false
end
function DenyAcceptDialog:setConnection(connection, nickname, platformId, splitShapesWithinLimits)
	if connection ~= nil then
		self.connection = connection
	end
	self:setTitle(nickname)
	self.platformIcon:setPlatformId(platformId)
	self.platformIcon.parent:invalidateLayout()
	self.dialogWarning:setVisible(not splitShapesWithinLimits)
	self.nickname = nickname
	self.platformId = platformId
	self.splitShapesWithinLimits = splitShapesWithinLimits
end
