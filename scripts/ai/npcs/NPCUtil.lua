NPCUtil = {}
function NPCUtil.createFromXML(xmlFilename)
	local xmlFile = XMLFile.load("NPC", xmlFilename, NPC.xmlSchema)
	if xmlFile == nil then
		return nil
	end
	local requiredDLC = xmlFile:getString("npc#requiredDLC")
	if requiredDLC ~= nil and g_modIsLoaded[g_uniqueDlcNamePrefix .. requiredDLC] == nil then
		xmlFile:delete()
		return nil, true
	end
	local className = xmlFile:getValue("npc.class", "NPC")
	xmlFile:delete()
	local class = ClassUtil.getClassObject(className)
	if class == nil then
		Logging.xmlWarning(xmlFile, "NPC controller class '%s' not found!", className)
		return nil
	end
	local npc = class.new(g_server ~= nil, g_client ~= nil)
	if not npc:load(xmlFilename) then
		npc:delete()
		return nil
	else
		return npc
	end
end
function NPCUtil.createConversationFromXML(npc, xmlFilename, uniqueId)
	local xmlFile = XMLFile.load("NPCConversation", xmlFilename, NPCConversation.xmlSchema)
	if xmlFile == nil then
		return nil
	end
	local className = xmlFile:getValue("conversation.class", "NPCConversation")
	xmlFile:delete()
	local class = ClassUtil.getClassObject(className)
	if class == nil then
		Logging.xmlWarning(xmlFile, "NPC Conversation class '%s' not found!", className)
		return nil
	end
	local conversation = class.new(npc, uniqueId)
	if not conversation:load(xmlFilename) then
		Logging.warning("Could not load NPC conversation '%s'!", xmlFilename)
		conversation:delete()
		return nil
	else
		return conversation
	end
end
function NPCUtil.createTextFromPath(path, isOption, isActive)
	local englishTextFilename = path .. "_en.xml"
	local xmlFile = XMLFile.load("NPCText", englishTextFilename, NPCText.xmlSchema)
	if xmlFile == nil then
		return nil
	else
		xmlFile:delete()
		local text = NPCText.new(isActive)
		text:load(path, isOption)
		return text
	end
end
function NPCUtil.loadActionsFromXMLFile(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local actions = nil
	local actionClasses = g_npcManager:getAllConverationActionClasses()
	for name, actionClass in pairs(actionClasses) do
		local actionIteratorKey = key .. ".actions." .. name
		for _, actionKey in xmlFile:iterator(actionIteratorKey) do
			local action = actionClass.createFromXML(xmlFile, actionKey, conversation, baseDirectory, customEnvironment)
			if action ~= nil then
				if actions == nil then
					actions = {}
				end
				table.insert(actions, action)
			else
				Logging.xmlWarning(xmlFile, "Could not create conversation action in '%s'", actionKey)
			end
		end
	end
	return actions
end
function NPCUtil.loadInputsFromXMLFile(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local inputs = nil
	local inputClasses = g_npcManager:getAllConverationInputClasses()
	for name, inputClass in pairs(inputClasses) do
		local inputIteratorKey = key .. ".inputs." .. name
		for _, inputKey in xmlFile:iterator(inputIteratorKey) do
			local input = inputClass.createFromXML(xmlFile, inputKey, conversation, baseDirectory, customEnvironment)
			if input ~= nil then
				if inputs == nil then
					inputs = {}
				end
				table.insert(inputs, input)
			else
				Logging.xmlWarning(xmlFile, "Could not create conversation input in '%s'", inputKey)
			end
		end
	end
	return inputs
end
function NPCUtil.loadOptionPrerequisitesFromXMLFile(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local prerequisites = nil
	local optionPrerequisiteClasses = g_npcManager:getAllConverationOptionPrerequisiteClasses()
	for name, class in pairs(optionPrerequisiteClasses) do
		local iteratorKey = key .. ".prerequisites." .. name
		for _, prerequisiteKey in xmlFile:iterator(iteratorKey) do
			local prerequisite = class.createFromXML(xmlFile, prerequisiteKey, conversation, baseDirectory, customEnvironment)
			if prerequisite ~= nil then
				if prerequisites == nil then
					prerequisites = {}
				end
				table.insert(prerequisites, prerequisite)
			else
				Logging.xmlWarning(xmlFile, "Could not create conversation option prerequisite in '%s'", prerequisiteKey)
			end
		end
	end
	return prerequisites
end
function NPCUtil.cleanEmotionalText(text)
	text = string.gsub(text, "(%[[%w, ]*%])", "")
	text = string.gsub(text, "(%[/[%w ]*%])", "")
	return text
end
