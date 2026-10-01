HelpLineActivatable = {}
local HelpLineActivatable_mt = Class(HelpLineActivatable)
function HelpLineActivatable.new()
	local self = setmetatable({}, HelpLineActivatable_mt)
	self.activateText = g_i18n:getText("helpLine_open")
	return self
end
function HelpLineActivatable:getIsActivatable()
	if g_gui.currentGui ~= nil then
		return false
	elseif g_helpLineManager.helpData == nil then
		return false
	elseif not g_currentMission:getCanShowHelpTriggers() then
		return false
	else
		return true
	end
end
function HelpLineActivatable:run()
	local data = g_helpLineManager.helpData
	if data ~= nil then
		g_gui:showGui("InGameMenu")
		g_messageCenter:publishDelayed(MessageType.GUI_INGAME_OPEN_HELP_SCREEN, data.categoryIndex, data.pageIndex)
	end
end
function HelpLineActivatable:getDistance(x, y, z)
	local data = g_helpLineManager.helpData
	if data ~= nil and data.triggerNode ~= nil then
		local tx, ty, tz = getWorldTranslation(data.triggerNode)
		return MathUtil.vector3Length(x - tx, y - ty, z - tz)
	end
	return math.huge
end
