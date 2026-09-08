-- Local values: ESRBUpdateDialog_mt
ESRBUpdateDialog = {}
local ESRBUpdateDialog_mt = Class(ESRBUpdateDialog, InfoDialog)
function ESRBUpdateDialog.register()
	local v2_ = ESRBUpdateDialog.new()
	g_gui:loadGui("dataS/gui/dialogs/InfoDialog.xml", "ESRBUpdateDialog", v2_)
	ESRBUpdateDialog.INSTANCE = v2_
end

-- Local values: dialog
function ESRBUpdateDialog.show(text, callback, target)
	if ESRBUpdateDialog.INSTANCE ~= nil then
		local v6_ = ESRBUpdateDialog.INSTANCE
		v6_:setCallback(callback, target)
		v6_:setText(text)
		g_gui:showDialog("ESRBUpdateDialog")
	end
end

-- Upvalues: ESRBUpdateDialog_mt
-- Local values: self
function ESRBUpdateDialog.new(target, custom_mt)
	-- upvalues: (copy) ESRBUpdateDialog_mt
	return InfoDialog.new(target, custom_mt or ESRBUpdateDialog_mt)
end

-- Local values: d, i, isDown
function ESRBUpdateDialog:update(dt)
	ESRBUpdateDialog:superClass().update(self, dt)
	for v11_ = 1, getNumOfGamepads() do
		for v12_ = 1, Input.MAX_NUM_BUTTONS do
			if getInputButton(v12_ - 1, v11_ - 1) > 0 then
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
