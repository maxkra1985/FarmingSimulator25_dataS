ESRBUpdateDialog = {}
local ESRBUpdateDialog_mt = Class(ESRBUpdateDialog, InfoDialog)
function ESRBUpdateDialog.register()
	local esrbUpdateDialog = ESRBUpdateDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/InfoDialog.xml", "ESRBUpdateDialog", esrbUpdateDialog)
	ESRBUpdateDialog.INSTANCE = esrbUpdateDialog
end
function ESRBUpdateDialog.show(text, callback, target)
	if ESRBUpdateDialog.INSTANCE ~= nil then
		local dialog = ESRBUpdateDialog.INSTANCE
		dialog:setCallback(callback, target)
		dialog:setText(text)
		g_gui:showDialog("ESRBUpdateDialog")
	end
end
function ESRBUpdateDialog.new(target, custom_mt)
	local self = InfoDialog.new(target, custom_mt or ESRBUpdateDialog_mt)
	return self
end
function ESRBUpdateDialog:update(dt)
	ESRBUpdateDialog:superClass().update(self, dt)
	for d = 1, getNumOfGamepads() do
		for i = 1, Input.MAX_NUM_BUTTONS do
			local isDown = 0 < getInputButton(i - 1, d - 1)
			if isDown then
				self:onClickOk()
				break
			end
		end
	end
end
function ESRBUpdateDialog:keyEvent(unicode, sym, modifier, isDown)
	if isDown then
		self:onClickOk()
	end
end
function ESRBUpdateDialog:mouseEvent(posX, posY, isDown, isUp, button)
	if isDown then
		self:onClickOk()
	end
end
