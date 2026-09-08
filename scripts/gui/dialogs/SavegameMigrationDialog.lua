-- Local values: SavegameMigrationDialog_mt
SavegameMigrationDialog = {}
local SavegameMigrationDialog_mt = Class(SavegameMigrationDialog, YesNoDialog)
function SavegameMigrationDialog.register()
	local v2_ = SavegameMigrationDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/SavegameMigrationDialog.xml", "SavegameMigrationDialog", v2_)
	SavegameMigrationDialog.INSTANCE = v2_
end

-- Local values: dialog
function SavegameMigrationDialog.show(callback, target)
	if SavegameMigrationDialog.INSTANCE ~= nil then
		SavegameMigrationDialog.INSTANCE:setCallback(callback, target)
		g_gui:showDialog("SavegameMigrationDialog")
	end
end

-- Upvalues: SavegameMigrationDialog_mt
-- Local values: self
function SavegameMigrationDialog.new(target, custom_mt)
	-- upvalues: (copy) SavegameMigrationDialog_mt
	return TextInputDialog.new(target, custom_mt or SavegameMigrationDialog_mt)
end

-- Local values: callback, target
function SavegameMigrationDialog.createFromExistingGui(gui, guiName)
	SavegameMigrationDialog.register()
	local v8_ = gui.callback
	local v9_ = gui.target
	SavegameMigrationDialog.show(v8_, v9_)
end
