GoalNPCConversationFinished = {}
GoalNPCConversationFinished.NAME = "npcConversationFinished"
local GoalNPCConversationFinished_mt = Class(GoalNPCConversationFinished)
function GoalNPCConversationFinished.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#npc", "Name of the npc", nil, true)
	schema:register(XMLValueType.STRING, basePath, "Filename to the conversation", nil, true)
end
function GoalNPCConversationFinished.new(npcName, filename, customMt)
	local self = setmetatable({}, customMt or GoalNPCConversationFinished_mt)
	self.npcName = npcName
	self.filename = filename
	self.finished = false
	return self
end
function GoalNPCConversationFinished:activate(tour, step)
	self.npc = g_npcManager:getNPCByName(self.npcName)
	if self.npc == nil then
		Logging.warning("GoalNPCConversationFinished.activate: NPC '%s' not found", self.npcName)
		return
	end
	self.conversation = self.npc:getConversationByFilename(self.filename)
	if self.conversation == nil then
		Logging.warning("GoalNPCConversationFinished.activate: Conversation '%s' not defined for NPC '%s'", self.filename, self.npcName)
	else
		self.finished = false
		self.npc:setNextConversation(self.conversation, function()
			self.finished = true
		end)
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
	if self.npc == nil or self.conversation == nil then
		return true
	end
	return self.finished
end
function GoalNPCConversationFinished.createFromXML(xmlFile, key, baseDirectory, customEnvironment)
	local npcName = xmlFile:getValue(key .. "#npc")
	if npcName == nil then
		Logging.xmlWarning(xmlFile, "Missing 'npcName' for '%s'", key)
		return nil
	end
	local filename = xmlFile:getValue(key)
	if filename == nil then
		Logging.xmlWarning(xmlFile, "Missing 'filename' for '%s'", key)
		return nil
	else
		return GoalNPCConversationFinished.new(npcName, filename)
	end
end
g_guidedTourManager:registerGoalClass(GoalNPCConversationFinished.NAME, GoalNPCConversationFinished)
