-- Local values: ConversationInputLeaseVehicles_mt
ConversationInputLeaseVehicles = {}
ConversationInputLeaseVehicles.NAME = "leaseVehicles"
local ConversationInputLeaseVehicles_mt = Class(ConversationInputLeaseVehicles)

function ConversationInputLeaseVehicles.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#value", "True if vehicles should be leased, else false", false, false)
end

-- Upvalues: ConversationInputLeaseVehicles_mt
-- Local values: self
function ConversationInputLeaseVehicles.new(conversation, doLeaseVehicles, customMt)
	-- upvalues: (copy) ConversationInputLeaseVehicles_mt
	local v7_ = customMt or ConversationInputLeaseVehicles_mt
	local v8_ = setmetatable({}, v7_)
	v8_.conversation = conversation
	v8_.doLeaseVehicles = doLeaseVehicles
	return v8_
end

-- Local values: npc
function ConversationInputLeaseVehicles:run()
	local v10_ = self.conversation:getNPC()
	if v10_ == nil then
		Logging.error("ConversationInputLeaseVehicles.run: No NPC set!")
		return false
	else
		v10_:setInputData(ConversationInputLeaseVehicles.NAME, self.doLeaseVehicles)
		return true
	end
end

-- Local values: doLeaseVehicles
function ConversationInputLeaseVehicles.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v14_ = xmlFile:getValue(key .. "#value")
	if v14_ ~= nil then
		return ConversationInputLeaseVehicles.new(conversation, v14_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'value\' for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationInputClass(ConversationInputLeaseVehicles.NAME, ConversationInputLeaseVehicles)
