-- Local values: GameTestCase_mt
GameTestCase = {}
GameTestCase.RESULT = {}
GameTestCase.RESULT.SUCCESS = 0
GameTestCase.RESULT.FAILED = 1
GameTestCase.LOG_COPY_INTERVAL = 100
local GameTestCase_mt = Class(GameTestCase)

-- Upvalues: GameTestCase_mt
-- Local values: self
function GameTestCase.new(customMt)
	-- upvalues: (copy) GameTestCase_mt
	local v3_ = customMt or GameTestCase_mt
	local v4_ = setmetatable({}, v3_)
	v4_.index = -1
	v4_.description = "none"
	v4_.descriptionShort = "none"
	v4_.resultReason = "Unknown"
	v4_.screenshots = {}
	v4_.logCopyTimer = 0
	return v4_
end

function GameTestCase:delete() end

function GameTestCase:getName()
	return ClassUtil.getClassNameByObject(self)
end

function GameTestCase:getFullName()
	if self.index > 0 then
		return string.format("%s #%d", ClassUtil.getClassNameByObject(self), self.index)
	else
		return self:getName()
	end
end

function GameTestCase:getDescription()
	return self.description
end

function GameTestCase:getShortDescription()
	return self.descriptionShort
end

function GameTestCase:getBaseFilename()
	return string.format("%stestCase%04d/", g_gameTestManager.currentTestFolder, self.index)
end

function GameTestCase:getFilename()
	return self:getBaseFilename() .. "report.xml"
end

function GameTestCase:loadFromConfigXML(xmlFile, key)
	return true
end

function GameTestCase:start(finishedCallback)
	createFolder(self:getBaseFilename())
end

function GameTestCase:update(dt)
	if self.testTask ~= nil then
		self.testTask:update(dt)
	end
end

function GameTestCase:onFinished(result, reason, finishedCallback)
	self:print(string.format("Finished test case. Result: %s (%s)", GameTestCase.getResultName(result), reason))
	self.result = result
	self.resultReason = reason
	self:createReport(self.testTask, result)
	self.testTask:delete()
	self.testTask = nil
	finishedCallback(result)
end

-- Local values: gameTestFolder, fullPath, screenshot
function GameTestCase:takeScreenshot(name)
	local v20_ = self:getBaseFilename()
	local v21_ = v20_ .. string.format("screenshot_%03d_%s.png", #self.screenshots + 1, name)
	saveScreenshot(v21_)
	local v22_ = {
		["filename"] = v21_:sub(string.len(v20_) + 1),
		["position"] = { getWorldTranslation(getCamera()) }
	}
	local v23_ = self.screenshots
	table.insert(v23_, v22_)
end

-- Local values: filename, xmlFile, i, screenshot, key
function GameTestCase:createReport(testTask, result)
	local v27_ = self:getFilename()
	local v28_ = XMLFile.create("gameTestTaskCaseReport", v27_, "testCaseReport", nil)
	v28_:setString("testCaseReport#result", GameTestCase.getResultName(result))
	v28_:setString("testCaseReport#reason", self.resultReason)
	v28_:setString("testCaseReport#taskName", self:getName())
	v28_:setString("testCaseReport#description", self:getDescription())
	v28_:setString("testCaseReport#descriptionShort", self:getShortDescription())
	self:saveToXMLFile(v28_, "testCaseReport.config")
	for v29_ = 1, #self.screenshots do
		local v30_ = self.screenshots[v29_]
		local v31_ = string.format("testCaseReport.screenshots.screenshot(%d)", v29_ - 1)
		v28_:setString(v31_ .. "#filename", v30_.filename)
		v28_:setVector(v31_ .. "#position", v30_.position)
	end
	if testTask ~= nil then
		testTask:fillReportXMLFile(v28_, "testCaseReport")
	end
	v28_:save()
	v28_:delete()
	self:print("Saved case report to \'%s\'", v27_)
end

function GameTestCase:fillReportXMLFile(xmlFile) end

function GameTestCase:saveToXMLFile(xmlFile, key)
	xmlFile:setString(key .. "#className", ClassUtil.getClassNameByObject(self))
	if g_currentMission ~= nil then
		xmlFile:setString(key .. "#mapId", g_currentMission.missionInfo.mapId)
		xmlFile:setString(key .. "#mapTitle", g_currentMission.missionInfo.mapTitle)
	end
end
function GameTestCase.print(p35_, p36_, ...)
	g_gameTestManager:print("(" .. p35_:getFullName() .. "): " .. string.format(p36_, ...))
end

-- Local values: mapXMLFilename, mapXMLFile, mapFilename, i, field, fieldKey, i, placeable, placeableKey
function GameTestCase.fillMetaData(xmlFile, key)
	xmlFile:setString(key .. ".map#id", g_currentMission.missionInfo.mapId)
	xmlFile:setString(key .. ".map#title", g_currentMission.missionInfo.mapTitle)
	xmlFile:setString(key .. ".map#imageFilename", NetworkUtil.convertToNetworkFilename(g_currentMission.mapImageFilename))
	local v39_ = Utils.getFilename(g_currentMission.missionInfo.mapXMLFilename, g_currentMission.baseDirectory)
	local v40_ = XMLFile.load("MapXML", v39_, Mission00.xmlSchema)
	local v41_ = v40_:getString("map.filename")
	local v42_ = Utils.getFilename(v41_, g_currentMission.baseDirectory)
	xmlFile:setString(key .. ".map#filename", NetworkUtil.convertToNetworkFilename(v42_))
	v40_:delete()
	for v43_, v44_ in ipairs(g_fieldManager.fields) do
		local v45_ = string.format("%s.map.fields.field(%d)", key, v43_ - 1)
		xmlFile:setString(v45_ .. "#fieldId", v44_:getName())
		xmlFile:setFloat(v45_ .. "#posX", v44_.posX)
		xmlFile:setFloat(v45_ .. "#posZ", v44_.posZ)
		xmlFile:setString(v45_ .. "#name", v44_.name or string.format("Field %d", v43_))
	end
	for v46_, v47_ in ipairs(g_currentMission.placeableSystem.placeables) do
		local v48_ = string.format("%s.placeables.placeable(%d)", key, v46_ - 1)
		xmlFile:setString(v48_ .. "#filename", NetworkUtil.convertToNetworkFilename(v47_.configFileName))
		xmlFile:setString(v48_ .. "#i3dFilename", NetworkUtil.convertToNetworkFilename(v47_.i3dFilename))
		xmlFile:setVector(v48_ .. "#translation", { getWorldTranslation(v47_.rootNode) })
		xmlFile:setVector(v48_ .. "#rotation", { getWorldRotation(v47_.rootNode) })
	end
end

function GameTestCase.registerXMLPaths(xmlFile, key) end

-- Local values: name, index
function GameTestCase.getResultName(resultIndex)
	for v50_, v51_ in pairs(GameTestCase.RESULT) do
		if v51_ == resultIndex then
			return v50_
		end
	end
	return "INVALID"
end

function GameTestCase.generateTestCases(xmlFile, key)
	Logging.error("Base GameTestCase cannot be generated!")
end

function GameTestCase.generateTestCaseFromConfig(xmlFile, key)
	Logging.error("Base GameTestCase cannot be generated from XML!")
end
GameTestManager.registerTestCase(GameTestCase)
