GuidedTourUtil = {}
function GuidedTourUtil.createFromXML(xmlFilename)
	local xmlFile = XMLFile.load("guidedTour", xmlFilename, GuidedTour.xmlSchema)
	if xmlFile == nil then
		return nil
	end
	local className = xmlFile:getValue("guidedTour.class", "GuidedTour")
	xmlFile:delete()
	local class = ClassUtil.getClassObject(className)
	if class == nil then
		Logging.xmlWarning(xmlFile, "GuidedTour controller class '%s' not found!", className)
		return nil
	end
	local guidedTour = class.new()
	if not guidedTour:load(xmlFilename) then
		guidedTour:delete()
		return nil
	else
		return guidedTour
	end
end
function GuidedTourUtil.loadActionsFromXMLFile(xmlFile, key, baseDirectory, customEnvironment, stepIndex)
	local actions = nil
	local actionClasses = g_guidedTourManager:getAllActionClasses()
	for name, actionClass in pairs(actionClasses) do
		local actionIteratorKey = key .. ".actions." .. name
		for _, actionKey in xmlFile:iterator(actionIteratorKey) do
			local action = actionClass.createFromXML(xmlFile, actionKey, baseDirectory, customEnvironment, stepIndex)
			if action ~= nil then
				if actions == nil then
					actions = {}
				end
				table.insert(actions, action)
			else
				Logging.xmlWarning(xmlFile, "Could not create guided tour action in '%s'", actionKey)
			end
		end
	end
	return actions
end
function GuidedTourUtil.loadGoalsFromXMLFile(xmlFile, key, baseDirectory, customEnvironment)
	local goals = nil
	local goalClasses = g_guidedTourManager:getAllGoalClasses()
	for name, goalClass in pairs(goalClasses) do
		local goalIteratorKey = key .. ".goals." .. name
		for _, goalKey in xmlFile:iterator(goalIteratorKey) do
			local goal = goalClass.createFromXML(xmlFile, goalKey, baseDirectory, customEnvironment)
			if goal ~= nil then
				if goals == nil then
					goals = {}
				end
				goal.name = name
				table.insert(goals, goal)
			else
				Logging.xmlWarning(xmlFile, "Could not create guided tour goal in '%s'", goalKey)
			end
		end
	end
	return goals
end
function GuidedTourUtil.loadProgressesFromXMLFile(xmlFile, key, baseDirectory, customEnvironment)
	local progresses = nil
	local progressClasses = g_guidedTourManager:getAllProgressClasses()
	for name, progressClass in pairs(progressClasses) do
		local progressIteratorKey = key .. ".progresses." .. name
		for _, progressKey in xmlFile:iterator(progressIteratorKey) do
			local progress = progressClass.createFromXML(xmlFile, progressKey, baseDirectory, customEnvironment)
			if progress ~= nil then
				if progresses == nil then
					progresses = {}
				end
				progress.name = name
				table.insert(progresses, progress)
			else
				Logging.xmlWarning(xmlFile, "Could not create guided tour progress in '%s'", progressKey)
			end
		end
	end
	return progresses
end
