-- Local values: SavegameConflictDialog_mt
SavegameConflictDialog = {}
local SavegameConflictDialog_mt = Class(SavegameConflictDialog, MessageDialog)
function SavegameConflictDialog.register()
	local v2_ = SavegameConflictDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/SavegameConflictDialog.xml", "SavegameConflictDialog", v2_)
	SavegameConflictDialog.INSTANCE = v2_
end

-- Local values: dialog
function SavegameConflictDialog.show(startCallback, savegameScreenCallback, savegame, savegameId, showKeepBoth)
	if SavegameConflictDialog.INSTANCE ~= nil then
		local v8_ = SavegameConflictDialog.INSTANCE
		v8_:setFinishedCallback(startCallback, savegameScreenCallback)
		v8_:setSavegame(true, savegame)
		v8_:setCloudSavegame(savegame.conflictedMetadata)
		v8_:setSavegameId(savegameId)
		v8_:setShowKeepBoth(showKeepBoth == nil and true or showKeepBoth)
		g_gui:showDialog("SavegameConflictDialog")
	end
end

-- Upvalues: SavegameConflictDialog_mt
-- Local values: self
function SavegameConflictDialog.new(target, custom_mt)
	-- upvalues: (copy) SavegameConflictDialog_mt
	if custom_mt == nil then
		custom_mt = SavegameConflictDialog_mt
	end
	local v11_ = ColorPickerDialog.new(target, custom_mt)
	v11_.savegameId = 1
	return v11_
end

-- Local values: startCallback, savegameScreenCallback, savegame, savegameId, showKeepBoth
function SavegameConflictDialog.createFromExistingGui(gui, guiName)
	SavegameConflictDialog.register()
	local v13_ = gui.startCallback
	local v14_ = gui.savegameScreenCallback
	local v15_ = gui.savegame
	local v16_ = gui.savegameId
	local v17_ = gui.showKeepBoth
	SavegameConflictDialog.show(v13_, v14_, v15_, v16_, v17_)
end

function SavegameConflictDialog:setFinishedCallback(startCallback, savegameScreenCallback)
	self.startCallback = startCallback
	self.savegameScreenCallback = savegameScreenCallback
end

-- Local values: savegame
function SavegameConflictDialog:setLocalSavegame(metadata)
	self:setSavegame(true, (self:getSavegameFromMetadata(metadata)))
end

-- Local values: savegame
function SavegameConflictDialog:setCloudSavegame(metadata)
	self:setSavegame(false, (self:getSavegameFromMetadata(metadata)))
end

-- Local values: savegame, xmlFile
function SavegameConflictDialog:getSavegameFromMetadata(metadata)
	local v26_ = FSCareerMissionInfo.new("", nil, 1)
	v26_:loadDefaults()
	if metadata ~= "" then
		local v27_ = loadXMLFileFromMemory("careerSavegameXML", metadata)
		if v27_ ~= nil then
			if not v26_:loadFromXML(v27_) then
				v26_:loadDefaults()
			end
			delete(v27_)
		end
	end
	return v26_
end

-- Local values: playTimeHoursF, playTimeHours, playTimeMinutes, timePlayed
function SavegameConflictDialog:setSavegame(isLocal, savegame)
	if savegame ~= nil then
		local v31_ = savegame.playTime / 60 + 0.0001
		local v32_ = math.floor(v31_)
		local v33_ = (v31_ - v32_) * 60
		local v34_ = math.floor(v33_)
		local v35_ = string.format("%02d:%02d", v32_, v34_)
		if isLocal then
			self.local_gameName:setText(savegame.savegameName)
			self.local_money:setText(savegame.money)
			self.local_timePlayed:setText(v35_)
			self.local_createDate:setText(savegame.saveDateFormatted)
		else
			self.cloud_gameName:setText(savegame.savegameName)
			self.cloud_money:setText(savegame.money)
			self.cloud_timePlayed:setText(v35_)
			self.cloud_createDate:setText(savegame.saveDateFormatted)
		end
	end
	self.savegame = savegame
end

function SavegameConflictDialog:setSavegameId(savegameId)
	self.savegameId = savegameId
end

function SavegameConflictDialog:setShowKeepBoth(showKeepBoth)
	self.keepBoth:setDisabled(showKeepBoth ~= nil and not showKeepBoth and true or false)
	self.showKeepBoth = showKeepBoth
end

function SavegameConflictDialog:onClickKeepLocal()
	g_savegameController:resolveConflict(self.savegameId, SaveGameResolvePolicy.KEEP_LOCAL)
	self:close()
	if self.startCallback ~= nil then
		local v41_ = self.startCallback.callback
		local v42_ = self.startCallback.target
		local v43_ = self.startCallback.extraAttributes
		v41_(v42_, unpack(v43_))
	end
end

function SavegameConflictDialog:onClickKeepRemote()
	g_savegameController:resolveConflict(self.savegameId, SaveGameResolvePolicy.KEEP_REMOTE)
	self:close()
	if self.startCallback ~= nil then
		local v45_ = self.startCallback.callback
		local v46_ = self.startCallback.target
		local v47_ = self.startCallback.extraAttributes
		v45_(v46_, unpack(v47_))
	end
end

function SavegameConflictDialog:onClickKeepBoth()
	self:close()
	if g_savegameController:resolveConflict(self.savegameId, SaveGameResolvePolicy.KEEP_BOTH) and self.savegameScreenCallback ~= nil then
		local v49_ = self.savegameScreenCallback.callback
		local v50_ = self.savegameScreenCallback.target
		local v51_ = self.savegameScreenCallback.extraAttributes
		v49_(v50_, unpack(v51_))
	end
end
SavegameConflictDialog.L10N_SYMBOL = {
	["TITLE_CREATE_FARM"] = "ui_createNewFarm",
	["TITLE_EDIT_FARM_TEMPLATE"] = "ui_editFarm",
	["DEFAULT_FARM_NAME"] = "ui_defaultFarmName",
	["BUTTON_CREATE"] = "button_mp_createFarm",
	["BUTTON_CONFIRM"] = "button_confirm"
}
