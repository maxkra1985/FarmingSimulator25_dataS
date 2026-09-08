GuidedTourUtil = {}

-- Local values: xmlFile, className, class, guidedTour
function GuidedTourUtil.createFromXML(xmlFilename)
	local v2_ = XMLFile.load("guidedTour", xmlFilename, GuidedTour.xmlSchema)
	if v2_ == nil then
		return nil
	end
	local v3_ = v2_:getValue("guidedTour.class", "GuidedTour")
	v2_:delete()
	local v4_ = ClassUtil.getClassObject(v3_)
	if v4_ == nil then
		Logging.xmlWarning(v2_, "GuidedTour controller class \'%s\' not found!", v3_)
		return nil
	end
	local v5_ = v4_.new()
	if v5_:load(xmlFilename) then
		return v5_
	end
	v5_:delete()
	return nil
end

-- Local values: actions, actionClasses, name, actionClass, actionIteratorKey, _, actionKey, action
function GuidedTourUtil.loadActionsFromXMLFile(xmlFile, key, baseDirectory, customEnvironment, stepIndex)
	local v11_ = g_guidedTourManager:getAllActionClasses()
	local v12_ = nil
	for v13_, v14_ in pairs(v11_) do
		for _, v15_ in xmlFile:iterator(key .. ".actions." .. v13_) do
			local v16_ = v14_.createFromXML(xmlFile, v15_, baseDirectory, customEnvironment, stepIndex)
			if v16_ == nil then
				Logging.xmlWarning(xmlFile, "Could not create guided tour action in \'%s\'", v15_)
			else
				v12_ = v12_ == nil and {} or v12_
				table.insert(v12_, v16_)
			end
		end
	end
	return v12_
end

-- Local values: goals, goalClasses, name, goalClass, goalIteratorKey, _, goalKey, goal
function GuidedTourUtil.loadGoalsFromXMLFile(xmlFile, key, baseDirectory, customEnvironment)
	local v21_ = g_guidedTourManager:getAllGoalClasses()
	local v22_ = nil
	for v23_, v24_ in pairs(v21_) do
		for _, v25_ in xmlFile:iterator(key .. ".goals." .. v23_) do
			local v26_ = v24_.createFromXML(xmlFile, v25_, baseDirectory, customEnvironment)
			if v26_ == nil then
				Logging.xmlWarning(xmlFile, "Could not create guided tour goal in \'%s\'", v25_)
			else
				v22_ = v22_ == nil and {} or v22_
				v26_.name = v23_
				table.insert(v22_, v26_)
			end
		end
	end
	return v22_
end

-- Local values: progresses, progressClasses, name, progressClass, progressIteratorKey, _, progressKey, progress
function GuidedTourUtil.loadProgressesFromXMLFile(xmlFile, key, baseDirectory, customEnvironment)
	local v31_ = g_guidedTourManager:getAllProgressClasses()
	local v32_ = nil
	for v33_, v34_ in pairs(v31_) do
		for _, v35_ in xmlFile:iterator(key .. ".progresses." .. v33_) do
			local v36_ = v34_.createFromXML(xmlFile, v35_, baseDirectory, customEnvironment)
			if v36_ == nil then
				Logging.xmlWarning(xmlFile, "Could not create guided tour progress in \'%s\'", v35_)
			else
				v32_ = v32_ == nil and {} or v32_
				v36_.name = v33_
				table.insert(v32_, v36_)
			end
		end
	end
	return v32_
end
