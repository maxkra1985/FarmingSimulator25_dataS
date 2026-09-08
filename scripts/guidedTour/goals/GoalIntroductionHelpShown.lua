-- Local values: GoalIntroductionHelpShown_mt
GoalIntroductionHelpShown = {}
GoalIntroductionHelpShown.NAME = "introductionHelpShown"
local GoalIntroductionHelpShown_mt = Class(GoalIntroductionHelpShown)

function GoalIntroductionHelpShown.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#id", "Id of the introduction help item", nil, true)
	schema:register(XMLValueType.BOOL, basePath .. "#blockInput", "If the input should be blocked", true, false)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#text", "A custom text that should be displayed", nil, false)
end

-- Upvalues: GoalIntroductionHelpShown_mt
-- Local values: self
function GoalIntroductionHelpShown.new(id, blockInput, customText, customMt)
	-- upvalues: (copy) GoalIntroductionHelpShown_mt
	local v8_ = customMt or GoalIntroductionHelpShown_mt
	local v9_ = setmetatable({}, v8_)
	v9_.id = id
	v9_.blockInput = blockInput
	v9_.customText = customText
	v9_.wasShown = false
	return v9_
end

-- Local values: introSystem, callback, forced
function GoalIntroductionHelpShown:activate(tour, step)
	self.wasShown = false
	if g_currentMission.introductionHelpSystem == nil then
		self.wasShown = true
	end
	g_currentMission.introductionHelpSystem:showHelp(self.id, true, self.blockInput, self.customText, function()
		-- upvalues: (copy) self
		self.wasShown = true
	end)
end

function GoalIntroductionHelpShown:isAchieved()
	return self.wasShown
end

-- Local values: id, blockInput, customText
function GoalIntroductionHelpShown.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v15_ = xmlFile:getValue(key .. "#id")
	if v15_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'id\' for \'%s\'", key)
		return nil
	end
	local v16_ = xmlFile:getValue(key .. "#blockInput", true)
	local v17_ = xmlFile:getValue(key .. "#text", nil, customEnvironment, false)
	return GoalIntroductionHelpShown.new(v15_, v16_, v17_)
end
g_guidedTourManager:registerGoalClass(GoalIntroductionHelpShown.NAME, GoalIntroductionHelpShown)
