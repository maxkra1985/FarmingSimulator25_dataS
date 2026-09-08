-- Local values: HelpLineActivatable_mt
HelpLineActivatable = {}
local HelpLineActivatable_mt = Class(HelpLineActivatable)
function HelpLineActivatable.new()
	-- upvalues: (copy) HelpLineActivatable_mt
	local v2_ = HelpLineActivatable_mt
	local v3_ = setmetatable({}, v2_)
	v3_.activateText = g_i18n:getText("helpLine_open")
	return v3_
end

function HelpLineActivatable:getIsActivatable()
	if g_gui.currentGui == nil then
		if g_helpLineManager.helpData == nil then
			return false
		else
			return g_currentMission:getCanShowHelpTriggers() and true or false
		end
	else
		return false
	end
end

-- Local values: data
function HelpLineActivatable:run()
	local v4_ = g_helpLineManager.helpData
	if v4_ ~= nil then
		g_gui:showGui("InGameMenu")
		g_messageCenter:publishDelayed(MessageType.GUI_INGAME_OPEN_HELP_SCREEN, v4_.categoryIndex, v4_.pageIndex)
	end
end

-- Local values: data, tx, ty, tz
function HelpLineActivatable:getDistance(x, y, z)
	local v8_ = g_helpLineManager.helpData
	if v8_ == nil or v8_.triggerNode == nil then
		return math.huge
	end
	local v9_, v10_, v11_ = getWorldTranslation(v8_.triggerNode)
	return MathUtil.vector3Length(x - v9_, y - v10_, z - v11_)
end
