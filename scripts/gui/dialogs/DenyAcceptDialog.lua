-- Local values: DenyAcceptDialog_mt
DenyAcceptDialog = {}
local DenyAcceptDialog_mt = Class(DenyAcceptDialog, YesNoDialog)
function DenyAcceptDialog.register()
	local v2_ = DenyAcceptDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/DenyAcceptDialog.xml", "DenyAcceptDialog", v2_)
	DenyAcceptDialog.INSTANCE = v2_
end

-- Local values: dialog
function DenyAcceptDialog.show(callback, target, connection, nickname, platformId, splitShapesWithinLimits)
	if DenyAcceptDialog.INSTANCE ~= nil then
		local v9_ = DenyAcceptDialog.INSTANCE
		v9_:setCallback(callback, target)
		v9_:setConnection(connection, nickname, platformId, splitShapesWithinLimits)
		g_gui:showDialog("DenyAcceptDialog")
	end
end

-- Upvalues: DenyAcceptDialog_mt
-- Local values: self
function DenyAcceptDialog.new(target, custom_mt)
	-- upvalues: (copy) DenyAcceptDialog_mt
	return YesNoDialog.new(target, custom_mt or DenyAcceptDialog_mt)
end

-- Local values: newGui, callback, target, connection, nickname, platformId, splitShapesWithinLimits
function DenyAcceptDialog.createFromExistingGui(gui, guiName)
	local v14_ = DenyAcceptDialog.new(nil, nil)
	g_gui:loadGui(gui.xmlFilename, guiName, v14_)
	local v15_ = gui.callbackFunc
	local v16_ = gui.target
	local v17_ = gui.connection
	local v18_ = gui.nickname
	local v19_ = gui.platformId
	local v20_ = gui.splitShapesWithinLimits
	DenyAcceptDialog.show(v15_, v16_, v17_, v18_, v19_, v20_)
	return v14_
end

function DenyAcceptDialog:sendCallback(isDenied, isAlwaysDenied)
	if self.inputDelay >= self.time then
		return true
	end
	self:close()
	if self.callbackFunc ~= nil then
		if self.target == nil then
			self.callbackFunc(self.connection, isDenied, isAlwaysDenied)
		else
			self.callbackFunc(self.target, self.connection, isDenied, isAlwaysDenied)
		end
	end
	return false
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
