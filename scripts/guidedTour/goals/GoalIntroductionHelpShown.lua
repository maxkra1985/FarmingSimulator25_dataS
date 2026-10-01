GoalIntroductionHelpShown = {}
GoalIntroductionHelpShown.NAME = "introductionHelpShown"
local GoalIntroductionHelpShown_mt = Class(GoalIntroductionHelpShown)
function GoalIntroductionHelpShown.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#id", "Id of the introduction help item", nil, true)
	schema:register(XMLValueType.BOOL, basePath .. "#blockInput", "If the input should be blocked", true, false)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#text", "A custom text that should be displayed", nil, false)
end
function GoalIntroductionHelpShown.new(id, blockInput, customText, customMt)
	local self = setmetatable({}, customMt or GoalIntroductionHelpShown_mt)
	self.id = id
	self.blockInput = blockInput
	self.customText = customText
	self.wasShown = false
	return self
end
function GoalIntroductionHelpShown:activate(tour, step)
	self.wasShown = false
	local introSystem = g_currentMission.introductionHelpSystem
	if introSystem == nil then
		self.wasShown = true
	end
	local callback = function()
		self.wasShown = true
	end
	local forced = true
	g_currentMission.introductionHelpSystem:showHelp(self.id, true, self.blockInput, self.customText, callback)
end
function GoalIntroductionHelpShown:isAchieved()
	return self.wasShown
end
function GoalIntroductionHelpShown.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local id = xmlFile:getValue(key .. "#id")
	if id == nil then
		Logging.xmlWarning(xmlFile, "Missing 'id' for '%s'", key)
		return nil
	else
		local blockInput = xmlFile:getValue(key .. "#blockInput", true)
		local customText = xmlFile:getValue(key .. "#text", nil, customEnvironment, false)
		return GoalIntroductionHelpShown.new(id, blockInput, customText)
	end
end
g_guidedTourManager:registerGoalClass(GoalIntroductionHelpShown.NAME, GoalIntroductionHelpShown)
