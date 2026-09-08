-- Local values: GuidedTour_mt
GuidedTour = {}
g_xmlManager:addCreateSchemaFunction(function()
	GuidedTour.xmlSchema = XMLSchema.new("guidedTour")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v1_ = GuidedTour.xmlSchema
	v1_:register(XMLValueType.STRING, "guidedTour.class", "Class name of the guided tour controller", "GuidedTour", false)
	v1_:register(XMLValueType.L10N_STRING, "guidedTour.title", "Title of the guided tour", "Tour", false)
	v1_:register(XMLValueType.STRING, "guidedTour.steps.step(?).class", "Controller class of the step", "GuidedTourStep", false)
	GuidedTourStep.registerXMLPaths(v1_, "guidedTour.steps.step(?)")
	local v2_ = g_guidedTourManager:getAllActionClasses()
	for v3_, v4_ in pairs(v2_) do
		v4_.registerXMLPaths(v1_, string.format("guidedTour.finish.actions.%s(?)", v3_))
	end
end)
local GuidedTour_mt = Class(GuidedTour)

function GuidedTour.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".player#vehicleUniqueId", "Unique id of the controlled vehicle")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. ".player#position", "World position of the player")
	schema:register(XMLValueType.INT, basePath .. ".step#index", "Current guided tour step")
	schema:register(XMLValueType.BOOL, basePath .. "#showProgress", "If current progress is shown")
	GuidedTourStep.registerSavegameXMLPaths(schema, basePath .. ".step")
end

-- Upvalues: GuidedTour_mt
-- Local values: self
function GuidedTour.new(customMt)
	-- upvalues: (copy) GuidedTour_mt
	local v9_ = customMt or GuidedTour_mt
	local v10_ = setmetatable({}, v9_)
	v10_.baseDirectory = nil
	v10_.pendingStartStepIndex = nil
	v10_.steps = {}
	v10_.currentStepIndex = 0
	v10_.showProgress = false
	return v10_
end

-- Local values: xmlFile, _, baseDirectory, customEnvironment
function GuidedTour:load(xmlFilename)
	local v13_ = XMLFile.load("guidedTour", xmlFilename, GuidedTour.xmlSchema)
	if v13_ == nil then
		return nil
	end
	local _, v14_ = Utils.getModNameAndBaseDirectory(v13_:getFilename())
	local v15_ = g_currentMission.loadingMapModName
	self.title = v13_:getValue("guidedTour.title", "Tour", v15_)
	if not self:loadSteps(v13_, v14_, v15_) then
		Logging.xmlWarning(v13_, "Could not load steps")
		v13_:delete()
		return false
	end
	self.finishActions = GuidedTourUtil.loadActionsFromXMLFile(v13_, "guidedTour.finish", v14_, v15_, 999999)
	self.mainProgressBar = g_currentMission.hud:addSideNotificationProgressBar(self.title, nil, 0)
	v13_:delete()
	return true
end

-- Local values: stepIndex, stepKey, className, class, step
function GuidedTour:loadSteps(xmlFile, baseDirectory, customEnvironment)
	for v20_, v21_ in xmlFile:iterator("guidedTour.steps.step") do
		local v22_ = xmlFile:getString(v21_ .. ".class", "GuidedTourStep")
		local v23_ = ClassUtil.getClassObject(v22_)
		if v23_ == nil then
			Logging.xmlWarning(xmlFile, "GuidedTourStep controller class \'%s\' not found!", v22_)
			return false
		end
		local v24_ = v23_.new()
		if not v24_:load(xmlFile, v21_, baseDirectory, customEnvironment, v20_) then
			v24_:delete()
			Logging.xmlWarning(xmlFile, "Could not load guidedTour step \'%s\'", v21_)
			return false
		end
		local v25_ = self.steps
		table.insert(v25_, v24_)
	end
	if #self.steps ~= 0 then
		return true
	end
	Logging.xmlWarning(xmlFile, "No steps defined for guided tour")
	return false
end

function GuidedTour:saveToXMLFile(xmlFile, key)
	xmlFile:setValue(key .. ".step#index", self.currentStepIndex)
	xmlFile:setValue(key .. "#showProgress", self.showProgress)
end

-- Local values: stepIndex, step
function GuidedTour:loadFromXMLFile(xmlFile, key)
	self.showProgress = xmlFile:getValue(key .. "#showProgress", false)
	local v32_ = xmlFile:getValue(key .. ".step#index")
	local v33_ = self.steps[v32_]
	if v33_ == nil then
		return false
	end
	if not v33_:loadFromXMLFile(xmlFile, key .. ".step") then
		return false
	end
	self.pendingStartStepIndex = v32_
	return true
end

-- Local values: _, step
function GuidedTour:delete()
	for _, v35_ in ipairs(self.steps) do
		v35_:delete()
	end
end

-- Local values: step
function GuidedTour:update(dt)
	if self.nextStepIndex ~= nil then
		local v38_ = self.steps[self.nextStepIndex]
		if v38_ == nil then
			self:finish()
		else
			self:startStep(v38_)
		end
		self.nextStepIndex = nil
	end
	if self.currentStep ~= nil and self.currentStep.update ~= nil then
		self.currentStep:update(dt)
	end
end

function GuidedTour:setShowProgress(showProgress)
	self.showProgress = showProgress
end

function GuidedTour:draw()
	if self.currentStep ~= nil and self.currentStep.draw ~= nil then
		self.currentStep:draw()
	end
	if self.showProgress then
		g_currentMission.hud:markSideNotificationProgressBarForDrawing(self.mainProgressBar)
	end
end

function GuidedTour:start(finishCallback)
	g_messageCenter:publish(MessageType.GUIDED_TOUR_STARTED)
	g_currentMission:setTimeScaleMultiplier(0.1)
	self.finishCallback = finishCallback
	self.nextStepIndex = self.pendingStartStepIndex or 1
end

function GuidedTour:finish()
	g_messageCenter:publish(MessageType.GUIDED_TOUR_FINISHED)
	self:cleanup()
	self.finishCallback(true)
end

function GuidedTour:cancel()
	self:cleanup()
	if self.finishCallback ~= nil then
		self.finishCallback(false)
	end
end

-- Local values: _, action, _, spot
function GuidedTour:cleanup()
	g_currentMission:setTimeScaleMultiplier(1)
	g_currentMission.introductionHelpSystem:hideAll()
	if self.currentStep ~= nil then
		self.currentStep:finish()
	end
	if self.finishActions ~= nil then
		for _, v47_ in ipairs(self.finishActions) do
			v47_:run(self, nil)
		end
	end
	if self.npcSpots ~= nil then
		for _, v48_ in pairs(self.npcSpots) do
			g_npcManager:removeSpot(v48_)
		end
		self.npcSpots = nil
	end
	self.currentStep = nil
	self.currentStepIndex = nil
	g_currentMission.hud:removeSideNotificationProgressBar(self.mainProgressBar)
end

function GuidedTour:startStep(step)
	self.currentStep = step
	self.currentStepIndex = step.index
	step:start(self, function()
		-- upvalues: (copy) self, (copy) step
		self.currentStep = nil
		self.nextStepIndex = step.index + 1
	end)
	self.mainProgressBar.progress = self.currentStepIndex / #self.steps
	if self.currentStep ~= nil then
		self.mainProgressBar.text = self.currentStep.taskDescription
	end
	g_messageCenter:publish(MessageType.GUIDED_TOUR_CHANGED)
end

function GuidedTour:getCanAbort()
	return true
end

-- Local values: stepInfos, i, step, stepInfo
function GuidedTour:getPassedStepsInfo()
	local v52_ = {}
	for v53_ = 1, self.currentStepIndex do
		local v54_ = self.steps[v53_]:getInfo()
		if v54_ ~= nil then
			table.insert(v52_, v54_)
		end
	end
	return v52_
end

-- Local values: npc, spot, spotName
function GuidedTour:getNPCSpot(npcName)
	local v57_ = g_npcManager:getNPCByName(npcName)
	if v57_ == nil then
		return nil
	end
	if self.npcSpots == nil then
		self.npcSpots = {}
	end
	local v58_ = self.npcSpots[npcName]
	if v58_ ~= nil then
		return v58_
	end
	local v59_ = string.format("GuidedTourSpot_%s", npcName)
	local v60_ = g_npcManager:getSpotByUniqueId(v59_)
	if v60_ == nil then
		v60_ = NPCSpot.create(v59_, v57_, 0, 0, 0, 0, 0, 0, true)
	end
	self.npcSpots[npcName] = v60_
	g_npcManager:addSpot(v60_)
	return v60_
end
