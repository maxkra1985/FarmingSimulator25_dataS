-- Local values: NPCConversation_mt
NPCConversation = {}
local NPCConversation_mt = Class(NPCConversation)
g_xmlManager:addCreateSchemaFunction(function()
	NPCConversation.xmlSchema = XMLSchema.new("npcConversation")
end)
g_xmlManager:addInitSchemaFunction(function()
	local v2_ = NPCConversation.xmlSchema
	v2_:register(XMLValueType.BOOL, "conversation.isActive", "If conversation is active", nil, false)
	v2_:register(XMLValueType.STRING, "conversation.class", "Class name of the npc conversation controller", "NPCConversation", false)
	NPCConversationType.registerXMLPath(v2_, "conversation.type", "Type of the conversation", "DEFAULT", false)
	v2_:register(XMLValueType.INT, "conversation.probability", "Default probability of the conversation", 1, false)
	v2_:register(XMLValueType.STRING, "conversation.textFlow#startId", "Start unique id of the conversation", nil, false)
	local v3_ = g_npcManager:getAllConverationPrerequisiteClasses()
	for v4_, v5_ in pairs(v3_) do
		v5_.registerXMLPaths(v2_, string.format("conversation.prerequisites.%s(?)", v4_))
	end
	NPCConversationItem.registerXMLPaths(v2_, "conversation.textFlow.item(?)")
end)

-- Local values: prerequisiteClasses, name, class
function NPCConversation.registerSavegameXMLPaths(xmlSchema, key)
	xmlSchema:register(XMLValueType.INT, key .. "#numTriggered", "How often this conversation was trigged")
	xmlSchema:register(XMLValueType.INT, key .. "#lastMonotonicDay", "Last ingame monotonic day since last occurrence")
	xmlSchema:register(XMLValueType.STRING, key .. "#lastDate", "Real date since last occurrence")
	local v8_ = g_npcManager:getAllConverationPrerequisiteClasses()
	for v9_, v10_ in pairs(v8_) do
		if v10_.registerSavegameXMLPaths ~= nil then
			v10_.registerSavegameXMLPaths(xmlSchema, string.format("%s.%s", key, v9_))
		end
	end
end

-- Upvalues: NPCConversation_mt
-- Local values: self
function NPCConversation.new(npc, uniqueId, customMt)
	-- upvalues: (copy) NPCConversation_mt
	local v14_ = customMt or NPCConversation_mt
	local v15_ = setmetatable({}, v14_)
	v15_.isActive = nil
	v15_.npc = npc
	v15_.uniqueId = uniqueId
	v15_.typeId = nil
	v15_.probability = 1
	v15_.index = 0
	v15_.conversationItems = {}
	v15_.idToConversationItem = {}
	v15_.isLoaded = false
	return v15_
end

-- Local values: xmlFile, customEnv, baseDirectory
function NPCConversation:load(xmlFilename)
	local v18_ = XMLFile.load("NPCConversation", xmlFilename, NPCConversation.xmlSchema)
	if v18_ == nil then
		return nil
	end
	local v19_, v20_ = Utils.getModNameAndBaseDirectory(v18_:getFilename())
	self.xmlFilename = xmlFilename
	self.baseDirectory = v20_
	self.customEnvironment = v19_
	self.isActive = v18_:getValue("conversation.isActive", nil)
	self.typeId = NPCConversationType.loadFromXMLFile(v18_, "conversation.type")
	if self.typeId == nil then
		Logging.xmlWarning(v18_, "Invalid converation type! Resetting to DEFAULT")
		self.typeId = NPCConversationType.DEFAULT
	end
	self.probability = v18_:getValue("conversation.probability", 1)
	if not self.isActive or self:loadPrerequisites(v18_) then
		v18_:delete()
		return true
	end
	Logging.xmlWarning(v18_, "Could not load prerequisites")
	v18_:delete()
	return false
end

-- Local values: prerequisiteClasses, name, prerequisiteClass, prerequisiteIteratorKey, _, prerequisiteKey, prerequisite
function NPCConversation:loadPrerequisites(xmlFile)
	local v23_ = g_npcManager:getAllConverationPrerequisiteClasses()
	for v24_, v25_ in pairs(v23_) do
		for _, v26_ in xmlFile:iterator("conversation.prerequisites." .. v24_) do
			local v27_ = v25_.createFromXML(xmlFile, v26_, self, self.baseDirectory, self.customEnvironment)
			if v27_ == nil then
				Logging.xmlWarning(xmlFile, "Could not create conversation prerequisite in \'%s\'", v26_)
			else
				if self.prerequisites == nil then
					self.prerequisites = {}
				end
				local v28_ = self.prerequisites
				table.insert(v28_, v27_)
			end
		end
	end
	return true
end

-- Local values: xmlFile
function NPCConversation:loadTexts()
	if self.isLoaded then
		return
	else
		local v30_ = XMLFile.load("NPCConversation", self.xmlFilename, NPCConversation.xmlSchema)
		if v30_ == nil then
			return nil
		elseif self:loadConversationItems(v30_, "conversation.textFlow") then
			v30_:delete()
			self.isLoaded = true
			return true
		else
			Logging.xmlWarning(v30_, "Could not load textFlow")
			v30_:delete()
			return false
		end
	end
end

-- Local values: _, conversationItem
function NPCConversation:unloadTexts()
	for _, v32_ in pairs(self.idToConversationItem) do
		v32_:delete()
	end
	self.idToConversationItem = {}
	self.conversationItems = {}
	self.isLoaded = false
end

-- Local values: _, itemKey, conversationItem, id, startId, _, conversationItem
function NPCConversation:loadConversationItems(xmlFile, key)
	for _, v36_ in xmlFile:iterator(key .. ".item") do
		local v37_ = NPCConversationItem.new(self)
		if not v37_:loadFromXML(xmlFile, v36_, self.baseDirectory, self.customEnvironment) then
			return false
		end
		local v38_ = v37_:getId()
		if self.idToConversationItem[v38_] ~= nil then
			Logging.xmlWarning(xmlFile, "Item with id \'%s\' already exists in text flow for \'%s\'", v38_, v36_)
			return false
		end
		self.idToConversationItem[v38_] = v37_
		local v39_ = self.conversationItems
		table.insert(v39_, v37_)
		v37_:setIndex(#self.conversationItems)
		if self.startId == nil then
			self.startId = v38_
		end
	end
	local v40_ = xmlFile:getValue(key .. "#startId")
	if v40_ ~= nil then
		if self.idToConversationItem[v40_] == nil then
			Logging.xmlWarning(xmlFile, "Given startId \'%s\' is not defined", v40_)
		else
			self.startId = v40_
		end
	end
	for _, v41_ in pairs(self.idToConversationItem) do
		if not v41_:validateXML(xmlFile) then
			return false
		end
	end
	return true
end

function NPCConversation:delete()
	self:unloadTexts()
end

function NPCConversation:getUniqueId()
	return self.uniqueId
end

function NPCConversation:setIndex(index)
	self.index = index
end

function NPCConversation:getIndex()
	return self.index
end

function NPCConversation:getType()
	return self.typeId
end

function NPCConversation:getNPC()
	return self.npc
end

function NPCConversation:getConversationItemById(id)
	return self.idToConversationItem[id]
end

function NPCConversation:getConversationItemByIndex(index)
	return self.conversationItems[index]
end

function NPCConversation:compare(conversation)
	return self:getWeight() < conversation:getWeight()
end

function NPCConversation:getWeight()
	return 1
end

function NPCConversation:getProbability()
	return self.probability
end

-- Local values: _, prerequisite
function NPCConversation:getIsAvailable(player, userData)
	if not self.isActive then
		return false
	end
	if self.prerequisites ~= nil then
		for _, v59_ in ipairs(self.prerequisites) do
			if not v59_:getIsValid(player, userData) then
				return false
			end
		end
	end
	return true
end

function NPCConversation:getCanBeCanceled()
	return false
end

function NPCConversation:init(player) end

-- Local values: _, prerequisite
function NPCConversation:start(player, userData)
	local v62_ = g_server ~= nil
	assert(v62_, "NPCConversation:start is a server only function")
	self:updateUserData(userData)
	if self.prerequisites ~= nil then
		for _, v63_ in ipairs(self.prerequisites) do
			if v63_.onConversationStart ~= nil then
				v63_:onConversationStart()
			end
		end
	end
end

function NPCConversation:reset()
	self:unloadTexts()
end

-- Local values: _, prerequisite, prerequisiteData
function NPCConversation:updateUserData(userData)
	userData.lastTriggedMonotonicDay = g_currentMission.environment.currentMonotonicDay
	userData.lastTriggedDate = getDate("%Y/%m/%d %H:%M")
	userData.numTriggered = (userData.numTriggered or 0) + 1
	if self.prerequisites ~= nil then
		for _, v67_ in ipairs(self.prerequisites) do
			if v67_.updateUserData ~= nil then
				local v68_ = userData[v67_.NAME] or {}
				v67_:updateUserData(v68_)
				if next(v68_) ~= nil then
					userData[v67_.NAME] = v68_
				end
			end
		end
	end
end

-- Local values: _, prerequisite, prerequisiteKey
function NPCConversation:saveToSavegameXMLFile(xmlFile, key, userData)
	if userData.numTriggered ~= nil then
		xmlFile:setValue(key .. "#numTriggered", userData.numTriggered)
	end
	if userData.lastTriggedMonotonicDay ~= nil then
		xmlFile:setValue(key .. "#lastMonotonicDay", userData.lastTriggedMonotonicDay)
	end
	if userData.lastTriggedDate ~= nil then
		xmlFile:setValue(key .. "#lastDate", userData.lastTriggedDate)
	end
	if self.prerequisites ~= nil then
		for _, v73_ in ipairs(self.prerequisites) do
			if v73_.saveToSavegameXMLFile ~= nil then
				v73_:saveToSavegameXMLFile(xmlFile, string.format("%s.%s", key, v73_.NAME), userData[v73_.NAME])
			end
		end
	end
end

-- Local values: _, prerequisite, prerequisiteKey, prerequisiteData
function NPCConversation:loadFromSavegameXMLFile(xmlFile, key, userData)
	userData.numTriggered = xmlFile:getValue(key .. "#numTriggered")
	userData.lastTriggedMonotonicDay = xmlFile:getValue(key .. "#lastMonotonicDay")
	userData.lastTriggedDate = xmlFile:getValue(key .. "#lastDate")
	if self.prerequisites ~= nil then
		for _, v78_ in ipairs(self.prerequisites) do
			if v78_.loadFromSavegameXMLFile ~= nil then
				local v79_ = {}
				v78_:loadFromSavegameXMLFile(xmlFile, string.format("%s.%s", key, v78_.NAME), v79_)
				if next(v79_) ~= nil then
					userData[v78_.NAME] = v79_
				end
			end
		end
	end
end

function NPCConversation:getHasUserData()
	return next(self.userData) ~= nil
end

-- Local values: _, item
function NPCConversation:validate()
	self:loadTexts()
	for _, v82_ in ipairs(self.conversationItems) do
		v82_:validate()
	end
	self:unloadTexts()
end
