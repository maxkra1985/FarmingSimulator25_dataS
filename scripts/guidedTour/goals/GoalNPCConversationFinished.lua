-- Local values: GoalNPCConversationFinished_mt
GoalNPCConversationFinished = {}
GoalNPCConversationFinished.NAME = "npcConversationFinished"
local GoalNPCConversationFinished_mt = Class(GoalNPCConversationFinished)

function GoalNPCConversationFinished.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#npc", "Name of the npc", nil, true)
	schema:register(XMLValueType.STRING, basePath, "Filename to the conversation", nil, true)
end

-- Upvalues: GoalNPCConversationFinished_mt
-- Local values: self
function GoalNPCConversationFinished.new(npcName, filename, customMt)
	-- upvalues: (copy) GoalNPCConversationFinished_mt
	local v7_ = customMt or GoalNPCConversationFinished_mt
	local v8_ = setmetatable({}, v7_)
	v8_.npcName = npcName
	v8_.filename = filename
	v8_.finished = false
	return v8_
end

function GoalNPCConversationFinished:activate(tour, step)
	self.npc = g_npcManager:getNPCByName(self.npcName)
	if self.npc == nil then
		Logging.warning("GoalNPCConversationFinished.activate: NPC \'%s\' not found", self.npcName)
		return
	else
		self.conversation = self.npc:getConversationByFilename(self.filename)
		if self.conversation == nil then
			Logging.warning("GoalNPCConversationFinished.activate: Conversation \'%s\' not defined for NPC \'%s\'", self.filename, self.npcName)
		else
			self.finished = false
			self.npc:setNextConversation(self.conversation, function()
				-- upvalues: (copy) self
				self.finished = true
			end)
		end
	end
end

function GoalNPCConversationFinished:deactivate()
	if self.npc ~= nil then
		self.npc:setNextConversation(nil)
	end
	self.npc = nil
	self.conversation = nil
end

function GoalNPCConversationFinished:isAchieved()
	return (self.npc == nil or self.conversation == nil) and true or self.finished
end

-- Local values: npcName, filename
function GoalNPCConversationFinished.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local v14_ = xmlFile:getValue(key .. "#npc")
	if v14_ == nil then
		Logging.xmlWarning(xmlFile, "Missing \'npcName\' for \'%s\'", key)
		return nil
	end
	local v15_ = xmlFile:getValue(key)
	if v15_ ~= nil then
		return GoalNPCConversationFinished.new(v14_, v15_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'filename\' for \'%s\'", key)
	return nil
end
g_guidedTourManager:registerGoalClass(GoalNPCConversationFinished.NAME, GoalNPCConversationFinished)
