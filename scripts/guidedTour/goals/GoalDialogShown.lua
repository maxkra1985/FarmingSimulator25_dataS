-- Local values: GoalDialogShown_mt
GoalDialogShown = {}
GoalDialogShown.NAME = "dialogShown"
local GoalDialogShown_mt = Class(GoalDialogShown)

function GoalDialogShown.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#text", "Text of the dialog", nil, true)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#title", "Title of the dialog", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".input(?)#name", "Name of the input action", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".input(?)#name2", "Name of the second input action", nil, false)
	schema:register(XMLValueType.L10N_STRING, basePath .. ".input(?)#text", "Text of the action", nil, false)
	schema:register(XMLValueType.BOOL, basePath .. ".input(?)#keyboardOnly", "If the input should only be visible if keyboard input is active", false, false)
	schema:register(XMLValueType.BOOL, basePath .. ".input(?)#gamepadOnly", "If the input should only be visible if gamepad input is active", false, false)
end

-- Upvalues: GoalDialogShown_mt
-- Local values: self
function GoalDialogShown.new(title, text, inputs, customMt)
	-- upvalues: (copy) GoalDialogShown_mt
	local v8_ = customMt or GoalDialogShown_mt
	local v9_ = setmetatable({}, v8_)
	v9_.title = title
	v9_.text = text
	v9_.inputs = inputs
	v9_.wasShown = false
	return v9_
end

-- Local values: controls, useGamepadButtons, _, input, callback
function GoalDialogShown:activate(tour, step)
	self.wasShown = false
	local v11_ = g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD
	local v12_ = {}
	for _, v13_ in ipairs(self.inputs) do
		if not (v13_.keyboardOnly and v11_) and (Platform.isMobile or (not v13_.gamepadOnly or v11_)) then
			table.insert(v12_, v13_)
		end
	end
	g_currentMission.hud:showInGameMessage(self.title, self.text, -1, v12_, function(_)
		-- upvalues: (copy) self
		self.wasShown = true
	end, nil)
end

function GoalDialogShown:isAchieved()
	return self.wasShown
end

-- Local values: text, title, inputs, _, inputKey, actionName, input
function GoalDialogShown.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v18_ = xmlFile:getValue(key .. "#text", nil, customEnvironment, false)
	if v18_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'text\' for \'%s\'", key)
		return nil
	end
	local v19_ = xmlFile:getValue(key .. "#title", g_i18n:getText("ui_tour"), customEnvironment, false)
	local v20_ = {}
	for _, v21_ in xmlFile:iterator(key .. ".input") do
		local v22_ = xmlFile:getValue(v21_ .. "#name")
		if v22_ ~= nil then
			local v23_ = {
				["actionName"] = v22_,
				["actionName2"] = xmlFile:getValue(v21_ .. "#name2"),
				["text"] = xmlFile:getValue(v21_ .. "#text", nil, customEnvironment, false),
				["keyboardOnly"] = xmlFile:getValue(v21_ .. "#keyboardOnly", false),
				["gamepadOnly"] = xmlFile:getValue(v21_ .. "#gamepadOnly", false)
			}
			table.insert(v20_, v23_)
		end
	end
	return GoalDialogShown.new(v19_, v18_, v20_)
end
g_guidedTourManager:registerGoalClass(GoalDialogShown.NAME, GoalDialogShown)
