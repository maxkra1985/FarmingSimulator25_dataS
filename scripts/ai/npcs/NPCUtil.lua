NPCUtil = {}

-- Local values: xmlFile, requiredDLC, className, class, npc
function NPCUtil.createFromXML(xmlFilename)
	local v2_ = XMLFile.load("NPC", xmlFilename, NPC.xmlSchema)
	if v2_ == nil then
		return nil
	end
	local v3_ = v2_:getString("npc#requiredDLC")
	if v3_ ~= nil and g_modIsLoaded[g_uniqueDlcNamePrefix .. v3_] == nil then
		v2_:delete()
		return nil, true
	end
	local v4_ = v2_:getValue("npc.class", "NPC")
	v2_:delete()
	local v5_ = ClassUtil.getClassObject(v4_)
	if v5_ == nil then
		Logging.xmlWarning(v2_, "NPC controller class \'%s\' not found!", v4_)
		return nil
	end
	local v6_ = v5_.new(g_server ~= nil, g_client ~= nil)
	if v6_:load(xmlFilename) then
		return v6_
	end
	v6_:delete()
	return nil
end

-- Local values: xmlFile, className, class, conversation
function NPCUtil.createConversationFromXML(npc, xmlFilename, uniqueId)
	local v10_ = XMLFile.load("NPCConversation", xmlFilename, NPCConversation.xmlSchema)
	if v10_ == nil then
		return nil
	end
	local v11_ = v10_:getValue("conversation.class", "NPCConversation")
	v10_:delete()
	local v12_ = ClassUtil.getClassObject(v11_)
	if v12_ == nil then
		Logging.xmlWarning(v10_, "NPC Conversation class \'%s\' not found!", v11_)
		return nil
	end
	local v13_ = v12_.new(npc, uniqueId)
	if v13_:load(xmlFilename) then
		return v13_
	end
	Logging.warning("Could not load NPC conversation \'%s\'!", xmlFilename)
	v13_:delete()
	return nil
end

-- Local values: englishTextFilename, xmlFile, text
function NPCUtil.createTextFromPath(path, isOption, isActive)
	local v17_ = path .. "_en.xml"
	local v18_ = XMLFile.load("NPCText", v17_, NPCText.xmlSchema)
	if v18_ == nil then
		return nil
	end
	v18_:delete()
	local v19_ = NPCText.new(isActive)
	v19_:load(path, isOption)
	return v19_
end

-- Local values: actions, actionClasses, name, actionClass, actionIteratorKey, _, actionKey, action
function NPCUtil.loadActionsFromXMLFile(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v25_ = g_npcManager:getAllConverationActionClasses()
	local v26_ = nil
	for v27_, v28_ in pairs(v25_) do
		for _, v29_ in xmlFile:iterator(key .. ".actions." .. v27_) do
			local v30_ = v28_.createFromXML(xmlFile, v29_, conversation, baseDirectory, customEnvironment)
			if v30_ == nil then
				Logging.xmlWarning(xmlFile, "Could not create conversation action in \'%s\'", v29_)
			else
				v26_ = v26_ == nil and {} or v26_
				table.insert(v26_, v30_)
			end
		end
	end
	return v26_
end

-- Local values: inputs, inputClasses, name, inputClass, inputIteratorKey, _, inputKey, input
function NPCUtil.loadInputsFromXMLFile(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v36_ = g_npcManager:getAllConverationInputClasses()
	local v37_ = nil
	for v38_, v39_ in pairs(v36_) do
		for _, v40_ in xmlFile:iterator(key .. ".inputs." .. v38_) do
			local v41_ = v39_.createFromXML(xmlFile, v40_, conversation, baseDirectory, customEnvironment)
			if v41_ == nil then
				Logging.xmlWarning(xmlFile, "Could not create conversation input in \'%s\'", v40_)
			else
				v37_ = v37_ == nil and {} or v37_
				table.insert(v37_, v41_)
			end
		end
	end
	return v37_
end

-- Local values: prerequisites, optionPrerequisiteClasses, name, class, iteratorKey, _, prerequisiteKey, prerequisite
function NPCUtil.loadOptionPrerequisitesFromXMLFile(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v47_ = g_npcManager:getAllConverationOptionPrerequisiteClasses()
	local v48_ = nil
	for v49_, v50_ in pairs(v47_) do
		for _, v51_ in xmlFile:iterator(key .. ".prerequisites." .. v49_) do
			local v52_ = v50_.createFromXML(xmlFile, v51_, conversation, baseDirectory, customEnvironment)
			if v52_ == nil then
				Logging.xmlWarning(xmlFile, "Could not create conversation option prerequisite in \'%s\'", v51_)
			else
				v48_ = v48_ == nil and {} or v48_
				table.insert(v48_, v52_)
			end
		end
	end
	return v48_
end

function NPCUtil.cleanEmotionalText(text)
	local v54_ = string.gsub(text, "(%[[%w, ]*%])", "")
	return string.gsub(v54_, "(%[/[%w ]*%])", "")
end
