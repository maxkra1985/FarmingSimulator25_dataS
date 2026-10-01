SavegameMigrationDialog = {}
local SavegameMigrationDialog_mt = Class(SavegameMigrationDialog, YesNoDialog)
function SavegameMigrationDialog.register()
	local savegameMigrationDialog = SavegameMigrationDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/SavegameMigrationDialog.xml", "SavegameMigrationDialog", savegameMigrationDialog)
	SavegameMigrationDialog.INSTANCE = savegameMigrationDialog
end
function SavegameMigrationDialog.show(callback, target)
	if SavegameMigrationDialog.INSTANCE ~= nil then
		local dialog = SavegameMigrationDialog.INSTANCE
		dialog:setCallback(callback, target)
		g_gui:showDialog("SavegameMigrationDialog")
	end
end
function SavegameMigrationDialog.new(target, custom_mt)
	local self = TextInputDialog.new(target, custom_mt or SavegameMigrationDialog_mt)
	return self
end
function SavegameMigrationDialog.createFromExistingGui(gui, guiName)
	SavegameMigrationDialog.register()
	local callback = gui.callback
	local target = gui.target
	SavegameMigrationDialog.show(callback, target)
end
