-- Local values: GuidedTourStep_mt
GuidedTourStep = {}
local GuidedTourStep_mt = Class(GuidedTourStep)

-- Local values: actionClasses, name, actionClass, goalClasses, name, goalClass, progressClasses, name, progressClass
function GuidedTourStep.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.L10N_STRING, basePath .. ".taskDescription#text", "The description text of the current task", nil, false)
	schema:register(XMLValueType.BOOL, basePath .. "#showProgress", "Hide or show the current tour progress bar", nil, false)
	schema:register(XMLValueType.L10N_STRING, basePath .. ".info#text", "The info text of the current task", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".info.input(?)#name", "Name of the input action", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".info.input(?)#name2", "Name of the second input action", nil, false)
	schema:register(XMLValueType.L10N_STRING, basePath .. ".info.input(?)#text", "Text of the action", nil, false)
	local v4_ = g_guidedTourManager:getAllActionClasses()
	for v5_, v6_ in pairs(v4_) do
		v6_.registerXMLPaths(schema, string.format("%s.actions.%s(?)", basePath, v5_))
	end
	local v7_ = g_guidedTourManager:getAllGoalClasses()
	for v8_, v9_ in pairs(v7_) do
		v9_.registerXMLPaths(schema, string.format("%s.goals.%s(?)", basePath, v8_))
	end
	local v10_ = g_guidedTourManager:getAllProgressClasses()
	for v11_, v12_ in pairs(v10_) do
		v12_.registerXMLPaths(schema, string.format("%s.progresses.%s(?)", basePath, v11_))
	end
end

-- Local values: actionClasses, name, actionClass, goalClasses, name, goalClass, progressClasses, name, progressClass
function GuidedTourStep.registerSavegameXMLPaths(schema, basePath)
	local v15_ = g_guidedTourManager:getAllActionClasses()
	for v16_, v17_ in pairs(v15_) do
		if v17_.registerSavegameXMLPaths ~= nil then
			v17_.registerSavegameXMLPaths(schema, string.format("%s.actions.%s(?)", basePath, v16_))
		end
	end
	local v18_ = g_guidedTourManager:getAllGoalClasses()
	for v19_, v20_ in pairs(v18_) do
		if v20_.registerSavegameXMLPaths ~= nil then
			v20_.registerSavegameXMLPaths(schema, string.format("%s.goals.%s(?)", basePath, v19_))
		end
	end
	local v21_ = g_guidedTourManager:getAllProgressClasses()
	for v22_, v23_ in pairs(v21_) do
		if v23_.registerSavegameXMLPaths ~= nil then
			v23_.registerXMLPaths(schema, string.format("%s.progresses.%s(?)", basePath, v22_))
		end
	end
end

-- Upvalues: GuidedTourStep_mt
-- Local values: self
function GuidedTourStep.new(customMt)
	-- upvalues: (copy) GuidedTourStep_mt
	local v25_ = customMt or GuidedTourStep_mt
	local v26_ = setmetatable({}, v25_)
	v26_.loadedFromSavegame = nil
	v26_.taskDescription = nil
	v26_.info = nil
	return v26_
end

-- Local values: infoKey, _, inputKey, actionName, input
function GuidedTourStep:load(xmlFile, key, baseDirectory, customEnvironment, stepIndex)
	self.index = stepIndex
	self.showProgress = xmlFile:getValue(key .. "#showProgress", true)
	self.taskDescription = xmlFile:getValue(key .. ".taskDescription#text", nil, customEnvironment, false)
	self.actions = GuidedTourUtil.loadActionsFromXMLFile(xmlFile, key, baseDirectory, customEnvironment, stepIndex)
	self.goals = GuidedTourUtil.loadGoalsFromXMLFile(xmlFile, key, baseDirectory, customEnvironment)
	self.progresses = GuidedTourUtil.loadProgressesFromXMLFile(xmlFile, key, baseDirectory, customEnvironment)
	local v33_ = key .. ".info"
	if xmlFile:hasProperty(v33_) then
		self.info = {}
		self.info.text = xmlFile:getValue(v33_ .. "#text")
		for _, v34_ in xmlFile:iterator(v33_ .. ".input") do
			if self.info.inputs == nil then
				self.info.inputs = {}
			end
			local v35_ = xmlFile:getValue(v34_ .. "#name")
			if v35_ ~= nil then
				local v36_ = {
					["actionName"] = v35_,
					["actionName2"] = xmlFile:getValue(v34_ .. "#name2"),
					["text"] = xmlFile:getValue(v34_ .. "#text", nil, customEnvironment, false)
				}
				local v37_ = self.info.inputs
				table.insert(v37_, v36_)
			end
		end
	end
	return true
end

-- Local values: _, action, _, progress, _, goal
function GuidedTourStep:saveToXMLFile(xmlFile, key)
	if self.actions ~= nil then
		for _, v41_ in ipairs(self.actions) do
			if v41_.saveToXMLFile ~= nil then
				v41_:saveToXMLFile(xmlFile, string.format("%s.actions.%s", key, v41_.NAME))
			end
		end
	end
	if self.progresses ~= nil then
		for _, v42_ in ipairs(self.progresses) do
			if v42_.saveToXMLFile ~= nil then
				v42_:saveToXMLFile(xmlFile, string.format("%s.progresses.%s", key, v42_.NAME))
			end
		end
	end
	if self.goals ~= nil then
		for _, v43_ in ipairs(self.goals) do
			if v43_.saveToXMLFile ~= nil then
				v43_:saveToXMLFile(xmlFile, string.format("%s.goals.%s", key, v43_.NAME))
			end
		end
	end
end

-- Local values: _, action, _, progress, _, goal
function GuidedTourStep:loadFromXMLFile(xmlFile, key)
	if self.actions ~= nil then
		for _, v47_ in ipairs(self.actions) do
			if v47_.loadFromXMLFile ~= nil and not v47_:loadFromXMLFile(xmlFile, string.format("%s.actions.%s", key, v47_.NAME)) then
				return false
			end
		end
	end
	if self.progresses ~= nil then
		for _, v48_ in ipairs(self.progresses) do
			if v48_.loadFromXMLFile ~= nil and not v48_:loadFromXMLFile(xmlFile, string.format("%s.progresses.%s", key, v48_.NAME)) then
				return false
			end
		end
	end
	if self.goals ~= nil then
		for _, v49_ in ipairs(self.goals) do
			if v49_.loadFromXMLFile ~= nil and not v49_:loadFromXMLFile(xmlFile, string.format("%s.goals.%s", key, v49_.NAME)) then
				return false
			end
		end
	end
	self.loadedFromSavegame = true
	return true
end

-- Local values: _, action, _, progress, _, goal
function GuidedTourStep:delete()
	if self.actions ~= nil then
		for _, v51_ in ipairs(self.actions) do
			if v51_.delete ~= nil then
				v51_:delete()
			end
		end
	end
	if self.progresses ~= nil then
		for _, v52_ in ipairs(self.progresses) do
			if v52_.delete ~= nil then
				v52_:delete()
			end
		end
	end
	if self.goals ~= nil then
		for _, v53_ in ipairs(self.goals) do
			if v53_.delete ~= nil then
				v53_:delete()
			end
		end
	end
end

-- Local values: _, action, _, progress, _, goal
function GuidedTourStep:update(dt)
	if self.actions ~= nil then
		for _, v56_ in ipairs(self.actions) do
			if v56_.update ~= nil then
				v56_:update(dt)
			end
		end
	end
	if self.progresses ~= nil then
		for _, v57_ in ipairs(self.progresses) do
			if v57_.update ~= nil then
				v57_:update(dt)
			end
		end
	end
	if self.goals ~= nil then
		for _, v58_ in ipairs(self.goals) do
			if v58_.update ~= nil then
				v58_:update(dt)
			end
		end
	end
	self:checkIfDone()
end

function GuidedTourStep:draw() end

-- Local values: _, action, hud, _, progress, _, goal
function GuidedTourStep:start(tour, callback)
	self.isRunning = true
	self.callback = callback
	if self.actions ~= nil then
		for _, v62_ in ipairs(self.actions) do
			v62_:run(tour, self)
		end
	end
	if self.progresses ~= nil then
		local _ = g_currentMission.hud
		for _, v63_ in ipairs(self.progresses) do
			if v63_.activate ~= nil then
				v63_:activate(tour, self)
			end
		end
	end
	if self.goals ~= nil then
		for _, v64_ in ipairs(self.goals) do
			if v64_.activate ~= nil then
				v64_:activate(tour, self)
			end
		end
	end
end

-- Local values: _, progress, _, goal
function GuidedTourStep:finish()
	self.isRunning = false
	if self.progresses ~= nil then
		for _, v66_ in ipairs(self.progresses) do
			if v66_.deactivate ~= nil then
				v66_:deactivate()
			end
		end
	end
	if self.goals ~= nil then
		for _, v67_ in ipairs(self.goals) do
			if v67_.deactivate ~= nil then
				v67_:deactivate()
			end
		end
	end
end

-- Local values: _, goal
function GuidedTourStep:checkIfDone()
	if self.goals ~= nil then
		for _, v69_ in ipairs(self.goals) do
			if not v69_:isAchieved() then
				return
			end
		end
	end
	self:finish()
	self.callback()
end

function GuidedTourStep:getProgressByIndex(progressIndex)
	if self.progresses == nil then
		return nil
	else
		return self.progresses[progressIndex]
	end
end

function GuidedTourStep:getInfo()
	return self.info
end
