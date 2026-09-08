-- Local values: NPCConversationItem_mt
NPCConversationItem = {}
local NPCConversationItem_mt = Class(NPCConversationItem)

-- Local values: optionPath, actionClasses, name, class, inputClasses, name, class, optionPrerequisiteClasses, name, class
function NPCConversationItem.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#id", "Unique id of the conversation text flow item", nil, true)
	schema:register(XMLValueType.BOOL, basePath .. "#isActive", "If the item is active", nil, false)
	schema:register(XMLValueType.STRING, basePath .. "#nextId", "Unique id of the next converstion flow item", nil, false)
	schema:register(XMLValueType.STRING, basePath .. "#animationType", "Name of the animation that should be played", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".text", "Path to the conversation text flow item text", nil, true)
	local v4_ = basePath .. ".next.option(?)"
	local v5_ = g_npcManager:getAllConverationActionClasses()
	for v6_, v7_ in pairs(v5_) do
		v7_.registerXMLPaths(schema, string.format("%s.actions.%s(?)", basePath, v6_))
		v7_.registerXMLPaths(schema, string.format("%s.actions.%s(?)", v4_, v6_))
	end
	local v8_ = g_npcManager:getAllConverationInputClasses()
	for v9_, v10_ in pairs(v8_) do
		v10_.registerXMLPaths(schema, string.format("%s.inputs.%s(?)", basePath, v9_))
		v10_.registerXMLPaths(schema, string.format("%s.inputs.%s(?)", v4_, v9_))
	end
	local v11_ = g_npcManager:getAllConverationOptionPrerequisiteClasses()
	for v12_, v13_ in pairs(v11_) do
		v13_.registerXMLPaths(schema, string.format("%s.prerequisites.%s(?)", v4_, v12_))
	end
	schema:register(XMLValueType.STRING, v4_ .. "#id", "Unique id of the conversation flow item. Used for Dialog Editor only", nil, true)
	schema:register(XMLValueType.BOOL, v4_ .. "#isActive", "If the item is active. Used for Dialog Editor only", nil, false)
	schema:register(XMLValueType.STRING, v4_ .. "#nextId", "Unique id of the next converstion flow item", nil, false)
	schema:register(XMLValueType.STRING, v4_ .. ".text", "Path to the conversation text flow item option text", nil, true)
end

-- Upvalues: NPCConversationItem_mt
-- Local values: self
function NPCConversationItem.new(conversation, customMt)
	-- upvalues: (copy) NPCConversationItem_mt
	local v16_ = customMt or NPCConversationItem_mt
	local v17_ = setmetatable({}, v16_)
	v17_.conversation = conversation
	v17_.index = 0
	v17_.id = nil
	v17_.text = nil
	v17_.nextId = nil
	v17_.options = nil
	v17_.actions = nil
	return v17_
end

-- Local values: path, animationTypeName, animationType, fullPath, _, optionKey, nextId, isActive, optionPath, fullOptionPath, optionText, option
function NPCConversationItem:loadFromXML(xmlFile, key, baseDirectory, customEnvironment)
	self.id = xmlFile:getValue(key .. "#id")
	if self.id == nil then
		Logging.xmlWarning(xmlFile, "Missing id for npc conversation item \'%s\'", key)
		return false
	end
	local v23_ = xmlFile:getValue(key .. ".text")
	if v23_ == nil then
		Logging.xmlWarning(xmlFile, "Missing text element for npc conversation item \'%s\'", key)
		return false
	end
	local v24_ = xmlFile:getValue(key .. "#animationType")
	if v24_ ~= nil then
		if NPCAnimationType.getByName(v24_) == nil then
			Logging.xmlWarning(xmlFile, "Animation type \'%s\' not defined for npc conversation item \'%s\'", key)
		else
			self.animationType = v24_
		end
	end
	local v25_ = Utils.getFilename(v23_, baseDirectory)
	self.isActive = xmlFile:getValue(key .. "#isActive", true)
	self.text = NPCUtil.createTextFromPath(v25_, false, self.isActive)
	if self.text == nil then
		Logging.xmlWarning(xmlFile, "Could not create text for npc conversation item \'%s\'", key)
		return false
	end
	for _, v26_ in xmlFile:iterator(key .. ".next.option") do
		local v27_ = xmlFile:getValue(v26_ .. "#nextId")
		local v28_ = xmlFile:getValue(v26_ .. "#isActive", true)
		local v29_ = xmlFile:getValue(v26_ .. ".text")
		if v29_ == nil then
			Logging.xmlWarning(xmlFile, "Missing text element for npc conversation item option \'%s\'", v26_)
			return false
		end
		local v30_ = Utils.getFilename(v29_, baseDirectory)
		local v31_ = NPCUtil.createTextFromPath(v30_, true, v28_)
		if v31_ == nil then
			Logging.xmlWarning(xmlFile, "Could not create text for npc conversation item option \'%s\'", v26_)
			return false
		end
		local v32_ = {
			["nextId"] = v27_,
			["isActive"] = v28_,
			["text"] = v31_,
			["inputs"] = NPCUtil.loadInputsFromXMLFile(xmlFile, v26_, self.conversation, baseDirectory, customEnvironment),
			["actions"] = NPCUtil.loadActionsFromXMLFile(xmlFile, v26_, self.conversation, baseDirectory, customEnvironment),
			["prerequisites"] = NPCUtil.loadOptionPrerequisitesFromXMLFile(xmlFile, v26_, self.conversation, baseDirectory, customEnvironment)
		}
		if self.options == nil then
			self.options = {}
		end
		local v33_ = self.options
		table.insert(v33_, v32_)
	end
	if self.options == nil or #self.options == 0 then
		self.nextId = xmlFile:getValue(key .. "#nextId")
	end
	self.inputs = NPCUtil.loadInputsFromXMLFile(xmlFile, key, self.conversation, baseDirectory, customEnvironment)
	self.actions = NPCUtil.loadActionsFromXMLFile(xmlFile, key, self.conversation, baseDirectory, customEnvironment)
	return true
end

-- Local values: _, option
function NPCConversationItem:delete()
	self.text:delete()
	if self.options ~= nil then
		for _, v35_ in ipairs(self.options) do
			v35_.text:delete()
		end
	end
end

-- Local values: _, option
function NPCConversationItem:init()
	self.text:init()
	if self.options ~= nil then
		for _, v37_ in ipairs(self.options) do
			v37_.text:init()
		end
	end
end

-- Local values: _, option
function NPCConversationItem:reset()
	self.text:reset()
	if self.options ~= nil then
		for _, v39_ in ipairs(self.options) do
			v39_.text:reset()
		end
	end
end

-- Local values: _, input, _, action
function NPCConversationItem:activate()
	if self.inputs ~= nil then
		for _, v41_ in ipairs(self.inputs) do
			v41_:run()
		end
	end
	if self.actions ~= nil then
		for _, v42_ in ipairs(self.actions) do
			v42_:run()
		end
	end
end

-- Local values: option, _, input, _, action
function NPCConversationItem:activateOption(index)
	if self.options == nil then
		Logging.devWarning("Cannot activate conversation item option. No options available!")
		return
	else
		local v45_ = self.options[index]
		if index == nil then
			Logging.devWarning("Cannot activate conversation item option. Invalid option index \'%s\'!", index)
			return
		elseif v45_.isActive then
			if v45_.inputs ~= nil then
				for _, v46_ in ipairs(v45_.inputs) do
					v46_:run()
				end
			end
			if v45_.actions ~= nil then
				for _, v47_ in ipairs(v45_.actions) do
					v47_:run()
				end
			end
		else
			Logging.devWarning("Cannot activate conversation item option \'%s\'. Option is inactive!", index)
		end
	end
end

function NPCConversationItem:getId()
	return self.id
end

function NPCConversationItem:setIndex(index)
	self.index = index
end

function NPCConversationItem:getIndex()
	return self.index
end

function NPCConversationItem:getIsActive()
	return self.isActive
end

function NPCConversationItem:getText()
	return self.text
end

function NPCConversationItem:getOptions()
	return self.options
end

function NPCConversationItem:getNextId()
	return self.nextId
end

function NPCConversationItem:getOptionByIndex(index)
	if self.options == nil then
		return nil
	else
		return self.options[index]
	end
end

-- Local values: nextItem, k, option, optionNextItem
function NPCConversationItem:validateXML(xmlFile)
	if self.nextId == nil or self.conversation:getConversationItemById(self.nextId) ~= nil then
		if self.options ~= nil then
			for v60_, v61_ in ipairs(self.options) do
				if v61_.nextId ~= nil and self.conversation:getConversationItemById(v61_.nextId) == nil then
					Logging.xmlWarning(xmlFile, "NextId \'%s\' of npc conversation item \'%s\' option \'%d\' not defined!", v61_.nextId, self.id, v60_)
					return false
				end
			end
		end
		return true
	else
		Logging.xmlWarning(xmlFile, "NextId \'%s\' of npc conversation item \'%s\' not defined!", self.nextId, self.id)
		return false
	end
end

function NPCConversationItem:validate()
	self:init()
	self:reset()
end
