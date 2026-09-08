-- Local values: InputHelpElement_mt
InputHelpElement = {}
local InputHelpElement_mt = Class(InputHelpElement)
InputHelpElement.SEPARATOR = {
	["NONE"] = 1,
	["COMBO_INPUT"] = 2,
	["ANY_INPUT"] = 3
}
InputHelpElement.NO_DATA = {}

-- Upvalues: InputHelpElement_mt
-- Local values: self
function InputHelpElement.new(actionName, actionName2, buttonOverlays, keyLabels, separators, isComboButtonMapping, text, inlineModifierButtons, iconOverlay, priority)
	-- upvalues: (copy) InputHelpElement_mt
	local v12_ = InputHelpElement_mt
	local v13_ = setmetatable({}, v12_)
	v13_.actionName = actionName or ""
	v13_.actionName2 = actionName2 or ""
	v13_.buttons = buttonOverlays or InputHelpElement.NO_DATA
	v13_.separators = separators or InputHelpElement.NO_DATA
	v13_.isComboButtonMapping = isComboButtonMapping or InputHelpElement.NO_DATA
	v13_.keys = keyLabels or InputHelpElement.NO_DATA
	v13_.text = text or ""
	v13_.inlineModifierButtons = inlineModifierButtons
	v13_.iconOverlay = iconOverlay
	v13_.priority = priority or GS_PRIO_NORMAL
	return v13_
end

-- Local values: actionNames
function InputHelpElement:getActionNames()
	local v15_ = {}
	if self.actionName ~= "" then
		local v16_ = self.actionName
		table.insert(v15_, v16_)
	end
	if self.actionName2 ~= "" then
		local v17_ = self.actionName2
		table.insert(v15_, v17_)
	end
	return v15_
end
InputHelpElement.AXIS_ICON = {}
InputHelpElement.AXIS_ICON.CRANE_ARM1_ROTATE_X = "CRANE_ARM1_ROTATE_X"
InputHelpElement.AXIS_ICON.CRANE_ARM1_ROTATE_Y = "CRANE_ARM1_ROTATE_Y"
InputHelpElement.AXIS_ICON.CRANE_ARM1_TRANSLATE = "CRANE_ARM1_TRANSLATE"
InputHelpElement.AXIS_ICON.CRANE_ARM2_ROTATE_X = "CRANE_ARM2_ROTATE_X"
InputHelpElement.AXIS_ICON.CRANE_ARM2_ROTATE_TOOL = "CRANE_ARM2_ROTATE_TOOL"
InputHelpElement.AXIS_ICON.CRANE_ARM2_TRANSLATE = "CRANE_ARM2_TRANSLATE"
InputHelpElement.AXIS_ICON.DRAWBAR_ROTATE_X = "DRAWBAR_ROTATE_X"
InputHelpElement.AXIS_ICON.FRONTLOADER_ARM_ROTATE = "FRONTLOADER_ARM_ROTATE"
InputHelpElement.AXIS_ICON.FRONTLOADER_ARM_ROTATE_TOOL = "FRONTLOADER_ARM_ROTATE_TOOL"
InputHelpElement.AXIS_ICON.GRABBER_OPEN_CLOSE = "GRABBER_OPEN_CLOSE"
InputHelpElement.AXIS_ICON.GRABBER_ROTATE_Y = "GRABBER_ROTATE_Y"
InputHelpElement.AXIS_ICON.IMPLEMENT_ATTACHER_ROTX = "IMPLEMENT_ATTACHER_ROTX"
InputHelpElement.AXIS_ICON.IMPLEMENT_ATTACHER_TRANS = "IMPLEMENT_ATTACHER_TRANS"
InputHelpElement.AXIS_ICON.IMPLEMENT_TRANS_X = "IMPLEMENT_TRANS_X"
InputHelpElement.AXIS_ICON.IMPLEMENT_TRANS_Y = "IMPLEMENT_TRANS_Y"
InputHelpElement.AXIS_ICON.PIPE_END_ROTATE = "PIPE_END_ROTATE"
InputHelpElement.AXIS_ICON.PIPE_ROTATE_X = "PIPE_ROTATE_X"
InputHelpElement.AXIS_ICON.PIPE_ROTATE_Y = "PIPE_ROTATE_Y"
InputHelpElement.AXIS_ICON.REEL_TRANSLATE_X = "REEL_TRANSLATE_X"
InputHelpElement.AXIS_ICON.REEL_TRANSLATE_Y = "REEL_TRANSLATE_Y"
InputHelpElement.AXIS_ICON.SPRAYER_ARM_TRANSLATE_Y = "SPRAYER_ARM_TRANSLATE_Y"
InputHelpElement.AXIS_ICON.SUPPORT_ARM_TRANSLATE_Y = "SUPPORT_ARM_TRANSLATE_Y"
InputHelpElement.AXIS_ICON.TOOL_OPEN_CLOSE = "TOOL_OPEN_CLOSE"
InputHelpElement.AXIS_ICON.TOP_DOOR_ROTATE = "TOP_DOOR_ROTATE"
InputHelpElement.AXIS_ICON.WHEEL_BASE_TRANSLATE_X = "WHEEL_BASE_TRANSLATE_X"
InputHelpElement.AXIS_ICON.CHASSIS_HEIGHT = "CHASSIS_HEIGHT"
InputHelpElement.AXIS_ICON.WORKING_WIDTH_TRANSLATE_X = "WORKING_WIDTH_TRANSLATE_X"
InputHelpElement.AXIS_ICON.CRANE_EC_TRANSLATE_Y = "CRANE_EC_TRANSLATE_Y"
InputHelpElement.AXIS_ICON.CRANE_EC_TRANSLATE_Z = "CRANE_EC_TRANSLATE_Z"
InputHelpElement.AXIS_ICON.BEET_PICKUP_TRANS_X = "BEET_PICKUP_TRANS_X"
InputHelpElement.AXIS_ICON.BEET_PICKUP_TRANS_Y = "BEET_PICKUP_TRANS_Y"
InputHelpElement.AXIS_ICON.SEAT_ROT_Y = "SEAT_ROT_Y"
InputHelpElement.AXIS_ICON.SNOW_PLOW_ROT_LEFT = "SNOW_PLOW_ROT_LEFT"
InputHelpElement.AXIS_ICON.SNOW_PLOW_ROT_CENTER = "SNOW_PLOW_ROT_CENTER"
InputHelpElement.AXIS_ICON.SNOW_PLOW_ROT_RIGHT = "SNOW_PLOW_ROT_RIGHT"
InputHelpElement.AXIS_ICON.FORKLIFT_ROTATE_X = "FORKLIFT_ROTATE_X"
InputHelpElement.AXIS_ICON.FORKLIFT_TRANSLATE_Y = "FORKLIFT_TRANSLATE_Y"
